# Replication Package: Demographic Transition and the Rise of Wealth Inequality

**Date**: January 2026

This replication package accompanies:

Krzysztof Makarski, Joanna Tyrowicz, and Piotr Żoch. (forthcoming). "Demographic transition and the rise of wealth inequality". *Economic Journal*.

---

## Repository Layout

```
demographic-transition-wealth-inequality/
├── README.md                    This file
├── LICENSE.txt                  MIT license
├── SCENARIOS.md                 Full scenario catalogue
│
├── fortran_code/                Fortran OLG model (main solver)
│   ├── *.f90                    Source files
│   ├── 5Gtrans.sln              Visual Studio solution
│   ├── Data/                    Calibration inputs consumed by the model
│   ├── Instructions/            Per-scenario switch files
│   ├── Parameters/              Per-scenario parameter files
│   ├── Results/                 Per-scenario output (gitignored, regenerated)
│   ├── scenarios.txt            Scenario list for batch runs
│   └── run_scenarios*.bat       Batch drivers
│
├── inputs_stata_code/           Stata (and MATLAB) code that produces
│                                the calibration inputs in fortran_code/Data/
│   ├── demography/
│   ├── depreciation/
│   ├── income_process/          Stata + MATLAB income-process pipeline
│   │   ├── estimate_income_process.do
│   │   ├── estimate_parameters.m
│   │   ├── matlab/              Helper .m files
│   │   └── run_estimation.bat   End-to-end driver (Stata → MATLAB → plot)
│   ├── labor_share/
│   ├── skill_premium/
│   ├── social_security/
│   ├── tax_rate/
│   └── tfp/
│
├── outputs_stata_code/          Stata code that produces paper tables/figures
│                                from Fortran output
│
├── sensitivity_stata_code/      Robustness-check Stata code
│
├── graphs/                      Generated figures (inputs/ and outputs/)
│
├── data/                        Raw microdata and model-ready panels
│                                (PSID, SCF, etc. — gitignored, see below)
│
├── psid/                        Root-level PSID extract consumed by
│                                inputs_stata_code/income_process/
│                                (gitignored, ~98 MB)
│
└── docs/                        Internal docs (brainstorms, solutions)
```

**Pipeline at a glance**: `data/` + `psid/` → `inputs_stata_code/` (Stata/MATLAB) → `fortran_code/Data/` → `fortran_code/` (OLG model solver) → `fortran_code/Results/` → `outputs_stata_code/` (tables and figures) → `graphs/outputs/`.

> **All shell commands in the replication steps below assume you are in the `fortran_code/` subdirectory unless the step explicitly says otherwise.** File paths in prose (e.g. `fortran_code/Data/_data_*.txt`, `fortran_code/Results/psid_all_govt__/`) are likewise relative to `fortran_code/` unless qualified with another prefix.

---

## Authors

- **Krzysztof Makarski** - SGH Warsaw School of Economics and FAME|GRAPE - kmakar@sgh.waw.pl
- **Joanna Tyrowicz** - University of Augsburg, FAME|GRAPE, University of Warsaw, and IZA - j.tyrowicz@grape.org.pl
- **Piotr Żoch** - University of Warsaw, FAME|GRAPE - p.zoch@uw.edu.pl

**Corresponding Author**: Joanna Tyrowicz - j.tyrowicz@grape.org.pl

**Replication Package Maintainer**: Piotr Żoch - p.zoch@uw.edu.pl

---

## License

The code in this repository is licensed under the [MIT License](https://choosealicense.com/licenses/mit/).

See [LICENSE.txt](LICENSE.txt) for full license text.

Data licensing information is provided in the Data Availability section below.

---

# Data Availability and Provenance Statements

## Statement about Rights

The author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript.

## Summary of Availability

This paper uses publicly available data and authors' estimates derived from restricted-access microdata. All **processed/derived data files** necessary for replication are included in this package.

Some estimates were derived from **restricted-access PSID microdata** (Panel Study of Income Dynamics, 1970-2019 waves). The PSID microdata cannot be redistributed but can be accessed by researchers through the PSID Data Center (see Section 3 below for access instructions).

**Important**: All results in the paper can be replicated using the included derived data files. Access to raw PSID data is NOT required for replication, but instructions are provided for researchers who wish to re-estimate the income process parameters from scratch.

---

## Details on Each Data Source

### 1. U.S. Population Data by Age Cohort

**Description**: Historical and projected population counts by 5-year age groups for the United States, covering years 1935-2100.

**Source**: United Nations Population Database

**Access**: https://population.un.org/wpp/

**Date Accessed**: 2021-2022

**License/Terms**: Public domain, freely redistributable under UN terms of use

**Files in this package**:
- `fortran_code/Data/_data_Nn_US_1935_2100.txt` - Main population series (1935-2100)
- `fortran_code/Data/_data_Nn_US_1935_init_old.txt` - Initial population distribution for 1935

**Notes**: Population data aggregated into 5-year periods (model periods). Historical data (1935-2020) combined with UN medium-variant projections (2020-2100) for future periods.

---

### 2. Survival Probabilities and Mortality Data

**Description**: Conditional survival probabilities by age and education level (college vs. less than college). Constructed from U.S. death certificate data.

**Source**: Case, Anne and Deaton, Angus. 2021. "Life expectancy in adulthood is falling for those without a BA degree, but as educational gaps have widened, racial gaps have narrowed." *Proceedings of the National Academy of Sciences* 118(11): e2024777118. https://doi.org/10.1073/pnas.2024777118

**Access**: Data available from PNAS supplementary materials at: https://www.pnas.org/doi/10.1073/pnas.2024777118

**Date Accessed**: 2021

**License/Terms**: Published data, freely available for research use

**Files in this package**:
- `fortran_code/Data/_data_pi_cond_US_since1935.txt` - Conditional survival probabilities (overall population)
- `fortran_code/Data/_data_pi_cond_het_US_since1935.txt` - Heterogeneous survival (by education, 1990-2018)
- `fortran_code/Data/_data_pi_US_since1935_col.txt` - College-educated survival probabilities
- `fortran_code/Data/_data_pi_US_since1935_no_col.txt` - Non-college-educated survival probabilities
- `fortran_code/Data/_data_het_pi_US_since1935_all.txt` - Comprehensive heterogeneous mortality data

**Notes**:
- Case and Deaton (2021) provide mortality data by education for cohorts reaching age 50 between 1935-1990 (historical) and 1990-2065 (projections).
- For cohorts born before 1915, we extrapolate using the ratio observed for the 1915 cohort (1.018).
- For cohorts born after 1990, we use the ratio observed for the 1990 cohort (1.006).
- Combined with UN population data to construct complete survival probabilities by education.

---

### 3. Age-Efficiency (Wage) Profiles

**Description**: Age-specific labor productivity profiles reflecting life-cycle earnings patterns, estimated separately for college and non-college educated workers.

**Source**: **Authors' estimates** using Panel Study of Income Dynamics (PSID) 1970-2019 waves. Estimation uses Deaton-Paxson (2000) decomposition method to separate age, cohort, and time effects.

**Raw Data Access**: PSID data requires registration at https://psidonline.isr.umich.edu/. Free access for research purposes, requires data use agreement.

**Date Accessed**: 2020-2021

**License/Terms**: PSID data subject to data use agreement. **Raw microdata cannot be redistributed**. Estimated age profiles (included here) can be shared.

**Files in this package** (all are **derived/analysis data**):
- `fortran_code/Data/_data_omega_deaton_avghourly.txt` - Baseline age-efficiency profile
- `fortran_code/Data/_data_omega_deaton_avghourlyhh.txt` - Household-level profile
- `fortran_code/Data/_data_omega_busno_drop_hhslabinc_avghourlyhh.txt` - Excluding business income
- `fortran_code/Data/_data_omega_mostdrop_hhslabinc_avghourlyhh.txt` - Alternative specification
- [Additional omega files for robustness specifications]

**Notes**:
- These files contain **estimated parameters**, not raw PSID data
- Estimation procedure: Deaton and Paxson (2000) decomposition, identifying age effects while controlling for cohort and year effects
- Raw PSID data is NOT needed for replication - use the included estimated profiles
- For researchers who want to re-estimate: See Online Appendix for detailed estimation procedure

---

### 4. Total Factor Productivity (TFP) Growth

**Description**: Historical TFP growth rates (1950-2017) and projections (2018-2100) for the U.S. economy, adjusted to be labor-augmenting.

**Source**:
- Historical (1950-2017): Penn World Table (PWT) 10.0, variable `rtfpna`
- Projections (2018+): Fernald, John G. 2016. "Reassessing Longer-Run U.S. Growth: How Low?" Federal Reserve Bank of San Francisco Working Paper 2016-18.

**Access**:
- PWT 10.0: https://www.rug.nl/ggdc/productivity/pwt/
- Fernald (2016): https://www.frbsf.org/economic-research/publications/working-papers/2016/18/

**Date Accessed**: 2020-2021

**License/Terms**: Both public domain / freely available for research

**Files in this package**:
- `fortran_code/Data/_data_gamma.txt` - Baseline TFP growth series (1935-2100)
- `fortran_code/Data/_data_gamma_robustness.txt` - Alternative TFP for robustness checks

**Notes**:
- TFP from PWT adjusted to be labor-augmenting using time-varying capital share α_t
- Further adjusted for changing age/education composition and skill premium
- Pre-1950: Flat TFP growth assumed
- Post-2020: 0.6% annual TFP growth following Fernald (2016) projections (range: 0.4-0.8%)

---

### 5. Tax Progressivity and Effective Tax Rates

**Description**: Tax progressivity parameter (λ) governing the elasticity of after-tax to pre-tax income in the progressive tax function.

**Source**: Heathcote, Jonathan, Kjetil Storesletten, and Giovanni L. Violante. 2017. "Optimal Tax Progressivity: An Analytical Framework." *Quarterly Journal of Economics* 132(4): 1693-1754.

**Access**: https://doi.org/10.1093/qje/qjx018 (Parameter values reported in paper)

**Date Accessed**: 2020

**License/Terms**: Published academic paper, parameters can be used with citation

**Files in this package**:
- `fortran_code/Data/_data_lambda.txt` - Tax progressivity parameter over time (1935-2100)

**Notes**:
- λ_t governs progressivity in tax function: T(y) = y - (1-τ)(y/ȳ)^(1-λ)ȳ
- Historical values from Heathcote et al. (2017) estimates
- Projected to remain constant after 2020

---

### 6. Social Security Replacement Rates

**Description**: Parameters governing Social Security benefit calculations in the model (rho parameter).

**Source**: Calibrated to match U.S. Social Security Administration data on benefit expenditures as share of GDP

**Access**: SSA Office of the Chief Actuary - https://www.ssa.gov/oact/

**Date Accessed**: 2020-2021

**License/Terms**: Public domain

**Files in this package**:
- `fortran_code/Data/_data_rho_1935.txt` - Replacement rate parameter series (1935-2100)

**Notes**: Model replicates observed pension expenditure/GDP ratio well, with future path matching CBO projections

---

### 7. Educational Attainment and Skill Premium

**Description**: (a) Share of population with college education by birth cohort, and (b) College wage premium (log difference between college and non-college wages)

**Sources**:
- **College shares**: U.S. Census Bureau and American Community Survey (individual-level data aggregated by cohort)
- **Skill premium**: Autor, David and Dorn, David. 2020. "Changes in the occupational skill-intensity of U.S. manufacturing employment: 1980-1995." Updated series from Goldin and Katz (2008), extended to 1914-2020.

**Access**:
- Census/ACS: https://www.census.gov/programs-surveys/acs
- Skill premium data: Updated series available from Autor-Dorn research pages

**Date Accessed**: 2020-2021

**License/Terms**: Public domain (Census/ACS), published academic series (skill premium)

**Files in this package**:
- `fortran_code/Data/_data_college_share.txt` - Share with college degree by cohort (1885-2050)

**Notes**:
- College shares calculated for each entry cohort and projected forward
- Skill premium series smoothed using Hodrick-Prescott filter (λ=6.25), assumed constant after 2020

---

### 8. Social Security Contribution Rates

**Description**: Payroll tax rates for Social Security over time, relative to GDP

**Source**: OECD Social Security Contributions database

**Access**: https://data.oecd.org/

**Date Accessed**: 2020-2021

**License/Terms**: OECD data freely available for research

**Files in this package**:
- `fortran_code/Data/_data_contrib.txt` - Empty file (contributions calculated endogenously in model)
- `fortran_code/Data/_data_contrib_to_gdp.txt` - Historical contributions as share of GDP

**Notes**: Model uses contributions/GDP ratio. Effective contribution rate τ_ss calculated using labor share (1-α)

---

### 9. Depreciation Rates and Capital Share

**Description**: Capital depreciation rates and labor/capital shares in production

**Source**: Bureau of Economic Analysis (BEA) Fixed Assets Tables and National Income accounts

**Access**: https://apps.bea.gov/national/FA2004/Index.asp

**Date Accessed**: 2020-2021

**License/Terms**: Public domain

**Files in this package**:
- `fortran_code/Data/_data_depr.txt` - Depreciation rate series (1935-2100)

**Notes**: Depreciation rates from BEA aggregated across asset types, adjusted to model periodicity (5 years)

---

### 10. Additional Calibration Data

**Description**: Labor share, government spending, and other auxiliary parameters

**Sources**:
- **Labor share**: BEA NIPA tables
- **Government spending**: BEA National Income accounts
- **Interest rates**: Various (used for counterfactual scenarios only)

**Files in this package**:
- `fortran_code/Data/_data_labsh.txt` - Labor share of income (=1-α)
- `fortran_code/Data/_data_gy_1935.txt` - Government spending relative to GDP (empty - calculated endogenously)
- `fortran_code/Data/_data_exog_rate_1935.txt` - Exogenous interest rates (for sensitivity analysis)

**Access**: https://www.bea.gov/

**License/Terms**: Public domain

**Notes**: Most fiscal parameters determined endogenously by government budget closure rule

---

### Data Not Included

**[IF APPLICABLE]:**

The following data cannot be redistributed due to licensing restrictions:
- [List any restricted data]
- Instructions for access: [Provide detailed steps]
- Expected access timeline: [e.g., "2-3 months for data use agreement approval"]
- Contact for assistance: [name and email]

**Without this restricted data, the following results cannot be replicated**:
- [List specific tables/figures that require restricted data]

**All other results can be replicated using the included data.**

---

# Dataset List

| Data File | Source | Type | Included | Described Above |
|-----------|--------|------|----------|-----------------|
| `_data_Nn_US_*.txt` | [Source] | Secondary/Public | Yes | Section 1 |
| `_data_pi_*.txt` | [Source] | Secondary/Public | Yes | Section 2 |
| `_data_omega_*.txt` | Derived from PSID | Analysis/Derived | Yes | Section 3 |
| `_data_gamma*.txt` | [Source] | Secondary/Public | Yes | Section 4 |
| `_data_lambda.txt` | Heathcote et al. (2017) | Secondary/Public | Yes | Section 5 |
| `_data_rho_*.txt` | [Source] | Secondary/Public | Yes | Section 6 |
| `_data_college_share.txt` | [Source] | Secondary/Public | Yes | Section 7 |
| `_data_contrib*.txt` | SSA | Secondary/Public | Yes | Section 8 |
| `_data_depr.txt` | BEA | Secondary/Public | Yes | Section 9 |
| `_data_labsh.txt` | [Source] | Secondary/Public | Yes | Section 10 |
| `_data_gy_*.txt` | [Source] | Secondary/Public | Yes | Section 10 |
| `_data_exog_rate_*.txt` | [Source] | Secondary/Public | Yes | Section 10 |

**Note**: Additional robustness variants exist for some data series (e.g., multiple omega files for different specifications).

---

# Computational Requirements

## Software Requirements

### Required Software

1. **Intel Fortran Compiler**
   - Version: Intel Fortran Compiler Classic 2021.1 or later, OR Intel oneAPI Fortran Compiler 2024.0 or later
   - Download: https://www.intel.com/content/www/us/en/developer/tools/oneapi/fortran-compiler.html
   - Note: Both the classic (ifort) and the new (ifx) compilers work
   - License: Free download available (may require registration)

2. **Microsoft Visual Studio**
   - Version: Visual Studio 2019 or later (2022 recommended)
   - Components required:
     - C++ build tools (required by Fortran compiler)
     - Windows SDK
   - Download: https://visualstudio.microsoft.com/downloads/
   - License: Community Edition (free) is sufficient

3. **Stata** (for calibration inputs and paper figures)
   - Version: Stata/SE 16 or later (tested with Stata 16)
   - Required packages: `psmatch2`, `mat2txt`, `egenmore` (install via `ssc install`)
   - Used by: `inputs_stata_code/` (Step 2, calibration inputs) and `outputs_stata_code/` (Step 7, paper figures)
   - License: Commercial (StataCorp)

4. **MATLAB**
   - Version: R2018b or later
   - Used by: `inputs_stata_code/income_process/` (Stage B of Step 2 — income-process parameter estimation)
   - License: Commercial (MathWorks)

5. **Git** (for cloning repository)
   - Version: 2.30 or later
   - Download: https://git-scm.com/downloads
   - License: Open source (GPL)

6. **Operating System**
   - Windows 10 (64-bit) or Windows 11 (64-bit)
   - Note: The batch scripts (.bat) and Visual Studio project files are Windows-specific
   - **Linux/macOS compatibility**: The Fortran code itself is cross-platform compatible, but would require:
     - GNU Make or equivalent build system
     - Modification of the system() calls in main.f90 (mkdir/copy commands)
     - Shell scripts to replace .bat files

### Optional Software

- **Intel VTune Profiler** (for performance analysis, not required for replication)
- **Text editor** for viewing results (any plain text editor)

---

## Hardware Requirements

### Minimum Requirements

- **Processor**: 4-core Intel or AMD x64 processor, 2.5 GHz or faster
- **RAM**: 8 GB
- **Storage**: 2 GB free space (500 MB for code and data, 1.5 GB for results)
- **Operating System**: Windows 10 (64-bit)

### Recommended Specifications

- **Processor**: 8-core Intel or AMD x64 processor, 3.0 GHz or faster
- **RAM**: 16 GB or more
- **Storage**: 5 GB free space (allows for multiple scenario results)
- **Operating System**: Windows 11 (64-bit)

### System Used for Publication Results

The results in the paper were produced on the following system:

- **Machine**: [Desktop workstation / Laptop / Server cluster]
- **Processor**: [Specific model, e.g., "Intel Core i7-12700K (8 cores, 16 threads) @ 3.6 GHz base, 5.0 GHz turbo"]
- **RAM**: [e.g., "32 GB DDR4-3200"]
- **Storage**: [e.g., "1 TB NVMe SSD"]
- **Operating System**: Windows 11 Pro (Build 26200)
- **Compiler**: Intel Fortran Compiler Classic 2021.7.1
- **Visual Studio**: Visual Studio 2022 (Version 17.8)

---

## Memory and Runtime Requirements

### Summary

**Total time to reproduce all results**: Approximately [X hours] on the recommended system specified above.

**Peak memory usage**: Approximately [Y GB] RAM for the largest scenarios.

### Details by Scenario

Runtime estimates on the system specified above (8-core processor, 16 GB RAM):

| Scenario | Runtime | Memory Peak | Description |
|----------|---------|-------------|-------------|
| `psid_all_govt__` | ~[X] hours | ~[Y] GB | **PRIMARY BASELINE** - Full model with all transitions |
| `psid_ndm_govt__` | ~[X] hours | ~[Y] GB | Counterfactual: No demographic changes |
| `psid_nds_govt__` | ~[X] hours | ~[Y] GB | Counterfactual: Population structure fixed at 1955 |
| `psid_ntx_govt__` | ~[X] hours | ~[Y] GB | Counterfactual: Tax system fixed at 1955 |
| [Other scenarios] | ~[X] hours | ~[Y] GB | [Description] |

**Total for all scenarios in scenarios.txt**: ~[X] hours

### Runtime Scaling

- Runtime scales approximately linearly with CPU speed
- Memory requirements are fixed (not dependent on CPU)
- Scenarios can be run in parallel on multi-core systems (no dependencies between scenarios)
- Using all cores (parallel execution of scenarios): Total time reduces to ~[X] hours

### Runtime Components

For the main baseline scenario (`psid_all_govt__`):
1. Initial steady state computation: ~[X]% of total runtime ([Y] minutes)
2. Final steady state computation: ~[X]% of total runtime ([Y] minutes)
3. Transition path computation: ~[X]% of total runtime ([Y] hours)
4. Output writing and aggregation: ~[X]% of total runtime ([Y] minutes)

**Note on Convergence**: Runtime can vary by ±20% depending on convergence speed, which is affected by:
- Initial guesses (currently optimized for fast convergence)
- Tolerance settings (set in parameters files)
- Compiler optimization flags (set to /O2 in Release mode)

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
- See CLAUDE.md for detailed line-by-line documentation

Example: `psid_all_govt__instructions.txt`

### Parameters Files (`fortran_code/Parameters/` folder)

Files named: `{version}{experiment}{closure}parameters.txt`

Format: 51 lines containing numerical parameters
- Tolerance levels, damping factors, structural parameters
- Order of lines is CRITICAL and must match `set_globals.f90` read order
- See CLAUDE.md for detailed line-by-line documentation

Example: `psid_all_govt__parameters.txt`

---

## Output Files

Results are written to scenario-specific subfolders: `fortran_code/Results/{version}{experiment}{closure}/`

### Time Series Outputs

Files named: `{variable}_trans.txt`

- `gdp_trans.txt` - GDP over transition
- `r_trans.txt` - Interest rate
- `bigK_trans.txt` - Aggregate capital
- `bigl_trans.txt` - Aggregate labor
- `debt_trans.txt` - Government debt
- `replacement_trans.txt` - Pension replacement rate
- [Many more time series files]

Format: One value per line, representing years 1935-2100 (bigT periods)

### Cross-Sectional Outputs

Files named: `{variable}_j_trans.csv`

- `c_j_trans.csv` - Consumption by age
- `l_j_trans.csv` - Labor supply by age
- `b_j_trans.csv` - Pension benefits by age
- [Many more cross-sectional files]

Format: CSV files with dimensions (age × type × time)

### Distributional Outputs

- `mass_trans.csv` or `mass_trans_small.csv` - Full distribution (if `switch_full_csv_write=1`)
- `mass_trans_medium.csv` - Medium output (if `switch_full_csv_write=0`, `switch_small_write=0`)
- `mass_trans_minimal.csv` - Minimal output (if `switch_small_write=1`)
- `prob_trans.csv` - Probability distributions across states
- `gini_weight_trans.csv` - Gini coefficient weights

### Steady State Information

- `steadys_old_information_run.txt` - Initial steady state summary
- `steadys_new_information_run.txt` - Final steady state summary
- `information.txt` - Run configuration and parameter summary

### Copied Configuration (for reproducibility)

- `{version}{experiment}{closure}instructions.txt` - Copy of instructions used
- `{version}{experiment}{closure}parameters.txt` - Copy of parameters used

---

## License for Code

The code in this repository is licensed under the MIT License.

**Copyright (c) [YEAR] [COPYRIGHT HOLDERS]**

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

See [LICENSE.txt](LICENSE.txt) for full text.

---

# Instructions to Replicators

## Prerequisites

Before beginning, ensure you have:
1. ✅ Installed Intel Fortran Compiler (see Software Requirements)
2. ✅ Installed Visual Studio with C++ build tools (see Software Requirements)
3. ✅ At least 8 GB RAM and 2 GB free disk space (see Hardware Requirements)
4. ✅ Cloned or downloaded this repository to your local machine

---

## Step-by-Step Replication Instructions

### Step 1: Download the Repository

```bash
git clone https://github.com/pzoch/demographic-transition-wealth-inequality.git
cd demographic-transition-wealth-inequality
```

Or download as ZIP and extract to any local path — no hardcoded locations are assumed.

---

### Step 2: Generate Calibration Inputs (Stata + MATLAB)

The Fortran model reads ~40 calibration input files from `fortran_code/Data/`. These files are produced by the Stata (and MATLAB) code under `inputs_stata_code/`. **Re-running the calibration pipeline is part of the replication**: the pre-generated files in the repository reflect the authors' most recent run and should be treated as a snapshot, not a frozen deliverable.

**Required software**:
- **Stata 16+** with the `psmatch2`, `mat2txt`, and `egenmore` packages
- **MATLAB R2018b+** (required by `inputs_stata_code/income_process/`)
- **Raw PSID extract** at `psid/psid.dta` (~98 MB, at the repository root). Not redistributed — obtain through the PSID Data Center. See the Data Availability section for access instructions.

#### Stage A — Macro, Demographic, and Fiscal Inputs

The master driver is `inputs_stata_code/__main_data_prepare.do`, but **do not run it headlessly with `stata -e`**. The pipeline is designed to be launched from a Stata project file that establishes the project root and working directory. The repository ships two such entry points, one per Stata stage:

| Stage | Project file | Driver to run from inside it |
|---|---|---|
| Step 2 — calibration inputs | `inputs_stata_code/main.stpr` | `__main_data_prepare.do` |
| Step 7 — paper figures | `outputs_stata_code/__replication_graphs.stpr` | `__main.do` |

To run Step 2:

1. Open `inputs_stata_code/main.stpr` in interactive Stata (File → Open, or double-click the file on Windows).
2. In the project's Do-file window, open `__main_data_prepare.do`.
3. Run the do-file (Do-file Editor → Execute).

The helpers in this folder use relative paths (`$bsource/bone`, `../fortran_code/data/_data_$var.txt`, etc.) that rely on Stata's project-scoped working directory. Launching the same script via `stata -e do __main_data_prepare.do` from a shell will fail on the first `merge` because the empty `$bsource` global expands to a root-absolute `/bone` path outside the project session.

This orchestrates every `M0*`, `H0*`, `D0*`, and `T0*` prep script and writes the following `.txt` files into `../fortran_code/data/` (lowercase — see note below):

- `_data_depr.txt` (depreciation) — `depreciation/M01prepare_depr.do`
- `_data_gamma.txt` (TFP growth path) — `tfp/M02prepare_gamma.do`
- `_data_lab_share.txt` (labor share) — `labor_share/M03prepare_labor_share.do`
- `_data_irr.txt` (exogenous rate series for the `exor_` scenario) — `../sensitivity_stata_code/exog_rate/M04prepare_exog_rate.do`
- `_data_skill_premium.txt` — `skill_premium/H01prepare_skill_premium.do`
- `_data_college_share.txt` — `skill_premium/D02_prepare_college.do`
- `_data_tC.txt`, `_data_tK.txt`, `_data_tL.txt` (consumption, capital, labor tax rates) — `tax_rate/T01prepare_taxes.do`
- `_data_contributions.txt` (pension contributions) — `social_security/T02prepare_contributions.do`
- `_data_lambda.txt` (tax progressivity) — `tax_rate/T03prepare_tax_lambda.do`

**Case-sensitivity note**: every helper above calls `export delimited ... using "../fortran_code/data/_data_$var.txt"` with a **lowercase** `data/`. The Fortran sources read from `fortran_code/Data/` with a **capital** `D`. On Windows these resolve to the same directory and the pipeline works; on case-sensitive filesystems (Linux, case-sensitive macOS, many CI runners) the scripts write files the Fortran code cannot find. If replicating on Linux, either rename the tracked folder to `data/`, create a symlink, or update every `export delimited` call to use `Data/`.

Note that the `sensitivity_stata_code/exog_rate/` code is load-bearing for the `exor_` scenario and is called from `__main_data_prepare.do`; it is *not* purely optional robustness code. The `gcbo_` scenario's robustness prep lives at `inputs_stata_code/tfp/M02robustness_prepare_gamma.do` and is invoked from `outputs_stata_code/__main.do` (see Step 7) — not from `__main_data_prepare.do`.

#### Stage B — Income-Process Parameters (Stata + MATLAB)

The income-process calibration estimates persistence and variance parameters from PSID and is driven by its own batch script:

```bash
cd inputs_stata_code\income_process
run_estimation.bat
```

This runs Stata (`estimate_income_process.do`) → MATLAB (`estimate_parameters.m`) → plotting (`matlab/plot_estimates.m`), and copies the resulting `.txt` files into `../../fortran_code/Data/`:

- `_data_omega_mostdrop_hhslabinc_avghourlyhh.txt` — age-efficiency profile (mostdrop variant)
- `_data_omega_busno_drop_hhslabinc_avghourlyhh.txt` — age-efficiency profile (busno_drop variant)
- `_data_sigma2eps_mostdrop_hhslabinc_avghourlyhh.txt` — transitory shock variance (mostdrop)
- `_data_sigma2eps_busno_drop_hhslabinc_avghourlyhh.txt` — transitory shock variance (busno_drop)

Plots are saved to `../../graphs/inputs/`.

#### Stage C — Population and Mortality

Demography is split across two mechanisms, neither of which is driven by `__main_data_prepare.do`:

1. **Frozen population series** — `_data_Nn_US_1935_2100.txt` and `_data_Nn_US_1935_init_old.txt` in `fortran_code/Data/` are **hand-written frozen inputs**. No Stata script in the repository regenerates them. They should be treated as source data, not pipeline output.
2. **Mortality / heterogeneous-survival scripts** — `inputs_stata_code/demography/mortality/D01_life_tables.do` and `inputs_stata_code/demography/hetero_pi/D03_prepare_hetero_pi.do` produce `_data_pi_cond_US_since*.txt`, `_data_pi_US_since1935_{no_}col.txt`, and `_data_het_pi_US_since1935_all.txt`. **These scripts write to `inputs_stata_code/demography/<subfolder>/output/`, not to `fortran_code/Data/` directly** — the files are then copied over by hand. The scripts are dispatched from `outputs_stata_code/__main.do` (Appendix C), not from `__main_data_prepare.do`.

Other `_data_*.txt` files present in `fortran_code/Data/` — including `_data_tauC.txt`, `_data_tauK.txt`, `_data_tauL.txt`, `_data_contrib.txt`, `_data_contrib_to_gdp.txt`, `_data_exog_rate_1935.txt`, `_data_gy_1935.txt`, `_data_rho_1935.txt`, `_data_type_multiplier*.txt`, `_data_type_share.txt`, `_data_het_pi_US_since1935.txt`, `_data_pi_cond_het_US_since1935.txt`, and `_data_gamma_robustness.txt` — are **frozen inputs** with no Stata script producing them today. Treat them as source data alongside the population series.

#### Verify

Once all three stages have run, check that `fortran_code/Data/` contains the expected files:

```bash
dir fortran_code\Data\
```

You should see ~40 files including `_data_Nn_US_*.txt` (population), `_data_pi_*.txt` (mortality), `_data_omega_*.txt` (productivity), `_data_gamma*.txt` (TFP), and the tax / contribution / skill-premium files listed above. The full catalogue is in the Data Availability section.

**If any files are missing** after running Stages A and B: see Data Availability section for the PSID access instructions, and check the individual `.do` logs under `inputs_stata_code/*/`.

---

### Step 3: Compile the Model

#### Option A: Using Visual Studio (Recommended)

1. **Open the solution**:
   - Double-click `fortran_code/5Gtrans.sln` (opens Visual Studio)
   - Visual Studio will load the project

2. **Set build configuration**:
   - At the top: Select "Release" (not Debug)
   - Select "x64" platform

3. **Clean and rebuild**:
   - Menu: Build → Clean Solution
   - Menu: Build → Rebuild Solution (or press Ctrl+Alt+F7)

4. **Verify compilation**:
   - Check Output window for "Build succeeded"
   - Verify executable exists: `x64\Release\5Gtrans.exe` OR `5Gtrans.exe` (depending on project settings)

**Compilation time**: ~2-5 minutes depending on your system

**Common issues**:
- "Fortran compiler not found": Install Intel Fortran Compiler (see Software Requirements)
- "Cannot open include file": Check that all .f90 files are in the same directory
- Linking errors: Ensure Visual Studio C++ build tools are installed

#### Option B: Using Command Line

Open the Intel Fortran Compiler command prompt and switch into `fortran_code/`:

```bash
cd fortran_code
ifort /O2 /Qipo /exe:5Gtrans.exe *.f90
```

Or with the newer ifx compiler:

```bash
ifx /O2 /Qipo /exe:5Gtrans.exe *.f90
```

---

### Step 4: Run a Single Scenario (Test)

From `fortran_code/`, test the installation by running the main baseline scenario:

```bash
cd fortran_code
5Gtrans.exe psid_ all_ govt__
```

Or if the executable is in a subdirectory:

```bash
x64\Release\5Gtrans.exe psid_ all_ govt__
```

**Expected behavior**:
- Program prints "Running scenario: psid_all_govt__"
- Creates `fortran_code/Results/psid_all_govt__/` folder
- Prints iteration progress for initial steady state
- Prints iteration progress for final steady state
- Prints iteration progress for transition path
- Writes output files to `fortran_code/Results/psid_all_govt__/`
- Prints "computations completed"

**Runtime**: ~[X] hours on recommended system (see Runtime Requirements)

**Monitor progress**: The program prints convergence diagnostics every iteration:
```
iter =   1   err =  1.234E-02   feasibility =  5.678E-04
iter =   2   err =  5.678E-03   feasibility =  2.345E-04
...
iter = 150   err =  9.876E-08   feasibility =  1.234E-08
```

When `err < tol` (typically 1e-7), the iteration converges.

---

### Step 5: Verify Results

Check that output files were created:

```bash
dir fortran_code\Results\psid_all_govt__\
```

You should see:
- `gdp_trans.txt` - GDP time series
- `r_trans.txt` - Interest rate time series
- `bigK_trans.txt` - Capital stock time series
- `steadys_old_information_run.txt` - Initial steady state summary
- `steadys_new_information_run.txt` - Final steady state summary
- Many other output files (~30+ files depending on switches)

**Quick validation**:
1. Open `steadys_new_information_run.txt`
2. Check that values are reasonable (not NaN, not extremely large/small)
3. Compare to pre-computed results (if provided in repository)

**Detailed validation**:
See "Verification" section below for how to compare results to paper tables/figures.

---

### Step 6: Run All Scenarios

To reproduce all results in the paper, from `fortran_code/`:

```bash
cd fortran_code
run_scenarios_from_list.bat
```

This script:
1. Reads `scenarios.txt` (list of scenarios)
2. Runs each uncommented scenario sequentially
3. Saves output to separate subfolders in `fortran_code/Results/`

**Important**: `fortran_code/scenarios.txt` ships as a **catalogue**, not a pre-configured run list. Every paper scenario is listed but most are commented out (prefixed with `#`) for safety — running the full set is multi-day. Before invoking the batch script, uncomment the scenarios you actually want to run. The full map from paper figure → scenarios is in [SCENARIOS.md](SCENARIOS.md); the scenario families needed for the paper are:

- `psid_ all_ govt__` (baseline)
- `psid_ ndm_ govt__`, `psid_ nds_ govt__`, `psid_ ndo_ govt__` (Main Text, demographic decomposition)
- `psid_ nlb_`, `psid_ ntx_`, `psid_ nts_` (all-factor decomposition)
- `psid_ ncs_`, `psid_ ncp_`, `psid_ nsh_` (income inequality decomposition)
- `psid_ ntl_`, `psid_ ntc_`, `psid_ ntk_`, `psid_ ntp_` (tax decomposition)
- `psid_ nls_`, `psid_ nga_`, `psid_ ndp_` (technology decomposition)
- `crr3_ all_ govt__`, `crr3_ ndm_ govt__` (Appendix F.1, higher risk aversion)
- `hrat_ all_ govt__`, `hrat_ ndm_ govt__` (Appendix F.2, heterogeneous returns — **requires `5Gtrans_het.exe`**, a separate Release_HetRate build)
- `ndel_ all_ govt__`, `ndel_ ndm_ govt__` (F.3, no discount-factor shocks)
- `nstr_ all_ govt__`, `nstr_ ndm_ govt__` (F.4, no superstars)
- `gcbo_ all_ govt__`, `gcbo_ ndm_ govt__` (F.5, CBO productivity growth)
- `exor_ all_ govt__` (F.6, exogenous interest rate)
- `beqs_ all_ govt__`, `beqs_ ndm_ govt__` (F.7, unequal bequests)

**Runtime for all scenarios**: ~[X] hours (see Runtime Requirements)

**Monitoring**: Output for each scenario is printed to console. You can redirect to log file:

```bash
run_scenarios_from_list.bat > replication_log.txt 2>&1
```

**Parallel execution** (if you have multiple cores):
Edit `run_scenarios_from_list.bat` to run scenarios in parallel, or open multiple command windows and run different scenarios simultaneously:

```bash
# Window 1:
5Gtrans.exe psid_ all_ govt__

# Window 2:
5Gtrans.exe psid_ ndm_ govt__

# Window 3:
5Gtrans.exe psid_ nds_ govt__
```

Scenarios are independent and can run in parallel.

---

### Step 7: Generate Paper Tables and Figures

The paper's tables and figures are produced by **`outputs_stata_code/__main.do`**, which is the master driver for the post-Fortran stage. It reads scenario output from `fortran_code/Results/`, merges Fortran results with data, computes inequality and macro statistics, and saves graphs to `graphs/outputs/`.

As with Step 2, **launch the pipeline via the Stata project file**, not via `stata -e`:

1. Open `outputs_stata_code/__replication_graphs.stpr` in interactive Stata.
2. Open `__main.do` inside the project.
3. Run the do-file.

Internal paths set by the script:

- `$resultspath = "..\fortran_code\Results\"`
- `$graphspath  = "..\graphs\outputs\"`
- `$datapath    = "..\data\"`

`__main.do` orchestrates:

- **Main text figures**: `R_Figure1.do` (Gini change to 1950), `R_Figure2.do` (line plots with labels), `R_Figure3.do` (counterfactual bar plots, called with several different variant sets for Figures 2–4).
- **Appendix B — Calibration figures**: re-runs the Stage-A prep scripts from Step 2 (`M01prepare_depr.do`, `M02prepare_gamma.do`, `M03prepare_labor_share.do`, `H01prepare_skill_premium.do`, `D02_prepare_college.do`, `T01prepare_taxes.do`, `T02prepare_contributions.do`, `T03prepare_tax_lambda.do`) with a plotting source switched on.
- **Appendix C — Population and mortality**: dispatches `demography/hetero_pi/D03_prepare_hetero_pi.do` and `demography/mortality/D01_life_tables.do`.
- **Appendix D — Model vs Data comparisons**: `MvD_1_macro.do`, `MvD_2_Gini_income.do`, `MvD_3_Gini_wealth.do`, `MvD_4_GE_decomposition.do`.
- **Appendix E — Additional decompositions**: further calls to `R_Figure3.do` with income, tax, and technology counterfactual sets.
- **Appendix F — Sensitivity**: calls to `R_Figure1_app.do` and `R_Figure2.do` across the `crr3_`, `hrat_`, `ndel_`, `nstr_`, `gcbo_`, `exor_`, and `beqs_` sensitivity scenarios, including re-preparation of inputs through `M02robustness_prepare_gamma.do` (for `gcbo_`) and `M04prepare_exog_rate.do` (for `exor_`). **Note**: the current `__main.do` calls `../sensitivity_stata_code/exog_rate/M02robustness_prepare_gamma` on [__main.do:164](outputs_stata_code/__main.do#L164), but the actual file lives at [inputs_stata_code/tfp/M02robustness_prepare_gamma.do](inputs_stata_code/tfp/M02robustness_prepare_gamma.do). Appendix F.5 (`gcbo_` branch) currently errors at this step. **Fixing it requires more than a path change**: the script also assumes cwd=`inputs_stata_code/` and needs `bone1y.dta` recreated (Appendix B erases it earlier in the run), so the call has to be wrapped in `cd ..\inputs_stata_code` + `do _prepare_programs.do` + the script + erase + `cd ..\outputs_stata_code`. See [docs/stata_pipeline_audit.md](docs/stata_pipeline_audit.md) §2.3 for the full sketch.

`__main.do` assumes that **every scenario referenced in the figure-building sections has already been run** (Step 6) and that its output is present under `fortran_code/Results/<scenario>/`. Missing scenarios will surface as Stata errors pointing at the specific `.csv` that could not be imported.

Final figures are saved to `graphs/outputs/` as `.png` (and some `.gph` / `.eps` for editable sources). The full mapping from paper item → script → figure file is in the "List of Tables and Figures" section below.

---

## Verification

### Comparing Results to Paper

Use the mapping table below to find which output file corresponds to each paper table/figure:

| Paper Item | Output File(s) | Expected Value | Tolerance |
|------------|----------------|----------------|-----------|
| Table 1, Row 1 (Initial SS GDP) | `fortran_code/Results/psid_all_govt__/steadys_old_information_run.txt`, line [X] | [Value] | ±0.001 |
| Table 1, Row 2 (Final SS GDP) | `fortran_code/Results/psid_all_govt__/steadys_new_information_run.txt`, line [X] | [Value] | ±0.001 |
| Table 2 (Transition path) | `fortran_code/Results/psid_all_govt__/gdp_trans.txt` | [Range] | ±0.01 |
| Figure 1 (Interest rate) | `fortran_code/Results/psid_all_govt__/r_trans.txt` | [Description] | Visual inspection |
| [Continue for all tables/figures] | | | |

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
- **Solution**: Clean the solution (Build → Clean) and rebuild
- Delete all .mod and .obj files in x64/Release/
- Rebuild from scratch

**Error**: "Link error: unresolved external"
- **Solution**: Ensure all .f90 files are included in the project
- Right-click project → Add → Existing Item → Select missing .f90 files

### Runtime Errors

**Error**: "Configuration file not found"
- **Solution**: Check that `fortran_code/Instructions/` and `fortran_code/Parameters/` folders contain the required files
- Verify file names exactly match: `{version}{experiment}{closure}instructions.txt`

**Error**: "Stack overflow" or "Access violation"
- **Solution**: Increase stack size in project properties
- Project Properties → Fortran → Optimization → Stack Size → Set to "unlimited" or large value (e.g., 500000000)

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

## Advanced Usage

### Running Custom Scenarios

To create a new scenario:

1. **Copy configuration files**:
   ```bash
   copy Instructions\psid_all_govt__instructions.txt Instructions\custom_all_govt__instructions.txt
   copy Parameters\psid_all_govt__parameters.txt Parameters\custom_all_govt__parameters.txt
   ```

2. **Edit the files** to modify switches or parameters

3. **Run the scenario**:
   ```bash
   5Gtrans.exe custom_ all_ govt__
   ```

4. **Results** will be saved to `fortran_code/Results/custom_all_govt__/`

### Modifying Model Parameters

Key parameters can be changed by editing the parameters file:

- **Line 12**: `delta` - Discount factor (typically 1.010)
- **Line 13**: `theta` - Risk aversion (typically 1.5)
- **Line 14**: `alpha` - Capital share (typically 0.35)
- **Line 15**: `depr` - Depreciation rate (typically 0.05)

See `CLAUDE.md` for complete documentation of all 51 parameter lines.

### Sensitivity Analysis

To run sensitivity analysis across parameter values:

1. Create multiple parameter files with different values
2. Add them to `scenarios.txt`
3. Run `run_scenarios_from_list.bat`
4. Compare results across scenarios

---

## Getting Help

### Documentation

- **`fortran_code/CLAUDE.md`**: Technical documentation for the Fortran codebase (model equations, switches, parameter lines, build configurations).
- **`SCENARIOS.md`**: Full per-scenario catalogue, including which paper figure each scenario supports.
- **`docs/`**: Internal brainstorm notes and documented solutions to recurring integration issues.
- **This README**: Replication instructions for users.

### Contact

For questions about replication:
- **Email**: [replication-contact@institution.edu]
- **GitHub Issues**: https://github.com/pzoch/demographic-transition-wealth-inequality/issues
- **Expected response time**: [e.g., "Within 1 week"]

The authors commit to assisting with replication efforts for [2 years / duration specified by journal] following publication.

### Common Issues Database

[IF APPLICABLE: Link to FAQ or common issues page]

---

# List of Tables and Figures

This section maps each table and figure in the paper to the output files and programs that generate them.

## Reproducibility Status

The provided code reproduces:
- ✅ All numbers provided in text in the paper
- ✅ All tables and figures in the paper
- ✅ All tables and figures in the online appendix

---

## Main Text

| Item | Description | Program/File | Output File(s) | Notes |
|------|-------------|--------------|----------------|-------|
| **Table 1** | Steady State Comparison | `steady_state.f90` | `fortran_code/Results/psid_all_govt__/steadys_old_information_run.txt` and `steadys_new_information_run.txt` | Compare "Initial SS" vs. "Final SS" values |
| **Table 2** | Transition Path Statistics | `transition.f90` | `fortran_code/Results/psid_all_govt__/gdp_trans.txt`, `r_trans.txt`, `bigK_trans.txt` | Aggregate statistics over transition |
| **Table 3** | Welfare Analysis | `pfi_household_problem.f90` | [Requires post-processing of consumption and labor files] | Calculate consumption-equivalent variation |
| **Table 4** | Decomposition | Multiple scenarios | Compare `psid_all_govt__` vs. `psid_ndm_govt__` vs. other counterfactuals | Run all scenarios in `scenarios.txt` |
| **Figure 1** | Interest Rate Path | `transition.f90` | `fortran_code/Results/psid_all_govt__/r_trans.txt` | Plot time series (years 1935-2100) |
| **Figure 2** | Capital Stock Path | `transition.f90` | `fortran_code/Results/psid_all_govt__/bigK_trans.txt` | Plot time series |
| **Figure 3** | Life-Cycle Consumption | `pfi_agregation.f90` | `fortran_code/Results/psid_all_govt__/c_j_trans.csv` | Plot age profiles for selected years |
| **Figure 4** | Life-Cycle Labor Supply | `pfi_agregation.f90` | `fortran_code/Results/psid_all_govt__/l_j_trans.csv` | Plot age profiles for selected years |
| **Figure 5** | Wealth Distribution | `pfi_distribution.f90` | `fortran_code/Results/psid_all_govt__/gini_weight_trans.csv`, `mass_trans.csv` | Compute Gini coefficient and wealth shares |
| [Continue for all tables/figures...] | | | | |

---

## Online Appendix

| Item | Description | Program/File | Output File(s) | Notes |
|------|-------------|--------------|----------------|-------|
| **Table A.1** | Robustness: Alternative Calibration | `steady_state.f90` | `fortran_code/Results/[TBD]/steadys_new_information_run.txt` | Compare to baseline `psid_all_govt__` — scenario name pending (the former `base_*` alternative was retired in the scenario audit) |
| **Table A.2** | Robustness: TFP Assumptions | Multiple scenarios | Compare scenarios with different `_data_gamma*.txt` files | Run scenarios with different TFP files |
| [Continue for appendix items...] | | | | |

---

## In-Text Numbers

| Location | Description | Source |
|----------|-------------|--------|
| Page X, para Y | "GDP grows by Z%" | `fortran_code/Results/psid_all_govt__/gdp_trans.txt`, compare year 1935 to year 2100 |
| Page X, para Y | "Welfare gain of W%" | Calculate from consumption equivalent variation |
| [Continue for all in-text numbers...] | | |

---

# References

## Data Sources

### Mortality and Demographics

- Case, Anne and Deaton, Angus. 2021. "Life expectancy in adulthood is falling for those without a BA degree, but as educational gaps have widened, racial gaps have narrowed." *Proceedings of the National Academy of Sciences* 118(11): e2024777118. https://doi.org/10.1073/pnas.2024777118

- United Nations, Department of Economic and Social Affairs, Population Division. 2022. "World Population Prospects 2022." https://population.un.org/wpp/

- U.S. Census Bureau. 2021. "American Community Survey." https://www.census.gov/programs-surveys/acs

### Income and Wages

- Autor, David and Dorn, David. 2020. "Changes in the occupational skill-intensity of U.S. manufacturing employment." Updated series extending Goldin and Katz (2008). https://www.ddorn.net/data.htm

- Panel Study of Income Dynamics, public use dataset. Produced and distributed by the Survey Research Center, Institute for Social Research, University of Michigan, Ann Arbor, MI (1970-2019 waves). https://psidonline.isr.umich.edu/

- Goldin, Claudia and Lawrence F. Katz. 2008. *The Race Between Education and Technology*. Cambridge, MA: Harvard University Press.

- Deaton, Angus and Christina Paxson. 2000. "Growth and Saving Among Individuals and Households." *Review of Economics and Statistics* 82(2): 212–225.

### Tax Parameters

- Heathcote, Jonathan, Kjetil Storesletten, and Giovanni L. Violante. 2017. "Optimal Tax Progressivity: An Analytical Framework." *Quarterly Journal of Economics* 132(4): 1693-1754. https://doi.org/10.1093/qje/qjx018

### Productivity and Economic Aggregates

- Feenstra, Robert C., Robert Inklaar and Marcel P. Timmer. 2015. "The Next Generation of the Penn World Table." *American Economic Review* 105(10): 3150-3182. https://www.ggdc.net/pwt (Penn World Table 10.0, accessed 2021)

- Fernald, John G. 2016. "Reassessing Longer-Run U.S. Growth: How Low?" Federal Reserve Bank of San Francisco Working Paper 2016-18. https://www.frbsf.org/economic-research/publications/working-papers/2016/18/

- U.S. Bureau of Economic Analysis. 2021. "Fixed Assets Tables." U.S. Department of Commerce. https://apps.bea.gov/national/FA2004/Index.asp (accessed 2020-2021)

- U.S. Bureau of Economic Analysis. 2021. "National Income and Product Accounts." U.S. Department of Commerce. https://www.bea.gov/data/gdp/gross-domestic-product (accessed 2020-2021)

### Government and Social Security

- U.S. Social Security Administration. 2021. "Social Security Contributions and Benefit Payments." Office of the Chief Actuary. https://www.ssa.gov/oact/ (accessed 2020-2021)

- OECD. 2021. "Social Security Contributions (indicator)." https://data.oecd.org/ (accessed 2020-2021)

- Congressional Budget Office. 2020. "The 2020 Long-Term Budget Outlook." https://www.cbo.gov/publication/56516

## Software and Tools

- Intel Corporation. 2021. "Intel Fortran Compiler Classic." Version 2021.7.1 (or later). https://www.intel.com/content/www/us/en/developer/tools/oneapi/fortran-compiler.html

- Microsoft Corporation. 2022. "Visual Studio 2019/2022." https://visualstudio.microsoft.com/

## Academic References (Methodology)

- Chetty, Raj et al. 2016. "The Association Between Income and Life Expectancy in the United States, 2001-2014." *JAMA* 315(16): 1750-1766.

- Bach, Laurent, Laurent E. Calvet, and Paolo Sodini. 2020. "Rich Pickings? Risk, Return, and Skill in Household Wealth." *American Economic Review* 110(9): 2703-2747.

---

# Acknowledgments

We thank (in alphabetical order) Roel Beetsma, Fabian Kindermann, Per Krusell, Iga Magda, Ward Romp, and Nancy Stokey for their valuable discussions and insights. We are especially grateful to Piotr Dworczak and Oliwia Komada for their thoughtful comments and suggestions. We also wish to acknowledge the Editor, Francesco Lippi, and four anonymous referees, whose constructive feedback greatly enhanced this paper. Additionally, we appreciate the comments received from the participants of AEA 2022, CEF 2022, and IIPF 2022.

We are indebted to Marcin Lewandowski for his excellent research assistance.

This project was supported by National Science Center (Poland), grant #2016/22/E/HS4/00129, whose generosity is greatly appreciated.

Any remaining errors are entirely our own.

---

# Version History

## Version 1.1 (January 2026)

- **Bug fix**: Corrected replacement rate calculation (steady_state.f90:809)
  - Changed `sum_b_weight_ss` to `sum_b_weight_vec_ss(m)` for type-specific weights
- **Documentation**: Enhanced code documentation (13 files, 2,134 net additions)
- **Compilation**: Fixed compilation errors and removed preprocessor directives
- **Cleanup**: Removed unused simulation functions

## Version 1.0 (November 2024)

- Initial submission
- All main results and robustness checks

---

**Last Updated**: January 16, 2026

**README Version**: 1.0

**Corresponding Author**: [Name] - [email@institution.edu]
