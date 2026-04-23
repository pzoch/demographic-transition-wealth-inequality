set more off
set scheme burd    // match __main.do; produces clean-white calibration plots under graphs/inputs/

* set initial and final years
global year_start 1935
global year_stop 2100
global download_data 0		// 0 = load local .dta (default), 1 = re-download from dbnomics

cd "`c(pwd)'"
clear
do _prepare_programs.do					// this keeps routines that are repeated between dofiles

global f_results "" // paste here the path for your results output from Fortran if you want to compare model to data 
* currently the dofiles use our outputs


*** PROCESS DATA - FORTRAN INPUTS;
* PWT inputs;
global bsource "."
do depreciation/M01prepare_depr			
do tfp/M02prepare_gamma					
do labor_share/M03prepare_labor_share	
do ../sensitivity_stata_code/exog_rate/M04prepare_exog_rate		//this is just robustness, never frozen

* skill premium and high/low shares;
do skill_premium/H01prepare_skill_premium 
*college share
do skill_premium/D02_prepare_college 

* taxes and contributions;
do tax_rate/T01prepare_taxes		
do social_security/T02prepare_contributions		
do tax_rate/T03prepare_tax_lambda 

capture erase bone.dta
capture erase bone1y.dta


