
use ../graphs/outputs/wealth_inequality/combined_gini.dta, clear

// run the program
prep_data_for_main_plot
local first  = $r2 - 1.5
local second = $r1 + 2.5
local third  = $r1 + 0.5 
		
twoway  ///
		(rarea aGini_variant_base  aGini_variant_comp  year ,  color(gs14%40))  ///
		(tsline aGini_variant_base  if inrange(year,1950,2015), lcolor(black) lwidth(thick) lpattern(solid) )  ///
		(tsline aGini_variant_base  if inrange(year,2015,2050), lcolor(black) lwidth(thick) lpattern(dash) ) ///
		(pcarrowi  $variant_base_min   1975   $variant_base_max   1975, lcolor(black) mcolor(black) lpattern(dash) lwidth(0.7)  barbsize(0)   )  ///
		(pcarrowi  $variant_comp_1975  1975   $variant_base_1975  1975, lcolor(gs6) mcolor(gs6) lwidth(0.4)  barbsize(0)   )  ///
		(pcarrowi  $variant_comp_2015  2015   $variant_base_2015  2015, lcolor(gs6) mcolor(gs6) lwidth(0.4)  barbsize(0)   )  ///
		(pcarrowi  $variant_comp_2050  2050   $variant_base_2050  2050, lcolor(gs6) mcolor(gs6) lwidth(0.4)  barbsize(0)   )  ///
		(tsline aGini_variant_comp   if inrange(year,1950,2015), lcolor(purple) lwidth(0.7)  lpattern(solid) )  ///
		(tsline aGini_variant_comp   if inrange(year,2015,2050), lcolor(purple) lwidth(0.7)  lpattern(dash) )  ///
		(pcarrowi  $variant_comp_min 2050   $variant_comp_max 2050, lcolor(purple) mcolor(purple) lpattern(dash)  lwidth(0.7)  barbsize(0)   )  ///
		if inrange(year,1950,2050)  ,	///
		text(`first'  1975 "Since $variant_base_y1: {&Delta} $variant_base_diff pp " , color(black))  ///
		text(`second' 2040 "Since $variant_comp_y1: {&Delta} $variant_comp_diff pp " , color(purple))  ///
		text(`third ' 1975 "{&Delta} $diff_1975 pp ", color(gs6))  ///
		text(`third'  2015 "{&Delta} $diff_2015 pp ", color(gs6))   ///
		text(`first'  2045 "{&Delta} $diff_2050 pp ", color(gs6))  ///
		yline($variant_comp_min , lcolor(purple) lpattern(dot) lwidth(thick)) ///
		yline($variant_comp_max , lcolor(purple) lpattern(dot) lwidth(thick) )  ///
		yline($variant_base_min , lcolor(black) lpattern(dot) lwidth(thick)) ///
		yline($variant_base_max , lcolor(black) lpattern(dot) lwidth(thick) )  ///
		legend(order(2 "Baseline" 8 "[S1]Longevity fixed at 1955")  position(11) col(3))  ///
		xtitle("") ytitle("Wealth Gini") xsize(12) ysize(6) ysc(r($r1 $r2)) ///
		xlabel(#6) ylabel(#7)
		

		
