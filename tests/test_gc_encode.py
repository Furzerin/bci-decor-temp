import struct
import tempfile
import unittest
from pathlib import Path

from src.gc_encode import adaptive_golomb_encode, write_compressed_file


class AdaptiveGolombEncodeTests(unittest.TestCase):
    def test_payload_and_matlab_style_compression_rate(self):
        result = adaptive_golomb_encode(
            [-1, 0, 1], modulus=3, group_size=10, include_bitstream=True
        )

        self.assertEqual(result["bitstream"], "01000011")
        self.assertEqual(result["encoded_bits"], 8)
        self.assertAlmostEqual(result["compression_rate_percent"], 100 * (1 - 8 / 27))

    def test_compressed_file_contains_metadata_and_packed_payload(self):
        result = adaptive_golomb_encode(
            [-1, 0, 1], modulus=3, group_size=10, include_bitstream=True
        )

        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "residuals.agc"
            file_size = write_compressed_file(path, result)
            contents = path.read_bytes()

        header = struct.Struct(">4sQIQI")
        magic, sample_count, group_size, payload_bits, group_count = header.unpack_from(
            contents
        )
        self.assertEqual(
            (magic, sample_count, group_size, payload_bits, group_count),
            (b"AGC1", 3, 10, 8, 1),
        )
        self.assertEqual(struct.unpack_from(">I", contents, header.size), (3,))
        self.assertEqual(contents[header.size + 4 :], b"\x43")
        self.assertEqual(file_size, len(contents))


if __name__ == "__main__":
    unittest.main()
