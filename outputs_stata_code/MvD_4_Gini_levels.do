
use ../graphs/outputs/wealth_inequality/combined_gini.dta, clear

tsset year

foreach var in Gini_data_wealth_trend $scenario {
	sum `var' if year == 1950
	gen a`var' = (`var'-`r(mean)')*100
	}

*** Figure 1
twoway  (bar Gini_data_wealth_trend year,  barwidth(3.2) color(gs12) bargap(0) )  ///
		(tsline $scenario, lcolor(black) lwidth(thick) yaxis(2))  ///
		if inrange(year,1950,2015) , ///
		legend(cols(2) order(1 "Data (left axis)"  2 "Baseline model (right axis)")  position(11) ) ///
		xtitle("") title("Gini coefficient")  yline(0, lcolor(gs12) lwidth(medthick)) ///
		ytitle("Gini coefficient", size(*1.2))  ytitle("Gini coefficient", size(*1.2) axis(2)) ///
	 	xlabel(1950[15]2015, labsize(*1.2) ) ///
		xsize(7.5) ysize(3)  ylabel(, labsize(*1.2)  angle(h) gstyle(dot) glcolor(grey))

		graph export $graphspath\\Results_Gini_levels.png, replace
		graph export $graphspath\\Results_Gini_levels.eps, replace
		graph export $graphspath\\Results_Gini_levels.svg, replace
