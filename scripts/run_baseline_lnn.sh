#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

TAPS="${1:-4}"
PYTHON="${PYTHON:-python3}"

if ! [[ "$TAPS" =~ ^[1-9][0-9]*$ ]]; then
    printf 'Error: taps must be a positive integer (received: %s)\n' "$TAPS" >&2
    exit 2
fi

cd "$PROJECT_DIR"
exec "$PYTHON" main.py \
    --method LNN \
    --taps "$TAPS" \
    --epochs 4000 \
    --dataset dataset/C_Easy1_noise01.mat \
    --signal-type Easy \
    --noise 01