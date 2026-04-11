
use ../graphs/outputs/wealth_inequality/combined_gini.dta, clear

keep if inlist(year,1975,2015,2050)
tempfile bars_data_f
tempname bars_data

local base "$variant_base"
local comps "$variant_comp"
global scenarios  $variant_comp

local n : word count $colors

forvalues i = 1/`n' {
    local c`i' : word `i' of $colors
	local s`i' : word `i' of $variant_comp
}

capture postclose
postfile `bars_data' year str18 scenario level difference  using `bars_data_f', replace
foreach comp of local comps {

    cap drop aGini_base
    gen aGini_base = `base'*100

    cap drop aGini_comp
    gen aGini_comp = `comp'*100

    levelsof year, local(y)
    foreach yy of local y {

        summarize aGini_comp if year==`yy', meanonly
        local current = r(mean)

        summarize aGini_base if year==`yy', meanonly
        local baseval = r(mean)

        local diff = `baseval' - `current' 

        post `bars_data' (`yy') ("`comp'") (`current') (`diff')
	}
}

postclose `bars_data'

use `bars_data_f', clear

encode scenario, g(new_name)

gsort year new_name
gen N = _n 
levelsof year, local(y)
foreach yy of local y {
    replace N = N + 1 if year>`yy'
	sum N if year == `yy'
	local ylabels `ylabels' `r(mean)' "`yy'"
}


sum new_name
local l1 = `r(max)' + 1
local l2 = 2*`r(max)' + 2
local l3 = 3*`r(max)' + 2
twoway	(bar differ N if scenario=="`s1'", lwidth(white) hor barw(0.95) bcolor(`c1')) ///
		(bar differ N if scenario=="`s2'", lwidth(white) hor barw(0.95) bcolor(`c2')) ///
		(bar differ N if scenario=="`s3'", lwidth(white) hor barw(0.95) bcolor(`c3')) ///
		(bar differ N if scenario=="`s4'", lwidth(white) hor barw(0.95) bcolor(`c4')) ///
		(bar differ N if scenario=="`s5'", lwidth(white) hor barw(0.95) bcolor(`c5')) ///
		, ysc(reverse) $legend ///
		xline(0, lcolor(gs6) lpattern(solid)) ///
		xlabel(#`l3',grid glcolor(gs6) gstyle(dot)) ///
		yscale(r(`r(min)'(1)`r(max)')) ylabel(0 "1975" `l1' "2015" `l2' "2055", grid glcolor(gs6) gstyle(dot)) ///
		ytitle("") xtitle("Gini points") ///
		
