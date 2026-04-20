capture mkdir skill_premium\ACS_college\processed

global lam = 1600

////////////////// Import data from ACS (downloaded from IPUMS) //////////////////
use "skill_premium\ACS_college\ACS_college.dta", clear
keep if age == 25
gen has_BA_more = (higrade >= 19 & year < 1990) //completed at least 16 years of education
//higrade in general version reports the highest grade completed; detailed higrade also provide attended
gen has_BA_equal = (higrade == 19 & year < 1990) //completed precisely 16 years of education
replace  has_BA_more = 1 if inlist(educd, 101 , 114,115,116)  & year >= 1990
//^ those who obtained Bachelor's degree OR  Master's degree  OR Professional degree beyond a bachelor's OR Doctoral degree


replace has_BA_equal = has_BA_more if year >= 1990
collapse (mean) has_BA_more has_BA_equal [pw = perwt], by(year)
tsset year
merge 1:1 year using $bsource/bone1y
sort year

ipolate has_BA_more year, generate(college_share)
periods

gen data = _merge==3
drop _merge

* to expand the inputs before 1940, we take the first value (seems legit)
sum college_share 	if year==1940
replace college_share = `r(mean)' if mi(college_share) & year<1940
* to expand the inputs after 2020, we gradually smoothen out the share  to flat levels
sum college_share 	if year==2020
replace college_share =  `r(mean)'  + 0.5 /25 * (fiveyear - 17)^(1/1.9) if mi(college_share) & year>2020

tsfilter hp college_share_cycle = college_share, smooth($lam) trend(college_share_trend) // smoothen the series

collapse (mean) college_share_trend (first) year data, by(fiveyear)
rename college_share_trend college_share


gen ncollege_share = 1 - college_share
drop fiveyear


////// FROZEN /////////
gen college_share_model = college_share
sum college_share if year == 1955
replace college_share_model = `r(mean)' if year>=1955


////// DRAWING ////////
global var_frozen college_share_model
global var college_share
global ys 1940
global ye 2020
special_drawing

preserve
stack college_share ncollege_share, into(v)
export delimited v using "../fortran_code/Data/_data_$var.txt", delimiter(tab) novarnames nolabel replace

restore
gen cohort = year - 25
save "skill_premium\ACS_college\processed\col_share_acs", replace

clear
range cohort 1840 2075 48
merge 1:1 cohort using "skill_premium\ACS_college\processed\col_share_acs", nogen
replace college_share = .0469714 if cohort < 1910
replace year = cohort + 25
replace data = 0 if mi(data)
replace ncollege_share = 1- college_share if mi(ncollege_share)
save "skill_premium\ACS_college\processed\col_share_acs_ext", replace
