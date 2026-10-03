#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PYTHON="${PYTHON:-python3}"
EPOCHS=4000
TAPS=4
OUTPUT_CSV=""
OUTPUT_ROOT="output/noise"
DATASETS=(
    "dataset/C_Easy1_noise005.mat,Easy,005,0.05"
    "dataset/C_Easy1_noise01.mat,Easy,01,0.1"
    "dataset/C_Easy1_noise015.mat,Easy,015,0.15"
    "dataset/C_Easy1_noise02.mat,Easy,02,0.2"
    "dataset/C_Difficult1_noise005.mat,Difficult,005,0.05"
    "dataset/C_Difficult1_noise01.mat,Difficult,01,0.1"
    "dataset/C_Difficult1_noise015.mat,Difficult,015,0.15"
    "dataset/C_Difficult1_noise02.mat,Difficult,02,0.2"
)

cd "$PROJECT_DIR"

usage() {
    cat <<'EOF'
Usage: ./scripts/run_noise.sh [options]

Train a 4-tap LNN for 4,000 epochs on every Easy and Difficult dataset at
noise levels 0.05, 0.1, 0.15, and 0.2. Save run artifacts and aggregate
results under output/noise/.

Options:
  --epochs COUNT       Override the training epoch count
  --taps COUNT         Override the number of LNN taps
  --output-csv PATH    Override the aggregate CSV path
  -h, --help           Show this help
EOF
}

while (($#)); do
    case "$1" in
        --epochs|--taps|--output-csv)
            if (($# < 2)); then
                printf 'Error: %s requires a value\n' "$1" >&2
                exit 2
            fi
            option="$1"
            value="$2"
            case "$option" in
                --epochs) EPOCHS="$value" ;;
                --taps) TAPS="$value" ;;
                --output-csv) OUTPUT_CSV="$value" ;;
            esac
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Error: unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if ! [[ "$EPOCHS" =~ ^[1-9][0-9]*$ ]]; then
    printf 'Error: invalid epoch count: %s\n' "$EPOCHS" >&2
    exit 2
fi
if ! [[ "$TAPS" =~ ^[1-9][0-9]*$ ]]; then
    printf 'Error: invalid tap count: %s\n' "$TAPS" >&2
    exit 2
fi

for entry in "${DATASETS[@]}"; do
    IFS=, read -r dataset signal_type noise noise_level <<< "$entry"
    if [[ ! -f "$dataset" ]]; then
        printf 'Error: dataset not found: %s\n' "$dataset" >&2
        exit 1
    fi
done

mkdir -p "$OUTPUT_ROOT"
if [[ -z "$OUTPUT_CSV" ]]; then
    timestamp="$(date '+%Y%m%d_%H%M%S')"
    OUTPUT_CSV="$OUTPUT_ROOT/lnn_noise_robustness_${timestamp}.csv"
else
    mkdir -p "$(dirname "$OUTPUT_CSV")"
fi
printf '%s\n' \
    'method,taps,epochs,signal_type,noise,dataset,cr_percent,compression_ratio,encoded_bits,sample_count,run_dir,compression_summary_csv' \
    > "$OUTPUT_CSV"

total_runs=${#DATASETS[@]}
run_number=0
for entry in "${DATASETS[@]}"; do
    IFS=, read -r dataset signal_type noise noise_level <<< "$entry"
    run_number=$((run_number + 1))
    printf '[%s/%s] LNN signal=%s, noise=%s, taps=%s, epochs=%s\n' \
        "$run_number" "$total_runs" "$signal_type" "$noise_level" "$TAPS" "$EPOCHS"
    if ! run_output=$(
        "$PYTHON" main.py \
            --method LNN \
            --taps "$TAPS" \
            --epochs "$EPOCHS" \
            --dataset "$dataset" \
            --signal-type "$signal_type" \
            --noise "$noise" \
            --output-root "$OUTPUT_ROOT" 2>&1 | tee /dev/stderr
    ); then
        printf 'Error: LNN run failed for dataset=%s\n' "$dataset" >&2
        exit 1
    fi

    summary_csv="$(sed -n 's/^Compression summary: //p' <<< "$run_output" | tail -n 1)"
    if [[ -z "$summary_csv" || ! -f "$summary_csv" ]]; then
        printf 'Error: run did not produce a readable compression summary\n' >&2
        exit 1
    fi
    IFS=, read -r method sample_count residual_sample_count encoded_bits \
        compression_ratio cr_percent compressed_file_bytes \
        prediction_errors_csv compressed_file < <(tail -n 1 "$summary_csv")
    if [[ -z "$cr_percent" || -z "$compression_ratio" || -z "$encoded_bits" ]]; then
        printf 'Error: malformed compression summary: %s\n' "$summary_csv" >&2
        exit 1
    fi
    run_dir="$(dirname "$summary_csv")"
    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
        "$method" "$TAPS" "$EPOCHS" "$signal_type" "$noise_level" "$dataset" \
        "$cr_percent" "$compression_ratio" "$encoded_bits" "$sample_count" \
        "$run_dir" "$summary_csv" >> "$OUTPUT_CSV"
    printf '  CR=%s%% (recorded in %s)\n' "$cr_percent" "$OUTPUT_CSV"
done

printf 'Completed %s runs; noise robustness results: %s\n' "$total_runs" "$OUTPUT_CSV"