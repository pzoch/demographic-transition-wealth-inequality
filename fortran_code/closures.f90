! WHAT   : Closing budget -> tax rate to keep debt share unchanged in the long term
! TAKE   : unchanged in routine:   consumption_gross, capital tax [[tk]], interest rate [[r_bar]], private saving [[sum_priv_sv]], labor force growth [[nu(i)=big_l(i)/big_l(i-1)]], 
!          unchanged in routine:   change in technological progress [[gam = z_t/z_(t-1)]], wage [[w_bar]], sum of contribution to pension system in each perion [[contribution]], sum of pension benefit [[sum_b]],
!                                  (switch_init_FF == 0) .AND. (switch_init_retirement_db == 0) .AND. (switch_init_retirement_FF == 0) intial values of taxation and debt are not taken from the file 
!          changed   in routine:   debt_share, budget deficit, lump sum tax cohort unspecific [[upsilon]], consumption and labor  tax
! DO     : update tax rate during iteration on transition path
! RETURN : updated tax rate 

select case (switch_residual)
    case(0)
        if (switch_tauK_gross == 0) then
            debt_share(1) = debt(1)/y(1)
            Tax(1) = tc(1)*consumption_gross_new(1) + tk(1)*r_bar(1)*sum_priv_sv(1)/(nu(1)*gam_t(1)) &
                    + sum(N_t_j(1:bigJ,1)*labor_tax_j_vfi(1:bigJ,1))/bigl(1) !+ tL(1)*sum_b(1)  
            do i = 2,bigT,1
                Tax(i) = tc(i)*consumption_gross_new(i) + tk(i)*r_bar(i)*sum_priv_sv(i-1)/(nu(i)*gam_t(i)) &
                        + sum(N_t_j(1:bigJ,i)*labor_tax_j_vfi(1:bigJ,i))/bigl(i) !+ tL(i)*sum_b(i)  
            enddo 
            deficit(1) = debt(1) - debt(1)/(nu(1)*gam_t(1))
            upsilon(1) = (g(1) + subsidy(1) + (1 + r_bar(1))*debt(1)/(nu(1)*gam_t(1)) - Tax(1) - debt(1))*bigl(1)/N_t(1)
            do i = 2,bigT,1
                debt_share(i) = debt(i)/y(i)
                deficit(i) = debt(i) - debt(i-1)/(nu(i)*gam_t(i))
                upsilon(i) = (g(i) + subsidy(i) + (1 + r_bar(i))*debt(i-1)/(nu(i)*gam_t(i)) - Tax(i) - debt(i))*bigl(i)/N_t(i)
            enddo
        else
              debt_share(1) = debt(1)/y(1)
            Tax(1) = tc(1)*consumption_gross_new(1) + tk(1)*(r_bar(1)+depr)*k(1) &
                    + sum(N_t_j(1:bigJ,1)*labor_tax_j_vfi(1:bigJ,1))/bigl(1) !+ tL(1)*sum_b(1)  
            do i = 2,bigT,1
                Tax(i) = tc(i)*consumption_gross_new(i) + tk(i)*(r_bar(i)+depr)*k(i) &
                        + sum(N_t_j(1:bigJ,i)*labor_tax_j_vfi(1:bigJ,i))/bigl(i) !+ tL(i)*sum_b(i)  
            enddo 
            deficit(1) = debt(1) - debt(1)/(nu(1)*gam_t(1))
            upsilon(1) = (g(1) + subsidy(1) + (r(1))*debt(1)/(nu(1)*gam_t(1)) - Tax(1) - debt(1))*bigl(1)/N_t(1)
            do i = 2,bigT,1
                debt_share(i) = debt(i)/y(i)
                deficit(i) = debt(i) - debt(i-1)/(nu(i)*gam_t(i))
                upsilon(i) = (g(i) + subsidy(i) + (r(i))*debt(i-1)/(nu(i)*gam_t(i)) - Tax(i) - debt(i))*bigl(i)/N_t(i)
            enddo  
        endif
        
        
    case(1)
        if (switch_tauK_gross == 0) then
    !       case 1 - tC is residual
            debt_share(1) = debt(1)/y(1)
            if (switch_ref_run_now == 0) then 
                upsilon = upsilon_r_ss_1*y*bigl/N_t
            endif
            deficit(1) = debt(1) - debt(1)/(nu(1)*gam_t(1))

            do i = 2,bigT,1
                debt_share(i) = debt(i)/y(i)
                deficit(i) = debt(i) - debt(i-1)/(nu(i)*gam_t(i))
                tc(i) =  (g(i) + subsidy(i) + (1 + r_bar(i))*debt(i-1)/(nu(i)*gam_t(i)) - debt(i) - upsilon(i)/(bigl(i)/N_t(i)) &
                         - tk(i)*r_bar(i)*sum_priv_sv(i-1)/(nu(i)*gam_t(i)) &
                         - sum(N_t_j(1:bigJ,i)*labor_tax_j_vfi(1:bigJ,i))/bigl(i))/consumption_gross_new(i) 
            enddo
        else
                !       case 1 - tC is residual
            debt_share(1) = debt(1)/y(1)
            if (switch_ref_run_now == 0) then 
                upsilon = upsilon_r_ss_1*y*bigl/N_t
            endif
            deficit(1) = debt(1) - debt(1)/(nu(1)*gam_t(1))

            do i = 2,bigT,1
                debt_share(i) = debt(i)/y(i)
                deficit(i) = debt(i) - debt(i-1)/(nu(i)*gam_t(i))
                tc(i) =  (g(i) + subsidy(i) + (r(i))*debt(i-1)/(nu(i)*gam_t(i)) - debt(i) - upsilon(i)/(bigl(i)/N_t(i)) &
                         - tk(i)*(r_bar(i)+depr)*k(i) &
                         - sum(N_t_j(1:bigJ,i)*labor_tax_j_vfi(1:bigJ,i))/bigl(i))/consumption_gross_new(i) 
            enddo
        endif
        
        
        
          case(6)
          if (switch_tauK_gross == 0) then
    !       case 6 - g is residual
            debt_share(1) = debt(1)/y(1)
            if (switch_ref_run_now == 0) then 
                upsilon = upsilon_r_ss_1*y*bigl/N_t
            endif
            deficit(1) = debt(1) - debt(1)/(nu(1)*gam_t(1))

            do i = 2,bigT,1
                debt_share(i) = debt(i)/y(i)
                deficit(i) = debt(i) - debt(i-1)/(nu(i)*gam_t(i))
                
                        g(i) =   tc(i)*consumption_gross_new(i) - ( subsidy(i) + (1 + r_bar(i))*debt(i-1)/(nu(i)*gam_t(i)) - debt(i) - upsilon(i)/(bigl(i)/N_t(i)) &
                         - tk(i)*r_bar(i)*sum_priv_sv(i-1)/(nu(i)*gam_t(i)) &
                         - sum(N_t_j(1:bigJ,i)*labor_tax_j_vfi(1:bigJ,i))/bigl(i))
                
                        g_share(i) = g(i)/y(i)
            enddo
            else
                !       case 6 - g is residual
            debt_share(1) = debt(1)/y(1)
            if (switch_ref_run_now == 0) then 
                upsilon = upsilon_r_ss_1*y*bigl/N_t
            endif
            deficit(1) = debt(1) - debt(1)/(nu(1)*gam_t(1))

            do i = 2,bigT,1
                debt_share(i) = debt(i)/y(i)
                deficit(i) = debt(i) - debt(i-1)/(nu(i)*gam_t(i))
                         g(i) = tc(i) * consumption_gross_new(i)  - (subsidy(i) + (r(i))*debt(i-1)/(nu(i)*gam_t(i)) - debt(i) - upsilon(i)/(bigl(i)/N_t(i)) &
                         - tk(i)*(r_bar(i)+depr)*k(i) &
                         - sum(N_t_j(1:bigJ,i)*labor_tax_j_vfi(1:bigJ,i))/ bigl(i))
                         
                         
                         g_share(i) = g(i)/y(i)
            enddo
        endif
        

        
end select
