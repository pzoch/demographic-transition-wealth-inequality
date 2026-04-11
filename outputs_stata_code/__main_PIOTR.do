global resultspath 	"..\fortran_code\Results\"
global graphspath 	"..\graphs\outputs\"
global datapath 	"..\data\"

global year_start 1935
global year_stop 2100 
global lam=500 

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
do R_Figure2.do 		//  lines with labels (Figure 2)
capture mkdir "../graphs/_MT_main"
graph export "../graphs/_MT_main/all.png", replace

global variant_base "psid_all_govt__"
global variant_comp "psid_ndo_govt__ psid_ndm_govt__ psid_nds_govt__"
do R_Figure3.do 		//  bars for demographic sub-scenarios (Figure 3)

global variant_base "psid_all_govt__"
global variant_comp "psid_ndm_govt__ psid_nlb_govt__ psid_ntx_govt__ psid_nts_govt__"
do R_Figure4.do 		//  bars for all "big" scenarios (Figure 4)

** Do graphs for Appendix B -- Calibration
cd ..\inputs_stata_code
global year_start 1935 // set initial year
global year_stop  2100 // set final year

* PWT inputs;
global lam=500 						
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

erase ../inputs_stata_code/bone.dta
erase ../inputs_stata_code/bone1y.dta

cd ..\outputs_stata_code


** Do graphs for Appendix C -- Populations
cd ..\inputs_stata_code
do ..\inputs_stata_code\demography\hetero_pi\D03_prepare_hetero_pi 
do ..\inputs_stata_code\demography\mortality\D01_life_tables 
cd ..\outputs_stata_code

** Do graphs for Appendix D -- Model vs Data 
global scenario		"psid_all_govt__"

global year_start 1950
global year_stop  2010
global year_end   2100
global min_age 20
global max_age 65
do MvD_1_macro.do  
do MvD_2_Gini_income.do
do MvD_3_Gini_wealth.do
do MvD_4_GE_decomposition.do

** Do graphs for Appendix E -- Additional results
* E.1 Income inequality decomposition
global variant_base "psid_all_govt__"
global variant_comp "psid_nlb_govt__ psid_ncs_govt__ psid_ncp_govt__ psid_nsh_govt__"
do R_Figure_AppE_Income.do

* E.2 Taxes decomposition
global variant_base "psid_all_govt__"
global variant_comp "psid_ntx_govt__ psid_ntl_govt__ psid_ntc_govt__ psid_ntk_govt__ psid_ntp_govt__"
do R_Figure_AppE_Taxes.do

* E.3 Technology decomposition
global variant_base "psid_all_govt__"
global variant_comp "psid_nts_govt__ psid_nls_govt__ psid_nga_govt__ psid_ndp_govt__"
do R_Figure_AppE_Tech.do

** Do graphs for Appendix F -- Sensitivity
capture mkdir "../graphs/_MT_robust"

* F.1 Higher intertemporal elasticity of substitution (CRR calibration)
global variant_base "crr3_all_govt__"
global variant_comp "crr3_ndm_govt__"
do R_Figure2.do
graph export "../graphs/_MT_robust/crr3.png", replace

* F.2 Heterogeneous rates of return
global variant_base "hrat_all_govt__"
global variant_comp "hrat_ndm_govt__"
do R_Figure2.do
graph export "../graphs/_MT_robust/hrat.png", replace

* F.3 Model without discount factor shocks
global variant_base "ndel_all_govt__"
global variant_comp "ndel_ndm_govt__"
do R_Figure2.do
graph export "../graphs/_MT_robust/ndel.png", replace

* F.4 Income process without superstars
global variant_base "nstr_all_govt__"
global variant_comp "nstr_ndm_govt__"
do R_Figure2.do
graph export "../graphs/_MT_robust/nstr.png", replace

* F.5 Higher productivity growth (CBO parameters)
do ../sensitivity_stata_code/exog_rate/M02robustness_prepare_gamma //prepare inputs for simulation
global variant_base "gcbo_all_govt__"
global variant_comp "gcbo_ndm_govt__"
do R_Figure2.do
graph export "../graphs/_MT_robust/gcbo.png", replace

* F.6 Exogeneous interest rate
do ../sensitivity_stata_code/exog_rate/M04prepare_exog_rate //prepare inputs for simulation
global variant_base "exor_all_govt__"
global variant_comp "psid_all_govt__"
do R_Figure_F6_exograte.do

* F.7 Unequal distribution of bequests
global variant_base "beqs_all_govt__"
global variant_comp "beqs_ndm_govt__"
do R_Figure2.do
graph export "../graphs/_MT_robust/beqs.png", replace
