"""Dataset loading and preparation utilities for the decorrelation pipeline."""

from __future__ import annotations

import csv
from pathlib import Path
from typing import Dict, Iterable, Tuple

import numpy as np

try:
    from scipy.io import loadmat
except ModuleNotFoundError:  # pragma: no cover - handled at runtime.
    loadmat = None


def round_matlab(values: Iterable[float]) -> np.ndarray:
    """Round halfway cases away from zero, matching MATLAB's ``round``."""
    array = np.asarray(values, dtype=np.float64)
    return np.copysign(np.floor(np.abs(array) + 0.5), array)


def load_mat_data(dataset_path: str, key: str = "data") -> np.ndarray:
    """Load a MATLAB array from a .mat file and flatten it to a 1D signal."""
    if loadmat is None:
        raise ModuleNotFoundError("scipy is required to read MATLAB files")

    candidate = Path(dataset_path)
    if not candidate.exists():
        if not candidate.name.startswith("C_"):
            prefixed = candidate.with_name(f"C_{candidate.name}")
            if prefixed.exists():
                candidate = prefixed
            else:
                matches = list(candidate.parent.glob(f"*{candidate.stem}*.mat"))
                if matches:
                    candidate = matches[0]
                else:
                    raise FileNotFoundError(f"Could not find a MATLAB file matching '{dataset_path}'")

    mat = loadmat(str(candidate), squeeze_me=True)
    if key not in mat:
        raise KeyError(f"MAT file '{candidate}' does not contain the '{key}' field")

    signal = np.asarray(mat[key], dtype=np.float64)
    return np.ravel(signal)


def normalization_factor(data: Iterable[float]) -> float:
    """Return the scale factor used by the MATLAB normalization reference."""
    signal = np.asarray(list(data), dtype=np.float64)
    if signal.size == 0:
        raise ValueError("Cannot normalize an empty signal")

    data_min = float(np.min(signal))
    data_max = float(np.max(signal))
    if data_max == data_min:
        return 1.0

    pos_fact = 255.0 / data_max if data_max > 0 else float("inf")
    neg_fact = -256.0 / data_min if data_min < 0 else float("inf")
    if np.isfinite(pos_fact) and np.isfinite(neg_fact):
        return neg_fact if pos_fact >= neg_fact else pos_fact
    if np.isfinite(pos_fact):
        return pos_fact
    if np.isfinite(neg_fact):
        return neg_fact
    return 1.0


def normalize_signal(data: Iterable[float]) -> np.ndarray:
    """Apply the reference 255/−256 scaling and round to integer samples."""
    signal = np.asarray(list(data), dtype=np.float64)
    if signal.size == 0:
        return signal.copy()
    return round_matlab(signal * normalization_factor(signal))


def create_split_indices(num_samples: int, train_range: Tuple[int, int] = (1001, 3000), val_range: Tuple[int, int] = (3001, 4000), test_range: Tuple[int, int] = (4001, 5000)) -> Dict[str, Tuple[int, int]]:
    """Map the sample ranges described in the project to Python slice indices."""
    bounds = {
        "train": (max(0, train_range[0] - 1), min(num_samples, train_range[1])),
        "validation": (max(0, val_range[0] - 1), min(num_samples, val_range[1])),
        "test": (max(0, test_range[0] - 1), min(num_samples, test_range[1])),
    }
    return bounds


def _save_csv_signal(path: Path, values: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as csv_file:
        writer = csv.writer(csv_file)
        for value in np.ravel(values):
            writer.writerow([float(value)])


def _load_csv_signal(path: Path) -> np.ndarray:
    values = []
    with path.open("r", newline="") as csv_file:
        reader = csv.reader(csv_file)
        for row in reader:
            if not row:
                continue
            values.append(float(row[0]))
    return np.asarray(values, dtype=np.float64)


def prepare_dataset(dataset_path: str, data_dir: str = "data", overwrite: bool = False) -> Dict[str, np.ndarray]:
    """Load a dataset, split it into train/validation/test segments and cache it as CSV."""
    source = Path(dataset_path)
    dataset_name = source.stem
    data_root = Path(data_dir)
    data_root.mkdir(parents=True, exist_ok=True)

    signal = load_mat_data(str(source))
    normalized = normalize_signal(signal)

    split_map = create_split_indices(len(normalized))
    splits = {
        "train": normalized[split_map["train"][0] : split_map["train"][1]],
        "validation": normalized[split_map["validation"][0] : split_map["validation"][1]],
        "test": normalized[split_map["test"][0] : split_map["test"][1]],
    }

    csv_paths = {
        "train": data_root / f"{dataset_name}_train.csv",
        "validation": data_root / f"{dataset_name}_validation.csv",
        "test": data_root / f"{dataset_name}_test.csv",
    }

    if overwrite or not all(path.exists() for path in csv_paths.values()):
        for split_name, values in splits.items():
            _save_csv_signal(csv_paths[split_name], values)

    for split_name, path in csv_paths.items():
        if path.exists():
            splits[split_name] = _load_csv_signal(path)

    return {
        "source": signal,
        "normalized": normalized,
        "train": splits["train"],
        "validation": splits["validation"],
        "test": splits["test"],
    }


def make_lagged_dataset(signal: np.ndarray, taps: int = 4) -> Tuple[np.ndarray, np.ndarray]:
    """Create regression data where each row contains the previous taps and the target is the current value."""
    if taps <= 0:
        raise ValueError("taps must be a positive integer")

    values = np.asarray(signal, dtype=np.float64)
    if len(values) <= taps:
        return np.empty((0, taps), dtype=np.float64), np.empty((0,), dtype=np.float64)

    windows = np.lib.stride_tricks.sliding_window_view(values, taps + 1)
    X = np.ascontiguousarray(windows[:, :-1])
    y = np.array(windows[:, -1], copy=True)
    return X, y


def map_signed_data(signal: np.ndarray) -> np.ndarray:
    """Map signed values to non-negative integers as described in the project notes."""
    mapped = np.where(signal >= 0, 2.0 * signal, -2.0 * signal - 1.0)
    return np.rint(mapped).astype(np.int64)
