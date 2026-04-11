**********************************************
**** This dofile graphs Gini from the model **
**** and from the data ***********************
**********************************************


// Calculating Gini from observational 5year data
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
drop if year == .
save `data'

//Calculating Gini from the model

local scenario		"psid_all_govt__"

tempfile model

	use ..\data\model_`scenario'
	replace mass = ceil(mass*10e5)
	gen wealthno0 = sav + 0.0001
	
matrix INEQ = J(30, 2, .)
matrix colnames INEQ = year_start Gini_model_5yr 

local irow = 0

forvalues yr = $year_start(5)$year_stop {
	local ++irow
	local span = 5
	qui ineqdeco wealthno0  [fweight = mass] if year == `yr'
	matrix INEQ[`irow', 1] = `yr' 
	matrix INEQ[`irow', 2] = `r(gini)'
}


matrix list INEQ
clear
svmat float INEQ, names(col)
drop if year == .

merge  1:1 year using `data'

tsset year

twoway 	(tsline Gini_model , lcolor(black) lwidth(thick))  ///
		(bar Gini_dta year, barwidth(3) yaxis(2) fcolor(gs12) lcolor(none))  if year>1949 ,   ///
		legend(order(2 "Data" 1 "Baseline model")) ///
		title("") xtitle(" ") ///
		ytitle(" Gini coefficient in the model") ytitle(" Gini coefficient in the data", axis(2)) ///
		xsize(5) ysize(1.5) 
	graph export $graphspath\\MvD_Gini_levels.png, replace 
	