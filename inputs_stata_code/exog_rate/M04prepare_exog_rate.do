* Build the exogenous interest-rate path consumed by Fortran when
* switch_exog_rate=1 (e.g. the exor_ scenario).
* Source: GGDC penn10/irr.USA (internal rate of return). The cached
* snapshot lives in exog_rate/irr.dta with the original variable name.

if $download_data == 1 {
	capture dbnomics import , provider(GGDC) dataset(penn10/irr.USA) clear
	ren period year
	ren value irr
	keep year irr
	destring _all, replace ignore(NA)
	save exog_rate/irr.dta, replace
}

use exog_rate/irr.dta , clear
rename irr exog_rate
merge 1:1 year using bone1y

global lam = 500

* HP-filter the annual series to keep the trend
tsset year
tsfilter hp exog_rate_cycle = exog_rate, smooth($lam) trend(exog_rate_trend)
replace exog_rate = exog_rate_trend
gen fiveyear = floor(year/5)*5

* Average the smoothed 1y rate over 5-year windows
collapse (mean) exog_rate (first) year, by(fiveyear)

* Smooth post-2015 path: hit 0.07 in 2100, fitted via quadratic through 2015/2020/2100
replace exog_rate = 0.07   if year==2100
replace exog_rate = 0.0731 if year==2020
gen t = fiveyear-2015
reg exog_rate c.t c.t#c.t if year == 2015|year == 2020|year==2100
predict xb if year>2015
replace exog_rate = xb if year>2015

* Pre-1950: hold flat at the first available value
sum exog_rate if inrange(year,1950,1951)
replace exog_rate = `r(mean)' if year<1950

replace exog_rate = exog_rate*100
tsset year
tsline exog_rate, yscale(range(5 11))

////// EXPORTING ///////
* Fortran reads this file when switch_exog_rate=1 (see fortran_code/data.f90)
export delimited exog_rate using "../fortran_code/Data/_data_exog_rate.txt", delimiter(tab) novarnames nolabel replace
