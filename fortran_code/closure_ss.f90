!===============================================================================
! FILE: closure_ss.f90
!
! DESCRIPTION:
!   Government budget closure rule for steady state equilibrium. Ensures
!   government budget balances by adjusting fiscal instrument (typically
!   government spending g). Included in steady_state.f90.
!
! PURPOSE:
!   Calculate government budget constraint and adjust residual fiscal variable
!   to achieve budget balance in steady state.
!
! BUDGET CONSTRAINT:
!   g_ss + (debt_ss / (gam_ss*nu_ss)) + subsidy_ss = 
!     tauC_ss * consumption_ss + tauK_ss * r_bar_ss * k_ss + tauL_ss * labor_inc + debt_ss * (1 + r_bar_ss)/(gam_ss*nu_ss)
!
! CLOSURE RULE (Case 6 - hardcoded):
!   Government spending (g_ss) adjusts to balance budget:
!   g_ss = tax_revenue - (subsidy_ss - deficit_ss - capital_tax - labor_tax)
!
! TAXES:
!   - Consumption tax: tc_ss * consumption_ss_gross
!   - Capital tax: tk_ss * r_bar_ss * k_ss (if net) or tk_ss*(r_bar_ss+depr)*k_ss (if gross)
!   - Labor tax: labor_tax_revenue_ss/bigl_ss
!
! DEBT DYNAMICS:
!   deficit_ss = debt_ss * (1 - (1+r_bar_ss)/(gam_ss*nu_ss))
!   Debt grows at rate gam_ss*nu_ss (TFP * population growth)
!
! SWITCH_TAUК_GROSS:
!   0 = Capital tax on net returns (r_bar_ss)
!   1 = Capital tax on gross returns (r_bar_ss + depr)
!
! VARIABLES:
!   INPUT:
!     - consumption_ss_gross: Aggregate consumption
!     - k_ss: Capital stock
!     - debt_ss: Government debt
!     - r_bar_ss, r_ss: Interest rates
!     - tc_ss, tk_ss: Tax rates
!     - labor_tax_ss_j: Labor tax by age and type
!     - N_big_ss_j: Population by age and type
!     - subsidy_ss: Pension subsidy
!     - gam_ss, nu_ss: Growth rates
!     - bigl_ss, y_ss, N_ss: Aggregates
!   OUTPUT:
!     - g_ss: Government spending (residual)
!     - g_per_capita_ss: Per capita government spending
!     - g_share_ss: Government spending as share of GDP
!     - deficit_ss: Budget deficit
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