---
title: Stata Pipeline Audit and Pending-Modification Commit
type: refactor
date: 2026-04-13
source_brainstorm: docs/brainstorms/2026-04-13-stata-pipeline-audit-brainstorm.md
---

# Stata Pipeline Audit and Pending-Modification Commit

## Overview

Produce a read-only audit of the three Stata folders (`inputs_stata_code/`, `outputs_stata_code/`, `sensitivity_stata_code/`), commit the 14 pending modifications that are currently sitting uncommitted in the working tree, and validate the end-to-end pipelines by running both drivers in a scratch copy and diffing their outputs against the tracked Fortran inputs. No existing `.do`, `.dta`, or `.stpr` file is edited. Integration issues are documented as a ranked TODO list inside the audit document for a future session to act on.

## Problem Statement / Motivation

The replication package's Stata layer is mostly wired up but has drifted:

1. **14 files are modified but uncommitted** across the three Stata folders, reflecting in-progress work that needs to be captured cleanly before further changes land.
2. **Integration gaps** were identified during brainstorming but not verified or documented anywhere canonical:
   - `inputs_stata_code/r_sd/R01compare_r_sd.do` is never called from `__main_data_prepare.do` and writes nothing into `fortran_code/Data/`.
   - `outputs_stata_code/__main_PIOTR.do` (154 lines) has diverged structurally from `__main.do` (187 lines) — provenance unclear.
   - `outputs_stata_code/asi_aux.dta` is not referenced by any `.do` file.
   - `inputs_stata_code/demography/` is dispatched from `outputs_stata_code/__main.do`, not from the main input driver — unusual, possibly intentional, undocumented.
   - `outputs_stata_code/bone.dta`, `bone1y.dta` are tracked even though `__main_data_prepare.do` erases them at the end of every run.
   - Both `.stpr` files are binary Java-serialized Stata workspaces — unreviewable by diff and probably don't belong in git.
3. **No end-to-end verification exists** that the current Stata drivers actually produce the files the Fortran model consumes. The pipeline is assumed to work because the last successful run was weeks ago.

The audit answers, once and authoritatively: what does every Stata file do, which ones are reachable from a driver, what does each driver actually produce, and where are the gaps?

## Proposed Solution

Five phases, executed in order. Each phase commits its own artifact so progress is visible in `git log`.

**Phase 1 — Commit pending modifications.** Stage and commit all 14 pending Stata modifications in a single, descriptive commit. No edits, no cleanups, no renames. This frees the working tree for the audit artifacts.

**Phase 2 — Static audit.** Trace the call graphs of both `__main_data_prepare.do` and `__main.do` by reading files (no Stata execution). Build a table of every `.do`, `.dta`, `.stpr`, and tracked `.txt` in the three Stata folders with columns: path, kind, reads, writes, reached-from, status. Status is one of: live, orphan, stale-duplicate, temp-intermediate, exploratory, binary-workspace, unknown.

**Phase 3 — Scratch-copy dry-run.** Copy `inputs_stata_code/` and `outputs_stata_code/` (and `sensitivity_stata_code/` since it is referenced from the input driver) to a scratch directory outside the repo. Run `__main_data_prepare.do` and `__main.do` there against read-only copies of `data/`, `psid/`, and `fortran_code/Results/`. Capture the full Stata logs. Diff the scratch outputs against the tracked files in `fortran_code/Data/` and `graphs/outputs/`. Record which files match, which differ, and which fail to build.

**Phase 4 — Write the audit document.** Consolidate Phase 2 and Phase 3 findings into `docs/stata_pipeline_audit.md`. Structure: intro, static call graph, per-file status table, dry-run results, open issues TODO list (ranked P0–P3). The TODO list is the only thing that survives beyond this session as actionable work.

**Phase 5 — Commit the audit.** Single commit adding `docs/stata_pipeline_audit.md` plus the brainstorm and plan files under `docs/brainstorms/` and `docs/plans/`.

## Technical Considerations

- **Read-only constraint is strict.** No edits to any existing `.do`, `.dta`, or `.stpr` file. No `.gitignore` edits. Violations require an explicit user exception, flagged in chat before acting.
- **Windows paths in Stata scripts.** `outputs_stata_code/__main.do:1-3` uses backslash-quoted globals (`"..\fortran_code\Results\"`). The scratch copy must preserve the relative layout so that `..\fortran_code\Results\` still resolves. Simplest: create the scratch directory as a sibling of `fortran_code/` with the same name as the original folder, and symlink `fortran_code/` into the scratch parent.
- **Stata single-user license** (noted in the income-process learning): close any interactive Stata before running the scratch drivers in batch mode.
- **Binary `.stpr` files** cannot be meaningfully diffed. The audit treats them as opaque and recommends (does not perform) gitignoring them.
- **Income-process pipeline is intentionally separate** per [docs/solutions/integration-issues/income-process-pipeline-consolidation.md](docs/solutions/integration-issues/income-process-pipeline-consolidation.md). The audit must record this as "intentional isolation, see learning" rather than flagging it as an issue.
- **Demography pipeline asymmetry** is similarly documented in the audit but not restructured.
- **`bone*.dta` modifications** exist even though the driver erases them at the end. Possible causes: someone ran a partial script that didn't reach the `erase` lines, or the files were re-added after a later run. The audit records the state without judging it; commit Phase 1 captures whatever is in the working tree as-is.

## Acceptance Criteria

### Functional

- [ ] Phase 1 commit exists in `git log`, containing exactly the 14 pending Stata modifications (no other files, no edits to the files themselves).
- [ ] `docs/stata_pipeline_audit.md` exists and covers every tracked file in `inputs_stata_code/`, `outputs_stata_code/`, and `sensitivity_stata_code/` (excluding gitignored intermediates).
- [ ] The audit contains a static call graph section showing which scripts are reachable from each of the two `__main*.do` drivers.
- [ ] The audit contains a dry-run results section with: Stata exit status for each driver, list of files produced, diff summary against tracked `fortran_code/Data/` files (match / differ / missing).
- [ ] The audit ends with a ranked TODO list (P0–P3) covering at minimum: `r_sd/` disposition, `__main_PIOTR.do` disposition, `asi_aux.dta` disposition, `.stpr` tracking policy, `bone*.dta` gitignore decision, demography-asymmetry documentation.
- [ ] Phase 5 commit exists adding the audit doc (and optionally the brainstorm + plan).
- [ ] No `.do`, `.dta`, or `.stpr` file in the three Stata folders has been edited by this session (verified by `git diff` on the Phase-1 baseline).

### Non-functional

- [ ] Scratch dry-run runs outside the repo tree; the real working tree is untouched by the run.
- [ ] Audit document is under ~500 lines and readable in one sitting.
- [ ] Audit records absolute confidence level for each status classification (high/medium/low) so future readers can judge which findings need re-verification.

### Quality gates

- [ ] Phase 1 commit message names the scope precisely ("Stata: snapshot pending driver + calibration updates", not "WIP").
- [ ] Audit TODO list is ranked, not a flat bag of notes.
- [ ] Every "orphan" or "stale" classification in the audit is supported by a grep or static trace, not inference.

## Success Metrics

- Future sessions can answer "is this Stata file still used?" from the audit in under 30 seconds without re-scanning the tree.
- Dry-run either confirms the pipelines are green end-to-end, or produces a concrete failing command the user can act on — no ambiguous "looks fine" result.

## Dependencies & Risks

- **Dependency**: Stata must be installable/callable from the command line on this machine. If it is not, Phase 3 degrades to "static-only audit" and the plan flags Phase 3 as deferred rather than silently skipping it.
- **Dependency**: `fortran_code/Results/psid_all_govt__/` must exist for `__main.do` to run (it reads `mass_trans_small.csv` from there). If Results are stale or missing, Phase 3 records the gap rather than trying to regenerate them.
- **Risk**: The scratch copy could accidentally touch the real `fortran_code/Data/` if the drivers use absolute paths. Mitigation: inspect each driver's `global` path definitions before the dry-run, and if any absolute path leaks to the real tree, degrade Phase 3 to a targeted subset.
- **Risk**: Running `__main_data_prepare.do` erases `bone.dta`/`bone1y.dta` in the scratch copy — harmless (files are regenerated), but worth noting.
- **Risk**: The 14 pending modifications include `.dta` files (`bone.dta`, `bone1y.dta`, `_replication_graphs.stpr`) which are binary. Committing them captures a frozen snapshot; the audit flags these for the follow-up session.

## Open Questions (carried from brainstorm)

1. Once the audit confirms `r_sd/` is exploratory, should it be wired into `__main_data_prepare.do`, archived under `docs/archive/`, or left in place?
2. `__main_PIOTR.do` — archive, delete, or keep?
3. `.stpr` files — gitignore as IDE state?
4. `bone*.dta` / `asi_aux.dta` — gitignore confirmed as temp files?
5. Demography and income-process entry points — consolidate into `__main_data_prepare.do`, or bless the current split in README?

These questions are answered in a follow-up session, not this one.

## Implementation Phases

### Phase 1 — Commit pending modifications

**Tasks**
1. Run `git status --short` against the three Stata folders to confirm the exact 14-file list.
2. Stage those 14 files explicitly by path (no `git add -A`, no `git add .`), so nothing outside the Stata scope slips in.
3. Run `git diff --cached --stat` and confirm only the expected files are staged.
4. Commit with message:

   ```
   Stata: snapshot pending calibration + output driver updates

   Captures in-progress modifications across inputs_stata_code/,
   outputs_stata_code/, and sensitivity_stata_code/ prior to
   the pipeline audit in docs/stata_pipeline_audit.md.
   ```

5. Verify with `git status` that the working tree is clean for the three Stata folders.

**Pseudocode example**
```bash
# Phase 1
git status --short inputs_stata_code outputs_stata_code sensitivity_stata_code
# confirm 14 files
git add \
  inputs_stata_code/__main_data_prepare.do \
  inputs_stata_code/depreciation/M01prepare_depr.do \
  inputs_stata_code/income_process/output/busno_drop_hhslabinc/_data_sigma2eps_busno_drop_hhslabinc_avghourlyhh.txt \
  inputs_stata_code/income_process/output/mostdrop_hhslabinc/_data_sigma2eps_mostdrop_hhslabinc_avghourlyhh.txt \
  inputs_stata_code/labor_share/M03prepare_labor_share.do \
  inputs_stata_code/skill_premium/D02_prepare_college.do \
  inputs_stata_code/skill_premium/H01prepare_skill_premium.do \
  inputs_stata_code/tfp/M02prepare_gamma.do \
  outputs_stata_code/MvD_1_macro.do \
  outputs_stata_code/__main.do \
  outputs_stata_code/__replication_graphs.stpr \
  outputs_stata_code/bone.dta \
  outputs_stata_code/bone1y.dta \
  sensitivity_stata_code/exog_rate/M04prepare_exog_rate.do
git diff --cached --stat
git commit -m "$(cat <<'EOF'
Stata: snapshot pending calibration + output driver updates

Captures in-progress modifications across inputs_stata_code/,
outputs_stata_code/, and sensitivity_stata_code/ prior to
the pipeline audit in docs/stata_pipeline_audit.md.
EOF
)"
```

**Success criteria**
- Exactly one commit added, touching exactly the 14 files, no edits.
- `git status` on the three Stata folders shows clean.

---

### Phase 2 — Static audit

**Tasks**
1. Read `inputs_stata_code/__main_data_prepare.do` top-to-bottom. Record every `do <path>` call in a table: caller, callee, line number.
2. Read `outputs_stata_code/__main.do` top-to-bottom. Same table.
3. Recursively list every `.do`, `.dta`, `.stpr`, and tracked `.txt` under the three Stata folders.
4. For each file, `grep` the three folders for its basename to determine who (if anyone) references it. Record in a per-file table.
5. Classify each file with a **status**:
   - `live` — reached from a driver, writes to `fortran_code/Data/` or to a paper output location.
   - `orphan` — no caller, no paper output.
   - `stale-duplicate` — parallel variant of a live file, no caller.
   - `temp-intermediate` — written and then erased within a driver run.
   - `exploratory` — has a caller (e.g. `.stpr` workspace) but produces only diagnostics.
   - `binary-workspace` — `.stpr` or other opaque binary.
   - `unknown` — status cannot be determined statically; flagged for Phase 3 or follow-up.
6. Attach a confidence level (high/medium/low) and a one-line reason to each classification.

**Files to produce (staged but not yet committed — committed in Phase 5)**
- `docs/stata_pipeline_audit.md` (draft — Phase 4 finalizes it)

**Success criteria**
- Every file under the three Stata folders appears in the audit's per-file table.
- Every "orphan" / "stale-duplicate" classification cites at least one grep or line reference as evidence.

---

### Phase 3 — Scratch-copy dry-run

**Tasks**
1. Create scratch directory at `%TEMP%/emeryt_stata_dryrun_20260413/` (Windows temp, outside the repo).
2. Copy `inputs_stata_code/`, `outputs_stata_code/`, `sensitivity_stata_code/` into the scratch dir.
3. Create a scratch `fortran_code/` sibling containing read-only copies (or junctions) of `fortran_code/Data/`, `fortran_code/Results/`, so the relative paths in `__main.do` (`..\fortran_code\Results\`) resolve.
4. Create a scratch `data/` sibling mirroring only the files that `__main.do` reads.
5. Before running anything, grep the scratch drivers for absolute paths (`C:\`, `D:\`, `N:\`). Any hit aborts the dry-run and records the offending line in the audit.
6. Run in batch mode from the scratch `inputs_stata_code/`:

   ```
   stata-mp -e do __main_data_prepare.do
   ```

   Capture stdout, stderr, and the Stata `.log` file.

7. Run from the scratch `outputs_stata_code/`:

   ```
   stata-mp -e do __main.do
   ```

   Capture the same.
8. Diff the scratch `fortran_code/Data/*.txt` outputs against the real tracked `fortran_code/Data/*.txt` files. For each file, record: match / differ (+line count) / missing / extra.
9. Write results to a "Dry-run" section in the audit draft.

**Degradation plan** — if any precondition fails:
- Stata not callable → Phase 3 degrades to "not executed, reason recorded" and Phase 4 proceeds with static findings only.
- Driver has absolute paths → Phase 3 records the paths and stops, Phase 4 adds a P0 TODO to fix them.
- `fortran_code/Results/psid_all_govt__/` missing → `__main.do` dry-run is skipped, `__main_data_prepare.do` still runs.

**Success criteria**
- Audit contains concrete dry-run evidence (log excerpts, diff summaries) OR a precise, actionable reason Phase 3 could not run.

---

### Phase 4 — Write `docs/stata_pipeline_audit.md`

**Tasks**
1. Compose the audit document with sections:
   - **Intro** — scope, date, constraints (strict read-only).
   - **Static call graph** — one call tree per driver, with line references.
   - **Per-file status table** — path, kind, reached-from, status, confidence, one-line note.
   - **Dry-run results** — Phase 3 output.
   - **Known asymmetries (documented, not bugs)** — demography dispatched from outputs driver, income-process separate pipeline (link to existing learning).
   - **Open issues — ranked TODO list**, with priority (P0 blocker / P1 ship-blocker / P2 nice-to-have / P3 exploratory), effort estimate, and a recommended action per item.
2. Aim for under 500 lines. If the per-file table balloons, move it to a collapsed `<details>` block.
3. Include a pointer back to this plan and to the brainstorm.

**Success criteria**
- A reader who has never touched the Stata layer can, after reading the audit alone, answer: which driver do I run, what does each subfolder produce, what's broken, and what's the top-priority fix.

---

### Phase 5 — Commit the audit

**Tasks**
1. Stage `docs/stata_pipeline_audit.md`, `docs/brainstorms/2026-04-13-stata-pipeline-audit-brainstorm.md`, `docs/plans/2026-04-13-refactor-stata-pipeline-audit-plan.md`.
2. Commit with message:

   ```
   Stata pipeline audit: static + dry-run findings

   Adds docs/stata_pipeline_audit.md covering call graphs,
   per-file status, scratch dry-run results, and a ranked TODO
   list for follow-up. Read-only with respect to existing .do
   and .dta files. Source brainstorm and plan included.
   ```

3. Final `git status` check — working tree clean.

**Success criteria**
- Two commits total from this session (Phase 1 snapshot, Phase 5 audit). No other commits, no modifications to existing Stata files.

## References & Research

### Internal references
- Brainstorm: [docs/brainstorms/2026-04-13-stata-pipeline-audit-brainstorm.md](docs/brainstorms/2026-04-13-stata-pipeline-audit-brainstorm.md)
- Input driver: [inputs_stata_code/__main_data_prepare.do:16-29](inputs_stata_code/__main_data_prepare.do#L16-L29)
- Output driver: [outputs_stata_code/__main.do:1-60](outputs_stata_code/__main.do#L1-L60)
- Orphan candidate: [inputs_stata_code/r_sd/R01compare_r_sd.do](inputs_stata_code/r_sd/R01compare_r_sd.do)
- Stale duplicate candidate: [outputs_stata_code/__main_PIOTR.do](outputs_stata_code/__main_PIOTR.do)
- Relevant learning: [docs/solutions/integration-issues/income-process-pipeline-consolidation.md](docs/solutions/integration-issues/income-process-pipeline-consolidation.md) — income-process intentional isolation
- Monorepo brainstorm context: [docs/brainstorms/2026-03-05-replication-package-monorepo-brainstorm.md](docs/brainstorms/2026-03-05-replication-package-monorepo-brainstorm.md)

### Constraints recap
- Strict read-only on existing `.do`, `.dta`, `.stpr` files.
- No `.gitignore` edits in this session.
- Two commits allowed (Phase 1 snapshot, Phase 5 audit) — nothing else.
- All integration fixes become TODOs in the audit doc, not code changes.
