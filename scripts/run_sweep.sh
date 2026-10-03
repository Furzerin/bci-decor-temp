#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PYTHON="${PYTHON:-python3}"
DATASET="dataset/C_Easy1_noise01.mat"
EPOCHS_CSV="1000,2000,4000,5000,7500,10000,20000"
TAP_RANGES="1:1:10,12:4:32"
NOISE="01"
SIGNAL_TYPE="Easy"
OUTPUT_CSV=""
OUTPUT_ROOT="output/optimization"

cd "$PROJECT_DIR"

usage() {
    cat <<'EOF'
Usage: ./scripts/run_sweep.sh [options]

Sweep LNN epochs and tap counts, saving trial artifacts and compression rates
under output/optimization/.

Options:
  --dataset PATH          Dataset to process
  --epochs LIST           Comma-separated epoch counts
  --taps RANGES           Comma-separated inclusive start:step:stop ranges
  --noise VALUE           Noise label (default: 01)
  --signal-type VALUE     Signal label (default: Easy)
  --output-csv PATH       Override the aggregate CSV path
  -h, --help              Show this help
EOF
}

while (($#)); do
    case "$1" in
        --dataset|--epochs|--taps|--noise|--signal-type|--output-csv)
            if (($# < 2)); then
                printf 'Error: %s requires a value\n' "$1" >&2
                exit 2
            fi
            option="$1"
            value="$2"
            case "$option" in
                --dataset) DATASET="$value" ;;
                --epochs) EPOCHS_CSV="$value" ;;
                --taps) TAP_RANGES="$value" ;;
                --noise) NOISE="$value" ;;
                --signal-type) SIGNAL_TYPE="$value" ;;
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

IFS=',' read -r -a EPOCHS <<< "$EPOCHS_CSV"
if ((${#EPOCHS[@]} == 0)); then
    printf 'Error: --epochs must contain positive integers\n' >&2
    exit 2
fi
for epochs in "${EPOCHS[@]}"; do
    if ! [[ "$epochs" =~ ^[1-9][0-9]*$ ]]; then
        printf 'Error: invalid epoch count: %s\n' "$epochs" >&2
        exit 2
    fi
done

IFS=',' read -r -a RANGE_LIST <<< "$TAP_RANGES"
TAPS=()
declare -A SEEN_TAPS=()
for range in "${RANGE_LIST[@]}"; do
    IFS=':' read -r start step stop extra <<< "$range"
    if [[ -n "${extra:-}" ]] || ! [[ "$start" =~ ^[1-9][0-9]*$ ]] \
        || ! [[ "$step" =~ ^[1-9][0-9]*$ ]] \
        || ! [[ "$stop" =~ ^[1-9][0-9]*$ ]] || ((stop < start)); then
        printf 'Error: invalid tap range: %s (expected start:step:stop)\n' "$range" >&2
        exit 2
    fi
    for ((tap = start; tap <= stop; tap += step)); do
        if [[ -n "${SEEN_TAPS[$tap]:-}" ]]; then
            printf 'Error: tap ranges overlap at tap %s\n' "$tap" >&2
            exit 2
        fi
        SEEN_TAPS[$tap]=1
        TAPS+=("$tap")
    done
done
if ((${#TAPS[@]} == 0)); then
    printf 'Error: --taps must contain at least one tap count\n' >&2
    exit 2
fi

if [[ -z "$OUTPUT_CSV" ]]; then
    mkdir -p output/optimization
    timestamp="$(date '+%Y%m%d_%H%M%S')"
    OUTPUT_CSV="output/optimization/$(basename "${DATASET%.*}")_lnn_sweep_${timestamp}.csv"
else
    mkdir -p "$(dirname "$OUTPUT_CSV")"
fi
printf '%s\n' \
    'method,taps,epochs,cr_percent,compression_ratio,encoded_bits,sample_count,run_dir,compression_summary_csv' \
    > "$OUTPUT_CSV"

total_runs=$((${#TAPS[@]} * ${#EPOCHS[@]}))
run_number=0
for taps in "${TAPS[@]}"; do
    for epochs in "${EPOCHS[@]}"; do
        run_number=$((run_number + 1))
        printf '[%s/%s] LNN taps=%s, epochs=%s\n' "$run_number" "$total_runs" "$taps" "$epochs"
        if ! run_output=$(
            "$PYTHON" main.py \
                --method LNN \
                --taps "$taps" \
                --epochs "$epochs" \
                --dataset "$DATASET" \
                --signal-type "$SIGNAL_TYPE" \
                --noise "$NOISE" \
                --output-root "$OUTPUT_ROOT" 2>&1 | tee /dev/stderr
        ); then
            printf 'Error: LNN run failed for taps=%s, epochs=%s\n' "$taps" "$epochs" >&2
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
        printf '%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
            "$method" "$taps" "$epochs" "$cr_percent" "$compression_ratio" \
            "$encoded_bits" "$sample_count" "$run_dir" "$summary_csv" \
            >> "$OUTPUT_CSV"
        printf '  CR=%s%% (recorded in %s)\n' "$cr_percent" "$OUTPUT_CSV"
    done
done

printf 'Completed %s runs; sweep results: %s\n' "$total_runs" "$OUTPUT_CSV"