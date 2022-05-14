! WHAT   : declare values for switches, ATTENTION! : they are overwritten in some subroutines (e.g. ret_age_dem_main etc.) !!!!to do in close future!!!!, clear (reset) global variables before next run of code 
! DO     : read initial values of switches and base (from base scenario run) values of basic variables
! RETURN : clean values for next run 

MODULE global_vars2
USE global_vars
USE get_data
use pfi_trans

IMPLICIT NONE
CONTAINS

subroutine globals 
    real, dimension(bigJ, bigT) :: ones
    real*8 :: pi_i_6, pi_6_6, pi_6_7, pi_7_7 ! super stars 
    

call chdir(cwd_r)


    
    
! switches related to income processes

    switch_sigma2_epsilon_t    =  1        ! transition path;  0 = sigma2_epsilon is constant; 1 = sigma2_epsilon is cohort specific; 2 = sigma2_epsilon is time specific
    switch_initial_dispersion   = 1        ! 0 = everybody is born the same; 1 = initial productivity is drawn from some distribution
  
    experiment_no             = 22
    ! pick experiments; 0 - everything, -1 - nothing, 1 - demography, 2 - labor tax (average and marginal), 3 - tfp, 4 - just longevity, 5 - just population growth, 6 - capital tax, 7 - shock variance, -2 everything but demographics. -4 demographics with different bequests, -5 all with different bequests,  -6 demo with zipf bequests and fixed labor supply,  -7 demo with different bequests and fixed labor supply
    !switch_mortality         = 1         ! 0 = no mortality on transition, 1 mortality according to data, 3 N according to data, pi as in first steady state, there would be baby boomers, 4 N1 == 1, pi as in the first steady state, 5, 6, 7 mortality and growth rate of young populaton set at the initial level 
    !switch_unstable_dem_ss   = 1         ! 0 = demography  in steady state is stable (fertility rate = 2), 1 unstable demography in steady state (based on UN), -1 unstable (set growth to its initial value)
    !switch_go_to_lower_gamma = 0         ! 0 = gamma = const = 2%, 1 empirical
    !switch_change_tauL       = 0         ! 0 = const,  1 = empirical -- warning: how will it interact with various closures?  
    !switch_change_lambda     = 0         ! 0 = const,  1 = empirical -- warning: how will it interact with various closures?     
    !switch_change_tauK       = 0         ! 0 = const,  1 = empirical -- warning: how will it interact with various closures?
    
    
!!! DEBUG_SWITCH
       switch_labor_choice      = 1         ! 0 = no labor choice (phi = 1) , 1 =  labor choice determined by 0<phi<1
       switch_cohort_ps         = 0         ! 0 = points pension system like us, 1 = the same benefits within a whole cohorts  
       switch_see_ret           = 0         ! 0 = agent sees no tax-benefit link; 1 = agent sees implicit savings
       switch_g_const           = 0         ! 0 = g keept as a fixed share of gdp, 1 = g keept as fixed in per capita terms 
       switch_fix_labor         = 0         ! if labor is fixed it is fixed to this number
       switch_tauK_gross        = 1         ! 0 = net return on capital is taxed, 1 = gross return on capital is taxed 
       switch_unequal_bequest   = 0         ! 0 - bequests given by people of age j to people with age j-1, distributed equally; 1 - bequests given by all people to j=1, unequal distribution
       switch_reduce_pension    = 0
       switch_increase_ret_age  = 0                                
       switch_calibration       = 0
       switch_persistent_delta  = 0
       switch_epsilon_corr      = 1
       switch_change_gy         = 1
     
       

    ! OPEN (unit=3, FILE = "experiment_details.txt")
    ! 
    !
    !    ! first some details of experiment     
    !    read(3,*) experiment
    !    read(3,*) switch_mortality             
    !    read(3,*) switch_unstable_dem_ss       
    !    read(3,*) switch_go_to_lower_gamma   
    !    read(3,*) switch_change_tauL
    !    read(3,*) switch_change_lambda            
    !    read(3,*) switch_change_tauK           
    !    read(3,*) switch_steady_demo   
    !    read(3,*) switch_change_sl        
    !    read(3,*) switch_change_debt      
    !    read(3,*) switch_residual_t 
    !    read(3,*) switch_residual_1 
    !    
    !    
    !    ! second, some debug switches/options
    !    read(3,*) switch_labor_choice
    !    read(3,*) switch_cohort_ps             
    !    read(3,*) switch_see_ret       
    !    read(3,*) switch_g_const   
    !    read(3,*) switch_fix_labor
    !    read(3,*) switch_tauK_gross            
    !    read(3,*) switch_unequal_bequest           
    !    read(3,*) switch_reduce_pension   
    !    read(3,*) switch_increase_ret_age        
    !    read(3,*) switch_persistent_delta      
    !    read(3,*) switch_epsilon_corr    
    !    read(3,*) switch_change_gy             
    !    read(3,*) switch_return_risk    
    !    read(3,*) switch_income_risk    
    !    read(3,*) switch_discount_risk             
    !    read(3,*) switch_return_risk
    !    
    !    read(3,*) switch_starting_year
    !    read(3,*) switch_ss_write
    !    read(3,*) switch_run_1
    !    read(3,*) switch_run_2
    !    read(3,*) switch_run_t
    !    read(3,*) switch_param_1
    !    read(3,*) switch_param_2
    !    read(3,*) switch_partial_eq
    !    
    !CLOSE(3) 
    !
    !
    ! 
     
        switch_mortality         = 1      
        switch_unstable_dem_ss   = 1        
        switch_go_to_lower_gamma = 1         
        switch_change_tauL       = 1
        switch_change_lambda     = 1      
        switch_change_tauK       = 1
        switch_steady_demo       = 1
        switch_sigma2_epsilon_t  = 1
        
        switch_change_debt       = 1
        switch_change_sl         = 1
        switch_income_risk       = 1
        switch_discount_risk     = 1
        switch_return_risk       = 0
        switch_change_gy         = 1
        switch_keep_fixed        = 0
        
    experiment = 'hir_'
    switch_starting_year = 3    ! first year for which we have data: 0 = 1935, 1 = 1960, 2 = 1950 (if data not available, assume it is equal to the 1st available period) this matters for filling matrices with data, 3 - start fron 1935 and assume the same path until 1960
    switch_reform = 0           ! 0 = base transition, 1 = main LSRA (baseline + reform + welfare change)
    
    
    
    switch_partial_eq = 0   ! 0 = full transition model, 1 = decomposition of variance and expected value effect for welafare 2 (see file partial_eq_decomposition)
    switch_elas = 0 !0 - non elasticity calculation, 1 - elasticity using OPD, 2 - semileasticity using OPD 

    switch_ss_write = 0        ! 0 - do not save big csv files with steady state, 1 save

    switch_run_1 = 1            ! 0 = don't run old steady state; 1 = run old steady state
    switch_run_2 = 1            ! 0 = don't run new steady state; 1 = run new steady state
    switch_run_t = 1            ! 0 = don't run transition; 1 = run transition
    
    switch_type_1 = 0           ! initial ss: 0 = DB; 1 = DC 
    switch_type_2 = 0           ! final   ss: 0 = DB; 1 = DC
    switch_pension = abs(switch_type_1 - switch_type_2)         ! 0 = all are in new pension scheme in transitionFF; 1 = old cohorts remain in the old system in transitionFF

! note: transition path is run only if the second steady state is run
    switch_param_1 = 0          ! 0 = with old parameters; 1 = with new parameters  
    switch_param_2 = 1          ! 0 = with old parameters; 1 = with new parameters  

! note: parameters on the transition path are determined by the parameters on the second steady state     
    switch_vf      = 1         ! 0 = analitical solution, 1 endogenous grid
    

    !
   if (bigJ == 4) then ! 0 = retirement age from data file, retirement age equal to value of switch_fix_retirement_age. ex switch  = 45 means jbar = 45 
        switch_fix_retirement_age = 3 
    elseif (bigJ == 16) then
        switch_fix_retirement_age = 10         
    elseif (bigJ == 20) then
        switch_fix_retirement_age = 11 
    elseif  (bigJ == 80)  then
        switch_fix_retirement_age = 0 ! thus we are going to use data projection 
    elseif  (bigJ == 2)  then
        switch_fix_retirement_age = 2 
     endif
if (switch_increase_ret_age == 1 ) then 
    switch_fix_retirement_age = 0
endif
  
!!!!!!!!!!!!!!!!!!!
    err_tol = 1e-7 !! 0.05_dp !! 
    err_ss_tol = 1e-11
    ones = 1 

!!!!!!!! choose closure!!!!!!!!!!
    switch_residual_t = 1
    switch_residual_1 = 1
    switch_residual_2 = 1

        closure = 'taxC__'


    up_ss = 0.75d0 

  
    valor_share = 1.0_dp ! % of growth rate, to ma być 25%, jednak w REV mielismy 0.2 wiec na razie jest tyle
    
    tc_ss =  -0.0674225d0 !

  
    tL = tL
    tk = tK
    tc = tc_ss
    

    debt_constr = 1_dp/zbar

    tc_growth = 0.20d0 ! what is this?
    up_tc = 0.7d0 
    

    g_share_ss = 0.28d0 ! 0.17d0 !0.17_dp
    
    
    superstar_factor_1 = 6.5d0
    superstar_factor_2 = 25.0d0
    
    alpha = 0.33_dp
    theta = 2.0_dp!2.0_dp
   
    up_t = 0.7d0
    
    ! population shares of types
    bigM_share_ss = 1.0d0 / bigM
    ! productivity multiplier
    type_multiplier = 1.0d0

    include 'parameters_CD.f90'
    

    if (switch_labor_choice == 0) then
        phi  = 1.00_dp 
    endif

    call read_data(omega_ss, gam_t, gam_cum, zet, pi, pi_weight, Nn_, jbar_t, tauL_t, tauK_t, lambda_t, debt_constr_t, alpha_t, gy_factor_t)
    include 'shocks_parameters.f90'
    ! it is need for implicit tax subroutine
    ! assume that jbar_t is monotonic for each year of birth we may calculete jbar 
    new_ret_yob = -bigT
    new_ret_yob(1) = 1 - jbar_t(1) + 1
    last = new_ret_yob(1) 
    do i = 2, bigT    
        ! calculate years of birth of new retired
        new_ret_yob(i) = i - jbar_t(i) + 1
        ! during increase ret age we may have 
        ! new_ret_yob(i) <=  new_ret_yob(i -1) which is not true cause 
        ! there is no possibility to be shorn of pension - we need to 
        ! take in to account during calculate year of birth [yob] specifc ret age
            if (new_ret_yob(i) <= last) then
                new_ret_yob(i) = -bigT ! unreal small number
            else 
                 last  = new_ret_yob(i)
            endif
    enddo
    jbar_t_yob(:) = jbar_t(1)
    do i = 1, bigT, 1
        if (new_ret_yob(i) > -bigT) then
            ! we use first occuring of 
            jbar_t_yob(new_ret_yob(i)) =  jbar_t(i)  
        endif
    enddo
    
    t1_ss_contrib = t1_ss_old
    t1 = t1_ss_old
    do i = 1,bigT,1
        omega(:,i) = omega_ss
    enddo
    
    g_share    =  g_share_ss * gy_factor_t
    g_share_ss =  g_share(1)
    g_share_ss_2 =g_share(bigT)
    
    
    jbar_ss_old = jbar_t(1)
    jbar_ss_new = jbar_t(bigT)

    debt_constr_ss_old = debt_constr_t(1)
    debt_constr_ss_new = debt_constr_t(bigT)
    
    gam_ss_old = gam_t(1)
    gam_ss_new = gam_t(bigT)

    pi_ss_old = pi(:,1)
    pi_ss_new = pi(:,bigT)

    pi_weight_ss_old = pi_weight(:,1)
    pi_weight_ss_new = pi_weight(:,bigT)
    
    N_ss_old = Nn_(:,1)
    N_ss_new = Nn_(:,bigT)

    tauL_ss_old = tauL_t(1)
    tauL_ss_new = tauL_t(bigT)
    
    tauK_ss_old = tauK_t(1)
    tauK_ss_new = tauK_t(bigT)
    
    lambda_ss_old = lambda_t(1)
    lambda_ss_new = lambda_t(bigT)
    
    alpha_ss_old = alpha_t(1)
    alpha_ss_new = alpha_t(bigT)
    
call chdir(cwd_w)    
end subroutine globals



subroutine clear_globals
    k_ss_1 = 0
    r_ss_1 = 0
    w_bar_ss_1 = 0
    upsilon_r_ss_1 = 0
    l_ss_j_1 = 0
    w_ss_j_1 = 0
    s_ss_j_1 = 0
    c_ss_j_1 = 0
    b_ss_j_1 = 0

   
    k_ss_2 = 0
    r_ss_2 = 0
    w_bar_ss_2 = 0
    upsilon_r_ss_2 = 0
    l_ss_j_2 = 0
    w_ss_j_2 = 0
    s_ss_j_2 = 0
    c_ss_j_2 = 0
    b_ss_j_2 = 0

   
    
    c_db = 0
    l_db = 0
    tax_c_db = 0
    r_db = 0 
end subroutine clear_globals

end module global_vars2
