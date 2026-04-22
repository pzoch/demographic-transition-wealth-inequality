* =============================================================================
* Regenerate the three frozen .dta snapshots MvD_1_macro.do reads under
* $download_data=0: data/irr_data.dta, data/benefits_cbo.dta,
* data/avghours_data.dta.
*
* Default: DOES NOT DOWNLOAD. This script is a no-op unless the caller sets
*   global download_data 1
* explicitly. This mirrors MvD_1_macro.do / __main.do's convention and keeps
* a default `do _bootstrap_MvD_data.do` safe to run.
*
* To refresh the snapshots (network required):
*   In Stata Command window after opening __replication_graphs.stpr:
*     global download_data 1
*     do _bootstrap_MvD_data.do
*
* Implementation: uses the dbnomics Stata community package (same as
* MvD_1_macro.do's download blocks). Requires:
*   ssc install libjson
*   ssc install moremata
*   ssc install dbnomics
* If dbnomics fails with Mata compile errors, reinstall the dependencies
* fresh (ssc uninstall dbnomics; ssc install libjson, replace;
* ssc install dbnomics, replace).
*
* Equivalent to the three $download_data==1 blocks in MvD_1_macro.do
* (lines 9-19, 37-49, 85-117). Same HP-filter (lambda=1600), same 5-year
* collapse, same normalisation.
* =============================================================================

* --- Gate: default no-op ---
if "$download_data" == "" {
    global download_data 0
}
if $download_data != 1 {
    display as error "bootstrap skipped: default is no-download."
    display as text  "Set 'global download_data 1' before running this script" ///
        " to refresh the three .dta snapshots from dbnomics."
    exit 0
}

clear all
set more off
capture mkdir data

* Programs needed for the 5-year binning (periods / periods_proj)
global year_start 1950
global year_stop  2020
global lam        1600
do _prog_coding.do

* =============================================================================
* irr -- GGDC Penn World Tables 10, series irr.USA
* =============================================================================
capture dbnomics import, provider(GGDC) dataset(penn10/irr.USA) clear
ren (period value) (year irr_data)
keep year irr_data
destring _all, replace ignore(NA)
tsset year
tsfilter hp irr_cycle = irr_data, smooth($lam) trend(irr_trend)
replace irr_data = irr_trend * 100
gen fiveyear = floor(year/5)*5
collapse (mean) irr_data (first) year, by(fiveyear)
save data/irr_data.dta, replace

* =============================================================================
* benefits -- CBO Social Security payments as % of GDP (51134-MO/SS.PGDP)
* =============================================================================
capture dbnomics import, pr(CBO) dataset(51134-MO/SS.PGDP) clear
rename value benefits_data
rename period year
destring year benefits_data, replace
keep year benefits_data
replace year = 1960 if year == 1962
drop if year > 2020
periods
collapse (mean) benefits_data (first) year, by(fiveyear)
gen source = "data"
save data/benefits_cbo.dta, replace

* =============================================================================
* avghours -- OECD working-age population (20-64) x GGDC Penn avh, emp
* =============================================================================
tempfile oecd_wap
capture dbnomics import, provider(OECD) dataset(DSD_POPULATION@DF_POP_HIST) series(USA.POP.PS._T.Y20T64.H) clear
keep value period
destring value period, replace
replace value = value / 1000000
gen name = "wa_pop"
reshape wide value, i(period) j(name) string
rename valuewa_pop wap
save `oecd_wap'

capture dbnomics import, provider(GGDC) dataset(penn10) series(avh.USA,emp.USA) clear
keep value period subject
reshape wide value, i(period) j(subject) string
gen tothours = valueemp * valueavh
merge 1:1 period using `oecd_wap'
gen avghours_data = tothours / wap
rename period year
keep avghours_data year
periods
tsfilter hp avghours_cycle = avghours_data, smooth($lam) trend(avghours_trend)
replace avghours_data = avghours_trend
sum avghours_data if inrange(year, 1950, 2015)
replace avghours_data = (avghours_data / `r(mean)') * 100
collapse (mean) avghours_data (first) year, by(fiveyear)
save data/avghours_data.dta, replace

display as text "bootstrap complete: data/{irr_data,benefits_cbo,avghours_data}.dta saved."
