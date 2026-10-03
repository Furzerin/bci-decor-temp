"""Golomb coding utilities for the decorrelation pipeline."""

from __future__ import annotations

import struct
from pathlib import Path
from typing import Any, Dict, Iterable, List, Sequence

import numpy as np

_CONTAINER_HEADER = struct.Struct(">4sQIQI")


def map_signed_data(signal: Iterable[float]) -> np.ndarray:
    """Map the signal to a non-negative integer domain before Golomb coding."""
    arr = np.rint(np.asarray(list(signal), dtype=np.float64)).astype(np.int64)
    mapped = np.where(arr >= 0, 2 * arr, -2 * arr - 1)
    return mapped.astype(np.int64)


def golomb_encode(values: Sequence[int], modulus: int | None = None) -> str:
    """Encode non-negative integers using unary and truncated-binary Golomb codes."""
    values_array = np.rint(np.asarray(values, dtype=np.float64)).astype(np.int64)
    if values_array.size == 0:
        return ""

    if modulus is None:
        modulus = max(1, int(np.median(np.abs(values_array.astype(np.float64))) + 1.0))
    if modulus <= 0:
        raise ValueError("modulus must be positive")

    bitstream: List[str] = []
    for value in values_array:
        if value < 0:
            raise ValueError("Golomb coding expects non-negative integers")
        quotient, remainder = divmod(int(value), int(modulus))
        bitstream.append("1" * quotient + "0")
        if modulus > 1:
            binary_width = int(np.ceil(np.log2(modulus)))
            cutoff = (1 << binary_width) - modulus
            if remainder < cutoff:
                bitstream.append(f"{remainder:0{binary_width - 1}b}")
            else:
                bitstream.append(f"{remainder + cutoff:0{binary_width}b}")
    return "".join(bitstream)


def _adaptive_modulus(mapped_values: np.ndarray) -> int:
    zero_percent = 100.0 * float(np.count_nonzero(mapped_values == 0)) / len(mapped_values)
    if zero_percent < 5.1:
        return 9
    if zero_percent < 7.4:
        return 8
    if zero_percent < 8.26:
        return 7
    if zero_percent < 9.15:
        return 6
    if zero_percent < 9.66:
        return 5
    if zero_percent < 10.52:
        return 7
    if zero_percent < 12.28:
        return 8
    if zero_percent < 12.69:
        return 7
    if zero_percent < 13.05:
        return 6
    if zero_percent < 13.86:
        return 5
    if zero_percent < 16.51:
        return 4
    return 3


def _golomb_code_length(value: int, modulus: int) -> int:
    quotient, remainder = divmod(value, modulus)
    if modulus == 1:
        return quotient + 1
    binary_width = int(np.ceil(np.log2(modulus)))
    cutoff = (1 << binary_width) - modulus
    remainder_width = binary_width - 1 if remainder < cutoff else binary_width
    return quotient + 1 + remainder_width


def compute_compression_rate(original_bits: int, encoded_bits: int) -> float:
    """Return the input-to-encoded bit ratio; values above 1.0 indicate compression."""
    if encoded_bits <= 0:
        return float("inf")
    return float(original_bits / encoded_bits)


def write_compressed_file(path: Path, result: Dict[str, Any]) -> int:
    """Write an adaptive Golomb bitstream and its decoding metadata.

    The container stores the encoded bit count and one modulus per coding
    group, followed by the MSB-first, byte-packed payload. The returned size
    includes the container metadata.
    """
    bitstream = result.get("bitstream")
    if bitstream is None:
        raise ValueError("result must include a bitstream")

    encoded_bits = int(result["encoded_bits"])
    if len(bitstream) != encoded_bits:
        raise ValueError("bitstream length does not match encoded_bits")
    if any(bit not in "01" for bit in bitstream):
        raise ValueError("bitstream may contain only '0' and '1'")

    moduli = [int(modulus) for modulus in result["group_moduli"]]
    group_size = int(result["group_size"])
    header = _CONTAINER_HEADER.pack(
        b"AGC1",
        int(result["sample_count"]),
        group_size,
        encoded_bits,
        len(moduli),
    )
    modulus_data = struct.pack(f">{len(moduli)}I", *moduli) if moduli else b""
    payload = np.packbits(
        np.frombuffer(bitstream.encode("ascii"), dtype=np.uint8) - ord("0"),
        bitorder="big",
    ).tobytes()

    with path.open("wb") as compressed_file:
        compressed_file.write(header)
        compressed_file.write(modulus_data)
        compressed_file.write(payload)

    return len(header) + len(modulus_data) + len(payload)


def adaptive_golomb_encode(
    signal: Iterable[float],
    modulus: int | None = None,
    group_size: int = 50000,
    include_bitstream: bool = False,
) -> Dict[str, Any]:
    """Apply the reference zero-frequency modulus selection in fixed-size groups.

    The original signal is counted as 9 bits per sample when calculating the
    compression percentage. Set ``include_bitstream`` to materialize the encoded
    payload for writing to a compressed file.
    """
    source = np.asarray(list(signal), dtype=np.float64)
    mapped = map_signed_data(source)
    if group_size <= 0:
        raise ValueError("group_size must be positive")

    group_moduli = []
    encoded_bits = 0
    bitstream_parts: List[str] = []
    for start in range(0, len(mapped), group_size):
        group = mapped[start : start + group_size]
        group_modulus = modulus if modulus is not None else _adaptive_modulus(group)
        if group_modulus <= 0:
            raise ValueError("modulus must be positive")
        group_moduli.append(int(group_modulus))
        encoded_bits += sum(_golomb_code_length(int(value), int(group_modulus)) for value in group)
        if include_bitstream:
            bitstream_parts.append(golomb_encode(group, int(group_modulus)))

    original_bits = len(source) * 9
    compression_rate = compute_compression_rate(original_bits, encoded_bits)
    compression_rate_percent = (
        100.0 * (1.0 - encoded_bits / original_bits) if original_bits else 0.0
    )
    return {
        "mapped": mapped,
        "encoded_bits": encoded_bits,
        "sample_count": len(source),
        "compression_rate": compression_rate,
        "compression_rate_percent": compression_rate_percent,
        "modulus": group_moduli[0] if group_moduli and len(set(group_moduli)) == 1 else None,
        "group_moduli": group_moduli,
        "group_size": group_size,
        "bitstream": "".join(bitstream_parts) if include_bitstream else None,
    }


def compression_ratio(signal: Iterable[float], modulus: int | None = None) -> float:
    """Return the compression ratio for the mapped signal."""
    return float(adaptive_golomb_encode(signal, modulus)["compression_rate"])
