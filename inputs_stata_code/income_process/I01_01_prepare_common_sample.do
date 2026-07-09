* Prepare the common cleaned PSID sample used by all income-process variants.

capture confirm file "income_process/I01_00_config.do"
if !_rc {
    do "income_process/I01_00_config.do"
}
else {
    capture confirm file "I01_00_config.do"
    if !_rc {
        do "I01_00_config.do"
    }
    else {
        do "inputs_stata_code/income_process/I01_00_config.do"
    }
}
local measure "$IP_MEASURE"

display as text "=== STAGE 1: PSID common sample selection ==="
use "$IP_PSID_PATH", clear
rename hours hdshours

* --- CPI deflator (Jan 2000 base) ---
gen     price=22.6 	if year==1970
replace price=23.5 	if year==1971
replace price=24.3 	if year==1972
replace price=25.8 	if year==1973
replace price=28.6 	if year==1974
replace price=31.3 	if year==1975
replace price=33.1 	if year==1976
replace price=35.2 	if year==1977
replace price=37.9 	if year==1978
replace price=42.2 	if year==1979
replace price=47.8 	if year==1980
replace price=52.8 	if year==1981
replace price=56.1 	if year==1982
replace price=57.8 	if year==1983
replace price=60.4 	if year==1984
replace price=62.5 	if year==1985
replace price=63.7 	if year==1986
replace price=66.0 	if year==1987
replace price=68.7 	if year==1988
replace price=72.0 	if year==1989
replace price=75.9 	if year==1990
replace price=79.1 	if year==1991
replace price=81.5 	if year==1992
replace price=83.9 	if year==1993
replace price=86.1 	if year==1994
replace price=88.5 	if year==1995
replace price=91.1 	if year==1996
replace price=93.2 	if year==1997
replace price=96.7 	if year==1999
replace price=102.8 if year==2001
replace price=106.9 if year==2003
replace price=113.4 if year==2005
replace price=120.4 if year==2007
replace price=124.6 if year==2009
replace price=130.6 if year==2011
replace price=135.3 if year==2013
replace price=137.6 if year==2015
replace price=142.4 if year==2017
replace price=148.5 if year==2019
replace price=157.3 if year==2021
replace price = price/100

* --- Income definition (same for both variants) ---
* hhslabinc = all household labor income including business
gen hhslabinc       = wife_labinc_exc + wife_labinc_bus + wife_assinc_bus + wife_farm + hdslabinc_exc + hdslabinc_bus + hdsassinc_bus if year > 1993
replace hhslabinc   = wife_labinc_inc + hdslabinc_inc + total_assinc_bus  if year < 1993
replace hhslabinc   = wife_labinc_inc + hdslabinc_inc + wife_assinc_bus + hdsassinc_bus  if year == 1993

gen hhsinc_bus      = wife_assinc_bus + wife_labinc_bus + hdslabinc_bus + hdsassinc_bus if year > 1993
replace hhsinc_bus  = hdslabinc_bus + total_assinc_bus if year < 1993
replace hhsinc_bus  = hdslabinc_bus + wife_assinc_bus + hdsassinc_bus  if year == 1993

gen hhshours = hdshours + hours_wife
gen avghourlyhh = hhslabinc / hhshours

* --- Deflate ---
replace avghourlyhh = avghourlyhh / price
replace hhsinc_bus  = hhsinc_bus / price
replace hhslabinc   = hhslabinc / price

* --- Preliminary cleaning ---
rename pid person
sort person year

gen y = `measure'

sort person year
by person: gen dyear = year - year[_n-1]
replace dyear = dyear / 2 if year > 1998

egen todrop = sum(dyear > 1 & dyear != .), by(person)
egen n = sum(person != .), by(person)
replace todrop = 1 if n == 1
drop if todrop > 0
drop todrop dyear n

drop if year < 1970
replace age = age - 1
drop if age > 65
drop if age < 20

* --- Education coding ---
gen     sc = .
replace sc = 1 if educ >= 0  & educ <= 11
replace sc = 2 if (educ == 12 | educ == 13)
replace sc = 3 if educ >= 14 & educ <= 17
replace sc = . if educ > 17
drop educ
rename sc educ

sort person year
qui by person: replace educ = educ[_n-1] if educ == .
gsort person -year
qui by person: replace educ = educ[_n-1] if educ == .
sort person year

egen maxed = max(educ), by(person)
gen educ2 = educ
replace educ = maxed
drop maxed

* --- Birth year ---
drop if age > 110
egen lasty = max(year), by(person)
gen lastage = age if year == lasty
gen b = year - lastage
replace b = 0 if b == .
egen yb = sum(b), by(person)
replace age = year - yb
drop lasty lastage b

* --- Outlier removal ---
local gy_max  5.00
local gy_min -0.80
local y_max  250
local y_min  2
local inc_max  1000000
local inc_min  1000
local hours_max 999999
local hours_min 260
local times_min 4

sort person year
qui by person: gen gy = (`measure' - `measure'[_n-1]) / (`measure'[_n-1])
replace gy = sqrt(gy) if year > 1998 & mi(gy)

gen m = gy > `gy_max' & gy != . | gy < `gy_min' & gy != . | ///
        y > `y_max' & y != . | y < `y_min' & y != . | ///
        hhshours < `hours_min' & hhshours != . | hhshours > `hours_max' & hhshours != . | ///
        hhslabinc < `inc_min' & hhslabinc != . | hhslabinc > `inc_max' & hhslabinc != .
egen mm = sum(m), by(person)
drop if mi(`measure')
drop if m > 0

egen n = sum(person != .), by(person)
gen todrop = 0
replace todrop = 1 if n < `times_min'
drop if todrop > 0

drop if yb < 1926
drop if yb > 1986

gen cohort = floor((yb - 1) / 5)

* Save common sample before variant-specific filtering
save "$IP_COMMON_SAMPLE", replace
display as text "Saved common sample: $IP_COMMON_SAMPLE"
