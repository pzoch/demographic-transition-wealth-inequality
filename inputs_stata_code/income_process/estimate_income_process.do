* =============================================================================
* INCOME PROCESS ESTIMATION: Consolidated Stata Pipeline
* =============================================================================
* Produces: _data_omega_{variant}_avghourlyhh.txt  (age-efficiency profiles)
*           Covariance matrix txt files for MATLAB estimation
*
* Pipeline: PSID sample selection -> Deaton APC decomposition -> Covariance matrices
*
* Source scripts (on Dropbox, for reference):
*   prepare_psid/psid_hhlabinc_marcin_RENAME.do
*   deaton/deaton.do
*   covariance_matrices_binned/prepare_income_dynamics_binned.do
* =============================================================================

clear all
set more off

* Install required community packages (only needed once)
capture which mat2txt
if _rc != 0 {
    ssc install mat2txt
}

* =============================================================================
* CONFIGURATION (only section user ever edits)
* =============================================================================
local variants      mostdrop_hhslabinc busno_drop_hhslabinc
local measure       avghourlyhh
local psid_path     "../../psid/psid"    // path to raw PSID dta (no extension), relative to this .do file's directory

* n_reps: 0 = point estimate only (fast), 1000 = full bootstrap for confidence bands.
* Override the default via environment variable N_REPS (e.g. `set N_REPS=1000` before
* running run_estimation.bat). Leave unset for the default of 0.
local n_reps_env : env N_REPS
if "`n_reps_env'" != "" {
    local n_reps `n_reps_env'
}
else {
    local n_reps 0
}
display as text "Using n_reps = `n_reps'"

* Create output directories
capture mkdir "./output"
foreach variant of local variants {
    capture mkdir "./output/`variant'"
    capture mkdir "./output/`variant'/cov_binned"
}

* =============================================================================
* STAGE 1: SAMPLE SELECTION
* (from psid_hhlabinc_marcin_RENAME.do, lines 31-261)
* =============================================================================

display as text "=== STAGE 1: Sample selection (`variant') ==="

use `psid_path', clear
rename hours hdshours

* --- CPI deflator (Jan 2000 base) ---
gen     price=22.6 	if year==1970
replace price=23.5 	if year==1971
replace price=24.3 	if year==1972
replace price=25.8 	if year==1973
replace price=28.6 	if year==1974
replace price=31.3 	if year==1975
replace price=33.1 	if year==1976
replace price=35.2 	if year==1977
replace price=37.9 	if year==1978
replace price=42.2 	if year==1979
replace price=47.8 	if year==1980
replace price=52.8 	if year==1981
replace price=56.1 	if year==1982
replace price=57.8 	if year==1983
replace price=60.4 	if year==1984
replace price=62.5 	if year==1985
replace price=63.7 	if year==1986
replace price=66.0 	if year==1987
replace price=68.7 	if year==1988
replace price=72.0 	if year==1989
replace price=75.9 	if year==1990
replace price=79.1 	if year==1991
replace price=81.5 	if year==1992
replace price=83.9 	if year==1993
replace price=86.1 	if year==1994
replace price=88.5 	if year==1995
replace price=91.1 	if year==1996
replace price=93.2 	if year==1997
replace price=96.7 	if year==1999
replace price=102.8 if year==2001
replace price=106.9 if year==2003
replace price=113.4 if year==2005
replace price=120.4 if year==2007
replace price=124.6 if year==2009
replace price=130.6 if year==2011
replace price=135.3 if year==2013
replace price=137.6 if year==2015
replace price=142.4 if year==2017
replace price=148.5 if year==2019
replace price=157.3 if year==2021
replace price = price/100

* --- Income definition (same for both variants) ---
* hhslabinc = all household labor income including business
gen hhslabinc       = wife_labinc_exc + wife_labinc_bus + wife_assinc_bus + wife_farm + hdslabinc_exc + hdslabinc_bus + hdsassinc_bus if year > 1993
replace hhslabinc   = wife_labinc_inc + hdslabinc_inc + total_assinc_bus  if year < 1993
replace hhslabinc   = wife_labinc_inc + hdslabinc_inc + wife_assinc_bus + hdsassinc_bus  if year == 1993

gen hhsinc_bus      = wife_assinc_bus + wife_labinc_bus + hdslabinc_bus + hdsassinc_bus if year > 1993
replace hhsinc_bus  = hdslabinc_bus + total_assinc_bus if year < 1993
replace hhsinc_bus  = hdslabinc_bus + wife_assinc_bus + hdsassinc_bus  if year == 1993

gen hhshours = hdshours + hours_wife
gen avghourlyhh = hhslabinc / hhshours

* --- Deflate ---
replace avghourlyhh = avghourlyhh / price
replace hhsinc_bus  = hhsinc_bus / price
replace hhslabinc   = hhslabinc / price

* --- Preliminary cleaning ---
rename pid person
sort person year

gen y = `measure'

sort person year
qby person: gen dyear = year - year[_n-1]
replace dyear = dyear / 2 if year > 1998

egen todrop = sum(dyear > 1 & dyear != .), by(person)
egen n = sum(person != .), by(person)
replace todrop = 1 if n == 1
drop if todrop > 0
drop todrop dyear n

drop if year < 1970
replace age = age - 1
drop if age > 65
drop if age < 20

* --- Education coding ---
gen     sc = .
replace sc = 1 if educ >= 0  & educ <= 11
replace sc = 2 if (educ == 12 | educ == 13)
replace sc = 3 if educ >= 14 & educ <= 17
replace sc = . if educ > 17
drop educ
rename sc educ

sort person year
qui by person: replace educ = educ[_n-1] if educ == .
gsort person -year
qui by person: replace educ = educ[_n-1] if educ == .
sort person year

egen maxed = max(educ), by(person)
gen educ2 = educ
replace educ = maxed
drop maxed

* --- Birth year ---
drop if age > 110
egen lasty = max(year), by(person)
gen lastage = age if year == lasty
gen b = year - lastage
replace b = 0 if b == .
egen yb = sum(b), by(person)
replace age = year - yb
drop lasty lastage b

* --- Outlier removal ---
local gy_max  5.00
local gy_min -0.80
local y_max  250
local y_min  2
local inc_max  1000000
local inc_min  1000
local hours_max 999999
local hours_min 260
local times_min 4

sort person year
qui by person: gen gy = (`measure' - `measure'[_n-1]) / (`measure'[_n-1])
replace gy = sqrt(gy) if year > 1998 & mi(gy)

gen m = gy > `gy_max' & gy != . | gy < `gy_min' & gy != . | ///
        y > `y_max' & y != . | y < `y_min' & y != . | ///
        hhshours < `hours_min' & hhshours != . | hhshours > `hours_max' & hhshours != . | ///
        hhslabinc < `inc_min' & hhslabinc != . | hhslabinc > `inc_max' & hhslabinc != .
egen mm = sum(m), by(person)
drop if mi(`measure')
drop if m > 0

egen n = sum(person != .), by(person)
gen todrop = 0
replace todrop = 1 if n < `times_min'
drop if todrop > 0

drop if yb < 1926
drop if yb > 1986

gen cohort = floor((yb - 1) / 5)

* Save common sample before variant-specific filtering
tempfile common_sample
save `common_sample', replace

* --- Deaton program (age effect extraction) ---
* Must be defined OUTSIDE the foreach loop (Stata parser issue with `end`)
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

* =============================================================================
* VARIANT LOOP: filter + Deaton + covariance matrices for each variant
* =============================================================================
foreach variant of local variants {

local output_dir "./output/`variant'"
display as text ""
display as text "###############################################################"
display as text "# Processing variant: `variant'"
display as text "###############################################################"

use `common_sample', clear

* --- Variant-specific sample selection ---
if "`variant'" == "mostdrop_hhslabinc" {
    * Drop households where >25% of 5-year income comes from business
    gen year_g = floor(year / 5) * 5
    bys year: egen p25 = pctile(hhslabinc), p(25)

    preserve
    tempfile superstars
    collapse (sum) hhsinc_bus hhslabinc p25 weight, by(year_g person)
    gen share = hhsinc_bus / hhslabinc
    gen most = 0
    replace most = 1 if share >= 0.25 & !mi(share) & hhslabinc > p25
    tsset person year_g
    gen entry = ((l5.most == 0) & (most == 1))
    gen exit  = ((most == 1) & (f5.most == 0))
    save `superstars', replace
    restore

    merge m:1 person year_g using `superstars', nogen
    sort person year
    drop if most == 1
    drop year_g p25
    display as text "   mostdrop: dropped business-income superstars"
}
else if "`variant'" == "busno_drop_hhslabinc" {
    * Keep all households (no filtering)
    display as text "   busno_drop: keeping all households"
}

* Save cleaned sample
save "`output_dir'/psid_`variant'_`measure'", replace
display as text "   Saved: `output_dir'/psid_`variant'_`measure'.dta"

* --- Generate bootstrap samples ---
if `n_reps' > 0 {
    set seed 20240101
    display as text "   Generating `n_reps' bootstrap samples..."
    forvalues ag = 1/`n_reps' {
        rename person person_old
        bsample, cluster(person_old) idcluster(person) strata(cohort)
        save "`output_dir'/psid_`variant'_`measure'_rep`ag'", replace
        use "`output_dir'/psid_`variant'_`measure'", clear
    }
    display as text "   Bootstrap samples saved to `output_dir'/"
}


* =============================================================================
* STAGE 2: DEATON APC DECOMPOSITION + STAGE 3: COVARIANCE MATRICES
* (from deaton/deaton.do + prepare_income_dynamics_binned.do)
*
* These two stages are merged into one rep loop. For each bootstrap rep:
*   2a) Run Deaton decomposition -> residuals by education
*   2b) Compute 5-yr binned covariance matrices -> save txt
* =============================================================================

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
        stack exp_mean_ageff_HE exp_mean_ageff_LE, into(v)
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

}  /* end foreach variant */

display as text ""
display as text "=== All variants complete ==="
display as text "Next: run estimate_parameters.m in MATLAB"
