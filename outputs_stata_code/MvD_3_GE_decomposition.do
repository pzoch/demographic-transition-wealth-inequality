
**********************************************
**** This dofile graphs GE decomposition *****
**** from the model **************************
**** and from the data ***********************
**********************************************

* Clear any named graphs left over from earlier MvD scripts.
capture graph drop _all

// Obtaining decompositions from the model
local scenario		"psid_all_govt__"

	use ..\data\model_`scenario', clear
	replace mass = ceil(mass*10e7)
	gen cohort = year - age
	replace cohort = floor(cohort/5)*5
	gen wealthno0 = sav
	replace wealthno0 = 0.0001 if wealthno0 <=0 

	matrix INEQ = J(50, 5, .)
	matrix colnames INEQ = year_start year_end m_tot m_within m_between 

	local irow = 0
	forvalues yr = 1950(5)2010 {	
	local i = 30 
	local span = 5
		if (`yr' + `i' + 9) > 2020 {
				continue 
			}

	local ++irow
	di "row `irow' and year `yr'"
	
	matrix INEQ[`irow', 1] = `yr' 
	matrix INEQ[`irow', 2] = `yr' + `i' 
	local icol = 3
		preserve
		keep if inrange(year,`yr',`yr'+`span'-1) 
		qui ours_ineqdeco wealthno0  [pw = mass] , beta(0.5) by(cohort)
			
		local within_early_no0 		= `r(within)' 
		local between_early_no0		= `r(between)' 	
		local total_early_no0 		= `r(ge)'	
		restore
		
		preserve
		keep if inrange(year,`yr'+`i',`yr'+`i'+`span'-1)
		qui ours_ineqdeco  wealthno0 [pw = mass] , beta(0.5) by(cohort)
			
		local within_late_no0 		= `r(within)' 	
		local between_late_no0		= `r(between)' 	
		local total_late_no0 			= `r(ge)'	
		restore
		
		matrix INEQ[`irow', `icol']		= `total_early_no0'
		matrix INEQ[`irow', `icol'+1]	= `within_late_no0' - `within_early_no0'
		matrix INEQ[`irow', `icol'+2]	= `between_late_no0' - `between_early_no0'
	}

	matrix list INEQ
	clear
	tempfile model
	svmat float INEQ, names(col)
	keep if !mi(year_start)
	save `model'

	
// Obtaining decompositions from the observational data
use "..\data\SCF\SCF_plus.dta", clear
gen mass = ceil(wgtI95W95*10e7)
gen wealthno0 = ffanw 
replace wealthno0 = 0.0001 if wealthno0<=0
gen coh = year - ageh
gen cohort = floor(coh/5)*5
drop coh

	matrix INEQ = J(50, 5, .)
	matrix colnames INEQ = year_start year_end d_tot d_within d_between 

	local irow = 0
	forvalues yr = 1950(5)2010 {	
	local i = 30 
	local span = 5
		if (`yr' + `i' + 9) > 2020 {
				continue 
			}

	local ++irow
	di "row `irow' and year `yr'"
	matrix INEQ[`irow', 1] = `yr' 
	matrix INEQ[`irow', 2] = `yr' + `i' 
	local icol = 3
		qui ours_ineqdeco wealthno0  [pw = mass] if inrange(year,`yr',`yr'+`span'-1), beta(0.5) by(cohort)
			
		local within_early_no0 		= `r(within)' 
		local between_early_no0		= `r(between)' 	
		local total_early_no0 		= `r(ge)'	

		qui ours_ineqdeco  wealthno0 [pw = mass] if inrange(year,`yr'+`i',`yr'+`i'+`span'-1), beta(0.5) by(cohort)
			
		local within_late_no0 		= `r(within)' 	
		local between_late_no0		= `r(between)' 	
		local total_late_no0 			= `r(ge)'	
		
		matrix INEQ[`irow', `icol']		= `total_early_no0'
		matrix INEQ[`irow', `icol'+1]	= `within_late_no0' - `within_early_no0'
		matrix INEQ[`irow', `icol'+2]	= `between_late_no0' - `between_early_no0'
	}

	matrix list INEQ
	clear
	tempfile data
	svmat float INEQ, names(col)
	keep if !mi(year_start)
	save `data'
	

//Plotting the graphs side by side
merge 1:1 year_start using `model'	

global size				"xsize(7.5) ysize(3)"
global ylabel			"#20, labsize(*0.6)"
global xlabel5			"xlabel(1950(5)1990, tposition(o) labsize(*0.6) )"
global xlabel10			"xlabel(1950(5)1990, tposition(o) labsize(*0.6) )"
global label1			"DATA: contribution of BETWEEN cohort GE"
global label2			"DATA: contribution of WITHIN cohort GE"
global label3			"DATA: overall change of GE in this period"
global label4			"MODEL: contribution of BETWEEN cohort GE"
global label5			"MODEL: contribution of WITHIN cohort GE"
global label6			"MODEL: overall change of GE in this period"
	
gen year_data = year_start - 1
gen year_model = year_start +1


foreach l in d m {
gen `l'_between_g  = d_between
replace `l'_between_g  = `l'_between_g + `l'_within  if `l'_within > 0 & `l'_between > 0
}

twoway	(bar d_between_g  year_data, barw(1.5) bcolor(gs8*1.2)) ///
		(bar d_within year_data, barw(1.5)   bcolor(gs8*0.4))  ///
		(bar m_between_g year_model, barw(1.5)   bcolor(purple*1.2)) ///
		(bar m_within year_model, barw(1.5)   bcolor(purple*0.4)) if year_data<1980 , ///
		legend(pos(13) col(2) order(1 "$label1" 3 "$label4" 2 "$label2" 4 "$label5"  ) bexpand)   ///
		yline(0, lcolor(black))  ytitle("change in GE inequality")  ylabel($ylabel grid glcolor(grey) gstyle(dot)) ///
		xlabel(1950 "1950/4-1980/4"  1955 "1955/9-1985/9" 1960 "1960/4-1990/4" 1965 "1965/9-1995/9" 1970 "1970/4-2000/4" 1975 "1975/9-2005/9"  ///
							1980 "1980/4-2010/4"  , tposition(i) labsize(*0.8) )   ///
		xtitle("Period over which change in GE inequality was computed") ///
		xsize(6) ysize(3)

graph export $graphspath\\MvD_GE.png, replace
graph export $graphspath\\MvD_GE.eps, replace
graph export $graphspath\\MvD_GE.svg, replace  fontface("Times New Roman") 
