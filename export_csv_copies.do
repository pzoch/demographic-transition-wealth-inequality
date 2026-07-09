* export_csv_copies.do
* -----------------------------------------------------------------------------
* Writes a non-proprietary (csv) sibling next to every Stata .dta dataset
* shipped in this replication package, as requested in the EJ reproducibility
* report ("A copy of all datasets in non-proprietary format is included").
*
* Run from the repository root:
*   "C:\Program Files\Stata16\StataSE-64.exe" /e do export_csv_copies.do
*
* Notes:
* - Values are exported as stored (nolabel); variable and value labels remain
*   documented in the .dta files.
* - data/model_psid_all_govt__.dta is NOT exported: it is a regenerable
*   intermediate rebuilt from fortran_code/Results/ by outputs_stata_code/__main.do.
* -----------------------------------------------------------------------------
version 16
clear all
set more off

local dta_files ///
    "graphs/outputs/wealth_inequality/combined_gini.dta" ///
    "inputs_stata_code/bone.dta" ///
    "inputs_stata_code/bone1y.dta" ///
    "inputs_stata_code/demography/hetero_pi/data/New_data_on_mortality.dta" ///
    "inputs_stata_code/demography/hetero_pi/processed/hetero_pi.dta" ///
    "inputs_stata_code/demography/hetero_pi/processed/pi_col_merge_M.dta" ///
    "inputs_stata_code/demography/mortality/processed/mortality_part_00.dta" ///
    "inputs_stata_code/demography/mortality/processed/mortality_part_11.dta" ///
    "inputs_stata_code/demography/mortality/processed/mortality_part_22.dta" ///
    "inputs_stata_code/demography/mortality/processed/pi_tot_new.dta" ///
    "inputs_stata_code/depreciation/depreciation.dta" ///
    "inputs_stata_code/exog_rate/irr.dta" ///
    "inputs_stata_code/labor_share/labor_share.dta" ///
    "inputs_stata_code/skill_premium/ACS_college/processed/col_share_acs.dta" ///
    "inputs_stata_code/skill_premium/ACS_college/processed/col_share_acs_ext.dta" ///
    "inputs_stata_code/skill_premium/AutorGoldinKatz2020/figure1/prem_1820_2012.dta" ///
    "inputs_stata_code/skill_premium/AutorGoldinKatz2020/figure1/wprem2_17.dta" ///
    "inputs_stata_code/skill_premium/AutorGoldinKatz2020/tables_A1_A2_figure_A1/clghsgwg-march-regseries-exp.dta" ///
    "inputs_stata_code/skill_premium/AutorGoldinKatz2020/tables_A1_A2_figure_A1/colhs1405.dta" ///
    "inputs_stata_code/skill_premium/AutorGoldinKatz2020/tables_A1_A2_figure_A1/colhs1417_new.dta" ///
    "inputs_stata_code/skill_premium/AutorGoldinKatz2020/tables_A1_A2_figure_A1/effunits-exp-byexp-6318.dta" ///
    "inputs_stata_code/skill_premium/AutorGoldinKatz2020/tables_A1_A2_figure_A1/km-cg-rsup-6317.dta" ///
    "inputs_stata_code/skill_premium/AutorGoldinKatz2020/tables_A1_A2_figure_A1/km-plot-6317.dta" ///
    "inputs_stata_code/skill_premium/AutorGoldinKatz2020/tables_A1_A2_figure_A1/wprem2_17.dta" ///
    "inputs_stata_code/social_security/contributions.dta" ///
    "inputs_stata_code/tfp/gamma.dta" ///
    "outputs_stata_code/data/avghours_data.dta" ///
    "outputs_stata_code/data/benefits_cbo.dta" ///
    "outputs_stata_code/data/irr_data.dta" ///
    "data/PSID/psid_ready.dta" ///
    "data/PSID/ageeffects_busno_drop_hhslabinc_avghourlyhh.dta" ///
    "data/PSID/ageeffects_mostdrop_hhslabinc_avghourlyhh.dta" ///
    "data/SCF/SCF_plus.dta"

local n_ok 0
local n_missing 0
foreach f of local dta_files {
    capture confirm file "`f'"
    if _rc {
        display as error "MISSING (skipped): `f'"
        local ++n_missing
        continue
    }
    use "`f'", clear
    local csv : subinstr local f ".dta" ".csv"
    export delimited using "`csv'", replace nolabel
    display as text "wrote `csv'"
    local ++n_ok
}

display as result "export_csv_copies: `n_ok' csv files written, `n_missing' inputs missing."
