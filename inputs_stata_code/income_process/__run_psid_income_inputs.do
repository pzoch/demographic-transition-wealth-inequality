* Run the Stata side of the PSID income-process pipeline.
* Produces cleaned variant samples, psid_ready.dta, omega txt files, and covariance txt files for MATLAB.
* Deaton/omega and sigma2epsilon plots are scripted outside this input-prep driver; see
* outputs_stata_code/income_process/plot_omega.do and outputs_matlab_code/income_process/plot_estimates.m.

clear all
set more off

capture confirm file "income_process/00_config.do"
if !_rc {
    do "income_process/00_config.do"
}
else {
    capture confirm file "00_config.do"
    if !_rc {
        do "00_config.do"
    }
    else {
        do "inputs_stata_code/income_process/00_config.do"
    }
}

do "$IP_INCOME_DIR/01_prepare_common_sample.do"
do "$IP_INCOME_DIR/02_make_variant_samples.do"
do "$IP_INCOME_DIR/03_export_omega_covariances.do"

display as text ""
display as text "=== Stata PSID income-process inputs complete ==="
display as text "Next: run inputs_matlab_code/income_process/run_income_process_matlab.bat"
