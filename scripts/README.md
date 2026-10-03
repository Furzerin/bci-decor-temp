# Experiment Scripts 

## Part 0: Baseline - Decorrelation

    Variation of loss matrics through the training process
    Results of prediction, difference, compression
    Compression rate of each method

## Part 1: Model Optimization

    Time Denpendency (taps) - 1:1:10, 12:4:32
    Over-Fitting (epochs) - 1000, 2000, 4000, 5000, 7500, 10000, 20000

## Part 2: Experiments

### Noise Robustness - Noise Rate

    Types - Easy, Difficult
    Noise - 0.05, 0.1, 0.15, 0.2

### Memory Efficiency - Quantization

    Bitwidth - 4, 8, 12, 16, 32

## Part 3: Efficient Real-time Hardware Implementation - Area and Power Consumption
    
    System Frequency - 100, 200, 333, 500kHz, 1, 2, 5, 10, 20, 50, 100, 200, 500, 667MHz, 1GHz


## Logs

### Running the LNN baseline

Run `./scripts/run_baseline_lnn.sh [taps]` to train the LNN for 4,000 epochs.
Each run creates a uniquely named directory under `output/`, including the
dataset, method, tap count, epoch count, and run timestamp. The run directory
contains `prediction_errors.csv` (sample index, true value, predicted value,
and true-minus-predicted difference), the trained model checkpoint (`.npz`), and `compression_summary.csv`.

### Sweeping LNN epochs and taps

Run `./scripts/run_sweep.sh` to test epochs `1000, 2000, 4000, 5000, 7500,
10000, 20000` for tap counts `1:1:10` and `12:4:32` (inclusive ranges).
Every run retains its normal run directory and artifacts. A separate
timestamped `output/optimization/*_lnn_sweep_*.csv` records the method, taps,
epochs, compression rate (CR), encoded bits, sample count, and paths to that
run's directory and compression summary. Each trial's model checkpoint,
prediction errors, compressed residuals, and compression summary are also
stored in its own timestamped directory under `output/optimization/`. The
aggregate CSV is updated after each run so completed results remain available
if a later run fails.

Pass `--epochs` and `--taps` to override the defaults, for example:
`./scripts/run_sweep.sh --epochs 1000,2000 --taps 1:1:4,12:4:16`.
Tap ranges use `start:step:stop` notation; the stop is included when the
sequence reaches it. Use `--output-csv PATH` to override the aggregate CSV path.

The Python workflow follows `LNNT-AP/LNN_analyzer.m`: LNN training uses the
first 2,000 signed 9-bit samples, divided by 128, with the same lagged inputs
and targets used during inference. Predictions are converted back to signed
9-bit values, and rounding follows MATLAB's halfway-away-from-zero behavior.
The initial tap predictions use zero. DPCM1 and DPCM2 use first- and
second-order differences. Golomb coding chooses a modulus independently for
each 50,000-sample block and reports compression as a percentage against a
9-bit-per-sample input: `CR = 100 * (1 - encoded_payload_bits / (9 * samples))`.
This MATLAB-style compression rate (CR) is payload-only: it excludes the
container header and per-block modulus metadata. Each run
writes `residuals.agc`, containing the `AGC1` header, sample count, block size,
payload bit count, block moduli, and the MSB-first byte-packed Golomb payload.
Any unused low bits in the last payload byte are padding. Each run also writes
`compression_summary.csv` with the encoded size, compression ratio (CR), and
paths to its prediction/error CSV and compressed file.

### Running the DPCM comparison

Run `./scripts/run_baseline_dpcm.sh` to process
`dataset/C_Easy1_noise01.mat` with DPCM1 and DPCM2. Each method writes its
predictions and differences to `prediction_errors.csv` in its run directory,
along with the compressed residual payload. A timestamped
`output/C_Easy1_noise01_dpcm_compression_*.csv` records the CR, encoded payload
size, and paths to each method's prediction and compressed files. DPCM
calculation and comparison logic are kept together in `src/dpcm.py`.