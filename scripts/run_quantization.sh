#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PYTHON="${PYTHON:-$PROJECT_DIR/venv/bin/python}"
DATASET="${DATASET:-dataset/C_Easy1_noise01.mat}"
NOISE="${NOISE:-01}"
SIGNAL_TYPE="${SIGNAL_TYPE:-Easy}"
TRAIN_OUTPUT_ROOT="output/quantization/training"
INFERENCE_OUTPUT_ROOT="output/quantization/inference"
TAPS=(2 3 4 5 6 7 8 16)
FORMATS="4:2:1,8:2:5,12:2:9,16:4:11,32:8:23"

cd "$PROJECT_DIR"

if [[ ! -x "$PYTHON" ]]; then
    printf 'Error: Python executable is not available: %s\n' "$PYTHON" >&2
    exit 2
fi
if [[ ! -f "$DATASET" ]]; then
    printf 'Error: dataset not found: %s\n' "$DATASET" >&2
    exit 2
fi

mkdir -p "$TRAIN_OUTPUT_ROOT" "$INFERENCE_OUTPUT_ROOT"
SUMMARY_CSV="$INFERENCE_OUTPUT_ROOT/quantization_summary_$(date '+%Y%m%d_%H%M%S_%N').csv"
printf '%s\n' \
    'method,taps,epochs,bitwidth,integer_bits,fractional_bits,mse,sample_count,encoded_bits,compression_ratio,cr_percent,compressed_file_bytes,model_path,prediction_errors_csv,compressed_file,run_dir' \
    > "$SUMMARY_CSV"

for taps in "${TAPS[@]}"; do
    printf '\nTraining LNN taps=%s for 4000 epochs\n' "$taps"
    run_output="$("$PYTHON" main.py \
        --method LNN \
        --taps "$taps" \
        --epochs 4000 \
        --dataset "$DATASET" \
        --signal-type "$SIGNAL_TYPE" \
        --noise "$NOISE" \
        --output-root "$TRAIN_OUTPUT_ROOT" 2>&1)" || {
            printf '%s\n' "$run_output" >&2
            printf 'Error: training failed for taps=%s\n' "$taps" >&2
            exit 1
        }
    printf '%s\n' "$run_output"

    model_path="$(sed -n 's/^Trained model: //p' <<< "$run_output" | tail -n 1)"
    if [[ -z "$model_path" || ! -f "$model_path" ]]; then
        printf 'Error: training did not produce a readable checkpoint for taps=%s\n' "$taps" >&2
        exit 1
    fi

    "$PYTHON" -m src.quantization \
        --model "$model_path" \
        --dataset "$DATASET" \
        --output-root "$INFERENCE_OUTPUT_ROOT" \
        --summary-csv "$SUMMARY_CSV" \
        --formats "$FORMATS"
done

printf '\nCompleted %s training runs and %s quantized inferences.\n' \
    "${#TAPS[@]}" "$((${#TAPS[@]} * 5))"
printf 'Quantized CR summary: %s\n' "$SUMMARY_CSV"