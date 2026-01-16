!===============================================================================
! FILE: transition.f90
!
! DESCRIPTION:
!   Module for computing transition path between two steady states in the
!   overlapping generations (OLG) model. Solves for time-varying general
!   equilibrium with demographic transitions, policy reforms, and TFP shocks
!   from period t=1 (old steady state) to t=bigT (new steady state).
!
! MODULE: transition_DB
!   Contains transition path computation routine
!
! KEY SUBROUTINE:
!   - transition_path_DB: Main iterative solver for transition path equilibrium
!
! TRANSITION PATH EQUILIBRIUM:
!   For each period t = 1 to bigT, find:
!   1. Prices: {r(t), w(m,t)} that clear markets
!   2. Household decisions: {c(j,m,t), l(j,m,t), s(j,m,t)} for all cohorts
!   3. Government policy: {g(t), debt(t)} satisfying budget constraint
!   4. Pension benefits: {b(j,m,t)} from PAYG or funded system
!   Such that:
!   - Households optimize given prices, policy, and expectations
!   - Firms maximize profits period-by-period
!   - Markets clear each period: K(t) + Debt(t) = savings(t-1)
!   - Government budget balances each period (via closure rule)
!   - Terminal conditions: converge to new steady state
!
! COHORT STRUCTURE (key complication):
!   At time t, bigJ cohorts are alive (ages j=1 to bigJ)
!   - Cohort born at calendar time (t-j+1)
!   - Faces demographic conditions from its birth year
!   - Different cohorts have different retirement ages (jbar_t_yob)
!   - Must track cohort-specific pension accumulations
!
! ITERATIVE ALGORITHM:
!   FOR iter_t = 1 TO n_iter_t:
!     1. Compute prices from capital path k(t):
!        r_bar(t) = zbar*alpha*k(t)^(alpha-1) - depr
!        w_bar(m,t) = CES wages from labor aggregation
!
!     2. Calculate pension benefits for all cohorts (include pension_system.f90):
!        - Track wage histories for each cohort
!        - Apply valorization (wage indexation)
!        - Compute benefits at retirement, index post-retirement
!
!     3. Solve household problem via backward induction:
!        - Start from terminal period bigT (use new SS value function)
!        - Work backward: For t = bigT-1 down to 1, j = bigJ down to 1
!        - At each (t,j), solve for optimal {c,l,s} given EV(t+1,j+1)
!        - Handle bequest receipt at specified age (beq_age)
!
!     4. Simulate forward to get distributions:
!        - Start from initial distribution at t=1
!        - Use policy functions to evolve prob(j,a,aime,ε,m,t)
!
!     5. Aggregate across all households:
!        bigl(t) = CES aggregate of labor by type
!        consumption(t) = sum over (j,m) of N(j,m,t) * c(j,m,t)
!        savings(t) = sum over (j,m) of N(j,m,t) * s(j,m,t)
!
!     6. Compute bequests from mortality (include bequest.f90):
!        Deaths between t-1 and t leave assets to survivors
!
!     7. Government budget closure (include closures.f90):
!        g(t) = residual to balance budget (case 6 hardcoded)
!
!     8. Update capital path:
!        k_new(t+1) = [savings(t) - debt(t)] / [nu(t+1)*gam(t+1)]
!        cum_err = sum over t of |k_new(t) - k(t)|
!
!     9. Convergence check:
!        IF cum_err < err_tol: EXIT
!        ELSE: k(t) = up_t*k(t) + (1-up_t)*k_new(t) (damping)
!   END FOR
!
! TIME-VARYING INPUTS (demographic and policy changes):
!   - N_big_t_j(j,m,t): Population by age, type, time (from data)
!   - gam_t(t): TFP growth rate over time
!   - tauL_t(t), tauK_t(t), tauC_t(t): Tax rates over time
!   - rho_t(t): Pension replacement rate over time
!   - jbar_t(t): Retirement age by period (may change with reforms)
!   - jbar_t_yob(yob): Cohort-specific retirement ages
!
! DEPENDENCIES:
!   - get_data: Data structures and utilities
!   - global_vars: Parameter and variable declarations
!   - pfi_trans: Policy function iteration for transition
!
! INCLUDES (via include statements):
!   - Initial_values_db.f90: Initialize transition path guesses
!   - ces_production.f90: CES production function (time-varying)
!   - bequest.f90: Bequest distribution calculation
!   - pension_system.f90: Pension benefit calculation (transition)
!   - closures.f90: Government budget closure (transition)
!   - transition_iterations.f90: Main iteration loop
!   - Print_db.f90: Diagnostic output
!
! NOTES:
!   - Transition horizon bigT typically 250-400 periods (1250-2000 years)
!   - Convergence tolerance err_tol typically 1e-4 to 1e-6
!   - Damping parameter up_t typically 0.5-0.7
!   - Initial capital k(1) from old steady state
!   - Terminal capital k(bigT) should converge to new steady state
!   - Handles heterogeneous agents: income shocks, return shocks, discount shocks
!   - Computes superstar labor income shares for top earners
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
!   Computes full transition path equilibrium from initial steady state (t=1)
!   to terminal steady state (t=bigT). Solves for time-varying general
!   equilibrium with demographic transitions, policy reforms, TFP changes,
!   and cohort overlaps. Core solver for analyzing transition dynamics.
!
! ARGUMENTS:
!   INPUT (control parameters):
!     - switch_tauK_gross: Capital tax treatment (0=net, 1=gross)
!     - switch_unequal_bequest: Bequest distribution mechanism
!         0 = Equal within age cohort
!         1 = Pooled to newborns
!         2 = Unequal via Zipf law
!
!   OUTPUT (equilibrium paths):
!     - l_j(j,m,t): Labor supply by age j, type m, period t
!     - c_j(j,m,t): Consumption by age, type, period
!     - sv_j(j,m,t): End-of-period savings by age, type, period
!     - lab_j(j,m,t): Labor participation by age, type, period
!     - tax_c(t): Consumption tax rate path
!     - r_f(t): After-tax interest rate path
!     - g_per_capita(t): Per capita government spending path
!
! KEY LOCAL VARIABLES (transition paths):
!   Prices:
!     - k(t): Capital stock per effective labor unit
!     - r(t): After-tax net interest rate
!     - r_bar(t): Pre-tax gross interest rate (marginal product of capital)
!     - w_bar(m,t): Pre-tax wage per efficiency unit by education type
!
!   Aggregates:
!     - bigl(t): Aggregate effective labor (CES aggregate)
!     - y(t): Output per effective labor = zbar*k(t)^alpha
!     - bigY(t): Total output = y(t)*bigl(t)
!     - consumption(t): Aggregate consumption
!     - savings(t): Aggregate savings
!
!   Government:
!     - g(t): Government spending per effective labor
!     - debt(t): Government debt per effective labor
!     - Tax(t): Total tax revenue
!     - deficit(t): Budget deficit
!
!   Pension system:
!     - b_j(j,m,t): Pension benefits by age, type, time
!     - subsidy(t): Pension subsidy (benefits - contributions)
!     - valor_mult(t): Valorization factor for benefit indexation
!
!   Bequests:
!     - bequest(m,t): Aggregate bequests by type and time
!     - bequest_j(j,m,t): Bequest receipts by age, type, time
!     - bequest_left_j(j,m,t): Bequests left by deaths
!
!   Demographics:
!     - N_t_j(j,t): Population by age and time
!     - N_big_t_j(j,m,t): Population by age, type, time
!     - nu(t): Labor productivity growth = bigl(t)/bigl(t-1)
!
! ALGORITHM (outer iteration loop):
!   FOR iter_t = 1 TO n_iter_t:
!
!     1. COMPUTE PRICES (for all t):
!        IF switch_exog_rate == 1:
!          r_bar(t) = exogenous rate, k(t) backed out
!        ELSE:
!          r_bar(t) = zbar*alpha*k(t)^(alpha-1) - depr
!        END IF
!        y(t) = zbar*k(t)^alpha
!        w_bar(m,t) = CES production (include ces_production.f90)
!
!     2. PENSION BENEFITS (include pension_system.f90):
!        - Compute avg_wl(t) = average wage at retirement
!        - At retirement: b1_j(jbar,m,t) = rho(t)*avg_wl(t)
!        - Post-retirement: b1_j(j,m,t) = valor_mult(t)*b1_j(j-1,m,t-1)
!        - Subsidy: difference between benefits and contributions
!
!     3. SOLVE HOUSEHOLD PROBLEM (include transition_iterations.f90):
!        a. Backward induction over time and age:
!           FOR t = bigT DOWN TO 1:
!             FOR j = bigJ DOWN TO 1:
!               Solve: max u(c,l) + beta*E[V(t+1,j+1,a',aime',ε')]
!               Subject to: budget constraint, borrowing limit
!               Store: c(j,a,aime,ε,m,t), l(⋅), svplus(⋅), V(⋅)
!             END FOR
!           END FOR
!        b. Forward simulation for distribution:
!           prob(j,a,aime,ε,m,t) evolves using policy functions
!
!     4. AGGREGATE:
!        bigl(t) = [sum_m theta(m,t) * bigl_type(m,t)^rho]^(1/rho)
!        consumption(t) = sum_{j,m} N(j,m,t) * c(j,m,t) / bigl(t)
!        savings(t) = sum_{j,m} N(j,m,t) * sv(j,m,t) / bigl(t)
!
!     5. COMPUTE BEQUESTS (include bequest.f90):
!        Deaths: bequest_left(j,m,t) = [N(j,m,t) - N(j+1,m,t+1)] * r * sv(j,m,t) / gam
!        Distribute according to switch_unequal_bequest rule
!
!     6. GOVERNMENT BUDGET (include closures.f90):
!        g(t) = taxes(t) - [subsidy(t) + debt_service(t) - new_debt(t)]
!
!     7. UPDATE CAPITAL PATH:
!        k_new(t+1) = [savings(t) - debt(t)] / [nu(t+1) * gam(t+1)]
!        cum_err = sum_{t=1}^{bigT} |k_new(t) - k(t)|
!
!     8. CONVERGENCE CHECK:
!        IF cum_err < err_tol: EXIT
!        ELSE: k(t) = up_t*k(t) + (1-up_t)*k_new(t)
!   END FOR
!
! CONVERGENCE CRITERIA:
!   - Tolerance: err_tol (typically 1e-4 to 1e-6)
!   - Maximum iterations: n_iter_t (typically 100-500)
!   - Damping parameter: up_t (typically 0.5-0.7)
!   - Prints cumulative error each iteration if switch_print=1
!
! INITIAL CONDITIONS (t=1):
!   - Capital k(1) from old steady state
!   - Distribution prob(...,1) from old steady state
!   - Policy parameters from old steady state
!
! TERMINAL CONDITIONS (t=bigT):
!   - Capital k(bigT) should converge to new steady state
!   - Value function V(...,bigT) uses new steady state continuation
!   - Policy parameters approach new steady state
!
! TIME-VARYING PARAMETERS:
!   - Demographics: N_big_t_j(j,m,t), pi(j,m,t), jbar_t(t)
!   - TFP growth: gam_t(t)
!   - Taxes: tauL_t(t), tauK_t(t), tauC_t(t)
!   - Pension: rho_t(t), t1_t(t)
!   - Type productivity: type_multiplier_t(m,t)
!
! COHORT TRACKING:
!   - jbar_t_yob(yob): Retirement age by year of birth
!   - Cohort at age j in period t was born in period (t-j+1)
!   - Different cohorts face different lifetime parameters
!
! OUTPUT CALCULATIONS:
!   - Gini coefficients for labor income, total income, wealth
!   - Superstar shares (top earners): labor income, population
!   - Replacement rates: benefits / pre-retirement earnings
!
! NOTES:
!   - Most computationally intensive routine in the model
!   - Transition horizon bigT typically 250-400 periods (1250-2000 years)
!   - Each iteration solves bigT general equilibria
!   - Backward induction ensures perfect foresight
!   - Handles heterogeneous agents across multiple dimensions
!   - Calls output() subroutine at end to write results to files
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
