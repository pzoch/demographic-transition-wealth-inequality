# Scenario Reference

This document maps the computational scenario codes used in the replication package to the counterfactual experiments described in the paper *"Demographic transition and the rise of wealth inequality"* by Makarski, Tyrowicz, and Żoch.

## Naming Convention

Each scenario is identified by three components:

```
{version}_{experiment}_{closure}
```

- **Version** (`xxxx_`): Model calibration or robustness


 variant
- **Experiment** (`yyy_`): Which factors are held fixed at 1955 levels
- **Closure** (`govt__`): Fiscal closure rule (always `govt__`)

Example: `psid_ndm_govt__` = PSID calibration, no demographic changes, government closure.

## How to Run

**Standard model** (Release|x64 &rarr; `5Gtrans.exe`):
```
x64\Release\5Gtrans.exe psid_ all_ govt__
```

**Heterogeneous-rate model** (Release_HetRate|x64 &rarr; `5Gtrans_het.exe`):
```
x64\Release_HetRate\5Gtrans_het.exe hrat_ all_ govt__
```

**Batch scripts:**
- `run_scenarios_from_list.bat` &mdash; runs scenarios listed in `scenarios.txt`
- `run_scenarios_het.bat` &mdash; runs `hrat_all_govt__` and `hrat_ndm_govt__`

Each scenario requires matching files in `Instructions/` and `Parameters/`.

---

## Baseline Scenario

| Code | Description |
|------|-------------|
| `psid_all_govt__` | **Baseline.** All observed changes active (demographics, income, taxes, technology). PSID-calibrated income process. Produces the black line in all main figures. |

---

## Main Counterfactual Experiments

All counterfactuals use the `psid_` version. Each holds specific factors at their 1955 levels while everything else evolves as in the baseline. The difference in the wealth Gini between baseline and counterfactual measures the contribution of the held-fixed factor.

### [S1] Demographics (Rising Longevity)

| Code | Paper Label | What Is Held Fixed |
|------|-------------|-------------------|
| `psid_ndm_govt__` | [S1] Longevity:1955 | Mortality rates fixed at 1955 levels in both the population structure and the consumer problem (`switch_mortality=6`). Isolates the total effect of rising longevity. |
| `psid_nds_govt__` | [S1a] ExpectedLongevity:1955 | Mortality rates fixed at 1955 levels only in the consumer problem (`switch_mortality=5`). Agents do not respond to rising longevity, but actual population structure evolves as in data. Isolates the behavioral effect. |
| `psid_ndo_govt__` | [S1b] PopStructure:1955 | Population structure (weights) fixed at 1955 levels (`switch_mortality=8`), but agents perceive actual survival probabilities from data. Isolates the composition effect. |

**Figures:** Main text Figure 1 (levels), Figure 2 (lines for [S1]), Figure 3 (bars for [S1], [S1a], [S1b]), Figure 4 (bars for [S1] vs [S2], [S3], [S4]).

### [S2] Income Inequality

| Code | Paper Label | What Is Held Fixed |
|------|-------------|-------------------|
| `psid_nlb_govt__` | [S2] IncomeINEQ:1955 | College share, college premium, and idiosyncratic income shock variance all fixed at 1955 levels. |
| `psid_ncs_govt__` | [S2a] CollegeShare:1955 | Share of college graduates fixed at 1955 level. |
| `psid_ncp_govt__` | [S2b] CollegePremium:1955 | College wage premium fixed at 1955 level. |
| `psid_nsh_govt__` | [S2c] Shocks:Initial | Idiosyncratic income shock parameters fixed at initial cohort levels (entering labor market ~1955). |

**Figure:** Online Appendix Figure (Income decomposition bars).

### [S3] Taxes

| Code | Paper Label | What Is Held Fixed |
|------|-------------|-------------------|
| `psid_ntx_govt__` | [S3] Taxes:1955 | All tax rates (labor, capital, consumption, progressivity) fixed at 1955 levels. |
| `psid_ntl_govt__` | [S3a] &tau;<sub>L</sub>:1955 | Average labor income tax rate only. |
| `psid_ntc_govt__` | [S3b] &tau;<sub>C</sub>:1955 | Consumption tax rate only. |
| `psid_ntk_govt__` | [S3c] &tau;<sub>K</sub>:1955 | Capital income tax rate only. |
| `psid_ntp_govt__` | [S3d] Progression:1955 | Labor income tax progressivity (&lambda;) only. |

**Figure:** Online Appendix Figure (Tax decomposition bars).

### [S4] Technology

| Code | Paper Label | What Is Held Fixed |
|------|-------------|-------------------|
| `psid_nts_govt__` | [S4] Technology:1955 | TFP growth rate, depreciation rate, and labor share all fixed at 1955 levels. Switches off: `gamma`, `sl`, `depr`. |
| `psid_nls_govt__` | [S4a] LabShare:1955 | Labor share fixed at 1955 level. Switches off: `sl`. |
| `psid_nga_govt__` | [S4b] TFP:1955 | TFP growth rate (gamma convergence) fixed at 1955 level. Switches off: `gamma`. |
| `psid_ndp_govt__` | [S4c] Depr:1955 | Depreciation rate fixed at 1955 level. Switches off: `depr`. |

**Figure:** Online Appendix Figure (Technology decomposition bars).

### Other PSID Counterfactuals

(No additional PSID counterfactuals beyond the scenarios listed above.)

---

## Sensitivity / Robustness Versions

Each robustness version modifies the model specification or calibration. For each version, two scenarios are run: `{version}_all_govt__` (baseline with all changes) and `{version}_ndm_govt__` (counterfactual with fixed longevity). The difference between them measures the contribution of demographics under the alternative model.

| Version | Paper section (figure) | Description | Executable |
|---------|--------------|-------------|------------|
| `crr3_` | §F.1 (Fig. F.1) | Higher risk aversion (&theta;=3 instead of 1.5). | `5Gtrans.exe` |
| `hrat_` | §F.2 (Fig. F.2) | Persistently heterogeneous rates of return by education level. College-educated households earn 62 bp higher annual returns. | `5Gtrans_het.exe` |
| `ndel_` | §F.3 (Fig. F.3) | No discount factor shocks (&delta; constant for all households). | `5Gtrans.exe` |
| `nstr_` | §F.4 (Fig. F.4) | No "superstars" income state. Standard 5-state income process estimated including business owners. Uses `busno_drop` data files. | `5Gtrans.exe` |
| `gcbo_` | §F.5 (Figs. F.5, F.6) | Higher future TFP growth rate path (CBO 2025 projection). TFP rebounds to >1% annually instead of stabilizing at 0.6%. Section F.5 contains Figure F.5 (the alternative TFP path) and Figure F.6 (the Gini counterfactual). | `5Gtrans.exe` |
| `beqs_` | §F.6 (Fig. F.7) | Unequal bequest distribution. 70% receive nothing, 20% receive half, top 10% receive the other half. Bequests received at age 45-49. | `5Gtrans.exe` |

---

## Switch Mapping

The table below shows which instruction-file switches differ from the baseline (`psid_all_govt__`) for each experiment code. Only switches that change are listed; all others remain at their baseline values.

| Experiment | Switches Changed (relative to `all`) |
|------------|--------------------------------------|
| `ndm` | `switch_mortality`: 1&rarr;6 (fix mortality at 1955) |
| `ntl` | `switch_change_tauL`: 1&rarr;0 |
| `ntc` | `switch_change_tauC`: 1&rarr;0 |
| `ntk` | `switch_change_tauK`: 1&rarr;0 |
| `ntp` | `switch_change_lambda`: 1&rarr;0 |
| `ntx` | `switch_change_tauL`, `tauC`, `lambda`, `tauK`: all 1&rarr;0 |
| `ncp` | `switch_change_premium`: 1&rarr;0 |
| `ncs` | `switch_change_type_share`: 1&rarr;0 |
| `nlb` | `switch_sigma2_epsilon_t`, `switch_change_premium`, `switch_change_type_share`: all 1&rarr;0 |
| `nls` | `switch_change_sl`: 1&rarr;0 |
| `ndp` | `switch_change_depr`: 1&rarr;0 |
| `nsh` | `switch_sigma2_epsilon_t`: 1&rarr;0 |
| `nts` | `switch_go_to_lower_gamma`, `switch_change_sl`, `switch_change_depr`: all 1&rarr;0 |
| `nga` | `switch_go_to_lower_gamma`: 1&rarr;0 |
| `ndo` | `switch_mortality`: 1&rarr;8 (fix population structure at 1955, agents see actual survival &mdash; [S1b] PopStructure) |
| `nds` | `switch_mortality`: 1&rarr;5 (fix consumer-perceived survival at 1955, population evolves &mdash; [S1a] ExpectedLongevity) |

For robustness **versions**, the experiment switches are the same as `psid_`; the differences are in parameters or model-level switches:

| Version | Key Difference |
|---------|---------------|
| `crr3_` | &theta;=3.0 (in parameters file) |
| `hrat_` | `rate_adj` &ne; 0 (in parameters file); requires `5Gtrans_het.exe` |
| `ndel_` | `switch_discount_risk`: 2&rarr;0 |
| `nstr_` | `switch_drop_psid_superstars`: 0&rarr;1 (uses `busno_drop` data files) |
| `gcbo_` | `switch_go_to_lower_gamma`: 1&rarr;3 (loads `_data_gamma_robustness.txt` instead of `_data_gamma.txt`) |
| `beqs_` | `switch_unequal_bequest`: 0&rarr;2 |

---

## Figure-to-Scenario Mapping

| Figure | Scenarios Used |
|--------|---------------|
| Main Fig. 1: Model vs SCF data wealth Gini (bar+line) | `psid_all` + SCF data |
| Main Fig. 2: Baseline vs. constant longevity (lines) | `psid_all` vs. `psid_ndm` |
| Main Fig. 3: Longevity decomposition bars | `psid_all` vs. `psid_ndm` (S1), `psid_nds` (S1a), `psid_ndo` (S1b) |
| Main Fig. 4: All factors comparison bars | `psid_all` vs. `psid_ndm` (S1), `psid_nlb` (S2), `psid_ntx` (S3), `psid_nts` (S4) |
| App.: Income decomposition | `psid_all` vs. `psid_nlb` (S2), `psid_ncs` (S2a), `psid_ncp` (S2b), `psid_nsh` (S2c) |
| App.: Tax decomposition | `psid_all` vs. `psid_ntx` (S3), `psid_ntl` (S3a), `psid_ntc` (S3b), `psid_ntk` (S3c), `psid_ntp` (S3d) |
| App.: Technology decomposition | `psid_all` vs. `psid_nts` (S4), `psid_nls` (S4a), `psid_nga` (S4b), `psid_ndp` (S4c) |
| Figure F.1 (§F.1 &theta;=3) | `crr3_all` vs. `crr3_ndm` |
| Figure F.2 (§F.2 het. returns) | `hrat_all` vs. `hrat_ndm` |
| Figure F.3 (§F.3 no &delta; shocks) | `ndel_all` vs. `ndel_ndm` |
| Figure F.4 (§F.4 no superstars) | `nstr_all` vs. `nstr_ndm` |
| Figure F.5 (§F.5 alternative TFP path) | — (calibration plot from `M02robustness_prepare_gamma.do`, not a scenario run) |
| Figure F.6 (§F.5 higher TFP growth Gini) | `gcbo_all` vs. `gcbo_ndm` |
| Figure F.7 (§F.6 unequal bequests Gini) | `beqs_all` vs. `beqs_ndm` |
