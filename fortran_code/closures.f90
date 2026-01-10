!===============================================================================
! FILE: closures.f90
!
! DESCRIPTION:
!   Government budget closure rules for transition path. Ensures period-by-period
!   government budget balance by adjusting fiscal instrument (typically spending).
!   Included in transition.f90.
!
! PURPOSE:
!   Calculate government budget constraint for each period t and adjust residual
!   fiscal variable to achieve budget balance along transition path.
!
! BUDGET CONSTRAINT (period t):
!   g(t) + debt(t) + subsidy(t) = 
!     tauC(t)*consumption_gross(t) + tauK(t)*r_bar(t)*savings(t-1)/(nu*gam) 
!     + tauL(t)*labor_income(t) + debt(t-1)*(1+r_bar(t))/(nu*gam)
!
! CLOSURE RULE (Case 6 - hardcoded):
!   Government spending g(t) adjusts each period to balance budget:
!   g(t) = tax_revenue(t) - [subsidy(t) + debt_service(t) - new_debt(t) - capital_tax(t) - labor_tax(t)]
!
! DEBT DYNAMICS:
!   debt(t) = debt(t-1)*(1+r_bar(t))/(nu(t)*gam_t(t)) + deficit(t)
!   deficit(t) = debt(t) - debt(t-1)/(nu(t)*gam_t(t))
!   debt_share(t) = debt(t)/y(t)
!
! TAX REVENUES:
!   - Consumption: tc(t) * consumption_gross_new(t)
!   - Capital: tk(t) * r_bar(t) * sum_priv_sv(t-1) / (nu(t)*gam_t(t))
!   - Labor: labor_tax_revenue(t) / bigl(t)
!
! SWITCH_TAUK_GROSS:
!   0 = Tax on net capital income (r_bar)
!   1 = Tax on gross capital income (r_bar + depr)
!
! TIME STRUCTURE:
!   - Variables at t-1 carried forward with growth adjustment
!   - Interest accrues between periods
!   - Population and TFP growth affect debt dynamics
!
! VARIABLES:
!   INPUT (time-varying paths):
!     - consumption_gross_new(t): Aggregate consumption
!     - sum_priv_sv(t): Private savings
!     - debt(t): Government debt path (initial guess)
!     - r_bar(t), r(t): Interest rate paths
!     - tc(t), tk(t): Tax rate paths
!     - labor_tax_j(j,m,t): Labor tax by age, type, time
!     - N_t_j(j,t): Population by age and time
!     - type_share_j_t(j,m,t): Type shares
!     - subsidy(t): Pension subsidy path
!     - gam_t(t), nu(t): TFP and population growth
!     - bigl(t), y(t): Aggregate labor and output
!   OUTPUT:
!     - g(t): Government spending path (residual)
!     - deficit(t): Budget deficit path
!     - debt_share(t): Debt-to-GDP ratio path
!
! NOTES:
!   - Must satisfy budget constraint every period along transition
!   - Debt path given exogenously or determined by closure rule
!   - Alternative closures (not active): tax rates adjust instead of g
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
