---
status: solved
priority: p2
category: integration-issues
tags: [stata, matlab, fortran, pipeline, reproducibility, income-process, calibration]
module: estimate_income_process.do, estimate_parameters.m
symptoms: ["can't remember which script combination produced final data files", "hardcoded absolute paths", "manual variant switching required"]
date_solved: 2026-03-05
---

# Income Process Estimation Pipeline Consolidation

## Problem Statement

The income process calibration pipeline was spread across 4 scripts on Dropbox with:
- Hardcoded absolute paths (`G:/TempDrop/`, `D:/EJ_Bootstrap/`)
- Variant names edited by hand in `local` statements across multiple files
- An `exit` statement mid-script blocking downstream code
- No clear documentation of which script combination produced the final output

Two variants needed for the paper:
- `mostdrop_hhslabinc` — baseline (psid_ scenarios)
- `busno_drop_hhslabinc` — robustness App. F.4 (nstr_ scenarios)

## Working Solution

Replaced 4 fragile scripts with 2 consolidated scripts that loop over all variants automatically:

### 1. `estimate_income_process.do` (Stata)
Merges 3 Stata scripts into one pipeline:
- **Stage 1**: PSID sample selection (income definition, deflation, cleaning, variant-specific filtering)
- **Stage 2**: Deaton APC decomposition (age effects → omega txt)
- **Stage 3**: 5-year binned covariance matrices (for MATLAB)

Configuration:
```stata
local variants      mostdrop_hhslabinc busno_drop_hhslabinc
local measure       avghourlyhh
local n_reps        0    // 0 = point only, 1000 = full bootstrap
```

### 2. `estimate_parameters.m` (MATLAB)
Consolidated ML estimation script:
```matlab
variants = {'mostdrop_hhslabinc', 'busno_drop_hhslabinc'};
n_reps   = 0;    % 0 = point only, 1000 = full bootstrap
```

### Output Structure
```
output/{variant}/
├── _data_omega_{variant}_avghourlyhh.txt       ← Fortran input
├── _data_sigma2eps_{variant}_avghourlyhh.txt    ← Fortran input
├── H.mat, L.mat                                 ← Full estimation results
├── psid_{variant}_avghourlyhh.dta               ← Cleaned sample
└── cov_binned/                                  ← Covariance matrices
```

### Running the Pipeline

**One-click** (batch mode, requires no interactive Stata running):
```
run_estimation.bat
```

**Or manually:**
```stata
cd "D:\Emeryt_local\calibration\income_process"
do estimate_income_process.do
```
Then in MATLAB:
```matlab
cd D:/Emeryt_local/calibration/income_process
estimate_parameters
```

MATLAB auto-copies omega + sigma2eps to `../../emeryt/Data/` — no manual copy step.

### Directory Structure (final)
```
calibration/
├── psid/
│   ├── psid.dta                       # Raw PSID (94MB)
│   └── psid_read.R                    # Reference: how psid.dta was built
└── income_process/
    ├── estimate_income_process.do      # Stata: psid.dta → omega + covariances
    ├── estimate_parameters.m           # MATLAB: covariances → sigma2eps → auto-copy
    ├── run_estimation.bat              # One-click pipeline
    ├── matlab/                         # MATLAB helpers
    └── output/{variant}/               # All outputs per variant
```

Old reference scripts (`prepare_psid/`, `deaton/`, `covariance_matrices_binned/`) deleted — consolidated scripts are the single source of truth. Originals remain on Dropbox for archaeological purposes.

## Verification

All 4 output files verified against existing Fortran `Data/` files:
- Omega files: **exact match**
- Sigma2eps files: **~1e-8 relative error** (optimizer precision)

## Key Gotchas

1. `program define ... end` must be OUTSIDE `foreach` loops in Stata (see stata-program-define-inside-foreach.md)
2. Sigma2eps mapping drops bin 1 (1926), pads bin 2 five times (see sigma2eps-fortran-bin-mapping.md)
3. `mat2txt` Stata package required — script auto-installs if missing
4. Stata single-user license prevents batch + interactive sessions simultaneously — close interactive Stata before running `run_estimation.bat`
5. MATLAB helper functions (`loader.m`, `objective_cohort_binned.m`, `create_parameters_binned.m`) must be in `matlab/` subdirectory — script calls `addpath('matlab')`
6. MATLAB auto-copies outputs to `../../emeryt/Data/` — path is relative, so must run from `income_process/` directory
