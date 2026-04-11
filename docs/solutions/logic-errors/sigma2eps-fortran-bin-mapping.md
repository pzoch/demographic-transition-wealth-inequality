---
status: solved
priority: p1
category: logic-errors
tags: [matlab, fortran, mapping, sigma2-epsilon, income-process]
module: estimate_parameters.m
symptoms: ["sigma2eps output doesn't match reference", "wrong cohort bins exported to Fortran"]
date_solved: 2026-03-04
---

# Sigma2_epsilon Bin-to-Fortran Mapping

## Problem Statement

MATLAB estimates 12 five-year cohort bins of `sigma2_epsilon` (bins 1-12, cohorts 1926-1981). Fortran needs 15 values per education type. The initial mapping was wrong, producing values that didn't match the reference files.

## Root Cause

**Wrong mapping (first attempt):** Pad bin 1 five times, then use bins 2-11, dropping bin 12.

**Correct mapping:** Drop bin 1 (1926 cohort — fewest observations, unreliable), repeat bin 2 five times (pre-data padding for 1935-1959), then use bins 3-12.

## Working Solution

```matlab
first_export_bin = 2;    % bin 1 = 1926 is dropped (unreliable)
n_pad            = 5;    % repeat first exported bin 5 times

sig_col = sigma2_epsilon_point(:);  % ensure column vector
sigma2eps_fortran(:, itype) = [ ...
    repmat(sig_col(first_export_bin), n_pad, 1); ...   % periods 1-5  (1935-1959)
    sig_col(first_export_bin+1:end) ];                  % periods 6-15 (1960-2009)
```

## Fortran Read Order

File has 30 lines: lines 1-15 = H (college), lines 16-30 = L (no college).

```fortran
do m = 1, bigM          ! m=1 is H, m=2 is L
    do i = 1, last_data_sigma2_epsilon   ! 15
        read(11,*) sigma2_epsilon_data(m, i)
    end do
end do
```

Fortran parameters: `start_year = 1935`, `break_index = 5` (1955), `last_data_sigma2_epsilon = 15`.

## Verification

Output matches reference within ~1e-8 relative error (MATLAB optimizer precision).
