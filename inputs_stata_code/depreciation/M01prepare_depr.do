* for depreciation we need periods shifted by 1
* the logic is that the rate at which capital depreciates between 1955 and 1960 is
* depr_1960 = 1 - (1-d_1960)*(1-d_1959)*(1-d_1958)*(1-d_1957)*(1-d_1956);

/*capture dbnomics import , provider(GGDC) dataset(penn10/delta.USA) clear
	ren period year
	ren value delta
	keep year delta
	destring _all, replace

save depreciation/depreciation.dta, replace */	

use depreciation/depreciation.dta, clear
periods

tsfilter hp delta_cycle = delta, smooth($lam) trend(delta_trend)
gen l_retain = log(1 - delta_trend)

collapse (mean) l_retain (first) year, by(fiveyear)  // means, because the last period had only 4 observations 
replace l_retain = l_retain*5

replace year = year + 5  //to align periods correctly
gen depr_5 = 1 - exp(l_retain)
drop l_retain

merge 1:1 year using $bsource/bone
drop fiveyear
periods

gen data = _merge==3
drop _merge

* to expand the inputs before 1955, we take the first value (seems legit)
sum depr_5 	if year==1955
replace depr_5 = `r(mean)' if mi(depr) & year<1955
* to expand the inputs after 2015, we gradually smoothen out the rate of depreciation to flat levels
sum depr_5 	if year==2020
replace depr_5 =  `r(mean)' + 0.08 /16 * (fiveyear - 19)^(1/2)  if mi(depr) & year>2015

drop fiveyear
gen depr_model = depr_5
sum depr_5 if year == 1955
replace depr_model = `r(mean)' if year>=1955


////// DRAWING ////////
rename depr_5 depr
label var depr "Depreciation"
global var depr
global var_frozen depr_model
global ys 1955
global ye 2020
special_drawing



////// EXPORTING ///////
export delimited $var using "../fortran_code/data/_data_$var.txt", delimiter(tab) novarnames nolabel replace

