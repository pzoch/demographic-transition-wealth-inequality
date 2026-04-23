
use ../graphs/outputs/wealth_inequality/combined_gini.dta, clear

tsset year

* Use the HP-filtered trend series (matches paper). The raw Gini_dta_5yr has
* a ~6 p.p. 1975 dip from single-period noise; the trend smooths it to ~2.5
* p.p., which is what the published Figure 1 shows. See _prep_Gini_data.do.
foreach var in Gini_data_wealth_trend $scenario {
	sum `var' if year == 1950
	gen a`var' = (`var'-`r(mean)')*100
	}

*** Figure 1
twoway  (bar aGini_data_wealth_trend year,  barwidth(3.2) color(gs12) bargap(0) )  ///
		(tsline a$scenario, lcolor(black) lwidth(thick))  ///
		if inrange(year,1950,2015) , ///
		legend(cols(2) order(1 "Data"  2 "Baseline model")  position(11) ) ///
		xtitle("") title("Change in wealth Gini coefficient (in p.p. relative to 1950)")  yline(0, lcolor(gs12) lwidth(medthick)) ///
		ytitle("Gini coefficient change in p.p.", size(*1.2))  ///
	 	xlabel(1950[15]2015, labsize(*1.2) ) ///
		xsize(7.5) ysize(3)  ylabel(, labsize(*1.2)  angle(h) gstyle(dot) glcolor(grey))

		graph export $graphspath\\Results_Gini_changes.png, replace
