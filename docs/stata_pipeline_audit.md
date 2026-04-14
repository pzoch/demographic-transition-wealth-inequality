---
title: Stata pipeline audit
date: 2026-04-14
scope: inputs_stata_code/, outputs_stata_code/, sensitivity_stata_code/
source_brainstorm: docs/brainstorms/2026-04-13-stata-pipeline-audit-brainstorm.md
source_plan: docs/plans/2026-04-13-refactor-stata-pipeline-audit-plan.md
constraint: read-only with respect to all existing .do, .dta, .stpr files
---

# Stata Pipeline Audit

## 1. Purpose and scope

This document is a read-only audit of the three Stata folders in the replication package:

- [inputs_stata_code/](../inputs_stata_code/) — produces `_data_*.txt` inputs consumed by the Fortran model.
- [outputs_stata_code/](../outputs_stata_code/) — produces paper figures from Fortran model results.
- [sensitivity_stata_code/](../sensitivity_stata_code/) — robustness inputs used by the sensitivity runs.

The audit answers, once and authoritatively, four questions:

1. Which files are reachable from a driver (`__main_data_prepare.do` or `__main.do`) and which are not.
2. What each reachable script reads and writes.
3. Whether the drivers actually run end-to-end today, in a clean sandbox, without manual intervention.
4. Where the integration gaps are, ranked by priority, so a future session can act on them.

No existing `.do`, `.dta`, or `.stpr` file was modified during the audit. No `.gitignore` changes were made. All integration fixes appear below as TODOs, not commits.

## 2. Static call graph

### 2.1 `inputs_stata_code/__main_data_prepare.do`

Driver source: [inputs_stata_code/__main_data_prepare.do](../inputs_stata_code/__main_data_prepare.do)

```
__main_data_prepare.do
├── _prepare_programs.do                     (defines programs: periods, drawing, special_drawing, special_drawing2; saves bone.dta, bone1y.dta in cwd)
├── depreciation/M01prepare_depr.do          (writes ../fortran_code/data/_data_depr.txt)
├── tfp/M02prepare_gamma.do                  (writes ../fortran_code/data/_data_gamma.txt)
├── labor_share/M03prepare_labor_share.do    (writes ../fortran_code/data/_data_lab_share.txt)
├── ../sensitivity_stata_code/exog_rate/M04prepare_exog_rate.do   (robustness; writes _data_irr.txt, not frozen)
├── skill_premium/H01prepare_skill_premium.do (writes ../fortran_code/data/_data_skill_premium.txt)
├── skill_premium/D02_prepare_college.do     (writes ../fortran_code/data/_data_college_share.txt)
├── tax_rate/T01prepare_taxes.do             (writes _data_tC.txt, _data_tK.txt, _data_tL.txt via $var loop)
├── social_security/T02prepare_contributions.do (writes ../fortran_code/data/_data_contributions.txt)
├── tax_rate/T03prepare_tax_lambda.do        (writes ../fortran_code/data/_data_lambda.txt)
└── (erases bone.dta, bone1y.dta at end)
```

**Not called** from this driver, but present in `inputs_stata_code/`:

- `demography/mortality/D01_life_tables.do` — called only from `__main.do` Appendix C.
- `demography/hetero_pi/D03_prepare_hetero_pi.do` — called only from `__main.do` Appendix C.
- `income_process/estimate_income_process.do` — standalone pipeline, invoked via a separate MATLAB+Stata driver (`run_estimation.bat`), intentionally isolated.
- `tfp/M02robustness_prepare_gamma.do` — writes `_data_gamma_robustness.txt`; called **indirectly** from `__main.do` Appendix F, but via a broken path (see 2.3).
- `r_sd/R01compare_r_sd.do` — exploratory, no caller anywhere.
- `skill_premium/AutorGoldinKatz2020/**` — third-party vendor code for Autor-Goldin-Katz figure reproduction, not wired into either driver.

### 2.2 `outputs_stata_code/__main.do`

Driver source: [outputs_stata_code/__main.do](../outputs_stata_code/__main.do)

```
__main.do
├── _prog_coding.do
├── _prog_ineq_function.do
├── _prep_Gini_data.do
│
├── [Main-text figures]
│   ├── R_Figure1.do
│   ├── R_Figure2.do         (invoked 6× with different variant_base/variant_comp globals)
│   └── R_Figure3.do         (invoked 5× for main text + Appendix E groups)
│
├── [Appendix B — Calibration; re-runs input helpers with $bsource="../outputs_stata_code/"]
│   ├── ../inputs_stata_code/depreciation/M01prepare_depr.do
│   ├── ../inputs_stata_code/tfp/M02prepare_gamma.do
│   ├── ../inputs_stata_code/labor_share/M03prepare_labor_share.do
│   ├── ../inputs_stata_code/skill_premium/H01prepare_skill_premium.do
│   ├── ../inputs_stata_code/skill_premium/D02_prepare_college.do
│   ├── ../inputs_stata_code/tax_rate/T01prepare_taxes.do
│   ├── ../inputs_stata_code/social_security/T02prepare_contributions.do
│   └── ../inputs_stata_code/tax_rate/T03prepare_tax_lambda.do
│
├── [Appendix C — Populations]
│   ├── ../inputs_stata_code/demography/hetero_pi/D03_prepare_hetero_pi.do
│   └── ../inputs_stata_code/demography/mortality/D01_life_tables.do
│
├── [Appendix D — Model vs Data]
│   ├── MvD_1_macro.do
│   ├── MvD_2_Gini_income.do
│   ├── MvD_3_Gini_wealth.do
│   └── MvD_4_GE_decomposition.do
│
├── [Appendix E, F — counterfactuals] R_Figure1_app.do, more R_Figure2.do / R_Figure3.do calls
│
├── ../sensitivity_stata_code/exog_rate/M02robustness_prepare_gamma   (BROKEN PATH — see 2.3)
└── ../sensitivity_stata_code/exog_rate/M04prepare_exog_rate
```

### 2.3 Broken references found by static trace

| Reference | Location | Actual file | Severity |
|---|---|---|---|
| `../sensitivity_stata_code/exog_rate/M02robustness_prepare_gamma` | [outputs_stata_code/__main.do:164](../outputs_stata_code/__main.do#L164) | [inputs_stata_code/tfp/M02robustness_prepare_gamma.do](../inputs_stata_code/tfp/M02robustness_prepare_gamma.do) | **P1** — would crash `__main.do` at Appendix F.5 |
| `$bsource/bone` with `$bsource=""` | [inputs_stata_code/depreciation/M01prepare_depr.do:28](../inputs_stata_code/depreciation/M01prepare_depr.do#L28) | expands to `/bone.dta`, file-not-found in batch | **P0** — blocks the entire input driver in batch mode |

## 3. Per-file status table

Legend:
- **live** — reached from a driver, writes an input to the Fortran model or a paper output.
- **helper** — defines programs or helper data used by live files (e.g. `_prepare_programs.do`).
- **orphan** — no caller found by grep, produces no Fortran or paper output.
- **stale-duplicate** — parallel variant of a live file, no caller.
- **temp-intermediate** — written during a driver run and erased before exit.
- **binary-workspace** — `.stpr` Stata project file, opaque Java-serialized state.
- **pre-seeded** — committed input consumed by a driver rather than produced.
- **tracked-input-data** — tracked `.dta` serving as pickled source data (e.g. `depreciation.dta`).
- **vendor** — third-party code (Autor-Goldin-Katz replication kit), self-contained.

### 3.1 `inputs_stata_code/`

| Path | Kind | Status | Confidence | Note |
|---|---|---|---|---|
| `__main_data_prepare.do` | driver | live | high | Fortran-input pipeline driver |
| `_prepare_programs.do` | helper | helper | high | Defines programs + seeds `bone.dta` / `bone1y.dta` |
| `main.stpr` | Stata project | binary-workspace | high | Unreviewable; should probably be gitignored |
| `depreciation/M01prepare_depr.do` | script | live | high | Writes `_data_depr.txt` |
| `depreciation/depreciation.dta` | data | tracked-input-data | high | Pickled PWT depreciation series (origin: dbnomics, commented out) |
| `tfp/M02prepare_gamma.do` | script | live | high | Writes `_data_gamma.txt` |
| `tfp/M02robustness_prepare_gamma.do` | script | orphan-but-intended | medium | `__main.do:164` tries to call it via broken path (see 2.3) |
| `tfp/gamma.dta` | data | tracked-input-data | high | Pickled PWT TFP series |
| `labor_share/M03prepare_labor_share.do` | script | live | high | Writes `_data_lab_share.txt` |
| `labor_share/labor_share.dta` | data | tracked-input-data | high | Pickled PWT labor-share series |
| `skill_premium/H01prepare_skill_premium.do` | script | live | high | Writes `_data_skill_premium.txt` |
| `skill_premium/D02_prepare_college.do` | script | live | high | Writes `_data_college_share.txt` |
| `skill_premium/ACS_college/ACS_college.dta` | data | tracked-input-data | high | ACS college-share source |
| `skill_premium/ACS_college/processed/col_share_acs*.dta` | data | temp-intermediate | high | Regenerated by D02 |
| `skill_premium/AutorGoldinKatz2020/**` | vendor | vendor | high | Self-contained AGK 2020 replication kit |
| `tax_rate/T01prepare_taxes.do` | script | live | high | Writes `_data_tC/tK/tL.txt` in `$var` loop |
| `tax_rate/T03prepare_tax_lambda.do` | script | live | high | Writes `_data_lambda.txt` |
| `tax_rate/MTZ_model_{lambda,tC,tK,tL}_trans.txt` | data | tracked-input-data | high | Source text files read by T01/T03 |
| `social_security/T02prepare_contributions.do` | script | live | high | Writes `_data_contributions.txt` |
| `social_security/contributions.dta` | data | tracked-input-data | high | Pickled contributions series |
| `demography/mortality/D01_life_tables.do` | script | live (only via `__main.do`) | high | Writes `_data_pi_cond_US_*.txt` under `demography/mortality/output/` |
| `demography/mortality/processed/*.dta` | data | temp-intermediate | high | Regenerated by D01 |
| `demography/mortality/output/*.txt` | data | live-output | high | Fortran-consumed but written to a local `output/` folder, not `fortran_code/data/` — see TODO 5 |
| `demography/hetero_pi/D03_prepare_hetero_pi.do` | script | live (only via `__main.do`) | high | Writes `_data_het_pi_US_since1935_*.txt` under `demography/hetero_pi/output/` |
| `demography/hetero_pi/data/New_data_on_mortality.dta` | data | tracked-input-data | high | Source data for D03 |
| `demography/hetero_pi/processed/*.dta` | data | temp-intermediate | high | Regenerated by D03 |
| `demography/hetero_pi/output/*.txt` | data | live-output | high | Same asymmetry as mortality/output/ |
| `income_process/estimate_income_process.do` | script | live (standalone) | high | Driven by MATLAB+Stata `run_estimation.bat`; intentionally isolated |
| `income_process/output/mostdrop_hhslabinc/*` | data | live-output | high | Eventually copied to `fortran_code/Data/_data_sigma2eps_*.txt` etc. |
| `income_process/matlab/output/**` | data | temp-intermediate | high | MATLAB-side artifacts |
| `r_sd/R01compare_r_sd.do` | script | **orphan / exploratory** | high | No caller; produces a diagnostic `line` graph only; no Fortran output |
| `r_sd/r_sd.dta` | data | orphan-input | high | Federal Reserve net-worth shares snapshot used only by the orphan R01 |

### 3.2 `outputs_stata_code/`

| Path | Kind | Status | Confidence | Note |
|---|---|---|---|---|
| `__main.do` | driver | live | high | Paper-figures driver |
| `__main_PIOTR.do` | driver (variant) | **stale-duplicate** | high | 155-line alternate driver; references figure files that do not exist in the folder (`R_Figure4.do`, `R_Figure_AppE_Income.do`, `R_Figure_AppE_Taxes.do`, `R_Figure_AppE_Tech.do`, `R_Figure_F6_exograte.do`), so it cannot run today |
| `__replication_graphs.stpr` | Stata project | binary-workspace | high | IDE state; should probably be gitignored |
| `_prog_coding.do`, `_prog_ineq_function.do`, `_prep_Gini_data.do` | helper | helper | high | Program definitions called at top of `__main.do` |
| `R_Figure1.do`, `R_Figure1_app.do`, `R_Figure2.do`, `R_Figure3.do` | script | live | high | Figures produced for main text and appendices |
| `MvD_1_macro.do`, `MvD_2_Gini_income.do`, `MvD_3_Gini_wealth.do`, `MvD_4_GE_decomposition.do` | script | live | high | Appendix D model-vs-data figures |
| `bone.dta`, `bone1y.dta` | data | **pre-seeded** | high | Consumed by `__main.do` Appendix B re-runs via `$bsource="../outputs_stata_code/"`. Not temp files in this location — deliberately committed inputs. See TODO 2 |
| `asi_aux.dta` | data | **orphan** | high | Zero references across all `.do` files; likely stale artifact |

### 3.3 `sensitivity_stata_code/`

| Path | Kind | Status | Confidence | Note |
|---|---|---|---|---|
| `exog_rate/M04prepare_exog_rate.do` | script | live | high | Called from `__main_data_prepare.do:19` and `__main.do:175`; writes `_data_irr.txt` |
| `exog_rate/irr.dta` | data | tracked-input-data | high | Source data for M04 |
| `exog_rate/M02robustness_prepare_gamma.do` | script | **missing** | high | `__main.do:164` expects this path but the file only exists at `inputs_stata_code/tfp/M02robustness_prepare_gamma.do`. See 2.3 |

## 4. Scratch-copy dry-run results

**Sandbox location**: `n:\PROJECTS\EMERYT\_stata_sandbox_20260414\` (sibling of the repo — no in-tree execution, per user policy).

**Setup**: copied `inputs_stata_code/`, `outputs_stata_code/`, `sensitivity_stata_code/` into the sandbox. Created empty `fortran_code/data/` and `graphs/{inputs,outputs}/` at the sandbox root so that the drivers' `../fortran_code/data/...` and `../graphs/inputs/...` writes resolve inside the sandbox. No files in the real repo tree were written during the run.

**Absolute-path pre-check**: `grep -r '[A-Za-z]:[\\/]' *.do` on the sandbox returned only URLs in comments. No hard-coded drive letters. Safe to run.

**Stata version**: StataSE 16, single-user perpetual license, `C:\Program Files\Stata16\StataSE-64.exe`. Invoked in batch mode with `/e do ...`, with `MSYS_NO_PATHCONV=1` to stop Git Bash from rewriting `/e` into `E:/`.

### 4.1 `__main_data_prepare.do` — **FAILED**

Executed from `<sandbox>/inputs_stata_code/`. Full log: `<sandbox>/inputs_stata_code/__main_data_prepare.log`. Relevant tail:

```
. do depreciation/M01prepare_depr

. use depreciation/depreciation.dta, clear
. periods
        time variable:  year, 1950 to 2019
. tsfilter hp delta_cycle = delta, smooth($lam) trend(delta_trend)
. gen l_retain = log(1 - delta_trend)
. collapse (mean) l_retain (first) year, by(fiveyear)
. replace l_retain = l_retain*5
(14 real changes made)
. replace year = year + 5
(14 real changes made)
. gen depr_5 = 1 - exp(l_retain)
. drop l_retain

. merge 1:1 year using $bsource/bone
file /bone.dta not found
r(601);
end of do-file
r(601);
```

**Root cause** — `__main_data_prepare.do:15` sets `global bsource ""`. Then `M01prepare_depr.do:28` does `merge 1:1 year using $bsource/bone`, which expands to `using /bone`. Stata on Windows treats the leading `/` as an absolute path and fails to find `/bone.dta`. In the Appendix-B rerun from `__main.do`, the same M01 script works because `$bsource` is set to `"../outputs_stata_code/"`, producing the valid path `../outputs_stata_code//bone`. The standalone input driver has been silently broken for this setting for some time.

**Workaround** (do not commit in this session): set `global bsource "./"` or change M01 to handle an empty `$bsource`.

**Scope of failure**: `__main_data_prepare.do` crashes at step 1 of 10. None of the `fortran_code/data/_data_*.txt` inputs are regenerated. A handful of earlier artifacts are produced in the sandbox before the crash: `inputs_stata_code/bone.dta`, `inputs_stata_code/bone1y.dta` (both written by `_prepare_programs.do`).

### 4.2 `__main.do` — **NOT EXECUTED**

Not attempted in this audit. Reasons:

1. The input driver's failure (4.1) already demonstrates the pipeline is not runnable end-to-end in batch without manual fixes. Attempting the output driver adds no new information for the TODO list.
2. `__main.do` reads `..\fortran_code\Results\psid_all_govt__\mass_trans_small.csv` and references twenty-plus additional Fortran `Results/` scenarios. Staging these into the sandbox would require copying on the order of gigabytes of Fortran output, and each copy is a chance to accidentally diverge from the tracked state. The user's read-only / no-overwrite policy argues against a half-prepared run.
3. The Appendix-B section of `__main.do` re-invokes the same input helpers that crashed in 4.1 — but with a different `$bsource`, so it would actually succeed there. Documenting the asymmetry is more valuable than observing it again.

Verification: `git status` on the real tree after the sandbox run shows no new modifications to any file under `fortran_code/Data/`, `graphs/`, `inputs_stata_code/`, `outputs_stata_code/`, or `sensitivity_stata_code/`. The sandbox is self-contained.

## 5. Known asymmetries (documented, not bugs)

### 5.1 Demography dispatched from the output driver

`inputs_stata_code/demography/hetero_pi/` and `inputs_stata_code/demography/mortality/` contain scripts that live under `inputs_stata_code/` but are only called from `outputs_stata_code/__main.do` (Appendix C). They produce `_data_het_pi_*.txt` and `_data_pi_cond_US_*.txt` which the Fortran model reads from `fortran_code/Data/`. The current layout writes these into sub-folders `demography/*/output/` rather than directly into `../fortran_code/data/`. Someone (or some build step) then copies them into `fortran_code/Data/`. This step is not scripted anywhere in the repository.

This is not a bug per se — the demography outputs are frozen by hand and rarely change — but it means the "driver" model of the pipeline has a silent gap. Flagged as P2 below.

### 5.2 Income process is a separate pipeline

`inputs_stata_code/income_process/` is a MATLAB + Stata pipeline dispatched via `run_estimation.bat`, not from `__main_data_prepare.do`. This is intentional isolation — see [docs/solutions/integration-issues/income-process-pipeline-consolidation.md](solutions/integration-issues/income-process-pipeline-consolidation.md) if present, or the integration brainstorm for historical context. The audit records it as a known and accepted split; no change recommended.

### 5.3 Case asymmetry: `fortran_code/Data/` vs `fortran_code/data/`

The Stata scripts write to `../fortran_code/data/_data_*.txt` (lowercase). The Fortran source reads from `fortran_code/Data/` (capital D). On Windows these resolve to the same directory and the pipeline works. On any case-sensitive filesystem (Linux, macOS with case-sensitive APFS, CI runners) they are different directories and the pipeline breaks silently — Stata writes files the Fortran side cannot find. Flagged as P2 below.

## 6. Open issues — ranked TODO list

Each item is scoped for a **future** session. Nothing in this list is actioned in the current one.

### P0 — blocks end-to-end pipeline

- [ ] **Fix `$bsource` resolution in the standalone input driver.** [inputs_stata_code/__main_data_prepare.do:15](../inputs_stata_code/__main_data_prepare.do#L15) sets `global bsource ""`, which expands to the invalid path `/bone` inside [inputs_stata_code/depreciation/M01prepare_depr.do:28](../inputs_stata_code/depreciation/M01prepare_depr.do#L28) (and likely the other input helpers that share the `$bsource/bone` pattern). Two acceptable fixes: set `global bsource "."` in the driver, or drop the `$bsource/` prefix in the helpers so they merge directly against `bone.dta` in cwd. Either way, verify all helpers that touch `$bsource` after the fix.

### P1 — blocks a specific branch of the pipeline

- [ ] **Fix the broken `M02robustness_prepare_gamma` path in the output driver.** [outputs_stata_code/__main.do:164](../outputs_stata_code/__main.do#L164) calls `../sensitivity_stata_code/exog_rate/M02robustness_prepare_gamma`, but the file lives at [inputs_stata_code/tfp/M02robustness_prepare_gamma.do](../inputs_stata_code/tfp/M02robustness_prepare_gamma.do). This means Appendix F.5 (the CBO productivity-growth robustness run) fails on any clean execution. Fix is a one-line path change in `__main.do`.

- [ ] **Commit the full output driver to a dry-run.** Once the P0 fix lands, stage a scratch run of `__main.do` with a copy of `fortran_code/Results/` in the sandbox, and record which figures build cleanly versus which still error. This audit deferred that run on purpose; the follow-up should not.

### P2 — integration hygiene (not blocking, but fragile)

- [ ] **Resolve the `Data/` vs `data/` case asymmetry.** Scripts write lowercase; Fortran reads capital. Pick one, rename the tracked files, and update all `export delimited` calls. The canonical name used in the tracked outputs is `fortran_code/Data/` (capital D), so update the Stata scripts to write to `../fortran_code/Data/`.

- [ ] **Wire the demography outputs into `fortran_code/Data/`.** Today `inputs_stata_code/demography/{mortality,hetero_pi}/output/_data_*.txt` are produced by `D01_life_tables.do` and `D03_prepare_hetero_pi.do`, but the copy into `fortran_code/Data/` happens by hand. Either add a final `copy` / `!copy` step at the end of each script, or add a consolidation block to `__main_data_prepare.do` that dispatches them (they are currently only reached via `__main.do` Appendix C).

- [ ] **Decide the `bone*.dta` policy.** [outputs_stata_code/bone.dta](../outputs_stata_code/bone.dta) and [outputs_stata_code/bone1y.dta](../outputs_stata_code/bone1y.dta) are **pre-seeded inputs**, not temp files, for the Appendix B re-runs in `__main.do`. They must stay committed as long as the Appendix B path uses `$bsource="../outputs_stata_code/"`. Add a `README.md` note in `outputs_stata_code/` explaining why, or restructure so `_prepare_programs.do` runs at the top of `__main.do` Appendix B and these files disappear. Do **not** gitignore them without one of those two changes — doing so breaks `__main.do`.

### P3 — cleanup / deferred decisions

- [ ] **Archive or delete `outputs_stata_code/__main_PIOTR.do`.** It is a stale-duplicate of `__main.do` that references five figure files which do not exist in the folder (`R_Figure4.do`, `R_Figure_AppE_{Income,Taxes,Tech}.do`, `R_Figure_F6_exograte.do`), so it cannot run at all today. Either move to `docs/archive/` with a note, or delete.

- [ ] **Delete or justify `outputs_stata_code/asi_aux.dta`.** Zero references anywhere in the Stata code.

- [ ] **Gitignore `.stpr` IDE workspaces.** [inputs_stata_code/main.stpr](../inputs_stata_code/main.stpr) and [outputs_stata_code/__replication_graphs.stpr](../outputs_stata_code/__replication_graphs.stpr) are Java-serialized Stata project files. They store open tabs and cursor positions, not pipeline logic. Keeping them tracked adds binary churn every time someone opens Stata. Recommend adding `*.stpr` to `.gitignore` and `git rm --cached` them.

- [ ] **Decide `r_sd/R01compare_r_sd.do` disposition.** It is exploratory code comparing Fed Reserve wealth-share SDs to HKS calibration targets. Produces a single diagnostic line graph, no Fortran inputs. Either wire it into a documentation/diagnostics flow, move it under `docs/exploratory/`, or delete.

- [ ] **Document the income-process split in `README.md`.** The current README references the monorepo layout but does not make clear that `inputs_stata_code/income_process/` is driven separately from `__main_data_prepare.do`. A three-line pointer would save the next replicator an hour.

## 7. References

- Brainstorm: [docs/brainstorms/2026-04-13-stata-pipeline-audit-brainstorm.md](brainstorms/2026-04-13-stata-pipeline-audit-brainstorm.md)
- Plan: [docs/plans/2026-04-13-refactor-stata-pipeline-audit-plan.md](plans/2026-04-13-refactor-stata-pipeline-audit-plan.md)
- Phase 1 snapshot commit: `1227ffb` — "Stata: snapshot pending calibration + output driver updates"
- Input driver: [inputs_stata_code/__main_data_prepare.do](../inputs_stata_code/__main_data_prepare.do)
- Output driver: [outputs_stata_code/__main.do](../outputs_stata_code/__main.do)
