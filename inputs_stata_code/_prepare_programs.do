
capture program drop periods
program periods
tsset year
drop if year < $year_start 
drop if year > $year_stop
sum year, det
gen fiveyear =  floor((year-`r(min)')/5) - floor(($year_start -`r(min)')/5) + 1
end




clear
range year 1935 2100 34
save bone, replace

clear
range year 1935 2100 166
save bone1y, replace


capture program drop drawing
program drawing
preserve
tsset year
keep if year < 2050
twoway	(tsline $var if inrange(year,$ys,$ye), lcolor(black) lwidth(vthick)) ///
		(tsline $var if inrange(year,1935,$ys), lcolor(blue) lpattern(dash)) ///
		(tsline $var if inrange(year,$ye,2100), lcolor(blue) lpattern(dash)), ///
		xtitle("year", size(*1.35)) ytitle(, size(*1.35)) title("") xlabel(1935[25]2050, labsize(*1.2)) ///
		ylabel(,labsize(*1.2) ) legend(order(1 "data" 2 "extrapolation") size(*1.35))
	graph save "../graphs/inputs/$var.gph", replace
	graph export "../graphs/inputs/$var.png", replace
	graph export "../graphs/inputs/$var.eps", replace
	graph export "../graphs/inputs/$var.svg", replace
	graph export "../graphs/inputs/$var.pdf", replace
restore
end


capture program drop special_drawing
program special_drawing
capture graph drop _all
preserve
tsset year
keep if year < 2050
twoway	(tsline $var_frozen ,lcolor(red) lpattern(solid)) ///
		(tsline $var if inrange(year,$ys,$ye), lcolor(black) lwidth(vthick)) ///
		(tsline $var if inrange(year,1935,$ys), lcolor(black)  lwidth(medium) lpattern(dash)) ///
		(tsline $var if inrange(year,$ye,2100), lcolor(black) lwidth(medium)  lpattern(dash)) , ///
		xtitle("year", size(*1.35)) ytitle(, size(*1.35)) title("") xlabel(1935[25]2050, labsize(*1.2)) ///
		ylabel(,labsize(*1.2) ) legend(order(-  "Baseline"  - "Counterfactual" 2 "data"  1 "fixed at 1955" 3 "extrapolation"  ) size(*1.4) cols(2))

	graph save "../graphs/inputs/$var.gph", replace
	graph export "../graphs/inputs/$var.png", replace
	graph export "../graphs/inputs/$var.eps", replace
	graph export "../graphs/inputs/$var.svg", replace
	graph export "../graphs/inputs/$var.pdf", replace
restore
end


capture program drop special_drawing2
program special_drawing2
* Drop any named graphs left in memory by earlier scripts (e.g., MvD_1's
* "irr"/"avghours"/"benefits"). Otherwise `graph save` without an explicit
* name can resolve to the wrong graph and emit "graph benefits not found".
capture graph drop _all
preserve
tsset year
keep if year < 2050
twoway	(tsline $var_frozen ,lcolor(blue) lpattern(dash)) ///
		(tsline $var if inrange(year,$ys,$ye), lcolor(black) lwidth(vthick)) ///
		(tsline $var if inrange(year,1935,$ys), lcolor(black)  lwidth(medium) lpattern(dash)) ///
		(tsline $var if inrange(year,$ye,2100), lcolor(black) lwidth(medium)  lpattern(dash)) , ///
		xtitle("year", size(*1.35)) ytitle(, size(*1.35)) title("") xlabel(1935[25]2050, labsize(*1.2)) ///
		ylabel(,labsize(*1.2) ) legend(order(-  "Primary"  - "Alternative" 2 "data"  1 "extrapolation" 3 "extrapolation"  ) size(*1.4) cols(2))

	graph save "../graphs/inputs/$var.gph", replace
	graph export "../graphs/inputs/$var.png", replace
	graph export "../graphs/inputs/$var.eps", replace
	graph export "../graphs/inputs/$var.svg", replace
	graph export "../graphs/inputs/$var.pdf", replace
restore
end

