

MODULE global_vars2
USE global_vars
USE get_data
use pfi_trans

IMPLICIT NONE
CONTAINS

subroutine globals 
    real, dimension(bigJ, bigT) :: ones

    


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
        read(3,*) switch_change_depr 
        read(3,*) switch_change_contrib
        read(3,*) switch_change_rho
        read(3,*) switch_keep_fixed 
        read(3,*) switch_residual_t 
        read(3,*) switch_residual_1 
        read(3,*) switch_residual_2 
        read(3,*) switch_no_debt

        ! second, some debug switches/options
        read(3,*) switch_het_mortality
        read(3,*) switch_labor_choice
        read(3,*) switch_cohort_ps             
        read(3,*) switch_fix_labor
        read(3,*) switch_tauK_gross            
        read(3,*) switch_unequal_bequest           
        read(3,*) switch_reduce_pension   
        read(3,*) switch_persistent_delta      
        read(3,*) switch_epsilon_corr                
        read(3,*) switch_income_risk 
        read(3,*) switch_income_fixed_effect 
        read(3,*) switch_discount_risk 
        read(3,*) switch_return_risk 
        read(3,*) switch_initial_dispersion 
        
        ! run properties
        read(3,*) switch_run_1
        read(3,*) switch_run_2
        read(3,*) switch_run_t
        read(3,*) switch_param_1
        read(3,*) switch_param_2
        read(3,*) switch_ss_write
        read(3,*) switch_profile 
        read(3,*) switch_small_write 
        read(3,*) switch_exog_rate
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
  

        call read_data(omega_ss_big, gam_t, gam_cum, zet, pi_big, pi_big_weight, Nn_big, jbar_t, t1_t, tauL_t, tauK_t, tauC_t, lambda_t, debt_constr_t, alpha_t, type_multiplier_t, gy_factor_t, type_share_t, depr_t, rho_t, exog_rate_t)
            
        ! rescale to account for zbar
        zeta_p      = zeta_p**zbar  
        sigma_nu_d  = sigma_nu_d*(1-zeta_d**(2*zbar))/(1-zeta_d**2)
        zeta_d      = zeta_d**zbar 
        
    ones = 1 
 
    tL = tL
    tk = tK
    tc = tc_ss
   
    
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
    
    exog_rate_ss_old = exog_rate_t(1)
    exog_rate_ss_new = exog_rate_t(bigT)
    
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
    lab_ss_j_1 = 0
    w_ss_j_1 = 0
    s_ss_j_1 = 0
    c_ss_j_1 = 0
    b_ss_j_1 = 0

   
    k_ss_2 = 0
    r_ss_2 = 0
    w_bar_ss_2 = 0
    upsilon_r_ss_2 = 0
    l_ss_j_2 = 0
    lab_ss_j_2 = 0
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

    
    
    
    
    
    
    

    