log using taba1_a2_figa1_1914_2017,t replace
*Autor-Goldin-Katz (2020 AEA P&P) -- inputs for Tables A1 and A2 and Figure A1
*Regressions for Table A1, output used for Table A2, and plot for Figure A1
*Katz-Murphy College Plus/HS Wage Premium Regressions for GK RBET Table 8.2 updated to 2017
*1914 to 2017
*1914, 1939, 1949, 1959 Data from 1915 Iowa and U.S. Censuses
*1963-2005 from March CPS AKK
*1914 to 2005 Data same at Table 8.2 of Goldin and Katz (The Race Between Education and Technology, 2008)
*1914 to 2005 from colhs1405.dta
*2006-2017 from 2007-2018 March CPS from Autor (2019 Ely Lecture, AEA P&P 2019) using km-cg-rsup-6317.dta
*College Plus Wage Premium and Relative College Equiv Supply in Efficiency Units
*Look at college wage premium and relative supply changes


set more 1
set mem 50m
use colhs1405
d
list year wprem2 relsup
merge year using km-cg-rsup-6317
tab _merge
sort year
list

*Add 2006 to 2017 from Autor (2019)
*Use 2005 as base year for splicing and use Autor update for changes 2005 to 2017
*wprem2 - clphsg_all = .0037398 in 2005
replace wprem2 = clphsg_all + .0037398 if year>=2006
*relsup - eu_lnclg = .0152795 in 2005
replace relsup = eu_lnclg + .0152795 if year>=2006

list

gen time = year - 1914
gen t49 = max(year-1949,0)
gen t59 = max(year-1959,0)
gen t92 = max(year-1992,0)
gen tsq = time*time/10
gen t3 = tsq*time/10
gen t4 = t3*time/10
gen t5 = t4*time/10
gen d49 = year==1949


*College Wage Premium, 1914-2017, wprem2, young males for 1914-39 college premium change
*Col. (1)
reg wprem2 relsup time t49 t92
*Col. (2)
reg wprem2 relsup time t59 t92
predict pred2
*Col. (3)
reg wprem2 relsup time t59 t92 d49
predict pred3
*Col. (4)
*Shift in Relative Supply Coeff After 1949
gen relsup49 = relsup
replace relsup49 = 0 if year<=1949
reg wprem2 relsup relsup49 time t59 t92 d49

*Log Relative Deamnd Based on Col. (2) estimate of implied sigma of 1.62
gen demand2 = relsup + 1.62*wprem2
*Inputs for Table A2
list year wprem2 relsup demand2

*1914 to 2005
reg wprem2 relsup time t59 t92 if year<=2005

label variable wprem2 "Actual"
label variable pred2 "Predicted, col. (2)"
label variable year " "

save colhs1417_new, replace
*Figure A1
line wprem2 pred2 year, c(l l) ti("Actual vs. Predicted College Wage Premium, 1914 to 2017") xlabel(1914(15)2017) l1("Ln College/HS Wage Premium") saving(figure_a1, replace)
keep year wprem2 pred2
rename wprem2 wprem2_17
label data "College Plus/HS Premium, 1914-2017"
label variable wprem2_17 "Col Grad+/HS Wage Diff"
save wprem2_17,replace
log close
