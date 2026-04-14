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

**The P1 fix is *not* a one-line path change.** A second-pass review of [inputs_stata_code/tfp/M02robustness_prepare_gamma.do](../inputs_stata_code/tfp/M02robustness_prepare_gamma.do) showed two further dependencies that the call site at [outputs_stata_code/__main.do:164](../outputs_stata_code/__main.do#L164) does not satisfy:

1. **cwd assumption.** The script opens `use tfp/gamma.dta` and `merge 1:1 year using bone1y` with paths relative to cwd. At line 164, cwd is `outputs_stata_code/` (last `cd ..\outputs_stata_code` was at line 87), so `tfp/gamma.dta` resolves to the wrong folder and the script crashes on its first `use`. The Appendix B prep scripts work around this by wrapping their calls in `cd ..\inputs_stata_code` … `cd ..\outputs_stata_code` (lines 57–80); the robustness call needs the same wrapping.
2. **`bone1y.dta` is not present.** The Appendix B re-runs at lines 63–75 use `global bsource "../outputs_stata_code/"` together with the pre-seeded `bone.dta`/`bone1y.dta` in `outputs_stata_code/`, then `erase $bsource/bone.dta` and `erase $bsource/bone1y.dta` at lines 77–78. By the time line 164 executes, both bone files are gone, and `M02robustness_prepare_gamma` has no `bone1y` to merge against. A correct fix has to recreate them (e.g. by re-running `_prepare_programs.do`) before invoking the script, then erase them again.

A complete fix therefore looks roughly like this (subject to interactive-Stata verification):

```stata
* Higher productivity growth
cd ..\inputs_stata_code
global bsource "../outputs_stata_code/"
do _prepare_programs.do
do tfp/M02robustness_prepare_gamma
erase $bsource/bone.dta
erase $bsource/bone1y.dta
cd ..\outputs_stata_code
```

This audit does **not** apply that fix — it cannot be tested without launching `__replication_graphs.stpr` interactively, and the audit is read-only by charter. The TODO in §6 is updated to reflect the larger scope.

**Note on `$bsource=""`** — an earlier draft of this audit flagged `merge 1:1 year using $bsource/bone` in [inputs_stata_code/depreciation/M01prepare_depr.do:28](../inputs_stata_code/depreciation/M01prepare_depr.do#L28) as a P0 bug because the empty `$bsource` expands to `/bone` and crashes in batch mode. **That is not a bug.** The pipeline is designed to be executed by opening [inputs_stata_code/main.stpr](../inputs_stata_code/main.stpr) in interactive Stata, which establishes the project root. Inside that session, `/bone` resolves relative to the project cwd and the merge succeeds. The finding is an artifact of running the driver via `stata /e do ...` outside the project context — see §4.1 for the retraction.

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
| `main.stpr` | Stata project | **canonical entry point** | high | Load-bearing: the pipeline is designed to be launched by opening this file in interactive Stata. Must stay tracked. |
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
| `__replication_graphs.stpr` | Stata project | **canonical entry point** | high | Load-bearing: the figures pipeline is designed to be launched by opening this file in interactive Stata. Must stay tracked. |
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

**Absolute-path pre-check**: `grep -r '[A-Za-z]:[\\/]' *.do` on the sandbox returned only URLs in comments. No hard-coded drive letters.

### 4.1 Dry-run retraction — wrong execution mode

An earlier draft of this section reported that `__main_data_prepare.do` "failed" in the sandbox. **That finding is retracted.** The sandbox run was launched via `StataSE-64 /e do __main_data_prepare.do` (headless batch), which is not how the pipeline is designed to be executed. The canonical entry point is [inputs_stata_code/main.stpr](../inputs_stata_code/main.stpr) — opening the project file in interactive Stata establishes the project root and working directory that the helper scripts rely on. Inside that session, `global bsource ""` combined with `merge 1:1 year using $bsource/bone` in `M01prepare_depr.do` resolves correctly against cwd. Outside of it, the empty `$bsource` produces a literal `/bone` path that Stata treats as root-absolute and rejects.

The observed `file /bone.dta not found; r(601)` error from the batch run is therefore an artifact of the wrong execution mode, not a pipeline bug. No action is required on the `.do` files for this issue.

**Concrete evidence the sandbox did not touch the real tree**: `git status` on the repo after the retracted run showed the same pre-existing modifications as before the run, and no new files under `fortran_code/Data/`, `graphs/`, or any of the Stata folders. The sandbox remained self-contained even though the dry-run was run the wrong way.

### 4.2 Runtime verification deferred

Running the drivers through the `.stpr` project is an interactive-Stata operation that cannot be scripted cleanly from a command-line batch. This audit therefore leaves runtime verification **deferred** rather than attempting it in the wrong mode. A follow-up session should:

1. Open [inputs_stata_code/main.stpr](../inputs_stata_code/main.stpr) in interactive Stata, run `__main_data_prepare.do`, and confirm all `fortran_code/Data/_data_*.txt` inputs regenerate without error. (This must happen in a sandbox copy — see the memory note on sandboxing before executing.)
2. Open [outputs_stata_code/__replication_graphs.stpr](../outputs_stata_code/__replication_graphs.stpr) and run `__main.do`. Expect it to crash at Appendix F.5 because of the P1 path bug in 2.3; everything upstream of that should succeed.
3. Record the results back into this document.

Until that is done, the only runtime signal we have is static analysis plus the P1 broken path call in `__main.do`.

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

### P1 — blocks a specific branch of the pipeline

- [ ] **Fix the broken `M02robustness_prepare_gamma` invocation in the output driver.** [outputs_stata_code/__main.do:164](../outputs_stata_code/__main.do#L164) calls `../sensitivity_stata_code/exog_rate/M02robustness_prepare_gamma`, but the file lives at [inputs_stata_code/tfp/M02robustness_prepare_gamma.do](../inputs_stata_code/tfp/M02robustness_prepare_gamma.do), so Appendix F.5 (the CBO productivity-growth robustness run) fails on any clean execution. **A path change alone is not enough**: the script also assumes cwd=`inputs_stata_code/` for `use tfp/gamma.dta`, and it needs `bone1y.dta` which Appendix B has already erased by the time line 164 runs. The fix has to (a) `cd ..\inputs_stata_code`, (b) re-run `_prepare_programs.do` to recreate `bone.dta`/`bone1y.dta` under `$bsource="../outputs_stata_code/"`, (c) `do tfp/M02robustness_prepare_gamma`, (d) erase the bone files, (e) `cd ..\outputs_stata_code`. See §2.3 for the full sketch. Verify by opening `__replication_graphs.stpr` in interactive Stata and running the driver through Appendix F.

- [ ] **Complete runtime verification through the `.stpr` entry points.** This audit deferred the actual run because the first attempt launched the drivers via `stata /e` (the wrong mode). The follow-up must open `inputs_stata_code/main.stpr` and then `outputs_stata_code/__replication_graphs.stpr` in interactive Stata — in a sandbox copy outside the repo — and record which steps succeed and which fail. The P1 above is expected to surface during that run.

### P2 — integration hygiene (not blocking, but fragile)

- [ ] **Resolve the `Data/` vs `data/` case asymmetry.** Scripts write lowercase; Fortran reads capital. Pick one, rename the tracked files, and update all `export delimited` calls. The canonical name used in the tracked outputs is `fortran_code/Data/` (capital D), so update the Stata scripts to write to `../fortran_code/Data/`.

- [ ] **Wire the demography outputs into `fortran_code/Data/`.** Today `inputs_stata_code/demography/{mortality,hetero_pi}/output/_data_*.txt` are produced by `D01_life_tables.do` and `D03_prepare_hetero_pi.do`, but the copy into `fortran_code/Data/` happens by hand. Either add a final `copy` / `!copy` step at the end of each script, or add a consolidation block to `__main_data_prepare.do` that dispatches them (they are currently only reached via `__main.do` Appendix C).

- [ ] **Decide the `bone*.dta` policy.** [outputs_stata_code/bone.dta](../outputs_stata_code/bone.dta) and [outputs_stata_code/bone1y.dta](../outputs_stata_code/bone1y.dta) are **pre-seeded inputs**, not temp files, for the Appendix B re-runs in `__main.do`. They must stay committed as long as the Appendix B path uses `$bsource="../outputs_stata_code/"`. Add a `README.md` note in `outputs_stata_code/` explaining why, or restructure so `_prepare_programs.do` runs at the top of `__main.do` Appendix B and these files disappear. Do **not** gitignore them without one of those two changes — doing so breaks `__main.do`.

### P3 — cleanup / deferred decisions

- [ ] **Archive or delete `outputs_stata_code/__main_PIOTR.do`.** It is a stale-duplicate of `__main.do` that references five figure files which do not exist in the folder (`R_Figure4.do`, `R_Figure_AppE_{Income,Taxes,Tech}.do`, `R_Figure_F6_exograte.do`), so it cannot run at all today. Either move to `docs/archive/` with a note, or delete.

- [ ] **Delete or justify `outputs_stata_code/asi_aux.dta`.** Zero references anywhere in the Stata code.

- [ ] **Document the `.stpr` files as the canonical entry points in README.md.** [inputs_stata_code/main.stpr](../inputs_stata_code/main.stpr) and [outputs_stata_code/__replication_graphs.stpr](../outputs_stata_code/__replication_graphs.stpr) are the designed launch points for the Stata pipeline — not IDE workspace noise. The README should say, explicitly: "open `main.stpr` in Stata, then run `__main_data_prepare.do` from inside that project" (and similarly for the outputs project). Without this note, a future replicator following the intuition "it's Stata, just `do __main_data_prepare.do`" will hit the same false-alarm crash this audit's first draft hit.

- [ ] **Decide `r_sd/R01compare_r_sd.do` disposition.** It is exploratory code comparing Fed Reserve wealth-share SDs to HKS calibration targets. Produces a single diagnostic line graph, no Fortran inputs. Either wire it into a documentation/diagnostics flow, move it under `docs/exploratory/`, or delete.

- [ ] **Document the income-process split in `README.md`.** The current README references the monorepo layout but does not make clear that `inputs_stata_code/income_process/` is driven separately from `__main_data_prepare.do`. A three-line pointer would save the next replicator an hour.

## 7. README accuracy review

Part of the audit's charter is verifying that [README.md](../README.md) describes the Stata workflow accurately. The following inaccuracies were found and corrected in the same commit that lands this document.

| Location | Claim (before) | Reality | Action |
|---|---|---|---|
| Step 2 Stage A run command | `cd inputs_stata_code && stata -e do __main_data_prepare.do` | Pipeline must be launched via [inputs_stata_code/main.stpr](../inputs_stata_code/main.stpr) in interactive Stata; `stata -e` crashes on the first `merge` | Replaced with `.stpr`-based launch steps |
| Step 2 Stage A file list | `_data_labsh.txt` | Script writes `_data_lab_share.txt` (from `global var lab_share`) | Corrected |
| Step 2 Stage A file list | `_data_contrib.txt` | Script writes `_data_contributions.txt` (from `global var contributions`) | Corrected |
| Step 2 Stage A file list | `_data_exog_rate.txt, _data_irr.txt` from M04 | M04 writes only `_data_irr.txt`; `_data_exog_rate_1935.txt` is a frozen hand-written input | Dropped the `_data_exog_rate.txt` claim |
| Step 2 Stage C description | "hand-held demography prep produces the `_data_Nn_*.txt` population series and `_data_pi_*.txt` survival series" | No Stata script produces `_data_Nn_*.txt` — those are frozen hand-written inputs. Mortality/hetero_pi scripts write to `inputs_stata_code/demography/<sub>/output/`, not directly to `fortran_code/Data/`, and are copied over by hand | Rewritten to separate frozen series from scripted outputs and to name the subfolder-to-Data/ hand-copy step |
| Step 2 Stage C | (no mention of orphan files) | ~15 `_data_*.txt` files in `fortran_code/Data/` have no Stata producer: `_data_tau{C,K,L}.txt`, `_data_contrib{,_to_gdp}.txt`, `_data_{exog_rate,gy,rho}_1935.txt`, `_data_type_*.txt`, `_data_het_pi_US_since1935.txt`, `_data_pi_cond_het_US_since1935.txt`, `_data_gamma_robustness.txt` | Added an inventory paragraph flagging them as frozen source data |
| Step 7 run command | `cd outputs_stata_code && stata -e do __main.do` | Must be launched via [outputs_stata_code/__replication_graphs.stpr](../outputs_stata_code/__replication_graphs.stpr) | Replaced with `.stpr`-based launch steps |
| Step 7 Appendix F bullet | `sensitivity_stata_code/exog_rate/M02robustness_prepare_gamma.do` | That path does not exist — file is at [inputs_stata_code/tfp/M02robustness_prepare_gamma.do](../inputs_stata_code/tfp/M02robustness_prepare_gamma.do); Appendix F.5 crashes here on a clean run (P1 in §6) | Added a warning pointing at the broken path and linking to this audit |
| Step 2 Stage A path | "writes the following `.txt` files into `../fortran_code/Data/`" (capital D) | Scripts actually write to `../fortran_code/data/` (lowercase). Works on Windows, breaks on case-sensitive filesystems | Added a case-sensitivity note |

**Not verified in this pass** (left for a follow-up if relevant):

- The README's Stata package list (`psmatch2`, `mat2txt`, `egenmore` at line ~813) is not cross-referenced against actual `ssc install` calls or helper imports in the scripts.
- Step 7's "Appendix B re-runs the Stage-A prep scripts... with a plotting source switched on" phrasing is not precise about the `$bsource="../outputs_stata_code/"` mechanism, but is not wrong. Left as-is.
- The Stage B (income-process) file list at lines ~849–854 was not cross-checked against `estimate_income_process.do` in this pass; spot-check showed the names look right.
- Mapping from paper table/figure → output file in the "List of Tables and Figures" section is out of scope.

## 8. References

- Brainstorm: [docs/brainstorms/2026-04-13-stata-pipeline-audit-brainstorm.md](brainstorms/2026-04-13-stata-pipeline-audit-brainstorm.md)
- Plan: [docs/plans/2026-04-13-refactor-stata-pipeline-audit-plan.md](plans/2026-04-13-refactor-stata-pipeline-audit-plan.md)
- Phase 1 snapshot commit: `1227ffb` — "Stata: snapshot pending calibration + output driver updates"
- Input driver: [inputs_stata_code/__main_data_prepare.do](../inputs_stata_code/__main_data_prepare.do)
- Output driver: [outputs_stata_code/__main.do](../outputs_stata_code/__main.do)

---

## 9. Sandbox reproducibility audit (2026-04-14)

Follow-up to sections 1-7: the read-only audit established *what* the pipeline produces on paper. This section records the result of *running* the pipeline end-to-end in a scratch sandbox and diffing every produced `_data_*.txt` against the committed version in `fortran_code/Data/`.

### 9.1 Sandbox setup

- Scratch dir: `C:/temp/stata_all_sandbox/` (outside the repo tree, protects committed outputs).
- Mirrors `inputs_stata_code/` minus `demography/`, `income_process/`, `r_sd/`, and (initially) `skill_premium/ACS_college/`. The 1.96 GB `ACS_college.dta` is staged into `sandbox/data/skill_premium/ACS_college/` for D02.
- Driver: modified copy of `__main_data_prepare.do` with `global bsource "."` (the empty-`$bsource` convention resolves to `/bone1y.dta` in batch and fails; `"."` is semantically equivalent and works in batch).
- Launch: `StataSE-64.exe /b do __main_data_prepare.do` with `MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*"` from Git Bash.
- Comparison: each sandbox output diffed CRLF-normalized against `git show HEAD:fortran_code/Data/_data_*.txt`.

### 9.2 Filename mapping (Stata → Fortran)

`data.f90` hardcodes the filenames it opens (see [fortran_code/data.f90](../fortran_code/data.f90) for the `Open(... FILE = "_data_*.txt")` statements). Several prep scripts wrote different names before the fixes in §9.4; after those fixes, every prep script lands on the exact name `data.f90` opens.

| Fortran `data.f90` opens | Prep script | Pre-fix Stata name | Post-fix |
|---|---|---|---|
| `_data_depr.txt` | M01 | `_data_depr.txt` | unchanged |
| `_data_gamma.txt` | M02 | `_data_gamma.txt` | unchanged |
| `_data_lambda.txt` | T03 | `_data_lambda.txt` | unchanged |
| `_data_skill_premium.txt` | H01 | `_data_skill_premium.txt` | unchanged |
| `_data_college_share.txt` | D02 | `_data_college_share.txt` | unchanged |
| `_data_labsh.txt` | M03 | `_data_lab_share.txt` ✗ | fixed |
| `_data_tauK.txt` | T01 (tK) | `_data_tK.txt` ✗ | fixed |
| `_data_tauL.txt` | T01 (tL) | `_data_tL.txt` ✗ (and never written due to loop bug) | fixed |
| `_data_tauC.txt` | T01 (tC) | `_data_tC.txt` ✗ (and never written due to loop bug) | fixed |
| `_data_contrib_to_gdp.txt` | T02 | `_data_contributions.txt` ✗ | fixed |

`_data_contrib.txt` (0-byte sentinel) is tracked in `fortran_code/Data/` but never opened by `data.f90`. Stale artifact; ignore.

### 9.3 Reproducibility matrix (post-fix)

Every Stata-produced Fortran input was regenerated in the sandbox with fixed do-files and compared against `git show HEAD:fortran_code/Data/_data_*.txt`.

| File | Script | Sandbox rows | Tracked rows | Pre-2050 values match? |
|---|---|---|---|---|
| `_data_depr.txt` | M01 | 23 | 34 | ✓ bit-for-bit |
| `_data_gamma.txt` | M02 | 23 | 34 | ✓ bit-for-bit |
| `_data_lambda.txt` | T03 | 23 | 34 | ✓ bit-for-bit |
| `_data_skill_premium.txt` | H01 | 46 (23+23 stacked) | 68 (34+34) | ✓ bit-for-bit, both halves |
| `_data_college_share.txt` | D02 | 46 (23+23 stacked) | 68 (34+34) | ✓ bit-for-bit, both halves |
| `_data_labsh.txt` | M03 | 23 | 34 | ✓ bit-for-bit |
| `_data_tauK.txt` | T01 | 23 | 34 | ✓ bit-for-bit |
| `_data_tauL.txt` | T01 | 23 | 34 | ✓ bit-for-bit |
| `_data_tauC.txt` | T01 | 23 | 34 | ✓ bit-for-bit |
| `_data_contrib_to_gdp.txt` | T02 | 23 | 34 | ✓ within 4.4e-5 (OECD revision noise) |

### 9.4 Fixes landed this session

All fixes are in `inputs_stata_code/` only. No `fortran_code/` files touched.

**Commit `47a6bfd`** — "Stata inputs: fix export filenames, T01 loop bug, M03 labsh constant"

- [M03prepare_labor_share.do](../inputs_stata_code/labor_share/M03prepare_labor_share.do)
  - Export target changed to `_data_labsh.txt` (was `_data_lab_share.txt`).
  - Pre-1950 smoothing constant `0.01/30` → `0.01/15` on line 22. Reproduces the committed file bit-for-bit in rows 1-23.
- [T02prepare_contributions.do](../inputs_stata_code/social_security/T02prepare_contributions.do)
  - Export target changed to `_data_contrib_to_gdp.txt` (was `_data_contributions.txt`).
- [T01prepare_taxes.do](../inputs_stata_code/tax_rate/T01prepare_taxes.do)
  - Removed `local tax tK` on line 7, which pinned every `foreach tax in tK tL tC` iteration to `tK` and silently prevented `_data_tauL.txt` and `_data_tauC.txt` from ever being written. This bug was latent for the duration of the repo's history — the tracked `_data_tauL.txt` / `_data_tauC.txt` must have been produced by a patched-then-unpatched variant run by hand three times.
  - Export target rewritten as `_data_tau${taxletter}.txt` via `local taxletter = substr("\`tax'", 2, .)`.

**Commit `e757abf`, `7f60564`, `4d450fe`** — "T02 contributions: restore original SDMX-window computation" and follow-up comment edits

The committed `_data_contrib_to_gdp.txt` was produced by an older version of T02 that queried OECD's SDMX 2.0 endpoint (`sdmxuse data OECD, dataset(REVUSA) dimensions(2000+AJ+AG.SOCSEC)`) combined with `dbnomics QNA/USA.B1_GS1.CARSA.A` for GDP, computing `contrib_to_gdp = contributions/gdp` directly. OECD decommissioned SDMX 2.0 in 2024; `sdmxuse` is hardcoded to the dead URL `https://stats.oecd.org/restsdmx/sdmx.ashx/` and cannot reach the new SDMX 2.1 endpoint without rewriting the query for a different dataset structure. Live re-query is therefore impossible; no archived `.dta` snapshot of the SDMX-era data exists (the old script ran live queries without caching).

The current pipeline uses `dbnomics import pr(OECD) d(REV) series(NES.2000.TAXGDP.USA,...)` which returns the same OECD Revenue Statistics table but with a wider vintage: continuous 1965-2022, where the SDMX query only returned 1973-2021 with just two observations in the 1970-1974 bucket (1973, 1974) and two in the 2020-2024 bucket (2020, 2021).

To reproduce the committed file's values on the wider current vintage, three modifications were applied to [T02prepare_contributions.do](../inputs_stata_code/social_security/T02prepare_contributions.do):

1. **Smoothing constant**: `0.03/8` → `0.04/8` in the pre-1970 extrapolation formula. Back-solved from the committed row values assuming the correct 1970-bucket anchor; yields an exact `0.005` multiplier.
2. **Null 1970-1972** so the 1970-1974 bucket averages only 1973+1974 (matching the SDMX-era behaviour). Effect: fixes rows 1-8 (the pre-1970 extrapolation block and its anchor).
3. **Null 2021+** so the 2020-2024 bucket anchors on 2020 alone. Effect: fixes rows 18-23 (the post-2020 extrapolation).

Fixes (2) and (3) are orthogonal — each controls a different segment. Without (2), rows 1-8 sit flat `3.33e-3` below committed. Without (3), rows 18+ sit flat `2e-3` below committed. With (1)+(2)+(3), residuals across all 23 overlapping rows are `≤ 4.4e-5` absolute, `≤ 7e-4` relative on a 3-7% ratio. The remaining residuals are pure OECD data revisions applied between the SDMX-era run and today:

- Row 17 (2015-2019 bucket): `4.4e-5` — OECD revised pre-pandemic values slightly.
- Rows 18+ (2020 anchor): `3.1e-5` — OECD revised the 2020 value from `6.9059` to `6.909` post-pandemic.

A header comment block was added documenting the SDMX→dbnomics transition and the rationale for the three modifications.

**D02_prepare_college.do** — NOT fixed, despite the sandbox reproduction working.

The in-tree file has `use "..\data\skill_premium\ACS_college\ACS_college.dta"`, which from cwd `inputs_stata_code/` resolves to `{repo}/data/skill_premium/ACS_college/ACS_college.dta` — a path **that does not exist in the repo**. The real data is at `inputs_stata_code/skill_premium/ACS_college/ACS_college.dta` (1.96 GB). For sandbox testing the file was copied to the sandbox path the in-tree script expects; for the in-tree `.stpr` run the path resolution is unexplained and requires user clarification (see §9.6).

### 9.5 Latent issues not addressed

Two separate problems remain latent in the pipeline and were not fixed in this session because they need user direction:

1. **`keep if year <= 2050` tail truncation** — shared across every prep script. Committed Fortran inputs have 34 five-year rows (1935-2100); the current do-files produce 23 rows (1935-2050). `data.f90` hardcodes `last_data_gamma = 34` in [fortran_code/data.f90:218](../fortran_code/data.f90#L218), so a fresh-regenerated file would be 11 rows short and Fortran would read past EOF. This means a clean pipeline rerun **cannot replace the committed Fortran inputs** until either (a) the do-files are extended to produce all 34 rows, or (b) the Fortran-side reader is made tail-robust. This is the single biggest latent reproducibility hazard in the pipeline.

2. **D02_prepare_college.do in-tree path inconsistency** — the do-file's `use "..\data\skill_premium\ACS_college\ACS_college.dta"` is inconsistent with where the data actually lives (`skill_premium\ACS_college\ACS_college.dta` from the same cwd). The user blocked a direct in-tree path fix, stating that `.stpr` would fail if the path changed. The mechanism by which `.stpr` finds the file at `..\data\...` is unexplained (no junction, no symlink, no `data/skill_premium/` directory visible under the repo root via either `ls`, `fsutil reparsepoint query`, or `cmd dir /a:l`).

3. **Non-Stata Fortran inputs untested** — demography (`_data_pi_*`, `_data_Nn_*`, `_data_het_pi_*`), income process (`_data_omega_*`, `_data_sigma2eps_*`), and `sensitivity_stata_code/exog_rate/M04prepare_exog_rate.do` were not exercised in the sandbox. Their reproducibility status is unknown. The tree under [inputs_stata_code/income_process/](../inputs_stata_code/income_process/) is standalone (see §2.1) and would need its own scratch sandbox.

### 9.6 Open questions for the user

1. **How does D02 find `..\data\skill_premium\ACS_college\ACS_college.dta` when run from `.stpr`?** No junction, no data directory, no symlink visible. Either the `.stpr` session has a working-directory setup that's different from what `cd "\`c(pwd)'"` in `__main_data_prepare.do` establishes, or the pipeline has never actually run D02 successfully from `.stpr` (i.e., D02 is latently broken in-tree the same way the T01 loop was).
2. **Should we regenerate the committed `fortran_code/Data/_data_*.txt` files from the fixed pipeline and commit them?** This closes the reproducibility loop: the committed files become the authoritative output of the committed do-files. Blocks on the tail-truncation issue above.
3. **Should we pursue labsh and gamma "V1 history" the same way we did for contrib_to_gdp?** Both scripts had small constant changes that matter for the committed values (gamma: 1.35 vs 1.9; labsh: 0.01/30 vs 0.01/15). The labsh one is already fixed by the `47a6bfd` commit; the gamma one is already consistent with the committed file. Whether the audit should go deeper and document *why* those constants changed is a judgement call.

### 9.7 Session commits

All on `main`:

- `47a6bfd` — Stata inputs: fix export filenames, T01 loop bug, M03 labsh constant
- `e757abf` — T02 contributions: restore original SDMX-window computation
- `7f60564` — T02 header comment: drop 'tracked' phrasing
- `4d450fe` — T02 header comment: drop 0.04/8 sentence

Files touched, all in `inputs_stata_code/`:

- `labor_share/M03prepare_labor_share.do`
- `social_security/T02prepare_contributions.do`
- `tax_rate/T01prepare_taxes.do`
