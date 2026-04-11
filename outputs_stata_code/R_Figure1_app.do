
use ../graphs/outputs/wealth_inequality/combined_gini.dta, clear

tsset year

foreach var in Gini_dta_5yr $scenario {
	sum `var' if year == 1950
	gen a`var' = (`var'-`r(mean)')*100
	}

*** Figure 1 
twoway  (bar aGini_dta_5yr year,  barwidth(3.2) color(gs12) bargap(0) )  ///
		(tsline apsid_all_govt__, lcolor(black) lwidth(thick))  ///
		(tsline aexor_all_govt__, lcolor(blue) lwidth(thick))  ///
		if inrange(year,1950,2015) , /// 
		legend(cols(3) order(1 "Data"  2 "Baseline model" 3 "Open-economy model")  position(11) ) ///
		xtitle("") title("Change in wealth Gini coefficient (in p.p. relative to 1950)")  yline(0, lcolor(gs12) lwidth(medthick)) ///
		ytitle("Gini coefficient change in p.p.", size(*1.2))  ///
	 	xlabel(1950[15]2015, labsize(*1.2) ) ///
		xsize(7.5) ysize(3)  ylabel(, labsize(*1.2)  angle(h) gstyle(dot) glcolor(grey)) 
		 
		graph export $graphspath\\Results_Gini_changes.png, replace 
