"""Linear neural network training utilities for temporal decorrelation."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Dict, Iterable, List, Sequence, Tuple, Union

import numpy as np

try:  # pragma: no cover - optional dependency.
    import torch
    import torch.nn as nn
    import torch.nn.functional as F
except ModuleNotFoundError:  # pragma: no cover - numpy fallback used in tests.
    torch = None
    nn = None
    F = None


class NumPyLinearNetwork:
    """Linear network trained with sample-wise Widrow-Hoff updates."""

    def __init__(self, taps: int, learning_rate: float = 1e-3, weight_decay: float = 0.0):
        self.taps = int(taps)
        self.learning_rate = float(learning_rate)
        self.weight_decay = float(weight_decay)
        self.weights = np.zeros(self.taps, dtype=np.float64)
        self.bias = 0.0

    def predict(self, inputs: np.ndarray) -> np.ndarray:
        inputs = np.asarray(inputs, dtype=np.float64)
        if inputs.ndim == 1:
            inputs = inputs.reshape(1, -1)
        return inputs @ self.weights + self.bias

    def fit(
        self,
        X: np.ndarray,
        y: np.ndarray,
        epochs: int = 200,
        scheduler_step: int | None = None,
    ) -> List[float]:
        X = np.asarray(X, dtype=np.float64)
        y = np.asarray(y, dtype=np.float64)
        if X.ndim == 1:
            X = X.reshape(-1, 1)
        if X.shape[0] != y.shape[0]:
            raise ValueError("X and y need the same number of rows")
        if X.shape[0] == 0:
            raise ValueError("Training data must contain at least one sample")

        history: List[float] = []
        lr = self.learning_rate
        for epoch in range(epochs):
            squared_error = 0.0
            for inputs, target in zip(X, y):
                error = float(target - (inputs @ self.weights + self.bias))
                squared_error += error * error
                self.weights += lr * error * inputs
                if self.weight_decay:
                    self.weights -= 2.0 * lr * self.weight_decay * self.weights
                self.bias += lr * error
            history.append(squared_error / X.shape[0])

            if scheduler_step and (epoch + 1) % scheduler_step == 0:
                lr *= 0.7

        return history

    def evaluate(self, X: np.ndarray, y: np.ndarray) -> float:
        prediction = self.predict(X)
        return float(np.mean((prediction - y) ** 2))

    def save(self, path: str | Path) -> None:
        output = Path(path)
        output.parent.mkdir(parents=True, exist_ok=True)
        if output.suffix.lower() == ".pt":
            if torch is None:
                raise ModuleNotFoundError("PyTorch is required to save an LNN model as .pt")
            torch.save(
                {
                    "format": "numpy_linear_network",
                    "weights": torch.as_tensor(self.weights, dtype=torch.float64),
                    "bias": torch.tensor(self.bias, dtype=torch.float64),
                    "taps": self.taps,
                },
                output,
            )
            return
        np.savez(output, weights=self.weights, bias=self.bias, taps=self.taps)

    @classmethod
    def load(cls, path: str | Path) -> "NumPyLinearNetwork":
        payload = np.load(path)
        model = cls(int(payload["taps"]))
        model.weights = np.asarray(payload["weights"], dtype=np.float64)
        model.bias = float(payload["bias"])
        return model


class TorchLinearNetwork:
    """PyTorch-based single-layer linearly predictive network."""

    def __init__(self, taps: int, learning_rate: float = 1e-3):
        self.model = nn.Sequential(nn.Linear(taps, 1, bias=True))
        self.optimizer = torch.optim.Adam(self.model.parameters(), lr=learning_rate)
        self.scheduler = torch.optim.lr_scheduler.StepLR(self.optimizer, step_size=50, gamma=0.5)
        self.learning_rate = learning_rate

    def predict(self, X: np.ndarray) -> np.ndarray:
        with torch.no_grad():
            tensor = torch.as_tensor(X, dtype=torch.float32)
            prediction = self.model(tensor)
            return prediction.detach().numpy().reshape(-1)

    def fit(self, X: np.ndarray, y: np.ndarray, epochs: int = 200) -> List[float]:
        X_tensor = torch.as_tensor(X, dtype=torch.float32)
        y_tensor = torch.as_tensor(y, dtype=torch.float32).reshape(-1)
        history: List[float] = []

        for _ in range(epochs):
            self.optimizer.zero_grad()
            prediction = self.model(X_tensor).reshape(-1)
            loss = F.mse_loss(prediction, y_tensor)
            loss.backward()
            self.optimizer.step()
            self.scheduler.step()
            history.append(float(loss.item()))

        return history

    def evaluate(self, X: np.ndarray, y: np.ndarray) -> float:
        prediction = self.model(torch.as_tensor(X, dtype=torch.float32)).reshape(-1)
        target = torch.as_tensor(y, dtype=torch.float32).reshape(-1)
        return float(F.mse_loss(prediction, target).item())

    def save(self, path: str | Path) -> None:
        output = Path(path)
        output.parent.mkdir(parents=True, exist_ok=True)
        torch.save(self.model.state_dict(), output)

    @classmethod
    def load(cls, path: str | Path, taps: int, learning_rate: float = 1e-3) -> "TorchLinearNetwork":
        model = cls(taps, learning_rate=learning_rate)
        model.model.load_state_dict(torch.load(path, map_location="cpu"))
        return model


def _ensure_taps(signal: Sequence[float], taps: int) -> int:
    total = int(taps)
    if total <= 0:
        raise ValueError("taps must be at least 1")
    if len(signal) <= total:
        return min(total, max(1, len(signal) - 1))
    return total


def train_lnn(signal: np.ndarray, taps: int = 4, epochs: int = 200, learning_rate: float = 5e-4, validation_signal: np.ndarray | None = None, output_dir: str = "output", dataset_name: str = "signal") -> Dict[str, Any]:
    """Train a linear neural network on lagged versions of the input signal."""
    from .data_prep import make_lagged_dataset

    taps = _ensure_taps(signal, taps)
    X_train, y_train = make_lagged_dataset(np.asarray(signal, dtype=np.float64), taps=taps)
    if validation_signal is None:
        X_val = X_train
        y_val = y_train
    else:
        X_val, y_val = make_lagged_dataset(np.asarray(validation_signal, dtype=np.float64), taps=taps)

    model = NumPyLinearNetwork(taps=taps, learning_rate=learning_rate)
    history = model.fit(X_train, y_train, epochs=epochs)
    val_mse = model.evaluate(X_val, y_val)
    model_path = Path(output_dir) / f"{dataset_name}_lnn_taps{taps}_epoch{epochs}.npz"
    model.save(model_path)
    return {
        "model": model,
        "history": history,
        "validation_mse": val_mse,
        "taps": taps,
        "model_path": str(model_path),
        "weights": model.weights,
        "bias": model.bias,
    }


def predict_lnn(model: Any, signal: np.ndarray, taps: int = 4) -> np.ndarray:
    """Apply a trained linear model to the full signal."""
    from .data_prep import make_lagged_dataset

    X, _ = make_lagged_dataset(np.asarray(signal, dtype=np.float64), taps=taps)
    if hasattr(model, "predict"):
        return model.predict(X)
    if isinstance(model, dict):
        weights = np.asarray(model.get("weights", np.zeros(taps)), dtype=np.float64)
        bias = float(model.get("bias", 0.0))
        return X @ weights + bias
    if isinstance(model, (tuple, list)) and len(model) >= 2:
        weights, bias = model[:2]
        return X @ np.asarray(weights, dtype=np.float64) + float(bias)
    raise TypeError(f"Unsupported model type: {type(model)!r}")


def evaluate_lnn(model: Any, signal: np.ndarray, taps: int = 4) -> float:
    """Compute MSE for a model over a full signal."""
    from .data_prep import make_lagged_dataset

    X, y = make_lagged_dataset(np.asarray(signal, dtype=np.float64), taps=taps)
    if hasattr(model, "evaluate"):
        return model.evaluate(X, y)
    prediction = predict_lnn(model, signal, taps=taps)
    return float(np.mean((prediction - y) ** 2))


def save_lnn_model(model: Any, path: str | Path) -> None:
    if hasattr(model, "save"):
        model.save(path)
        return
    if isinstance(model, dict):
        payload = Path(path)
        payload.parent.mkdir(parents=True, exist_ok=True)
        np.savez(payload, weights=np.asarray(model.get("weights", [])), bias=float(model.get("bias", 0.0)), taps=int(model.get("taps", len(model.get("weights", [])))))
        return
    raise TypeError("Unsupported model object for saving")


def load_lnn_model(path: str | Path, taps: int = 4, learning_rate: float = 1e-3) -> Any:
    payload = Path(path)
    if payload.suffix.lower() == ".pt" and torch is not None:
        checkpoint = torch.load(payload, map_location="cpu", weights_only=True)
        if checkpoint.get("format") == "numpy_linear_network":
            model = NumPyLinearNetwork(int(checkpoint["taps"]))
            model.weights = checkpoint["weights"].numpy().astype(np.float64)
            model.bias = float(checkpoint["bias"].item())
            return model
        return TorchLinearNetwork.load(payload, taps=taps, learning_rate=learning_rate)
    if payload.suffix.lower() == ".npz":
        return NumPyLinearNetwork.load(payload)
    raise ValueError(f"Unsupported model path suffix: '{payload.suffix}'")
