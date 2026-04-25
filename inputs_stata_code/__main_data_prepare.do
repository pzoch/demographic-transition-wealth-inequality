set more off
set scheme burd    // match __main.do; produces clean-white calibration plots under graphs/inputs/

* set initial and final years
global year_start 1935
global year_stop 2100
global download_data 0		// 0 = load local .dta (default), 1 = re-download from dbnomics

cd "`c(pwd)'"
clear
do _prepare_programs.do					// this keeps routines that are repeated between dofiles



do external/copy_to_fortran.do    // external Fortran inputs - see external/README.md

*** PROCESS DATA - FORTRAN INPUTS;
* PWT inputs;
global bsource "."
do depreciation/M01prepare_depr
do tfp/M02prepare_gamma
do labor_share/M03prepare_labor_share

* skill premium and high/low shares;
do skill_premium/H01prepare_skill_premium 
*college share
do skill_premium/D02_prepare_college 

* taxes and contributions;
do tax_rate/T01prepare_taxes
do social_security/T02prepare_contributions
do tax_rate/T03prepare_tax_lambda

* demography (D01 first because D03 reads D01's pi_tot_new.dta)
do demography/mortality/D01_life_tables
do demography/hetero_pi/D03_prepare_hetero_pi

capture copy "demography/mortality/output/_data_pi_cond_US_since1935.txt" ///
    "../fortran_code/Data/_data_pi_cond_US_since1935.txt", replace


* PSID income-process inputs (optional; requires raw PSID extract).
capture confirm file "income_process/PSID/psid.dta"
if !_rc {
    do income_process/__run_psid_income_inputs.do
}
else {
    display as text "Raw PSID extract not found; keeping packaged PSID-derived Fortran inputs."
    display as text "To rebuild them, place psid.dta in income_process/PSID/ and rerun this driver."
}

capture erase bone.dta
capture erase bone1y.dta


