
    

MODULE partial_eqm_calc
use global_vars
!use individual_vf
use pfi_trans


IMPLICIT NONE

CONTAINS

subroutine partial_eqm_solve(switch_residual, switch_tauK_gross, switch_unequal_bequest, param_ss, switch_type,  rho, r_bar_ss,  w_bar_ss, upsilon_ss, b_ss_j, l_ss_j, w_ss_j, s_ss_j, c_ss_j, asset_ss_j, lab_income_ss_j, t1_ss, b1_ss_j, b2_ss_j, pillarI_ss_j, pillarII_ss_j, bequest_ss_j,l_ss_j_var, s_pom_ss_j_var, c_ss_j_var, asset_ss_j_var, lab_income_ss_j_var, gini_weight_ss )
    real(dp), intent(in) :: r_bar_ss, w_bar_ss, upsilon_ss ! prices
    real(dp), dimension(bigj) :: pi_ss, life_exp, pi_weight_ss
    real(dp), dimension(bigj) :: savings_ss_j, lti_ss_j,  consumption_ss_gross_j, u_ss_j, income_ss_j, savings_ss_rate_j
	real(dp), dimension(bigj) :: denominator_j, subsidy_ss_j, N_ss_j, bequest_ss_j
    real*8, dimension(0:n_a) :: prob_ss_marg
    real(dp), intent(in)  :: rho	
    integer, intent(in)   :: param_ss
    integer, intent(in)   :: switch_residual, switch_type, switch_tauK_gross, switch_unequal_bequest			
    real(dp) ::  jbar_ss, gam_ss, N_ss, nu_ss, t1_ss, r_ss
    real(dp), dimension(bigj), intent(out) :: l_ss_j, w_ss_j, s_ss_j, c_ss_j, asset_ss_j, lab_income_ss_j, l_ss_j_var, s_pom_ss_j_var, c_ss_j_var, asset_ss_j_var, lab_income_ss_j_var  
    real(dp), dimension(bigj,n_a), intent(out) :: gini_weight_ss
    

    ! pension system 
     real(dp), dimension(bigj) :: b1_ss_j, b2_ss_j, pillarI_ss_j, pillarII_ss_j, &
                                 contributionI_ss_j, contributionII_ss_j, b_ss_j
    
     real(dp) ::  accountI_ss, accountII_ss, pillarI_ss, pillarII_ss, rI_ss, b_scale_factor_ss, t2_ss, &
                nom1, denom1, nom2, denom2
     real(dp), dimension(bigj) :: tau1_ss, tau1_a_ss, tau2_ss, b_pom_ss_j, w_pom_ss_j, s_pom_ss_j
    real(dp) :: displs
    
    real(dp), dimension(bigj, n_a) :: V_ss_j

    if (param_ss == 0) then ! 0 = with old parameters;  1 = with new parameters
        alpha = alpha_ss_old
        gam_ss = gam_ss_old
        pi_ss = pi_ss_old 
        pi_weight_ss = pi_weight_ss_old
        N_ss_j =  N_ss_old
        jbar_ss = jbar_ss_old
        nu_ss =  nu_ss_old
        t1_ss = t1_ss_old
        t2_ss = t2_ss_old
        tL_ss   = tauL_ss_old
        tK_ss   = tauK_ss_old
        lambda= lambda_ss_old
        debt_constr= debt_constr_ss_old
        pi_ip = pi_ip_ss_old
        n_sp_value = n_sp_value_ss_old
        pi_ip_init = pi_ip_init_ss_old
        g_share_ss = g_share_ss
        
    else 
        alpha = alpha_ss_new
        gam_ss = gam_ss_new
        pi_ss = pi_ss_new
        pi_weight_ss = pi_weight_ss_new
        N_ss_j =  N_ss_new
        jbar_ss = jbar_ss_new
        nu_ss = nu_ss_new
        t1_ss = t1_ss_new
        t2_ss = t2_ss_new
        tL_ss  = tauL_ss_new
        tK_ss   = tauK_ss_new
        lambda = lambda_ss_new
        pi_ip = pi_ip_ss_new
        debt_constr= debt_constr_ss_new
        n_sp_value = n_sp_value_ss_new
        pi_ip_init = pi_ip_init_ss_new
        g_share_ss = g_share_ss_2
    endif

    
    
    !  here we rebuild shock grids 

        pi_id = pi_id_hold
        n_sd_value = n_sd_value_hold
        pi_ir = pi_ir_hold
        n_sr_value = n_sr_value_hold
        pi_id_ret = pi_id_hold
        n_sd_value_ret = n_sd_value_hold
        pi_ir_ret = pi_ir_hold
        n_sr_value_ret = n_sr_value_hold
    
    
    if (switch_discount_risk==0) then
    n_sd_value(:) = 0.0d0
    n_sd_value_ret(:) = 0.0d0
    endif
    
    if (switch_return_risk==0) then
    n_sr_value(:) = 0.0d0
    n_sr_value_ret(:) = 0.0d0
    endif
    
    if (switch_no_ret_delta_risk==1) then
    n_sd_value_ret(:) = 0.0d0
    elseif (switch_no_ret_delta_risk==2) then
        pi_id_ret(:,:) = 0.0d0
        do  s = 1, n_sd, 1
            pi_id_ret(s,s) = 1.0d0     
        enddo
    endif
    
    
    if (switch_no_ret_return_risk==1) then
    n_sr_value_ret(:) = 0.0d0
    endif
    
    if (switch_longevity_pe==2) then
    pi_ss = pi_ss_new
    endif
    
    if (switch_popweight_pe==2) then
    pi_weight_ss = pi_weight_ss_new
    endif
    
    if (switch_taxes_pe==2) then
        t1_ss = t1_ss_new
        t2_ss = t2_ss_new
        tL_ss   = tauL_ss_new
        tK_ss   = tauK_ss_new
        lambda= lambda_ss_new
    endif
        


life_exp = 0
do j = 1,bigJ,1       
    do s = 0,bigJ-j,1
        if (s /= bigJ-j) then
            life_exp(j) = life_exp(j) + (s+1)*(pi_ss(j+s)/pi_ss(j))*(1-pi_ss(j+s+1)/pi_ss(j+s))
        else ! i.e. s==bigJ-j
            life_exp(j) = life_exp(j) + (s+1)*pi_ss(j+s)/pi_ss(j)  
        endif
    enddo
enddo  




    
    if (switch_tauK_gross == 0) then
        r_ss = 1 + (1 - tk_ss)*r_bar_ss  
        else
        r_ss = 1 + (1 - tk_ss)*(r_bar_ss + depr) - depr
    endif
    
    w_ss_j = (1-tl_ss)*(1 - t1_ss-t2_ss)*w_bar_ss
    

    


        w_pom_ss_vfi = (1.0_dp - t1_ss - t2_ss)*w_bar_ss 
        w_pom_ss_implicit_vfi = (t1_ss*tau1_ss +  t2_ss*tau2_ss)*w_bar_ss
        
        if (switch_tauK_gross == 0) then
            r_ss_vfi = (1d0 - tk_ss)*r_bar_ss  
            else
            r_ss_vfi = (1d0 - tk_ss)*(r_bar_ss+depr) - depr
        endif
        
        tc_ss_vfi = 1_dp + tc_ss
        gam_ss_vfi = gam_ss
        pi_ss_vfi = pi_ss
        b_ss_j_vfi = b_ss_j
        bequest_ss_j_vfi =  bequest_ss_j
        jbar_ss_vf = ceiling(jbar_ss)
        upsilon_ss_vf = upsilon_ss
        N_ss_j_vfi =  N_ss_j
        iter_com = iter
        call agent_vf()
        c_ss_j = c_ss_j_vfi
        l_ss_j = l_ss_j_vfi
        asset_ss_j = asset_pom_ss_j
        l_ss_j_var = l_ss_j_var_vfi
        c_ss_j_var = c_ss_j_var_vfi
        s_pom_ss_j_var = s_pom_ss_j_var_vfi
        asset_ss_j_var = asset_ss_j_var_vfi
        lab_income_ss_j_var =lab_income_ss_j_var_vfi
        s_pom_ss_j(1:bigJ-1) = s_pom_ss_j_vfi(1:bigJ-1) 
        if ((switch_type == 1) .and. (switch_see_ret == 1)) then 
            do j = 1,bigj,1  
                if (j == 1) then
                    s_ss_j(j) = (w_pom_ss_vfi(j))*l_ss_j(j) - labor_tax_ss_j_vfi(j) - c_ss_j(j)*(1+tc_ss)  - upsilon_ss + bequest_ss_j(j)
                else
                    s_ss_j(j) = r_ss*s_ss_j(j-1)/gam_ss + (w_pom_ss_vfi(j))*l_ss_j(j) - labor_tax_ss_j_vfi(j) + b_ss_j(j) - c_ss_j(j)*(1d0+tc_ss)  - upsilon_ss + bequest_ss_j(j)
                endif
            enddo
        else
           s_ss_j(:) =  s_pom_ss_j
        endif
        avg_ef_l_suply =  sum(N_ss_j(1:jbar_ss-1)*l_ss_j_vfi(1:jbar_ss-1))/sum(N_ss_j(1:jbar_ss-1))
        LabIncAVG_ss_vfi =  sum(N_ss_j(1:jbar_ss-1)*l_ss_j_vfi(1:jbar_ss-1)*w_pom_ss_vfi(1:jbar_ss-1))/sum(N_ss_j(1:jbar_ss-1))
        gini_weight_ss  = gini_weight_sv



end subroutine partial_eqm_solve

END MODULE partial_eqm_calc