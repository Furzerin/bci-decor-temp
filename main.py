"""End-to-end orchestration for the neural signal decorrelation workflow."""

from __future__ import annotations

import argparse
import csv
from datetime import datetime
from pathlib import Path

import numpy as np

from src.data_prep import prepare_dataset
from src.data_prep import normalization_factor, round_matlab
from src.dpcm import dpcm
from src.gc_encode import adaptive_golomb_encode, write_compressed_file
from src.lnn_model import predict_lnn, train_lnn


def _create_run_directory(
    output_root: Path,
    dataset_path: str,
    method: str,
    taps: int,
    epochs: int,
) -> Path:
    run_name = f"{Path(dataset_path).stem}_{method.lower()}"
    if method == "LNN":
        run_name += f"_taps{taps}_epochs{epochs}"
    elif method == "DPCM2":
        run_name += "_order2"
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    run_dir = output_root / f"{run_name}_{timestamp}"
    run_dir.mkdir(parents=True, exist_ok=False)
    return run_dir


def _write_residual_csv(
    path: Path,
    true_values,
    predicted_values,
    first_sample_index: int,
    differences=None,
) -> None:
    with path.open("w", newline="") as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(("sample_index", "true_value", "predicted_value", "difference"))
        if differences is None:
            differences = np.asarray(true_values) - np.asarray(predicted_values)
        for offset, (actual, predicted, difference) in enumerate(
            zip(true_values, predicted_values, differences)
        ):
            writer.writerow(
                (
                    first_sample_index + offset,
                    float(actual),
                    float(predicted),
                    float(difference),
                )
            )


def run_pipeline(
    dataset_path: str,
    method: str = "LNN",
    taps: int = 4,
    epochs: int = 250,
    noise: str = "01",
    signal_type: str = "Easy",
) -> dict:
    """Train the requested decorrelation method and assess it on the dataset."""
    normalized_method = method.upper()
    if normalized_method not in {"LNN", "DPCM1", "DPCM2"}:
        raise ValueError(f"Unsupported method '{method}'. Use 'LNN', 'DPCM1', or 'DPCM2'.")

    prepared = prepare_dataset(dataset_path, data_dir="data")
    raw_signal = prepared["source"]
    quantized_signal = prepared["normalized"]

    output_dir = Path("output")
    output_dir.mkdir(parents=True, exist_ok=True)
    run_dir = _create_run_directory(output_dir, dataset_path, normalized_method, taps, epochs)

    if normalized_method == "LNN":
        training_signal = raw_signal[:2000]
        if training_signal.size <= taps:
            raise ValueError(
                f"LNN training requires more than {taps} samples; "
                f"the first-2000-sample training segment has {training_signal.size}"
            )
        trained = train_lnn(training_signal, taps=taps, epochs=epochs, learning_rate=1e-3, output_dir=str(run_dir), dataset_name=f"{signal_type}_noise{noise}")
        effective_taps = trained["taps"]
        scale = normalization_factor(raw_signal)
        raw_prediction = np.zeros_like(raw_signal, dtype=np.float64)
        raw_prediction[effective_taps:] = predict_lnn(
            trained["model"], raw_signal, taps=effective_taps
        )
        prediction = round_matlab(raw_prediction * scale)
        true_values = quantized_signal
        residual = true_values - prediction
        residual_path = run_dir / "prediction_errors.csv"
        result = {
            "method": "LNN",
            "model": trained["model"],
            "residual": residual,
            "prediction": prediction,
            "mse": float(
                ((raw_signal[effective_taps:] - raw_prediction[effective_taps:]) ** 2).mean()
            ),
            "model_path": trained["model_path"],
            "run_dir": str(run_dir),
            "residual_path": str(residual_path),
        }
        _write_residual_csv(residual_path, true_values, prediction, 1)
    elif normalized_method in {"DPCM1", "DPCM2"}:
        mode = normalized_method.lower()
        decoded = dpcm(quantized_signal, mode)
        residual_path = run_dir / "prediction_errors.csv"
        result = {
            "method": normalized_method,
            "residual": decoded.residual,
            "prediction": decoded.prediction,
            "coefficients": decoded.coefficients,
            "mse": float((decoded.residual ** 2).mean()),
            "run_dir": str(run_dir),
            "residual_path": str(residual_path),
        }
        if normalized_method == "DPCM1":
            _write_residual_csv(
                residual_path,
                quantized_signal[1:],
                decoded.prediction[1:],
                2,
                differences=decoded.residual,
            )
        else:
            _write_residual_csv(
                residual_path,
                quantized_signal,
                decoded.prediction,
                1,
                differences=decoded.residual,
            )
    gc_result = adaptive_golomb_encode(
        result["residual"], modulus=None, include_bitstream=True
    )
    compressed_path = run_dir / "residuals.agc"
    container_bytes = write_compressed_file(compressed_path, gc_result)
    gc_result["compressed_file_bytes"] = container_bytes
    gc_result["bitstream"] = None
    result["gc_result"] = gc_result
    result["cr_percent"] = gc_result["compression_rate_percent"]
    result["compression_ratio"] = gc_result["compression_rate"]
    result["compressed_path"] = str(compressed_path)
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description="Run neural signal decorrelation and Golomb coding.")
    parser.add_argument("--dataset", default="dataset/C_Easy1_noise01.mat")
    parser.add_argument("--method", choices=("LNN", "DPCM1", "DPCM2"), default="LNN")
    parser.add_argument("--taps", type=int, default=4, help="Number of previous samples used by the LNN.")
    parser.add_argument("--epochs", type=int, default=250, help="Number of LNN training epochs.")
    parser.add_argument("--noise", default="01")
    parser.add_argument("--signal-type", default="Easy")
    args = parser.parse_args()

    result = run_pipeline(
        dataset_path=args.dataset,
        method=args.method,
        taps=args.taps,
        epochs=args.epochs,
        noise=args.noise,
        signal_type=args.signal_type,
    )
    print(f"Method: {result['method']}")
    print(f"MSE: {result['mse']:.6f}")
    print(f"Golomb CR: {result['cr_percent']:.3f}%")
    print(f"Encoded payload: {result['gc_result']['encoded_bits']} bits")
    print(f"Compressed output: {result['compressed_path']}")
    print(f"Run directory: {result['run_dir']}")
    print(f"Prediction errors: {result['residual_path']}")
    if "model_path" in result:
        print(f"Trained model: {result['model_path']}")


if __name__ == "__main__":
    main()
