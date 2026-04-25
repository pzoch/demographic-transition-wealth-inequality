* Figure C.1 -- Population pyramid: full-model vs frozen-longevity counterfactual.

capture graph drop _all

tempfile tem_base tem_comp

import delimited "$resultspath/$variant_base/population.csv", clear
gen year = 5*_n + 1935 - 5
local count = 1
forvalues i = 25(5)100 {
    capture rename v`count' age_base_`i'
    local count = `count' + 1
}
capture drop v17
reshape long age_base_, i(year) j(age)
rename age_base_ population
reshape wide population, i(age) j(year)
gen source = "base"
save `tem_base', replace

import delimited "$resultspath/$variant_comp/population.csv", clear
gen year = 5*_n + 1935 - 5
local count = 1
forvalues i = 25(5)100 {
    capture rename v`count' age_comp_`i'
    local count = `count' + 1
}
capture drop v17
reshape long age_comp_, i(year) j(age)
rename age_comp_ population
reshape wide population, i(age) j(year)
gen source = "comp"
save `tem_comp', replace

clear
append using `tem_base'
append using `tem_comp'

foreach yr in 1935 1950 1975 2000 2020 2050 2100 {
    twoway  (bar population`yr' age if source == "comp", bcolor(red%50)    horizontal barw(5)) ///
            (bar population`yr' age if source == "base", bcolor(purple%50) horizontal barw(3)), ///
            title("`yr'") legend(order(1 "Counterfactual: longevity fixed at 1955" 2 "Baseline")) ///
            xtitle("`yr' population") ytitle("age")
    graph export "$graphspath/AppC_PopStructure_`yr'.png", replace
    graph export "$graphspath/AppC_PopStructure_`yr'.eps", replace
    graph export "$graphspath/AppC_PopStructure_`yr'.svg", replace fontface("Times New Roman")
    graph export "$graphspath/AppC_PopStructure_`yr'.pdf", replace
}
