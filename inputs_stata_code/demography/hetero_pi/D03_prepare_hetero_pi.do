capture mkdir demography\hetero_pi\processed
capture mkdir demography\hetero_pi\output

*****************Merging pi data with college proportion*********************************
//Use data generated in D01_life_tables.do
use "demography\mortality\processed\pi_tot_new.dta", clear
rename Year year
gen cohort = year - age
merge m:1 cohort using "skill_premium\ACS_college\processed\col_share_acs_ext.dta", nogen
rename college_share prop_col
rename ncollege_share prop_no_col
save "demography\hetero_pi\processed\pi_col_merge_M.dta", replace


******************************Anne Case Data*************************************
//The data was shared via email. Reference article:
//Case, A., & Deaton, A. (2021). Life expectancy in adulthood is falling for those without a BA degree, but as educational gaps have widened, racial gaps have narrowed. Proceedings of the National Academy of Sciences, 118(11), e2024777118.

/*Anne Case has year by year data in age interval of 1 yr. 
Here we create  data in interval of 5yrs. */

use "demography\hetero_pi\data\New_data_on_mortality.dta", clear
drop if inlist(sex,1,2) //dropping seperate rows for female and male
drop race //we only have agregate of those so this variables are useless
drop sex

label define edu 0 "All" 1 "less than BA" 3 "BA or more"
label values edclass edu 

gen pi = 1- tmort/population

//there is no data for 2019, I use data from 2018
tempfile last_year
preserve
drop if year != 2018
replace year = 2019
save `last_year' , replace
restore
append using `last_year'

//original vars in 1 yr interval
gen Cohortx = year - age
rename year Yearx
rename age Agex

//5 yrs interval
gen cohort	= 5 * floor(Cohortx/5)
gen age	= 5 * floor(Agex/5)
gen year	= 5 * floor(Yearx/5)


keep if Cohortx == cohort //keeping only people who have been born st. cohort mod 5 == 0
gen nw_log_pi = ln(pi) //for collapse - in stata no product
collapse (sum) nw_log_pi, by(cohort year edclass) //for particular cohort probability of surviving year+4yrs
gen pi = exp(nw_log_pi)
drop nw_log_pi

seperate pi, by(edclass)
bys year cohort: egen pr1 = mean(pi1)
bys year cohort: egen pr3 = mean(pi3)
bys year cohort: egen pr0 = mean(pi0)


drop if pi1 == .
drop pi0 pi1 pi3 pi edclass
gen pr = pr3/pr1

bys cohort: egen mean_pr = mean(pr)

******************************Merging with homogenous pi data*************************************
merge 1:1 year cohort using "demography\hetero_pi\processed\pi_col_merge_M.dta"

bysort cohort: egen aux = mean(mean_pr)
replace mean_pr = aux if mean_pr==.
drop aux

replace pr = mean_pr if pr ==.

//replacing pr for second and last available cohorts
replace pr = 1.018468 if cohort < 1915
replace pr = 1.006594 if cohort >= 1995

gen syn_pr1 = pi/(prop_no_col + pr*prop_col)
gen syn_pr3 = syn_pr1 * pr
gen syn_pr0 = pr1 * prop_no_col + pr3 *prop_col


replace syn_pr1 = pr1 if pr1!=.
replace syn_pr3 = pr3 if pr3!=.

sort year age
replace syn_pr1 = round(syn_pr1, .00001)
replace syn_pr3 = round(syn_pr3, .00001)
keep year age cohort syn_pr1 syn_pr3
save "demography\hetero_pi\processed\hetero_pi.dta", replace



keep syn_pr1 syn_pr3

preserve
stack syn_pr3 syn_pr1, into (prob) clear
replace prob = round(prob, .00001)
replace prob= 0.9999 if prob >= 1

keep prob
export delimited "demography\hetero_pi\output\_data_het_pi_US_since1935_all.txt", delimiter(tab) novarnames nolabel replace
export delimited "..\fortran_code\Data\_data_het_pi_US_since1935_all.txt", delimiter(tab) novarnames nolabel replace
restore

preserve
keep syn_pr1
export delimited "demography\hetero_pi\output\_data_pi_US_since1935_no_col.txt", replace
export delimited "..\fortran_code\Data\_data_pi_US_since1935_no_col.txt", replace
restore

preserve
keep syn_pr3
export delimited "demography\hetero_pi\output\_data_pi_US_since1935_col.txt", replace
export delimited "..\fortran_code\Data\_data_pi_US_since1935_col.txt", replace
restore

******************************Calculating LE50 for heterogenous pi*************************************

use "demography\hetero_pi\processed\hetero_pi.dta", clear
merge 1:1 year cohort using "demography\hetero_pi\processed\pi_col_merge_M.dta"

drop if age <50
drop if cohort < 1885
drop if cohort > 2000

//LE FOR NO-COLLEGE
tempfile non_college

preserve
keep age cohort syn_pr1
rename syn_pr1 pi

reshape wide pi, j(age) i(cohort)
gen cumpi = 1
forvalues y=50(5)95 {
	gen surv`y' = pi`y' * 5 * cumpi + (1-pi`y') * cumpi* 2.5 
	replace cumpi = cumpi *  pi`y'  
} 

egen LE50 = rowtotal(surv*) 
drop surv* cumpi pi*
gen year = cohort + 50
gen college = 0
save `non_college' , replace
restore
//ALL
tempfile all

preserve
keep age cohort pi

reshape wide pi, j(age) i(cohort)
gen cumpi = 1
forvalues y=50(5)95 {
	gen surv`y' = pi`y' * 5 * cumpi + (1-pi`y') * cumpi* 2.5 
	replace cumpi = cumpi *  pi`y'  
} 

egen LE50 = rowtotal(surv*) 
drop surv* cumpi pi*
gen year = cohort + 50
gen college = 2
save `all' , replace
restore


//LE WITH COLLEGE
keep age cohort syn_pr3
rename syn_pr3 pi

reshape wide pi, j(age) i(cohort)

gen cumpi = 1
forvalues y=50(5)95 {
	gen surv`y' = pi`y' * 5 * cumpi + (1-pi`y') * cumpi* 2.5 
	replace cumpi = cumpi *  pi`y'  
} 

egen LE50 = rowtotal(surv*) 
drop surv* cumpi pi*
gen year = cohort + 50
gen college = 1

append using `non_college'
append using `all'

seperate LE50, by(college)

di 2015 - (95-50) 
gen fixed_col 	= LE501 if year<=1955
sum fixed_col if year==1955
replace fixed_col = `r(mean)'  if year>1955
gen fixed_ncol	= LE500 if year<=1955
sum fixed_ncol if year==1955
replace fixed_ncol = `r(mean)'  if year>1955

//THIS IS THE MAIN VISUALISATION:	
twoway 	(line LE501 year if inrange(year,1935,1970), lcolor(blue) lwidth(thick) ) ///
		(line LE501 year if year>=1970 , lcolor(blue)  lwidth(medium) lpattern(dash)) ///
		(line LE500 year if inrange(year,1935,1970) , sort lcolor(black) lwidth(thick)) ///
		(line LE500 year if year>=1970 , lcolor(black) lwidth(medium)  lpattern(dash)) , ///
		xlabel(1935[15]2050, labsize(*1.2)) ylabel(24[5]40, labsize(*1.2)) ///
		legend(cols(2) order(-  "Data"  - "Demographic forecast" 1 "college"  2 "college"  3 "less than college"  4 "less than college") ///
		size(*1.2)) xtitle("year", size(*1.2)) xsize(2) ysize(1) ytitle("Life expectancy at 50")
/*
graph save 	 "graphs\inputs\LE50year.gph", replace
graph export "graphs\inputs\LE50year.png", replace
graph export "graphs\inputs\LE50year.svg", replace
graph export "graphs\inputs\LE50year.eps", replace
graph export "graphs\inputs\LE50year.pdf", replace