//Prepare data for exogenous irr
/*
capture dbnomics import , provider(GGDC) dataset(penn10/irr.USA) clear
	ren period year
	ren value irr
	keep year irr
	destring _all, replace ignore(NA)

save ../sensitivity_stata_code/exog_rate/irr.dta, replace 		*/

use ../sensitivity_stata_code/exog_rate/irr.dta , clear
merge 1:1 year using bone1y

//Smooth-out the irr
tsset year
foreach var in  irr  {
	tsfilter hp `var'_cycle	= `var', smooth($lam) trend(`var'_trend)
	replace `var' = `var'_trend
	}
gen fiveyear = floor(year/5)*5

//Get the avg of 1-yr irr over 5 yrs 
collapse (mean)  irr  (first) year, by(fiveyear)

//Arbitrary values to fit the quadratic polynomial (we want 2100 irr = 0.07, smothly decreasing)
replace irr = 0.07 if year==2100
replace irr = 0.0731 if year==2020
gen t = fiveyear-2015
reg irr c.t c.t#c.t if year == 2015|year == 2020|year==2100
predict xb if year>2015
//Use the fitted polynomial
replace irr = xb if year>2015
//For missing irr before 1950 we just take a constant = first available value (1950)
sum irr 	if inrange(year,1950,1951)
replace irr = `r(mean)' if year<1950

replace irr = irr*100
tsset year
//Visual check: this is quite importat!
global var irr
tsline $var, yscale(range(5 11) )


///for partial-equilibrium model input
export delimited $var using "../fortran_code/data/_data_$var.txt", delimiter(tab) novarnames nolabel replace
