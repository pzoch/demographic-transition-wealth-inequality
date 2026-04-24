global resultspath 	"..\fortran_code\Results\"
global graphspath 	"..\graphs\outputs\"
global datapath 	"..\data\"

global year_start 1935
global year_stop 2100
global download_data 0		// 0 = load local .dta (default), 1 = re-download from dbnomics 

do _prog_coding.do
do _prog_ineq_function.do
do _prep_Gini_data.do

set scheme burd

** Prepare data from the model simulation
local scenario		"psid_all_govt__"

import delimited  $resultspath\\`scenario'\\mass_trans_small.csv, clear 
	drop if inc_shock==6
	keep if mass > 0
	keep mass year age labinc_pretax sav
	replace year = 5*year + 1935- 5
	replace age = 5*age + 20 
	keep if inrange(year,$year_start,$year_stop)
	gen source = "Model"
	compress

save ..\data\model_`scenario', replace

** Do graphs for the main text
global scenario		"psid_all_govt__"
do R_Figure1.do 		//  model vs data Gini change to 1950 (Figure 1)

global variant_base "psid_all_govt__" 
global variant_comp "psid_ndm_govt__"  
global r1 70 
global r2 78
do R_Figure2.do 		//  lines with labels (Figure 2)
graph export $graphspath\\Results_Gini_counterfactuals.png, replace 


global variant_base "psid_all_govt__" 
global variant_comp "psid_ndm_govt__ psid_nds_govt__ psid_ndo_govt__ "   
global legend `"legend(order(1 "[S1] Longevity:1955" 2 "[S1a] ExpectedLongevity:1955" 3 "[S1b] PopStructure:1955" ) cols(3))"'
global colors "purple pink orange_red"
do R_Figure3.do 		//  bars for population scenarios (Figure 3)
graph export $graphspath\\Results_Gini_drivers_demographics.png, replace 

global variant_base "psid_all_govt__" 
global variant_comp "psid_ndm_govt__ psid_nlb_govt__ psid_ntx_govt__ psid_nts_govt__ "  
global legend `"legend(order(1 "[S1] Longevity:1955" 2 "[S2] IncomeINEQ:1955" 3 "[S3] Taxes:1955" 4 "[S4] Technology:1955") cols(4))"'
global colors "purple blue orange green"
do R_Figure3.do 		//  bars for population scenarios (Figure 4)
graph export $graphspath\\Results_Gini_drivers_comparison.png, replace 


** Do graphs for Appendix B -- Calibration
cd ..\inputs_stata_code
global year_start 1935 // set initial year
global year_stop  2100 // set final year

* PWT inputs;
global bsource "../outputs_stata_code/"
do ../inputs_stata_code/depreciation/M01prepare_depr			
do ../inputs_stata_code/tfp/M02prepare_gamma					
do ../inputs_stata_code/labor_share/M03prepare_labor_share	

* skill premium and high/low shares;
do ../inputs_stata_code/skill_premium/H01prepare_skill_premium 
*college share
do ../inputs_stata_code/skill_premium/D02_prepare_college 

* taxes and contributions;
do ../inputs_stata_code/tax_rate/T01prepare_taxes		
do ../inputs_stata_code/social_security/T02prepare_contributions		
do ../inputs_stata_code/tax_rate/T03prepare_tax_lambda 

erase $bsource/bone.dta
erase $bsource/bone1y.dta

cd ..\outputs_stata_code


** Do graphs for Appendix C -- Populations
* D01/D03 moved to inputs_stata_code/__main_data_prepare.do — they produce
* Fortran inputs and belong in the input pipeline, not in the output driver.
* Figure B.2 (LE50year.png) is produced there as a side-effect of D03.
* Figure C.1 (population pyramids) stays here because it reads Fortran's
* population.csv, which only exists after the model has run.
global variant_base "psid_all_govt__"
global variant_comp "psid_ndm_govt__"
do R_FigureC1_popstructure.do

** Do graphs for Appendix D -- Model vs Data 
global scenario		"psid_all_govt__"

global year_start 1950
global year_stop  2020
global year_end   2100
global min_age 20
global max_age 65
do MvD_1_macro.do  
do MvD_2_Gini_income.do
do MvD_3_Gini_wealth.do
do MvD_4_GE_decomposition.do

** Do graphs for Appendix E -- Additional results
* combine all scenarios gini_trans.csv from all relevant folders

*Income inequality
global variant_base "psid_all_govt__" 
global variant_comp "psid_nlb_govt__ psid_ncs_govt__ psid_ncp_govt__ psid_nsh_govt__"  
global legend `"legend(order(1 "[S2] IncomeINEQ:1955" 2 "[S2a] CollegeShare:1955 " 3 "[S2b] CollegePremium:1955" 4 "[S2c] Shocks:Initial" ) cols(4))"'
global colors "blue emidblue purple%30 eltblue "
do R_Figure3.do				// Figure E.1.
graph export $graphspath\\Results_Gini_drivers_incomes.png, replace 

*Taxes
global variant_base "psid_all_govt__" 
global variant_comp "psid_ntx_govt__ psid_ntl_govt__ psid_ntc_govt__ psid_ntk_govt__ psid_ntp_govt__"  
global legend `"legend(order(1 "[S3] Taxes:1955" 2 "[S3a] {&tau}{sub:L}:1955 " 3 "[S3b] {&tau}{sub:C}:1955" 4 "[S3c] {&tau}{sub:K}:1955" 5 "[S3d] Progressivity:1955" ) cols(3))"'
global colors "orange orange_red*0.5 dkorange*0.5 dkorange orange_red "
do R_Figure3.do				// Figure E.2.
graph export $graphspath\\Results_Gini_drivers_taxes.png, replace 

*Macroeconomic trends // 
global variant_base "psid_all_govt__" 
global variant_comp "psid_nts_govt__ psid_nls_govt__ psid_nga_govt__ psid_ndp_govt__ "  
global legend `"legend(order(1 "[S4] Technology:1955" 2 "[S4a] LabShare:1955" 3 "[S4b] TFP:1955" 4 "[S4c] Depr:1955" ) cols(4))"'
global colors "dkgreen dkgreen*0.5 dk_green*0.3 green  " 
do R_Figure3.do				// Figure E.3.
graph export $graphspath\\Results_Gini_drivers_macro.png, replace

** Do graphs for Appendix F -- Sensitivity
* Higher intertemporal elasticity of substitution
global variant_base "crr3_all_govt__" 
global variant_comp "crr3_ndm_govt__" 
global r1 68 
global r2 74
do R_Figure2.do 		//  Figure F.1
graph export $graphspath\\AppF_Gini_counterfactuals_theta.png, replace 

* Heterogeneous rates of return
global variant_base "hrat_all_govt__" 
global variant_comp "hrat_ndm_govt__"
global r1 70 
global r2 80
do R_Figure2.do 		//  Figure F.2
graph export $graphspath\\AppF_Gini_counterfactuals_hetrates.png, replace 

* Model without discount factor shocks
global variant_base "ndel_all_govt__" 
global variant_comp "ndel_ndm_govt__" 
global r1 49
global r2 70
do R_Figure2.do 		//  Figure F.3
graph export $graphspath\\AppF_Gini_counterfactuals_homogendelta.png, replace 


* Income process without superstars
global variant_base "nstr_all_govt__"    
global variant_comp "nstr_ndm_govt__"   
global r1 67 
global r2 76
do R_Figure2.do 		//  Figure F.4
graph export $graphspath\\AppF_Gini_counterfactuals_nosuperstars.png, replace 

* Higher productivity growth
cd ..\inputs_stata_code
global bsource "../outputs_stata_code/"
do _prepare_programs
do tfp/M02robustness_prepare_gamma
erase $bsource/bone.dta
erase $bsource/bone1y.dta
cd ..\outputs_stata_code

global variant_base "gcbo_all_govt__" 
global variant_comp "gcbo_ndm_govt__" 
global r1 70 
global r2 77
do R_Figure2.do 		//  Figure F.6
graph export $graphspath\\AppF_Gini_counterfactuals_gamma.png, replace 


* Exogeneous interest rate (M04 needs bone1y.dta; regenerate via _prepare_programs
* because the preceding M02robustness block erases it at lines 173-174).
cd ..\inputs_stata_code
do _prepare_programs
do ../sensitivity_stata_code/exog_rate/M04prepare_exog_rate //prepare inputs for simulation
erase bone.dta
erase bone1y.dta
cd ..\outputs_stata_code
global scenario		"psid_all_govt__ exor_all_govt__"
do R_Figure1_app.do 		//  Figure F.7
graph export $graphspath\\AppF_Gini_counterfactuals_exograte.png, replace 

* Unequal distribution of bequests
global variant_base "beqs_all_govt__" 
global variant_comp "beqs_ndm_govt__" 
global r1 69 
global r2 77
do R_Figure2.do 		//  Figure F.8
graph export $graphspath\\AppF_Gini_counterfactuals_beq.png, replace 

