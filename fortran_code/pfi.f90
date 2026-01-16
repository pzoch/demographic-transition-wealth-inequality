!===============================================================================
! FILE: pfi.f90
!
! DESCRIPTION:
!   Master module for Policy Function Iteration (PFI) in heterogeneous-agent OLG
!   model. Solves household dynamic optimization problem using Euler equation method
!   with progressive taxation, endogenous labor, AIME-dependent pensions, and multiple
!   shocks. Includes distribution computation and aggregation routines.
!
! MODULE: pfi_trans
!   Comprehensive module containing all household problem solving routines, utility
!   functions, distribution methods, and aggregation procedures.
!
! PURPOSE:
!   Central computational workhorse for the OLG model. Takes prices {r, w, tc} and
!   policy {τ, λ, ρ, b} as given, then:
!   1. Solves household optimization → policy functions {c, l, a'}
!   2. Computes equilibrium distribution → prob(j,a,aime,ε,δ,r)
!   3. Aggregates to get macro variables → {C, L, K, Tax, Pensions}
!
! MAIN ALGORITHM - POLICY FUNCTION ITERATION:
!   Backward iteration over ages j = bigJ,...,1:
!   1. Terminal period (j=bigJ): Simple consumption-savings problem
!   2. Working ages (j < jbar): Labor-leisure choice with progressive taxes
!   3. Retirement (j ≥ jbar): Pension income with AIME-dependent benefits
!
!   At each (j,a,aime,ε,δ,r):
!   a. Compute RHS of Euler equation: E[δ(1+r)u'(c',l')|ε]
!   b. Invert to get optimal consumption: c* s.t. u'(c*,l*) = RHS
!   c. Find labor l* from intra-temporal FOC: u_l/u_c = w(1-τ')
!   d. Back out savings: a' = (1+r)a + wεl + b - c - tax
!   e. Update AIME: aime' = f(aime, wεl) [US Social Security formula]
!   f. Store: c(j,a,aime,ε,δ,r), l(⋅), a'(⋅), aime'(⋅), V(⋅)
!
! KEY FEATURES:
!   - Progressive taxation: τ(income) = 1 - (1-τ)×(income/avg)^(-λ)
!   - Endogenous labor: u(c,l) with intra-temporal optimality
!   - AIME tracking: Average indexed monthly earnings for Social Security
!   - Multiple shocks: Permanent (ε_p), persistent (ε_r), discount (δ), return (r)
!   - Bequest receipt: Optional mid-life wealth transfer (switch_unequal_bequest=2)
!   - Hand-to-mouth risk: Optional binding borrowing constraint shocks
!
! KEY FUNCTIONS:
!   - margu(c,l,tc): Marginal utility ∂u/∂c = φ(c^φ×(1-l)^(1-φ))^(1-θ)/c
!   - valuefunc(_trans): Lifetime utility V(j,a,aime,ε) = u(c,l) + δπE[V(j+1,⋅)]
!   - year(it,ij,ijj): Time index conversion for cohort tracking
!   - optimal_labor(c,w,⋅): Newton-Raphson solver for labor given consumption
!   - optimal_consumption_and_labor_new: Joint (c,l) optimizer using bisection+Newton
!
! KEY SUBROUTINES:
!   HOUSEHOLD PROBLEM:
!   - household_ss: Solve for steady state (included from pfi_household_problem.f90)
!   - household_trans_endo: Solve for transition path (included file)
!   - agent_vf: Wrapper for steady state solve + distribution + aggregation
!   - get_transition: Wrapper for transition solve + distribution + aggregation
!
!   DISTRIBUTION:
!   - get_distribution_ss: Forward simulation to get prob_ss(j,⋅) (pfi_distribution.f90)
!   - get_distribution_trans: Same for transition path (pfi_distribution.f90)
!
!   AGGREGATION:
!   - aggregation_ss: Compute cohort averages and distributional stats (pfi_agregation.f90)
!   - aggregation_trans: Same for transition (pfi_agregation.f90)
!
!   UTILITY:
!   - initialize_trans: Set up grids (sv, aime), survival probabilities, AIME formula
!   - comptax: Compute tax paid and marginal rate given progressive schedule
!   - foc_intratemp: Solve intra-temporal FOC for (c,l) given available resources
!
! STATE SPACE (6-dimensional + age):
!   Individual state s = (j, a, aime, ip, ir, id):
!   - j ∈ {1,...,bigJ}: Age (5-year periods, typically bigJ=16 for ages 20-99)
!   - a ∈ [a_l, a_u]: Assets, discretized to ia ∈ {0,...,n_a} (n_a ≈ 50-100)
!   - aime ∈ [aime_l, aime_u]: AIME for Social Security, grid i_aime ∈ {0,...,n_aime}
!   - ip ∈ {1,...,n_sp}: Permanent/persistent productivity shock index
!   - ir ∈ {1,...,n_sr}: Return shock index (portfolio heterogeneity)
!   - id ∈ {1,...,n_sd}: Discount factor shock index (preference heterogeneity)
!
! HOUSEHOLD PROBLEM (BELLMAN EQUATION):
!   V(j,a,aime,ε,δ,r) = max_{c,l,a'} u(c,l) + (δ+δ_shock)×π(j)×E[V(j+1,a',aime',ε')]
!   subject to:
!     Budget: c + a' = (1+r+r_shock)×a + w×ε×l + b(aime) + bequest - tax(w×ε×l)
!     Borrowing: a' ≥ a_l (typically 0, no borrowing)
!     Labor: l ∈ [0,1] if j < jbar (working age), l=0 if j ≥ jbar (retired)
!     Consumption: c > 0
!     AIME: aime' = update_aime(aime, w×ε×l, j) [Social Security formula]
!
! UTILITY SPECIFICATION:
!   Nested CES (Generalized Cobb-Douglas):
!   u(c,l) = [(c^φ × (1-l)^(1-φ))^(1-θ)]^(1-1/θ) / (1-1/θ)
!   where:
!   - θ: Coefficient of relative risk aversion (CRRA), 1/θ = EIS
!   - φ: Weight on consumption (Cobb-Douglas between c and leisure 1-l)
!   - rho_subst: Elasticity of substitution for CES aggregation (not directly in utility)
!
!   Special cases:
!   - θ=1: u = φ×log(c) + (1-φ)×log(1-l) [log utility]
!   - φ=1, switch_fix_labor>0: Exogenous labor (no leisure utility)
!
! PROGRESSIVE TAXATION (Heathcote et al. 2017):
!   Tax on labor income:
!   tax(income) = income - (1-τ)×(income/LabIncAVG)^(1-λ)×LabIncAVG
!   where:
!   - τ: Average tax rate at mean income
!   - λ: Progressivity (λ=0 → flat tax, λ>0 → progressive)
!   - LabIncAVG: Average labor income (normalizing constant)
!   Marginal rate: τ'(income) = 1 - (1-τ)×(1-λ)×(income/LabIncAVG)^(-λ)
!
! SOCIAL SECURITY (AIME-BASED):
!   Pension benefit: b(aime) = ρ × replacement_rate(aime)
!   where:
!   - AIME: Average indexed monthly earnings (updated each working year)
!   - replacement_rate(aime): Progressive formula with two bend points
!     = 0.90×aime if aime < bend1
!     = 0.90×bend1 + 0.32×(aime-bend1) if bend1 ≤ aime < bend2
!     = 0.90×bend1 + 0.32×(bend2-bend1) + 0.15×(aime-bend2) if aime ≥ bend2
!   - ρ: Aggregate replacement rate (calibrated to match contribution/benefit ratio)
!
! SHOCKS:
!   1. Permanent/persistent productivity (ip):
!      - AR(1) process: log(ε_t) = ζ_p×log(ε_{t-1}) + ν_t, ν ~ N(0,σ²_ε)
!      - Discretized to n_sp states with transition matrix pi_ip
!      - Affects labor income: w×ε×l
!
!   2. Return shock (ir):
!      - AR(1) process: r_t = r̄ + ζ_r×(r_{t-1}-r̄) + η_t, η ~ N(0,σ²_r)
!      - Discretized to n_sr states with transition matrix pi_ir
!      - Affects asset returns: (1+r+r_shock)×a
!
!   3. Discount factor shock (id):
!      - AR(1) process: δ_t = δ̄ + ζ_d×(δ_{t-1}-δ̄) + ξ_t, ξ ~ N(0,σ²_d)
!      - Discretized to n_sd states with transition matrix pi_id
!      - Affects patience: (δ+δ_shock)×π×E[V']
!
!   4. Mortality risk:
!      - Conditional survival probability π(j,t) varies by age, time, education
!      - Incorporated in value function via π×E[V(j+1,⋅)]
!
! GRIDS:
!   - Asset grid sv(0:n_a): Exponentially spaced from a_l to a_u
!     sv(ia) = grid_cons(a_l, a_u, n_a, a_grow) [power function]
!     Denser near borrowing constraint for accuracy
!
!   - AIME grid aime(0:n_aime): Exponentially spaced from aime_l to aime_u
!     Captures Social Security benefit heterogeneity
!
! INTERPOLATION:
!   - Linear interpolation for off-grid policies: linear_int(a', ial, iar, dist, sv, ⋅)
!   - Returns bracket [ial, iar] and weight dist ∈ [0,1]
!   - Distributes probability mass across neighboring points in distribution step
!
! DISTRIBUTION COMPUTATION:
!   Forward simulation (Young's method):
!   1. Initialize prob(1,⋅) from bequest distribution
!   2. Forward iterate: prob(j+1,⋅) = ∑ prob(j,⋅) × Pr[a'|policy] × Pr[ε'|ε] × π(j)
!   3. Linear interpolation for off-grid a' distributes mass to neighbors
!   See pfi_distribution.f90 for details
!
! AGGREGATION:
!   Integrate over distribution:
!   - Cohort average: var_j = ∑_{a,aime,ε,δ,r} prob(j,⋅) × policy(j,⋅)
!   - Economy total: VAR = ∑_j N(j) × var_j
!   - Inequality: Gini, top wealth shares, etc.
!   See pfi_agregation.f90 for details
!
! MODULE VARIABLES:
!   GRIDS:
!   - sv(0:n_a): Asset grid
!   - aime(0:n_aime): AIME grid
!   - aime_replacement_rate(0:n_aime): Social Security benefit formula
!
!   STEADY STATE (6D arrays):
!   - V_ss, EV_ss: Value function and expected continuation value
!   - c_ss, l_ss, lab_ss: Consumption, effective labor, raw hours
!   - svplus_ss: Savings (next period assets)
!   - aime_plus_ss: Updated AIME
!   - prob_ss: Equilibrium distribution
!   - labor_tax, lab_income_ss, tot_income_ss: Tax and income variables
!   - RHS_ss: Right-hand side of Euler equation
!
!   TRANSITION PATH (7D arrays, +time dimension):
!   - Same variables with _trans suffix and extra dimension i ∈ {1,...,bigT}
!
!   AGGREGATES:
!   - *_ss_j_vfi(bigJ): Cohort averages (steady state)
!   - *_j_vfi(bigJ,bigT): Cohort averages (transition)
!   - gini_weight_*, top_*, share_*: Distributional moments
!
! INCLUDED FILES:
!   - pfi_household_problem.f90: Household optimization routines (backward iteration)
!   - pfi_distribution.f90: Distribution computation (forward simulation)
!   - pfi_agregation.f90: Aggregation and distributional statistics
!   - pfi_print.f90: Output routines for CSV files
!
! DEPENDENCIES:
!   Toolbox modules (Kindermann library):
!   - linint: Linear interpolation
!   - splines: Cubic spline interpolation
!   - rootfinding: Equation solvers (Brent, Newton)
!   - minimization: Optimization (golden section, Powell)
!   - gaussian_int: Gauss-Legendre quadrature
!   - normalProb: Normal CDF/PDF/quantile
!   - AR_discrete: AR(1) discretization (Rouwenhorst, Tauchen)
!   - matrixtools: Matrix operations
!   - polynomial: Polynomial evaluation
!   - simplex: Simplex optimization
!   - assertions: Assert equality/positivity
!   - errwarn: Error/warning messages
!   - clock: Timing utilities
!   - global_vars: Model parameters and arrays
!
! PERFORMANCE:
!   - State space: bigJ × n_a × n_aime × n_sp × n_sr × n_sd ≈ 16×60×40×9×5×5 = 4.3M points
!   - Steady state: ~10-50 iterations × 4.3M evaluations ≈ 50-200M operations
!   - Transition: bigT iterations × bigJ ages × 4.3M points ≈ 2-10 billion operations
!   - Memory: ~50 GB for full transition arrays (8 bytes × 7 dimensions × multiple policies)
!   - Parallelization: Grid points are independent within age (OpenMP candidate)
!
! NOTES FOR REPLICATION:
!   - Convergence criteria: max|V^{n+1} - V^n| < tol (value function)
!   - Update: Dampened (mix old and new): V^{n+1} = up×V_new + (1-up)×V^n
!   - Borrowing constraint: a' ≥ a_l handled by restricting choice set
!   - Corner solutions: l=0 (retired), l=1 (rare, utility → -∞ as l→1)
!   - AIME cap: Maximum taxable earnings (e.g., $168,600 in 2024 dollars)
!   - Progressive tax calibration: {τ, λ} chosen to match average and marginal rates
!   - Bequest timing: Can occur at birth (switch_unequal_bequest=1) or mid-life (=2)
!   - Transition path: Backward from bigT (final SS) to 1 (initial SS), then forward distribution
!
! VALIDATION:
!   - Check Euler equation errors: Should be < 0.01% (0.0001) of consumption
!   - Verify budget constraint: c + a' ≈ (1+r)a + wεl + b - tax (within roundoff)
!   - Distribution sums to 1: ∑ prob(j,⋅) = 1 for all j
!   - Asset market clearing: ∑_j N(j)×a_j = K (checked in steady_state.f90)
!===============================================================================

module pfi_trans
    ! modules
    use assertions
    use errwarn
    use gaussian_int
    use linint
    use matrixtools
    use minimization
    use normalProb
    use polynomial
    use simplex
    use clock
    use rootfinding
    use splines
    use AR_discrete
    use global_vars
    
    
implicit none

!definition of variables
integer :: ia, i_aime, ip, ir, id, ir_r, ip_p, id_d, ibeq
real*8 :: sv(0:n_a)
real*8 :: aime(0:n_aime), aime_replacement_rate(0:n_aime)
integer ::  n_a_1, n_a_2, iter_com, iaimel, iaimer

!transition variables


real*8, dimension(:,:,:,:,:,:,:), allocatable ::  svplus_trans,  aime_plus_trans, l_trans, c_trans, labor_tax_trans, &
                                                  RHS_trans, prob_trans, sv_tempo_trans, V_trans, EV_trans, lab_income_trans, lab_income_pretax_trans,  tot_income_trans, tot_income_pretax_trans, bequest_j_trans

real*8, dimension(:,:,:,:,:,:,:), allocatable ::  svplus_beq_trans,  aime_plus_beq_trans, l_beq_trans, c_beq_trans, labor_tax_beq_trans, &
                                                  RHS_beq_trans, prob_beq_trans, ERHS_beq_trans, sv_tempo_beq_trans, V_beq_trans, EV_beq_trans, lab_income_beq_trans, lab_income_pretax_beq_trans,  tot_income_beq_trans, tot_income_pretax_beq_trans, V_after_beq_trans, EV_after_beq_trans, RHS_after_beq_trans
! big

real*8, dimension(:,:,:,:,:,:,:,:), allocatable ::  svplus_trans_big,  aime_plus_trans_big, l_trans_big, lab_trans_big, c_trans_big, labor_tax_trans_big, &
                                                  RHS_trans_big, prob_trans_big, sv_tempo_trans_big, V_trans_big, EV_trans_big, lab_income_trans_big, lab_income_pretax_trans_big,  tot_income_trans_big, tot_income_pretax_trans_big, bequest_j_trans_big

real*8, dimension(:,:,:,:,:,:,:,:), allocatable ::  svplus_beq_trans_big,  aime_plus_beq_trans_big, l_beq_trans_big, lab_beq_trans_big, c_beq_trans_big, labor_tax_beq_trans_big, &
                                                   RHS_beq_trans_big, ERHS_beq_trans_big, sv_tempo_beq_trans_big, V_beq_trans_big, EV_beq_trans_big, lab_income_beq_trans_big, lab_income_pretax_beq_trans_big,  tot_income_beq_trans_big, tot_income_pretax_beq_trans_big, V_after_beq_trans_big, EV_after_beq_trans_big

real*8, dimension(bigJ, bigT) :: bequest_j_vfi, bequest_j_vfi_dif, check_e, w_pom_trans_vfi,  w_pom_trans_implicit_vfi, &
                                 check_euler_trans, V_j_vfi_const_lambda, V_j_vfi_higher_lambda, V_j_vfi,&
                                 pi_trans_vfi_cond,  b_j_vfi, b_pom_j_dif,  N_t_j_vfi, pi_vfi, &
                                 c_j_vfi,  s_pom_j_vfi, l_j_vfi, labor_tax_j_vfi, lw_j_vfi, lw_lambda_j_vfi, l_pen_j_vfi, lab_j_vfi

real*8, dimension(bigT) ::   r_vfi, tc_vfi, gam_vfi, LabIncAVG_vfi, bequest_vfi, r_vfi_pretax, w_bar_vfi
real*8, dimension(n_beq,bigT) :: beq_zipf_trans

integer :: jbar_t_vfi(bigT)

!steady state variables
real*8, dimension(bigJ, 0:n_a, 0:n_aime, n_sp, n_sr,n_sd) :: V_ss, EV_ss, RHS_ss,  svplus_ss, l_ss, c_ss, lab_ss, srate_ss,lab_income_ss, lab_income_pretax_ss, tot_income_ss, tot_income_pretax_ss, sv_tempo, labor_tax, disposable_ss, prob_ss, &
 gini_weight_consumption,  aime_plus_ss, aime_tempo


real*8, dimension(n_beq, 0:n_a, 0:n_aime, n_sp, n_sr,n_sd) :: V_beq_ss,  V_after_beq_ss,  EV_beq_ss, RHS_beq_ss, svplus_beq_ss, l_beq_ss, c_beq_ss, lab_beq_ss, srate_beq_ss,lab_income_beq_ss, lab_income_pretax_beq_ss, tot_income_beq_ss, tot_income_pretax_beq_ss, sv_tempo_beq, labor_tax_beq, aime_plus_beq_ss, disposable_beq_ss, RHS_after_beq_ss, EV_after_beq_ss


!steady state variables - big
real*8, dimension(bigJ, 0:n_a, 0:n_aime, n_sp, n_sr,n_sd,bigM) :: V_ss_big, EV_ss_big, RHS_ss_big,  svplus_ss_big, lab_ss_big, l_ss_big, c_ss_big, srate_ss_big, lab_income_ss_big, lab_income_pretax_ss_big, disposable_ss_big, tot_income_ss_big, tot_income_pretax_ss_big, sv_tempo_big, labor_tax_big, prob_ss_big, &
 gini_weight_consumption_big,  aime_plus_ss_big, aime_tempo_big

real*8, dimension(n_beq, 0:n_a, 0:n_aime, n_sp, n_sr,n_sd,bigM) :: V_beq_ss_big,  V_after_beq_ss_big,  EV_beq_ss_big, RHS_beq_ss_big, svplus_beq_ss_big, l_beq_ss_big, c_beq_ss_big, lab_beq_ss_big, srate_beq_ss_big,lab_income_beq_ss_big, lab_income_pretax_beq_ss_big, tot_income_beq_ss_big, tot_income_pretax_beq_ss_big, sv_tempo_beq_big, labor_tax_beq_big, aime_plus_beq_ss_big, disposable_beq_ss_big, RHS_after_beq_ss_big, EV_after_beq_ss_big



real*8, dimension(bigJ) :: V_ss_j_vfi, c_ss_j_vfi, lab_income_ss_j_vfi, lab_income_pretax_ss_j_vfi, tot_income_ss_j_vfi, tot_income_pretax_ss_j_vfi, l_ss_j_vfi, lab_ss_j_vfi,  b_ss_j_vfi, &
                           bequest_ss_j_vfi, bequest_ss_j_vfi_dif, pi_ss_vfi, pi_ss_vfi_cond, s_pom_ss_j_vfi, pension_ss_j_vfi, &
                           labor_tax_ss_j_vfi, lw_ss_j_vfi, lw_lambda_ss_j_vfi, w_pom_ss_vfi, w_pom_ss_implicit_vfi, lab_high_ss_j_vfi, l_ss_pen_j_vfi, asset_pom_ss_j_vfi

real*8 ::   r_ss_vfi, r_ss_pretax_vfi, tc_ss_vfi, LabIncAVG_ss_vfi, LabIncAVG_ss_vfi_L, LabIncAVG_ss_vfi_H, gam_ss_vfi, available_temp, l_temp,c_temp, sv_temp, bequest_ss_vfi, w_bar_ss_vfi, sum_b_weight_ss_vfi
real*8 ::   gini_weight_sv(bigJ, 0:n_a)
integer ::  jbar_ss_vf

!comunication variables
integer :: j_com, ia_com, ip_com, i_com, ir_com
real*8 :: c_com, l_com, pi_com, c_ss_com, l_ss_com

! top_ten
real*8, dimension(bigJ) :: N_ss_j_vfi, asset_pom_ss_j, top_ten_coh, cons_proc_top_ten_coh 
real*8, dimension(bigJ, 0:n_a, 0:n_aime, n_sp, n_sr,n_sd) :: gini_income
real*8 :: savings_top_ten(10), top_ten(10), savings_cohort_ten(3,bigJ), &
          consumption_top_ten(3, bigJ), top_100(100),  savings_top_100(100), &
          top_ten_trans(10,bigT), savings_top_ten_trans(10, bigT), wspl(bigT), l_pen_j(bigJ,bigM,bigT), asset_trans(bigJ,bigT) , &
          gini_weight_trans(bigJ,0:n_a, bigT), share_neg, share_nonpos, share_0_sav
          
integer :: t
contains 


!*******************************************************************************************
! marginal utility of consumption
    function margu(cons, labor, tc)
        real*8, intent(in) :: cons, labor, tc !cosumption , labor and consumption tax
        real*8 :: margu, leis
        leis=1d0-labor
        margu = 1/tc*phi*(cons**phi*leis**(1d0-phi))**(1d0-theta)/cons
    end function 

!*******************************************************************************************
! value function - steady state!
 
    function valuefunc(sv_plus, aime_plus, cons, lab, j, ip, ir, id)
        implicit none

        integer, intent(in) :: j, ip, ir, id
        real*8, intent(in) :: sv_plus, aime_plus, cons, lab
        real*8 :: valuefunc, dist, dist_aime, c_help, l_help, pr
        integer :: ial, iar, aimel, aimer

        ! check whether consumption or leisure are too small
        c_help = max(cons, 1d-10)  
        l_help = min(max(lab,1d-10), 1d0-1d-10)    
        ! get tomorrows utility
        call linear_int(sv_plus, ial, iar, dist, sv, n_a, a_grow)
        call linear_int(aime_plus, aimel, aimer, dist_aime, aime, n_aime, aime_grow)
        
        ! calculate tomorrow's part of the value function
        valuefunc = 0d0
        if(j < bigJ)then
            if (theta == 1) then
                !valuefunc = log(max(dist*EV_ss(j+1, ial, ip,ir, id) + &
                              !(1d0-dist)*EV_ss(j+1, iar, ip,ir, id), 1d-10))
                valuefunc =   dist*dist_aime*EV_ss(j+1, ial, aimel, ip, ir, id) + &
                              dist*(1d0-dist_aime)*EV_ss(j+1, ial, aimer, ip, ir, id) + &
                              (1d0-dist)*dist_aime*EV_ss(j+1, iar, aimel, ip, ir, id) + &
                              (1d0-dist)*(1d0-dist_aime)*EV_ss(j+1, iar, aimer, ip, ir, id)
            else
                valuefunc =     max(dist*dist_aime*EV_ss(j+1, ial, aimel, ip, ir, id) + &
                              dist*(1d0-dist_aime)*EV_ss(j+1, ial, aimer, ip, ir, id) + &
                              (1d0-dist)*dist_aime*EV_ss(j+1, iar, aimel, ip, ir, id) + &
                        (1d0-dist)*(1d0-dist_aime)*EV_ss(j+1, iar, aimer, ip, ir, id), 1d-10)**(1d0-theta)/(1d0-theta)
            endif
        endif    
        
                ! add todays part and discount
            if (theta == 1) then
                valuefunc = (phi*log(c_help) +(1d0-phi)*log(1d0 - l_help))  +  (delta+n_sd_value(id))*pi_com*valuefunc 
            else
                valuefunc = (c_help**phi*(1d0-l_help)**(1d0-phi))**(1d0-theta)/(1d0-theta)  + (delta+n_sd_value(id))*pi_com*valuefunc 
            endif

    end function

!*******************************************************************************************
! value function - trans !
    function valuefunc_trans(sv_plus, aime_plus, cons, lab, j, ip, ir, id, it)
        implicit none

        integer, intent(in) :: j,  ip, it, ir, id
        real*8, intent(in) :: sv_plus, aime_plus, cons, lab
        real*8 :: valuefunc_trans, dist, dist_aime, c_help, l_help, pr
        integer :: itp, ial, iar, aimel, aimer

        ! check whether consumption or leisure are too small
        c_help = max(cons, 1d-10)  
        l_help = min(max(lab,1d-10), 1d0-1d-10)    
        ! get tomorrows year
        itp = year(it, j, j+1)
        ! get tomorrows utility
        call linear_int(sv_plus, ial, iar, dist, sv, n_a, a_grow)
        call linear_int(aime_plus, aimel, aimer, dist_aime, aime, n_aime, aime_grow)
        ! calculate tomorrow's part of the value function
        valuefunc_trans = 0d0
        if(j < bigJ)then            
            if (theta == 1) then
                valuefunc_trans = dist*dist_aime*EV_trans(j+1, ial, aimel, ip, ir, id, itp) + &
                                (1d0-dist)*dist_aime*EV_trans(j+1, iar, aimel, ip, ir, id, itp) + &
                                dist*(1d0-dist_aime)*EV_trans(j+1, ial, aimer, ip, ir, id, itp) + &
                                (1d0-dist)*(1d0-dist_aime)*EV_trans(j+1, iar, aimer, ip, ir, id, itp)
            else
                valuefunc_trans = max(dist*dist_aime*EV_trans(j+1, ial, aimel, ip, ir, id, itp) + &
                                (1d0-dist)*dist_aime*EV_trans(j+1, iar, aimel, ip, ir, id, itp) + &
                                dist*(1d0-dist_aime)*EV_trans(j+1, ial, aimer, ip, ir, id, itp) + &
                          (1d0-dist)*(1d0-dist_aime)*EV_trans(j+1, iar, aimer, ip, ir, id, itp), 1d-10)**(1d0-theta)/(1d0-theta)
            endif
        endif    
        ! add todays part and discount
        if (theta == 1) then
            valuefunc_trans = (phi*log(c_help) +(1d0-phi)*log(1d0 - l_help))  +  (delta+n_sd_value(id))*pi_com*valuefunc_trans 
        else
            valuefunc_trans = (c_help**phi*(1d0-l_help)**(1d0-phi))**(1d0-theta)/(1d0-theta)  + (delta+n_sd_value(id))*pi_com*valuefunc_trans 
        endif
        
    end function       
    
 !*******************************************************************************************   
    ! find year in which consumer will have ijj years, having in year it ij years
     function year(it, ij, ijj)

        implicit none

        integer, intent(in) :: it, ij, ijj
        integer :: year

        year = it + ijj - ij

        if(it == 1 .or. year <= 1)year = 1
        if(it == bigT .or. year >= bigT)year = bigT
    end function

  !*******************************************************************************************  
    ! find optimal labor for given consumption, wage, preference for leisure and labor tax parameters
     function optimal_labor(c, w, w_non_tax,  phi, tau, lambda, LabIncAVG, tax)
     
        real *8 :: c, w, w_non_tax, phi, tau, lambda, LabIncAVG, tax
        real *8 :: l, f_iter, f_prim_iter
        real *8 :: optimal_labor
        real *8 :: c_mult
   
       
        integer :: iter
       
        c_mult = (1-phi)/phi
   

        ! Newthon Rapson method
        l = 0.0001
        do iter = 1, 6, 1
            f_iter = 1 - l - c*c_mult*1/((1-tau)*(1-lambda)*(w/LabIncAVG)**(1-lambda)*LabIncAVG*l**(-lambda)+w_non_tax)
            f_prim_iter = -1 - c*c_mult*&
                             (lambda*(1-tau)*(1-lambda)*(w/LabIncAVG)**(1-lambda)*LabIncAVG*l**(-lambda-1) ) &
                             /((1-tau)*(1-lambda)*(w/LabIncAVG)**(1-lambda)*LabIncAVG*l**(-lambda)+w_non_tax)**2
 
            l = l-f_iter/f_prim_iter
        enddo          

       
        optimal_labor = min(1d0,max(l,0d0))
         
        
     end function
    
!*******************************************************************************************

    subroutine agent_vf()


        implicit none

        integer :: iter
        
            call initialize_trans
                
            ! solve the household problem
            call household_endo()
    
            ! calculate the distribution of households over state space
            call get_distribution_ss()
    
            ! aggregate individual decisions
            call aggregation_ss()
          
            
            
            
    end subroutine
!*******************************************************************************************
    
    subroutine get_transition()

        implicit none

        integer :: iter, ij, it, itmax
        logical :: check

        ! initialize remaining variables
        ! start timer

            ! solve the household problem
            do j = bigJ, 2, -1
                call household_trans_endo(j, 2)
            enddo
            
            do i = 2, bigT
                call household_trans_endo(1, i)
            enddo
    
            ! calculate the distribution of households over state space
            do i = 2, bigT
                call get_distribution_trans(i)
            enddo

            ! aggregate individual decisions
            do i = 2, bigT
                call aggregation_trans(i)
            enddo
    
end subroutine 
!*******************************************************************************************
  ! start policy functions iteration
subroutine agent_vf_trans() 
    implicit none
    call initialize_trans
    call get_transition()  
end subroutine
   
!*******************************************************************************************
! adjust policy function for endogenous grid to exogenous one by linear interpolation
subroutine change_grid_piecewise_lin_spline(endo_grid, egzo_grid, f, g)
    real*8 :: endo_grid(0:n_a), egzo_grid(0:n_a), f(0:n_a), g(0:n_a), coef1, coef2
    integer :: first, last, ik, it
        
do ia = 0, n_a, 1 
    first=0
    last=n_a
    do while(abs(last-first)>2)
        ik=floor(fi*first+(1d0-fi)*last)
        it=floor((1d0-fi)*first+fi*last)
        if(endo_grid(ik)<endo_grid(it)) then
            if(endo_grid(it)<=egzo_grid(ia)) then
                first=it
            else if(endo_grid(ik)<=egzo_grid(ia) .and. egzo_grid(ia)<endo_grid(it)) then
                first=ik
                last=it
            else if(egzo_grid(ia)<endo_grid(ik)) then
                last=ik
            endif
        else
             if(endo_grid(ik)<=egzo_grid(ia)) then
                first=ik
            else if(endo_grid(it)<=egzo_grid(ia) .and. egzo_grid(ia)<endo_grid(ik)) then
                first=it
                last=ik
            else if(egzo_grid(ia)<endo_grid(it)) then
                last=it
            endif
        endif
    enddo
    ik=first
    if(last-first == 2 .and. endo_grid(first+1)<egzo_grid(ia)) then
        ik=ik+1
    endif
    if(ik==0 .and. endo_grid(ik)>egzo_grid(ia)) then
        g(ia)=f(0)
    else
        coef1=abs(endo_grid(ik+1)-egzo_grid(ia))/abs(endo_grid(ik+1)-endo_grid(ik))
        coef2=abs(endo_grid(ik)-egzo_grid(ia))/abs(endo_grid(ik+1)-endo_grid(ik))
        g(ia)=coef1*f(ik)+coef2*f(ik+1)
        if(g(ia)>egzo_grid(n_a)) then 
            g(ia) = f(n_a)
        endif
    endif
enddo    
end subroutine
!*******************************************************************************************



!******************************************************************************************
    subroutine linear_int(assets, ial, iar, dist, grid, grid_size, grid_grow)

        implicit none
        integer :: grid_size
        real*8 :: assets, grid_grow
        real*8 :: grid(0:grid_size)
        integer :: ial, iar
        real*8 :: dist, real_ia


        real_ia = grid_Val_Inv(assets, grid(0), grid(grid_size), grid_size, grid_grow)

        ial = floor(real_ia)
        ial = max(ial, 0)
        ial = min(ial, grid_size-1)
        iar = ial+1
        dist = 1d0 - (assets-grid(ial))/(grid(iar)-grid(ial))

    end subroutine
!******************************************************************************************
    
   subroutine initialize_trans() 
    implicit none 
        
    real*8 :: sv_pom(0:n_a), Brackets(2)
   
    pi_trans_vfi_cond = 1d0
    pi_ss_vfi_cond = 1d0 !todo 
    

    do i = 1 , bigT, 1    
        do j=2, bigJ        
            pi_trans_vfi_cond(j,i)=pi(j,i)/pi(j-1,max(i-1,1))  
            pi_ss_vfi_cond(j) =  pi_ss_vfi(j)/pi_ss_vfi(j-1) 
        enddo
    enddo 
    ! size of the asset grid
 
    sv(0:n_a) = grid_cons(a_l, a_u, n_a, a_grow)
    aime(0:n_aime) = grid_cons(aime_l, aime_u, n_aime, aime_grow)
    ! based on https://fas.org/sgp/crs/misc/R43542.pdf


    Brackets(1) = 926d0/3921d0!
    Brackets(2) = 5583d0/3921d0! 
    

   do i_aime = 0, n_aime, 1
        if (aime(i_aime)< Brackets(1)) then 
            aime_replacement_rate(i_aime) = 0.9d0*aime(i_aime)  
        elseif (aime(i_aime)< Brackets(2)) then 
            aime_replacement_rate(i_aime) = 0.9d0*Brackets(1) + 0.32d0*(aime(i_aime)-Brackets(1))      
        else
            aime_replacement_rate(i_aime) = 0.9d0*Brackets(1)  + 0.32d0*(Brackets(2)-Brackets(1))  + 0.15d0*(aime(i_aime)-Brackets(2) )   
        endif
    enddo
    if (switch_cohort_ps == 1) then
        aime_replacement_rate =1d0 
    endif
    
    if (switch_partial_efficiency == 1) then 
       aime_replacement_rate = aime
       aime_cap = aime(n_aime)
    endif 


   end subroutine
   
!*******************************************************************************************
subroutine comptax(taxinc, lambda, tau, LabIncAVG, tax, mrate)
  !  
  ! Compute taxes paid and the marginal rate given
  !   (1) taxable income 
  !   (2) the tax schedule: (x,y) pairs, where x is the rate for income over y
  !
  implicit none

  real*8       :: taxinc, tau, lambda, LabIncAVG
  real*8       :: tax, mrate

 
        tax    = taxinc -(1-tau)*(taxinc/LabIncAVG)**(1-lambda)*LabIncAVG ! total tax collected on labor income
        mrate  = 1-(1-tau)*(1-lambda)*(taxinc/LabIncAVG)**(-lambda)


end subroutine comptax
!*******************************************************************************************
function foc_intratemp(av, w_tax, w_non_tax, tc, l_guess, LabIncAVG )
implicit none
    real*8 :: av, w_tax, w_non_tax, tc, l_guess, LabIncAVG 
    real*8 ::  c, l , foc_intratemp(3)
    real*8 :: lambda , tau_prog
    real*8:: l0, del, taxinc, nontaxinc, res, lp, tax, mrate, dres
    integer :: maxit, i
    tau_prog = tL_com
    lambda = lambda_com
    !besed on Heathcote, Jonathan, Kjetil Storesletten, and Giovanni L. Violante. "Optimal tax progressivity: An analytical framework." The Quarterly Journal of Economics 132.4 (2017): 1693-1754
    ! https://www.nber.org/papers/w19899.pdf
    ! https://www.sas.upenn.edu/~dkrueger/research/LafferCurves.pdf

    ! foc_intratemp = phi/(1-phi)*(w_non_tax+lambda*(1-tau_prog)*(w_tax)**(1-tau_prog)*l**(-tau_prog)*(1-l)-c (1-phi)/phi
    ! TAKE a look at ncn emeryt\model\prog_income_tax.lyx
      maxit  = 20
      l0  = l_guess
      del = 1d-8
      
      !!! Cobb-Douglas utility function
      if ( (switch_fix_labor == 0d0) ) then 
          do i= 1, maxit
            taxinc = w_tax*l0
            nontaxinc = w_non_tax*l0
            call comptax(taxinc, lambda, tau_prog, LabIncAVG, tax, mrate)
            res    = (1-phi)/phi/tc*(av+taxinc+nontaxinc-tax)-(w_tax*(1.0d0-mrate) + w_non_tax)*(1.0d0-l0)
            lp     = l0+del
            taxinc = w_tax*lp
            nontaxinc = w_non_tax*lp
            call comptax(taxinc, lambda, tau_prog, LabIncAVG, tax,mrate)
            dres   = ((1-phi)/phi/tc*(av+taxinc+nontaxinc-tax)-(w_tax*(1.0d0-mrate) + w_non_tax)*(1.0d0-lp)-res)/del
            l0     = min(max(l0-res/dres, del), 1d0-del)
          enddo  
    endif  
      l = l0
      taxinc = w_tax*l0
      nontaxinc = w_non_tax*l0
      call comptax(taxinc, lambda, tau_prog, LabIncAVG, tax,mrate)
      c = max((av+taxinc+nontaxinc-tax)/tc, del)
      if ((c .NE. c) .or. (l .NE. l) ) then
         write(*,*) 'problem'  
      endif
      foc_intratemp(1) = c
      foc_intratemp(2) = min(max(l, 0d0), 1d0-del)
      foc_intratemp(3) = tax

endfunction 





function derivative_crra(eta,nu,lambda,zeta, kappa, c)
! derivative of function_crra which define optimal consumption
! compere with file D:\Dropbox (UW)\NCN EMERYT\__model\egm\prog_income_tax_eqg_CRRA
implicit none
    real*8 :: eta, nu, lambda, zeta, kappa, c
    real*8 :: derivative_crra

    derivative_crra = - zeta*lambda*(1-eta*c**nu)**(lambda-1)*eta*nu*c**(nu-1)&
                      -kappa*eta*(nu-1)*c**(nu-2)*((1-eta*c**nu)**(lambda)- nu/(nu-1)*lambda*(1-eta*c**nu)**(lambda-1)*eta*c**nu ) &
                      -eta*(nu-1)*c**(nu-2)
        

endfunction

function function_crra(eta,nu,lambda,zeta, kappa, c)
! root of function_crra define optimal consumption
! compere with file D:\Dropbox (UW)\NCN EMERYT\__model\egm\prog_income_tax_eqg_CRRA
implicit none
    real*8 :: eta, nu, lambda, zeta, kappa, c
    real*8 :: function_crra
    
    function_crra = (zeta-kappa*eta*c**(nu-1))*(max(1-eta*c**nu, 0d0))**lambda-eta*c**(nu-1)
endfunction

!*******************************************************************************************


include "pfi_household_problem.f90"

include "pfi_distribution.f90"
 
include "pfi_agregation.f90"

include "pfi_print.f90"
!************************************************************************************************

!
function optimal_consumption_and_labor_new(RHS,phi, theta, tau, lambda,w, w_NT, tc, LabIncAVG )
!! return optimal labor and conumption 
!! for given    taxes scheme (tc, tau, lamda)
!!              utility function parameter theta, phi
!!              future optimal choice given by RHS 
!! (compere with file D:\Dropbox (UW)\NCN EMERYT\__model\egm\prog_income_tax_eqg_CRRA)
    real*8 :: RHS, phi, theta, tau, lambda, w, w_NT, tc, LabIncAVG
    real*8 :: eta, nu, zeta, kappa, c_l, c_r, c_rts, c_min, f, df, dxold, dx, l, out_of_range, decreasing_slow
    real*8 :: optimal_consumption_and_labor_new(2)
    integer :: iter, iter_max
    
    iter_max = 20
    
    !!! Cobb-Douglas utility function
    if (switch_fix_labor > 0d0) then 
        optimal_consumption_and_labor_new(1) = max(RHS**(1d0/(-theta)),1d-15)
        optimal_consumption_and_labor_new(2) =  switch_fix_labor
    else
    
        
        
    nu = (1-phi*(1-theta))/(1-phi)/(1-theta)
    
    if (RHS < 1e-10) then
        eta = 0
        else
        eta = (RHS)**(1/(1-phi)/(1-theta))
    endif
    zeta = (1-phi)*tc/phi/(1-tau)/(1-lambda)/(w**(1-lambda))/LabIncAVG**(lambda)
    kappa = w_NT/(1-tau)/(1-lambda)/(w**(1-lambda))/LabIncAVG**(lambda)
    
    ! in first step we use bisection to obtain coverage region for Newtor Raphson method
    
    ! initial guess: 
    ! consumption should be lower than wages - agent use to save for retirement, 
    ! you may have problem here if pension system is very generous for some agent type 
    ! thus we make sure in next lines that function is negative for our lower guess 
    ! and positive for higher guessed value
if (lambda == 0) then ! 
   c_rts = ((1d0-phi)*tc/eta/phi/((1-tau)*w+w_NT))**(1d0/(nu-1))     
else
    c_min = (1d0/eta)**(1d0/nu)
    c_l = 1.05d0*c_min
    c_r = max(w+w_NT, 2*c_l)

    
    ! orient the search such that f(c_l<0) and f(c_r)>)
    iter =1
    do while ((function_crra(eta,nu,lambda,zeta,kappa,c_r)<0) .and. (iter < iter_max))
        c_l = c_r
        c_r = 2d0*c_r
        iter = iter + 1 
        if (abs(c_l-c_r)< 1d-8) then 
            c_rts = 0.5d0*(c_l+c_r)   
            exit
        endif 
    enddo
    
    iter =1
    do while ((function_crra(eta,nu,lambda,zeta,kappa,c_l)>0) .and. (iter < iter_max))
        c_r = c_l
        c_l = 0.5d0*(c_l+c_min)
        iter = iter + 1 
        if (abs(c_l-c_r)< 1d-8) then 
            c_rts = 0.5d0*(c_l+c_r)   
            exit
        endif 
    enddo

 
    !initial guess for root
    c_rts = 0.5d0*(c_l+c_r)   
    ! the stepsize before last
    dxold = abs(c_l-c_r)
    ! the last stepsize
    dx = dxold
    f = function_crra(eta,nu,lambda,zeta,kappa,c_rts)
    df = derivative_crra(eta,nu,lambda,zeta,kappa,c_rts)

    
    do iter = 1, iter_max,1
       ! bisection if newton out of range
        out_of_range  = ((c_rts-c_r)*df-f)* ((c_rts-c_l)*df-f)
       ! or not decreasing fast enought
       decreasing_slow = abs(2d0*f)-abs(dxold*df)    
        IF ((out_of_range>0) .or. (decreasing_slow>0)) then 
            dxold = dx
            dx = 0.5*(c_r-c_l)
            c_rts = c_l+ dx
            if (abs(c_l- c_rts)<1d-8) then
                exit! change in root is negligible
            endif
        ELSE
            ! newton step acceplatle, take it
            dxold = dx
            dx = f/df
            c_rts = c_rts -dx
        ENDIF
        IF (abs(dx)<1d-8) then
            exit
       endif
        f = function_crra(eta,nu,lambda,zeta,kappa,c_rts)
        df = derivative_crra(eta,nu,lambda,zeta,kappa,c_rts)
        IF (f<0d0) THEN
            c_l = c_rts
        ELSE
            c_r = c_rts
        ENDIF
    enddo
endif
    continue 
    optimal_consumption_and_labor_new(1) = c_rts
    l = 1d0-(RHS/(c_rts**(phi*(1d0-theta)-1d0)))**(1d0/(1d0-phi)/(1d0-theta))
    optimal_consumption_and_labor_new(2) = min(max(l, 0d0), 1d0-1d-8)
    
    endif
    
endfunction 



end module