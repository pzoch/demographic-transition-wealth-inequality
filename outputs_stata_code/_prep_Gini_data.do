* Community `ineqdeco` is required by this script (line ~50) and by
* MvD_3_Gini_wealth.do. Auto-install on first run if missing.
capture which ineqdeco
if _rc != 0 {
    ssc install ineqdeco
}

local mainfolder "../fortran_code/Results/"
local subfolders : dir "`mainfolder'" dirs "*"

capture tempfile close `master'
tempfile master
save `master', emptyok

local first = 1
foreach folder of local subfolders {

    display "Processing folder: `folder'"

    * Construct full path to CSV
    local filepath "`mainfolder'/`folder'/gini_trans.csv"

    * Check if file exists
    capture confirm file "`filepath'"
    if !_rc {

        import delimited "`filepath'", clear
		ren gini_sav `folder'

        if `first' {
            save `master', replace
            local first = 0
        }
        else {
            merge 1:1 year using `master', nogen
            save `master', replace
        }
    }
}
replace year = year*5 + 1930
save `master', replace

tempfile data

use "..\data\SCF\SCF_plus.dta", replace
gen mass = ceil(wgtI95W95*10e7)
gen wealthno0 = ffanw
replace wealthno0 = 0.0001 if wealthno0<=0
matrix INEQ   = J(30, 2, .)
matrix colnames INEQ = year_start Gini_dta_5yr

local irow = 0

forvalues yr = 1945(5)2016 {
	local ++irow
	local span = 5
	qui ineqdeco wealthno0  [pw = mass] if inrange(year,`yr',`yr'+`span'-1)
	capture matrix INEQ[`irow', 1] = `yr'
	capture matrix INEQ[`irow', 2] = `r(gini)'
}

matrix list INEQ
clear
svmat float INEQ, names(col)
rename year_start year
drop if year == .

* Apply an HP filter to the raw 5-year Gini to get a smooth trend series,
* matching the paper's prep in Paper_16_inequality/.../G06p_wealth_ineq_prep_data.do
* (log-transform -> tsfilter hp smooth(20) -> exp back). R_Figure1 uses the
* trend (Gini_data_wealth_trend) so the 1975 bar reflects the data's smoothed
* cycle rather than the noisy single-period dip.
gen time = _n
tsset time
gen Gini_data_wealth = ln(Gini_dta_5yr * 100)
tsfilter hp Gini_data_wealth_cycle = Gini_data_wealth, smooth(20) trend(Gini_data_wealth_trend)
replace Gini_data_wealth_trend = exp(Gini_data_wealth_trend) / 100
drop time Gini_data_wealth Gini_data_wealth_cycle
tsset, clear

save `data'


use `data', clear
merge 1:1 year using `master'

capture mkdir "../graphs"
capture mkdir "../graphs/outputs"
capture mkdir "../graphs/outputs/wealth_inequality"
save ../graphs/outputs/wealth_inequality/combined_gini.dta, replace