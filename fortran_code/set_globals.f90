

MODULE global_vars2
USE global_vars
USE get_data
use pfi_trans

IMPLICIT NONE
CONTAINS

subroutine globals 
    real, dimension(bigJ, bigT) :: ones

    
    
    version = 'base_' ! these three strings allow us to load a correct version
    experiment = 'non_'
    closure = 'govt__'

call chdir(cwd_i)

    OPEN (unit=3, FILE = version//experiment//closure//"instructions.txt")
        ! preamble
        ! switches of the specification
        read(3,*) switch_mortality             
        read(3,*) switch_unstable_dem_ss       
        read(3,*) switch_go_to_lower_gamma   
        read(3,*) switch_change_tauL
        read(3,*) switch_change_tauC
        read(3,*) switch_change_lambda            
        read(3,*) switch_change_tauK           
        read(3,*) switch_steady_demo   
        read(3,*) switch_sigma2_epsilon_t        
        read(3,*) switch_change_premium      
        read(3,*) switch_change_type_share 
        read(3,*) switch_change_debt 
        read(3,*) switch_change_sl 
        read(3,*) switch_change_gy 
        read(3,*) switch_change_depr 
        read(3,*) switch_change_contrib
        read(3,*) switch_change_rho
        read(3,*) switch_wage_vs_income
        read(3,*) switch_keep_fixed 
        read(3,*) switch_residual_t 
        read(3,*) switch_residual_1 
        read(3,*) switch_residual_2 
        read(3,*) switch_no_debt

        ! second, some debug switches/options
        read(3,*) switch_het_mortality
        read(3,*) switch_utility_function
        read(3,*) switch_labor_choice
        read(3,*) switch_cohort_ps             
        read(3,*) switch_see_ret       
        read(3,*) switch_g_const   
        read(3,*) switch_fix_labor
        read(3,*) switch_tauK_gross            
        read(3,*) switch_unequal_bequest           
        read(3,*) switch_reduce_pension   
        read(3,*) switch_increase_ret_age        
        read(3,*) switch_persistent_delta      
        read(3,*) switch_epsilon_corr                
        read(3,*) switch_income_risk 
        read(3,*) switch_income_fixed_effect 
        read(3,*) switch_discount_risk 
        read(3,*) switch_return_risk 
        read(3,*) switch_initial_dispersion 
        
        ! run properties
        read(3,*) switch_starting_year
        read(3,*) switch_run_1
        read(3,*) switch_run_2
        read(3,*) switch_run_t
        read(3,*) switch_param_1
        read(3,*) switch_param_2
        read(3,*) switch_ss_write
        read(3,*) switch_profile 
        read(3,*) switch_small_write 
        CLOSE(3) 



call chdir(cwd_p)
    OPEN (unit=3, FILE = version//experiment//closure//"parameters.txt")
   ! load these parameter values
        read(3,*) n_iter_ss             
        read(3,*) n_iter_t
        read(3,*) n_iter_prof
        read(3,*) err_ss_tol             
        read(3,*) err_tol
        read(3,*) err_prof_tol
        read(3,*) up_ss
        read(3,*) up_t
        read(3,*) up_debt_t
        read(3,*) up_tc
        read(3,*) l_bound
        read(3,*) beta
        read(3,*) delta            
        read(3,*) theta           
        read(3,*) alpha   
        read(3,*) depr        
        read(3,*) rho_subst      
        read(3,*) phi 
        read(3,*) disutil 
        read(3,*) frisch 
        read(3,*) tc_ss 
        read(3,*) g_share_ss 
        read(3,*) rho_1 
        read(3,*) rho_2 
        read(3,*) t1_ss_old 
        read(3,*) t1_ss_new 
        read(3,*) t2_ss_old 
        read(3,*) t2_ss_new 
        read(3,*) valor_share 
        read(3,*) switch_fix_retirement_age
        if (n_superstar > 0) then
        do m = 1,bigM,1 
            do i = 1,n_superstar,1
                read(3,*) superstar_factor_mat(m,i) !load all superstar factors for a type
            enddo
        enddo
        do m = 1,bigM,1 
            do i = 1,2*n_superstar,1
                read(3,*) superstar_pi_mat(m,i)  !load transition probabilities in the following order: move from regular to the 1st superstar state, stay at the top, stay in the 1st superstar state (if n_superstar >1), move up from the 1st superstar state(if n_superstar >1), stay in the 2nd superstar state (if n_superstar >1), move up from the 2nd superstar state(if n_superstar >1)...    
            enddo
        enddo
        endif
        read(3,*)  a_l  
        read(3,*)  a_u  
        read(3,*)  a_grow  
        read(3,*) aime_l !=0.001d0
        read(3,*) aime_u !=9165d0/3921d0
        read(3,*) aime_cap !=9165d0/3921d0
        read(3,*) zeta_d
        read(3,*) sigma_nu_d
        read(3,*) zeta_r
        read(3,*) sigma_nu_r
        read(3,*) labor_constant
        read(3,*) g_correction_last_period
        read(3,*) delta_half_width
        read(3,*) htm_shock_freq
        read(3,*) beq_age
        read(3,*) zipf
        do m = 1,bigM,1 
            read(3,*) zeta_p(m)
        enddo
         do m = 1,bigM,1 
            read(3,*) sigma2_fix(m)
        enddo
        CLOSE(3) 
        
        
        if (switch_increase_ret_age == 1 ) then 
            switch_fix_retirement_age = 0
        endif
  

        call read_data(omega_ss_big, gam_t, gam_cum, zet, pi_big, pi_big_weight, Nn_big, jbar_t, t1_t, tauL_t, tauK_t, tauC_t, lambda_t, debt_constr_t, alpha_t, type_multiplier_t, gy_factor_t, type_share_t, depr_t, rho_t)
            
        ! rescale to account for zbar
        zeta_p      = zeta_p**zbar  
        sigma_nu_d  = sigma_nu_d*(1-zeta_d**(2*zbar))/(1-zeta_d**2)
        zeta_d      = zeta_d**zbar 
        
    ones = 1 
 
    tL = tL
    tk = tK
    tc = tc_ss
   
    
    ! adjustments to switch off labor choice if we use income data
    
    if (switch_wage_vs_income == 1) then
        switch_labor_choice = 0
        switch_fix_labor = labor_constant
    endif
    
    
    if (switch_labor_choice == 0) then
        phi  = 1.00_dp 
        switch_fix_labor = labor_constant
    endif


        const_zipf = 0.0d0
        do ibeq=1,n_beq,1
                    const_zipf = const_zipf + 1 / ibeq**(zipf)
        enddo
        
    type_multiplier_ss_old = type_multiplier_t(:,1)
    type_multiplier_ss_new = type_multiplier_t(:,bigT)
    
    include 'shocks_parameters.f90'
    include 'print_stamp.f90' 
    
        ! rescale to account for zbar
        !depr_t        = (1.0_dp + depr_t)**zbar - 1.0_dp 
    !depr_t        = 1.0d0-(1.0_dp -depr_t)**zbar
    ! THIS JUNK BELOW CAN BE AXED
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
    

    
    do i = 1,bigT,1
        omega_big(:,:,i) = omega_ss_big
    enddo
    
    g_share    =  g_share_ss * gy_factor_t
    g_share_ss =  g_share(1)
    g_share_ss_2 =g_share(bigT)
    
    t1_ss_old    = t1_t(1)
    t1_ss_new    = t1_t(bigT)
    
    jbar_ss_old = jbar_t(1)
    jbar_ss_new = jbar_t(bigT)

    debt_constr_ss_old = debt_constr_t(1)
    debt_constr_ss_new = debt_constr_t(bigT)
    
    gam_ss_old = gam_t(1)
    gam_ss_new = gam_t(bigT)

    pi_big_ss_old = pi_big(:,:,1)
    pi_big_ss_new = pi_big(:,:,bigT)

    pi_big_weight_ss_old = pi_big_weight(:,:,1)
    pi_big_weight_ss_new = pi_big_weight(:,:,bigT)
    
    N_big_ss_old = Nn_big(:,:,1)
    N_big_ss_new = Nn_big(:,:,bigT)

    tauL_ss_old = tauL_t(1)
    tauL_ss_new = tauL_t(bigT)
    
    t1_ss_old = t1_t(1)
    t1_ss_new = t1_t(bigT)
    
    tauK_ss_old = tauK_t(1)
    tauK_ss_new = tauK_t(bigT)
    
    tauC_ss_old = tauC_t(1)
    tauC_ss_new = tauC_t(bigT)
    
    lambda_ss_old = lambda_t(1)
    lambda_ss_new = lambda_t(bigT)
    
    alpha_ss_old = alpha_t(1)
    alpha_ss_new = alpha_t(bigT)
    
    depr_ss_old = depr_t(1)
    depr_ss_new = depr_t(bigT)
    
    rho_ss_old = rho_t(1)
    rho_ss_new = rho_t(bigT)
    

    
    type_share_ss_old = type_share_t(:,1)
    type_share_ss_new = type_share_t(:,bigT)
    
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

    
    
    
    
    
    
    
    !!! CLUTTER TO BE REMOVED
    
    !         !!! DEBUG_SWITCH
       !switch_labor_choice      = 1        ! 0 = no labor choice (phi = 1) , 1 =  labor choice determined by 0<phi<1
       !switch_cohort_ps         = 1         ! 0 = points pension system like us, 1 = the same benefits within a whole cohorts  
       !switch_see_ret           = 0         ! 0 = agent sees no tax-benefit link; 1 = agent sees implicit savings
       !switch_g_const           = 0         ! 0 = g keept as a fixed share of gdp, 1 = g keept as fixed in per capita terms 
       !switch_fix_labor         = 0        ! if labor is fixed it is fixed to this number
       !switch_tauK_gross        = 1         ! 0 = net return on capital is taxed, 1 = gross return on capital is taxed 
       !switch_unequal_bequest   = 0         ! 0 - bequests given by people of age j to people with age j-1, distributed equally; 1 - bequests given by all people to j=1, unequal distribution
       !switch_reduce_pension    = 0
       !switch_increase_ret_age  = 0                                
       !switch_calibration       = 0
       !switch_persistent_delta  = 0
       !switch_epsilon_corr      = 1
       !switch_utility_function  = 1        ! 0 - Cobb-Douglas in leisure and consumption, 1 - separable with constant Frisch, 2 - Uhlig
       !
       ! 
       ! 
       ! 
       ! 
       !
       !
       ! 

! switches related to income processes

    !switch_sigma2_epsilon_t    =  1        ! transition path;  0 = sigma2_epsilon is constant; 1 = sigma2_epsilon is cohort specific; 2 = sigma2_epsilon is time specific
    !switch_initial_dispersion   = 1        ! 0 = everybody is born the same; 1 = initial productivity is drawn from some distribution
  
      !switch_mortality         = 1         ! 0 = no mortality on transition, 1 mortality according to data, 3 N according to data, pi as in first steady state, there would be baby boomers, 4 N1 == 1, pi as in the first steady state, 5, 6, 7 mortality and growth rate of young populaton set at the initial level 
    !switch_unstable_dem_ss   = 1         ! 0 = demography  in steady state is stable (fertility rate = 2), 1 unstable demography in steady state (based on UN), -1 unstable (set growth to its initial value)
    !switch_go_to_lower_gamma = 0         ! 0 = gamma = const = 2%, 1 empirical
    !switch_change_tauL       = 0         ! 0 = const,  1 = empirical -- warning: how will it interact with various closures?  
    !switch_change_lambda     = 0         ! 0 = const,  1 = empirical -- warning: how will it interact with various closures?     
    !switch_change_tauK       = 0         ! 0 = const,  1 = empirical -- warning: how will it interact with various closures?
    
    
!!!! DEBUG_SWITCH
!       switch_labor_choice      = 1        ! 0 = no labor choice (phi = 1) , 1 =  labor choice determined by 0<phi<1
!       switch_cohort_ps         = 1         ! 0 = points pension system like us, 1 = the same benefits within a whole cohorts  
!       switch_see_ret           = 0         ! 0 = agent sees no tax-benefit link; 1 = agent sees implicit savings
!       switch_g_const           = 0         ! 0 = g keept as a fixed share of gdp, 1 = g keept as fixed in per capita terms 
!       switch_fix_labor         = 0        ! if labor is fixed it is fixed to this number
!       switch_tauK_gross        = 1         ! 0 = net return on capital is taxed, 1 = gross return on capital is taxed 
!       switch_unequal_bequest   = 0         ! 0 - bequests given by people of age j to people with age j-1, distributed equally; 1 - bequests given by all people to j=1, unequal distribution
!       switch_reduce_pension    = 0
!       switch_increase_ret_age  = 0                                
!       switch_calibration       = 0
!       switch_persistent_delta  = 0
!       switch_epsilon_corr      = 1
!       switch_utility_function  = 1        ! 0 - Cobb-Douglas in leisure and consumption, 1 - separable with constant Frisch, 2 - Uhlig
!     

!     
!        switch_mortality         = 5     
!        switch_unstable_dem_ss   = 1       
!        switch_go_to_lower_gamma = 1         
!        switch_change_tauL       = 1
!        switch_change_lambda     = 1      
!        switch_change_tauK       = 1
!        switch_steady_demo       = 1
!        switch_sigma2_epsilon_t  = 1
!        switch_change_premium    = 1
!        switch_change_type_share = 1
!        switch_change_debt       = 1
!        switch_change_sl         = 1
!        switch_income_risk       = 1
!        switch_discount_risk     = 0
!        switch_return_risk       = 0
!        switch_change_gy         = 1
!        switch_keep_fixed        = 1
!    
!    version = 'xxxx_' ! this is just to organize some versions, does not change anything in the code
!    experiment = 'all_'
!    switch_starting_year = 3    ! first year for which we have data: 0 = 1935, 1 = 1960, 2 = 1950 (if data not available, assume it is equal to the 1st available period) this matters for filling matrices with data, 3 - start fron 1935 and assume the same path until 1960
!    
!    
!    
!
!    switch_ss_write = 1        ! 0 - do not save big csv files with steady state, 1 save
!    switch_profile = 1        
!    switch_run_1 = 1            ! 0 = don't run old steady state; 1 = run old steady state
!    switch_run_2 = 1            ! 0 = don't run new steady state; 1 = run new steady state
!    switch_run_t = 0            ! 0 = don't run transition; 1 = run transition
!    
!
!! note: transition path is run only if the second steady state is run
!    switch_param_1 = 0          ! 0 = with old parameters; 1 = with new parameters  
!    switch_param_2 = 1          ! 0 = with old parameters; 1 = with new parameters  
!
!! note: parameters on the transition path are determined by the parameters on the second steady state     
    