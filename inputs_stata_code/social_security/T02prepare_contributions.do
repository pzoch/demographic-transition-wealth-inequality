*Here are contributions data from OECD starting in 1965 and ending in 2021*
*The data exist for two data points (1973; 1974) in period 8 and two 2 data points (2020; 2021) in period 18 hence average is calculated for those periods using those years *

/*capture dbnomics import, pr(OECD) d(REV) series(NES.2000.TAXGDP.USA,NES.AG.TAXGDP.USA,NES.AJ.TAXGDP.USA) clear
	keep period tax value 
	reshape wide value, i(period) j(tax) string
	rename period year
	rename value2000 contributions
	rename valueAG voluntary_contributions
	rename valueAJ imputed_contributions
	replace contributions = contributions + voluntary_contributions + imputed_contributions if voluntary_contributions!=.
	keep year contributions
	destring year contributions, replace
	
save social_security/contributions.dta, replace */


use social_security/contributions.dta, clear
//So that the periods start properly:
*replace year = 1970 if year == 1973
periods
collapse (mean) contributions (first) year, by(fiveyear)

merge 1:1 year using $bsource/bone
gen data = _merge==3
replace data = 0 if inrange(year,1970,1973)
drop _merge
sort year
tsset year 
drop fiveyear
periods

//ML: adjustments to match our previous database 
replace contributions =contributions/100
replace contributions =. if year==1965

sum contributions 	if year == 1970
replace contributions = `r(mean)' -  (0.03/8 * (8 - fiveyear)^(1/2))  if fiveyear<8 & mi(contributions)

sum contributions 	if year == 2020
replace contributions = `r(mean)'  if year>2020& mi(contributions)


////// DRAWING ////////
global var contributions 
global ys 1970
global ye 2020

tsset year
keep if year < 2050
twoway	 ///
		(tsline $var if inrange(year,$ys,$ye), lcolor(black) lwidth(vthick)) ///
		(tsline $var if inrange(year,1935,$ys), lcolor(black)  lwidth(medium) lpattern(dash)) ///
		(tsline $var if inrange(year,$ye,2100), lcolor(black) lwidth(medium)  lpattern(dash)) , ///
		xtitle("year", size(*1.35)) ytitle("", size(*1.35)) title("") xlabel(1935[25]2050, labsize(*1.2)) ///
		ylabel(,labsize(*1.2) ) legend(order(-  "Baseline" - ""  1 "data"   - "" 2 "extrapolation"  ) size(*1.4) cols(2))  
		
		
	graph save "../graphs/inputs/$var.gph", replace
	graph export "../graphs/inputs/$var.png", replace
	graph export "../graphs/inputs/$var.eps", replace
	graph export "../graphs/inputs/$var.svg", replace
	graph export "../graphs/inputs/$var.pdf", replace


////// EXPORTING ///////
export delimited $var using "../fortran_code/data/_data_$var.txt", delimiter(tab) novarnames nolabel replace
