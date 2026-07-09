/* This dofile is based on data disseminated by Luetticke in a working version paper of "Shocks, Frictions, and Inequality in US Business Cycles" (AER, forthcoming).
The data for the conditionally accepted version are shorter (we need the data to start as early as possible.
Also, the data for the conditionally accepted version lump together taxes and social security contributions in ATRs.
In our paper social security contributions are separate, also the contributions are not progressive in the US (except for the cut-off), 
so progressivity measures should not be affected by including/excluding the contributions.  */


import excel tax_rate/progressivity_measures_all.xlsx, firstrow clear
keep year P_picketty_ex*
rename P_picketty_ex* lambda
drop if mi(year)

merge 1:1 year using $bsource/bone1y

* extrapolating by filling in the average value for 2010-2017
sum lambda if inrange(year,2010,2017)
replace lambda = `r(mean)' if mi(lambda) & year > 2017

periods

collapse (mean) lambda (first) year, by(fiveyear)

preserve
	tempfile model
	import delimited "tax_rate/MTZ_model_lambda_trans.txt", clear // replace path here for $f_results for your own results
	ren v1 lambda_model
	gen year = 5*_n + 1935 - 5
	keep if inrange(year, $year_start, $year_stop)
	save `model', replace
restore
merge 1:1 year using `model'

///// FROZEN /////////
gen lambda_frozen = lambda
sum lambda if year == 1955
replace lambda_frozen = `r(mean)' if year>=1955

////// DRAWING ////////
global var_frozen lambda_frozen
global var lambda 
global ys 1935
global ye 2015
special_drawing

////// EXPORTING ///////
export delimited $var using "../fortran_code/Data/_data_$var.txt", delimiter(tab) novarnames nolabel replace
