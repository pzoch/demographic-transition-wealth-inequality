
capture program drop periods
program periods
tsset year
drop if year < $year_start 
drop if year > $year_stop
sum year, det
gen fiveyear =  floor((year-`r(min)')/5) - floor(($year_start -`r(min)')/5) + 1
end


capture program drop periods_proj
program periods_proj
tsset year
sum year, det
gen fiveyear =  floor((year-`r(min)')/5) - floor(($year_start -`r(min)')/5) + 1
end

clear
range year 1935 2100 34
save bone, replace

clear
range year 1935 2100 166
save bone1y, replace


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


//This program is used to prepare model data for plotting
capture program drop prep_data_for_main_plot
program prep_data_for_main_plot

    tsset year

    foreach variant in variant_base variant_comp {

        * Get the variable name stored in the global
        local varname = "$`variant'"

        cap drop aGini_`variant'
        gen aGini_`variant' = `varname'*100

        sum aGini_`variant' if inrange(year,1975,2050), detail

        global `variant'_min  =  `r(min)'
        global `variant'_max  =  `r(max)'

        local val = ${`variant'_max} - ${`variant'_min}

        if `val' == 0 {
            local clean = 0
        }
        else {
            local rounded = round(`val', 10^(floor(log10(abs(`val')))-1))
            local clean = round(`rounded', 1e-10)
        }

        global `variant'_diff : display %5.2g `clean'

        gen `variant'_min = `r(min)'
        gen `variant'_max = `r(max)'

        sum year if floor(aGini_`variant' * 100) / 100  == floor(`r(min)' * 100) / 100 
        global `variant'_y1 =  `r(mean)' 

        foreach y in 1975 2015 2050 {

            sum aGini_`variant' if year == `y'
            global `variant'_`y' = `r(mean)' 
        }
    }

	
foreach y in 1975 2015 2050 {
    
    local val = ${variant_base_`y'} - ${variant_comp_`y'}
    
    if `val' == 0 {
        global diff_`y' = 0
    }
    else {
        local rounded = round(`val', 10^(floor(log10(abs(`val')))-1))
        
        * kill floating-point noise explicitly
        local clean = round(`rounded', 1e-10)
        
        global diff_`y' : display %5.2g `clean'
    }
}

    keep if year >= 1935

end prep_data_for_main_plot
