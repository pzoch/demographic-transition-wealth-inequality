* Income-process path and run configuration.
* Supports running from repo root, inputs_stata_code, or inputs_stata_code/income_process.

capture confirm file "income_process/PSID/psid.dta"
if !_rc {
    global IP_INCOME_DIR "income_process"
    global IP_REPO_ROOT ".."
}
else {
    capture confirm file "PSID/psid.dta"
    if !_rc {
        global IP_INCOME_DIR "."
        global IP_REPO_ROOT "../.."
    }
    else {
        capture confirm file "inputs_stata_code/income_process/PSID/psid.dta"
        if !_rc {
            global IP_INCOME_DIR "inputs_stata_code/income_process"
            global IP_REPO_ROOT "."
        }
        else {
            display as error "Could not find PSID/psid.dta. Run from the repo root, inputs_stata_code, or inputs_stata_code/income_process."
            exit 601
        }
    }
}

global IP_VARIANTS "mostdrop_hhslabinc busno_drop_hhslabinc"
global IP_MEASURE "avghourlyhh"
global IP_PSID_PATH "$IP_INCOME_DIR/PSID/psid.dta"
global IP_OUTPUT_DIR "$IP_INCOME_DIR/output"
global IP_COMMON_SAMPLE "$IP_OUTPUT_DIR/common_sample.dta"
global IP_FORTRAN_DATA "$IP_REPO_ROOT/fortran_code/Data"

local n_reps_env : env N_REPS
if "`n_reps_env'" != "" {
    global IP_N_REPS `n_reps_env'
    display as text "Using N_REPS from environment: $IP_N_REPS"
}
else {
    local n_reps_file "$IP_INCOME_DIR/N_REPS.txt"
    capture confirm file "`n_reps_file'"
    if !_rc {
        tempname nreps_handle
        file open `nreps_handle' using "`n_reps_file'", read text
        file read `nreps_handle' n_reps_file_value
        file close `nreps_handle'
        local n_reps_file_value = strtrim("`n_reps_file_value'")
        if "`n_reps_file_value'" == "" {
            local n_reps_file_value 0
        }
        global IP_N_REPS `n_reps_file_value'
        display as text "Using N_REPS from `n_reps_file': $IP_N_REPS"
    }
    else {
        global IP_N_REPS 0
        display as text "N_REPS.txt not found; falling back to N_REPS = 0 (fast point-estimate run)."
        display as text "The shipped package default is 1000 (full paper bootstrap) in $IP_INCOME_DIR/N_REPS.txt."
    }
}

capture confirm number $IP_N_REPS
if _rc {
    display as error "N_REPS must be a non-negative integer. Check the N_REPS environment variable or $IP_INCOME_DIR/N_REPS.txt."
    exit 198
}
if $IP_N_REPS < 0 | $IP_N_REPS != floor($IP_N_REPS) {
    display as error "N_REPS must be a non-negative integer. Current value: $IP_N_REPS"
    exit 198
}

capture mkdir "$IP_OUTPUT_DIR"
foreach variant in $IP_VARIANTS {
    capture mkdir "$IP_OUTPUT_DIR/`variant'"
    capture mkdir "$IP_OUTPUT_DIR/`variant'/cov_binned"
}

capture which mat2txt
if _rc != 0 {
    ssc install mat2txt
}
