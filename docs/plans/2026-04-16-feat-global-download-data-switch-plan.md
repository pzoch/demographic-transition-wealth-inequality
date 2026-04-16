---
title: "feat: Add global $download_data switch for external data sources"
type: feat
date: 2026-04-16
brainstorm: docs/brainstorms/2026-04-16-dbnomics-download-switch-brainstorm.md
---

# feat: Add global `$download_data` switch for external data sources

## Overview

Replace the current comment/uncomment pattern for dbnomics downloads with a runtime global switch `$download_data`. When 0 (default), scripts load from committed `.dta` snapshots. When 1, scripts re-download from dbnomics/OECD and overwrite the local `.dta`.

## Motivation

Upstream data revisions (PWT, OECD) silently change pipeline outputs. The current approach — commenting out download blocks — works but is fragile and undocumented. A formal switch makes the freeze/refresh decision explicit and lets a replicator refresh data with a one-line change.

## Proposed Solution

### 1. Add the global to `__main_data_prepare.do`

At the top, alongside existing globals:

```stata
global year_start 1935
global year_stop 2100
global download_data 0    // 0 = load local .dta (default), 1 = re-download from dbnomics
```

### 2. Transform each input script's download block

Current pattern (all 5 input scripts + M04):

```stata
/*capture dbnomics import , provider(GGDC) dataset(penn10/delta.USA) clear
    ren period year
    ...
save depreciation/depreciation.dta, replace */

use depreciation/depreciation.dta, clear
```

New pattern:

```stata
if $download_data == 1 {
    capture dbnomics import , provider(GGDC) dataset(penn10/delta.USA) clear
    ren period year
    ...
    save depreciation/depreciation.dta, replace
}

use depreciation/depreciation.dta, clear
```

The `use` line stays unconditional — it runs in both modes. When `$download_data == 1`, the download refreshes the `.dta` first, then the `use` loads the fresh copy.

### 3. Handle `outputs_stata_code/MvD_1_macro.do`

MvD_1_macro.do has 4 active dbnomics calls that produce temporary data for model-vs-data figures. Apply the same pattern:

1. Run MvD_1_macro.do once with `$download_data = 1` to produce `.dta` snapshots
2. Save each download to a local `.dta` under `outputs_stata_code/data/`:
   - `data/irr_data.dta` (GGDC penn10/irr.USA)
   - `data/benefits_cbo.dta` (CBO 51134-MO/SS.PGDP)
   - `data/oecd_wap.dta` (OECD working-age population)
   - `data/ggdc_hours_emp.dta` (GGDC avh+emp)
3. Add `global download_data 0` to `outputs_stata_code/__main.do` (same default)

### 4. Update README.md

Add a subsection under Stage A explaining:
- The `$download_data` switch and its default
- How to refresh data (`global download_data 1` before running)
- That `.dta` snapshots are committed and pinned to specific data vintages

## Acceptance Criteria

- [ ] `global download_data 0` is set in `__main_data_prepare.do`
- [ ] `global download_data 0` is set in `__main.do` (for MvD_1_macro.do)
- [ ] All 6 input scripts use `if $download_data == 1 { ... }` instead of comment blocks
- [ ] `MvD_1_macro.do` saves 4 `.dta` snapshots and loads from them by default
- [ ] Pipeline produces identical outputs with `$download_data = 0` (no network calls)
- [ ] README documents the switch
- [ ] Batch-mode recipe in audit §11.8 updated to include `global download_data 0`

## Files to Modify

| File | Change |
|---|---|
| `inputs_stata_code/__main_data_prepare.do` | Add `global download_data 0` |
| `inputs_stata_code/depreciation/M01prepare_depr.do` | Uncomment + wrap in `if $download_data` |
| `inputs_stata_code/tfp/M02prepare_gamma.do` | Uncomment + wrap in `if $download_data` |
| `inputs_stata_code/labor_share/M03prepare_labor_share.do` | Uncomment + wrap in `if $download_data` |
| `inputs_stata_code/social_security/T02prepare_contributions.do` | Uncomment + wrap in `if $download_data` |
| `sensitivity_stata_code/exog_rate/M04prepare_exog_rate.do` | Uncomment + wrap in `if $download_data` |
| `outputs_stata_code/__main.do` | Add `global download_data 0` |
| `outputs_stata_code/MvD_1_macro.do` | Save to .dta + wrap in `if $download_data` |
| `README.md` | Document the switch |
| `docs/stata_pipeline_audit.md` §11.8 | Add `global download_data 0` to batch recipe |

## Notes

- `M02robustness_prepare_gamma.do` shares `tfp/gamma.dta` with `M02prepare_gamma.do` — no separate download block needed.
- `R01compare_r_sd.do` is orphan/exploratory — skip for now.
- T01 and T03 load from local CSV/xlsx, not dbnomics — no change needed.
- D01, D02, D03 load from local Excel/dta — no change needed.
