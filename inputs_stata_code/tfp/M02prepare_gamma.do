* we want gamma(period) = A(period)/A(period-1)
* so for example to get gamma(1960) we do take A(1960)/A(1955);


/*capture dbnomics import , provider(GGDC) dataset(penn10/rtfpna.USA) clear
	ren period year
	ren value rtfpna
	keep year rtfpna
	destring _all, replace ignore(NA)
	replace rtfpna = ln(rtfpna)
save tfp/gamma.dta, replace  */	
	
use tfp/gamma.dta, clear

global lam = 1600

merge 1:1 year using $bsource/bone1y // data on DBnomics start in 1954, but the file starts in 1950
gen data = _merge==3
replace data = 0 if inrange(year,1950,1954)
drop _merge
sort year
tsset year 

* to expand the inputs before 1955, we take the average growth rates from 1954-2015
gen drtfpna = d.rtfpna
sum drtfpna , det
local mgrowth =  `r(mean)'
sum rtfpna 	if year == 1954 
replace rtfpna = `r(mean)' -  (1.35 * `mgrowth' * (1954 - year))  if mi(rtfpna) & year<1954
* to expand the inputs after 2015, we gradually smoothen out the rate of depreciation to flat levels
sum rtfpna 	if year == 2019 
replace rtfpna = `r(mean)' + 0.9* `mgrowth' * (year - 2019)   if mi(rtfpna) & year>2019
tsline rtfpna

periods
gen gamma_raw			= rtfpna - l5.rtfpna
tsfilter hp tfp_cycle	= rtfpna, smooth($lam) trend(tfp_trend)
tsfilter hp gamma_cycle	= gamma_raw, smooth($lam) trend(gamma)
collapse (mean)  gamma (first) year data, by(fiveyear) //  
tsset fiveyear
keep if year <= 2050
* do something with the initial period
replace gamma = gamma[2] in 1

gen gamma_model = gamma
sum gamma if year == 1955
replace gamma_model = `r(mean)' if year>=1955
////// DRAWING ////////
global var gamma
global var_frozen gamma_model
global ys 1955
global ye 2020
special_drawing

////// EXPORTING ///////
export delimited $var using "../fortran_code/data/_data_$var.txt", delimiter(tab) novarnames nolabel replace
