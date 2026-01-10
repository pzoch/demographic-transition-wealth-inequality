!===============================================================================
! FILE: transition.f90
!
! DESCRIPTION:
!   Module for computing transition path between two steady states in the OLG
!   model. Solves for time-varying general equilibrium given demographic changes,
!   policy reforms, and productivity shocks over the transition horizon.
!
! MODULE: transition_DB
!   Contains transition path computation routine
!
! SUBROUTINE:
!   - transition_path_DB: Main iterative solver for transition path equilibrium
!
! ALGORITHM:
!   1. Initialize guess for capital path {k(t)} from steady states
!   2. For each period t = 1,...,bigT:
!      a. Compute factor prices r(t), w(t) from production
!      b. Calculate pension benefits for all cohorts alive at t
!      c. Solve household problem via backward induction PFI
!      d. Aggregate decisions across cohorts and types
!      e. Compute bequests and government budget for period t
!   3. Update capital path based on aggregate savings
!   4. Iterate until convergence: sum_t |k_new(t) - k_old(t)| < tol
!
! DEPENDENCIES:
!   - get_data: Data structures and utilities
!   - global_vars: Parameter and variable declarations
!   - pfi_trans: Policy function iteration for transition
!
! NOTES:
!   - Initial conditions from "old" steady state (t=1)
!   - Terminal conditions approach "new" steady state (t=bigT)
!   - Cohorts overlap across periods creating complex dynamics
!   - Handles demographic transitions, policy reforms, TFP shocks simultaneously
!===============================================================================

MODULE transition_DB
use get_data
use global_vars
use pfi_trans

IMPLICIT NONE 
CONTAINS

!-------------------------------------------------------------------------------
! SUBROUTINE: transition_path_DB
!
! PURPOSE:
!   Computes full transition path from initial to terminal steady state.
!   Solves for time-varying general equilibrium with demographic changes,
!   policy reforms, and aggregate shocks.
!
! ARGUMENTS (selected key inputs/outputs):
!   INPUT:
!     - switch_tauK_gross: Capital tax treatment (0=net, 1=gross)
!     - switch_unequal_bequest: Bequest distribution mechanism (0/1/2)
!   OUTPUT:
!     - l_j(j,m,t): Labor supply by age, type, and time
!     - c_j(j,m,t): Consumption by age, type, and time
!     - sv_j(j,m,t): Savings by age, type, and time
!     - lab_j(j,m,t): Labor hours by age, type, and time
!     - tax_c(t): Consumption tax revenue path
!     - r_f(t): After-tax interest rate path
!     - g_per_capita(t): Government spending per capita path
!
! LOCAL VARIABLES (key transition paths):
!   - k(t): Capital stock per effective labor
!   - r(t), r_bar(t): Net and gross interest rates
!   - w_bar(m,t): Average wage by type
!   - bigl(t): Aggregate effective labor
!   - y(t): Output per effective labor
!   - g(t): Government spending
!   - debt(t): Government debt
!   - Tax(t): Total tax revenue
!   - b_j(j,m,t): Pension benefits
!   - bequest(m,t): Aggregate bequests by type
!   - N_t_j(j,t): Population by age
!
! ALGORITHM DETAILS:
!   Outer loop (up to n_iter_t iterations):
!     For t = 1 to bigT:
!       1. Compute factor prices from k(t) via production function
!       2. Calculate pension benefits for all cohorts using past wages
!       3. Solve household problem via backward PFI:
!          - Start from terminal period with known terminal SS value
!          - Work backward computing value/policy functions
!          - Handle bequest shocks at specified age
!       4. Simulate forward to get distributions
!       5. Aggregate to get macro variables: bigl(t), savings, consumption
!       6. Compute bequests using mortality and bequest rules
!       7. Apply government budget closure to balance budget
!       8. Update k(t+1) from aggregate savings and population growth
!     
!     Check convergence:
!       err = sum over t of |k_new(t) - k_old(t)|
!       If err < err_tol, exit; else damp update and continue
!
! PENSION SYSTEM:
!   - Calculates benefits using earnings history (AIME)
!   - Handles both PAYG and funded pillars
!   - Applies valorization and indexation rules
!   - Cohort-specific retirement ages via jbar_t_yob array
!
! GOVERNMENT BUDGET:
!   Multiple closure rules (via switch_residual):
!     0: Lump-sum transfers adjust (upsilon residual)
!     1: Consumption tax adjusts (tauC residual)
!     2: Debt adjusts (debt residual)
!     6: Spending adjusts (g residual)
!
! CONVERGENCE:
!   - Tolerance: err_tol (typically 1e-6)
!   - Maximum iterations: n_iter_t (typically 100-500)
!   - Damping: up_t parameter smooths capital path updates
!   - Prints cumulative error each iteration if switch_print=1
!
! INITIAL/TERMINAL CONDITIONS:
!   - k(1) initialized from old steady state
!   - k(bigT) should converge to new steady state
!   - Value functions at bigT use terminal steady state
!   - Population N_t_j from demographic projections
!
! NOTES:
!   - Handles cohort overlaps: at time t, ages 1 to bigJ are alive
!   - Each cohort born at different calendar time with different parameters
!   - Bequests distributed according to switch_unequal_bequest rule
!   - Supports heterogeneous mortality (switch_het_mortality)
!   - Can fix labor supply (switch_fix_labor) or solve endogenously
!   - Includes "superstar" workers with higher productivity
!-------------------------------------------------------------------------------
subroutine transition_path_DB(switch_tauK_gross, switch_unequal_bequest, l_j, c_j, sv_j, tax_c, r_f, g_per_capita, lab_j)

    integer, parameter :: dp = kind(1.0d0)
    real(dp) :: pom, placeholder
    integer :: i_mark
    real(dp), dimension(n_iter_t) :: cum_err
    real(dp), dimension(bigj+n_p) :: u_all
    real(dp), dimension(bigj) ::  u_init_old
    real(dp), dimension(bigT) :: k_new, k_total, k_star, i_star,  err, sv_flow, debt_share, r_bar, r, u
    real(dp), dimension(bigT) :: Tax, debt, sum_b, replacement, replacement2, income, nu, nu_pop, labor_tax_revenue
    real(dp), dimension(n_beq,bigM,bigT) :: beq_zipf_trans_big
    real(dp), dimension(bigM,bigT) :: bequest, bigl_type
	real(dp), dimension(bigT) :: bigl, bigl_aux, average_l, average_lab, average_w, subsidy, consumption, consumption_gross, consumption_gross_new, savings, y, k, bigK, wl_bar, bigY,N_t, rI, g, deficit, sum_priv_sv, contribution, gap, valor_mult, r_, multiplier_ces, check_pension_clearing, superstar_labinc_share_trans, superstar_pop_share_trans, superstar_totinc_share_trans, labinc_superstar_trans, totinc_superstar_trans, pop_superstar_trans, labinc_aggregate_trans, totinc_aggregate_trans, bequest_trans
    real(dp), dimension(bigj, bigT) :: N_t_j,bigl_j, bigl_j_aux
    real(dp), dimension(bigj, bigM, bigT) :: N_big_t_j
    real(dp), dimension(bigj, bigM, bigT) :: w_pom_trans, savings_j, b_j, b_j_old, lti_j, consumption_gross_j, bequest_j, bequest_j_old, bequest_left_j, labor_tax_j
	real(dp), dimension(bigj, bigM, bigT) :: denominator_j, sv_old_j, sv_pom_j, sv_old_pom_j, subsidy_j,  l_new_j, w_j, u_j, income_j, savings_rate_j, contribution_j, type_share_j_t
    real(dp), dimension(0:n_a,bigT) :: prob_trans_marg
    real(dp), dimension(bigM, bigT) :: w_bar
    integer, intent(in) :: switch_tauK_gross, switch_unequal_bequest
    real(dp), dimension(bigj, bigM, bigT), intent(out) :: c_j, l_j, sv_j, lab_j
    real(dp), dimension(bigT), intent(out) :: r_f, tax_c, g_per_capita
    
    
    
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
    tc = tauC_t
    do i = 1,bigT,1
        do j = 1,bigJ,1
        t1(j,i) = t1_t(i)
        enddo
    
    enddo
    
    

    N_big_t_j = Nn_big

    

t2 = t2_ss_new
 
t2(:,1) = t2_ss_old
t1_contrib = t1



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


     

    debt = debt_trans
    N_t_j = sum(N_big_t_j,dim=2)
    N_t = sum(N_t_j, dim=1)
    bigl_type = 0.0d0
    bigl      = 0d0
    bigl_j = 0.0d0
    bigl_j_aux = 0.0d0
    
    do m = 1,bigM,1
        bigl_type(m,:)         = sum(N_big_t_j(:,m,:) * l_j(:,m,:), dim = 1 )
        bigl                   = bigl + type_multiplier_t(m,:) * bigl_type(m,:) ** rho_subst 

    enddo
    
    ! create a big matrix of cohort type shares
    do m = 1,bigM,1
    do i = 1,bigT,1
         
         do j = 1,bigJ,1
          type_share_j_t(j,m,i) = N_big_t_j(j,m,i) / sum(N_big_t_j(j,:,i))
         enddo
    enddo
     
enddo
    
    
    bigl = bigl ** (1.0d0/rho_subst)        
    
    nu(1) = nu_ss_old
    nu_pop(1) = nu_ss_old
    !nu(1) = 1 

    do i = 2,bigT,1
        nu(i) = bigl(i)/bigl(i-1)
        nu_pop(i) = N_t(i)/N_t(i-1)
    enddo 


    if (switch_exog_rate == 1) then
    r_bar     = (exog_rate_t/100 + 1d0)**(zbar) - 1
    k         = ((r_bar + depr_t)/(alpha_t*zbar))**(1/(alpha_t - 1))

    else
            
    r_bar = zbar*alpha_t*k**(alpha_t - 1) - depr_t

    endif
    

    y = zbar*k**(alpha_t)

    include 'ces_production.f90'
    
    bigK = k * bigl
    bigY = y * bigl

    lambda_trans = lambda_t
    debt_constr_trans = debt_constr_t
    
    !lambda_trans(1) = lambda_ss_old
    !do i = 2,bigT,1
    !    lambda_trans(i) = lambda_new
    !enddo
        
    savings_j = sv_j
    
    savings = 0.0d0
    do m = 1,bigM,1
        savings = savings +  sum(N_big_t_j(:,m,:)  *savings_j(:,m,:), dim=1)
    enddo    
    
    savings = savings / bigl
    
    wl_bar = 0.0d0
    do i = 1,bigT,1
        do m = 1,bigM,1
           wl_bar(i) = wl_bar(i) +  sum(N_big_t_j(:,m,i) * l_j(:,m,i) * w_bar(m,i), dim=1)   
        enddo
    enddo
    ! valor_share removed - was always 1.0 (full indexation)
    valor_mult(1) = (1 + 1.0d0*(gam_t(1)*nu(1) - 1))/gam_t(1)
    valor_mult(2) = (1 + 1.0d0*(gam_t(1)*nu(1) - 1))/gam_t(2)
    
    
    do i = 3, bigT, 1
        valor_mult(i) = (1 + 1.0d0*(gam_t(i-1)*(wl_bar(i-1))/(wl_bar(i-2))-1))/gam_t(i)
    enddo
    
    if (switch_tauK_gross == 0) then
        r = 1 + (1 - tk)*r_bar  
        else
        r = 1 + (1 - tk)*(r_bar+depr_t) - depr_t 
    endif
    


include 'bequest.f90' !! review this to see if new pi is accounted for

consumption = 0.0d0
do m=1,bigM,1
    consumption = consumption + sum(N_big_t_j(:,m,:)  * c_j(:,m,:), dim=1)/bigl       
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
    !            income_j(j,i) = w_j(j,i)*l_j(j,i) + b_j(j,i)   + bequest_j(j,i)
    !        else
    !            income_j(j,i) = r(i)*sv_j(j-1,i-1)/gam_t(i) + w_j(j,i)*l_j(j,i) + b_j(j,i)   + bequest_j(j,i)
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
!         write(*,*) (1 - tl(2))*w_j(j,2)*l_j(j,2)  + bequest_j(j,2) - (1+tc(2)) *c_j(j,2) - sv_j(j,2)
!    else
!         write(*,*) r(2)*sv_j(j-1,1)/gam_t(2) +  sum_b_weight_trans(2)*b_j(j,2) + (1 - tl(2))*w_j(j,2)*l_j(j,2)  + bequest_j(j,2) - (1+tc(2)) *c_j(j,2) - sv_j(j,2)
!    endif 
!enddo 
! 
     !prob_trans_marg = 0d0
     !do i = 1,bigT,1
     !       do ia = 0, n_a, 1
     !            do j = 1, bigJ  
     !                do i_aime = 0, n_aime, 1
     !                     do ip = 1 , n_sp, 1
     !                       do ir=1, n_sr, 1
     !                           do id=1,n_sd,1 
     !                           prob_trans_marg(ia,i) = prob_trans_marg(ia,i) + prob_trans(j, ia, i_aime, ip, ir, id,i)
     !                           enddo
     !                       enddo
     !                   enddo
     !               enddo
     !           enddo
     !       enddo
     !enddo
     !


!share calculation

superstar_labinc_share_trans(:) = 0.0d0
superstar_pop_share_trans(:) = 0.0d0        
labinc_superstar_trans(:) = 0.0d0
pop_superstar_trans(:) = 0.0d0
labinc_aggregate_trans(:) = 0d0
totinc_aggregate_trans(:) = 0d0
totinc_superstar_trans(:) = 0d0

do i = 1,bigT,1    
do j = 1, bigJ, 1

    do m = 1, bigM, 1
        do ia = 0, n_a, 1
            do i_aime = 0, n_aime, 1
                do ip = 1, n_sp, 1
                    do ir = 1, n_sr, 1
                        do id = 1, n_sd, 1
                        
                        if (ip > n_sp_risk - n_superstar) then
                            if (j < jbar_t_vfi(i)) then
                        labinc_superstar_trans(i) =  lab_income_pretax_trans_big(j, ia, i_aime, ip, ir, id,m,i) * (prob_trans_big(j, ia, i_aime, ip, ir, id,m,i)*N_big_t_j(j,m,i)/sum(N_big_t_j(:,:,i))) + labinc_superstar_trans(i)
                        totinc_superstar_trans(i) =  tot_income_trans_big(j, ia, i_aime, ip, ir, id,m,i) * (prob_trans_big(j, ia, i_aime, ip, ir, id,m,i)*N_big_t_j(j,m,i)/sum(N_big_t_j(:,:,i))) + totinc_superstar_trans(i)
                        endif
                        if (j<jbar_t_vfi(i)) then
                        pop_superstar_trans(i) = prob_trans_big(j, ia, i_aime, ip, ir, id,m,i)*N_big_t_j(j,m,i)  + pop_superstar_trans(i)
                        endif 
                        endif
                        labinc_aggregate_trans(i) = lab_income_pretax_trans_big(j, ia, i_aime, ip, ir, id,m,i) * (prob_trans_big(j, ia, i_aime, ip, ir, id,m,i)*N_big_t_j(j,m,i)/sum(N_big_t_j(:,:,i))) + labinc_superstar_trans(i)
                        totinc_aggregate_trans(i) = tot_income_trans_big(j, ia, i_aime, ip, ir, id,m,i) * (prob_trans_big(j, ia, i_aime, ip, ir, id,m,i)*N_big_t_j(j,m,i)/sum(N_big_t_j(:,:,i))) + totinc_aggregate_trans(i)
                        enddo        
                    enddo
                enddo
            enddo
        enddo
    enddo
enddo
enddo
superstar_labinc_share_trans = labinc_superstar_trans / labinc_aggregate_trans
do i =1,bigT,1
    superstar_labinc_share_trans(i) = labinc_superstar_trans(i) / labinc_aggregate_trans(i)
superstar_totinc_share_trans(i) = totinc_superstar_trans(i) / totinc_aggregate_trans(i)
superstar_pop_share_trans(i) = pop_superstar_trans(i) / sum(N_big_t_j(1:(jbar_t_vfi(i)-1),:,i))
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
