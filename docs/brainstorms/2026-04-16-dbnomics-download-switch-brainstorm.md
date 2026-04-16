---
title: Global download switch for external data sources
date: 2026-04-16
status: decided
---

# Global Download Switch for External Data Sources

## What We're Building

A global Stata switch (`$download_data`) in `__main_data_prepare.do` that controls whether scripts download fresh data from dbnomics/OECD/Fed or load from committed local `.dta` snapshots. Default = 0 (load local). Set to 1 to re-download and refresh snapshots.

## Why This Approach

- **Reproducibility**: upstream data revisions (PWT, OECD) silently change pipeline outputs. Pinning to local copies ensures deterministic results.
- **Already the pattern**: 6 of 7 download scripts already have dbnomics blocks commented out and load from `.dta`. This formalizes the pattern with a runtime switch instead of comment/uncomment.
- **Minimal churn**: keep `.dta` as the local format (no CSV conversion), keep the download code intact (just gated behind `if $download_data`).

## Key Decisions

1. **Switch location**: `__main_data_prepare.do`, near the top alongside `$year_start`/`$year_stop`. Set `global download_data 0` by default.
2. **Local format**: `.dta` (existing committed files). No CSV conversion.
3. **Scope**: all scripts that download external data, including `outputs_stata_code/MvD_1_macro.do`.
4. **Pattern**: each script wraps its download block in `if $download_data { ... save ..., replace }` then unconditionally does `use ..., clear` afterward.

## Scripts to Modify

### Input scripts (already have commented-out downloads)
| Script | Source | Local .dta |
|---|---|---|
| `inputs_stata_code/depreciation/M01prepare_depr.do` | GGDC penn10/delta.USA | `depreciation/depreciation.dta` |
| `inputs_stata_code/tfp/M02prepare_gamma.do` | GGDC penn10/rtfpna.USA | `tfp/gamma.dta` |
| `inputs_stata_code/tfp/M02robustness_prepare_gamma.do` | GGDC penn10/rtfpna.USA | `tfp/gamma.dta` (shared) |
| `inputs_stata_code/labor_share/M03prepare_labor_share.do` | GGDC penn10/labsh.USA | `labor_share/labor_share.dta` |
| `sensitivity_stata_code/exog_rate/M04prepare_exog_rate.do` | GGDC penn10/irr.USA | `sensitivity_stata_code/exog_rate/irr.dta` |
| `inputs_stata_code/social_security/T02prepare_contributions.do` | OECD REV via dbnomics | `social_security/contributions.dta` |

### Output scripts (currently active downloads)
| Script | Source | Local .dta (to create) |
|---|---|---|
| `outputs_stata_code/MvD_1_macro.do` | GGDC irr, CBO 51134, OECD POP, GGDC avh+emp | TBD — need to snapshot each download |

### Exploratory (orphan, low priority)
| Script | Source | Local .dta |
|---|---|---|
| `inputs_stata_code/r_sd/R01compare_r_sd.do` | Fed Reserve CSV | `r_sd/r_sd.dta` |

## Open Questions

- MvD_1_macro.do downloads 4 separate dbnomics series — should each save to its own `.dta`, or combine into one snapshot?
- Should the switch also be respected by `__main.do` (outputs driver) for MvD_1_macro.do? Probably yes — add `global download_data 0` to `__main.do` as well, or have it inherit from the environment.
