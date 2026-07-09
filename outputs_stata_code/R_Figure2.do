
use ../graphs/outputs/wealth_inequality/combined_gini.dta, clear

// run the program
prep_data_for_main_plot
quietly summarize aGini_variant_comp if inrange(year,1950,2050)
local dlo = r(min)
local dhi = r(max)
quietly summarize aGini_variant_base if inrange(year,1950,2050)
if r(min) < `dlo' local dlo = r(min)
if r(max) > `dhi' local dhi = r(max)
local ylo = `dlo' - 0.5
local yhi = `dhi' + 2
local first  = `yhi' - 1.5
local second = `ylo' + 2.5
local third  = `ylo' 
		
twoway  ///
		(tsline aGini_variant_base  if inrange(year,1950,2015), lcolor(black) lwidth(thick) lpattern(solid) )  ///
		(tsline aGini_variant_base  if inrange(year,2015,2050), lcolor(black) lwidth(thick) lpattern(dash) ) ///
		(pcarrowi  $variant_base_min   1975   $variant_base_max   1975, lcolor(black) mcolor(black) lpattern(dash) lwidth(0.7)  barbsize(0)   )  ///
		(pcarrowi  $variant_comp_1975  1975   $variant_base_1975  1975, lcolor(gs6) mcolor(gs6) lwidth(0.4)  barbsize(0)   )  ///
		(pcarrowi  $variant_comp_2015  2015   $variant_base_2015  2015, lcolor(gs6) mcolor(gs6) lwidth(0.4)  barbsize(0)   )  ///
		(pcarrowi  $variant_comp_2050  2050   $variant_base_2050  2050, lcolor(gs6) mcolor(gs6) lwidth(0.4)  barbsize(0)   )  ///
		(tsline aGini_variant_comp   if inrange(year,1950,2015), lcolor(purple) lwidth(medium)  lpattern(solid) )  ///
		(tsline aGini_variant_comp   if inrange(year,2015,2050), lcolor(purple) lwidth(medium)  lpattern(dash) )  ///
		(pcarrowi  $variant_comp_min 2050   $variant_comp_max 2050, lcolor(purple) mcolor(purple) lpattern(dash)  lwidth(medium)  barbsize(0)   )  ///
		if inrange(year,1950,2050)  ,	///
		text(`first'  1975 "Since $variant_base_y1: {&Delta} $variant_base_diff pp " , color(black))  ///
		text(`second' 2040 "Since $variant_comp_y1: {&Delta} $variant_comp_diff pp " , color(purple))  ///
		text(`third'  1975 "{&Delta} $diff_1975 pp ", color(gs6))  ///
		text(`third'  2015 "{&Delta} $diff_2015 pp ", color(gs6))   ///
		text(`first'  2045 "{&Delta} $diff_2050 pp ", color(gs6))  ///
		yline($variant_comp_min , lcolor(purple) lpattern(dot) lwidth(thin)) ///
		yline($variant_comp_max , lcolor(purple) lpattern(dot) lwidth(thin) )  ///
		yline($variant_base_min , lcolor(black) lpattern(dot) lwidth(thin)) ///
		yline($variant_base_max , lcolor(black) lpattern(dot) lwidth(thin) )  ///
		legend(order(1 "Baseline" 7 "[S1]Longevity fixed at 1955")  position(11) col(3))  ///
		xtitle("") ytitle("Wealth Gini") xsize(12) ysize(6) ysc(r(`ylo' `yhi')) ///
		xlabel(#6) ylabel(#7)
		

		
