!===============================================================================
! FILE: closures.f90
!
! DESCRIPTION:
!   Government budget closure for transition path. Computes g(t) (government
!   spending) as residual that balances the period-by-period budget constraint.
!   Handles debt dynamics and net vs gross capital tax base (switch_tauK_gross).
!
! INCLUDED IN: transition.f90 via include statement
!   Steady-state counterpart: closure_ss.f90
!
! KEY OUTPUTS: g(t), g_share(t), deficit(t), debt_share(t)
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
