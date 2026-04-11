

foreach tax in  tK tL tC{

* load McDaniel's data 
* data downaloaded from from https://drive.google.com/drive/folders/1O5ccfP2KN815y-OSp2hRMnHneW4lAkia 
local tax tK
import delimited tax_rate/updateorig`tax'.csv, clear

rename v1 year
rename unitedstates `tax'

keep year `tax'
destring *, replace ignore(nan)

merge 1:1 year using $bsource/bone1y
gen data = _merge==3
drop _merge
sort year
periods

collapse (mean) `tax' (first) year, by(fiveyear) 

sum `tax' if year == 1950
replace `tax' = `r(mean)' if year < 1950 & mi(`tax')
sum `tax' if year == 2015
replace `tax' = `r(mean)' if year > 2015 & mi(`tax')

preserve
	tempfile model
	import delimited "tax_rate/MTZ_model_`tax'_trans.txt", clear
	ren v1 `tax'_model
	gen year = 5*_n + 1935 - 5
	keep if inrange(year, $year_start, $year_stop)
	save `model', replace
restore
merge 1:1 year using `model'

///// FROZEN /////////
sum `tax' if year == 1955
gen `tax'_frozen = `r(mean)'
replace `tax'_frozen = . if year < 1955

////// DRAWING ////////
global var_frozen `tax'_frozen
global var `tax'
global ys 1950
global ye 2015
special_drawing

////// EXPORTING ///////
export delimited $var using "../fortran_code/data/_data_$var.txt", delimiter(tab) novarnames nolabel replace
}
