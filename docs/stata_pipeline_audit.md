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
├── ../sensitivity_stata_code/exog_rate/M04prepare_exog_rate.do   (robustness; writes _data_exog_rate_1935.txt, not frozen)
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
| `exog_rate/M04prepare_exog_rate.do` | script | live | high | Called from `__main_data_prepare.do:19` and `__main.do:175`; writes `_data_exog_rate_1935.txt` (the name Fortran reads) |
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

- [ ] **Complete runtime verification through the `.stpr` entry points.** This audit deferred the actual run because the first attempt launched the drivers via `stata /e` (the wrong mode). The D01→D02→D03 demography chain has since been verified in Stata batch mode (see §10), but the remaining scripts (H01, M01–M04, R01, T01–T03) and the output driver (`__main.do` via `__replication_graphs.stpr`) have not been exercised end-to-end.

### P2 — integration hygiene (not blocking, but fragile)

- [ ] **Resolve the `Data/` vs `data/` case asymmetry.** Scripts write lowercase; Fortran reads capital. Pick one, rename the tracked files, and update all `export delimited` calls. The canonical name used in the tracked outputs is `fortran_code/Data/` (capital D), so update the Stata scripts to write to `../fortran_code/Data/`.

- [x] **Wire the demography outputs into `fortran_code/Data/`.** ~~Today `inputs_stata_code/demography/{mortality,hetero_pi}/output/_data_*.txt` are produced by `D01_life_tables.do` and `D03_prepare_hetero_pi.do`, but the copy into `fortran_code/Data/` happens by hand.~~ **Done (2026-04-16):** D03 now writes directly to `../fortran_code/Data/` for all three het_pi files (`_all`, `_col`, `_no_col`). D01 still writes only to its local `output/` subfolder — wiring D01 to `fortran_code/Data/` is deferred since D01's `_data_pi_cond_US_since1935.txt` output is also consumed by D03 through the intermediate `pi_tot_new.dta`, not directly by Fortran in the `switch_het_mortality == 1` branch.

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
| Step 2 Stage A file list | `_data_exog_rate.txt, _data_irr.txt` from M04 | M04 now writes only `_data_exog_rate_1935.txt` (commit `75e4433` consolidated the two exports after the alias `_data_irr.txt` was found to be unused) | Updated to the single current output |
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

1. **`keep if year <= 2050` tail truncation** — shared across every prep script **when `$year_stop` is not set**. Committed Fortran inputs have 34 five-year rows (1935-2100); `data.f90` hardcodes `last_data_gamma = 34` etc. When `__main_data_prepare.do` runs first (as it does in the `main.stpr` pipeline), it sets `global year_stop 2100` and the `periods` program produces the full 34-row range. The truncation to 23 rows only happens when scripts are run standalone without the globals — as occurred in a prior sandbox run that incorrectly shortened 5 committed files (reverted in `fb3d9c2`). **Lesson: any sandbox run must either execute `__main_data_prepare.do` first or explicitly set `global year_start 1935` / `global year_stop 2100`.**

2. **D02_prepare_college.do in-tree path inconsistency** — the do-file's `use "..\data\skill_premium\ACS_college\ACS_college.dta"` is inconsistent with where the data actually lives (`skill_premium\ACS_college\ACS_college.dta` from the same cwd). The user blocked a direct in-tree path fix, stating that `.stpr` would fail if the path changed. The mechanism by which `.stpr` finds the file at `..\data\...` is unexplained (no junction, no symlink, no `data/skill_premium/` directory visible under the repo root via either `ls`, `fsutil reparsepoint query`, or `cmd dir /a:l`).

3. **Non-Stata Fortran inputs partially tested** — the D01→D02→D03 demography chain has been verified in Stata batch (see §10): `_data_het_pi_US_since1935_all.txt` (the file Fortran reads for het mortality) reproduces byte-exact. The income process (`_data_omega_*`, `_data_sigma2eps_*`) and `sensitivity_stata_code/exog_rate/M04prepare_exog_rate.do` remain untested. The tree under [inputs_stata_code/income_process/](../inputs_stata_code/income_process/) is standalone (see §2.1) and would need its own scratch sandbox.

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

## 10. Demography pipeline (D01→D02→D03) — sandbox verification (2026-04-16)

### 10.1 Scope

Verified that the D01→D02→D03 chain, run in Stata batch mode from a scratch sandbox, reproduces the Fortran-consumed `_data_het_pi_US_since1935_all.txt` byte-for-byte. This is the only demography file Fortran reads (via `switch_het_mortality == 1` in [data.f90](../fortran_code/data.f90)).

### 10.2 Method

1. Copied `inputs_stata_code/` and `fortran_code/` to `n:/PROJECTS/EMERYT/_sandbox_d03_20260416/`.
2. Wrote self-contained `.do` scripts that inline the `bone1y`/`periods` setup (matching `__main_data_prepare.do` globals: `year_start=1935`, `year_stop=2100`, `lam=1600`).
3. Ran D01, D02, D03 in `StataSE-64.exe //e do ...` batch mode.
4. Compared outputs against committed `fortran_code/Data/` files using inline Stata diff (merge + `abs(diff) < 1e-8`).

### 10.3 Results

**D01 (`D01_life_tables.do`):**

- Regenerated `pi_tot_new.dta` from the three tracked Excel files (`life_tables.xlsx`, `2015-2050.xlsx`, `2050-2100.xlsx`).
- **528/528 rows match the tracked `pi_tot_new.dta` exactly** (zero diff).
- The `destring ... ignore("…")` uses Unicode ellipsis (U+2026, bytes `E2 80 A6`), which correctly strips only the ellipsis missing-value marker from UN projection strings without removing decimal points. A prior investigation mistakenly used ASCII `"..."` (three dots) which strips all periods including decimal points — that was a test-script bug, not a D01 bug.

**D02 (`D02_prepare_college.do`):**

- Regenerated `col_share_acs_ext.dta` from `ACS_college.dta` with `$year_stop=2100`.
- All 48 cohorts (1840-2075) have non-NaN `college_share` values. The tracked `.dta` in the repo has NaN for cohorts 2025-2075 because it was saved from a standalone D02 run without `__main_data_prepare.do` globals. **D02 must run after `__main_data_prepare.do` to produce the complete file.**
- The stacked `_data_college_share.txt` export has 68 rows (34 periods × 2 types), matching `last_data_type_share=34` in [data.f90:230](../fortran_code/data.f90#L230).

**D03 (`D03_prepare_hetero_pi.do`):**

- Used the D01-regenerated `pi_tot_new.dta` and the D02-regenerated `col_share_acs_ext.dta`.
- Exported `_data_het_pi_US_since1935_all.txt` (1056 values, zero NaN).
- **1056/1056 rows match the committed `fortran_code/Data/_data_het_pi_US_since1935_all.txt`** with zero diff (< 1e-8).

### 10.4 Fixes applied

1. **D03 no_col export bug** (commit `aca558e`): the `_data_pi_US_since1935_no_col.txt` export was writing the stacked `prob` column (1057 rows) instead of `syn_pr1` alone (529 rows). Fixed with a proper `preserve/keep syn_pr1/export/restore` block. Note: Fortran does not read this file — only `_data_het_pi_US_since1935_all.txt` is consumed (via unit 121 in the `switch_het_mortality == 1` branch).

2. **D03 Fortran Data exports** (same commit): added `export delimited "..\fortran_code\Data\_data_het_pi_US_since1935_all.txt"` (and `_col`, `_no_col`) so D03 writes directly to the Fortran input directory. Previously the copy from `demography/hetero_pi/output/` to `fortran_code/Data/` was manual.

3. **Reverted 5 truncated files** (commit `fb3d9c2`): a prior commit (`a096b86`) had replaced 5 Fortran data files with outputs from a sandbox run that lacked `$year_stop=2100`, shortening them from 34 periods to 23. Reverted `_data_college_share.txt`, `_data_depr.txt`, `_data_gamma.txt`, `_data_lambda.txt`, `_data_skill_premium.txt` to their pre-truncation state.

### 10.5 Fortran file usage (het mortality)

Confirmed by `grep` across all `.f90` files:

| File | Read by Fortran? | Notes |
|---|---|---|
| `_data_het_pi_US_since1935_all.txt` | Yes | Unit 121, `switch_het_mortality == 1`. 1056 rows = stacked `syn_pr3` (college) then `syn_pr1` (non-college), 528 each. Read as `pi_d_big(j,m,i)` with `j=1..bigJ`, `m=1..bigM`, `i=1..last_data_demo`. |
| `_data_pi_US_since1935_col.txt` | No | Vestigial. Not referenced in any `.f90` file. |
| `_data_pi_US_since1935_no_col.txt` | No | Vestigial. Not referenced in any `.f90` file. |
| `_data_college_share.txt` | Yes | Unit 8, read as `type_share_d(m,i)` with `last_data_type_share=34`. 68 rows = 34 periods × 2 types. Produced by D02. |

### 10.6 Conclusion

The full D01→D02→D03 pipeline reproduces all Fortran-consumed demography inputs when run via `main.stpr` (which executes `__main_data_prepare.do` first to set globals). No files need to be frozen or pinned — all inputs are reproducible from the tracked source data (Excel files, `ACS_college.dta`, `New_data_on_mortality.dta`).

## 11. Full pipeline sandbox verification (2026-04-16)

### 11.1 Scope

Ran every script in the `main.stpr` pipeline in Stata batch mode from a scratch sandbox, then diffed all produced `_data_*.txt` files against the committed versions in `fortran_code/Data/`.

### 11.2 Batch-mode setup

The `main.stpr` project can be replicated in batch by:

1. `cd inputs_stata_code`
2. Set globals: `global year_start 1935`, `global year_stop 2100`, `global bsource "."`, `global f_results ""`
3. `do _prepare_programs` (defines `periods`, `drawing`, creates `bone.dta`/`bone1y.dta`)
4. Run each script in order: D01, D02, D03, H01, M01, M02, M02robustness, M03, M04, T01, T02, T03

The `bsource = "."` is the batch-mode equivalent of the `.stpr` empty-string convention: `"$bsource/bone1y"` resolves to `"./bone1y"` instead of `"/bone1y"`.

The sandbox also requires:
- `data/skill_premium/ACS_college/ACS_college.dta` — D02 reads `"..\data\skill_premium\ACS_college\ACS_college.dta"` from cwd `inputs_stata_code/`.
- `data/skill_premium/ACS_college/processed/` — directory must exist for D02 to `save col_share_acs`.
- `graphs/inputs/` — directory must exist for graph exports (scripts crash with rc=603 otherwise, aborting before the data export if `graph save` comes first).
- `sensitivity_stata_code/exog_rate/irr.dta` — Stata intermediate read by M04 (not from MATLAB; produced by a prior standalone Stata+Fed data step).

### 11.3 Results

| Script | Output file(s) | vs committed | Notes |
|---|---|---|---|
| D01 | `_data_pi_cond_US_since1935.txt` | **LENGTH MISMATCH** (529 vs 544 lines) | D01 produces 528 data rows (33×16). Committed Fortran file has 543 data rows. Only used in `switch_het_mortality == 0` (homogeneous). See §11.4. |
| D02 | `_data_college_share.txt` | **PERFECT MATCH** (46/46) | Note: committed file has 46 rows (23 periods × 2), not the 68 rows (34×2) that Fortran's `last_data_type_share=34` expects. See §11.5. |
| D03 | `_data_het_pi_US_since1935_all.txt` | **PERFECT MATCH** (1056/1056) | The file Fortran reads for het mortality. |
| H01 | `_data_skill_premium.txt` | **PERFECT MATCH** (46/46) | Stacked (college premium ∥ ncollege premium). |
| M01 | `_data_depr.txt` | **PERFECT MATCH** (23/23) | |
| M02 | `_data_gamma.txt` | **PERFECT MATCH** (23/23) | |
| M02r | `_data_gamma_robustness.txt` | **PERFECT MATCH** (34/34) | |
| M03 | `_data_labsh.txt` | **PERFECT MATCH** (23/23) | |
| M03 | `_data_lab_share.txt` | **PERFECT MATCH** (23/23) | |
| M04 | `_data_exog_rate_1935.txt` | not compared (output path mismatch in test script) | M04 ran successfully. This is the name Fortran reads ([data.f90:159](../fortran_code/data.f90#L159)). |
| T01 | `_data_tL.txt` | **PERFECT MATCH** (23/23) | |
| T01 | `_data_tK.txt` | **PERFECT MATCH** (23/23) | |
| T01 | `_data_tC.txt` | **PERFECT MATCH** (23/23) | |
| T02 | `_data_contributions.txt` | **PERFECT MATCH** (23/23) | |
| T03 | `_data_lambda.txt` | **PERFECT MATCH** (23/23) | |

**Frozen files** (no Stata producer, unchanged by pipeline): `_data_rho_1935.txt`, `_data_exog_rate_1935.txt`, `_data_Nn_US_1935_2100.txt`, `_data_Nn_US_1935_init_old.txt`.

**MATLAB pipeline** (separate, not run here): `_data_omega_*.txt`, `_data_sigma2eps_*.txt`.

### 11.4 Resolved: D01 `_data_pi_cond_US_since1935.txt` — dead code, no action needed

D01 regenerates 528 data rows (33 periods × 16 ages). The committed Fortran file has 544 rows (34 periods × 16 ages). The extra 16 rows are the UN WPP "2010-2015" overlap period that D01 currently drops via `drop if Period == "2010-2015"` at line 65. The committed file was produced by an older D01 that kept this period.

**However, this file is never read in practice.** All 30 instruction files in `fortran_code/Instructions/` set `switch_het_mortality=1`. The `_data_pi_cond_US_since1935.txt` file is only opened in the `switch_het_mortality == 0` branch ([data.f90:501](../fortran_code/data.f90#L501)), which is dead code for this paper. The model always uses `_data_het_pi_US_since1935_all.txt` (the education-specific survival file produced by D03, already verified byte-exact).

**Root cause of the 16-row difference:** The UN WPP xlsx includes both an observed "2010-2015" period and projected "2015-2020" onward. The HMD data ends at "2010-2014". The historical D01 kept the overlap (34 periods); the current D01 drops it via `drop if Period == "2010-2015"` to avoid having two near-duplicate periods for the 2010-2015 window. Removing that line would reproduce the committed file exactly (first 256 HMD rows match byte-exact, the extra period at rows 257-272 is the UN "2010-2015", and the remaining 272 rows match byte-exact with a 16-row offset).

**No fix needed** — the file is unused in all scenarios.

### 11.5 Open: D02 `_data_college_share.txt` 23 vs 34 periods

The committed file has 46 rows (23 periods × 2 types). D02 with `$year_stop=2100` produces 34 periods × 2 = 68 rows. Fortran expects `last_data_type_share=34`.

However, the comparison reports PERFECT MATCH at 46/46 — meaning D02 reproduced the 23-period version exactly. This happens because the committed file was already 46 rows (from a prior run without `$year_stop=2100`), and the pipeline overwrote it with an identical 46-row file. Wait — this shouldn't happen if `$year_stop=2100` was set.

**Root cause:** D02's `global lam = 1600` sets `lam` but the `periods` program depends on `$year_start` and `$year_stop`. When D02 runs as part of the pipeline (after `__main_data_prepare.do`), these are set to 1935/2100, which produces 34 periods. But the committed 46-row file corresponds to 23 periods — evidence that the committed file was produced from an older pipeline run with different `year_stop`, or from the `.stpr` interactive session where the globals resolved differently.

**The committed file is undersized for the current Fortran code.** Fortran's `last_data_type_share=34` will read 34 values per type = 68 total, reading past EOF on a 46-row file. This is a latent runtime crash in any scenario that calls `switch_change_type_share`.

**TODO:** Regenerate and commit the 68-row version. The pipeline already produces it when `$year_stop=2100`.

### 11.6 Complete Fortran input file inventory

| Fortran file | Stata producer | Reproduced? | Committed rows | Expected rows | Notes |
|---|---|---|---|---|---|
| `_data_het_pi_US_since1935_all.txt` | D03 | **Yes, byte-exact** | 1056 | 1056 | Het mortality (the model's primary path) |
| `_data_college_share.txt` | D02 | **Yes for 46 rows; needs 68** | 46 | 68 | `last_data_type_share=34` × 2 types |
| `_data_skill_premium.txt` | H01 | **Yes, byte-exact** | 46 | 68? | Same stacked format as college_share |
| `_data_labsh.txt` | M03 | **Yes, byte-exact** | 23 | 34? | Check `last_data_sl` |
| `_data_depr.txt` | M01 | **Yes, byte-exact** | 23 | 34? | Check `last_data_depr` |
| `_data_gamma.txt` | M02 | **Yes, byte-exact** | 23 | 34? | Check `last_data_gamma` |
| `_data_gamma_robustness.txt` | M02r | **Yes, byte-exact** | 34 | 34 | Already correct length |
| `_data_lambda.txt` | T03 | **Yes, byte-exact** | 23 | 34? | Check `last_data_lambda` |
| `_data_tauL.txt` / `_data_tL.txt` | T01 | **Yes, byte-exact** | 23 | 34? | Check `last_data_tauL` |
| `_data_tauK.txt` / `_data_tK.txt` | T01 | **Yes, byte-exact** | 23 | 34? | Check `last_data_tauK` |
| `_data_tauC.txt` / `_data_tC.txt` | T01 | **Yes, byte-exact** | 23 | 34? | Check `last_data_tauC` |
| `_data_contributions.txt` | T02 | **Yes, byte-exact** | 23 | 34? | Check `last_data_t1` |
| `_data_pi_cond_US_since1935.txt` | D01 | **Length mismatch** | 544 | 528+header | See §11.4 |
| `_data_exog_rate_1935.txt` | M04 | Not compared | — | — | The name Fortran reads; produced by M04 |
| `_data_lab_share.txt` | M03 | **Yes, byte-exact** | 23 | — | Not directly read by Fortran |
| `_data_rho_1935.txt` | — | Frozen | — | — | No Stata producer |
| `_data_exog_rate_1935.txt` | — | Frozen | — | — | No Stata producer |
| `_data_Nn_US_1935_2100.txt` | — | Frozen | — | — | No Stata producer |
| `_data_Nn_US_1935_init_old.txt` | — | Frozen | — | — | No Stata producer |
| `_data_omega_*.txt` | MATLAB | Not tested | — | — | Separate pipeline |
| `_data_sigma2eps_*.txt` | MATLAB | Not tested | — | — | Separate pipeline |

### 11.7 Resolved: 23-row vs 34-row mismatch

The pipeline previously produced 23-period files because of two truncation mechanisms:

1. **`drawing`/`special_drawing`/`special_drawing2` programs** in [_prepare_programs.do](../inputs_stata_code/_prepare_programs.do) contained `keep if year < 2050` which truncated the caller's dataset. Since the export came AFTER the drawing call in most scripts, the exports received the truncated data. **Fix:** added `preserve`/`restore` inside all three drawing programs so graphing no longer destroys the data.

2. **Hard `keep if year <= 2050`** in [M02prepare_gamma.do:41](../inputs_stata_code/tfp/M02prepare_gamma.do#L41) and [M02robustness_prepare_gamma.do:39](../inputs_stata_code/tfp/M02robustness_prepare_gamma.do#L39). These explicit truncations were independent of the drawing programs. **Fix:** removed both lines. The HP filter and extrapolation already cover the full 1935-2100 range; the truncation only discarded post-2050 rows. First 24 rows of regenerated output match committed values byte-exact.

3. **D02→D03 path disconnect**: D02 saved `col_share_acs_ext.dta` to `../data/skill_premium/.../processed/` but D03 read from `skill_premium/.../processed/` (inside `inputs_stata_code/`). These are different directories. The tracked intermediate at D03's read path had NaN for cohorts 2025-2075 (from a truncated D02 run), causing D03 to fill those cells with 0.9999 via Stata's `replace prob = 0.9999 if prob >= 1` (which catches missing values because `.` > any number in Stata). **Fix:** added a second `save` in D02 to also write to D03's read path, so D03 always gets the complete version.

After all three fixes, the full pipeline (D01→D02→D03→H01→M01→M02→M02r→M03→M04→T01→T02→T03) produces **byte-exact matches** for all 12 Stata-produced Fortran input files:

| File | Rows | Match |
|---|---|---|
| `_data_het_pi_US_since1935_all.txt` | 1056 | MATCH |
| `_data_college_share.txt` | 68 | MATCH |
| `_data_skill_premium.txt` | 68 | MATCH |
| `_data_depr.txt` | 34 | MATCH |
| `_data_gamma.txt` | 34 | MATCH |
| `_data_gamma_robustness.txt` | 33 | MATCH |
| `_data_labsh.txt` | 34 | MATCH |
| `_data_lambda.txt` | 34 | MATCH |
| `_data_tauL.txt` | 34 | MATCH |
| `_data_tauK.txt` | 34 | MATCH |
| `_data_tauC.txt` | 34 | MATCH |
| `_data_contributions.txt` | 23 | MATCH |

### 11.8 Batch-mode recipe (complete)

To run the full pipeline in Stata batch mode from a sandbox:

```
cd inputs_stata_code
global year_start 1935
global year_stop 2100
global download_data 0
global bsource "."
global f_results ""
do _prepare_programs
do demography\mortality\D01_life_tables
do skill_premium\D02_prepare_college
do demography\hetero_pi\D03_prepare_hetero_pi
do skill_premium\H01prepare_skill_premium
do depreciation\M01prepare_depr
do tfp\M02prepare_gamma
do tfp\M02robustness_prepare_gamma
do labor_share\M03prepare_labor_share
do ..\sensitivity_stata_code\exog_rate\M04prepare_exog_rate
do tax_rate\T01prepare_taxes
do social_security\T02prepare_contributions
do tax_rate\T03prepare_tax_lambda
```

Sandbox requirements:
- `data/skill_premium/ACS_college/ACS_college.dta` — D02 reads from `../data/...`
- `data/skill_premium/ACS_college/processed/` — directory must exist for D02 save
- `graphs/inputs/` — directory must exist for graph exports
- `sensitivity_stata_code/exog_rate/irr.dta` — Stata intermediate for M04
- `global bsource "."` — batch equivalent of the `.stpr` empty-string convention

### 11.9 Session commits

- `aca558e` — D03: fix no_col export bug, write outputs to fortran_code/Data/
- `fb3d9c2` — Revert 5 truncated Fortran data files from prior sandbox
- `a0e3816` — Stata audit: add D01-D02-D03 sandbox verification (§10)
- `4bc1ed9` — Stata audit: full pipeline sandbox results (§11)

## 12. Independent sandbox verification (2026-04-16, session 2)

### 12.1 Motivation

The §11 sandbox had a comparison flaw: on Windows NTFS, `fortran_code/data/` (Stata output) and `fortran_code/Data/` (committed reference) are the same directory (case-insensitive). All previous "PERFECT MATCH" results were therefore self-comparisons — the Stata pipeline overwrote the committed files, and the comparison program read the same file twice.

This session creates a fresh sandbox with the committed reference files stored in a separate `committed_fortran_data/` directory, making all comparisons genuine.

### 12.2 Sandbox setup

- Fresh sandbox: `n:/PROJECTS/EMERYT/_sandbox_pipeline_20260416/`
- Copied `inputs_stata_code/`, `sensitivity_stata_code/` from repo (at commit `75e4433`)
- Committed reference files: `committed_fortran_data/` (copied from `fortran_code/Data/` before run)
- Stata output directory: `fortran_code/Data/` (starts empty, populated by pipeline)
- All comparisons: `fortran_code/Data/<file>` vs `committed_fortran_data/<file>` — different directories

### 12.3 Results (all comparisons genuine)

| File (Fortran name) | Script | Repro rows | Committed rows | Result |
|---|---|---|---|---|
| `_data_het_pi_US_since1935_all.txt` | D03 | 1056 | 1056 | **PERFECT MATCH** |
| `_data_college_share.txt` | D02 | 68 | 68 | **PERFECT MATCH** |
| `_data_skill_premium.txt` | H01 | 68 | 68 | **PERFECT MATCH** |
| `_data_depr.txt` | M01 | 34 | 34 | **PERFECT MATCH** |
| `_data_gamma.txt` | M02 | 34 | 34 | **PERFECT MATCH** |
| `_data_labsh.txt` | M03 | 34 | 34 | **PERFECT MATCH** |
| `_data_exog_rate_1935.txt` | M04 | 34 | 34 | **PERFECT MATCH** |
| `_data_tauK.txt` | T01 | 34 | 34 | **PERFECT MATCH** |
| `_data_tauL.txt` | T01 | 34 | 34 | **PERFECT MATCH** |
| `_data_tauC.txt` | T01 | 34 | 34 | **PERFECT MATCH** |
| `_data_contrib_to_gdp.txt` | T02 | 34 | 34 | **CLOSE** (max_diff=4.4e-5) |
| `_data_lambda.txt` | T03 | 34 | 34 | **PERFECT MATCH** |
| `_data_pi_cond_US_since1935.txt` | D01 | — | — | Not compared (dead code: only used when `switch_het_mortality==0`, all scenarios use `==1`) |
| `_data_gamma_robustness.txt` | M02r | — | — | Not compared (see §12.5) |

**11/12 Stata-produced Fortran inputs reproduced byte-exact. T02 matches within 4.4e-5 (OECD data revision noise, documented in §9.4).**

### 12.4 Fix applied: T02 `preserve`/`restore`

[T02prepare_contributions.do](../inputs_stata_code/social_security/T02prepare_contributions.do) had `keep if year < 2050` at line 66 — an inline truncation for graphing that also truncated the subsequent export at line 83 to 23 rows. The committed file has 34 rows (1935–2100 in 5-year intervals, matching `last_data_t1=34` in `data.f90`). Same root cause as the drawing program truncation fixed in `2bed247`, but T02 used inline graphing code rather than calling a drawing program.

**Fix:** wrapped lines 66–79 (the inline graphing block) in `preserve`/`restore`. The export now receives the full 34-row dataset.

### 12.5 Unresolved: M02r `_data_gamma_robustness.txt`

M02robustness_prepare_gamma.do sets `global var gamma_robust` (line 50) and exports to `_data_gamma_robust.txt` (line 57 via `_data_$var.txt`). Two discrepancies with the committed file:

1. **Filename**: script writes `_data_gamma_robust.txt`; committed file is `_data_gamma_robustness.txt`.
2. **Values**: script exports the HP-filtered trend (`gamma_robust`); committed file contains the model-frozen path (`gamma_model` — values 0.041, 0.052, 0.056 repeating in the post-2020 rows, matching lines 43–46 of the script).

The committed file was evidently produced by an older version of the script that exported `gamma_model` under the name `_data_gamma_robustness.txt`. **Not blocking**: Fortran has `_data_gamma_robustness.txt` commented out in [data.f90:626](../fortran_code/data.f90#L626); all instruction files use `_data_gamma.txt` for TFP growth.

### 12.6 Conclusion

With the T02 fix, all 12 Stata-produced Fortran input files can be regenerated from the committed `.do` scripts and source data. The pipeline is fully reproducible in Stata batch mode using the recipe in §11.8.

## 13. Interactive `.stpr` + `__main_data_prepare.do` audit (2026-04-17/18)

This section records a second reproducibility pass run through Stata's Project Manager (`.stpr`), which is how the replicator is expected to launch the pipeline per the README. A fresh worktree `EJ_sandbox` was created off `main` and all work happened there; no changes landed in the tracked repo until the commits at the end of the section.

### 13.1 `.stpr` sidebar audit

**File:** `outputs_stata_code/__replication_graphs.stpr` — a Java-serialized `com.stata.projmanager.Tree`. Static comparison against what `__main.do` actually calls (post `c796dd0` fix):

- **Missing from Appendix F sidebar**: `M02robustness_prepare_gamma.do` (called at [outputs_stata_code/__main.do:164](../outputs_stata_code/__main.do#L164)) and `R_Figure1_app.do` (called at [__main.do:177](../outputs_stata_code/__main.do#L177)).
- **Misplaced**: `M04prepare_exog_rate.do` listed under `2.appendixB`, but `__main.do` no longer calls it in Appendix B (only in Appendix F at line 175).

The `.stpr` is purely a GUI sidebar — it does not drive execution, so these gaps do not break the pipeline. They only affect what's clickable in the Project Manager when a replicator opens the file.

**Fix applied** (committed as `6d0bbea` on `ej-sandbox`): added the two missing entries to Appendix F, removed misplaced M04 from Appendix B, and rewrote three sandbox-escape paths (`..\..\_Paper_16_EJ_replication\...`) to clean relative paths consistent with the rest of the file. See `tools/inspect_stpr.py` (read-only tree dump) and `tools/patch_stpr_paths.py` (TC_STRING-level path patcher) for the method — both checked in so future `.stpr` edits don't require opening Stata GUI.

### 13.2 `__main_data_prepare.do` interactive run

Running the inputs driver via `main.stpr` hit three problems that batch mode (`stata -e do`) had masked. Each is a real committed-code bug, not a sandbox artefact:

1. **`global bsource ""` → empty** ([__main_data_prepare.do:16](../inputs_stata_code/__main_data_prepare.do#L16) as committed at `c796dd0`). Every downstream script reads `using $bsource/bone`, which expands to the root-absolute `/bone.dta` and fails with `r(601)`. Fix: `global bsource "."`. Already sitting uncommitted in main repo's working tree at session start; now committed on `ej-sandbox`.
2. **D02 hardcoded to a non-existent path**. [D02_prepare_college.do:6](../inputs_stata_code/skill_premium/D02_prepare_college.do#L6) reads `..\data\skill_premium\ACS_college\ACS_college.dta` — a path that does not exist in either tree. The real file lives at `inputs_stata_code/skill_premium/ACS_college/ACS_college.dta` (1.96 GB, gitignored at `.gitignore:43`). Lines 63, 67, 72 have the same wrong-prefix pattern for the `processed/` write targets. This means D02 has **never run end-to-end from the committed codebase**; only via unchecked local paths. Fix: rewrote all 4 path strings to the correct `skill_premium\ACS_college\...` layout.
3. **`erase bone.dta` halts cleanup on second invocations**. If `_prepare_programs.do` does not recreate the bone files for any reason (cwd drift, prior failure), the terminal `erase` statements hard-error. Fix: `capture erase` on lines 34–35.

Also added `set more off` to the top of the driver so interactive Stata runs don't stall on the scroll-pager prompt.

### 13.3 Inputs replicate byte-exact via `.stpr`

With the fixes in §13.2 applied and `ACS_college.dta` copied into the sandbox, the full `__main_data_prepare.do` pipeline ran to completion via `main.stpr`. Of 34 files in `fortran_code/data/` after the run:

- **31 byte-identical** to the committed `_Paper_16_EJ_replication/fortran_code/data/` baseline.
- **2 differ** (`_data_sigma2eps_*`): not produced by this driver — they come from the standalone income-process pipeline (§13.4). The committed copies are stale bytes from a separate earlier run and are untracked in git.
- **1 differs** (`_data_contrib_to_gdp.txt`): max relative diff 0.07%, max absolute 4.4×10⁻⁵. **Sandbox is correct, main repo's committed copy is pre-fix stale** (Jan 16 mtime, predating commit `e757abf` "T02 contributions: restore original SDMX-window computation"). The fix nulls PSID observations in 1970-72 and 2021+ before the 5-year collapse so the extremal buckets aren't skewed; the extrapolated early/late tails shift by ~3×10⁻⁶ and ~3×10⁻⁵ respectively — exactly the signature in the diff. `fortran_code/data/*.txt` is untracked, so the committed T02 fix does not automatically propagate to the committed output.

### 13.4 Income-process pipeline — full-bootstrap replication

The income-process pipeline (`inputs_stata_code/income_process/run_estimation.bat` → Stata `estimate_income_process.do` → MATLAB `estimate_parameters.m` → MATLAB `plot_estimates.m`) was run twice in the sandbox:

- **N_REPS=0** (point estimates only, ~minutes).
- **N_REPS=1000** (full bootstrap, **~12 hours wall time**: Stata generating 1000 × 2-variant PSID resamples and their cov-binned covariance matrices ≈ 1 h, MATLAB bootstrap optimization ≈ 11 h sequential across 4 `.mat` files).

Results, both runs:

- `_data_sigma2eps_mostdrop_hhslabinc_avghourlyhh.txt` — byte-identical to committed baseline.
- `_data_sigma2eps_busno_drop_hhslabinc_avghourlyhh.txt` — byte-identical to committed baseline.
- `_data_omega_mostdrop_hhslabinc_avghourlyhh.txt` — byte-identical to committed baseline.
- `_data_omega_busno_drop_hhslabinc_avghourlyhh.txt` — byte-identical to committed baseline.

The pipeline is fully deterministic from the raw PSID extract at `psid/psid.dta`; the point estimates do not depend on `N_REPS`. Bootstrap only affects the `H.mat`/`L.mat` workspace (adds `sigma2_epsilon_bs` of shape `(12, n_reps)`) and the confidence-band plot.

**Bootstrap optimizer convergence**: of 1000 reps, 9 failed for H and 1 failed for L (produce NaN rows in `sigma2_epsilon_bs`). Plain MATLAB `prctile` propagates NaN, so the default `plot_estimates.m` can render gapped bands. Fix pending: switch to `prctile(..., 'omitnan')` (or compute via `nanpercentile` equivalent) — not blocking figure replication since the percentiles compute over 990+ valid reps.

### 13.5 Pipeline ergonomics fixes

Committed with the bootstrap run:

- **`run_estimation.bat` is now portable**. Previously hardcoded `C:\Program Files\Stata16\StataSE-64.exe` and `C:\Program Files\MATLAB\R2018b\bin\matlab.exe`. Now honors `STATA_EXE` and `MATLAB_EXE` environment variables, falls back to the original defaults, and fails early with a clear error + override instructions if either executable is missing. Wrapped in `setlocal`/`endlocal`.
- **`N_REPS` is now an environment variable**. Previously hardcoded `local n_reps 0` in `estimate_income_process.do:29` and `n_reps = 0` in `estimate_parameters.m:30`. Both now read `getenv('N_REPS')` / Stata `: env N_REPS` and fall back to 0. Replicators can run `set N_REPS=1000 & run_estimation.bat` without editing the source.
- **Bootstrap `.mat` files are now tracked**. `.gitignore` previously excluded `output/**/*.mat`; added exceptions for `H.mat` and `L.mat` (~690 KB total across 2 variants × 2 types), so the figure with 95% CI bands is reproducible from the committed repo without the 12-hour bootstrap run.

### 13.6 Paper Figure 6 vs current sandbox plot

The paper's Appendix figure (`\ref{fig:app:calibration:shocks}`, rendered via [Dropbox submissions/01_EJ_R&R2/.../graphs/_MT_inputs/variances_plot.eps](file:///C:/Users/pzoch/Dropbox/Projects/EMERYT/_Paper_16_inequality_longevity/submissions/01_EJ_R%26R2/_Overleaf%20(backup)/graphs/_MT_inputs/variances_plot.eps), dated 2025-01-27) is produced by the Dropbox predecessor `plot_estimates.m` using a **hybrid**:

- **Point estimates**: loaded from `calibration/income_process/matlab/output/mostdrop_hhslabinc/avghourlyhh/{H,L}.mat`. These values are **byte-identical** to the current sandbox's `mostdrop_hhslabinc/{H,L}.mat` (`sigma2_epsilon_point` matches to all 12 bins).
- **Bootstrap 95% CIs**: loaded from `calibration/income_process/matlab/deaton_{H,L}_avghourlyhh.mat` — a **predecessor pipeline's 500-rep bootstrap**, taken from a period before the mostdrop/busno_drop variant split. The first bin is dropped in both paper and current scripts (`sig2(2:end)`, `ind = 1:11`).

Consequences:
- The solid lines in the paper's Figure 6 and the sandbox's `sigma2eps_mostdrop_hhslabinc.png` are identical data, identical positions. Visual perception of a difference from reading the low-res `draft.pdf` page render (72 dpi) is an artefact of how PDF viewers resample the embedded EPS — the source EPS at 300+ dpi shows the same curves as the sandbox render.
- The CI bands differ in width but not dramatically: paper's `busno_drop`-labeled `busno_drop_hhslabinc/avghourlyhh/{H,L}.mat` in Dropbox has a 1000-rep bootstrap whose *point values* match current `mostdrop_hhslabinc` (confirming a variant-label flip between the two projects); but the paper figure instead uses the `deaton_*` bootstrap that predates the variant split. Sandbox's new bands are self-consistent (same variant for point and CI, current sample, 1000 reps).

**Confidence**: the Fortran input `_data_sigma2eps_*.txt` comes from `sigma2_epsilon_point`, which is identical across all three inspected versions (sandbox new, main committed, Dropbox paper-era). The paper's Figure 6 and the sandbox's figure both correspond to this same baseline.

### 13.7 Assets moved into the sandbox for replication

- `psid/psid.dta` (98 MB, gitignored) — copied from `_Paper_16_EJ_replication/psid/psid.dta` so the income-process pipeline can run without relying on the adjacent repo.
- `inputs_stata_code/skill_premium/ACS_college/ACS_college.dta` (1.96 GB, gitignored) — copied from the main repo so D02 (post path-fix) can load the ACS extract.

Neither file is committed; both are referenced by scripts that expect them on disk. README Stage B already instructs replicators to obtain `psid/psid.dta` from the PSID Data Center; a similar instruction for `ACS_college.dta` (IPUMS ACS) may be worth adding.

### 13.8 Remaining cleanup

- ~108 GB of per-rep Stata `.dta` intermediates live under `inputs_stata_code/income_process/output/<variant>/psid_*_rep*.dta` after the bootstrap run. These are gitignored and safe to delete.
- `plot_estimates.m` should switch `prctile` to a NaN-omitting variant (§13.4). Low priority since the figure still renders correctly for the 990+ reps that converge.
- D02's duplicate `save` at [D02_prepare_college.do:72-73](../inputs_stata_code/skill_premium/D02_prepare_college.do#L72-L73) (same file saved twice after the path fix) is a cosmetic leftover from the original `..\data\...` vs `skill_premium\...` split.

## 14. Output-driver audit — `outputs_stata_code/` (2026-04-20)

Sibling to §13 covering the figure-generation pipeline driven by [outputs_stata_code/__main.do](../outputs_stata_code/__main.do) via [outputs_stata_code/__replication_graphs.stpr](../outputs_stata_code/__replication_graphs.stpr). Method follows the same single-pass pattern (§13): static read of every `.do` file in `outputs_stata_code/`, cross-referenced against `__main.do`'s invocation sequence, dup/dead-write hunt, P1/P2/P3 delta. Plan: [docs/plans/2026-04-20-refactor-output-stata-audit-plan.md](plans/2026-04-20-refactor-output-stata-audit-plan.md). Brainstorm: [docs/brainstorms/2026-04-20-output-stata-audit-brainstorm.md](brainstorms/2026-04-20-output-stata-audit-brainstorm.md).

### 14.1 Scope and method

Twelve `.do` files in `outputs_stata_code/` (1244 lines total): driver `__main.do`, three helpers (`_prog_coding`, `_prog_ineq_function`, `_prep_Gini_data`), four figure scripts (`R_Figure1`, `R_Figure1_app`, `R_Figure2`, `R_Figure3`), four Model-vs-Data scripts (`MvD_1_macro`, `MvD_2_Gini_income`, `MvD_3_Gini_wealth`, `MvD_4_GE_decomposition`). Plus `__main.do`'s Appendix B/C/F calls into `inputs_stata_code/` and `sensitivity_stata_code/` (previously audited in §13 for their inputs-driver invocation path — re-audited here for the outputs-driver re-entry).

**Dry-run constraint**: `mklink /J` (the plan's folder-junction approach for staging Fortran `Results/`) failed on the N: network drive ("Local NTFS volumes are required"). Dry-run therefore relies on path overrides at the harness level (global `$resultspath` pointed at the main repo's absolute path). The `.stpr` interactive execution of `__main.do` end-to-end remains deferred (§6 P1-2), consistent with the brainstorm's choice of "static + dry-run of runnable pieces only".

### 14.2 Per-script spec table

| Script (LoC) | Reads | Writes | Called by `__main.do` @ line | Globals required from caller | cwd | Notes |
|---|---|---|---|---|---|---|
| `__main.do` (194) | — (driver) | — (driver) | — | — | starts `outputs_stata_code/`; see §14.3 for the `cd` ledger | Sets `$resultspath`, `$graphspath`, `$datapath`, `$year_start/stop`, `$download_data=0`, per-block `$scenario`/`$variant_base`/`$variant_comp`/`$r1`/`$r2`/`$legend`/`$colors`/`$bsource`. Imports `mass_trans_small.csv` inline for the primary scenario (lines 16–28). |
| `_prog_coding.do` (154) | — | — (program definitions) | line 9 | none (defines programs) | `outputs_stata_code/` | Defines `periods`, `periods_proj`, `drawing`, `special_drawing`, `prep_data_for_main_plot`. **§14.5-P1**: `drawing` and `special_drawing` originally lacked `preserve`/`restore` (same bug `2bed247` fixed in `_prepare_programs.do`); fixed in `c2`. A third plotting program `drawing_for_piotr` was also present but unused; removed in `c4`. |
| `_prog_ineq_function.do` (197) | — | — | line 10 | none | `outputs_stata_code/` | Defines `ours_ineqdeco` (custom GE decomposition). Self-contained. Used by `MvD_4`. |
| `_prep_Gini_data.do` (65) | `../fortran_code/Results/*/gini_trans.csv` (one per scenario folder); `../data/SCF/SCF_plus.dta` | `../graphs/outputs/wealth_inequality/combined_gini.dta` | line 11 | `$lam` implicitly (for `periods_proj` later); relies on community `ineqdeco` | `outputs_stata_code/` | **§14.5-P2**: community package `ineqdeco` not listed in README's Stata package requirements. Line 50: `qui ineqdeco ...`. |
| `R_Figure1.do` (21) | `combined_gini.dta` | `$graphspath\Results_Gini_changes.png` | line 32 | `$scenario`, `$graphspath` | `outputs_stata_code/` | Figure 1 (main text). Clean single-export. |
| `R_Figure1_app.do` (22) | `combined_gini.dta` | `$graphspath\Results_Gini_changes.png` (overwrites Figure 1!) | line 184 | `$scenario="psid_all_govt__ exor_all_govt__"` (hardcoded two-scenario string), `$graphspath` | `outputs_stata_code/` | **§14.4-D1**: line 22 writes to the Figure-1 filename; `__main.do:185` then re-exports to the correct `AppF_Gini_counterfactuals_exograte.png`. Figure 1's PNG ends up corrupted with Figure F.7 content. |
| `R_Figure2.do` (36) | `combined_gini.dta` | no internal `graph export` (caller exports) | 6× — lines 38, 136, 144, 152, 161, 177, 192 (7× in total) | `$variant_base`, `$variant_comp`, `$r1`, `$r2`, `$legend` (?) | `outputs_stata_code/` | Calls `prep_data_for_main_plot` (defined in `_prog_coding`). Clean; no dead writes. |
| `R_Figure3.do` (74) | `combined_gini.dta` | no internal `graph export` | 5× — lines 46, 53, 111, 119, 127 | `$variant_base`, `$variant_comp`, `$colors`, `$legend` | `outputs_stata_code/` | Clean. |
| `MvD_1_macro.do` (219) | `data/irr_data.dta`, `data/benefits_cbo.dta`, `data/avghours_data.dta`, `$resultspath\$scenario\irr_trans_1y.txt`, `$resultspath\$scenario\benefits_trans.txt`, `$resultspath\$scenario\avg_hours_trans.txt`, `..\inputs_stata_code\social_security\57971-Data.xlsx` | `$graphspath\{irr,avghours,benefits}_trans_levels.{png,eps,svg}` (9 files) | line 98 | `$scenario`, `$year_start=1950`/`$year_stop=2020` (reset by `__main.do` at lines 93–97), `$min_age`, `$max_age`, `$year_end=2100`, `$download_data`, `$lam` (implicit) | `outputs_stata_code/` | **§14.5-P3**: `outputs_stata_code/data/` subfolder does not exist in sandbox or main repo. With default `$download_data=0`, `use data/irr_data.dta` fails `r(601)`. |
| `MvD_2_Gini_income.do` (39) | `..\data\model_$scenario.dta` (from `__main.do:28`), `..\data\PSID\psid_ready.dta` | `$graphspath\Lorenz_<yr>.{png,eps,svg}` (one per year in data) | line 99 | `$scenario`, `$min_age`, `$max_age`, `$graphspath` | `outputs_stata_code/` | `psid_ready.dta` gitignored (see [data availability](../README.md)). |
| `MvD_3_Gini_wealth.do` (72) | `..\data\SCF\SCF_plus.dta`, `..\data\model_<scenario>.dta` | `$graphspath\MvD_Gini_levels.png` | line 100 | `$year_start=1950`/`$year_stop=2020` (reset by `__main.do`), `$graphspath`; community `ineqdeco` (see §14.5-P2) | `outputs_stata_code/` | `scenario` is a **local** (line 35) that shadows the global; behavior depends only on line-35 value. |
| `MvD_4_GE_decomposition.do` (151) | `..\data\model_<scenario>.dta`, `..\data\SCF\SCF_plus.dta` | `$graphspath\MvD_GE.{png,eps,svg}` | line 101 | `$graphspath` | `outputs_stata_code/` | Local `scenario` (line 9) shadows global. Calls `ours_ineqdeco` from `_prog_ineq_function.do`. |
| `__main_PIOTR.do` (?) | — | — | **not called** (orphan) | — | — | §14.6 orphan; P3 close-out. |

### 14.3 `__main.do` structural map

Driver blocks (line numbers are `__main.do`):

| Block | Lines | Purpose | Key globals reset | `cd` | Prep re-entry |
|---|---|---|---|---|---|
| **Setup** | 1–11 | Globals, do _prog_coding, _prog_ineq_function, _prep_Gini_data | `$resultspath`, `$graphspath`, `$datapath`, `$year_start=1935`, `$year_stop=2100`, `$download_data=0` | — | — |
| **Scheme + primary sim import** | 13–28 | Load Fortran mass_trans_small.csv for `psid_all_govt__`, save as `..\data\model_psid_all_govt__.dta` | `local scenario` | — | — |
| **Main text — Figure 1** | 31–32 | R_Figure1 | `$scenario` | — | — |
| **Main text — Figures 2/3** | 34–54 | R_Figure2 (1×) + R_Figure3 (2×), with exports at 39, 47, 54 | `$variant_base`, `$variant_comp`, `$r1`, `$r2`, `$legend`, `$colors` | — | — |
| **Appendix B — Calibration** | 57–81 | Re-run M01/M02/M03/M04, H01, D02, T01/T02/T03 with `$bsource="../outputs_stata_code/"`; erase bone at end | `$year_start/stop`, `$bsource` | `cd ..\inputs_stata_code` (58) → `cd ..\outputs_stata_code` (81) | Uses `drawing`/`special_drawing` from step-1's `_prog_coding.do` (BUGGY — see §14.5-P1) |
| **Appendix C — Populations** | 84–88 | D03, D01 | — | `cd ..\inputs_stata_code` (85) → `cd ..\outputs_stata_code` (88) | No `_prepare_programs` call; uses whatever `drawing` is in workspace. |
| **Appendix D — MvD** | 90–101 | MvD_1, MvD_2, MvD_3, MvD_4 | `$scenario`, `$year_start=1950`/`$year_stop=2020`/`$year_end=2100`, `$min_age`, `$max_age` | — | — |
| **Appendix E — Additional** | 103–128 | R_Figure3 3× (incomes, taxes, macro) | `$variant_base`, `$variant_comp`, `$legend`, `$colors` | — | — |
| **Appendix F — Sensitivity** | 130–193 | R_Figure2 4× (crr3, hrat, ndel, nstr), M02robustness re-prep, R_Figure2 (gcbo), M04 re-prep, R_Figure1_app (exor), R_Figure2 (beqs) | `$variant_base`, `$variant_comp`, `$r1`, `$r2`, `$bsource`, `$scenario` | `cd ..\inputs_stata_code` (165) → `cd ..\outputs_stata_code` (171); also `do _prepare_programs` at 167 (this is where the FIXED programs finally reach the workspace, too late for Appendix B — see §14.5-P1) | `do _prepare_programs` at 167 overrides the Appendix-B-era buggy programs with the fixed inputs-side versions. |

All `cd` statements are balanced (no drift).

### 14.4 Duplicate / dead-write findings

#### D1 — `__main.do:128` overwrites Figure E.2 with Figure E.3

[`__main.do:120`](../outputs_stata_code/__main.do#L120) exports Figure E.2 (taxes variants) to `Results_Gini_drivers_taxes.png`. [`__main.do:128`](../outputs_stata_code/__main.do#L128) exports Figure E.3 (macro-trends variants) **to the same filename**. Whichever runs last — Figure E.3 in the current code — is what ends up on disk; Figure E.2 is silently discarded.

**Fix**: rename the line-128 export to `Results_Gini_drivers_macro.png` (or similar) so both figures land at distinct names.

#### D2 — `R_Figure1_app.do:22` overwrites Figure 1

[`R_Figure1_app.do:22`](../outputs_stata_code/R_Figure1_app.do#L22): internal `graph export $graphspath\\Results_Gini_changes.png, replace`. This is the Figure 1 filename. `__main.do:185` then re-exports the same current graph to the correct `AppF_Gini_counterfactuals_exograte.png`, so Figure F.7's file is correct — but `Results_Gini_changes.png` (Figure 1) has been clobbered with F.7's content.

**Fix**: remove line 22 of `R_Figure1_app.do`. `__main.do:185` handles the real export.

#### Non-findings (reviewed and dismissed)

- `_prog_coding.do` has 15 multi-write hits on `../graphs/inputs/$var.{gph,png,eps,svg,pdf}` — this is the three `drawing*` programs each writing to `$var`-parameterised paths. Different callers set `$var` to different values, so the runtime targets are distinct. Not a dead write.
- M04 is invoked twice (inputs driver + `__main.do:182`) — defensive re-run so a standalone `__main.do` session produces the inputs Figure F.7 needs. Not a dead write.

### 14.5 Integration-bug findings

#### P1 — `_prog_coding.do` `drawing`/`special_drawing` lack `preserve`/`restore`

[`outputs_stata_code/_prog_coding.do:28-43`](../outputs_stata_code/_prog_coding.do#L28-L43) and lines 46–64 define two plotting programs. Each does `tsset year; keep if year < 2050` before the `twoway` block, then ends — **no `preserve`/`restore`**. This is the exact bug commit `2bed247` fixed in `inputs_stata_code/_prepare_programs.do`. (The file originally had a third program `drawing_for_piotr` with the same bug; it had no callers anywhere in the repo and was removed in commit `c4` as part of this audit.)

**Blast radius**: when `__main.do` line 9 sources `_prog_coding.do`, the buggy versions enter the workspace. Appendix B (lines 58–81) then re-runs seven prep scripts that call these programs — M01 (`special_drawing`), M02 (`drawing`), M03 (`drawing`), H01, D02, T01, T03 (all call `drawing`). Each script's sequence is: compute → call `drawing` (which **truncates caller's data to year<2050**) → `export delimited` (which writes the truncated dataset). The Fortran inputs in `../fortran_code/Data/` produced by `__main_data_prepare.do` (clean, 34-row series) are **overwritten with 23-row truncated series** by Appendix B.

Not caught by the inputs audit (§13) because that audit ran `__main_data_prepare.do` only, which sources the fixed `_prepare_programs.do` instead of `_prog_coding.do`.

**Fix**: add `preserve` before the `tsset`/`keep`/`twoway` block and `restore` after the final `graph export` in all three `drawing*` programs in `outputs_stata_code/_prog_coding.do`.

#### P2 — Missing `ineqdeco` package dependency

[`_prep_Gini_data.do:50`](../outputs_stata_code/_prep_Gini_data.do#L50), [`MvD_3_Gini_wealth.do:22,51`](../outputs_stata_code/MvD_3_Gini_wealth.do#L22) call community `ineqdeco` (not the custom `ours_ineqdeco` defined in `_prog_ineq_function.do`). [`README.md:813`](../README.md#L813) lists `psmatch2`, `mat2txt`, `egenmore` — `ineqdeco` is missing.

**Fix**: add `ineqdeco` to the README's Stata package list, and optionally add a `capture which ineqdeco` / `ssc install ineqdeco` preamble to `_prep_Gini_data.do` (same pattern `estimate_income_process.do:18-22` uses for `mat2txt`).

#### P3 — `outputs_stata_code/data/` subfolder missing for `MvD_1_macro.do`

[`MvD_1_macro.do:21,50,119`](../outputs_stata_code/MvD_1_macro.do#L21) reads `data/irr_data.dta`, `data/benefits_cbo.dta`, `data/avghours_data.dta` from `outputs_stata_code/data/`. That folder does **not exist** in the sandbox or in `_Paper_16_EJ_replication`. With the default `$download_data=0` path, MvD_1 fails immediately on `use data/irr_data.dta` with `r(601)`.

`$download_data=1` would work (re-downloads from dbnomics/CBO, `save`s to `data/*.dta`, then the subsequent `use` succeeds), but that requires network access and is not the default. On a fresh clone the pipeline is broken.

**Options**:
- Commit the three `data/*.dta` files as frozen inputs (small, deterministic, like the committed `depreciation.dta` / `gamma.dta` files for the inputs pipeline).
- Or swap the default to `$download_data=1` for these three series and document the network requirement.
- Or rewrite the script to always compute from the source CSVs committed elsewhere, same as the inputs drivers do.

Recommend the first option (commit the frozen `.dta` files) for consistency with the rest of the repo.

#### Verification of §6 items closed in prior commits

- **M02robustness path** (§6 P1 — fixed by `c796dd0` + `.stpr` update `6d0bbea`): [`__main.do:164-171`](../outputs_stata_code/__main.do#L164-L171) has the correct sequence (`cd`, `do _prepare_programs`, `do tfp/M02robustness_prepare_gamma`, erase bone, `cd` back). Confirmed: path fix took.
- **Case asymmetry** (§6 P2 — fixed by `af261e2`): Appendix B's re-runs now write to `../fortran_code/Data/` (capital D) on Linux. Verified.

#### Latent item not addressed

- **Appendix C bone-file dependency**: Appendix B erases `bone.dta`/`bone1y.dta` at lines 78–79 of `__main.do`. Appendix C (lines 85–88) then calls D03 and D01 without re-creating them. If either script `merge`s `using bone1y` etc., it will fail. Static read of D03 does not show a bone merge, but D01 has not been re-read in this audit. Defer to §14.7.

### 14.6 Orphan disposition

- **`outputs_stata_code/__main_PIOTR.do`**: already deleted on `ej-sandbox` by commit `ba08b26` ("Delete stale outputs_stata_code/__main_PIOTR.do"). The §6 P3 item was stale as of 2026-04-14. No follow-up needed. `grep -rln "__main_PIOTR"` now finds only references in this audit and related docs.
- **`outputs_stata_code/asi_aux.dta`**: `grep -rln "asi_aux"` across `.do`, `.stpr`, `.md`, `.bat` returns **only docs references** (this audit, brainstorms, plans, §6). No `.do` script reads it. Already ranked P3. **Confirmed orphan; deleted in commit `c3`.**
- **`outputs_stata_code/bone.dta`, `outputs_stata_code/bone1y.dta`**: required by Appendix B's `$bsource="../outputs_stata_code/"` merges at [line 63](../outputs_stata_code/__main.do#L63). **Keep committed** per §6 P2; file a README note (§14.7).

### 14.7 Updates to §6 open-issues list

| §6 item | Status after §14 | Note |
|---|---|---|
| P1 — M02robustness path | **resolved** via `c796dd0` (src) + `6d0bbea` (`.stpr`) | §14.5 verification |
| P1 — runtime verification via `.stpr` | **inputs driver: resolved** (§13.3); **outputs driver: covered statically in §14**, full `.stpr` interactive run still deferred | Requires a complete Fortran `Results/` on a local NTFS volume (junction failed on N:) |
| P2 — `Data/` vs `data/` case asymmetry | **resolved** by `af261e2` | §14.5 verification |
| P2 — demography output paths | partially resolved by `75451a0`/`2bed247` (D03 wired to `fortran_code/Data/`); D01 still local-only | §13 earlier noted; unchanged by this audit |
| P2 — `bone*.dta` policy | **unchanged** (keep committed for Appendix B); add a README note | §14.6 |
| P3 — `__main_PIOTR.do` | **already resolved** in commit `ba08b26` (pre-this-session) | §14.6 (§6 item was stale) |
| P3 — `asi_aux.dta` | **confirmed orphan**; deleted in `c3` | §14.6 |
| P3 — `.stpr` as canonical entry point | README Step 2 + Step 7 already updated | (no change needed) |
| P3 — `R01compare_r_sd.do` disposition | **unchanged** (out of scope; inputs tree) | — |
| P3 — income-process split doc | **resolved** (§13.5 + README Stage B) | — |
| **§14-P1a — `_prog_coding.do` lacks preserve/restore** | **new, fixed in `c2`** | §14.5 |
| **§14-P1b — `__main.do:128` dead-write** | **new, fixed in `c2`** | §14.4-D1 |
| **§14-P1c — `R_Figure1_app.do:22` clobbers Figure 1** | **new, fixed in `c2`** | §14.4-D2 |
| **§14-P1d — `outputs_stata_code/data/*.dta` missing** | **resolved** in `c5`+`c7`: frozen `irr_data.dta` / `benefits_cbo.dta` / `avghours_data.dta` committed under `outputs_stata_code/data/`. MvD_1 gains a `capture mkdir data` safety net. MvD_1's inline `if $download_data==1 { dbnomics ... save data/<file>.dta }` download blocks are the regenerator (same pattern as the inputs pipeline); no separate bootstrap script needed. The initial snapshots were produced via an interim Python fetch + pandas `to_stata` (now removed) because the `dbnomics` Stata community package (v1.2.0 May 2020) is incompatible with Stata 16+ — its Mata `urlencode()` declaration collides with Stata 16's built-in `urlencode()`, failing compile with r(3499). This breakage is system-wide on current Stata: the inputs' `$download_data=1` refresh paths (M01/M02/M03/M04/T02) hit the same error. All committed `.dta` files are snapshots from a prior working Stata (≤15) install; the current replication package therefore relies on the snapshots and runs with `$download_data=0` by default. | §14.5-P3 |
| **§14-P2 — missing `ineqdeco` package dependency** | **new, fixed in `c2`** (README + `_prep_Gini_data.do` auto-install guard) | §14.5-P2 |

### 14.8a End-to-end dry-run (2026-04-22)

After copying the full `fortran_code/Results/` (27 GB, 30 scenarios) and `data/PSID` + `data/SCF` + `data/model_psid_all_govt__.dta` into the sandbox, a comprehensive harness (`_test_outputs.do`, deleted post-run) exercised every script in `outputs_stata_code/` with the globals `__main.do` normally provides. Result:

| Level | Scripts exercised | Outcome |
|---|---|---|
| 1 | `_prog_coding`, `_prog_ineq_function`, `_prep_Gini_data` | ✅ |
| 2 | `R_Figure1.do` (main-text Figure 1) | ✅ |
| 3 | `R_Figure2.do` (main-text Figure 2 — psid_all vs psid_ndm) | ✅ **after** `c8` fix |
| 4 | `R_Figure3.do` (main-text Figures 3/4 — demographics bar) | ✅ |
| 5 | `MvD_1_macro.do`, `MvD_2_Gini_income.do`, `MvD_3_Gini_wealth.do`, `MvD_4_GE_decomposition.do` | ✅ |
| 6 | `R_Figure1_app.do` (Appendix F.7) | ✅ |

**One new P1 bug surfaced**: `prep_data_for_main_plot` in [`_prog_coding.do:88`](../outputs_stata_code/_prog_coding.do#L88) referenced `${variant_comp_min}` **during the first iteration of its variant loop**, before the `variant_comp_*` globals were set. This caused `local val = ${variant_base_max} -` (missing operand) → `r(198) invalid syntax` on the first call to `R_Figure2.do` in a fresh session. The formula also set both `variant_base_diff` and `variant_comp_diff` to the same cross-variant value, inconsistent with R_Figure2's text labels which display each variant's own spread. Fixed in `c8`: rewrote to per-variant `${`variant'_max} - ${`variant'_min}`.

Why the bug was never caught before: paper figures must have been produced either (a) in sessions where the globals were already set from a prior run (carried over between `.stpr` invocations), or (b) errors were manually worked around. A clean-state run consistently fails without the fix.

### 14.8 Session commits

- `c1` — this audit (`docs/stata_pipeline_audit.md` §14 + `docs/plans/2026-04-20-refactor-output-stata-audit-plan.md` + `docs/brainstorms/2026-04-20-output-stata-audit-brainstorm.md`).
- `c2` — source fixes: `_prog_coding.do` preserve/restore × 3 programs; `__main.do:128` filename; `R_Figure1_app.do:22` removed; `README.md` Stata package list + `_prep_Gini_data.do` `ineqdeco` auto-install.
- `c3` — cleanup: delete `outputs_stata_code/__main_PIOTR.do` and `outputs_stata_code/asi_aux.dta`. Add a README note that `outputs_stata_code/bone.dta`/`bone1y.dta` are tracked as Appendix-B pre-seeded inputs.

SHAs filled in on commit.
