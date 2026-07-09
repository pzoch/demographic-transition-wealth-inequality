

if $download_data == 1 {
	capture dbnomics import , provider(GGDC) dataset(penn10/labsh.USA) clear
	ren period year
	ren value labsh
	keep year labsh
	destring _all, replace ignore(NA)
	save labor_share/labor_share.dta, replace
}

use labor_share/labor_share.dta, clear
merge 1:1 year using $bsource/bone1y
sort year
periods

global lam = 500

gen data = _merge==3
drop _merge

* to expand the inputs before 1955, we take the first value (seems legit)
sum labsh 	if inrange(year,1950,1955)
replace labsh = `r(mean)' +  0.01/15 * (1950 - year)^(1/2)  if mi(labsh) & year<1950
* to expand the inputs after 2019, we gradually smoothen out labor share to flat levels
sum labsh 	if inrange(year,2015,2020)
replace labsh = `r(mean)' - 0.2/80 * (year - 2019)^(1/2)  if mi(labsh) & year>2019

quietly tsfilter hp labsh_cycle = labsh, smooth($lam) trend(labsh_trend) // smoothen the series

collapse (mean) labsh_trend (first) year data, by(fiveyear)
gen labsh = labsh_trend * 100
drop labsh_
rename labsh lab_share


///// FROZEN /////////
gen lab_share_model = lab_share
sum lab_share if year == 1955
replace lab_share_model = `r(mean)' if year>=1955

////// DRAWING ////////
global var_frozen lab_share_model
global var lab_share
global ys 1950
global ye 2015
special_drawing

////// EXPORTING ///////
export delimited $var using "../fortran_code/Data/_data_labsh.txt", delimiter(tab) novarnames nolabel replace


