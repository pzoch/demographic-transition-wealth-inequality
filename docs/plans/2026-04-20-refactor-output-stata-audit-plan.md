---
title: Audit outputs_stata_code/ Stata pipeline
type: refactor
date: 2026-04-20
source_brainstorm: docs/brainstorms/2026-04-20-output-stata-audit-brainstorm.md
status: planned
target_doc: docs/stata_pipeline_audit.md  (new §14)
target_branch: ej-sandbox
---

# Audit `outputs_stata_code/` Stata pipeline

## Overview

Produce a §14 "Interactive `.stpr` + `__main.do` audit" section in `docs/stata_pipeline_audit.md` that matches the depth of §13 (inputs driver). Cover all 12 `.do` files in `outputs_stata_code/` (driver + programs + figures + Model-vs-Data), trace the Appendix B/C/D/E/F blocks of `__main.do`, hunt duplicate/dead writes, verify integration bugs, and close or update the relevant items in §6's P1/P2/P3 lists.

This complements §13: the inputs driver is now verified byte-exact end-to-end; the output driver is the remaining hole in §6's P1. Static analysis alone would not catch the runtime bugs that only appear when globals propagate between `.do` calls, so we pair static reading with a scoped dry-run of runnable pieces.

## Problem Statement / Motivation

The prior audit (`docs/stata_pipeline_audit.md`, §2.2) mapped `__main.do`'s call graph statically but never exercised it. This session's inputs-driver audit (§13) found three real bugs in the committed baseline that neither static tracing nor `stata -e` batch mode had surfaced (`$bsource ""` → empty root-absolute path; D02 writing to a path that does not exist; `erase` halting cleanup). The same class of latent bugs almost certainly exists in the 11 output-side scripts and in `__main.do`'s 194-line orchestration. Without §14 we ship a replication package whose figure-generation pipeline has never been verified.

**Concrete hazards expected** (from §13 learnings + `docs/solutions/`):
- Missing / stale globals (§9.5 item 1): `MvD_*`/`R_Figure*` may assume `$year_start` set earlier in `__main.do` and silently produce wrong-size series when run standalone.
- cwd drift across `cd ..\inputs_stata_code` / `cd ..\outputs_stata_code` blocks (§2.3): Appendix B/C/F each re-seat the cwd; one forgotten `cd` back breaks the next block.
- `program define` inside `foreach` (build-errors solution): `_prog_coding.do` / `_prog_ineq_function.do` declare programs — verify they are not nested.
- Case-sensitivity (§5.3): already fixed for inputs; verify Appendix B/C/F re-runs also write to `Data/` consistently.
- Dead writes / duplicate exports (M04 / D03 pattern): 11 scripts with 12 potential save/export sites each — hunt systematically.

## Proposed Solution

One single-pass reading of all 12 scripts plus dry-run of runnable blocks, producing `## 14` in the audit doc with 8 subsections mirroring §13. Keep discovery and synthesis interleaved — one pass, one section, cross-referenced throughout.

Dry-run uses a Windows folder junction from the main repo's `fortran_code/Results/`, so the sandbox sees all 15+ scenarios `__main.do` references without copying ~GBs. Junction is created at the start and torn down after the session (or kept — read-only access keeps it safe).

## Technical Considerations

- **Junction command**: `cmd //c mklink /J "n:\PROJECTS\EMERYT\EJ_sandbox\fortran_code\Results" "n:\PROJECTS\EMERYT\_Paper_16_EJ_replication\fortran_code\Results"` — `mklink /J` creates a directory junction (no admin), as opposed to `mklink /D` (symlink, needs admin or dev-mode). Junction lives under `fortran_code/`, which is gitignored at that level (`fortran_code/.gitignore:Results/`), so no accidental tracking.
- **Branch**: stay on `ej-sandbox`. Sandbox is already the audit worktree (§13.7).
- **Commits**: expect 1–3 commits:
  - `c1` (always): `docs/stata_pipeline_audit.md` §14 + updated §6 P1/P2/P3 ticks.
  - `c2` (conditional): source fixes to any real bugs §14 discovers (same commit style as `ddd3e2f`).
  - `c3` (conditional): cleanup of confirmed-orphan files (`__main_PIOTR.do`, `asi_aux.dta`) — already P3 in §6.
- **Dry-run capture**: run each testable script as `stata /e do <script.do>` inside `outputs_stata_code/` with a setup preamble that defines the globals `__main.do` sets. Log `r(601)`/`r(111)` errors into §14's results table. Scripts whose inputs require Fortran scenarios that don't exist in the Results/ junction will be flagged "not dry-run" — not "failing".
- **Static-read checklist** per script (captured in §14.2 table):
  - Path and line count
  - Reads (`use`, `import delimited`, `merge … using`)
  - Writes (`save`, `export delimited`, `graph save`, `graph export`)
  - Globals referenced that are expected to come from the caller
  - Where `__main.do` invokes the script (line numbers) and what globals `__main.do` sets immediately beforehand
  - Any `cd` statements
  - Gotchas flagged from §13 learnings and `docs/solutions/`
  - Dry-run: `pass` / `error: …` / `not run (missing Fortran scenario X)`
- **No `.stpr` interactive run**. Running `__main.do` end-to-end through `__replication_graphs.stpr` would take a full Stata session and require baby-sitting per-figure errors interactively. It remains §6 P1-2 for a future session. The dry-run of individual scripts catches integration bugs without the interactivity cost.

## Acceptance Criteria

### Functional

- [ ] Folder junction created and `fortran_code/Results/psid_all_govt__/mass_trans_small.csv` visible from sandbox.
- [ ] `## 14` section written in `docs/stata_pipeline_audit.md` with subsections:
  - `14.1` Scope and method (reuse brainstorm language; cross-link to §13 for the inputs pair)
  - `14.2` Per-script spec table (12 rows — see template below)
  - `14.3` `__main.do` driver structure: globals set, Appendix B/C/D/E/F block boundaries, cwd tracking, line-accurate invocation map
  - `14.4` Duplicate / dead-write findings (same format as §13.3)
  - `14.5` Integration-bug findings (new bugs + recurrence checks for §13-class bugs: bsource, cd drift, case, missing globals)
  - `14.6` Disposition of `__main_PIOTR.do` and `asi_aux.dta` — confirm or reject the P3 archival proposals
  - `14.7` Updates to §6 P1/P2/P3 (closed items struck through; new items appended)
  - `14.8` Session commits (SHAs of `c1`, optionally `c2`, `c3`)

### Per-script spec-table template (§14.2)

```markdown
| Script (line count) | Reads | Writes | Called by __main.do (line) | Globals needed (from caller) | cwd assumption | Dry-run | Notes |
|---|---|---|---|---|---|---|---|
| __main.do (194) | ... | ... | — (driver) | — | starts outputs_stata_code/ | n/a | §14.3 line map |
| _prog_coding.do (154) | ... | ... | line 8 | — (defines programs) | outputs_stata_code/ | pass | `program define` outside loops? |
| _prog_ineq_function.do (197) | ... | ... | line 9 | — | outputs_stata_code/ | pass | ditto |
| _prep_Gini_data.do (65) | $datapath/... | scratch dta | line 10 | $datapath, $year_start, $year_stop | outputs_stata_code/ | pass | — |
| R_Figure1.do (21) | $resultspath/$scenario/mass_trans_small.csv | $graphspath/...png | line 31 | $scenario, $resultspath, $graphspath | outputs_stata_code/ | pass/fail | — |
| R_Figure1_app.do (22) | ... | ... | line 177 (Appendix F) | $scenario | outputs_stata_code/ | ... | — |
| R_Figure2.do (36) | ... | ... | 6×: lines 37, 135, 143, 151, 160, 185 | $variant_base, $variant_comp, $r1, $r2 | outputs_stata_code/ | ... | — |
| R_Figure3.do (74) | ... | ... | 5×: lines 45, 52, 110, 118, 126 | $variant_base, $variant_comp, $legend, $colors | outputs_stata_code/ | ... | — |
| MvD_1_macro.do (219) | $resultspath/$scenario/... + $datapath/... | ... | line 97 | $scenario, $year_start/stop/end, $min_age/$max_age | outputs_stata_code/ | ... | — |
| MvD_2_Gini_income.do (39) | ... | ... | line 98 | ditto | outputs_stata_code/ | ... | bin-mapping check (sigma2eps learnings) |
| MvD_3_Gini_wealth.do (72) | ... | ... | line 99 | ditto | outputs_stata_code/ | ... | ditto |
| MvD_4_GE_decomposition.do (151) | ... | ... | line 100 | ditto | outputs_stata_code/ | ... | — |
```

### Non-Functional

- [ ] §14 uses the §13 voice: bold severity tags, bracket-linked file paths with `#L<lineno>` anchors, back-references, dated H3 headers where appropriate.
- [ ] All save/export sites across the 12 scripts accounted for (dup / dead / live); no silent omissions.
- [ ] Each new finding either fixed in `c2`/`c3` or opened as a ranked P1/P2/P3 item in §14.7.
- [ ] No cached `__main.do` execution-order ambiguity: §14.3 line-map shows what `__main.do` does before each script call, so future readers can reason about globals without running Stata.

### Quality Gates

- [ ] `git diff --stat` on the audit commit ≤ 4 files (`docs/stata_pipeline_audit.md`, maybe `docs/brainstorms/…`, `docs/plans/this file`).
- [ ] Any source-fix commits (`c2`, `c3`) cite §14 subsection by number in the message.
- [ ] Dry-run commands and their exact stdout lines captured in a `<details>` block inside §14.2 (same style as §13.4's "Completed 1000 / 1000 bootstrap reps").

## Success Metrics

- A reader of §14 can predict what will happen when `__main.do` runs through `__replication_graphs.stpr`, without opening Stata, to within the precision of "these three figures will work, this one will fail with r(X) because …".
- Every P1 and P2 item in §6 is either marked resolved with a commit SHA, or downgraded with a justification.
- Zero unexplained `save`/`export` statements across `outputs_stata_code/`.

## Dependencies & Risks

| Risk | Mitigation |
|---|---|
| Junction command needs cmd.exe — not available in bash | Use `cmd //c "mklink /J ..."`; verified similar commands worked earlier this session. |
| `fortran_code/Results/` is gitignored; sandbox has no Results/ dir today; creating junction adds an untracked directory | Junction target path is inside `fortran_code/` which has `Results/` gitignored at the fortran-level `.gitignore`. Git will ignore the junction. |
| Dry-run of `R_Figure*` fails for reasons orthogonal to the script (wrong scenario name, missing Stata package `burd` scheme) | Distinguish "script bug" from "environment issue" in §14.2 notes. A cosmetic scheme failure is not the audit's subject. |
| `MvD_1_macro.do` is 219 lines and may call further nested scripts we haven't enumerated | Read it before the table; expand scope if it invokes uncounted scripts. Flag in §14.5. |
| `__main_PIOTR.do` or `asi_aux.dta` have hidden consumers we missed in prior grep | Before `c3` (deletion commit), run a second `git grep` across `.do`, `.f90`, `.bat`, `.md`, `.sln`, `.vfproj`. If zero hits, delete. |
| Running scripts standalone without `__main.do`'s global setup gives false positives | Dry-run harness: write a small Stata preamble `.do` that sets the globals `__main.do` defines before each block; source it before each script. Alternatively, run each script via `do __main.do` with early `exit` before the unrelated block — but that's expensive. Prefer the harness. |

## References & Research

### Internal references

- Audit doc (target): [docs/stata_pipeline_audit.md](../stata_pipeline_audit.md) — new §14 appended at line 778.
- Pattern to mirror: §13 subsections [13.1-13.8 at lines 699-778](../stata_pipeline_audit.md#L699-L778).
- Call-graph baseline: §2.2 [lines 59-98](../stata_pipeline_audit.md#L59-L98).
- Open-issues list to update: §6 [lines 241-269](../stata_pipeline_audit.md#L241-L269).
- Brainstorm: [docs/brainstorms/2026-04-20-output-stata-audit-brainstorm.md](../brainstorms/2026-04-20-output-stata-audit-brainstorm.md).

### Solution files to cross-check against each script

- [docs/solutions/build-errors/stata-program-define-inside-foreach.md](../solutions/build-errors/stata-program-define-inside-foreach.md) — check `_prog_coding.do`, `_prog_ineq_function.do`, and any MvD script that loops over programs.
- [docs/solutions/integration-issues/income-process-pipeline-consolidation.md](../solutions/integration-issues/income-process-pipeline-consolidation.md) — pre-seeded file lifecycle (bone.dta, bone1y.dta); applies to `__main.do` Appendix B/C/F.
- [docs/solutions/logic-errors/sigma2eps-fortran-bin-mapping.md](../solutions/logic-errors/sigma2eps-fortran-bin-mapping.md) — bin-to-period mapping bug pattern; applies to any MvD script re-binning Fortran results.

### Session commits this plan builds on

- `6d0bbea` — `.stpr` sidebar + path hygiene (added R_Figure1_app + M02robustness to Appendix F section of `__replication_graphs.stpr`).
- `ddd3e2f` — Sandbox-verified inputs pipeline fixes (bsource, D02 path, capture erase, env-var portability, bootstrap `.mat` exception).
- `598bc9b` — README Stage B + plot_estimates NaN + D02 duplicate save.
- `af261e2` — Case normalisation `data/` → `Data/`.
- `98de87f` — Bootstrap live/archive split (H.mat/L.mat untracked, H_archive.mat/L_archive.mat tracked).
- `fb91db8` — M04 `_data_irr.txt` dedupe.

## Implementation plan (operational order)

1. **Setup** (5 min): Create the folder junction via `cmd //c mklink /J …`. Verify `ls EJ_sandbox/fortran_code/Results/psid_all_govt__/mass_trans_small.csv` succeeds. Do NOT commit anything about the junction.

2. **Read `__main.do`** (~30 min): take line-by-line notes of globals set, `cd` statements, block boundaries (main text / Appendix B / C / D / E / F / sensitivity). Produce §14.3 skeleton.

3. **Read programs `_prog_coding.do`, `_prog_ineq_function.do`** (~20 min): enumerate every `program define … end` and check they are not nested in `foreach`. Note imports.

4. **Read `_prep_Gini_data.do`** (~10 min): what Gini-data .dta does it produce; what does it read.

5. **Read R_Figure{1,1_app,2,3}.do** (~30 min combined — 21+22+36+74 lines). For each, record inputs (csv from Results + dta from data/), outputs (png/eps to graphs/outputs/), globals expected.

6. **Read MvD_{1,2,3,4}.do** (~60 min — 219+39+72+151 lines). Focus on MvD_1 since it's longest. Check bin-mapping patterns (sigma2eps learnings) in MvD_2 / MvD_3.

7. **Static dup/dead-write hunt** (~10 min): run the same Python script used for inputs, expanded to include `outputs_stata_code/` and to look for `graph export`/`graph save` duplication.

8. **Build the §14.2 table** (~20 min): fill in the per-script rows from steps 2–7.

9. **Dry-run testable scripts** (~60 min, interleaved with writing):
   - Build a harness preamble `.do` that sets globals `__main.do` defines (`$resultspath`, `$graphspath`, `$datapath`, `$scenario`, `$year_start`, `$year_stop`, `$variant_base`, `$variant_comp`, etc.).
   - For each R_Figure* and MvD_*, run `stata /e do harness.do <script>.do` and capture the last 20 lines of the log. Record result in §14.2.
   - Programs (`_prog_*`) don't need dry-run — they're just `program define` blocks.

10. **Write §14.4 (dup/dead)**, §14.5 (integration bugs) from findings.

11. **Write §14.6** — grep once more for `__main_PIOTR` and `asi_aux` callers; decide whether they can be deleted.

12. **Write §14.7** — walk the §6 P1/P2/P3 list, strike completed items, append new ones.

13. **Commit `c1`**: the audit doc. Message format mirroring `ddd3e2f`: subject "Audit §14: outputs_stata_code pipeline end-to-end review"; body lists findings, links to commit SHAs for any fixes landed in `c2`/`c3`.

14. **Conditional `c2`**: if §14 surfaces any real bugs (bsource-class, path-class, cwd-class, duplicate-class) apply fixes + update related audit paragraph. One commit.

15. **Conditional `c3`**: if §14.6 confirms `__main_PIOTR.do` and `asi_aux.dta` have zero consumers, delete + amend §6 P3 entries. One commit.

16. **Teardown**: leave junction in place (read-only; harmless). Note its existence in §14.1 so future sessions don't recreate.

## Alternative approaches considered

**A. Full interactive `.stpr` run of `__main.do`** — richest verification but requires per-figure error diagnosis in a live Stata session and a full set of Fortran Results with every scenario (~20 scenarios × 1–5 GB each). Deferred to §6 P1-2 for a later session.

**B. Skip dry-run entirely, static-only audit** — cheaper but misses integration bugs that only surface at runtime (as the inputs audit proved: `$bsource ""` would not have been caught by static reading alone — the path string looks fine). Rejected.

**C. Three separate audit passes (spec table → dup hunt → P1/P2/P3 updates)** — cleaner separation of concerns but 3× the reading cost for low additional value. Rejected in favour of single-pass synthesis, consistent with §13's approach.

## Out of scope

- End-to-end `.stpr` run of `__main.do` (remains §6 P1-2 for a future session with Fortran simulation bandwidth).
- Regenerating graphs themselves (`graphs/inputs/`, `graphs/outputs/`). The audit's job is to verify the pipeline is reproducible; actually producing the paper's figures is Step 7 of README.md and is covered by the full `.stpr` run.
- Refactoring `__main.do`'s structure (e.g., extracting the Appendix F block into a subdriver). Any such work would be a separate plan.
- Changes to `R01compare_r_sd.do` (orphan in inputs tree, §6 P3) — not in scope of the outputs audit.
