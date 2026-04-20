---
date: 2026-04-20
topic: output-stata-audit
---

# Output Stata Pipeline Audit

## What We're Building

A deep-dive audit of `outputs_stata_code/` — the paper-figure and Appendix-table pipeline driven by `__main.do` via `__replication_graphs.stpr`. Same level of depth as the inputs-driver audit in `docs/stata_pipeline_audit.md` §13, but focused on the 12 scripts in `outputs_stata_code/` (plus the Appendix B/C re-runs and Appendix F sensitivity scripts) that the prior audit covered only statically (§2.2).

## Why This Approach

The inputs driver is now verified byte-exact end-to-end; the output driver is the remaining hole in §6's P1. The prior audit identified the call graph but never exercised the scripts, so we don't know which of them have the same kind of bugs we found and fixed in the inputs driver (wrong paths, duplicate exports, missing globals, case-asymmetry, stale inputs). This session closes that gap without attempting a full end-to-end Fortran-to-figures run — which would require simulating the model, out-of-scope here.

## Key Decisions

- **Scope: static + dry-run of runnable pieces.** Read every output `.do`; run where inputs are available; skip figure scripts whose inputs require Fortran simulation beyond what the main repo has already produced.
- **Dry-run uses existing Fortran Results via folder junction.** `mklink /J EJ_sandbox\fortran_code\Results _Paper_16_EJ_replication\fortran_code\Results` — zero copy, all 15+ scenarios visible in sandbox, isolation preserved because we only read from Results/.
- **Three deliverables, one pass, one audit section (§14).** Per-script spec table (what each script reads/writes/needs), duplicate/dead-write hunt (M04/D03 pattern across the 12 scripts), and integration-bug updates to §6's P1/P2/P3 rankings. Single reading pass — findings cross-referenced inline.
- **Document in existing audit file.** Add a `## 14. Output pipeline audit` section mirroring the §13 structure. Same audience, same conventions, cross-links back to earlier sections.
- **No runtime execution of __main.do through `.stpr`.** Dry-run individual scripts only; avoid the long interactive session. Full `.stpr` execution remains §6 P1-2 for a future session with a Fortran simulation pass.

## Scripts in scope

Under `outputs_stata_code/`:
- Driver: `__main.do`
- Programs: `_prog_coding.do`, `_prog_ineq_function.do`, `_prep_Gini_data.do`
- Main-text figures: `R_Figure1.do`, `R_Figure2.do`, `R_Figure3.do`
- Appendix extras: `R_Figure1_app.do`
- Appendix D: `MvD_1_macro.do`, `MvD_2_Gini_income.do`, `MvD_3_Gini_wealth.do`, `MvD_4_GE_decomposition.do`
- Stale (flagged P3): `__main_PIOTR.do`

Plus a coverage-only check on Appendix B/C re-runs (already audited for the inputs driver, but `__main.do` invokes them with different globals) and the Appendix F calls into `sensitivity_stata_code/` / `inputs_stata_code/tfp/` (M02robustness, M04).

## Open Questions

- Whether to pre-delete or keep `__main_PIOTR.do` and `asi_aux.dta` (§6 P3) — recommend removing during the same commit once the audit confirms they are truly orphaned.
- `bone*.dta` policy (§6 P2): does `__main.do` Appendix B actually read them from `outputs_stata_code/` (the "pre-seeded input" argument), or will the audit show a cleaner restructuring? Defer the decision until the audit reads the Appendix B block against `$bsource="../outputs_stata_code/"`.

## Next Steps

→ `/workflows:plan` for implementation details (file-by-file reading order, junction command, how to capture dry-run output, exact §14 subsection layout).
