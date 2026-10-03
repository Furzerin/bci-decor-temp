#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PYTHON="${PYTHON:-python3}"

cd "$PROJECT_DIR"
exec "$PYTHON" -c 'from src.dpcm import run_dpcm_comparison; run_dpcm_comparison()'