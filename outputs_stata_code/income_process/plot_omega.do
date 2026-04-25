* Plot deterministic productivity profiles from the Deaton-Paxson decomposition.
* Baseline output: Appendix Figure B.4.

capture graph drop _all
capture set scheme burd

local variant "mostdrop_hhslabinc"
if `"$IP_PLOT_VARIANT"' != "" {
    local variant "$IP_PLOT_VARIANT"
}
local measure "avghourlyhh"

local candidates ".. . ../.."
local repo_root ""
foreach root of local candidates {
    capture confirm file "`root'/data/PSID/ageeffects_`variant'_`measure'.dta"
    if !_rc & "`repo_root'" == "" {
        local repo_root "`root'"
    }
}
if "`repo_root'" == "" {
    display as error "Could not find data/PSID/ageeffects_`variant'_`measure'.dta. Run Step 2B first or supply the packaged processed PSID age-effects file."
    exit 601
}

local outdir "`repo_root'/graphs/inputs"
capture mkdir "`repo_root'/graphs"
capture mkdir "`outdir'"

use "`repo_root'/data/PSID/ageeffects_`variant'_`measure'.dta", clear

label variable ageff_LE "High school or less"
label variable ageff_HE "College or more"

twoway ///
    (line ageff_LE age, lcolor(navy) lwidth(medthick)) ///
    (line ageff_HE age, lcolor(maroon) lwidth(medthick)), ///
    title("(a) Empirical estimates", size(medsmall)) ///
    ytitle("log productivity") xtitle("age") ///
    ylabel(, grid glcolor(gs14)) xlabel(20(5)65) ///
    legend(order(1 "High school or less" 2 "College or more") rows(1) size(small)) ///
    xsize(3.4) ysize(2.8) name(omega_empirical, replace)

preserve
    gen age_start = 20 + 5 * floor((age - 20) / 5)
    replace age_start = 65 if age_start > 65
    collapse (mean) ageff_LE ageff_HE, by(age_start)
    gen omega_LE = exp(ageff_LE)
    gen omega_HE = exp(ageff_HE)
    quietly summarize omega_LE if age_start == 20, meanonly
    local base = r(mean)
    replace omega_LE = omega_LE / `base'
    replace omega_HE = omega_HE / `base'

    label variable omega_LE "High school or less"
    label variable omega_HE "College or more"

    twoway ///
        (connected omega_LE age_start, lcolor(navy) mcolor(navy) lwidth(medthick)) ///
        (connected omega_HE age_start, lcolor(maroon) mcolor(maroon) lwidth(medthick)), ///
        title("(b) Model inputs", size(medsmall)) ///
        ytitle("productivity, relative to age 20-24") xtitle("age group") ///
        ylabel(, grid glcolor(gs14)) xlabel(20 "20-24" 25 "25-29" 30 "30-34" 35 "35-39" 40 "40-44" 45 "45-49" 50 "50-54" 55 "55-59" 60 "60-64" 65 "65", angle(45) labsize(small)) ///
        legend(order(1 "High school or less" 2 "College or more") rows(1) size(small)) ///
        xsize(3.4) ysize(2.8) name(omega_model, replace)
restore

graph combine omega_empirical omega_model, cols(2) xsize(7.2) ysize(3.2) imargin(small)

graph save "`outdir'/omega_deaton_`variant'.gph", replace

graph export "`outdir'/omega_deaton_`variant'.png", replace
graph export "`outdir'/omega_deaton_`variant'.eps", replace
graph export "`outdir'/omega_deaton_`variant'.svg", replace fontface("Times New Roman")
graph export "`outdir'/omega_deaton_`variant'.pdf", replace
