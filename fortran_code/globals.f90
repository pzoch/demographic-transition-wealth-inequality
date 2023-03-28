! WHAT  : declaration of global (ALL subroutines and functions MAY USE them) parameters and variables
! TAKE  : none 
! DO    : definition of a switch in comments 
! RETURN: nothing
MODULE global_vars
IMPLICIT NONE
   save
    integer ::  n_iter_ss
    integer ::  n_iter_t
    integer ::  n_iter_prof
    integer, parameter :: dp = kind(1.0d0)
    integer, parameter :: bigJ = 16
    integer, parameter :: bigM = 2 ! number of permanent types
    integer, parameter :: n_p = 140, n_debt  = 60, forward = 1 ! id does not work :( 
    real(dp), parameter :: forward_smoothing = 1d0/real(forward)
	integer, parameter :: bigT = n_p+bigJ+1
    integer, parameter :: ofe_u = 0  
    real(dp), parameter :: zbar = real(80/bigJ) ! 4 periods model scale parameter
    integer :: iter, i, j, s, m, cl
    character(5) :: version
    character(1) :: beq_age_char
    character(6) :: closure
    character(12) :: variant
    character(4) :: experiment
    character(4) :: no_steady
    
    character(128) :: cwd, cwd_r, cwd_w, cwd_i, cwd_p
    
    integer :: switch_ss_write                              ! 0 - do not save big csv files with steady state, 1 save
    
    integer :: switch_run_1, switch_run_2, switch_run_t     ! 0 = don't run the first/second steady state/transition path; 1 = run the first/second steady state/transition path
    integer :: switch_profile                               ! 0 = do not calculate profiles; 1 = calculate profiles 
    integer :: switch_param_1, switch_param_2               ! 0 = with old parameters; 1 = with new parameters (pi,gam,N,jbar) 
    integer :: switch_type_1, switch_type_2                 ! 0 = payg; 1 = ff
    integer :: switch_steady_demo                           ! this is a switch that needs to be set to 1 to have nu_ss not equal to 1 in the initial steady state: 0 = demographical structure as in the data, 1 = demographical structure obtained by taking survival probabilities and some prespecified population growth rate
    
    integer :: switch_residual_1                            ! old steady state; 0 = upsilon is residual, there are no more options for the first steady state
    integer :: switch_residual_2                            ! new steady state; 0 = upsilon is residual; 1 = tC is residual; 2 = tL is residual                
    integer :: switch_residual_t                            ! transition path;  0 = upsilon is residual; 1 = tC is residual; 2 = tL is residual
    
    integer :: switch_starting_year                         ! first year for which we have data: 0 = 1935, 1 = 1960, 2 = 1950 -- this matters for filling matrices with data

    integer :: switch_sigma2_epsilon_t                      ! transition path;  0 = sigma2_epsilon is constant; 1 = sigma2_epsilon is cohort specific; 2 = sigma2_epsilon is time specific (working on 1 currently)
    integer :: switch_initial_dispersion                    ! 0 = everybody is born the same; 1 = initial productivity is drawn from some distribution (so far only 0 works)
    integer :: switch_epsilon_corr                          ! 0 do not worry that variances shift means, 1 - correct to keep mean constant

    integer :: switch_go_to_lower_gamma                    ! 0 = const,  1 = empirical     
    integer :: switch_change_tauL                          ! 0 = const,  1 = empirical - warning: how will it interact with various closures?  
    integer :: switch_change_tauC                          ! 0 = const,  1 = empirical - warning: how will it interact with various closures?  
    integer :: switch_change_lambda                        ! 0 = const,  1 = empirical - warning: how will it interact with various closures?     
    integer :: switch_change_tauK                          ! 0 = const,  1 = empirical - warning: how will it interact with various closures?    
    integer :: switch_tauK_gross                           ! 0 = tax on net capital income,  1 = tax on gross capital income  
    integer :: switch_unequal_bequest
    integer :: switch_change_debt
    integer :: switch_change_sl
    integer :: switch_change_gy
    integer :: switch_change_depr
    integer :: switch_change_contrib
    integer :: switch_utility_function
    integer :: switch_print
    integer :: switch_labor_choice                         ! 0 = no labor choice (phi = 1) , 1 =  labor choice determined by 0<phi<1
    integer :: switch_mortality                            ! 0 = no mortality on transition, 1 mortality according to data 
    integer :: switch_fix_retirement_age                   ! 0 = retirement age from data file, retirement age equal to value of switch_fix_retirement_age
    integer :: switch_unstable_dem_ss                      ! 0 = demography  in steady state is stable (fertility rate = 2), unstable demography in steady state 
    integer :: switch_cohort_ps                             ! 0 = points pension system like us, 1 = the same benefits within a whole cohorts 
    integer :: switch_see_ret                              ! 0 = agent sees no tax-benefit link; 1 = agent sees implicit savings
    integer :: switch_persistent_delta                  ! 0 = AR1 shocks to patience, 1 = permanent types assigned at birth (normal distr), 2 = permanent types assigned at birth (uniform)
    integer :: switch_change_premium                    ! 0 = does not change premium, 1 = changes wage premium !!! HERE IMPLEMENTED AS A CHANGE IN ETAS
    integer :: switch_income_risk
    integer :: switch_income_fixed_effect               ! 0 = no income fixed effects, 1 = income fixed effects, group specific
    integer :: switch_discount_risk
    integer :: switch_return_risk
    integer :: switch_keep_fixed                      
    real*8  :: switch_fix_labor                             ! 0 = endogenous labor, other number (=0.33 for US) fix labor force participation
    integer :: switch_g_const                               ! 0 = g keept as a fixed share of gdp, 1 = g keept as fixed in per capita terms 
    integer ::switch_change_type_share                            
    integer :: switch_ref_run_now 
    integer :: switch_reduce_pension
    integer :: switch_increase_ret_age
    integer :: switch_het_mortality                         ! 0 - take UN data, 1 - take our pi 
    integer :: switch_no_debt                               ! 0 - there is government debt, 1 - government debt set to 0 in all periods
    integer :: switch_change_rho
    integer :: switch_wage_vs_income                        ! 0 - use process for wages, 1 - use process for income
    
    real(dp), dimension(bigJ) :: omega_ss 
    real(dp), dimension(bigJ,bigM) :: omega_ss_big
    real(dp), dimension(n_p)  :: gam
    real(dp), dimension(n_p)  :: tauL
    real(dp), dimension(n_p)  :: tauK
    
    !real(dp), dimension(n_p)  :: lambda - name conflict

    real(dp) :: debt_constr
    real*8 :: pi_i_6, pi_6_6, pi_6_7, pi_7_7 ! super stars 
! Deklaracje zmiennych, ktore nam zostaja po steady state'ach
    real(dp) :: k_ss_1, r_ss_1, r_bar_ss_1, upsilon_r_ss_1, t1_ss_1, g_per_capita_ss_1 
    real(dp) :: k_ss_2, r_ss_2, r_bar_ss_2, upsilon_r_ss_2, t1_ss_2, g_per_capita_ss_2
    
    real(dp), dimension(bigM) :: w_bar_ss_1
    real(dp), dimension(bigM) :: w_bar_ss_2
    real(dp), dimension(bigM) :: sum_b_weight_vec_ss_old
    
    real(dp), dimension(bigJ,bigM) :: l_ss_j_1, w_ss_j_1, s_ss_j_1, c_ss_j_1, b_ss_j_1, l_ss_pen_j_1
    real(dp), dimension(bigJ,bigM) :: l_ss_j_2, w_ss_j_2, s_ss_j_2, c_ss_j_2, b_ss_j_2, l_ss_pen_j_2

! parameters
    real(dp) :: alpha, beta, delta, depr, theta, rho_subst, phi, up_ss, up_t, rho_1, rho_2, err_tol, err_ss_tol, err_prof_tol, frisch, disutil, l_bound, labor_constant
    real(dp) :: g_share_ss, g_share_ss_2, tk_ss, tl_ss, tc_ss, tc2_ss, t1_ss_old, t1_ss_new, t2_ss_old, t2_ss_new, valor_share, debt_constr_ss_old, debt_constr_ss_new, tc_new, tl_new, tk_new, alpha_ss_old, alpha_ss_new, g_correction_factor_old, g_correction_factor_new, depr_ss_old, depr_ss_new, rho_ss_old, rho_ss_new, frac_pat, delta_H
    real(dp) :: jbar_ss_old, jbar_ss_new, gam_ss_old, gam_ss_new, nu_ss_old, nu_ss_new, tauL_ss_old, tauL_ss_new, tauK_ss_old, tauK_ss_new, tauC_ss_old, tauC_ss_new, lambda_ss_old, lambda_ss_new, epsilon_correction_ss_old, epsilon_correction_ss_new
    real(dp), dimension(bigM) :: epsilon_correction_ss_old_big, epsilon_correction_ss_new_big, type_multiplier_ss_old, type_multiplier_ss_new, type_share_ss_old, type_share_ss_new
    real(dp) :: tc_growth, up_tc, up_debt_t
    real(dp), dimension(bigJ) :: pi_ss_old, pi_ss_new, pi_weight_ss_old, pi_weight_ss_new, N_, N_ss_old, N_ss_new  
    real(dp), dimension(bigJ,bigM) :: pi_big_ss_old, pi_big_ss_new, pi_big_weight_ss_old, pi_big_weight_ss_new, N_big_ss_old, N_big_ss_new, pi_ss_cond_big
    real(dp) :: superstar_factor_1, superstar_factor_2
    real(dp), dimension(bigM,2) :: superstar_factor_mat
    real(dp), dimension(bigM,4) :: superstar_pi_mat
    integer :: g_correction_last_period
    real(dp) :: delta_half_width, htm_shock_freq
! transition variables
    integer, dimension(bigT) :: jbar_t
	real(dp), dimension(bigT) :: g_share, tk, tL, tc, gam_t, gam_cum, zet, feasibility, lambda_t, t1_t, tauL_t, tauK_t,tauC_t, debt_constr_t, alpha_t, depr_t, gy_factor_t, rho_t 
    real(dp), dimension(bigT) :: sigma2_epsilon_t, epsilon_correction_t, g_correction_factor_t
    real(dp), dimension(bigT,bigM) :: sigma2_epsilon_t_big, epsilon_correction_t_big
    real(dp), dimension(bigM,bigT) ::  type_multiplier_t, type_share_t,sum_b_weight_trans_outer_mat
    real(dp), dimension(bigJ, bigT) :: Nn_, pi, omega, t1, pi_weight
    real(dp), dimension(bigJ, bigM, bigT) ::pi_big, pi_big_weight, Nn_big, pi_trans_cond_big
    real(dp), dimension(bigJ,bigM, bigT) :: omega_big
! LSRA
    real(dp), dimension(bigJ, bigM, bigT) :: c_db, l_db, s_db !  c_base, l_base,  c_ref, l_ref
    real(dp), dimension(- bigJ: bigT) ::  V_20_years_old_db !  V_20_years_old_base, V_20_years_old_ref
    real(dp), dimension(bigT) :: r_db, tax_c_db, g_per_capita_db, better !  r_base, tax_c_base, g_per_capita_base, r_ref, tax_c_ref, g_per_capita_ref
    real(dp), dimension(bigJ, bigT) :: x_j_pro,  x_unif_pro, sum_x_pro, x_c_j_pro, eq_unif_pro, sum_eq_pro
    real(dp) :: LS_pro , g_trans(bigT), g_ss_2, upsilon_r_ss_nr

! multiple types
    real(dp), dimension(bigM) :: bigM_share_ss
    real(dp), dimension(bigM) :: type_multiplier
 ! pfi 
    real*8, parameter  :: fi = (5d0**(1d0/2d0)-1d0)/2d0
    integer, parameter :: n_a = 50, n_aime = 11, n_sp_risk = 4, n_sd =4, n_sr = 3, n_beq = 2, n_sp_fix = 1, n_superstar = 1 ! convention here is that there are (n_sp_risk - n_superstar) ordinary income grid points
    integer, parameter            :: n_sp = (n_sp_risk) * n_sp_fix
    integer :: n_sp_risk_ordinary
    real*8 :: const_zipf
    
    real*8 :: zipf
    real*8, dimension(bigM) :: zeta_p
    real*8, dimension(bigM) :: sigma2_fix
        

    
    real*8 :: a_l, a_u, a_grow, aime_l, aime_u, aime_grow, poss_ass_sum_ss(bigJ), sigma_nu_r, n_sr_initial,&
                zeta_r, r_ss_, zeta_d, n_sd_initial, sigma_nu_d, n_sp_initial,&
               pi_ir(n_sr,n_sr), n_sr_value(n_sr), pi_id(n_sd,n_sd), n_sd_value(n_sd), prob_norm(n_sr), prob_norm_fix(n_sp_fix),  prob_norm_d(n_sd), pi_id_init(n_sd), pi_ir_init(n_sr)
    real*8 :: aime_cap, aime_cap_ge
    
     real*8, dimension(n_sp_fix,bigM) :: n_sp_fix_value
    
 ! cohort/time specific shock grids
    real*8   ::  pi_ip_risk_trans(n_sp_risk,n_sp_risk,bigT), n_sp_risk_value_trans(n_sp_risk,bigT), pi_ip_risk_init_trans(n_sp_risk,bigT) ! these will be used to construct things used in pfi.90 
    real*8   ::  pi_ip_risk_trans_big(n_sp_risk,n_sp_risk,bigM,bigT), n_sp_risk_value_trans_big(n_sp_risk,bigM,bigT), pi_ip_risk_init_trans_big(n_sp_risk,bigM, bigT) ! these are used in the outer routine and hold all the information
    
    real*8   ::  pi_ip_trans(n_sp,n_sp,bigT), n_sp_value_trans(n_sp,bigT), pi_ip_init_trans(n_sp,bigT) ! these will be used in pfi.90 
    real*8   ::  pi_ip_trans_big(n_sp,n_sp,bigM,bigT), n_sp_value_trans_big(n_sp,bigM,bigT), pi_ip_init_trans_big(n_sp,bigM, bigT) ! these are used in the outer routine and hold all the information
    
    real(dp) :: sigma2_epsilon_ss_old_big(bigM), sigma2_epsilon_ss_new_big(bigM) ! these will be used in pfi.90 
    real(dp) :: sigma2_epsilon_ss_old, sigma2_epsilon_ss_new ! these are used in the outer routine and hold all the information
    
    real*8   :: pi_ip_risk_ss_old_big(n_sp_risk,n_sp_risk,bigM), n_sp_risk_value_ss_old_big(n_sp_risk,bigM), pi_ip_risk_ss_new_big(n_sp_risk,n_sp_risk,bigM), n_sp_risk_value_ss_new_big(n_sp_risk,bigM), pi_ip_risk_init_ss_old_big(n_sp_risk,bigM), pi_ip_risk_init_ss_new_big(n_sp_risk,bigM) ! steady state shock 
    
    real*8   :: pi_ip_risk_ss_old(n_sp_risk,n_sp_risk), n_sp_risk_value_ss_old(n_sp_risk), pi_ip_risk_ss_new(n_sp_risk,n_sp_risk), n_sp_risk_value_ss_new(n_sp_risk), pi_ip_risk_init_ss_old(n_sp_risk), pi_ip_risk_init_ss_new(n_sp_risk) ! steady state shock realizations and transition probabilities
    
    real*8   :: pi_ip_ss_old_big(n_sp,n_sp,bigM), n_sp_value_ss_old_big(n_sp,bigM), pi_ip_ss_new_big(n_sp,n_sp,bigM), n_sp_value_ss_new_big(n_sp,bigM), pi_ip_init_ss_old_big(n_sp,bigM), pi_ip_init_ss_new_big(n_sp,bigM) ! steady state shock 
    real*8   :: pi_ip_ss_old(n_sp,n_sp), n_sp_value_ss_old(n_sp), pi_ip_ss_new(n_sp,n_sp), n_sp_value_ss_new(n_sp), pi_ip_init_ss_old(n_sp), pi_ip_init_ss_new(n_sp) ! steady state shock realizations and transition probabilities
    
    real*8   :: pi_ip_risk_big(n_sp_risk,n_sp_risk,bigM), n_sp_risk_value_big(n_sp_risk,bigM), pi_ip_risk_init_big(n_sp_risk,bigM) ! holder to make this code compatibile with older subroutines
    real*8   :: pi_ip_risk(n_sp_risk,n_sp_risk), n_sp_risk_value(n_sp_risk), pi_ip_risk_init(n_sp_risk)! holder to make this code compatibile with older subroutines
    
    real*8   :: pi_ip_big(n_sp,n_sp,bigM), n_sp_value_big(n_sp,bigM), pi_ip_init_big(n_sp,bigM) ! holder to make this code compatibile with older subroutines
    real*8   :: pi_ip(n_sp,n_sp), n_sp_value(n_sp), pi_ip_init(n_sp)! holder to make this code compatibile with older subroutines
    
    
    real*8, dimension(bigJ, bigM) ::   pillar1_ss_j_1, pillar2_ss_j_1, pillar1_ss_j_2, pillar2_ss_j_2
 ! pension system 
    real*8 :: sum_b_weight_ss, b_scale_factor_old, b_scale_factor_new, avg_ef_l_supply, priv_share, t1_ss_contrib
    real*8, dimension(bigJ, bigT) ::  sum_b_weight_trans(bigT), t1_contrib(bigJ, bigT), t2(bigJ, bigT), sum_b_weight_trans_outer(bigT)
    real*8, dimension(bigT) :: avg_ef_l_supply_trans, sum_b1_help, debt_trans, debt_trans_old
    

  ! bequests  
    integer :: beq_age
    real*8 :: beq_zipf_ss(n_beq), p_beq(n_beq)
    real*8, dimension(n_beq,bigT) :: p_beq_trans
    
    
! implicit tax
    real(dp), dimension(bigJ) :: tau1_ss_1, tau1_a_ss_1, tau2_ss_1, &
                                 tau1_ss_2, tau1_a_ss_2, &
                                 tau2_ss_2,&
                                 transfer_pfi
    
     real(dp), dimension(bigJ,bigM) :: bequest_left_ss_j_1, bequest_left_ss_j_2, s_pom_ss_j_1, s_pom_ss_j_2, w_pom_ss_j_1, w_pom_ss_j_2
     real(dp), dimension(bigJ,bigM) :: labor_tax_j_ss_1, labor_tax_j_ss_2
     real(dp), dimension(bigJ,bigM) :: bequest_ss_j_1, bequest_ss_j_2
    real(dp), dimension(bigM) :: bequest_ss_1, bequest_ss_2
                                 
    
    real(dp), dimension(bigJ, bigM) :: b1_ss_j_1, b2_ss_j_1, b1_ss_j_2, b2_ss_j_2
    real(dp) :: ret1_help, ret2_help, savings_ss_pom, pom2
    
 ! progression
    real*8  :: tau, lambda, lambda_trans(bigT),  debt_constr_trans(bigT)
    integer :: i_temp
    real*8  :: tl_com, lambda_com
    !real*8  :: lambda_old = 0.15d0, lambda_new = 0.15d0, progression_param= 0.15d0
! partial 
    real*8  :: avg_aime_replacement_rate(bigJ, bigT)
    integer :: switch_partial_efficiency = 0d0 , iter_theta, if_border, time_iter
    
! elasticity
    real(dp), dimension(bigT) ::  savings_el, k_el, elasticity, savings_base, savings_rel_dif, r_rel_diff
    real(dp), dimension(bigJ, bigT) :: sv_j_el
    real(dp) :: temp_test
    
    real(dp), dimension(bigT) :: delta_K, K_semi_elasticity_reform, K_semi_elasticity_base, delta_proc_r
    real(dp), dimension(bigT) :: r_semi_elasticity_reform, r_semi_elasticity_base, semi_elasticity, tk_reform, tk_base
    real(dp) :: pop_denom
    integer :: switch_partial_semi = 0
    
    ! retirement age 
    integer, dimension(-bigJ:bigT) :: jbar_t_yob ! retirement age of cohort which is j years old at time i
    integer, dimension(bigT) :: new_ret_yob  ! calculate years of birth of new retired
    integer :: last
    integer :: CohortRetAge
    
    integer :: calib_iter, switch_calibration 
     real*8 :: error_pen_sys, rho_l = 0.4d0, rho_u = 1.2d0
     real*8 :: error_labor, phi_l = 0.3d0, phi_u = 0.45d0
     real*8 :: error_tl, tl_l = 0.04d0, tl_u = 0.15d0 ! tl_l = 0.04d0, tl_u = 0.16d0 !
     real*8 :: error_tc, tc_l = 0.02d0, tc_u = 0.07d0
     real*8 :: error_tk, tk_l = 0.15d0, tk_u = 0.35d0
     real*8 :: error_delta, delta_l = 0.99d0**(zbar), delta_u = 1.02d0**(zbar)
     real*8 :: K_Y_target
     
     real*8  :: error_table(1:6), best_table(1:6), error_max , error_tot_min
     integer :: which_correct

end module global_vars