"""Differential Pulse Code Modulation utilities."""

from __future__ import annotations

import csv
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

import numpy as np


@dataclass
class DPCMResult:
    """Container holding a predictor, its estimate and the residual error."""

    prediction: np.ndarray
    residual: np.ndarray
    coefficients: np.ndarray

    def __array__(self, dtype=None):
        return np.asarray(self.residual, dtype=dtype)


def dpcm1(signal: np.ndarray) -> DPCMResult:
    """Implement the MATLAB reference for first-order differencing."""
    signal = np.asarray(signal, dtype=np.float64)
    coefficients = np.array([1.0], dtype=np.float64)

    prediction = np.zeros_like(signal, dtype=np.float64)
    if signal.size > 1:
        prediction[1:] = signal[:-1]

    residual = np.diff(signal) if signal.size > 1 else np.empty((0,), dtype=np.float64)
    return DPCMResult(prediction=prediction, residual=residual, coefficients=coefficients)


def dpcm2(signal: np.ndarray) -> DPCMResult:
    """Implement the MATLAB reference for second-order DPCM."""
    signal = np.asarray(signal, dtype=np.float64)
    coefficients = np.array([2.0, -1.0], dtype=np.float64)

    prediction = np.zeros_like(signal, dtype=np.float64)
    if signal.size >= 2:
        prediction[1] = signal[0]
    if signal.size >= 3:
        prediction[2:] = 2.0 * signal[1:-1] - signal[:-2]

    if signal.size == 0:
        residual = np.empty((0,), dtype=np.float64)
    elif signal.size == 1:
        residual = signal.copy()
    else:
        residual = np.empty(signal.size, dtype=np.float64)
        residual[0] = signal[0]
        residual[1] = signal[1] - signal[0]
        if signal.size > 2:
            residual[2:] = np.diff(signal, n=2)

    return DPCMResult(prediction=prediction, residual=residual, coefficients=coefficients)


def dpcm(signal: np.ndarray, mode: str = "dpcm1") -> DPCMResult:
    """Run DPCM in either the first or second order form."""
    normalized_mode = mode.lower()
    if normalized_mode == "dpcm1":
        return dpcm1(signal)
    if normalized_mode == "dpcm2":
        return dpcm2(signal)
    raise ValueError(f"Unsupported DPCM mode '{mode}'. Expected 'dpcm1' or 'dpcm2'.")


def run_dpcm_comparison(dataset_path: str = "dataset/C_Easy1_noise01.mat") -> None:
    """Run both DPCM methods and write a combined compression summary."""
    from main import run_pipeline

    results = [
        run_pipeline(dataset_path=dataset_path, method=method)
        for method in ("DPCM1", "DPCM2")
    ]

    dataset_stem = Path(dataset_path).stem
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    summary_path = (
        Path("output") / f"{dataset_stem}_dpcm_compression_{timestamp}.csv"
    )
    with summary_path.open("w", newline="") as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(
            (
                "method",
                "sample_count",
                "residual_sample_count",
                "encoded_bits",
                "compression_ratio",
                "cr_percent",
                "compressed_file_bytes",
                "prediction_errors_csv",
                "compressed_file",
            )
        )
        for result in results:
            gc_result = result["gc_result"]
            writer.writerow(
                (
                    result["method"],
                    gc_result["sample_count"],
                    len(result["residual"]),
                    gc_result["encoded_bits"],
                    gc_result["compression_rate"],
                    gc_result["compression_rate_percent"],
                    gc_result["compressed_file_bytes"],
                    result["residual_path"],
                    result["compressed_path"],
                )
            )
            print(
                f"{result['method']}: CR={result['cr_percent']:.3f}% "
                f"({gc_result['encoded_bits']} payload bits)"
            )

    print(f"Compression summary: {summary_path}")
    for result in results:
        print(f"{result['method']} prediction/difference CSV: {result['residual_path']}")
