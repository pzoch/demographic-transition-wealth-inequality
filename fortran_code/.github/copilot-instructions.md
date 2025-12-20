# AI Coding Agent Instructions for `emeryt`

These guidelines make an AI immediately productive in this Fortran OLG model project. Focus on existing patterns; do not introduce new paradigms unless asked.

## Core Architecture
- Entry point: `program olg2` in `main.f90`; it sets paths (`cwd_r`, `cwd_w`, `cwd_i`, `cwd_p`), initializes switch strings (`version`, `experiment`, `closure`), calls `globals` + `clear_globals`, allocates transition arrays, then `include 'main_base_transition.f90'` to run computations.
- Global state lives in modules `global_vars` (`globals.f90`) and `global_vars2` (`set_globals.f90`). Most routines rely on wide shared arrays; prefer reading/writing through existing global variables rather than passing large argument lists.
- Two major phases: steady state (`steady_state` module, subroutine `steady`) and transition path (`transition_DB` module, subroutine `transition_path_DB`). Steady state outputs serve as initial boundary conditions for transition.
- Data ingestion: `get_data` (`data.f90`) loads time‑series, demographic, shock distributions from `Data/` files into global arrays (e.g. `pi_big`, `omega_ss`, tax paths). Changes to data format must mirror existing OPEN/read loops.
- Household / micro state grids: dimensions defined in `global_vars` (`bigJ`, `bigM`, `n_a`, `n_aime`, `n_sp`, `n_sr`, `n_sd`, `bigT`). Arrays often shaped like `(bigJ,0:n_a,0:n_aime,n_sp,n_sr,n_sd,bigT)` or with `bigM` appended. Reuse constants—never hard-code numbers.

## Scenario Control & Switches
- Scenario behavior controlled by numerous integer switches in `global_vars` (e.g. `switch_sigma2_epsilon_t`, `switch_change_tauL`, `switch_labor_choice`, `switch_persistent_delta`, `switch_het_mortality`). Adjust switches before calling core routines; avoid modifying them mid‑iteration unless a routine already expects it.
- Parameter sets: dual steady states distinguished by "old" vs "new" suffix variables (`*_ss_old` / `*_ss_new`). The `param_ss` argument (0/1) in `steady` chooses which set to use; same pattern in transition with `param`.
- Variant identifiers (`version`, `experiment`, `closure`) are simple `character` tags used to select file I/O variants—keep naming consistent; adding a new variant usually requires branching where these strings are interpreted (search for their usage first).
- **CRITICAL**: `switch_residual` parameter (not in globals): Controls government budget closure in `steady` and `transition_path_DB`. Values: `0`=upsilon (lump‑sum transfer) residual, `1`=tC (consumption tax) residual, `2`=debt residual, `6`=g (government spending) residual. This parameter is **missing** from `main_base_transition.f90` calls—must be passed explicitly. See `closure_ss.f90` (steady state) and `closures.f90` (transition) for closure logic implementation.
- Related switches passed to steady/transition: `switch_tauK_gross` (0=net capital tax, 1=gross), `switch_unequal_bequest` (0/1/2 for bequest distribution variants), `switch_type` (0=PAYG, 1=FF pension system).

## Computational Patterns
- Iterative convergence: Steady state iterates until `err_ss` < tolerance; transition loops accumulate errors in arrays like `cum_err`. When adding new endogenous variables, integrate them into existing error aggregation rather than creating a separate termination condition.
- Optimization: `solver.f90` supplies Brent‑style line minimization (`fmin`) and custom objective (`uncertainty`). Reuse these for one‑dimensional searches; do not re‑implement numerical minimizers.
- Probability / shock evolution: Cohort/time specific grids (`pi_ip_*`, `sigma2_epsilon_t_big`) are prepared in `global_vars` and filled either in `get_data` or setup routines. Maintain naming convention: `_ss_old/_new` for steady, `_trans` for transition path, `_big` when `bigM` dimension present.
- Bequests & pension system: Variables like `pillarI_ss_j`, `b1_ss_j`, `bequest_ss_j` handled inside `steady`. For transition, analogous `pillarI_j`, `b1_j` etc. Extend by adding fields in the same grouped sections (search for `pillarI` occurrences for placement).

## Memory & Indexing Conventions
- Mixed indexing: Age/cohort loops use `1:bigJ`; asset grids use `0:n_a`; AIME grids use `0:n_aime`; time uses `1:bigT` unless lifetime arrays extend to `-bigJ:bigT` (e.g. `life_exp`). Respect these ranges—off‑by‑one errors can silently corrupt results.
- Allocation pattern: Main allocates transition arrays using `allocate(..., source = svplus_trans)` to copy shape; replicate this style when introducing parallel arrays for new variables.

## I/O and Paths
- Paths built from `getcwd()` then concatenated with forward slashes (`trim(cwd)//"/Data"` etc.) even on Windows—retain this separator style for consistency.
- Data files: Named `_data_*.txt` and read with simple formatted reads inside nested loops. When adding a dataset, follow the existing OPEN, loop over `m`, `j`, or `i`, then CLOSE pattern.
- Output matrices controlled by `switch_ss_write` / `switch_small_write` / `switch_print`. Gate new large writes behind one of these switches or introduce a parallel switch following naming style (`switch_*`).

## Extending Functionality
- New numerical routines: Place in a dedicated module (e.g. `matrixtools`, `rootfinding`) rather than embedding in `main`. Add `use global_vars` only if global state is required; otherwise keep modules lightweight to reduce coupling.
- New scenario parameter: Define both `*_ss_old` and `*_ss_new` versions plus transition path vector if time‑varying; update selection logic in steady/transition routines (`if (param_ss == 0) then ... else ...`).
- Avoid modifying `include 'main_base_transition.f90'` blindly—inspect it first (included into `main` after allocations). Any new arrays needed there must be allocated before the `include` line.

## Safety / Performance Notes
- Large array operations are memory intensive—prefer in‑place updates and avoid temporary whole‑array copies. If introducing vectorized loops, ensure bounds match the mixed indexing scheme.
- Do not rename modules or change public variable names casually; widespread implicit usage (via `use global_vars`) makes refactoring risky.
- Keep printing minimal; wrap debug output with `if (switch_print == 1) write(*,*) ...`.

## Quick Start Flow (Agent Actions)
1. Set or adjust scenario switches & variant strings in `main.f90` before `call globals` if introducing new behavior.
2. Load data via `read_data` (invoked inside broader setup—confirm invocation path before duplicating).
3. Call `steady` for each parameter set as needed (param_ss=0/1) to establish boundary states. **Must pass `switch_residual` as first argument** (currently missing in `main_base_transition.f90`).
4. Execute transition via `transition_path_DB` with appropriate `param` selection. **Must pass `switch_residual` as first argument**.
5. Write results guarded by existing switches to `Results/`.

## Function Signatures (Critical Reference)
```fortran
! Steady state - note switch_residual is FIRST parameter
subroutine steady(switch_residual, switch_tauK_gross, switch_unequal_bequest, param_ss, switch_type, ...)

! Transition path - note switch_residual is FIRST parameter  
subroutine transition_path_DB(switch_residual, switch_tauK_gross, switch_unequal_bequest, param, ...)
```

Please review: Are any key workflows (calibration loop, bequest mechanisms, or profiling routines) missing or unclear? Provide feedback and I will refine.
