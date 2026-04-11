********************************************************************
********************************************************************
capture program drop ours_ineqdeco
program ours_ineqdeco, sortpreserve rclass 

syntax varname(numeric) [aweight fweight pweight iweight] [if] [in] ///
	, Beta(real) [ BYgroup(varname numeric) Welfare Summarize]

if "`summarize'" != "" local summ "summ" 
if "`welfare'" != ""    local w "w" 
local inc "`varlist'"

di "BETA: ", "`beta'"

tempvar fi totaly py gini wgini im1 i0 i1 i2                 	///
  nk vk fik meanyk varyk lambdak loglamk lgmeank             	///
  thetak im1k i0k i1k i2k  ginik pyk                         	///
  im1b i0b i1b i2b  wginik i_beta i_beta_k with_beta  i_beta_b ///
  withm1 with0 withh with1 with2  wi first  

if "`weight'" == "" gen byte `wi' = 1
else gen `wi' `exp'

marksample touse
if "`bygroup'" != "" markout `touse' `bygroup'

qui count if `touse'
if r(N) == 0 error 2000

lab var `touse' "All obs"
lab def `touse' 1 " "
lab val `touse' `touse'

if "`bygroup'" != "" {
	capture levelsof `bygroup' if `touse' , local(gp)
	qui if _rc levels `bygroup' if `touse' , local(gp)
	foreach x of local gp {
		if int(`x') != `x' | (`x' < 0) { 
			di as error "`bygroup' contains non-integer or negative values"
			exit 459
		}
	}
}

set more off
	
quietly {

	count if `inc' < 0 & `touse'
	noi if r(N) > 0 {
		di " "
		di as txt "Warning: `inc' has `r(N)' values < 0." _c
		di as txt " Not used in calculations"
	}
	
	count if `inc' == 0 & `touse'
	noi if r(N) > 0 {
		di " "
		di as txt "Warning: `inc' has `r(N)' values = 0." _c
		di as txt " Not used in calculations"
	}
	
	replace `touse' = 0 if `inc' <= 0  // this replaces former 'badinc' stuff

	noi if "`summ'" != "" {
		di " "
		di as txt "Summary statistics for distribution of " _c
		di as txt "`inc'" ": all valid cases"
		sum `inc' [w = `wi'] if `touse', de
	}
	else  sum `inc' [w = `wi'] if `touse', det
	
	local sumwi = r(sum_w)
	local meany = r(mean)
	local vary = r(Var) 
	local sdy = r(sd)

	return scalar mean = r(mean)
	return scalar Var = r(Var)
	return scalar sd = r(sd)
	return scalar sumw = r(sum_w)
	return scalar N = r(N)
	return scalar min = r(min)
	return scalar max = r(max)

	gen double `fi' = `wi' / `sumwi' if `touse'

	gsort -`touse' `inc' 

	gen double `py' = (2 * sum(`wi') - `wi' + 1)/(2 * `sumwi' ) if `touse'


	egen double `i_beta' = sum(`fi' * (((`inc' / `meany')^`beta') - 1) /(`beta'*(`beta'-1))) if `touse'

	lab var `i_beta' "GE(`beta')"

	noi { 
		di "  "
		di as txt "Generalized Entropy indices GE(a), where a = income difference" 
		tabdisp `touse' in 1, c(`i_beta' ) f(%9.5f)
	}	

	// saved results compatible with previous versions of -ineqdeco-
	global S_i_beta = `i_beta'[1]
	return scalar ge = `i_beta'[1] 
		
*************************
* SUBGROUP DECOMPOSITIONS
*************************

if "`bygroup'" != "" {	

	qui {
		tempvar notuse
        gen byte `notuse' = -`touse'
		sort `notuse' `bygroup' `inc'

		by `notuse' `bygroup': gen byte `first' = _n == 1 if `touse'
		by `notuse' `bygroup': egen double `nk' = sum(`wi') if `touse'

		gen double `vk' = `nk' / `sumwi' if `touse'
	  	gen double `fik' = `wi' / `nk' if `touse'
		by `notuse' `bygroup': egen double `meanyk' = sum(`fik' * `inc') if `touse'
		by `notuse' `bygroup': egen double `varyk' = sum(`fik'* (`inc' - `meanyk')^2) if `touse'
		gen double `loglamk' = log(`meanyk') if `touse'
		gen double `lambdak' = `meanyk' / `meany' if `touse'
		gen double `lgmeank' = log(`meanyk') if `touse'
		gen double `thetak' = `vk' * `lambdak' if `touse'

		by `notuse' `bygroup': egen double `i_beta_k' = sum(`fik' * (((`inc' / `meanyk')^`beta') - 1) / (`beta'*(`beta'-1))) if `touse'
	}

	bysort `notuse' `bygroup' (`inc'): gen double `pyk' = (2 * sum(`wi') - `wi' + 1) / (2 * `nk' ) ///
		if `touse'

	lab var `vk' "Popn. share"
	lab var `meanyk' "Mean"
	lab var `lambdak' "Relative mean"
	lab var `thetak' "Income share"
	lab var `lgmeank' "log(mean)"
	lab var `i_beta_k' "GE(`beta')"
	
	capture levelsof `bygroup' if `touse' , local(group)
	qui if _rc levels `bygroup' if `touse' , local(group)

	return local levels "`group'"
	
	gsort -`first' `bygroup'
	local i = 1
	foreach k of local group	{
		return scalar ge_beta_`k' = `i_beta_k'[`i']

		return scalar mean_`k' = `meanyk'[`i']
		return scalar lgmean_`k' = `lgmeank'[`i']
		return scalar theta_`k' = `thetak'[`i']
		return scalar lambda_`k' = `lambdak'[`i']
		return scalar v_`k' = `vk'[`i']
		return scalar sumw_`k' = `nk'[`i']

		local ++i
	}

	drop `lgmeank' `thetak' `nk' `pyk' 

	egen double `with_beta' = sum(`fi' * `i_beta_k' * `lambdak'^`beta') if `touse'
	lab var `with_beta' "GE(`beta')"

	noi { 
		di "  "
		di as txt "Within-group inequality, GE_W(a)"
		tabdisp `touse' in 1 if `touse', c(`with_beta')  f(%9.5f)
	}	

	return scalar within = `with_beta'[1]

	** GE index between-group inequalities **

	egen double `i_beta_b' = sum(`fi' * (((`meanyk' / `meany')^`beta') - 1) / (`beta'*(`beta'-1))) if `touse'
	lab var `i_beta_b' "GE(`beta')"

	noi { 
		di "              "
		di as txt "Between-group inequality, GE_B(a):"
		tabdisp `touse' in 1 if `touse' , c(`i_beta_b')  f(%9.5f)
	}	
	return scalar between = `i_beta_b'[1]

	drop  `i_beta_b' 



} 	// end of  "`bygroup'"  block for subgroup decompositions


} 	// end quietly block

end
