---
title: Ship MvD_1 frozen data snapshots
type: feat
date: 2026-04-22
source_brainstorm: docs/brainstorms/2026-04-21-mvd1-data-sourcing-brainstorm.md
status: planned
target_branch: ej-sandbox
---

# Ship MvD_1 frozen data snapshots

Make `outputs_stata_code/MvD_1_macro.do` work under the default `$download_data=0` by committing the three processed `.dta` files it reads. Matches the inputs-pipeline pattern where each module keeps its own frozen download next to the script. Closes `docs/stata_pipeline_audit.md` §14.5-P3.

## Acceptance Criteria

- [ ] `outputs_stata_code/data/irr_data.dta`, `outputs_stata_code/data/benefits_cbo.dta`, `outputs_stata_code/data/avghours_data.dta` committed (tracked).
- [ ] `outputs_stata_code/MvD_1_macro.do` gains a single `capture mkdir data` line at the top (safety net on fresh clones; Stata's `save` does not create parent dirs, and `capture mkdir` is cheap + idempotent).
- [ ] Fresh-clone `outputs_stata_code/__replication_graphs.stpr` → run MvD_1_macro.do with default `$download_data=0` succeeds (no `r(601)` on `use data/*.dta`).
- [ ] Running MvD_1 with `$download_data=1` still refreshes the `.dta` snapshots (no regression).
- [ ] `docs/stata_pipeline_audit.md` §14.5-P3 and §14.7 marked resolved with the commit SHA.

## Implementation Plan

### Step 1 — Add mkdir safety net

Edit [`outputs_stata_code/MvD_1_macro.do`](../outputs_stata_code/MvD_1_macro.do) — add at the top (before line 1 or right after the header comment):

```stata
capture mkdir data
```

### Step 2 — User runs the one-time bootstrap in Stata

You do this (I can't run interactive Stata):

1. Double-click `outputs_stata_code/__replication_graphs.stpr` to open the project in Stata.
2. In the Command window, paste the preamble that sets the globals `__main.do` normally sets before calling MvD_1:

   ```stata
   global download_data 1
   global resultspath "..\fortran_code\Results\"
   global graphspath  "..\graphs\outputs\"
   global scenario    "psid_all_govt__"
   global year_start 1950
   global year_stop  2020
   global year_end   2100
   global min_age 20
   global max_age 65
   global lam 1600
   do _prog_coding.do
   ```

3. Double-click `MvD_1_macro.do` in the sidebar → Execute (do-file editor).
4. Expected: dbnomics fetches irr and benefits; OECD fetches working-age population; Penn fetches avh+emp. Three `.dta` files saved to `outputs_stata_code/data/`. Three graphs saved to `graphs/outputs/irr_trans_levels.{png,eps,svg}`, `avghours_trans_levels.*`, `benefits_trans_levels.*`.
5. Takes ~30-60 seconds on network.
6. Tell me "done".

### Step 3 — Commit

I'll commit as `c5`:
- `outputs_stata_code/MvD_1_macro.do` (the one `capture mkdir` line)
- `outputs_stata_code/data/irr_data.dta`
- `outputs_stata_code/data/benefits_cbo.dta`
- `outputs_stata_code/data/avghours_data.dta`
- `docs/stata_pipeline_audit.md` (§14.5-P3 and §14.7 marked resolved)

No `.gitignore` change needed — `outputs_stata_code/data/*.dta` is not excluded anywhere, so the new files track by default.

## References

- Brainstorm: [docs/brainstorms/2026-04-21-mvd1-data-sourcing-brainstorm.md](../brainstorms/2026-04-21-mvd1-data-sourcing-brainstorm.md)
- Audit item: [docs/stata_pipeline_audit.md §14.5-P3](../stata_pipeline_audit.md)
- Inputs-pipeline precedent (same pattern): `inputs_stata_code/depreciation/depreciation.dta`, `tfp/gamma.dta`, `labor_share/labor_share.dta`, `social_security/contributions.dta`, `sensitivity_stata_code/exog_rate/irr.dta`.
