* Plot replacement-rate scale parameter for Appendix Figure B.9.

capture graph drop _all
capture set scheme burd
if _rc {
    ssc install scheme-burd, replace
    set scheme burd
}

local candidates ". .. ../.."
local repo_root ""
foreach root of local candidates {
    capture confirm file "`root'/inputs_stata_code/external/_data_rho_1935.txt"
    if !_rc & "`repo_root'" == "" {
        local repo_root "`root'"
    }
}
if "`repo_root'" == "" {
    display as error "Could not find inputs_stata_code/external/_data_rho_1935.txt."
    exit 601
}

local outdir "`repo_root'/graphs/inputs"
capture mkdir "`repo_root'/graphs"
capture mkdir "`outdir'"

import delimited "`repo_root'/inputs_stata_code/external/_data_rho_1935.txt", clear varnames(nonames)
rename v1 rho
keep if !missing(rho)
gen year = 1935 + 5 * (_n - 1)

quietly summarize year, meanonly
local last_year = r(max)
quietly summarize rho if year == `last_year', meanonly
local last_rho = r(mean)
local oldN = _N
set obs `=_N + 4'
forvalues i = 1/4 {
    replace year = `last_year' + 5 * `i' in `=`oldN' + `i''
    replace rho = `last_rho' in `=`oldN' + `i''
}

label variable rho "Calibration"
label variable year "year"

twoway (line rho year, lcolor(navy) lwidth(medthick)), ///
    title("", size(medsmall)) ///
    ytitle("replacement rate scale parameter") xtitle("year") ///
    ylabel(0.4(0.2)1.2, grid glcolor(gs14)) xlabel(1935 1960 1985 2010 2035) ///
    legend(off) xsize(4.8) ysize(3.2)

graph save "`outdir'/rho.gph", replace
graph export "`outdir'/rho.png", replace
graph export "`outdir'/rho.eps", replace
graph export "`outdir'/rho.svg", replace 
graph export "`outdir'/rho.pdf", replace
