"""Decorrelation pipeline package."""

from .data_prep import load_mat_data, make_lagged_dataset, normalize_signal, prepare_dataset
from .dpcm import dpcm, dpcm1, dpcm2
from .gc_encode import adaptive_golomb_encode, compression_ratio, golomb_encode, map_signed_data
from .lnn_model import evaluate_lnn, load_lnn_model, predict_lnn, save_lnn_model, train_lnn

__all__ = [
    "adaptive_golomb_encode",
    "compression_ratio",
    "dpcm",
    "dpcm1",
    "dpcm2",
    "evaluate_lnn",
    "golomb_encode",
    "load_lnn_model",
    "load_mat_data",
    "make_lagged_dataset",
    "map_signed_data",
    "normalize_signal",
    "predict_lnn",
    "prepare_dataset",
    "save_lnn_model",
    "train_lnn",
]
