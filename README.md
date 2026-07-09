# Replication Package: Demographic Transition and the Rise of Wealth Inequality

**Date**: January 2026

This replication package accompanies:

Krzysztof Makarski, Joanna Tyrowicz, and Piotr Zoch. (forthcoming). "Demographic transition and the rise of wealth inequality". *Economic Journal*.

---

## Start Here: Replication Routes and Run Order

Most replicators do not need to run every stage. Choose one route first; the detailed steps later in this README use the same numbering and list inputs, outputs, commands, and details separately.

| Route | Goal | Raw restricted data needed? | Run order |
|---|---|---|---|
| **1. Figure-only check** | Recreate the paper figures from shipped model output. | No raw PSID or ACS/IPUMS. Requires shipped/obtained `data/SCF/SCF_plus.dta`, packaged `data/PSID/psid_ready.dta`, and populated `fortran_code/Results/`. | Step 1, then Step 7. Run the MATLAB plot-only command in Step 2B for Appendix Figure B.5 if needed. |
| **2. Rebuild processed calibration inputs** | Re-run Stata/MATLAB preprocessing from packaged snapshots, without restricted raw microdata. | No raw PSID or ACS/IPUMS. Packaged processed PSID and ACS-derived files are reused when raw extracts are absent. | Step 1, Step 2A, optional Step 2B (set `N_REPS.txt` to `0` first for the fast run), then Steps 3-7 only if you also want to re-solve the model. |
| **3. Full raw-data rebuild** | Recreate the processed PSID and ACS-derived inputs, re-solve the Fortran model, and regenerate figures. | Yes: `inputs_stata_code/income_process/PSID/psid.dta` and `inputs_stata_code/skill_premium/ACS_college/ACS_college.dta`. | Step 1, Step 2A, Step 2B, Step 3, Step 4, Step 6, Step 7. |

**Route 1: minimal reviewer checklist**

1. Confirm `fortran_code/Results/<scenario>/` folders are present, especially `psid_all_govt__` and `psid_ndm_govt__`.
2. Confirm `data/SCF/SCF_plus.dta` and `data/PSID/psid_ready.dta` are present.
3. Open `outputs_stata_code/__replication_graphs.stpr` in Stata.
4. Run `outputs_stata_code/__main.do`.
5. Check regenerated figures in `graphs/outputs/` and Appendix-B input figures in `graphs/inputs/`.

**Route 3: complete rebuild checklist**

1. Place raw PSID at `inputs_stata_code/income_process/PSID/psid.dta` if rebuilding the PSID income-process inputs.
2. Place raw ACS/IPUMS at `inputs_stata_code/skill_premium/ACS_college/ACS_college.dta` if rebuilding the college-share input.
3. Decide whether to keep `global download_data 0` in the Stata drivers or change it to `1` to refresh supported online data sources.
4. Decide the bootstrap setting in `inputs_stata_code/income_process/N_REPS.txt`: the shipped default `1000` reproduces the full paper bootstrap (about 12 hours across Stata and MATLAB); set it to `0` for a fast point-estimate run that reuses the archived paper confidence bands.
5. Run `inputs_stata_code/__main_data_prepare.do` from `inputs_stata_code/main.stpr`.
6. Run `inputs_stata_code/income_process/I01_run_psid_income_inputs.do` from the same Stata project if rebuilding PSID inputs, then run `inputs_matlab_code/income_process/run_income_process_matlab.bat`.
7. Use the shipped Fortran binaries or rebuild them in Visual Studio, then run the scenarios listed in `fortran_code/scenarios.txt` and the heterogeneous-rate scenarios with `run_scenarios_het.bat`.
8. Run `outputs_stata_code/__main.do` from `outputs_stata_code/__replication_graphs.stpr`.

**Manual settings to check before running**

| Setting | Default | Change only if |
|---|---|---|
| `global download_data` in `inputs_stata_code/__main_data_prepare.do` and `outputs_stata_code/__main.do` | `0` | You want Stata to refresh supported dbnomics/OECD/GGDC series instead of using packaged snapshots. |
| `inputs_stata_code/income_process/N_REPS.txt` | `1000` | You want a fast point-estimate run instead of the full 12-hour paper bootstrap: set it to `0` to reuse the archived 1000-repetition bootstrap files for the confidence bands. |
| `MATLAB_EXE` environment variable | `C:\Program Files\MATLAB\R2018b\bin\matlab.exe` | MATLAB is installed elsewhere or a different version is used. |
| Raw PSID path | absent by default | You are doing Route 3 and have obtained the PSID extract. |
| Raw ACS/IPUMS path | absent by default | You are doing Route 3 and have obtained the IPUMS USA extract. |

Missing raw PSID or ACS files are not automatically fatal for Routes 1-2. If raw PSID is absent, the Stata driver prints a message and keeps the packaged PSID-derived Fortran inputs and processed `psid_ready.dta`. If raw ACS/IPUMS is absent, the Stata driver keeps the packaged college-share inputs. A full raw-data rebuild requires supplying those raw files at the exact paths listed above.

---

## Replication Package Layout

```
demographic-transition-wealth-inequality/
|-- README.md                    This file; export to PDF for the journal deposit if required
|-- LICENSE.txt                  MIT license
|-- SCENARIOS.md                 Full scenario catalogue
|
|-- fortran_code/                Fortran OLG model (main solver)
|   |-- *.f90                    Source files
|   |-- 5Gtrans.sln              Visual Studio solution
|   |-- Data/                    Calibration inputs consumed by the model
|   |-- Instructions/            Per-scenario switch files
|   |-- Parameters/              Per-scenario parameter files
|   |-- Results/                 Per-scenario output (regenerated or supplied separately)
|   |-- scenarios.txt            Scenario list for batch runs
|   +-- run_scenarios*.bat       Batch drivers
|
|-- inputs_stata_code/           Stata code that produces calibration inputs
|   |                            and selected PSID-derived intermediates
|   |-- demography/
|   |-- depreciation/
|   |-- external/                External Fortran inputs (UN/CDC/SSA source data),
|   |                            copied to fortran_code/Data/ via copy_to_fortran.do
|   |-- income_process/          PSID cleaning, variants, omega, covariance txt
|   |   |-- PSID/                Optional raw PSID extract and extraction notes
|   |   |-- I01_0*_*.do          Split Stata stages
|   |   +-- I01_run_*.do         PSID income-process Stata launcher
|   |-- labor_share/
|   |-- skill_premium/
|   |-- social_security/
|   |-- tax_rate/
|   +-- tfp/
|
|-- inputs_matlab_code/          MATLAB estimators that consume Stata intermediates
|   +-- income_process/          Income-process parameter estimation
|
|-- outputs_stata_code/          Stata code that produces paper tables/figures
|                               from Fortran output and prepared data
|   |-- income_process/          Deaton age-profile plot (M05plot_omega.do)
|   +-- __main.do                Master driver (Step 7 entry point)
|
|-- outputs_matlab_code/         MATLAB plotting code
|   +-- income_process/          Sigma2epsilon plot
|
|-- graphs/                      Generated figures (inputs/ and outputs/)
|
+-- data/                        Provider data, processed panels, and model-ready panels
                                (SCF+, processed PSID, model panels, etc.; see below)
```

**Pipeline at a glance**: `data/` + `inputs_stata_code/income_process/PSID/` -> `inputs_stata_code/` + `inputs_matlab_code/` -> `fortran_code/Data/` -> `fortran_code/` (OLG model solver) -> `fortran_code/Results/` -> `outputs_stata_code/` + `outputs_matlab_code/` -> `graphs/`.

> **Path convention**: prose paths are relative to the repository root. Fortran run examples change into `fortran_code/` before invoking executables; Stata and MATLAB preprocessing should be launched from the project files or batch files named in the relevant step.

---

## Authors

- **Krzysztof Makarski** - SGH Warsaw School of Economics and FAME|GRAPE - kmakar@sgh.waw.pl
- **Joanna Tyrowicz** - University of Augsburg, FAME|GRAPE, University of Warsaw, and IZA - j.tyrowicz@grape.org.pl
- **Piotr Zoch** - University of Warsaw, FAME|GRAPE - p.zoch@grape.org.pl

**Corresponding Author**: Joanna Tyrowicz - j.tyrowicz@grape.org.pl

**Replication Package Maintainer**: Piotr Zoch - p.zoch@uw.edu.pl

---

## License

The code in this repository is licensed under the [MIT License](https://choosealicense.com/licenses/mit/).

See [LICENSE.txt](LICENSE.txt) for full license text.

Data licensing information is provided in the Data Availability section below.

---

# Data Availability and Provenance Statements

## Statement about Rights

The author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript.

The author(s) have documented permission to redistribute or publish the data contained within this replication package where redistribution is permitted. Data that should not be redistributed directly, including raw PSID and raw ACS/IPUMS extracts, is either omitted from the public package or should be shared only through provider-approved channels; the scripts and README document how replicators can obtain those inputs.

## Summary of Availability

This paper uses public data, authors' estimates derived from restricted-use or terms-governed public-use microdata, and precomputed model inputs. The code in this repository is distributable under the MIT license; each data file remains subject to the license or terms of the original data provider.

All unrestricted processed inputs needed to run the Fortran scenarios are included. The PSID-derived income-process inputs used by the Fortran model (`_data_omega_*.txt` and `_data_sigma2eps_*.txt`) are included in `fortran_code/Data/`; their Stata-side components are refreshed by `__main_data_prepare.do` or Step 2B when the replicator supplies the raw PSID extract.

The journal deposit should include the SCF+ file `data/SCF/SCF_plus.dta` (about 99 MB), which is used by the model-vs-data wealth-Gini and decomposition scripts. If it is missing, obtain SCF+ from the Kuhn-Schularick-Steins data archive listed below and place it at that path.

Raw PSID microdata (Panel Study of Income Dynamics, 1970-2019 waves) should not be redistributed directly from a PSID website download. For journal replication, the preferred route is to archive/share the exact PSID extract through the official PSID Repository for publication extracts, or have replicators obtain the extract from https://psidonline.isr.umich.edu/ under the PSID Conditions of Use. Raw PSID is not required to run the Fortran model with the shipped inputs. The package includes the processed PSID panel `data/PSID/psid_ready.dta` used by `outputs_stata_code/MvD_2_Gini_income.do` for Appendix Figure D.4; raw PSID is required only to regenerate that panel and the income-process pipeline from scratch.

The ACS/IPUMS extract is large (about 1.8 GB locally) and may be omitted from a public deposit if required by IPUMS terms. Despite its file name, `ACS_college.dta` **is raw data**: it is the IPUMS USA extract exactly as delivered by the IPUMS extract system - the authors only renamed the downloaded file; no observations or variables were modified. It contains the census/ACS samples for every year available at extraction time (decennial censuses 1940-2000, then ACS 2006, 2011, 2016, and 2021, reflecting the US move from a 10-year to a 5-year cadence). Note that IPUMS extracts are user-generated and re-downloading is not byte-reproducible; a fresh extract with the same samples and variables is equivalent in content but not bit-identical. The package includes the processed college-share inputs needed by the model; regenerating them from raw ACS requires `inputs_stata_code/skill_premium/ACS_college/ACS_college.dta`, obtained from IPUMS USA or redistributed only with the required IPUMS permission/journal-subset approval.

## What Is Included vs. What Must Be Rebuilt

The package is organized so replicators can either run the model from shipped processed inputs or rebuild the processed inputs from raw data where licensing permits. The table below is the shortest route through the data provenance:

| Data class | Included processed file(s) | Raw input needed only for full rebuild | Transformation script(s) | Notes on rights and exact rebuild |
|---|---|---|---|---|
| PSID income process | `fortran_code/Data/_data_omega_*.txt`, `fortran_code/Data/_data_sigma2eps_*.txt`, `data/PSID/psid_ready.dta`, `data/PSID/ageeffects_*.dta` | `inputs_stata_code/income_process/PSID/psid.dta` | `inputs_stata_code/income_process/I01_run_psid_income_inputs.do`, then `inputs_matlab_code/income_process/estimate_parameters.m` | Raw PSID is governed by PSID Conditions of Use. If not supplied through the PSID Repository, obtain it from the PSID Data Center and place it at the path shown. The exact extraction route is documented in `inputs_stata_code/income_process/PSID/psid_read.R` and `inputs_stata_code/income_process/PSID/README.md`. |
| ACS/IPUMS college share | `fortran_code/Data/_data_college_share.txt`, `inputs_stata_code/skill_premium/ACS_college/processed/col_share_acs*.dta` | `inputs_stata_code/skill_premium/ACS_college/ACS_college.dta` | `inputs_stata_code/skill_premium/D02_prepare_college.do` | The shipped raw extract is unmodified IPUMS USA output (only the file name was changed). A rebuild extract should use `YEAR`, `AGE`, `HIGRADE`, `EDUCD`, and `PERWT` for the years listed below. The IPUMS USA collection DOI is `10.18128/C010`; cite the version DOI matching your extract date (Version 16.0, `10.18128/D010.V16.0`, at the time of this revision). |
| SCF+ wealth data | `data/SCF/SCF_plus.dta` | same file, if omitted | `outputs_stata_code/_prep_Gini_data.do`, `outputs_stata_code/MvD_3_GE_decomposition.do` | SCF+ comes from Kuhn, Schularick, and Steins (2020). The file is used for model-vs-data wealth comparisons and is not produced by this package. |
| Macro, fiscal, tax, and aggregate calibration inputs | `fortran_code/Data/_data_depr.txt`, `_data_gamma.txt`, `_data_labsh.txt`, `_data_tau*.txt`, `_data_lambda.txt`, `_data_contrib_to_gdp.txt`, `_data_skill_premium.txt` | packaged `.dta`, `.csv`, or `.xlsx` snapshots; optional dbnomics refresh for selected series | `inputs_stata_code/__main_data_prepare.do` and component scripts | With `global download_data 0`, scripts use packaged snapshots. Setting `download_data 1` refreshes supported dbnomics/OECD/GGDC series and overwrites local snapshots. |
| Mortality, population, and pension replacement inputs | `fortran_code/Data/_data_pi_cond_US_since1935.txt`, `_data_het_pi_US_since1935_all.txt`, `_data_Nn_US_*.txt`, `_data_rho_1935.txt` | packaged HMD/UN/Case-Deaton/CDC/SSA source snapshots or hand-curated source files under `inputs_stata_code/` | `demography/mortality/D01_life_tables.do`, `demography/hetero_pi/D03_prepare_hetero_pi.do`, `external/copy_to_fortran.do` | The three files under `inputs_stata_code/external/` are hand-curated external inputs copied into `fortran_code/Data/`; the mortality scripts document the HMD, UN, and Case-Deaton transformations. |

No processed file used by the scripts is intended to be a manually edited black box. When a file is not regenerated by a script, it is listed above as either an external data product supplied by the original provider or a hand-curated authority input copied into place by `external/copy_to_fortran.do`.

## Non-Proprietary Data Copies

Every Stata dataset shipped in this package is accompanied by a `.csv` copy with identical values (exported as stored, without value labels; variable and value labels remain documented in the `.dta` files). This includes the large redistributed files `data/SCF/SCF_plus.csv` and the processed PSID panel `data/PSID/psid_ready.csv`. The only shipped `.dta` without a csv copy is `data/model_psid_all_govt__.dta`, a regenerable intermediate that `outputs_stata_code/__main.do` rebuilds from `fortran_code/Results/`.

## Raw Extract Specifications for Restricted Microdata

**PSID**: To rebuild the income-process files from scratch, place the raw public-use extract at `inputs_stata_code/income_process/PSID/psid.dta`. The authors' extraction uses the PSID Main Study family and individual files, the SRC sample, heads only, waves 1970-2019, and the `psidR` variable-list layout. The exact variable lists `famvars_big.txt` and `indvars.txt` are included in `inputs_stata_code/income_process/PSID/`, and `psid_read.R` finds them there automatically (current `psidR` versions no longer ship `famvars_big.txt`; environment-variable overrides are documented in the local README). The first Stata stage then constructs household labor income, business-income components, household hours, average hourly income, CPI-deflated measures, education categories, birth cohorts, and cleaned age-20-to-65 person panels. The most important derived output for the figure pipeline is `data/PSID/psid_ready.dta`; it is produced by `I01_02_make_variant_samples.do` from the `mostdrop_hhslabinc` variant after dropping households whose five-year business-income share exceeds 25 percent and whose labor income is above the year-specific first quartile.

**ACS/IPUMS**: The authors' `ACS_college.dta` is the raw IPUMS USA extract as downloaded, without any modification (the extract file was only renamed). To rebuild the college-share input from scratch, create `inputs_stata_code/skill_premium/ACS_college/ACS_college.dta` from IPUMS USA (https://usa.ipums.org/usa/) using the samples/years 1940, 1950, 1960, 1970, 1980, 1990, 2000, 2006, 2011, 2016, and 2021 - every year available at the authors' extraction time. Required variables are `YEAR`, `AGE`, `HIGRADE`, `EDUCD`, and `PERWT`. IPUMS extracts are user-generated, so a re-download is content-equivalent but not byte-identical to the authors' file. Cite the IPUMS USA version DOI matching the extract date (collection DOI `10.18128/C010`; Version 16.0 is `10.18128/D010.V16.0` at the time of this revision); see `inputs_stata_code/skill_premium/ACS_college/README.md`. `D02_prepare_college.do` keeps age-25 observations, defines BA-or-higher status using `HIGRADE` before 1990 and `EDUCD` from 1990 onward, computes weighted shares, interpolates/extrapolates the five-year model path, writes `fortran_code/Data/_data_college_share.txt`, and saves the processed cohort files used by the heterogeneous-mortality script.

## Replication-Team Code Issues Addressed in This Revision

The package was revised after the journal replication team attempted a full pipeline run. The following portability and reproducibility fixes are included in the current source tree:

| Issue observed in replication | Fix in this revision |
|---|---|
| Step 4 referenced a bare `5Gtrans.exe`, while the package may only ship binaries under `bin/` or `x64/Release/`; an older `bin/` executable also produced an insufficient-virtual-memory error on the replicator's machine. | The README now runs `bin\5Gtrans.exe` or `x64\Release\5Gtrans.exe` explicitly. The shipped `bin/` executables were rebuilt from the current x64 Release and Release_HetRate configurations. |
| Windows case-insensitive filename collision between `bigl_trans.txt` and `bigL_trans.txt` style outputs. | Removed the unused standalone lower-case labor-output streams from `fortran_code/Print_DB.f90`; downstream graph scripts use the CSV/full-output data or `bigY_trans.txt` instead. |
| Shared top-level Fortran outputs could be overwritten or confused across scenarios. | `data.f90` now writes `implied_pi.txt` inside the active scenario folder, and `set_globals.f90` changes explicitly to `Results/<scenario>/` before writing `information.txt`. |
| Stata scratch files `bone.dta` and `bone1y.dta` could be read-only in a copied journal package, causing `save, replace` to fail. | `_prog_coding.do`, `_prepare_programs.do`, `__main_data_prepare.do`, and cleanup blocks now clear stale Windows read-only attributes before overwrite/delete attempts. |
| Some documented SVG graph outputs were stale because scripts exported EPS twice or omitted SVG. | The relevant Stata graph scripts now export SVG explicitly alongside PNG/EPS/PDF/GPH outputs. |
| `N_REPS=1000` was unclear for interactive Stata and could make MATLAB fail when Stata bootstrap files were absent. | `inputs_stata_code/income_process/N_REPS.txt` is now the shared default read by both Stata and MATLAB, and it ships set to `1000` so the default run reproduces the paper bootstrap, as suggested by the replication team; `0` is the documented fast option. The `N_REPS` environment variable still works as an override. MATLAB now fails early with an actionable message if bootstrap covariance files are missing. |
| `psid_read.R` referenced a legacy `famvars_big.txt` list and an unshipped `Downloads/psid.xlsx` example. | The authors' exact variable lists `famvars_big.txt` and `indvars.txt` are now shipped next to `psid_read.R`, which finds them automatically; environment-variable overrides remain documented, and the unused `Downloads/psid.xlsx` code path was removed. |
| `outputs_stata_code/__main.do` could fail in Appendix B when raw `ACS_college.dta` was omitted. | The graph driver now rebuilds the college-share figure only when raw ACS/IPUMS is present; otherwise it keeps the packaged processed college-share inputs and existing graph. |
| Package datasets were shipped only as proprietary Stata `.dta` files. | Every shipped `.dta` is now accompanied by a `.csv` copy with identical values; `data/model_psid_all_govt__.dta` is documented as a regenerable intermediate and is the only exception. |

Pre-built Fortran executables must be rebuilt after source changes if the package is submitted with binaries. Generated logs and graphs should be regenerated after the final code run so that the deposit contains outputs from the revised scripts.

---

## Model Input Catalogue

Each model input file, its source, and the script that produces it.

| File | Source | Producer / location |
|---|---|---|
| `_data_Nn_US_1935_2100.txt` | UN World Population Prospects + CDC birth counts (https://population.un.org/wpp/, https://www.cdc.gov/nchs/nvss/) | `inputs_stata_code/external/` (hand-curated) |
| `_data_Nn_US_1935_init_old.txt` | CDC historical population tables | `inputs_stata_code/external/` (hand-curated) |
| `_data_rho_1935.txt` | SSA PIA benefit formula (https://www.ssa.gov/oact/) | `inputs_stata_code/external/` (hand-curated) |
| `_data_pi_cond_US_since1935.txt` | Human Mortality Database (https://www.mortality.org/) + UN WPP projections | `demography/mortality/D01_life_tables.do` |
| `_data_het_pi_US_since1935_all.txt` | Same as above, adjusted by education ratio from Case & Deaton (2021, PNAS 118(11)), shared by the authors | `demography/hetero_pi/D03_prepare_hetero_pi.do` |
| `_data_omega_{mostdrop,busno_drop}_hhslabinc_avghourlyhh.txt` | Derived from PSID 1970-2019 (https://psidonline.isr.umich.edu/) | `inputs_stata_code/income_process/I01_run_psid_income_inputs.do` |
| `_data_sigma2eps_{mostdrop,busno_drop}_hhslabinc_avghourlyhh.txt` | Derived from PSID 1970-2019 | `inputs_matlab_code/income_process/estimate_parameters.m` |
| `_data_gamma.txt` | Penn World Table 10.0 `rtfpna` (https://www.rug.nl/ggdc/productivity/pwt/) | `tfp/M02prepare_gamma.do` |
| `_data_gamma_robustness.txt` | Same as above (alternative scenario path) | `tfp/M02robustness_prepare_gamma.do` |
| `_data_tauC.txt`, `_data_tauK.txt`, `_data_tauL.txt` | McDaniel (2007) updated tax series (https://drive.google.com/drive/folders/1O5ccfP2KN815y-OSp2hRMnHneW4lAkia) | `tax_rate/T01prepare_taxes.do` |
| `_data_lambda.txt` | Piketty-based progressivity via Bayer-Born-Luetticke replication data (`tax_rate/progressivity_measures_all.xlsx`) | `tax_rate/T03prepare_tax_lambda.do` |
| `_data_contrib_to_gdp.txt` | OECD Revenue Statistics (https://data.oecd.org/) | `social_security/T02prepare_contributions.do` |
| `_data_depr.txt` | Penn World Table 10.0 `delta` | `depreciation/M01prepare_depr.do` |
| `_data_labsh.txt` | Penn World Table 10.0 `labsh` | `labor_share/M03prepare_labor_share.do` |
| `_data_skill_premium.txt` | Autor-Goldin-Katz (2020 AEA P&P), openICPSR 120694 | `skill_premium/H01prepare_skill_premium.do` |
| `_data_college_share.txt` | ACS/decennial census microdata via IPUMS USA (https://usa.ipums.org/usa/); raw extract uses years 1940, 1950, 1960, 1970, 1980, 1990, 2000, 2006, 2011, 2016, and 2021 with `YEAR`, `AGE`, `HIGRADE`, `EDUCD`, and `PERWT`; processed inputs are shipped so the raw extract is needed only for a full rebuild | `skill_premium/D02_prepare_college.do` |
| `_data_exog_rate.txt` | GGDC Penn World Table 10.0 `irr.USA` (internal rate of return); only consumed when `switch_exog_rate=1` (e.g. the `exor_` scenario, Figure F.7) | `exog_rate/M04prepare_exog_rate.do` |

### Auxiliary data consumed outside the Fortran input chain

- `data/SCF/SCF_plus.dta` - SCF+ harmonized wealth panel, Kuhn-Schularick-Steins (2020, *JPE*). The journal deposit should include this file (about 99 MB). If missing, download it from https://www.moritz-schularick.com/data and place it at this path. Consumed by `outputs_stata_code/_prep_Gini_data.do` and `MvD_3_GE_decomposition.do` to produce the paper's wealth-Gini and decomposition figures.
- `data/PSID/psid_ready.dta` - processed PSID panel generated from the mostdrop income-process sample and used by `outputs_stata_code/MvD_2_Gini_income.do` for Appendix Figure D.4. The Stata PSID stage refreshes this file when raw PSID is available.
- `inputs_stata_code/income_process/PSID/psid.dta` - raw PSID public-use extract. Obtain from https://psidonline.isr.umich.edu/ or from the authors' PSID Repository publication extract if one is supplied. Consumed only if replicators re-estimate the income process from scratch or regenerate `data/PSID/psid_ready.dta`. Otherwise the pre-computed `_data_omega_*.txt` and `_data_sigma2eps_*.txt` files suffice for running the Fortran model.
- `inputs_stata_code/skill_premium/ACS_college/processed/col_share_acs.dta` and `col_share_acs_ext.dta` - processed ACS/IPUMS college-share inputs. The raw `ACS_college.dta` extract is needed only to rebuild these processed files. `fortran_code/Data/_data_college_share.txt` is already included for the Fortran model; see `inputs_stata_code/skill_premium/ACS_college/README.md` for exact IPUMS years and variables.

### Recommended data citations

The following citations cover the data sources used by the paper and this package:

- Autor, David, Claudia Goldin, and Lawrence F. Katz. 2020. "Extending the Race between Education and Technology." *AEA Papers and Proceedings* 110: 347-351. Replication data: openICPSR 120694.
- Case, Anne, and Angus Deaton. 2021. "Life expectancy in adulthood is falling for those without a BA degree, but as educational gaps have widened, racial gaps have narrowed." *PNAS* 118(11).
- Feenstra, Robert C., Robert Inklaar, and Marcel P. Timmer. 2015. "The Next Generation of the Penn World Table." *American Economic Review* 105(10): 3150-3182. Penn World Table 10.0, https://www.rug.nl/ggdc/productivity/pwt/.
- Human Mortality Database. Max Planck Institute for Demographic Research (Germany), University of California, Berkeley (USA), and French Institute for Demographic Studies (France). https://www.mortality.org/.
- Kuhn, Moritz, Moritz Schularick, and Ulrike I. Steins. 2020. "Income and Wealth Inequality in America, 1949-2016." *Journal of Political Economy* 128(9): 3469-3519. SCF+ data archive: https://www.moritz-schularick.com/data.
- McDaniel, Cara. 2007. "Average tax rates on consumption, investment, labor and capital in the OECD 1950-2003." Arizona State University working paper; updated series.
- OECD. Revenue Statistics. https://data.oecd.org/.
- Panel Study of Income Dynamics, public use dataset. Produced and distributed by the Survey Research Center, Institute for Social Research, University of Michigan, Ann Arbor, MI. Waves 1970-2019.
- Ruggles, Steven, et al. IPUMS USA [dataset]. Minneapolis, MN: IPUMS. Collection DOI: https://doi.org/10.18128/C010; cite the version DOI matching the extract date (Version 16.0, https://doi.org/10.18128/D010.V16.0, current at this revision).
- Social Security Administration. Primary Insurance Amount benefit formula. https://www.ssa.gov/oact/.
- United Nations, Department of Economic and Social Affairs, Population Division. World Population Prospects. https://population.un.org/wpp/.
- US Centers for Disease Control and Prevention, National Center for Health Statistics. National Vital Statistics System. https://www.cdc.gov/nchs/nvss/.

The manuscript should carry the same data citations; this list is provided so the paper and the package stay in sync.

### Access, license, dates

All sources above are either public-domain, free for academic use under the provider's stated terms, or shipped here with the original authors' permission. Restricted or terms-governed raw microdata should be redistributed only through the provider-approved channel or omitted from the public package while retaining the processed files needed for replication. Source snapshots used in the paper were assembled during 2020-2022 and checked during the 2026 replication-package revision.

---

# Computational Requirements

## Software Requirements

### Required Software

1. **Intel Fortran Compiler**
   - Version: Intel oneAPI Fortran Compiler `ifx` 2025.1.1, build 20250418 (the version used to build the shipped `bin/5Gtrans.exe` and `bin/5Gtrans_het.exe`)
   - Download: https://www.intel.com/content/www/us/en/developer/tools/oneapi/fortran-compiler.html
   - Note: The vfproj uses `ifxCompiler` for the x64 configurations (Release, Release_HetRate, Debug). The Win32 configurations declare `ifortCompiler` but are not used for the shipped binaries.
   - License: Free download available (may require registration)

2. **Microsoft Visual Studio**
   - Version: Visual Studio Community 2019, 16.11.55 (`16.11.37206.5`)
   - Components required:
     - C++ build tools (required by Fortran compiler)
     - Windows SDK
   - Download: https://visualstudio.microsoft.com/downloads/
   - License: Community Edition (free) is sufficient

3. **Stata** (for calibration inputs and paper figures)
   - Version: Stata/SE 16.0
   - Required packages: `mat2txt` (used by the income-process pipeline), `ineqdeco` (used by the Gini prep), and `lorenz` (used by Appendix Figure D.4). These are auto-installed on first run by the scripts that need them.
   - Used by: `inputs_stata_code/` (Step 2, calibration inputs) and `outputs_stata_code/` (Step 7, paper figures)
   - License: Commercial (StataCorp)

4. **MATLAB**
   - Version: MATLAB 9.5.0.944444, R2018b
   - Used by: `inputs_matlab_code/income_process/` (Step 2B - income-process parameter estimation)
   - License: Commercial (MathWorks)

5. **Operating System**
   - Windows 10 (64-bit) or Windows 11 (64-bit)
   - Note: The batch scripts (.bat) and Visual Studio project files are Windows-specific
   - **Linux/macOS compatibility**: The Fortran code itself is cross-platform compatible, but would require:
     - GNU Make or equivalent build system
     - Modification of the system() calls in main.f90 (mkdir/copy commands)
     - Shell scripts to replace .bat files

### Optional Software

- **Text editor** for viewing results (any plain text editor)

---

## Hardware Requirements

### Minimum Requirements

- **Processor**: 4-core Intel or AMD x64 processor, 2.5 GHz or faster
- **RAM**: 8 GB
- **Storage**: At least 30 GB free space for a single baseline run. The baseline `psid_all_govt__` output alone includes multi-GB transition files, including `mass_trans_small.csv` and `prob_trans.csv`.
- **Operating System**: Windows 10 (64-bit)

### Recommended Specifications

- **Processor**: 8-core Intel or AMD x64 processor, 3.0 GHz or faster
- **RAM**: 16 GB or more
- **Storage**: 50 GB or more free space for comfortable replication. A complete set of paper-scenario result folders is about 27 GiB in the authors' results copy; 50 GB leaves headroom for reruns, logs, and temporary files.
- **Operating System**: Windows 11 (64-bit)

### Reference Hardware Environment

The April 2026 package verification and preprocessing run used:

- **Operating system**: Microsoft Windows 11 Pro, version 10.0.26200, build 26200
- **Processor**: AMD Ryzen 7 5800X 8-Core Processor
- **Cores / logical processors**: 8 / 16
- **RAM**: 95.9 GB
- **Local storage at verification time**: system drive 894 GB total / 651 GB free; data drive 3.7 TB total / 3.46 TB free
- **Repository location during verification**: network-mounted working copy

### Reference Software Environment

The recent package verification used:

- **Stata**: Stata/SE 16.0 (`C:\Program Files\Stata16\StataSE-64.exe`)
- **MATLAB**: MATLAB 9.5.0.944444, R2018b (`C:\Program Files\MATLAB\R2018b\bin\matlab.exe`)
- **Fortran compiler**: Intel Fortran Compiler `ifx` 2025.1.1, build 20250418, via Intel oneAPI 2025.1
- **Visual Studio**: Visual Studio Community 2019, version 16.11.55 (`16.11.37206.5`), with C++ build tools

The shipped Fortran binaries are Windows x64 builds. Rebuilding from source should work with the compiler/toolchain above or with a compatible Intel oneAPI Fortran + Visual Studio installation.

---

## Memory and Runtime Requirements

### Summary

The Stata and MATLAB preprocessing stages are relatively short compared with the Fortran transition computations. The full set of paper scenarios is a multi-day job on a typical workstation, and individual scenarios can take hours depending on convergence speed and hardware.

The largest practical resource constraint is disk space, not the code itself. In the authors' complete results copy, `fortran_code/Results/` is about 27 GiB across 30 scenario folders. Most of this comes from `psid_all_govt__` (about 19.8 GiB) and `psid_ndm_govt__` (about 6.7 GiB).

### Scenario Runtime Guidance

| Scenario group | Relative cost | Description |
|----------------|---------------|-------------|
| `psid_all_govt__` | High | Primary baseline; produces the largest downstream files used by most figures |
| `psid_n*` | High | Main counterfactuals for Figures 2-3 and appendices |
| `crr3_`, `ndel_`, `nstr_`, `gcbo_`, `beqs_` | High | Sensitivity families for Appendix F |
| `hrat_` | High | Heterogeneous-return sensitivity family; run separately with `5Gtrans_het.exe` |

### Runtime Scaling

- Scenarios are independent and can be run in parallel if you launch separate processes, provided there is enough RAM and disk bandwidth.
- Release builds are required for practical runtimes; Debug builds can be much slower.
- Runtime varies with convergence speed, tolerance settings, compiler version, CPU speed, and whether antivirus or cloud-sync tools scan the output folder during runs.

---
# Description of Programs and Code

## Overview

This replication package contains a **computational general equilibrium model** of overlapping generations (OLG) with heterogeneous agents. The model is implemented in **Fortran 90** and uses **policy function iteration** to solve household optimization problems and **iterative methods** to find equilibrium prices and allocations.

## Program Structure

### Main Program Files

- **`main.f90`**: Entry point for the model
  - Parses command-line arguments for scenario selection
  - Sets up file paths and creates output directories
  - Validates configuration files
  - Allocates memory for large arrays
  - Includes `main_base_transition.f90` for main computation

- **`main_base_transition.f90`**: Main computational logic (included in main.f90)
  - Computes initial steady state (pre-reform)
  - Computes final steady state (post-reform)
  - Computes transition path between steady states

### Core Computational Modules

- **`steady_state.f90`**: Steady state equilibrium solver
  - Iterates over capital stock to find market-clearing equilibrium
  - Calls household problem solver and aggregation routines
  - Computes government budget balance and pension system balance
  - **Key subroutine**: `steady()` (145-line documented header)

- **`transition.f90`**: Transition path solver
  - Solves for perfect foresight transition between two steady states
  - Handles cohort structure and time-varying parameters
  - Iterates to convergence on price paths
  - **Key subroutine**: `transition_path_DB()` (320+ line documented header)

### Household Problem Solvers

- **`pfi_household_problem.f90`**: Policy function iteration for household optimization
  - Solves household Bellman equation via backward induction
  - Handles 6-dimensional state space: age, assets, AIME, income shocks, return shocks, discount shocks
  - Computes optimal consumption, labor supply, and savings
  - **Contains**: `agent_vf()` and related optimization routines (130+ line documented header)

- **`pfi_agregation.f90`**: Aggregation across heterogeneous households
  - Computes aggregate capital, labor, consumption
  - Calculates distributional statistics (Gini coefficients, wealth shares)
  - Aggregates by age, type, and across population
  - **Key subroutine**: `get_aggregates()` (108-line documented header)

- **`pfi_distribution.f90`**: Distribution dynamics
  - Computes stationary distribution of agents across states
  - Forward simulation using policy functions
  - Handles initial distribution and bequest receipts
  - **Key subroutine**: `get_distribution()` (123-line documented header)

- **`pfi.f90`**: Master PFI module interface
  - Defines state space grids and interpolation methods
  - Sets up shock processes (income, return, discount)
  - Provides utility functions and helper routines
  - **234-line documented header** with complete problem formulation

### Economic Model Components

- **`pension_system.f90`** and **`pension_system_ss.f90`**: PAYG pension system
  - Calculates Social Security benefits using AIME formula
  - Handles valorization and indexation of benefits
  - Computes pension budget balance and subsidies
  - Supports both defined benefit (PAYG) and defined contribution (funded) systems

- **`ces_production.f90`** and **`ces_production_ss.f90`**: Production function
  - CES aggregation of heterogeneous labor types (college vs. non-college)
  - Computes factor prices (wages, interest rates)
  - Handles skill premium and substitution elasticity
  - **90+ line documented header**

- **`closures.f90`** and **`closure_ss.f90`**: Government budget
  - Computes government revenues (taxes on labor, capital, consumption)
  - Handles government debt dynamics
  - Implements closure rule (government spending adjusts residually)
  - **140+ line documented header** for transition path version

- **`bequest.f90`**: Bequest distribution
  - Calculates accidental bequests from mortality
  - Distributes bequests to surviving cohorts
  - Supports equal distribution, pooling, or Zipf distribution
  - **95-line documented header**

### Data and Configuration

- **`data.f90`**: Data loading and processing
  - Reads all external data files from `fortran_code/Data/` folder
  - Processes demographics, taxes, productivity, mortality
  - Extends time series to full transition horizon
  - **140-line documented header** listing all data files

- **`set_globals.f90`**: Parameter initialization
  - Reads configuration from `fortran_code/Instructions/` and `fortran_code/Parameters/` files
  - Sets up model parameters, switches, and arrays
  - Discretizes stochastic processes (AR(1) for shocks)
  - **160-line documented header** with 7-step initialization sequence

- **`globals.f90`**: Global variable declarations
  - Defines all model parameters, arrays, and constants
  - Dimensions: bigJ (ages), bigM (types), bigT (time periods)
  - State space: n_a (assets), n_aime (AIME), n_sp (income), n_sr (return), n_sd (discount)

### Utility Modules

- **`AR_discrete.f90`**: AR(1) process discretization
  - Rouwenhorst method for discretizing autoregressive processes
  - Used for income shocks, return shocks, discount factor heterogeneity

- **`normalProb.f90`**: Normal distribution utilities
  - CDF and PDF calculations for normal distribution
  - Used in shock process calibration

- **`linint.f90`**, **`splines.f90`**, **`polynomial.f90`**: Interpolation methods
  - Linear, cubic spline, and polynomial interpolation
  - Used for off-grid evaluation of value and policy functions

- **`rootfinding.f90`**, **`minimization.f90`**: Numerical optimization
  - Root-finding for Euler equations
  - Minimization for household optimization with constraints

- **`matrixtools.f90`**: Matrix operations
  - Linear algebra routines
  - Utilities for array manipulation

- **`sorting.f90`**: Sorting algorithms
  - Used for constructing wealth distribution
  - Needed for Gini coefficient and percentile calculations

- **`gini.f90`**: Inequality measures
  - Computes Gini coefficients
  - Calculates wealth and income concentration

### Output and Printing

- **`Print_steady_DB.f90`**: Steady state diagnostic output
  - Prints equilibrium values, prices, aggregates
  - Reports convergence diagnostics
  - Included in `steady_state.f90` when `switch_print=1`

- **`Print_DB.f90`**: Transition path diagnostic output
  - Prints time series of aggregate variables
  - Reports feasibility and error metrics
  - Included in `transition.f90`

- **`print_iter.f90`**: Iteration progress output
  - Reports convergence progress during iterative solution
  - Shows worst feasibility violations and errors

- **`print_stamp.f90`**: Timestamp utilities
  - Date/time stamps for output files

- **`pfi_print.f90`**: Policy function diagnostics
  - Prints policy functions for inspection/debugging

### Support Files

- **`clock.f90`**: Timing utilities for performance measurement
- **`assertions.f90`**: Runtime assertion checking
- **`errwarn.f90`**: Error and warning message handling
- **`gaussian_int.f90`**: Gaussian quadrature for numerical integration
- **`simplex.f90`**: Simplex algorithm (not currently used in main path)
- **`solver.f90`**: Additional solver utilities

### Build Configuration

- **`5Gtrans.sln`**: Visual Studio solution file
- **`5Gtrans.vfproj`**: Intel Fortran project file (contains compiler settings)
  - Optimization: /O2 (maximize speed)
  - Precision: /fp:precise
  - Runtime: multithreaded (/threads)

### Batch Scripts

- **`run_scenarios.bat`**: Runs a predefined set of scenarios
  - Hardcoded list of common scenarios
  - Useful for quick testing

- **`run_scenarios_from_list.bat`**: Runs scenarios from `scenarios.txt`
  - Reads scenario list from file (one per line)
  - Flexible for custom scenario sets

- **`scenarios.txt`**: List of scenarios to run
  - Format: `version experiment closure` (space-separated)
  - Example: `psid_ all_ govt__`

---

## Configuration Files

### Instructions Files (`fortran_code/Instructions/` folder)

Files named: `{version}{experiment}{closure}instructions.txt`

Format: 35 lines, each containing an integer switch value followed by comment
- Controls model features (mortality, taxes, pension rules, etc.)
- Order of lines is CRITICAL and must match `set_globals.f90` read order

Example: `psid_all_govt__instructions.txt`

### Parameters Files (`fortran_code/Parameters/` folder)

Files named: `{version}{experiment}{closure}parameters.txt`

Format: 51 lines containing numerical parameters
- Tolerance levels, damping factors, structural parameters
- Order of lines is CRITICAL and must match `set_globals.f90` read order

Example: `psid_all_govt__parameters.txt`

---

## Output Files

Results are written to scenario-specific subfolders: `fortran_code/Results/{version}{experiment}{closure}/`

**Output volume depends on three switches** in the scenario's `instructions.txt`:

| Switch | Baseline `psid_all_govt__` | All other shipped scenarios |
|---|---|---|
| `switch_print_macro` (line 36) | `1` | `0` |
| `switch_full_csv_write` (line 35) | `1` | `0` |
| `switch_small_write` (line 33) | `1` | `1` |

The baseline emits the full output set; every other scenario writes only the minimum needed to reproduce the paper figures (gini series + steady-state summaries + run metadata). Older runs may have left additional `*_j_trans.csv` / `mass_trans_minimal.csv` files in non-baseline result folders - those are stale artifacts of earlier code and are **not** produced by the current build.

### Always written (every scenario)

- `gini_trans.csv` - Gini coefficient of savings by year (consumed by [outputs_stata_code/_prep_Gini_data.do](outputs_stata_code/_prep_Gini_data.do))
- `steadys_old_information_run.txt` - Initial steady-state summary (gated by `switch_ss_write=1`, true for all shipped scenarios)
- `steadys_new_information_run.txt` - Final steady-state summary (same gating)
- `information.txt` - Run configuration and parameter summary
- `feasibility` - Per-period feasibility check from the transition iterations
- `{version}{experiment}{closure}instructions.txt`, `{version}{experiment}{closure}parameters.txt` - Copies of the inputs used (auto-copied for reproducibility)

### Written only when `switch_print_macro = 1` (baseline only)

Aggregate time series, one value per `bigT` period (1935-2100):

- Macro: `gdp_trans.txt`, `gdp_pc_trans.txt`, `bigK_trans.txt`, `bigY_trans.txt`, `capital_trans.txt`, `y_trans.txt`, `cy_ratio_trans.txt`, `ky_ratio_trans.txt`, `ky_ratio_trans_1y.txt`, `iy_ratio_trans.txt`, `gamma_trans.txt`, `nu_trans.txt`, `Nt_trans.txt`, `lifeexp_trans.txt`, `depend_ratio_trans.txt`, `g_share_trans.txt`, `lambda_trans.txt`, `zet_trans.txt`
- Rates and revenue: `r_trans.txt`, `rate_trans.txt`, `rbar_trans.txt`, `r_pretax_trans_1y.txt`, `r_afterax_trans_1y.txt`, `irr_trans_1y.txt`, `r_low_trans.txt` (only if `rate_adj /= 0`), `r_type_trans.csv` (same condition), `tC_trans.txt`, `tL_trans.txt`, `tK_trans.txt`, `tC_tax_revenue_trans.txt`, `tL_tax_revenue_trans.txt`, `tK_tax_revenue_trans.txt`
- Pension and debt: `benefits_trans.txt`, `replacement_trans.txt`, `replacement2_trans.txt`, `contrib_to_gdp_trans.txt`, `subsidy_share_trans.txt`, `sum_b_weight_trans.txt`, `debt_share_trans.txt`, `debt_cost_share_trans.txt`, `savings_trans.txt`, `debt_trans.txt`, `b_scale_factor.txt`, `t1_additional_contrib.txt`
- Welfare and superstars: `u_init_old_trans.txt`, `u_all_trans.txt`, `u20_trans.txt`, `star_tinc_trans.txt`, `star_linc_trans.txt`, `star_pop_trans.txt`, `beq_gdp_trans.txt`, `avg_hours_trans.txt`
- Distribution support: `gini_weight_trans.txt`, `gini_weight_trans.csv`

### Written only when `switch_full_csv_write = 1` (baseline only)

- `prob_trans.csv` - State-occupancy probabilities (year x age x asset x aime x income/return/discount shock)
- One of:
  - `mass_trans.csv` (if `switch_small_write = 0`) - Full mass distribution with all variables (consumption, hours, income, wealth, savings)
  - `mass_trans_small.csv` (if `switch_small_write = 1`) - Mass + pretax labor income + savings only (this is what the baseline scenario writes)
- `mass_trans_beq.csv` - Bequest-distribution mass (only if also `switch_unequal_bequest = 2`; not used by any shipped scenario)

### `switch_full_csv_write = 2` (compact mode, not used by any shipped scenario)

If you set this manually, you'll get `mass_trans_medium.csv` (`switch_small_write=0`) or `mass_trans_minimal.csv` (`switch_small_write=1`) instead of the `=1` outputs above.

---

## License for Code

The code in this repository is licensed under the MIT License.

**Copyright (c) 2026 the authors**

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

See [LICENSE.txt](LICENSE.txt) for full text.

---

# Instructions to Replicators

## Prerequisites

Before beginning a full replication from source, ensure you have:
1. Installed Intel Fortran Compiler (see Software Requirements)
2. Installed Visual Studio with C++ build tools (see Software Requirements)
3. At least 8 GB RAM and 30 GB free disk space for a baseline run (see Hardware Requirements)

For the plot-only fast path below, the Fortran compiler and Visual Studio are not needed if the precomputed `fortran_code/Results/` folders are already present.

---

## Step-by-Step Replication Instructions

Each step below is organized as **Inputs**, **Run**, **Outputs**, and **Details**. This is meant to separate what the replicator must supply from what the code produces.

### Step 1: Obtain and Check the Package

**Inputs**

- The extracted `3-replication-package` folder.
- Optional restricted raw-data files only if doing Route 3.

**Run**

Download and extract the package to any local path with enough disk space. No hardcoded locations are assumed.

```bat
dir
dir fortran_code\Results
```

**Outputs**

- A local working copy with this README, source code, shipped inputs, and, if included in the deposit, `fortran_code/Results/<scenario>/` folders.

**Details**

For Route 1, the result folders must already be present. At minimum, the figures use the scenario families listed in Step 6; the two largest folders are `psid_all_govt__` and `psid_ndm_govt__`. The baseline folder contains the large `mass_trans_small.csv` and `prob_trans.csv` files used by the Stata figure pipeline.

### Step 2: Generate Calibration Inputs

The Fortran model reads calibration files from `fortran_code/Data/`. Step 2 is split into a Stata stage for macro, demographic, fiscal, ACS, and PSID covariance inputs, and a MATLAB stage for the PSID income-process parameters.

**Inputs**

| Input | Required for | Location / setting |
|---|---|---|
| Packaged source snapshots | Routes 1-3 | `inputs_stata_code/`, `data/`, and `fortran_code/Data/` |
| Raw PSID extract | Route 3 PSID rebuild only | `inputs_stata_code/income_process/PSID/psid.dta` |
| Raw ACS/IPUMS extract | Route 3 ACS rebuild only | `inputs_stata_code/skill_premium/ACS_college/ACS_college.dta` |
| Stata | Step 2A and PSID stage of Step 2B | Stata 16+; packages are auto-installed where needed |
| MATLAB | MATLAB stage of Step 2B and Appendix Figure B.5 | `MATLAB_EXE` can override the default executable path |
| Bootstrap setting | Step 2B | `inputs_stata_code/income_process/N_REPS.txt` |

**Run**

Step 2A, the general Stata calibration stage:

1. Open `inputs_stata_code/main.stpr` in interactive Stata.
2. Open `__main_data_prepare.do` inside that project.
3. Run the do-file.

Step 2B, the PSID income-process stage, only if rebuilding PSID-derived inputs:

1. From the same Stata project, run `income_process/I01_run_psid_income_inputs.do`.
2. From the repository root, run:

```bat
set "MATLAB_EXE=C:\Program Files\MATLAB\R2018b\bin\matlab.exe"
inputs_matlab_code\income_process\run_income_process_matlab.bat
```

For Appendix Figure B.5 only, without re-estimating parameters, run:

```bat
"C:\Program Files\MATLAB\R2018b\bin\matlab.exe" -batch "run('outputs_matlab_code/income_process/plot_estimates.m')"
```

**Outputs**

| Output class | Files written or refreshed |
|---|---|
| Fortran calibration inputs | `fortran_code/Data/_data_*.txt` |
| PSID processed panels | `data/PSID/psid_ready.dta`, `data/PSID/ageeffects_*.dta` when raw PSID is supplied |
| ACS processed panels | `inputs_stata_code/skill_premium/ACS_college/processed/col_share_acs*.dta` when raw ACS/IPUMS is supplied |
| Calibration figures | `graphs/inputs/*.{png,eps,gph,svg,pdf}` for Stata figures; `graphs/inputs/sigma2eps_*.{eps,png}` for MATLAB |
| MATLAB live outputs | `inputs_matlab_code/income_process/output/<variant>/{H,L}.mat` |

**Details**

The Stata drivers use project-relative paths. Open them from `inputs_stata_code/main.stpr`; otherwise references such as `$bsource/bone` and `../fortran_code/Data/_data_$var.txt` may resolve incorrectly.

The `global download_data` switch is set to `0` at the top of the relevant Stata drivers. With the default value, scripts use packaged source snapshots and do not require network access. Setting it to `1` refreshes supported dbnomics/OECD/GGDC series and overwrites the local snapshots.

Raw ACS/IPUMS and raw PSID are conditional. If `ACS_college.dta` is absent, Step 2A keeps the packaged college-share inputs. If `psid.dta` is absent, Step 2A keeps the packaged PSID-derived Fortran inputs and processed `psid_ready.dta`. The exact raw-data specifications are in the Data Availability section and the local README files under `inputs_stata_code/income_process/PSID/` and `inputs_stata_code/skill_premium/ACS_college/`.

The full catalogue of `_data_*.txt` inputs and their producing scripts is in the Model Input Catalogue above. Three Fortran inputs have no Stata producer and are copied from `inputs_stata_code/external/` by `external/copy_to_fortran.do`: `_data_Nn_US_1935_2100.txt`, `_data_Nn_US_1935_init_old.txt`, and `_data_rho_1935.txt`.

The shared bootstrap setting is `inputs_stata_code/income_process/N_REPS.txt`. The shipped default is `1000`, which reproduces the paper's full bootstrap when you run both the Stata PSID stage and the MATLAB stage: expect about 12 hours in total, roughly 1 hour for Stata covariance generation plus roughly 11 hours for MATLAB `lsqnonlin` bootstrap estimation. For a fast run that computes point estimates only and reuses the archived 1000-repetition bootstrap files for the paper confidence bands, set that file to:

```text
0
```

MATLAB checks that the matching Stata bootstrap covariance files exist before starting a bootstrap run; if they are missing, it stops with an explicit missing-file message rather than a low-level `textscan` error.

`inputs_matlab_code/income_process/output/<variant>/{H,L}.mat` are live outputs and are overwritten by the MATLAB stage. The companion `{H,L}_archive.mat` files hold the authors' paper-baseline 1000-repetition bootstrap arrays. `outputs_matlab_code/income_process/plot_estimates.m` uses live point estimates plus archived confidence bands, so a fast `N_REPS=0` run does not erase the paper confidence intervals.

To verify Step 2, check:

```bat
dir fortran_code\Data
dir graphs\inputs
```

### Step 3: Compile the Model or Use Shipped Binaries

**Inputs**

- `fortran_code/*.f90`, `fortran_code/5Gtrans.sln`, and `fortran_code/5Gtrans.vfproj` if rebuilding.
- Intel oneAPI Fortran and Visual Studio with C++ build tools if rebuilding.
- `fortran_code/bin/5Gtrans.exe` and `fortran_code/bin/5Gtrans_het.exe` if using shipped binaries.

**Run**

Option 0, use shipped binaries:

```bat
dir fortran_code\bin
```

Option A, Visual Studio rebuild:

1. Open `fortran_code/5Gtrans.sln`.
2. Select `Release` and `x64`.
3. Build > Rebuild Solution.
4. Select `Release_HetRate` and `x64`.
5. Build > Rebuild Solution again for the heterogeneous-return executable.

Option B, command-line rebuild from an Intel Fortran prompt:

```bat
cd fortran_code
ifx /O2 /Qipo /exe:5Gtrans.exe *.f90
```

**Outputs**

- Main build: `fortran_code/x64/Release/5Gtrans.exe`.
- Heterogeneous-return build: `fortran_code/x64/Release_HetRate/5Gtrans_het.exe`.
- Shipped binary locations: `fortran_code/bin/5Gtrans.exe` and `fortran_code/bin/5Gtrans_het.exe`.

**Details**

The `Release_HetRate` configuration is needed for the `hrat_` sensitivity scenarios in Appendix F. It swaps in the heterogeneous-return source files through the Visual Studio project configuration. Compilation typically takes 2-5 minutes.

### Step 4: Run a Single Scenario Test

**Inputs**

- A main Fortran executable from Step 3.
- Calibration inputs in `fortran_code/Data/`.
- Matching instruction and parameter files in `fortran_code/Instructions/` and `fortran_code/Parameters/`.

**Run**

From `fortran_code/`, run the baseline scenario:

```bat
cd fortran_code
bin\5Gtrans.exe psid_ all_ govt__
```

After a local Visual Studio rebuild, you can instead run:

```bat
x64\Release\5Gtrans.exe psid_ all_ govt__
```

**Outputs**

- `fortran_code/Results/psid_all_govt__/`.
- Steady-state summaries, convergence diagnostics, aggregate time series, distribution files, and `gini_trans.csv`.

**Details**

This is a long run; expect hours for the baseline scenario on a typical workstation. The program prints the scenario name, then initial steady-state progress, final steady-state progress, and transition-path progress. Convergence is reached when the model's error criterion falls below the tolerance in the parameter file.

### Step 5: Verify a Scenario Output Folder

**Inputs**

- `fortran_code/Results/psid_all_govt__/` or another completed scenario folder.

**Run**

```bat
dir fortran_code\Results\psid_all_govt__
```

**Outputs to confirm**

- `steadys_old_information_run.txt` and `steadys_new_information_run.txt`.
- `gini_trans.csv`, consumed by downstream Stata scripts.
- Baseline aggregate series such as `gdp_trans.txt`, `r_trans.txt`, `bigK_trans.txt`, and `bigY_trans.txt`.
- Baseline full-output files `mass_trans_small.csv` and `prob_trans.csv`.

**Details**

The baseline scenario writes the large output set because it sets `switch_print_macro=1` and `switch_full_csv_write=1`. Most non-baseline scenarios write a smaller set, primarily `gini_trans.csv`, steady-state summaries, and run metadata. The full switch-by-switch output list is in the Output Files section.

### Step 6: Run All Model Scenarios

**Inputs**

- Completed Step 2 calibration inputs.
- Main executable `5Gtrans.exe`.
- Heterogeneous-return executable `5Gtrans_het.exe` for `hrat_` scenarios.
- Scenario definitions in `fortran_code/scenarios.txt`, `fortran_code/Instructions/`, and `fortran_code/Parameters/`.

**Run**

From `fortran_code/`:

```bat
cd fortran_code
run_scenarios_from_list.bat
run_scenarios_het.bat
```

**Outputs**

- One folder per completed scenario under `fortran_code/Results/`.
- The result folders consumed by Step 7 and listed in [SCENARIOS.md](SCENARIOS.md).

**Details**

`run_scenarios_from_list.bat` reads every uncommented scenario in `scenarios.txt` and runs them sequentially with `5Gtrans.exe`. It searches the current folder, `x64\Release\`, `x64\Debug\`, `Release\`, `Debug\`, and then `bin\` as a shipped-binary fallback.

The `hrat_` scenarios are not in `scenarios.txt`; run them with `run_scenarios_het.bat`, which invokes `5Gtrans_het.exe`. The full paper mapping from scenario family to figure is in [SCENARIOS.md](SCENARIOS.md). The complete scenario set is a multi-day workload.

To save a console log:

```bat
run_scenarios_from_list.bat > replication_log.txt 2>&1
```

Scenarios are independent and can be run in parallel in separate command windows if the machine has enough RAM and disk bandwidth.

### Step 7: Generate Paper Tables and Figures

**Inputs**

- Scenario folders under `fortran_code/Results/`.
- `data/SCF/SCF_plus.dta` for wealth model-vs-data figures.
- `data/PSID/psid_ready.dta` for Appendix Figure D.4.
- Stata project `outputs_stata_code/__replication_graphs.stpr`.

**Run**

1. Open `outputs_stata_code/__replication_graphs.stpr` in interactive Stata.
2. Open `__main.do` inside the project.
3. Run the do-file.

If the complete result folders are already present, Step 7 is the Route 1 fast path and Steps 2-6 can be skipped.

**Outputs**

- Main and appendix figures in `graphs/outputs/`.
- Appendix calibration/input figures in `graphs/inputs/`.
- Intermediate Stata datasets in `data/` where required by the plotting pipeline.

**Details**

`outputs_stata_code/__main.do` sets:

- `$resultspath = "..\fortran_code\Results\"`
- `$graphspath  = "..\graphs\outputs\"`
- `$datapath    = "..\data\"`

The driver produces main-text figures, Appendix B calibration figures, Appendix C population-structure figures, Appendix D model-vs-data figures, Appendix E decompositions, and Appendix F sensitivity figures. The full figure-to-script mapping is in the List of Tables and Figures section.

Appendix Figure B.1, the college-share calibration figure, is rebuilt only when `inputs_stata_code/skill_premium/ACS_college/ACS_college.dta` is present. If the raw ACS/IPUMS extract is omitted, the driver prints a message and keeps the packaged processed college-share inputs and existing `graphs/inputs/college_share.*` files.

`__main.do` assumes that every scenario referenced by the requested figures has already been run. Missing scenarios will surface as Stata errors pointing to the specific `.csv` or result folder that could not be imported.

The Stata drivers create transient `bone.dta` and `bone1y.dta` scratch files in `outputs_stata_code/`. They are regenerated on every run, read-only attributes are cleared before overwrite/delete attempts, and the files are safe to delete between runs.

---

## Verification

### Comparing Results to Paper

Use the replication crosswalk near the end of this README to map each paper table and figure to the Stata driver, Fortran scenario family, and output files that generate it. For the main numerical series, compare the files in `fortran_code/Results/psid_all_govt__/` and the generated figures in `graphs/outputs/` against the paper.

### Numerical Precision

Results should match the paper within numerical precision:
- **Steady state values**: Should match to 4-6 significant digits
- **Transition paths**: Should match to 3-5 significant digits
- **Welfare calculations**: Should match to 2-4 significant digits

**Small differences** (< 0.01%) may occur due to:
- Different compiler versions (Intel Fortran Classic vs. oneAPI)
- Different optimization flags
- Different operating system versions
- Hardware floating-point rounding differences

**Large differences** (> 1%) indicate a problem:
- Check that you're using the correct scenario
- Verify all data files are present and unchanged
- Check compiler settings (must be Release mode with /O2)
- Verify instructions and parameters files match the provided versions

---

## Troubleshooting

### Compilation Errors

**Error**: "Cannot open module file" or "Error opening compiled module"
- **Solution**: Clean the solution (Build > Clean) and rebuild
- Delete all .mod and .obj files in x64/Release/
- Rebuild from scratch

**Error**: "Link error: unresolved external"
- **Solution**: Ensure all .f90 files are included in the project
- Right-click project > Add > Existing Item > Select missing .f90 files

### Runtime Errors

**Error**: "Configuration file not found"
- **Solution**: Check that `fortran_code/Instructions/` and `fortran_code/Parameters/` folders contain the required files
- Verify file names exactly match: `{version}{experiment}{closure}instructions.txt`

**Error**: "Stack overflow" or "Access violation"
- **Solution**: Increase stack size in project properties
- Project Properties > Fortran > Optimization > Stack Size > Set to "unlimited" or large value (e.g., 500000000)

**Error**: Program hangs (no progress for hours)
- **Solution**: May be stuck in convergence loop
- Check parameters file: ensure tolerance (`err_ss_tol`) is not too small (e.g., use 1e-7, not 1e-12)
- Check damping parameter (`up_ss`) is between 0.3-0.8 (too high causes oscillation, too low is slow)

### Incorrect Results

**Issue**: Results differ significantly from paper
1. Verify scenario name is correct
2. Check that instructions and parameters files haven't been modified
3. Ensure Release mode (not Debug) was used
4. Verify compiler optimization is enabled (/O2)
5. Check data files haven't been corrupted (compare checksums if provided)

### Performance Issues

**Issue**: Runs much slower than expected runtime
- Check that Release mode is used (Debug is 10-50x slower)
- Verify CPU is not throttling (check temperatures, power settings)
- Close other applications (browser, etc.) to free RAM
- Check that antivirus isn't scanning the output folder during run


---

## Getting Help

### Documentation

- **`SCENARIOS.md`**: Full per-scenario catalogue, including which paper figure each scenario supports.
- **This README**: Replication instructions for users.

### Contact

For questions about replication, use the author contact information above.

---

# List of Tables and Figures

This section maps each numbered figure in the paper to the output files and programs that generate it. The paper contains no numbered tables.

## Reproducibility Status

The provided code and shipped inputs reproduce the paper conditional on the data inputs listed above:
- All numbers provided in text in the paper
- All main-text figures
- All scripted online-appendix figures
- All scripted online-appendix input-series figures

Data caveat: regenerating the PSID-derived income-process files requires the raw PSID extract; regenerating the ACS college-share input requires the raw IPUMS extract. The package includes processed versions needed for the Fortran model and Appendix Figures B.4 and D.4, plus SCF+ for the model-vs-data wealth figures.

---

## Main Text

| Figure | Paper title | Generating script | Output file |
|---|---|---|---|
| **Figure 1** | Evolution of wealth inequality: model vs. data | `outputs_stata_code/R_Figure1.do` | `graphs/outputs/Results_Gini_changes.png` |
| **Figure 2** | Baseline vs counterfactual scenario of constant longevity | `outputs_stata_code/R_Figure2.do` | `graphs/outputs/Results_Gini_counterfactuals.png` |
| **Figure 3** | Impact of rising longevity on wealth inequality (in Gini points) | `outputs_stata_code/R_Figure3.do` | `graphs/outputs/Results_Gini_drivers_demographics.png` |
| **Figure 4** | Impact of different factors evolution on wealth inequality (in Gini points) | `outputs_stata_code/R_Figure3.do` | `graphs/outputs/Results_Gini_drivers_comparison.png` |

The paper's main text contains no tables.

---

## Online Appendix B - Calibration

| Figure | Paper title | Generating script | Output file(s) |
|---|---|---|---|
| **Figure B.1** | Share of college graduates | `skill_premium/D02_prepare_college.do` | `graphs/inputs/college_share.*` |
| **Figure B.2** | Life expectancy at 50 (college vs. non-college) | `demography/hetero_pi/D03_prepare_hetero_pi.do` | `graphs/inputs/LE50year.*` |
| **Figure B.3** | Skill premium | `skill_premium/H01prepare_skill_premium.do` | `graphs/inputs/skill_premium.*` |
| **Figure B.4** | Deterministic profile of log productivity across age | `outputs_stata_code/income_process/M05plot_omega.do` | `graphs/inputs/omega_deaton_mostdrop_hhslabinc.*` |
| **Figure B.5** | Variances of idiosyncratic productivity shocks | `outputs_matlab_code/income_process/plot_estimates.m` | `graphs/inputs/sigma2eps_{mostdrop,busno_drop}_hhslabinc.{eps,png}` |
| **Figure B.6** | Technology - panels (a) depreciation, (b) labor share, (c) TFP | `depreciation/M01prepare_depr.do`; `labor_share/M03prepare_labor_share.do`; `tfp/M02prepare_gamma.do` | `graphs/inputs/depr.*`, `lab_share.*`, `gamma.*` |
| **Figure B.7** | Tax rates - panels (a-c) tau_C/tau_K/tau_L, (d) progressivity lambda | `tax_rate/T01prepare_taxes.do`; `tax_rate/T03prepare_tax_lambda.do` | `graphs/inputs/tC.*`, `tK.*`, `tL.*`, `lambda.*` |
| **Figure B.8** | Social security contributions to GDP | `social_security/T02prepare_contributions.do` | `graphs/inputs/contributions.*` |
| **Figure B.9** | Replacement-rate scale parameter rho_j,t | `inputs_stata_code/social_security/T04plot_rho.do` (invoked from `outputs_stata_code/__main.do`) | `graphs/inputs/rho.*` |

---

## Online Appendix C - Population structure

| Figure | Paper title | Generating script | Output file(s) |
|---|---|---|---|
| **Figure C.1** | Population structure: baseline vs. frozen-1955-longevity counterfactual, seven periods (1935, 1950, 1975, 2000, 2020, 2050, 2100) | `outputs_stata_code/R_FigureC1_popstructure.do` (reads `population.csv` from both `psid_all_govt__/` and `psid_ndm_govt__/` Results folders) | `graphs/outputs/AppC_PopStructure_{1935,1950,1975,2000,2020,2050,2100}.{png,svg}` |

---

## Online Appendix D - Model vs. data

| Figure | Paper title | Generating script | Output file |
|---|---|---|---|
| **Figure D.1** | The real interest rate, model vs data | `outputs_stata_code/MvD_1_macro.do` | `graphs/outputs/irr_trans_levels.*` |
| **Figure D.2** | Average annual hours per capita aged 20-64, model vs data | `outputs_stata_code/MvD_1_macro.do` | `graphs/outputs/avghours_trans_levels.*` |
| **Figure D.3** | Share of expenditure on social security benefits in GDP, model vs data | `outputs_stata_code/MvD_1_macro.do` | `graphs/outputs/benefits_trans_levels.*` |
| **Figure D.4** | Lorenz curves of income distribution (five decade snapshots, 1970-2010) | `outputs_stata_code/MvD_2_Gini_income.do` | `graphs/outputs/Lorenz_{1970,1980,1990,2000,2010}.*` |
| **Figure D.5** | Contribution of between-cohort vs. within-cohort inequality | `outputs_stata_code/MvD_3_GE_decomposition.do` | `graphs/outputs/MvD_GE.*` |

---

## Online Appendix E - Additional decompositions

| Figure | Paper title | Generating script | Output file |
|---|---|---|---|
| **Figure E.1** | Impact of evolution of income determinants on wealth inequality | `outputs_stata_code/R_Figure3.do` (`psid_ncs_/_ncp_/_nsh_` variants) | `graphs/outputs/Results_Gini_drivers_incomes.png` |
| **Figure E.2** | Impact of tax changes on wealth inequality | `outputs_stata_code/R_Figure3.do` (`psid_ntl_/_ntc_/_ntk_/_ntp_` variants) | `graphs/outputs/Results_Gini_drivers_taxes.png` |
| **Figure E.3** | Impact of technology changes on wealth inequality | `outputs_stata_code/R_Figure3.do` (`psid_nls_/_nga_/_ndp_` variants) | `graphs/outputs/Results_Gini_drivers_macro.png` |

---

## Online Appendix F - Sensitivity

| Figure | Paper title | Generating script | Output file |
|---|---|---|---|
| **Figure F.1** | Baseline vs. constant-longevity (theta = 3) | `outputs_stata_code/R_Figure2.do` (`crr3_` variants) | `graphs/outputs/AppF_Gini_counterfactuals_theta.png` |
| **Figure F.2** | Baseline vs. constant-longevity (heterogeneous returns) | `outputs_stata_code/R_Figure2.do` (`hrat_` variants) | `graphs/outputs/AppF_Gini_counterfactuals_hetrates.png` |
| **Figure F.3** | Baseline vs. constant-longevity (no discount-factor shocks) | `outputs_stata_code/R_Figure2.do` (`ndel_` variants) | `graphs/outputs/AppF_Gini_counterfactuals_homogendelta.png` |
| **Figure F.4** | Baseline vs. constant-longevity (no "superstars") | `outputs_stata_code/R_Figure2.do` (`nstr_` variants) | `graphs/outputs/AppF_Gini_counterfactuals_nosuperstars.png` |
| **Figure F.5** | Primary and alternative TFP growth rate | `tfp/M02robustness_prepare_gamma.do` | `graphs/inputs/gamma_robust.*` |
| **Figure F.6** | Baseline vs. constant-longevity (TFP growth rate) | `outputs_stata_code/R_Figure2.do` (`gcbo_` variants) | `graphs/outputs/AppF_Gini_counterfactuals_gamma.png` |
| **Figure F.7** | Baseline vs. open economy (exogenous interest rate) | `outputs_stata_code/R_Figure1_app.do` (`exor_` variant) | `graphs/outputs/AppF_Gini_counterfactuals_exograte.png` |
| **Figure F.8** | Baseline vs. constant-longevity (unequal bequest distribution) | `outputs_stata_code/R_Figure2.do` (`beqs_` variants) | `graphs/outputs/AppF_Gini_counterfactuals_beq.png` |

---

# References

## Bibliographic Data Citations

### Mortality and Demographics

- Human Mortality Database. University of California, Berkeley (USA), and Max Planck Institute for Demographic Research (Germany). https://www.mortality.org/ (accessed 2021).

- United Nations, Department of Economic and Social Affairs, Population Division. 2022. *World Population Prospects 2022*. https://population.un.org/wpp/

- Case, Anne and Deaton, Angus. 2021. "Life expectancy in adulthood is falling for those without a BA degree, but as educational gaps have widened, racial gaps have narrowed." *Proceedings of the National Academy of Sciences* 118(11): e2024777118. https://doi.org/10.1073/pnas.2024777118. Processed education-specific mortality file shared with us by the authors.

### Income, Wages, and Wealth

- Panel Study of Income Dynamics, public use dataset. Produced and distributed by the Survey Research Center, Institute for Social Research, University of Michigan, Ann Arbor, MI (1970-2019 waves). Data Center and documentation: https://psidonline.isr.umich.edu/ and https://psidonline.isr.umich.edu/Guide/documents.aspx. No PSID DOI is listed in the PSID Data Center documentation used for this package; cite the provider, waves, and access route.

- Autor, David, Claudia Goldin, and Lawrence F. Katz. 2020. "Extending the Race between Education and Technology." *AEA Papers and Proceedings* 110: 347-51. Replication package: openICPSR project 120694, https://www.openicpsr.org/openicpsr/project/120694/.

- Goldin, Claudia and Lawrence F. Katz. 2008. *The Race Between Education and Technology*. Cambridge, MA: Harvard University Press.

- U.S. Census Bureau. *American Community Survey* and decennial census microdata, accessed via IPUMS USA. IPUMS USA collection DOI: https://doi.org/10.18128/C010. The current IPUMS USA version at package revision is Version 16.0, https://doi.org/10.18128/D010.V16.0; use the version DOI corresponding to the extract date if rebuilding from IPUMS.

- Kuhn, Moritz, Moritz Schularick, and Ulrike I. Steins. 2020. "Income and Wealth Inequality in America, 1949-2016." *Journal of Political Economy* 128(9): 3469-3519 (SCF+ harmonized wealth panel). https://www.moritz-schularick.com/data

### Tax Parameters

- McDaniel, Cara. 2007. "Average tax rates on consumption, investment, labor and capital in the OECD 1950-2003," working paper (updated series used here). Data at https://drive.google.com/drive/folders/1O5ccfP2KN815y-OSp2hRMnHneW4lAkia.

- Bayer, Christian, Benjamin Born, and Ralph Luetticke. 2024. "Shocks, Frictions, and Inequality in US Business Cycles." *American Economic Review* 114(5): 1211-47. https://doi.org/10.1257/aer.20201875. Tax progressivity series (`progressivity_measures_all.xlsx`) downloaded from the authors' website on 2021-08-10.

### Productivity and Economic Aggregates

- Feenstra, Robert C., Robert Inklaar, and Marcel P. Timmer. 2015. "The Next Generation of the Penn World Table." *American Economic Review* 105(10): 3150-3182. Penn World Table 10.0, https://www.rug.nl/ggdc/productivity/pwt/ (accessed 2021 via dbnomics). Used for the TFP (`rtfpna`), depreciation (`delta`), labor share (`labsh`), and interest rate (`irr`) series.

### Government and Social Security

- U.S. Social Security Administration. *Primary Insurance Amount benefit formula*. Office of the Chief Actuary, https://www.ssa.gov/oact/ (used to compute age-specific replacement rates offline).

- OECD. *Revenue Statistics*, accessed via dbnomics (series `OECD/REV/NES.*.TAXGDP.USA`). https://data.oecd.org/

## Software and Tools

- Intel Corporation. 2025. "Intel oneAPI Fortran Compiler `ifx`." Version 2025.1.1, build 20250418. https://www.intel.com/content/www/us/en/developer/tools/oneapi/fortran-compiler.html

- Microsoft Corporation. 2019. "Visual Studio Community 2019." Version 16.11.55. https://visualstudio.microsoft.com/


---

# Acknowledgments

We thank (in alphabetical order) Roel Beetsma, Fabian Kindermann, Per Krusell, Iga Magda, Ward Romp, and Nancy Stokey for their valuable discussions and insights. We are especially grateful to Piotr Dworczak and Oliwia Komada for their thoughtful comments and suggestions. We also wish to acknowledge the Editor, Francesco Lippi, and four anonymous referees, whose constructive feedback greatly enhanced this paper. Additionally, we appreciate the comments received from the participants of AEA 2022, CEF 2022, and IIPF 2022.

We are indebted to Marcin Lewandowski for his excellent research assistance.

This project was supported by National Science Center (Poland), grant #2016/22/E/HS4/00129, whose generosity is greatly appreciated.

Any remaining errors are entirely our own.

---

**Last Updated**: May 2026

**Corresponding Author**: Joanna Tyrowicz - j.tyrowicz@grape.org.pl
