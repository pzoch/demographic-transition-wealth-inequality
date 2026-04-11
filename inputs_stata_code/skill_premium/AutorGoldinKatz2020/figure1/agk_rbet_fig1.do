log using agk_rbet_fig1, t
use prem_1820_2012
d
drop _merge
merge year using  wprem2_17
list year wprem2 wprem2_17 hs128 lwrclpr
#delimit ;
scatter wprem2_17 hs128 lwrclpr year, c(l l l) xlabel(1825(19)2017) ylabel(0(.1).7)
ti("Education/Skill Log Wage Premia, 1825-2017") l1("Log Wage Differential") s(oh ph dh) saving(agk_rbet_fig1,replace);
log close;
