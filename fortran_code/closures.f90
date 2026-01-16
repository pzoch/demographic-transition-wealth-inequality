!===============================================================================
! FILE: closures.f90
!
! DESCRIPTION:
!   Government budget closure rules for transition path. Enforces period-by-period
!   government budget balance by adjusting government spending as the residual.
!   Included in transition.f90 via include statement.
!
! PURPOSE:
!   Calculate government budget constraint for each period t along the transition
!   path and compute government spending g(t) that balances the budget, given
!   tax revenues, debt service, and pension subsidies.
!
! GOVERNMENT BUDGET CONSTRAINT (period t):
!   Sources (revenues):
!     + Consumption tax: tc(t) * consumption_gross(t)
!     + Capital tax: tk(t) * r_bar(t) * savings(t-1) / (nu(t)*gam(t))
!     + Labor tax: labor_tax_revenue(t) / bigl(t)
!     + New debt issuance: debt(t)
!
!   Uses (expenditures):
!     + Government spending: g(t) (RESIDUAL, adjusts to balance budget)
!     + Debt service: debt(t-1) * (1 + r_bar(t)) / (nu(t)*gam(t))
!     + Pension subsidy: subsidy(t) (benefits - contributions)
!
!   Balance condition:
!     g(t) + debt_service(t) + subsidy(t) = tax_revenues(t) + new_debt(t)
!
! DEBT DYNAMICS (transition path):
!   Debt per effective labor evolves according to:
!     debt(t) = debt(t-1) * (1 + r_bar(t)) / [nu(t) * gam_t(t)] + deficit(t)
!
!   Where:
!     deficit(t) = debt(t) - debt(t-1) / [nu(t) * gam_t(t)]
!     debt_share(t) = debt(t) / y(t) (debt-to-GDP ratio)
!
!   Growth adjustment nu(t)*gam_t(t) accounts for:
!     - nu(t) = bigl(t)/bigl(t-1): Labor productivity growth
!     - gam_t(t): TFP growth
!   Both reduce debt burden by expanding effective labor base.
!
! CLOSURE RULE (Case 6 - hardcoded):
!   Government spending g(t) is the RESIDUAL for each t:
!
!   IF switch_tauK_gross = 0 (tax on net returns):
!     g(t) = tc(t)*consumption_gross(t)
!          - subsidy(t)
!          - (1+r_bar(t))*debt(t-1)/[nu(t)*gam_t(t)]
!          + debt(t)
!          + tk(t)*r_bar(t)*savings(t-1)/[nu(t)*gam_t(t)]
!          + labor_tax_revenue(t)/bigl(t)
!
!   IF switch_tauK_gross = 1 (tax on gross returns):
!     g(t) = tc(t)*consumption_gross(t)
!          - subsidy(t)
!          - r(t)*debt(t-1)/[nu(t)*gam_t(t)]
!          + debt(t)
!          + tk(t)*(r_bar(t)+depr(t))*k(t)
!          + labor_tax_revenue(t)/bigl(t)
!
! SWITCH_TAUK_GROSS:
!   0 = Capital tax on net returns r_bar(t) (interest income only)
!   1 = Capital tax on gross returns r_bar(t)+depr(t) (includes depreciation)
!   Affects both tax revenue calculation and household budget constraints
!
! TAX REVENUES (period t):
!   1. Consumption tax:
!      Revenue = tc(t) * consumption_gross_new(t)
!      where consumption_gross_new = aggregate consumption before taxes
!
!   2. Capital tax:
!      IF switch_tauK_gross = 0:
!        Revenue = tk(t) * r_bar(t) * sum_priv_sv(t-1) / [nu(t)*gam_t(t)]
!      IF switch_tauK_gross = 1:
!        Revenue = tk(t) * (r_bar(t) + depr_t(t)) * k(t)
!
!   3. Labor tax:
!      Revenue = sum_{j,m} N(j,m,t) * type_share(j,m,t) * labor_tax_j(j,m,t)
!                divided by bigl(t)
!
! TIME STRUCTURE:
!   - Lagged variables: debt(t-1), savings(t-1) carried forward from previous period
!   - Growth adjustments: Variables divided by nu(t)*gam_t(t) to convert to
!     per-effective-labor units at time t
!   - Interest accrual: debt(t-1) grows at rate (1+r_bar(t)) between periods
!
! VARIABLES:
!   INPUT (time-varying paths from transition iteration):
!     - consumption_gross_new(t): Aggregate consumption per effective labor
!     - sum_priv_sv(t): Private savings per effective labor = k(t)*(gam*nu) + debt(t)
!     - debt(t): Government debt per effective labor (exogenous path or from previous iteration)
!     - r_bar(t): Pre-tax gross interest rate (marginal product of capital)
!     - r(t): After-tax net interest rate
!     - tc(t), tk(t): Tax rates (consumption, capital)
!     - labor_tax_j(j,m,t): Labor tax paid by each (age, type, time) cell
!     - N_t_j(j,t): Population by age and time
!     - type_share_j_t(j,m,t): Share of type m in age-j cohort at time t
!     - subsidy(t): Pension subsidy per effective labor
!     - gam_t(t): TFP growth rate
!     - nu(t): Labor productivity growth = bigl(t)/bigl(t-1)
!     - bigl(t): Aggregate effective labor
!     - y(t): Output per effective labor = zbar * k(t)^alpha
!     - k(t): Capital stock per effective labor
!     - depr_t(t): Depreciation rate (if switch_tauK_gross = 1)
!
!   OUTPUT:
!     - g(t): Government spending per effective labor (RESIDUAL for each t)
!     - g_share(t): Government spending as share of GDP = g(t)/y(t)
!     - deficit(t): Budget deficit per effective labor
!     - debt_share(t): Debt-to-GDP ratio = debt(t)/y(t)
!
! LABOR TAX CALCULATION:
!   For each period t, sum labor taxes across all (age, type) cells:
!     labor_tax_revenue(t) = sum_{j=1}^{bigJ} sum_{m=1}^{bigM}
!                            N_t_j(j,t) * type_share_j_t(j,m,t) * labor_tax_j(j,m,t)
!   This aggregates individual tax payments weighted by population shares.
!
! PENSION SUBSIDY:
!   subsidy(t) = (aggregate pension benefits) - (aggregate pension contributions)
!   Can be positive (benefits > contributions, government subsidizes system)
!   or negative (contributions > benefits, system runs surplus)
!   Computed in pension_system.f90
!
! ECONOMIC INTERPRETATION:
!   - Debt dynamics: Higher interest rates increase debt service burden
!   - Growth effects: Higher nu*gam reduces relative debt burden (denominator effect)
!   - Fiscal space: Higher tax revenues => higher feasible g(t)
!   - Crowding out: Higher debt service => lower g(t) available
!   - Pension costs: Higher subsidy(t) => lower g(t) (fiscal burden)
!   - Transition: g(t) adjusts flexibly to accommodate changing demographics,
!     tax bases, and debt service costs
!
! NOTES:
!   - Case 6 (g residual) is hardcoded and most commonly used
!   - Alternative closures possible: adjust tc(t), tk(t), debt(t), or transfers
!   - Must satisfy budget constraint every period t = 1,...,bigT
!   - Included during transition path iteration (include statement in transition.f90)
!   - Ensures exact budget balance (no approximation error)
!   - Parallel to closure_ss.f90 for steady state
!   - Initial period t=1 uses old steady state debt level
!   - Terminal period t=bigT approaches new steady state
!===============================================================================

    ! calculate labor tax revenue
    do i = 1,bigT,1
    labor_tax_revenue(i) = 0.0d0
    do m = 1,bigM,1
       labor_tax_revenue(i) = labor_tax_revenue(i) +   sum(N_t_j(1:bigJ,i)*type_share_j_t(1:bigJ,m,i)*labor_tax_j(1:bigJ,m,i),dim = 1)
    enddo
    enddo
    
    
    ! Case 6 - g is residual (hardcoded)
    if (switch_tauK_gross == 0) then

        debt_share(1) = debt(1)/y(1)
        deficit(1) = debt(1) - debt(1)/(nu(1)*gam_t(1))

        do i = 2,bigT,1
            debt_share(i) = debt(i)/y(i)
            deficit(i) = debt(i) - debt(i-1)/(nu(i)*gam_t(i))
            
                    g(i) =   tc(i)*consumption_gross_new(i) - ( subsidy(i) + (1 + r_bar(i))*debt(i-1)/(nu(i)*gam_t(i)) - debt(i) &
                     - tk(i)*r_bar(i)*sum_priv_sv(i-1)/(nu(i)*gam_t(i)) & 
                     -labor_tax_revenue(i)/bigl(i))
            
                    g_share(i) = g(i)/y(i)
        enddo
    else
        ! case 6 - g is residual
        debt_share(1) = debt(1)/y(1)
        deficit(1) = debt(1) - debt(1)/(nu(1)*gam_t(1))

        do i = 2,bigT,1
            debt_share(i) = debt(i)/y(i)
            deficit(i) = debt(i) - debt(i-1)/(nu(i)*gam_t(i))
                     g(i) = tc(i) * consumption_gross_new(i)  - (subsidy(i) + (r(i))*debt(i-1)/(nu(i)*gam_t(i)) - debt(i) &
                     - tk(i)*(r_bar(i)+depr_t(i))*k(i) &
                     - labor_tax_revenue(i)/ bigl(i))
                     
                     
                     g_share(i) = g(i)/y(i)
        enddo
    endif
