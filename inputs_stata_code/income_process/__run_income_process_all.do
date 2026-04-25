* Full income-process pipeline launcher for interactive Stata users.
* This keeps the .stpr workflow Stata-native while delegating estimation/plots to MATLAB.

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

do "$IP_INCOME_DIR/__run_psid_income_inputs.do"

capture confirm file "../inputs_matlab_code/income_process/run_income_process_matlab.bat"
if !_rc {
    shell cmd /c "..\inputs_matlab_code\income_process\run_income_process_matlab.bat"
}
else {
    shell cmd /c "..\..\inputs_matlab_code\income_process\run_income_process_matlab.bat"
}
