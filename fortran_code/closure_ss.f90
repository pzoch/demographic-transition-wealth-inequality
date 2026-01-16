!===============================================================================
! FILE: closure_ss.f90
!
! DESCRIPTION:
!   Government budget closure rule for steady state equilibrium. Balances the
!   government budget by adjusting government spending (g_ss) as the residual.
!   Included in steady_state.f90 via include statement.
!
! PURPOSE:
!   Enforce government budget constraint in steady state by computing spending
!   g_ss that satisfies the intertemporal budget balance condition, given tax
!   revenues, debt service, and pension subsidies.
!
! GOVERNMENT BUDGET CONSTRAINT (steady state):
!   Sources (revenues):
!     + Consumption tax revenue: tauC_ss * consumption_ss_gross
!     + Capital tax revenue: tauK_ss * r_bar_ss * k_ss (or on gross returns)
!     + Labor tax revenue: tauL_ss * labor_income_ss
!     + New debt issuance: debt_ss
!
!   Uses (expenditures):
!     + Government spending: g_ss (RESIDUAL, adjusts to balance budget)
!     + Debt service: debt_ss * (1 + r_bar_ss) / (gam_ss * nu_ss)
!     + Pension subsidy: subsidy_ss (benefits - contributions)
!
!   Balance condition:
!     g_ss + debt_service + subsidy_ss = tax_revenues + new_debt
!
! STEADY STATE DEBT DYNAMICS:
!   In steady state, debt per effective labor is constant:
!     debt_ss(t) = debt_ss(t-1) * (1 + r_bar_ss) / (gam_ss * nu_ss)
!
!   This implies deficit equals growth-adjusted debt service:
!     deficit_ss = debt_ss - debt_ss/(gam_ss*nu_ss)
!                = debt_ss * [1 - 1/(gam_ss*nu_ss)]
!                = debt_ss * [(gam_ss*nu_ss - 1)/(gam_ss*nu_ss)]
!
!   If gam_ss*nu_ss > 1 (economy growing): deficit_ss > 0 (can run deficit)
!   If gam_ss*nu_ss = 1 (no growth): deficit_ss = 0 (balanced budget)
!
! CLOSURE RULE (Case 6 - hardcoded):
!   Government spending (g_ss) is the RESIDUAL:
!     g_ss = tax_revenues - [subsidy_ss - deficit_ss - capital_tax - labor_tax]
!
!   Rearranged:
!     g_ss = tc_ss*consumption_ss_gross + tk_ss*r_bar_ss*k_ss + labor_tax_revenue_ss/bigl_ss
!          - subsidy_ss + deficit_ss
!
!   This ensures budget constraint holds exactly in steady state.
!
! TAX REVENUES:
!   1. Consumption tax: tc_ss * consumption_ss_gross
!      where consumption_ss_gross = aggregate consumption before taxes
!
!   2. Capital tax:
!      IF switch_tauK_gross = 0 (tax on net returns):
!        Capital tax revenue = tk_ss * r_bar_ss * k_ss
!      IF switch_tauK_gross = 1 (tax on gross returns):
!        Capital tax revenue = tk_ss * (r_bar_ss + depr) * k_ss
!
!   3. Labor tax: labor_tax_revenue_ss / bigl_ss
!      Computed as: sum over (j,m) of tauL_ss * w_bar_ss * l_ss_j * N_big_ss_j
!
! SWITCH_TAUK_GROSS:
!   0 = Capital tax on net returns r_bar_ss (interest only)
!   1 = Capital tax on gross returns r_bar_ss + depr (interest + depreciation)
!   Affects both tax revenue and after-tax return to households
!
! VARIABLES:
!   INPUT (from steady state iteration):
!     - consumption_ss_gross: Aggregate consumption per effective labor
!     - k_ss: Capital stock per effective labor
!     - debt_ss: Government debt per effective labor = debt_constr * y_ss
!     - r_bar_ss: Pre-tax gross interest rate (marginal product of capital)
!     - r_ss: After-tax net interest rate
!     - tc_ss, tk_ss, tl_ss: Tax rates (consumption, capital, labor)
!     - labor_tax_ss_j(j,m): Labor tax paid by age-type cell
!     - N_big_ss_j(j,m): Population by age and type
!     - subsidy_ss: Pension subsidy per effective labor (benefits - contributions)
!     - gam_ss: TFP growth rate (e.g., 1.015 for 1.5% annual growth)
!     - nu_ss: Labor productivity growth rate
!     - bigl_ss: Aggregate effective labor
!     - y_ss: Output per effective labor = zbar * k_ss^alpha
!     - N_ss: Total population
!     - depr: Depreciation rate (if switch_tauK_gross = 1)
!
!   OUTPUT:
!     - g_ss: Government spending per effective labor (RESIDUAL)
!     - g_per_capita_ss: Per capita government spending = g_ss*bigl_ss/N_ss
!     - g_share_ss: Government spending as share of GDP = g_ss/y_ss
!     - deficit_ss: Budget deficit per effective labor
!
! PENSION SUBSIDY:
!   subsidy_ss = (pension benefits paid) - (pension contributions received)
!   Can be positive (benefits exceed contributions, government transfers to system)
!   or negative (contributions exceed benefits, system runs surplus)
!
! ECONOMIC INTERPRETATION:
!   - Higher debt => higher debt service => lower g_ss (crowding out)
!   - Higher pension subsidy => lower g_ss (fiscal burden of pensions)
!   - Growing economy (gam*nu > 1) => can sustain positive deficit_ss
!   - Tax revenues increase with capital deepening (higher k_ss, r_bar_ss)
!
! NOTES:
!   - Case 6 (g residual) is hardcoded and most commonly used
!   - Alternative closures possible: adjust tauC, tauL, debt, or transfers
!   - Included at end of steady state iteration, after all other variables computed
!   - Ensures exact budget balance (no approximation error)
!   - Parallel to closures.f90 for transition path
!===============================================================================

    labor_tax_revenue_ss = 0.0d0
    do j = 1,bigJ,1
    do m = 1,bigM,1
       labor_tax_revenue_ss = labor_tax_revenue_ss +  N_big_ss_j(j,m)*labor_tax_ss_j(j,m)
    enddo
    enddo
    
    ! Case 6 - g is residual (hardcoded)
    if (switch_tauK_gross == 0) then
        deficit_ss =   (debt_ss * (1 - (1 + r_bar_ss) / (gam_ss * nu_ss)))    
        g_ss   =  tc_ss * consumption_ss_gross - (subsidy_ss - deficit_ss - tk_ss*r_bar_ss*k_ss  - 0.0d0 * tk_ss*r_bar_ss*debt_ss / (gam_ss * nu_ss)     -labor_tax_revenue_ss/bigl_ss) 
        g_per_capita_ss = g_ss*bigl_ss/N_ss       
        g_share_ss = g_ss/y_ss 
    else
        deficit_ss =   (debt_ss * (1 - (r_ss) / (gam_ss * nu_ss)))       
        g_ss =    tc_ss * consumption_ss_gross - (subsidy_ss  - deficit_ss - tk_ss*(r_bar_ss + depr)*k_ss -labor_tax_revenue_ss/bigl_ss) 
        g_per_capita_ss = g_ss*bigl_ss/N_ss       
        g_share_ss = g_ss/y_ss 
    endif