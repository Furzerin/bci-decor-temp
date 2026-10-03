"""Fixed-point LNN quantization and inference utilities."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

import numpy as np

from src.data_prep import prepare_dataset, round_matlab
from src.gc_encode import adaptive_golomb_encode, write_compressed_file
from src.lnn_model import load_lnn_model


def quantize_fixed_point(
    values: np.ndarray,
    integer_bits: int,
    fractional_bits: int,
) -> np.ndarray:
    """Quantize signed-magnitude values to the requested integer/fraction format."""
    if integer_bits <= 0 or fractional_bits < 0:
        raise ValueError("integer_bits must be positive and fractional_bits non-negative")

    values_array = np.asarray(values, dtype=np.float64)
    scale = float(1 << fractional_bits)
    max_magnitude = float((1 << (integer_bits + fractional_bits)) - 1)
    magnitude = np.floor(np.abs(values_array) * scale + 0.5)
    quantized_magnitude = np.minimum(magnitude, max_magnitude) / scale
    return np.copysign(quantized_magnitude, values_array)


def _write_prediction_errors(
    path: Path,
    signal: np.ndarray,
    prediction: np.ndarray,
) -> np.ndarray:
    residual = signal - prediction
    with path.open("w", newline="") as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(("sample_index", "true_value", "predicted_value", "difference"))
        for index, (actual, predicted, difference) in enumerate(
            zip(signal, prediction, residual), start=1
        ):
            writer.writerow((index, float(actual), float(predicted), float(difference)))
    return residual


def run_quantized_inference(
    model_path: str | Path,
    dataset_path: str,
    integer_bits: int,
    fractional_bits: int,
    output_root: str | Path,
    summary_csv: str | Path,
) -> dict:
    """Quantize a trained LNN, run full-signal inference, and measure its CR."""
    checkpoint_path = Path(model_path)
    if not checkpoint_path.is_file():
        raise FileNotFoundError(f"Trained model checkpoint not found: {checkpoint_path}")

    model = load_lnn_model(checkpoint_path)
    taps = int(model.taps)
    bitwidth = 1 + integer_bits + fractional_bits
    weights = quantize_fixed_point(model.weights, integer_bits, fractional_bits)
    bias = float(quantize_fixed_point(np.asarray(model.bias), integer_bits, fractional_bits))

    prepared = prepare_dataset(dataset_path, data_dir="data")
    signal = prepared["normalized"]
    model_signal = signal / 128.0
    normalized_prediction = np.zeros_like(model_signal, dtype=np.float64)
    windows = np.lib.stride_tricks.sliding_window_view(model_signal, taps + 1)
    inputs = np.ascontiguousarray(windows[:, :-1])
    normalized_prediction[taps:] = inputs @ weights + bias
    prediction = round_matlab(normalized_prediction * 128.0)

    output_dir = Path(output_root)
    run_dir = output_dir / f"{checkpoint_path.parent.name}_bits{bitwidth}"
    run_dir.mkdir(parents=True, exist_ok=False)

    quantized_model_path = run_dir / "quantized_model.npz"
    np.savez(
        quantized_model_path,
        weights=weights,
        bias=bias,
        taps=taps,
        bitwidth=bitwidth,
        integer_bits=integer_bits,
        fractional_bits=fractional_bits,
    )
    residual_path = run_dir / "prediction_errors.csv"
    residual = _write_prediction_errors(residual_path, signal, prediction)

    encoded = adaptive_golomb_encode(residual, include_bitstream=True)
    compressed_path = run_dir / "residuals.agc"
    compressed_file_bytes = write_compressed_file(compressed_path, encoded)
    encoded["compressed_file_bytes"] = compressed_file_bytes

    cr_percent = float(encoded["compression_rate_percent"])
    compression_ratio = float(encoded["compression_rate"])
    summary = {
        "method": "LNN",
        "taps": taps,
        "epochs": 4000,
        "bitwidth": bitwidth,
        "integer_bits": integer_bits,
        "fractional_bits": fractional_bits,
        "mse": float(np.mean(residual[taps:] ** 2)),
        "sample_count": int(encoded["sample_count"]),
        "encoded_bits": int(encoded["encoded_bits"]),
        "compression_ratio": compression_ratio,
        "cr_percent": cr_percent,
        "compressed_file_bytes": compressed_file_bytes,
        "model_path": str(quantized_model_path),
        "prediction_errors_csv": str(residual_path),
        "compressed_file": str(compressed_path),
        "run_dir": str(run_dir),
    }

    run_summary_path = run_dir / "compression_summary.csv"
    columns = tuple(summary)
    for path in (run_summary_path, Path(summary_csv)):
        path.parent.mkdir(parents=True, exist_ok=True)
        write_header = not path.exists() or path.stat().st_size == 0
        with path.open("a", newline="") as csv_file:
            writer = csv.DictWriter(csv_file, fieldnames=columns)
            if write_header:
                writer.writeheader()
            writer.writerow(summary)

    print(
        f"Quantized LNN taps={taps}, width={bitwidth} "
        f"(sign+{integer_bits}+{fractional_bits}): CR={cr_percent:.3f}%"
    )
    print(f"Quantized model: {quantized_model_path}")
    print(f"Compression summary: {run_summary_path}")
    return summary


def _parse_formats(value: str) -> list[tuple[int, int, int]]:
    formats = []
    for item in value.split(","):
        try:
            bitwidth_text, integer_text, fractional_text = item.split(":")
            bitwidth, integer_bits, fractional_bits = map(
                int, (bitwidth_text, integer_text, fractional_text)
            )
        except ValueError as error:
            raise argparse.ArgumentTypeError(
                f"Invalid format '{item}'; expected BITWIDTH:INTEGER_BITS:FRACTIONAL_BITS"
            ) from error
        if bitwidth != 1 + integer_bits + fractional_bits:
            raise argparse.ArgumentTypeError(
                f"Format '{item}' does not add up to its total bitwidth"
            )
        formats.append((bitwidth, integer_bits, fractional_bits))
    if not formats:
        raise argparse.ArgumentTypeError("At least one quantization format is required")
    return formats


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", required=True)
    parser.add_argument("--dataset", required=True)
    parser.add_argument("--output-root", required=True)
    parser.add_argument("--summary-csv", required=True)
    parser.add_argument(
        "--formats",
        type=_parse_formats,
        default=_parse_formats("4:2:1,8:2:5,12:2:9,16:4:11,32:8:23"),
    )
    args = parser.parse_args()

    for _, integer_bits, fractional_bits in args.formats:
        run_quantized_inference(
            model_path=args.model,
            dataset_path=args.dataset,
            integer_bits=integer_bits,
            fractional_bits=fractional_bits,
            output_root=args.output_root,
            summary_csv=args.summary_csv,
        )


if __name__ == "__main__":
    main()