# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

**CRITICAL: Do NOT modify any code unless explicitly asked to do so by the user.**

## Project Overview

This is a replication package for an economics paper submitted to the Review of Economic Studies. The code implements an **Overlapping Generations (OLG) model** with heterogeneous agents in Fortran. The model simulates pension system transitions, demographic changes, and policy reforms.

## Repository Structure

```
emeryt/
├── *.f90              # Fortran source files (main model code)
├── Instructions/      # Scenario switch configuration files
├── Parameters/        # Scenario parameter files
├── Data/              # Input data files (demographics, tax rates, etc.)
├── Results/           # Output files organized in scenario subfolders
│   ├── base_all_govt__/    # Results for base_all_govt__ scenario
│   ├── psid_ndm_govt__/    # Results for psid_ndm_govt__ scenario
│   └── ...
├── 5Gtrans.sln        # Visual Studio solution file
└── 5Gtrans.vfproj     # Intel Fortran project file
```

## File Naming Convention

Configuration and output files follow the pattern: `xxxx_yyy_govt__suffix.txt`

Where:
- **xxxx** = Version identifier (scenario type)
  - `base` = Baseline scenario
  - `psid` = PSID-calibrated model
  - `busn` = Business income variant
  - `beqs`/`beqx` = Bequest variants
  - `time` = Time-varying parameters
  - `nbus` = No business income
  - `gcbo` = CBO parameters
  - `hrat` = Hours ratio variant
  - `ndel`/`nhtm`/`nstr` = Other model variants
  - `crr1` = CRR calibration
  - `exor` = External rate
  - `test` = Testing configuration

- **yyy** = Experiment identifier (what varies in transition)
  - `all` = All changes active
  - `ndm` = No demographic changes
  - `ndo` = No debt changes (open economy)
  - `nds` = No debt changes (small open economy)
  - `non` = No changes (counterfactual)
  - `sub` = Subsidy variant
  - `ncp`/`ncs` = No consumption changes
  - `ndp`/`nth`/`ntk`/`ntl`/`ntp`/`nts`/`ntx`/`ntc` = Various "no change" experiments
  - `nga`/`nlb`/`nls`/`nsh` = Other counterfactuals

- **govt** = Closure rule (always `govt__` in current setup)

Examples:
- `base_all_govt__instructions.txt` = Baseline with all changes, government closure
- `psid_ndm_govt__parameters.txt` = PSID calibration, no demographics, government closure

## Core Program Flow

1. **Entry Point**: `main.f90` (`program olg2`)
   - Sets paths: `cwd_i` (Instructions), `cwd_p` (Parameters), `cwd_r` (Data), `cwd_w` (Results)
   - Sets scenario strings: `version`, `experiment`, `closure`
   - Creates scenario subfolder: `cwd_scenario` = `Results/{version}{experiment}{closure}`
   - Calls `globals` subroutine to load configuration
   - Allocates transition arrays
   - Includes `main_base_transition.f90` for computation logic

2. **Computation Flow** (in `main_base_transition.f90`):
   - Computes INITIAL steady state (`param_ss=0`) if `switch_run_1=1`
   - Computes FINAL steady state (`param_ss=1`) if `switch_run_2=1`
   - Computes TRANSITION path if `switch_run_2=1` and `switch_run_t=1`

3. **Output**: Results written to scenario subfolder `Results/{version}{experiment}{closure}/`

## Instructions Files Format

Located in `Instructions/` folder. **Order of lines matters** - must match read order in `set_globals.f90`.

```
Line 1:  switch_mortality             (demographic projection method)
Line 2:  switch_go_to_lower_gamma     (TFP convergence)
Line 3:  switch_change_tauL           (labor tax changes)
Line 4:  switch_change_tauC           (consumption tax changes)
Line 5:  switch_change_lambda         (bequest tax changes)
Line 6:  switch_change_tauK           (capital tax changes)
Line 7:  switch_steady_demo           (steady state demographics)
Line 8:  switch_sigma2_epsilon_t      (time-varying income risk)
Line 9:  switch_change_premium        (skill premium changes)
Line 10: switch_change_type_share     (education share changes)
Line 11: switch_change_sl             (labor supply changes)
Line 12: switch_change_depr           (depreciation changes)
Line 13: switch_change_contrib        (pension contribution changes)
Line 14: switch_change_rho            (replacement rate changes)
Line 15: switch_keep_fixed            (hold variables fixed)
Line 16: switch_het_mortality         (heterogeneous mortality)
Line 17: switch_labor_choice          (endogenous labor)
Line 18: switch_cohort_ps             (cohort pension system)
Line 19: switch_fix_labor             (fixed labor supply)
Line 20: switch_tauK_gross            (gross vs net capital tax)
Line 21: switch_unequal_bequest       (bequest distribution)
Line 22: switch_epsilon_corr          (earnings shock correlation)
Line 23: switch_income_risk           (income risk specification)
Line 24: switch_discount_risk         (discount factor heterogeneity)
Line 25: switch_return_risk           (return risk specification)
Line 26: switch_run_1                 (run initial steady state)
Line 27: switch_run_2                 (run final steady state)
Line 28: switch_run_t                 (run transition path)
Line 29: switch_param_1               (param set 1 - always 0)
Line 30: switch_param_2               (param set 2 - always 1)
Line 31: switch_ss_write              (write steady state output)
Line 32: switch_profile               (profiling mode)
Line 33: switch_small_write           (write compact output)
Line 34: switch_exog_rate             (exogenous interest rate)
```

Format per line: `VALUE // comment`

## Parameters Files Format

Located in `Parameters/` folder. **Order of lines matters** - must match read order in `set_globals.f90`.

```
Line 1:  n_iter_ss          (max steady state iterations, e.g., 300)
Line 2:  n_iter_t           (max transition iterations, e.g., 15)
Line 3:  n_iter_prof        (max profile iterations, e.g., 15)
Line 4:  err_ss_tol         (steady state tolerance, e.g., 1e-7)
Line 5:  err_tol            (transition tolerance, e.g., 1e-4)
Line 6:  err_prof_tol       (profile tolerance, e.g., 1e-5)
Line 7:  up_ss              (steady state update weight, e.g., 0.6d0)
Line 8:  up_t               (transition update weight, e.g., 0.6d0)
Line 9:  up_debt_t          (debt update weight, e.g., 0.0d0)
Line 10: up_tc              (consumption tax update, e.g., 0.6d0)
Line 11: l_bound            (lower bound, e.g., 50.0d0)
Line 12: delta              (discount factor, e.g., 1.010d0)
Line 13: theta              (risk aversion, e.g., 1.5d0)
Line 14: alpha              (capital share, e.g., 0.35d0)
Line 15: depr               (depreciation rate, e.g., 0.05d0)
Line 16: rho_subst          (substitution elasticity, e.g., 1.00d0)
Line 17: phi                (labor disutility, e.g., 0.33d0)
Line 18: disutil            (disutility parameter, e.g., 3.0d0)
Line 19: frisch             (Frisch elasticity, e.g., 1.0d0)
Line 20: tc_ss              (consumption tax SS, e.g., -0.0674225d0)
Line 21: g_share_ss         (government share, e.g., 0.5d0)
Line 22: switch_fix_retirement_age (retirement age switch)
Lines 23-26: superstar_factor_mat (if n_superstar > 0)
Lines 27-30: superstar_pi_mat (transition probabilities)
Line 31: a_l                (asset grid lower bound)
Line 32: a_u                (asset grid upper bound)
Line 33: a_grow             (asset grid growth rate)
Line 34: aime_l             (AIME lower bound)
Line 35: aime_u             (AIME upper bound)
Line 36: aime_cap           (AIME cap)
Line 37: zeta_d             (discount shock persistence)
Line 38: sigma_nu_d         (discount shock variance)
Line 39: zeta_r             (return shock persistence)
Line 40: sigma_nu_r         (return shock variance)
Line 41: labor_constant     (fixed labor value)
Line 42: delta_half_width   (delta distribution width)
Line 43: htm_shock_freq     (hand-to-mouth shock frequency)
Line 44: beq_age            (bequest receipt age)
Line 45: zipf               (Zipf distribution parameter)
Lines 46-47: zeta_p         (productivity persistence by type)
Lines 48-49: sigma2_fix     (fixed variance by type)
Line 50: nu_ss_old          (old SS productivity)
Line 51: nu_ss_new          (new SS productivity)
```

## Data Files

Located in `Data/` folder. Key files include:

- `_data_Nn_US_*.txt` - Population by age over time
- `_data_pi_*.txt` - Survival probabilities (conditional)
- `_data_omega_*.txt` - Age-efficiency profiles
- `_data_sigma2eps_*.txt` - Earnings shock variances
- `_data_gamma*.txt` - TFP growth rates
- `_data_tau*.txt` - Tax rate time series (L, K, C)
- `_data_lambda.txt` - Bequest tax rates
- `_data_skill_premium.txt` - College wage premium
- `_data_college_share.txt` - Population share by education
- `_data_contrib*.txt` - Pension contribution rates
- `_data_depr.txt` - Depreciation rates
- `_data_rho_*.txt` - Pension replacement rates
- `_data_type_share.txt` - Education type shares
- `_data_type_multiplier.txt` - Type-specific multipliers

## Key Modules and Files

| File | Purpose |
|------|---------|
| `main.f90` | Entry point, path setup, memory allocation |
| `main_base_transition.f90` | Included file with computation logic |
| `globals.f90` | Global variable declarations (`global_vars` module) |
| `set_globals.f90` | Parameter loading (`global_vars2` module, `globals` subroutine) |
| `steady_state.f90` | Steady state solver (`steady` subroutine) |
| `transition.f90` | Transition path solver (`transition_path_DB` subroutine) |
| `data.f90` | Data file loading (`read_data` subroutine) |
| `pfi_household_problem.f90` | Policy function iteration for households |
| `pfi_agregation.f90` | Aggregation routines |
| `pfi_distribution.f90` | Distribution calculations |

## Running the Model

1. **Configure scenario**: Set `version`, `experiment`, `closure` strings in `main.f90`
2. **Ensure matching files exist**:
   - `Instructions/{version}{experiment}{closure}instructions.txt`
   - `Parameters/{version}{experiment}{closure}parameters.txt`
3. **Compile**: Use Intel Fortran Compiler (ifort) via Visual Studio solution
4. **Run**: Execute compiled binary; results appear in `Results/{scenario}/` subfolder

## Output Files

Output files are written to scenario-specific subfolders: `Results/{version}{experiment}{closure}/`

Example: Running `base_all_govt__` scenario creates `Results/base_all_govt__/` containing:

### Time Series Outputs (`*_trans.txt`)
- `gdp_trans.txt` - GDP over transition
- `r_trans.txt` - Interest rate
- `bigK_trans.txt` - Aggregate capital
- `bigl_trans.txt` - Aggregate labor
- `debt_trans.txt` - Government debt
- `replacement_trans.txt` - Pension replacement rate

### Distributional Outputs (`*_trans.csv`)
- `c_j_trans.csv` - Consumption by age
- `l_j_trans.csv` - Labor by age
- `b_j_trans.csv` - Benefits by age
- `mass_trans_small.csv` - Population distribution
- `gini_weight_trans.csv` - Gini coefficient weights

### Steady State Outputs
- `steadys_old_information_run.txt` - Initial steady state info
- `steadys_new_information_run.txt` - Final steady state info

### Run Information
- `information.txt` - Switch and parameter settings used for the run

## Important Notes for AI Assistants

1. **DO NOT modify code** unless explicitly requested
2. **Line order matters** in Instructions and Parameters files - changes must preserve order
3. **Naming consistency**: Always use exact naming pattern `xxxx_yyy_govt__suffix`
4. **Global variables**: Model uses extensive shared state via `use global_vars`
5. **Mixed indexing**: Age uses `1:bigJ`, assets use `0:n_a`, time uses `1:bigT`
6. **Steady state pairs**: Variables have `_ss_old` and `_ss_new` versions
7. **Switch values**: Usually 0=off, 1=on, but some have multiple values (e.g., `switch_mortality` can be 1 or 6)

## Copilot Instructions Reference

See `.github/copilot-instructions.md` for additional technical details about:
- Core architecture patterns
- Scenario control and switches
- Computational patterns (iterative convergence)
- Memory and indexing conventions
- I/O path conventions
- Safety and performance notes
