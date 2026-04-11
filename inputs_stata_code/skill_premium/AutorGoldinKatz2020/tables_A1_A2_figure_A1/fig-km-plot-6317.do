pause off
set more 1


/*
* update: A Wu, 08/13/2019 (change fonts in figure on 08/19/2019)
local dir="/proj/pdautor/tech-race-revisited/ASEC/Science14-fig3b-4-update/"
* local dir="/Users/alicehwu/Dropbox/agk_rbet_revisited/data/March_CPS/autor_2014_marchcps/update/"
*/

capture log close
log using "fig-km-plot_6317.log", t replace

/*
   Based on kmregs-6308_fig4.do from AKK 2008
   
   College/High School Relative Supply and Wage Differential, 1963-2004 (March CPS)

   *Katz-Murphy College/HS Wage Differential Time Series Regressions
   *March CPS Data, 1963-2005
   *Basic Runs of Log(Coll/HS) gap on trend and log(Rel Supply)
   *Compare 1963-87 and Forecasts with Full Sample

   * Put together wage gap and supplies series
   * Both are based on fixed-weighted experience-group models

   * Updated to March 2006 data (2005 earnings year) by D. Autor on 10/10/2006

   * Updated to March 2008/9 data by M. Wasserman 10/2009

   * Updated to March 2010/13 data by C. Patterson 2/2014
*/

set more 1


* Wage gap series
use clghsgwg-march-regseries-exp.dta,clear
desc
keep year clghsg_all* clphsg_all*

* Adding supplies series
sort year
merge year using effunits-exp-byexp-6318
assert _merge==3
drop _merge
desc eu_* euexp*
tab expcat
keep if expcat==1
drop expcat
desc

*Different College/HS Wage Diff Series, M&F Combined and Rel Supply
list year clphsg_all eu_lnclg
*Trend Terms
gen t = year-1962
gen t2 = t*t
gen t3 = t2*t

#delimit;

* 1963-87 Regressions and Predictions ;
reg clphsg_all t eu_lnclg if year<1988;
predict gap6387;
label variable gap6387 "Katz-Murphy Predicted Wage Gap: 1963-1987 Trend" ;

* 1963-18 Regressions and Predictions ;
reg clphsg_all t eu_lnclg;
predict gap_linear;
label variable gap_linear "Fitted gap with linear time trend";

reg clphsg_all t t2 eu_lnclg;
predict gap_quadratic;
label variable gap_quadratic "Fitted gap with quadratic time trend";

reg clphsg_all t t2 t3 eu_lnclg;
predict gap_cubic;
label variable gap_cubic "Fitted gap with cubic time trend" ;

* Exponentiate and plot the quadratic series;
gen exp_gap_quadratic = 100*(exp(gap_quadratic)-1);
gen exp_clphsg_all=(exp(clphsg_all)-1)*100;
sort year;
label var exp_clphsg_all "Measured Gap";
label var exp_gap_quadratic "Predicted by Supply-Demand Model";
list year exp_clphsg_all exp_gap_quadratic;

/*
scatter exp_clphsg_all exp_gap_quadratic year, c(l l) msymbol (oh dh) 
xlabel(1964(3)2018, labsize(small)) legend(region(lstyle(none))) 
ylab(35(10)105) ytitle("College versus High-School Wage Gap (Percent)") 
ti("Percentage Hourly Earnings Gap between College and High-School Workers, 1963 - 2017",
size(medsmall)) legend(size(vsmall)) saving("`dir'/fig-KM-quadratic-1963-2017-expo.gph", replace);
*/

graph twoway scatter exp_clphsg_all exp_gap_quadratic year, c(l l) msymbol (oh dh) 
xlabel(1964(3)2018, labsize(tiny)) legend(region(lstyle(none))) 
ylab(35(10)105,labsize(small)) 
xtitle("Earnings year",size(small))
ytitle("College versus High-School Wage Gap (Percent)",size(small)) 
ti("Percentage Hourly Earnings Gap between College and High-School Workers, 1963 - 2017",size(small)) legend(size(vsmall))
graphregion(fcolor(white))
saving("`dir_Science'fig-KM-quadratic-1963-2017-expo-college.gph", replace);

graph export "fig-KM-quadratic-1963-2017-expo.pdf", replace;

graph twoway scatter clphsg_all gap_quadratic year, c(l l) msymbol (oh dh) 
xlabel(1964(3)2018, labsize(tiny)) legend(region(lstyle(none))) 
ylab(.35(.05).7,labsize(small)) 
xtitle("Earnings year",size(small))
ytitle("College versus High-School Wage Gap (Percent)",size(small)) 
ti("Log Weekly Earnings Gap between College and High-School Workers, 1963 - 2017",size(small)) legend(size(vsmall))
graphregion(fcolor(white))
saving("`dir_Science'fig-KM-quadratic-1963-2017-ln-college.gph", replace);

save km-plot-6317, replace;
keep year clphsg_all eu_lnclg;
list;
save km-cg-rsup-6317, replace;
d;
list;	
log close;
