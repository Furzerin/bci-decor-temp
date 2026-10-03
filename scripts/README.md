# Experiment Scripts 

## Part 0: Baseline - Decorrelation

    Variation of loss matrics through the training process
    Results of prediction, difference, compression
    Compression rate of each method

## Part 1: Model Optimization

### Step 1: Time Denpendency - Data Taps

### Step 2: Over-Fitting - Epochs

## Part 2: Experiments

### Step 1: Noise Robustness - Noise Rate

### Step 2: 

## Part 3: 

## Running the LNN baseline

Run `./scripts/run_baseline_lnn.sh [taps]` to train the LNN for 20,000 epochs.
Each run creates a uniquely named directory under `output/`, including the
dataset, method, tap count, epoch count, and run timestamp. The run directory
contains `prediction_errors.csv` (sample index, true value, predicted value,
and true-minus-predicted difference) and the trained model.

The Python workflow follows the reference implementation in `LNNT-AP`: LNN
training uses the first 2,000 raw signal samples, predictions and true values
are scaled to signed 9-bit values using the 255/−256 normalization rule, and
rounding follows MATLAB's halfway-away-from-zero behavior. The initial tap
predictions use zero. DPCM1 and DPCM2 use first- and
second-order differences. Golomb coding chooses a modulus independently for
each 50,000-sample block and reports compression as a percentage against a
9-bit-per-sample input: `CR = 100 * (1 - encoded_payload_bits / (9 * samples))`.
This MATLAB-style compression rate (CR) is payload-only: it excludes the
container header and per-block modulus metadata. Each run
writes `residuals.agc`, containing the `AGC1` header, sample count, block size,
payload bit count, block moduli, and the MSB-first byte-packed Golomb payload.
Any unused low bits in the last payload byte are padding.

## Running the DPCM comparison

Run `./scripts/run_baseline_dpcm.sh` to process
`dataset/C_Easy1_noise01.mat` with DPCM1 and DPCM2. Each method writes its
predictions and differences to `prediction_errors.csv` in its run directory,
along with the compressed residual payload. A timestamped
`output/C_Easy1_noise01_dpcm_compression_*.csv` records the CR, encoded payload
size, and paths to each method's prediction and compressed files. DPCM
calculation and comparison logic are kept together in `src/dpcm.py`.