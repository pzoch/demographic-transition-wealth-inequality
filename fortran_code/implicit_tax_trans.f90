!!!!!!!IMPLICIT TAX PART
    b_pom_j = b_j
    do i = 1, bigT, 1
        w_pom_j(:,i) = w_j(:,i)
    enddo
    tau1_s_t   = 0.0_dp
    tau2_s_t   = 0.0_dp
        
     if ( (switch_see_ret == 1) .and. (switch_type_2 == 1)) then
        do i = -bigJ, n_p+1
            do j = 1, jbar_t(max(i,1))-1
                ! t = retirement age of cohort which is j years old at time i -> it was born at i - j + 1
                t = jbar_t_yob(max(i-j+1, -bigj)) ! ret age for each above 1ss 
                do s = bigJ-t, 0, -1 ! retirement for each cohort may differ here we should refer to proper not today retirement age  
                    tau1_s_t(j,i) = 1.0_dp + tau1_s_t(j,i)*valor_mult(max(i+t+s-j+1,1))*gam_t(max(i+t+s-j+1,1))/r(max(i+t+s-j+1,1)) ! the value of pension flow at age jbar
                    tau2_s_t(j,i) = 1.0_dp + tau2_s_t(j,i)*(1.0_dp+r_bar(max(i+t+s-j+1,1)))/r(max(i+t+s-j+1,1))
                enddo
                tau1_s_t(j,i) = tau1_s_t(j,i)/life_exp(t,max(i+t-j,1)) ! the price of pension flow
                tau2_s_t(j,i) = tau2_s_t(j,i)/life_exp(t,max(i+t-j,1))
                do s = t-j, 1, -1
                    tau1_s_t(j,i) = tau1_s_t(j,i) * (1.0_dp+rI(max(i+s,1)))/r(max(i+s,1)) ! present price of pension flow
                    tau2_s_t(j,i) = tau2_s_t(j,i) * (1.0_dp+r_bar(max(i+s,1)))/r(max(i+s,1))
                enddo
               tau1_s_t(j,i) = tau1_s_t(j,i) * N_t_j(j,max(i,1))/N_t_j(t,max(i+t-j,1))
               tau2_s_t(j,i) = tau2_s_t(j,i) * N_t_j(j,max(i,1))/N_t_j(t,max(i+t-j,1))
            enddo
        enddo

        !do i = -bigJ, n_p+1
        !    ii = max(i,1)
        !    do j = 1, jbar_t(max(i,1))-1
        !        do s = bigJ-jbar_t(max(i,1)), 0, -1
        !            tau1_s_t(j,i) = 1.0_dp*b_scale_factor(max(i+jbar_t(ii)+s-j,1)) + &
        !                             tau1_s_t(j,i)*valor_mult(max(i+jbar_t(ii)+s-j+1,1))*&
        !                             gam_t(max(i+jbar_t(ii)+s-j+1,1))/&
        !                             r(max(i+jbar_t(ii)+s-j+1,1)) ! the value of pension flow at age jbar
        !            tau2_s_t(j,i) = 1.0_dp + &
        !                             tau2_s_t(j,i)*(1.0_dp+r_bar(max(i+jbar_t(ii)+s-j+1,1)))&
        !                             /r(max(i+jbar_t(ii)+s-j+1,1))
        !        enddo
        !
        !        if (i+jbar_t(ii)-j<2) then
        !            tau1_s_t(j,i) = tau1_s_t(j,i)/life_exp(jbar_t(1),1) ! the price of pension flow
        !            tau2_s_t(j,i) = tau2_s_t(j,i)/life_exp(jbar_t(1),1)
        !        else
        !            tau1_s_t(j,i) = tau1_s_t(j,i)/life_exp(jbar_t(ii),i+jbar_t(ii)-j) ! the price of pension flow
        !            tau2_s_t(j,i) = tau2_s_t(j,i)/life_exp(jbar_t(ii),i+jbar_t(ii)-j)   
        !        endif
        !
        !        do s = jbar_t(ii)-j, 1, -1
        !            is = max(i+s,1) 
        !            tau1_s_t(j,i) = tau1_s_t(j,i) * (1.0_dp+rI(is))/r(is) ! market interst rate
        !            tau2_s_t(j,i) = tau2_s_t(j,i) * (1.0_dp+r_bar(is))/r(is)
        !        enddo
        !        !it should works for constant retirement age
        !        tau1_s_t(j,i) = tau1_s_t(j,i) * pi(j,ii)/pi(jbar_t(ii),max(i+jbar_t(ii)-j,1)) ! annuity part
        !        tau2_s_t(j,i) = tau2_s_t(j,i) * pi(j,ii)/pi(jbar_t(ii),max(i+jbar_t(ii)-j,1))
        !    enddo
        !    
        !enddo
        !

        do i = n_p+2,bigT,1
            tau1_s_t(:,i) = tau1_ss_2
            tau2_s_t(:,i) = tau2_ss_2
        enddo
        
        

        w_pom_j = 0.0_dp
        do i = -bigJ, bigT
            ii = max(i,1)
            do j = 1,bigJ,1
                w_pom_j(j,i) = (1.0_dp - tL(ii))*(1.0_dp - t1(j,ii) - t2(j,ii))*w_bar(ii) + &
                                (t1_contrib(j,ii)*tau1_s_t(j,i) + t2(j,ii)*tau2_s_t(j,i))*w_bar(ii)
            enddo
        enddo
        
        b_pom_j = 0.0_dp

        do j = 1, bigJ-1,1
            sv_pom_j(j,1) = sv_j(j,1) + pillarI_j(j,1)*tau1_s_t(j,1)
            transfer_pfi(j) =  pillarI_j(j,1)*tau1_s_t(j,1)
        enddo

        
if (switch_type_1 == 0) then

        !!! when the first steady is DB (and DC reform is a shock), in the first period savings and wages are the market ones (tau == 1) 
            do j = 1, bigJ,1 !!!jbar_t(1), bigJ,1
                sv_pom_j(j,1) = sv_j(j,1)
                w_pom_j(j,1)  = w_j(j,1)
            enddo 

        !!! wages for all cohorts that remains in DB system with old pensions (works when switch_pension == 1)
            do i = 2, jbar_t(1) - ofe_u, 1
                do j = ofe_u + i - 1, jbar_t(1) - 1, 1
                    w_pom_j(j,i) = w_j(j,i)
                    tau1_s_t(j,i)  = 0d0
                enddo    
            enddo
                   
        !!! pensions for old cohorts remaining in DB system (switch_pension == 1)
            do i = 1, bigJ - ofe_u + 1, 1 
                if (i<= jbar_t(1) - ofe_u) then
                    do j = jbar_t(1), bigJ,1 
                        b_pom_j(j,i) = b_j(j,i)
                    enddo
                else 
                    do j = jbar_t(1) + (i - (jbar_t(1) - ofe_u) -1) , bigJ,1 
                        b_pom_j(j,i) = b_j(j,i)
                    enddo
                endif
            enddo

          !!! contributions to the DB system revaluated for DC and included in the sav_pom
          !!! savings are "revealed" to the agents at the end of the first period and can be used from the second one
            transfer_pfi =0d0
            do j = 1, ofe_u -1, 1
                sv_pom_j(j,1) = sv_j(j,1) + pillarI_j(j,1)*tau1_s_t(j,1)!*(1.0_dp - tL(1))
                transfer_pfi(j) =  pillarI_j(j,1)*tau1_s_t(j,1)!*(1.0_dp - tL(1))
                !write(*,'(f20.10, f20.10)')pillarI_j(j,1), tau1_s_t(j,1)
            enddo
        endif
    endif