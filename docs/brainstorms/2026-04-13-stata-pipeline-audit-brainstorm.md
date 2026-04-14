---
name: Stata pipeline audit and integration
date: 2026-04-13
status: ready-for-plan
---

# Stata Pipeline Audit & Integration

## What We're Building

A read-only audit of the Stata inputs and outputs pipelines, plus a clean commit of the pending modifications already in the working tree. Deliverables:

1. A clean git commit (or small commit series) of the 14 pending modifications under `inputs_stata_code/`, `outputs_stata_code/`, and `sensitivity_stata_code/` — as-is, no edits.
2. A new audit document `docs/stata_pipeline_audit.md` that maps every `.do` / `.stpr` / `.dta` file in the three Stata folders to:
   - what it reads,
   - what it writes,
   - whether it is reached from `inputs_stata_code/__main_data_prepare.do` or `outputs_stata_code/__main.do`,
   - its status (live / orphan / stale-duplicate / temp-intermediate / unknown).
3. A scratch-copy dry-run of `__main_data_prepare.do` and `__main.do`, with the diff of produced outputs against the tracked `fortran_code/Data/` files recorded in the audit doc.
4. A prioritized "open issues" TODO list inside the audit doc covering the integration gaps discovered (for a future session to act on).

**Out of scope**: any edits to existing `.do`, `.dta`, or `.stpr` files; any `.gitignore` edits; any removal of orphans or duplicates.

## Why This Approach

- Honors the strict "no modification to existing files" constraint.
- Separates *understanding* (audit) from *changing* (future session), which is the safer order given several files of uncertain status (`r_sd/`, `__main_PIOTR.do`, `asi_aux.dta`).
- Produces a single durable reference document that future work — and future replicators — can rely on without re-scanning the tree.
- The dry-run validates that the current, unmodified pipelines actually work end-to-end, which is the real signal of "integrated with the rest of the workflow".

## Known Findings (from lightweight scan)

- **Orphans / unknown status** (to investigate, not touch):
  - `inputs_stata_code/r_sd/R01compare_r_sd.do` — not called from `__main_data_prepare.do`; purpose unclear.
  - `outputs_stata_code/__main_PIOTR.do` — appears to be a stale variant of `__main.do`.
  - `outputs_stata_code/asi_aux.dta` — unreferenced in any `.do` file based on grep.
  - `outputs_stata_code/__replication_graphs.stpr` — Stata project file, undocumented in README.

- **Temp files tracked in git** (flag, don't fix):
  - `outputs_stata_code/bone.dta`, `bone1y.dta` — deleted at the end of `__main_data_prepare.do` and again in `__main.do`, so they're intermediates that should probably be gitignored.

- **Asymmetry** (document, don't restructure):
  - `inputs_stata_code/demography/` is dispatched from `outputs_stata_code/__main.do` (Appendix C), not from the `__main_data_prepare.do` driver. Unusual but functional.
  - `inputs_stata_code/income_process/` runs separately via `run_estimation.bat`, not from the main driver.

- **Uncommitted working tree** (to commit as-is):
  - 14 modified files across `inputs_stata_code/`, `outputs_stata_code/`, `sensitivity_stata_code/`.
  - Untracked regenerated artifacts in `fortran_code/data/` (lowercase) and `graphs/inputs/` — flag in audit, do not commit.

## Key Decisions

| Decision | Choice |
|---|---|
| Edit existing `.do`/`.dta`/`.stpr` files? | **No** — strict read-only. |
| Commit pending modifications? | **Yes**, as part of this work, in a clean commit. |
| Fix integration issues now? | **No** — document as TODOs in the audit. |
| Verification method? | **Dry-run in a scratch copy** of `inputs_stata_code/` + `outputs_stata_code/`, compare outputs to tracked `fortran_code/Data/` files by diff. |
| Treatment of `r_sd/`? | **Investigate and report only** — read the `.do`, trace inputs/outputs, record findings; no code change. |
| New files allowed? | **Only** the audit document under `docs/`. No new `.do`, no `.gitignore` changes, no `__main_*_extras.do` shim. |

## Open Questions (for the user, not blocking the plan)

1. `r_sd/R01compare_r_sd.do` — once the audit reports what it does, do you want it wired into the main driver in a follow-up session, or left as exploratory?
2. `__main_PIOTR.do` — archive to `docs/archive/`, delete, or leave in place?
3. `.stpr` project files — should they be tracked at all, or gitignored as IDE state?
4. `bone*.dta` / `asi_aux.dta` — confirm whether any of these should be gitignored in a follow-up.
5. Demography and income-process entry points — consolidate into `__main_data_prepare.do` in a follow-up, or document the current split as intentional?

## Success Criteria

- `git status` shows all 14 pending Stata modifications committed, nothing else changed.
- `docs/stata_pipeline_audit.md` exists and covers every file in the three Stata folders.
- The audit records a successful (or failing, with exact error) dry-run of both drivers from a scratch copy.
- The audit ends with a ranked TODO list of integration issues to act on in the next session.

## Next

Run `/workflows:plan` to turn this into an implementation plan.
