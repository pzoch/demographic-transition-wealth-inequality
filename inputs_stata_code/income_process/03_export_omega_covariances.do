* Export age-efficiency omega files and covariance matrices for MATLAB estimation.

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
local variants "$IP_VARIANTS"
local measure "$IP_MEASURE"
local n_reps $IP_N_REPS

capture program drop doit
program define doit
    while $ic < 66 {
        mac def ix = "aged$nc"
        replace ageff = _b[$ix] if age == $ic
        replace ageff_se = _se[$ix] if age == $ic
        mac def ic = $ic + 1
        mac def nc = $nc + 1
    }
end

foreach variant of local variants {
local output_dir "$IP_OUTPUT_DIR/`variant'"
display as text ""
display as text "###############################################################"
display as text "# Exporting omega and covariances: `variant'"
display as text "###############################################################"

display as text "=== STAGE 2+3: Deaton decomposition + Covariance matrices ==="

forvalues rep = 0/`n_reps' {

    display as text "--- Rep `rep' / `n_reps' ---"

    * Load appropriate sample
    if `rep' == 0 {
        use "`output_dir'/psid_`variant'_`measure'", clear
    }
    else {
        use "`output_dir'/psid_`variant'_`measure'_rep`rep'", clear
    }

    keep age year yb educ `measure' person

    keep if inrange(age, 20, 65)
    gen logy = ln(`measure')

    * --- Deaton decomposition ---
    tab age, gen(aged)
    tab yb, gen(cohd)
    tab year, gen(yrd)
    drop aged1
    drop cohd1

    * Year effects: add to zero and orthogonal to time trend
    forvalues n = 3(1)39 {
        local n0 = 42 - `n'
        local n1 = `n0' - 1
        local n2 = `n0' - 2
        replace yrd`n0' = yrd`n0' - `n1' * yrd2 + `n2' * yrd1
    }
    drop yrd2 yrd1

    * Low education (educ != 3)
    regress logy aged* cohd* yrd* if educ != 3 & inrange(age, 20, 65)
    predict double resid_LE if educ != 3, residuals
    replace resid_LE = 0 if educ == 3

    mac def nc = 2
    mac def ic = 21
    gen ageff = 0 if age == 20
    gen ageff_se = 0 if age == 20
    doit
    rename ageff ageff_LE
    rename ageff_se ageff_se_LE

    * High education (educ == 3)
    regress logy aged* cohd* yrd* if educ == 3 & inrange(age, 20, 65)
    predict double resid_HE if educ == 3, residuals
    replace resid_HE = 0 if educ != 3

    mac def nc = 2
    mac def ic = 21
    gen ageff = 0 if age == 20
    gen ageff_se = 0 if age == 20
    doit
    rename ageff ageff_HE
    rename ageff_se ageff_se_HE

    gen resid = resid_HE + resid_LE

    * --- Export omega (age effects) for rep 0 only ---
    if `rep' == 0 {
        * Save intermediate data for diagnostics
        preserve
        keep if educ == 3
        save "`output_dir'/psid_intermediate_H", replace
        restore
        preserve
        keep if educ < 3
        save "`output_dir'/psid_intermediate_L", replace
        restore

        * Export age-efficiency profile to txt
        preserve
        collapse (first) ageff_LE ageff_HE, by(age)
        save "`output_dir'/ageeffects_`measure'", replace

        gen exp_ageff_LE = exp(ageff_LE)
        gen exp_ageff_HE = exp(ageff_HE)

        gen age_group = floor((age - age[1]) / 5) - floor((20 + 1 - age[1]) / 5) + 1
        collapse (mean) ageff_LE ageff_HE exp_ageff_LE exp_ageff_HE, by(age_group)

        rename (exp_ageff_LE exp_ageff_HE) (mean_exp_ageff_LE mean_exp_ageff_HE)
        gen exp_mean_ageff_LE = exp(ageff_LE)
        gen exp_mean_ageff_HE = exp(ageff_HE)
        drop age*

        set obs `=_N + 6'
        foreach var in exp_mean_ageff_LE exp_mean_ageff_HE mean_exp_ageff_LE mean_exp_ageff_HE {
            replace `var' = 0 if missing(`var')
        }

        keep exp_mean_ageff_HE exp_mean_ageff_LE
        stack exp_mean_ageff_HE exp_mean_ageff_LE, into(v) clear
        drop _stack

        export delimited v using "`output_dir'/_data_omega_`variant'_`measure'.txt", delimiter(tab) novarnames nolabel replace
        display as text "   Saved omega: `output_dir'/_data_omega_`variant'_`measure'.txt"
        restore
    }

    * --- Stage 3: Covariance matrices (5-yr binned cohorts) ---
    * Save intermediate data by education for covariance computation
    tempfile deaton_H deaton_L
    preserve
    keep if educ == 3
    if `rep' == 0 {
        save `deaton_H', replace
    }
    else {
        save `deaton_H', replace
    }
    restore
    preserve
    keep if educ < 3
    save `deaton_L', replace
    restore

    foreach educ_level in "L" "H" {
        forvalues yr = 1926(5)1986 {
            mat Holder`yr' = J(46, 46, .)
            mat Nobs`yr' = J(46, 46, .)
        }

        if "`educ_level'" == "H" {
            use `deaton_H', clear
        }
        else {
            use `deaton_L', clear
        }

        qui xtset person age
        qui tsfill
        qui keep resid year person yb age

        qui reshape wide resid year, i(person yb) j(age)

        gen cov = .

        forvalues yr = 1926(5)1986 {
            preserve
            qui keep if inrange(yb, `yr', `yr' + 4)

            forvalues ag = 1/46 {
                local max_s = 46 - `ag'
                local ag_true = `ag' + 19
                forvalues s = 1/`max_s' {
                    local s_true = `ag' + 19 + `s'
                    capture qui correlate resid`ag_true' resid`s_true', covariance
                    if c(rc) == 0 {
                        mat Holder`yr'[`ag', `s'] = r(cov_12)
                        mat Nobs`yr'[`ag', `s'] = r(N)
                    }
                    else if !inlist(c(rc), 2000, 2001) {
                        mat Holder`yr'[`ag', `s'] = 111
                        display as error "Unexpected error in regression"
                        exit c(rc)
                    }
                }
            }
            restore

            * Save covariance matrices
            if `rep' == 0 {
                mat2txt, matrix(Holder`yr') saving("`output_dir'/cov_binned/`educ_level'_cohort`yr'.txt") replace
                mat2txt, matrix(Nobs`yr') saving("`output_dir'/cov_binned/Nobs_`educ_level'_cohort`yr'.txt") replace
            }
            else {
                mat2txt, matrix(Holder`yr') saving("`output_dir'/cov_binned/`educ_level'_cohort`yr'_rep`rep'.txt") replace
                mat2txt, matrix(Nobs`yr') saving("`output_dir'/cov_binned/Nobs_`educ_level'_cohort`yr'_rep`rep'.txt") replace
            }
        }
    }
}

display as text "=== Pipeline complete for `variant' ==="
display as text "Outputs in: `output_dir'/"
display as text "  - _data_omega_`variant'_`measure'.txt"
display as text "  - cov_binned/*.txt (point estimate + `n_reps' bootstrap reps)"

}

display as text ""
display as text "=== All Stata income-process variants complete ==="
