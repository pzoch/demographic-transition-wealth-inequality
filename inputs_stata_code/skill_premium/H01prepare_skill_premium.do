/* Load Autor, Goldin, Katz 2020 data 
Downloaded from https://www.openicpsr.org/openicpsr/project/120694/version/V1/view jsessionid=302ACC5985CCD9147C6B1A1D75417BD7 
We ignore data points for 1914, 1939 and 1949 due to large variance and disparity with later observations */
use skill_premium/AutorGoldinKatz2020/tables_A1_A2_figure_A1/wprem2_17.dta, clear
keep wprem2_17 year 
merge 1:1 year using $bsource/bone1y
ipolate wprem2_17 year, generate(wprem2)

global lam = 500

keep if year >= 1935
tsset year
tsline wprem2

replace wprem2= 0.386 if mi(wprem2) & year < 1963
sum wprem2 if year == 2017
replace wprem2= `r(mean)' if mi(wprem2) & year > 2017
quietly tsfilter hp wprem2_cycle = wprem2, smooth($lam) trend(wprem2_trend)
tsline wprem2_trend
periods

collapse (mean) wprem2_trend (first) year, by(fiveyear)
rename wprem2_trend wprem2
gen skill_premium = exp(wprem2)
tsset year
tsline skill_premium
gen skill_premium_model = skill_premium
sum skill_premium if year == 1955
replace skill_premium_model = `r(mean)' if year>=1955

////// DRAWING ////////
global var_frozen skill_premium_model
global var skill_premium 
global ys 1935
global ye 2015
special_drawing

////// EXPORTING ///////
gen ones = 1.00

stack $var ones, into(v) clear
drop _stack
export delimited v using "../fortran_code/Data/_data_$var.txt", delimiter(tab) novarnames nolabel replace
