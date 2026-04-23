* Clear any named graphs left over from MvD_1 (irr, avghours, benefits).
* Without this, subsequent `graph export` calls inside the lorenz loop can
* capture stale named graphs from memory instead of the freshly-drawn
* lorenz curve — Lorenz_<yr>.png files end up containing MvD_1's time-series
* plots. See docs/stata_pipeline_audit.md §14 diagnosis.
capture graph drop _all

	use ..\data\model_$scenario, clear
	ren labinc_pretax hhslabinc
	ren mass weight
 
	append using "..\data\PSID\psid_ready.dta"
	replace source = "PSID" if mi(source)
	replace hhslabinc = pure_labinc if source == "PSID"
	keep  year age source hhslabinc weight

	replace year = 5 * floor(year/5) if source == "PSID"  
	recode year (1975=1970)  (1985=1980)  (1995=1990)  (2005=2000)   (2015=2010)

	replace age = 5* floor((age)/5) if source == "PSID"

	keep if inrange(year,1970,2015) & inrange(age,$min_age ,$max_age ) 
	encode source, 	gen(sourcen) 		

levelsof year, local(yrs)
foreach yr in `yrs' {

	preserve
	keep if year == `yr'
	
	sum hhslabinc					if source=="PSID", det  
	replace hhslabinc = .		if ((hhslabinc > `r(p99)'  ) | hhslabinc < 0 ) & source=="PSID"
	sum hhslabinc					if source=="Model", det  
	replace hhslabinc = .		if ((hhslabinc > `r(p99)' ) | hhslabinc < 0 ) & source=="Model"

	keep if !mi(hhslabinc) & !mi(weight)  

	lorenz estimate hhslabinc  [pw=weight] ,  over(sourcen)  gini
	lorenz graph,  title("`yr'")  overlay  ci(nor)  legend(bplacement(nw) ring(0) cols(1)) ysize(1) xsize(1)
		graph export $graphspath\\Lorenz_`yr'.png, replace	
		graph export $graphspath\\Lorenz_`yr'.eps, replace		
		graph export $graphspath\\Lorenz_`yr'.svg, replace	

	restore
}
