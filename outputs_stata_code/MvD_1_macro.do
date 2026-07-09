capture mkdir data

//this dofile graphs following macro variables:
// irr      // avg_hours    // benefits

// (additional possible graphs, not in the paper)
// iy_ratio // gdp 			// subsidy_share   // ky_ratio

// combine model and data files, merge them all into one file, then graph
// irr (data)
if $download_data == 1 {
	capture dbnomics import , provider(GGDC) dataset(penn10/irr.USA) clear
	ren (period value ) (year irr_data)
	keep year irr_data
	destring _all, replace ignore(NA)
	tsset year
	quietly tsfilter hp irr_cycle	= irr_data, smooth($lam) trend(irr_trend) //Smooth-out the irr
	replace irr_data = irr_trend*100
	gen fiveyear = floor(year/5)*5
	collapse (mean) irr_data (first) year, by(fiveyear) //Get the avg of 1-yr irr over 5 yrs
	save data/irr_data.dta, replace
}
use data/irr_data.dta, clear

preserve
// irr (model)
		tempfile model_data
		import delimited $resultspath\\$scenario\\irr_trans_1y.txt, clear
		ren v1 irr_model
		gen year = 5*_n + 1935 - 5
	save `model_data', replace
restore
merge 1:1 year using `model_data'
drop _merge
preserve

// benefits (data, two sources: DBnomics from CBO for past data, CBO from CBO for projections)
	tempfile data
	if $download_data == 1 {
		capture dbnomics import , provider(CBO) dataset(51134-MO/SS.PGDP) clear
		rename value benefits_data
		rename period year
		destring year benefits_data, replace
		keep year benefits_data
		replace year = 1960 if year == 1962
		drop if year > 2020
		periods
		collapse (mean) benefits_data (first) year, by(fiveyear)
		gen source = "data"
		save data/benefits_cbo.dta, replace
	}
	use data/benefits_cbo.dta, clear
	save `data'

	tempfile ss_projection
	*import excel "https://www.cbo.gov/system/files/2022-07/57971-Data.xlsx", sheet("Supp Data 1-1") cellrange(A8:C39) firstrow clear // this is the original source of the data
	import excel ..\inputs_stata_code\social_security\57971-Data.xlsx, sheet("Supp Data 1-1") cellrange(A8:C39) firstrow clear
		rename A year
		gen ss_deficit = Revenuesa - Outlaysb
		rename Outlaysb benefits_proj
		replace year = 2020 if year == 2022

	periods_proj
	collapse (mean) benefits ss_deficit (first) year, by(fiveyear)
	gen source = "projection"
	save `ss_projection', replace

// benefits model
	tempfile model_data
		import delimited $resultspath\\$scenario\\benefits_trans.txt, clear
		ren v1 benefits_model
		replace benefits_model = benefits_model * 100
		gen year = 5*_n + 1935 - 5
	save `model_data'

restore
merge 1:1 year using `model_data'
drop _merge
merge 1:1 year using `data'
drop _merge
merge 1:1 year using `ss_projection'
drop _merge


preserve

// average hours (data)
	tempfile data
	if $download_data == 1 {
		tempfile oecd_wap
		capture dbnomics import, provider(OECD) dataset(DSD_POPULATION@DF_POP_HIST) series(USA.POP.PS._T.Y20T64.H) clear
			keep value period
			destring value period, replace
			replace value = value / 1000000
			gen name = "wa_pop"
			reshape wide value, i(period) j(name) string
			rename valuewa_pop wap
		save `oecd_wap'

		capture dbnomics import , provider(GGDC) dataset(penn10) series(avh.USA,emp.USA) clear
			/* note: data for K/Y ratio, real VA per capita, and I/Y ratio can be obtained analogously from GGDC */
			/* rnna.USA,csh_i.USA,irr.USA,rgdpna.USA,pop.USA */
			keep value period subject
			reshape wide value, i(period) j(subject) string
			gen tothours = valueemp * valueavh
			merge 1:1 period using `oecd_wap'
			gen avghours_data = tothours/ wap
			* renormalize hours
			rename period year
			keep avghours_data year
			periods

			quietly tsfilter hp avghours_cycle	= avghours, smooth($lam) trend(avghours_trend)
			replace avghours_data = avghours_trend
			sum avghours_data  if inrange(year,1950,2015)
			replace avghours_data = (avghours_data / `r(mean)' ) * 100

		collapse (mean) avghours_data (first) year, by(fiveyear)
		save data/avghours_data.dta, replace
	}
	use data/avghours_data.dta, clear
	save `data'

// average hours (model)
	tempfile model_data
		import delimited $resultspath\\$scenario\\avg_hours_trans.txt, clear
		ren v1 avghours_model
		gen year = 5*_n + 1935 - 5
		replace avghours_model = avghours_model
		sum avghours_model  if inrange(year,1950,2015)
		replace avghours_model = (avghours_model / `r(mean)' ) * 100
	save `model_data'

restore
merge 1:1 year using `data'
drop _merge
merge 1:1 year using `model_data'
drop _merge




************************************************
***** GRAPHING *********************************
************************************************



preserve
keep if inrange(year,1950, 2050)
tsset year

foreach v in irr   {
	sum `v'_data
	local low  = floor(`r(min)') - floor(7* `r(sd)')
	local high = floor(`r(max)') + floor(7* `r(sd)')
twoway		(tsline `v'_data, lcolor(gs12) lwidth(thick)) ///
			(tsline `v'_model, lcolor(black) lwidth(medthick))  ///
if inrange(year,1950,2015) , ///
		legend(cols(2) order(1 "Data"  2 "Baseline model")  position(11) ) ///
	 	xlabel(1950[15]2015, labsize(*1.2) ) ///
		xtitle("") ///
		xscale(range(1950 2015)) ///
		yscale(range(`low' `high')) ///
		ylabel(`low'[1]`high', labsize(*1.2)) xtitle(, size(*1.2)) xtitle(, size(*1.2))  ///
		xsize(7.5) ysize(3)  ylabel(, labsize(*1.2)  angle(h) gstyle(dot) glcolor(grey)) ///
		name(`v', replace)

graph export $graphspath\\`v'_trans_levels.png, replace
graph export $graphspath\\`v'_trans_levels.eps, replace
graph export $graphspath\\`v'_trans_levels.svg, replace

}


foreach v in  avghours  {
	sum `v'_data
	local low  = floor(`r(min)') - floor(`r(sd)')
	local high = floor(`r(max)') + floor(2* `r(sd)')
twoway		(tsline `v'_data, lcolor(gs12) lwidth(thick)) ///
			(tsline `v'_model, lcolor(black) lwidth(medthick))  ///
if inrange(year,1950,2015) , ///
		legend(cols(2) order(1 "Data"  2 "Baseline model")  position(11) ) ///
	 	xlabel(1950[15]2015, labsize(*1.2) ) ///
		xtitle("") ///
		xscale(range(1950 2015)) ///
		yscale(range(`low' `high')) ///
		ylabel(`low'[2]`high', labsize(*1.2)) xtitle(, size(*1.2)) xtitle(, size(*1.2))  ///
		xsize(7.5) ysize(3)  ylabel(, labsize(*1.2)  angle(h) gstyle(dot) glcolor(grey)) ///
		name(`v', replace)

graph export $graphspath\\`v'_trans_levels.png, replace
graph export $graphspath\\`v'_trans_levels.eps, replace
graph export $graphspath\\`v'_trans_levels.svg, replace

}



sum benefits_model if inrange(year,1950, 2050)
	local low  = floor(`r(min)') - floor(`r(sd)')
	local high = floor(`r(max)') + floor(`r(sd)')

twoway  ///
	(tsline benefits_data  if inrange(year,1950,2020) , lcolor(gs12) lwidth(thick)) ///
	(tsline benefits_proj  if inrange(year,2020,2050) , lcolor(gs12) lwidth(thick) lpattern(dash)) ///
	(tsline benefits_model if inrange(year,1950,2020) , lcolor(black) lwidth(medthick))  ///
	(tsline benefits_model if inrange(year,2020,2050) , lcolor(black) lwidth(medthick) lpattern(dash))  ///
	if inrange(year,1950, 2050)	, ///
		legend(cols(2) order(1 "Data"  3 "Baseline model")  position(11) ) ///
	 	xlabel(1950[15]2060, labsize(*1.2) ) ///
		xtitle("") ///
		xscale(range(1950 2060)) ///
		yscale(range(`low' `high')) ///
		ylabel(`low'[1]`high', labsize(*1.2)) xtitle(, size(*1.2)) xtitle(, size(*1.2))  ///
		xsize(7.5) ysize(3)  ylabel(, labsize(*1.2)  angle(h) gstyle(dot) glcolor(gray)) ///
		name(benefits, replace)

graph export $graphspath\\benefits_trans_levels.png, replace
graph export $graphspath\\benefits_trans_levels.eps, replace
graph export $graphspath\\benefits_trans_levels.svg, replace
