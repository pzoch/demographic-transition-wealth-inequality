capture mkdir demography\mortality\processed
capture mkdir demography\mortality\output

////////////////// Improt data from the Human Mortality database //////////////////
clear
import excel "demography\mortality\life_tables.xlsx", sheet("Sheet1") firstrow
rename Age Agex
gen age  = mod(_n-1, 19)*5+20
// q(x) is probability of death in given period  therefore 
// 1 - q(x) is probabiliy of surviving given period, conditional of survivng to that age 
gen pi = 1- qx
rename Year Period 
keep Period age pi 
save "demography\mortality\processed\mortality_part_00.dta", replace


////////////////// Improt data from the UN projections //////////////////
clear
import excel "demography\mortality\2015-2050.xlsx", sheet("Sheet1") firstrow 
keep if Regionsubregioncountryorar =="United States of America"
// cleaning
capture drop Index Variant Notes Countrycode Ageintervaln Centraldeathratemxn ///
Probabilityofdyingqxn Numberofsurvivorslx Numberofdeathsdxn NumberofpersonyearslivedLx ///
SurvivalratioSxn PersonyearslivedTx Expectationoflifeex Averagenumberofyearsliveda S Parentcode
drop if Agex<20
drop if Agex>95
drop Regionsubregioncountryorar
destring Probabilityofsurvivingpxn, ignore("…") gen(pi)
sort Period Agex
// adjust age measures to model definitions
gen age = mod(_n-1, 16)*5+20
keep Period age pi 
save "demography\mortality\processed\mortality_part_11.dta", replace


////////////////// Improt data from the UN projections //////////////////
clear
import excel "demography\mortality\2050-2100.xlsx", sheet("Sheet1") firstrow
keep if Regionsubregioncountryorar =="United States of America"
// cleaning
capture drop Index Variant Notes Countrycode Ageintervaln Centraldeathratemxn ///
Probabilityofdyingqxn Numberofsurvivorslx Numberofdeathsdxn NumberofpersonyearslivedLx ///
SurvivalratioSxn PersonyearslivedTx Expectationoflifeex Averagenumberofyearsliveda S
drop if Agex<20
drop if Agex>95
drop Regionsubregioncountryorar
destring Probabilityofsurvivingpxn, ignore("…") gen(pi)
sort Period Agex
// adjust age measures to model definitions
gen age = mod(_n-1, 16)*5+20
keep Period age pi 
save "demography\mortality\processed\mortality_part_22.dta", replace

clear 
use "demography\mortality\processed\mortality_part_00.dta"
append using "demography\mortality\processed\mortality_part_11.dta"
append using "demography\mortality\processed\mortality_part_22.dta"


sort Period age

keep if age < 100
drop if Period == "2015-2018"
drop if Period == "1933-1934"
drop if Period == "2010-2015"

gen Year = floor((_n-1)/16)*5 + 1935
tab Year
set scheme burd 
twoway (scatter pi Year if age == 20) ///
(scatter pi Year if age == 25) ///
(scatter pi Year if age == 30) ///
(scatter pi Year if age == 35) ///
(scatter pi Year if age == 40) ///
(scatter pi Year if age == 45) ///
(scatter pi Year if age == 50) ///
(scatter pi Year if age == 55) ///
(scatter pi Year if age == 60) ///
(scatter pi Year if age == 65) ///
(scatter pi Year if age == 70) ///
(scatter pi Year if age == 75) ///
(scatter pi Year if age == 80) ///
(scatter pi Year if age == 85) ///
(scatter pi Year if age == 90) ///
(scatter pi Year if age == 95)

preserve
keep pi 
export delimited "demography\mortality\output\_data_pi_cond_US_since1935.txt", replace 
restore

preserve 
keep if Year > 1945 
keep pi 
export delimited "demography\mortality\output\_data_pi_cond_US_since1950.txt", replace 
restore

preserve 
keep if Year > 1955 
keep pi 
export delimited "demography\mortality\output\_data_pi_cond_US_since1960.txt", replace 
restore

preserve 
keep if Year > 2008 
keep pi 
export delimited "demography\mortality\output\_data_pi_cond_US.txt", replace 
restore

save "demography\mortality\processed\pi_tot_new.dta", replace
exit
