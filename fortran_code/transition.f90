! WHAT   : transition path for PAYG  
! TAKE   : initial parametrizations and values of the basic variables as a guess on the path,             
! DO     : start iteration, variable_new = f(variable_old) etc. until sum|variable_new(i) - variable_old(i)|< err_tol
! RETURN : generated transition path

MODULE transition_DB
use get_data
use global_vars
use pfi_trans

IMPLICIT NONE 
CONTAINS
subroutine transition_path_DB(switch_residual,switch_tauK_gross, switch_unequal_bequest, param, l_j, c_j, s_j, tax_c, r_f, g_per_capita)

    integer, parameter :: dp = kind(1.0d0)
    real(dp) :: pom
    integer :: i_mark
    real(dp), dimension(n_iter_t) :: cum_err
    real(dp), dimension(bigj+n_p) :: u_all
    real(dp), dimension(bigj) ::  u_init_old
    real(dp), dimension(bigT) :: k_new, k_total, k_star, i_star,  err, sv_flow, debt_share, r_bar, r, u
    real(dp), dimension(bigT) :: upsilon, upsilon_r, upsilon_old, Tax, debt, sum_b, replacement, replacement2, income, nu, nu_pop, labor_tax_revenue
    real(dp), dimension(bigM,bigT) :: bequest
	real(dp), dimension(bigT) :: bigl, bigl_aux, average_l, average_w, subsidy, consumption, consumption_gross, consumption_gross_new, savings, y, k, bigK,wl_bar, bigY,N_t, rI, g, deficit, sum_priv_sv, contribution, gap, valor_mult, r_
    real(dp), dimension(bigj, bigT) :: N_t_j,bigl_j, bigl_j_aux
    real(dp), dimension(bigj, bigM, bigT) :: w_pom_trans, savings_j, b_j, b_j_old, lti_j, consumption_gross_j, bequest_j, bequest_j_old, bequest_left_j, labor_tax_j
	real(dp), dimension(bigj, bigM, bigT) :: denominator_j, sv_j, sv_old_j, sv_pom_j, sv_old_pom_j, subsidy_j,  l_new_j, w_j, u_j, income_j, savings_rate_j, contribution_j
    real(dp), dimension(0:n_a,bigT) :: prob_trans_marg
    real(dp), dimension(bigM, bigT) :: w_bar
    integer, intent(in) :: switch_residual, switch_tauK_gross, switch_unequal_bequest
    integer, intent(in) :: param
    real(dp), dimension(bigT), intent(out) :: r_f, tax_c, g_per_capita

    
    
    real(dp), dimension(bigj, bigM, bigT), intent(out) :: c_j, l_j, s_j
    
    ! partial equilibrum stohastic vs deterministic model 
    ! this is probably not needed for anything
    !real(dp), dimension(bigj) ::  u_init_old_higher_lambda, u_init_old_const_lambda
    !real(dp), dimension(bigT) ::  u_higher_lambda, u_const_lambda, x_c_higher_lambda, c_higher_lambda_tot, disc_higher_lambda
    !real(dp), dimension(bigj, bigT) :: u_j_higher_lambda, mult_partial, x_j_higher_lambda, x_c_j_higher_lambda, sum_eq_higher_lambda
    !real(dp) ::  LS_higher_lambda, S_C_higher_lambda, unif_higher_lambda 
    !real(dp), dimension(bigJ, bigT) :: c_j_higher_lambda, l_j_higher_lambda, sv_j_higher_lambda, sv_pom_j_higher_lambda
    
    
    real(dp), dimension(bigJ, bigM, bigT) :: b1_j, b2_j
    real(dp), dimension(bigJ,bigM,bigT) ::pillarI_j, pillarII_j, pillarI_old_j, pillarII_old_j, contributionI_j, contributionII_j
    real(dp), dimension(bigJ,-bigJ:bigT)  :: life_exp ! -bigJ:bigT is needed for implicit tax when we want to perwfome DC- DC with changing mortality
    real(dp), dimension(bigT) :: b_scale_factor, pillarI, pillarII, contributionI, contributionII
    real(dp) :: accountI, accountII, sv_help, nom1, denom1, nom2, denom2
    
    real(dp) :: avg_wl(bigT)
    
    real(dp),	dimension(bigJ,-bigJ:bigT)	:: tau1_s_t, tau1_a_s_t, tau2_s_t, tau1_s_t_old, tau1_a_s_t_old, tau2_s_t_old
    real(dp),	dimension(bigJ, bigM, -bigJ:bigT)	:: w_pom_j
    integer :: is, ii, si


    
        
    tl = tauL_t
    tk = tauK_t
    
    if (param == 0) then    ! 0 = with old parameters (i.e. overwriting);  1 = with default (transition) parameters
        do i = 1,bigT,1
		    omega(:,i)  = omega_ss
            pi(:,i)     = pi_ss_old
            pi_weight(:,i)     = pi_weight_ss_old
            Nn_(:,i)    = N_ss_old
            gam_t(i)    = gam_ss_old
            jbar_t(i)   = jbar_ss_old
            tL(i)       = tauL_ss_old
            lambda_t(i) = lambda_ss_old
            tK(i)       = tauK_ss_old
            alpha_t(i)       = alpha_ss_old
            debt_constr_t(i) = debt_constr_ss_old
            g_share(i)      = g_share_ss
	    enddo
        gam_cum(1) = gam_t(1)
        do i=2,bigT,1
            gam_cum(i) = gam_cum(i-1)*gam_t(i)
        enddo
    endif

    
t1 = t1_ss_new
t2 =  t2_ss_new
 
do i = 1,n_p,1
    do j =1, bigj, 1
        if (j-i+3 > ofe_u) then 
            t1(j,i) = t1_ss_old
            t2(j,i) = t2_ss_old  
        endif
    enddo
enddo 
t1(:,1) = t1_ss_old
t2(:,1) = t2_ss_old
t1_contrib = t1

if (switch_residual_t == 4) then ! we use contribution closure  
    t1(:,1)  = t1_ss_1
    t1(:,2:) = t1_ss_2
endif 


life_exp = 0
! initial stady state
do j = 1,bigJ,1       
	do s = 0,bigJ-j,1
        is = max(1+s,1)
	        if (s /= bigJ-j) then
	            life_exp(j,1) = life_exp(j,1) + (s+1)*(pi(j+s,1)/pi(j,1))*(1-pi(j+s+1,1)/pi(j+s,1))
	        else
	            life_exp(j,1) = life_exp(j,1) + (s+1)*pi(j+s,1)/pi(j,1) 
        endif
    enddo
enddo 
do i = 2,bigT-bigJ,1
    do j = 1,bigJ,1       
	    do s = 0,bigJ-j,1
            is = max(i+s,1)
	            if (s /= bigJ-j) then
	                life_exp(j,i) = life_exp(j,i) + (s+1)*(pi(j+s,is)/pi(j,max(i,1)))*(1-pi(j+s+1,is+1)/pi(j+s,is))
	            else
	                life_exp(j,i) = life_exp(j,i) + (s+1)*pi(j+s,is)/pi(j,max(i,1)) 
            endif
        enddo
    enddo 
enddo
do i = bigT-bigJ,bigT,1
    life_exp(:,i) = life_exp(:,bigT-bigJ)
enddo


           !!!INITIAL VALUES
include 'Initial_values_db.f90'


    
    N_t_j = Nn_
    N_t = sum(N_t_j, dim=1)

    bigl_j = 0.0d0
    bigl_j_aux = 0.0d0
    
    do m = 1,bigM,1
        
        bigl_j = bigl_j + bigM_share_ss(m) * N_t_j*l_j(:,m,:)
        bigl_j_aux = bigl_j_aux + bigM_share_ss(m) * N_t_j*l_j(:,m,:)
    enddo
    
    bigl = sum(bigl_j, dim=1)
    bigl_aux = sum(bigl_j_aux, dim=1)
    
  
    nu(1) = nu_ss_old
    nu_pop(1) = nu_ss_old
    !nu(1) = 1 
    do i = 2,bigT,1
        nu(i) = bigl(i)/bigl(i-1)
        nu_pop(i) = N_t(i)/N_t(i-1)
    enddo 


    r_bar = zbar*alpha_t*k**(alpha_t - 1) - depr
    do m = 1,bigM
        w_bar(m,:) = zbar*(1 - alpha_t)*k**alpha_t * type_multiplier(m)
    enddo
    y = zbar*k**(alpha_t)
    
    bigK = k * bigl
    bigY = y * bigl

    do i = n_p+2,bigT,1
        tc(i) = tc_new
        !tl(i) = tl_new
    enddo

    
    
    lambda_trans = lambda_t
    debt_constr_trans = debt_constr_t
    
    !lambda_trans(1) = lambda_ss_old
    !do i = 2,bigT,1
    !    lambda_trans(i) = lambda_new
    !enddo
        
    savings_j = sv_j
    
    savings = 0.0d0
    do m = 1,bigM,1
        savings = savings + bigM_share_ss(m) * sum(N_t_j *savings_j(:,m,:), dim=1)/bigl
    enddo    
    
    wl_bar = 0.0d0
    do i = 1,bigT,1
        do m = 1,bigM,1
           wl_bar(i) = wl_bar(i) +  bigM_share_ss(m) * sum( N_t_j(:,i) * l_j(:,m,i) * w_bar(m,i), dim=1)   
        enddo
    enddo
    valor_mult(1) = (1 + valor_share*(gam_t(1)*nu(1) - 1))/gam_t(1)
    valor_mult(2) = (1 + valor_share*(gam_t(1)*nu(1) - 1))/gam_t(2)
    
    
    do i = 3,bigT,1
        valor_mult(i) = (1 + valor_share*(gam_t(i-1)*(wl_bar(i-1))/(wl_bar(i-2))-1))/gam_t(i)
    enddo
    
    if (switch_tauK_gross == 0) then
        r = 1 + (1 - tk)*r_bar  
        else
        r = 1 + (1 - tk)*(r_bar+depr) - depr 
    endif
    


include 'bequest.f90'

consumption = 0.0d0
do m=1,bigM,1
    consumption = consumption + bigM_share_ss(m) * sum(N_t_j*c_j(:,m,:), dim=1)/bigl       
enddo

    consumption_gross = consumption!/(1+tc)
    consumption_gross_new = consumption_gross
do i = 1, n_p, 1
    labor_tax_j(:,:,i) = labor_tax_j_ss_1
enddo
do i = n_p +1, bigT, 1
    labor_tax_j(:,:,i) = labor_tax_j_ss_2
enddo
avg_aime_replacement_rate = 0.33d0
!LabIncAVG_vfi = 0.33d0*w_bar
!!!!!!!!!!!!!!!!! iterations start 
 include 'transition_iterations.f90' 

!!!!!!!!!!!!!!!!! iterations end

    !do i = 2,bigT,1
    !    do j = 1,bigJ,1
    !        if (j == 1) then
    !            income_j(j,i) = w_j(j,i)*l_j(j,i) + b_j(j,i)  - upsilon(i) + bequest_j(j,i)
    !        else
    !            income_j(j,i) = r(i)*sv_j(j-1,i-1)/gam_t(i) + w_j(j,i)*l_j(j,i) + b_j(j,i)  - upsilon(i) + bequest_j(j,i)
    !        endif
    !    enddo
    !    savings_rate_j(:,i) = sv_j(:,i)/income_j(:,i)
    !enddo
    !
    !income = sum(N_t_j*income_j, dim=1)/bigl
tax_c = tc

 !include 'utility_trans.f90' 


! which budget constrain doeas not hold 
! budget constrain 
!do j = 1, bigJ, 1
!    if (j == 1) then
!         write(*,*) (1 - tl(2))*w_j(j,2)*l_j(j,2) - upsilon(2) + bequest_j(j,2) - (1+tc(2)) *c_j(j,2) - sv_j(j,2)
!    else
!         write(*,*) r(2)*sv_j(j-1,1)/gam_t(2) +  sum_b_weight_trans(2)*b_j(j,2) + (1 - tl(2))*w_j(j,2)*l_j(j,2) - upsilon(2) + bequest_j(j,2) - (1+tc(2)) *c_j(j,2) - sv_j(j,2)
!    endif 
!enddo 
! 
     prob_trans_marg = 0d0
     do i = 1,bigT,1
            do ia = 0, n_a, 1
                 do j = 1, bigJ  
                     do i_aime = 0, n_aime, 1
                          do ip = 1 , n_sp, 1
                            do ir=1, n_sr, 1
                                do id=1,n_sd,1 
                                prob_trans_marg(ia,i) = prob_trans_marg(ia,i) + prob_trans(j, ia, i_aime, ip, ir, id,i)* N_t_j(j,i)/N_t(i)
                                enddo
                            enddo
                        enddo
                    enddo
                enddo
            enddo
     enddo
     


if (switch_print == 1) then
    ! printing on screen
    include 'print_iter.f90'
    ! PRINTING TO FILES
    include 'Print_db.f90'
endif

call output


 
end subroutine transition_path_DB

END MODULE transition_DB