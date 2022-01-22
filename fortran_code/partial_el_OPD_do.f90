! adjust of implicit tax to take into account higher tax rate
    include 'implicit_tax_trans.f90'
    
    !! determine wages
    !do i = 1, bigT,1
    !    w_pom_trans_vfi(:,i) = (1 - t1(:,i) - t2(:,i))*omega(:,i)*w_bar(i)
    !    w_pom_trans_implicit_vfi(:,i) = (t1_contrib(:,i)*tau1_s_t(:,i) + t2(:,i)*tau2_s_t(:,i))*omega(:,i)*w_bar(i)
    !enddo
    
! household problem
    write(*,*) w_pom_trans_implicit_vfi(:,time_iter)
    call agent_vf_trans() 
    write(*,*)  l_j_vfi(:,time_iter)   
    
    ! we have labor decysion thus we can recalculate pensions 
    ! when labor decysion are made we need to recalculate 2nd pillar
!! to take into account total savings 
!    do j = 1,bigJ,1
!        contributionI_j(j,:) = t1_contrib(j,:)*omega(j,:)*w_bar(:)*l_j_vfi(j,:)
!        contributionII_j(j,:) = t2(j,:)*omega(j,:)*w_bar(:)*l_j_vfi(j,:)
!    enddo
!    ! pillar aould change - here we assume tat benefits are unchanged 
!    pillarI_j(1,:) = contributionI_j(1,:)
!    pillarII_j(1,:) = contributionII_j(1,:)
!    if (switch_type_1 == 0) then
!        ! instead of init cap from data...
!        !pillarI_j(:,1) = (t1_ss_old/0.1953_dp)*init_cap*average_w(1)
!        !... we use theoretical value 
!        !pillarI_j(1,1) = (t1(1,1)*omega(1,1)*w_bar(1)*l_j(1,1))
!        pillarI_j(1,1) = (t1_contrib(1,1)*omega(1,1)*w_bar(1)*l_j(1,1))
!        do j = 2,min(jbar_t(1)-1, ofe_u-1), 1 
!                pillarI_j(j,1) =  (1+rI(1))/gam_t(1)*pillarI_j(j-1,1)*N_t_j(j-1,1)/N_t_j(j,1) &
!                                + t1_contrib(j,1)*omega(j,1)*w_bar(1)*l_j(j,1)
!        enddo    
!        ! t1_a and t2 are equal zero in 1st period of transition path  
!        ! hence we add only contribution driven by t1 
!        pillarII_j(:,1) = 0
!    endif
!        do i = 2,bigT,1 
!            do j = 2,bigj,1
!                if (j < jbar_t(i)) then
!                    pillarI_j(j,i) = (1 + rI(i))*pillarI_j(j-1,i-1)/gam_t(i)*pi(j-1, i-1)/pi(j,i)  + contributionI_j(j,i) 
!                    pillarII_j(j,i) = (1 + r_bar(i))*pillarII_j(j-1,i-1)/gam_t(i)*pi(j-1, i-1)/pi(j,i)  + contributionII_j(j,i)
!                elseif (((j == jbar_t(i)) .and. ((j-1) .ne. jbar_t(i-1))) .or. (j > jbar_t(i) .and. b1_j(j-1,i-1) == 0)) then ! pension is not individual but cohort-specific
!                ! elseif (j == jbar_t(i)) then       ! pension is not individual but cohort-specific
!                    accountI = (1 + rI(i))*pillarI_j(j-1,i-1)/gam_t(i)*pi(j-1, i-1)/pi(j,i) 
!                    accountII = (1 + r_bar(i))*pillarII_j(j-1,i-1)/gam_t(i)*pi(j-1, i-1)/pi(j,i) 
!                    b1_j(j,i) = accountI/life_exp(j,i) ! beginning of the year
!                    b2_j(j,i) = accountII/life_exp(j,i) ! beginning of the year
!                    accountII = 0.0_dp
!                    pillarI_j(j,i) = (1 + rI(i))*pillarI_j(j-1,i-1)/gam_t(i)*pi(j-1, i-1)/pi(j,i)  - b1_j(j,i) ! end of the year
!                    pillarII_j(j,i) = (1 + r_bar(i))*pillarII_j(j-1,i-1)/gam_t(i)*pi(j-1, i-1)/pi(j,i)  - b2_j(j,i)! end of the year
!                else
!                    b1_j(j,i) = valor_mult(i)*b1_j(j-1,i-1)
!					b2_j(j,i) = b2_j(j-1,i-1)*(1 + r_bar(i))/gam_t(i) ! beginning of the year
!                    pillarI_j(j,i) = (1 + rI(i))*pillarI_j(j-1,i-1)/gam_t(i)*pi(j-1, i-1)/pi(j,i)  - b1_j(j,i) ! end of the year
!                    pillarII_j(j,i) = (1 + r_bar(i))*pillarII_j(j-1,i-1)/gam_t(i)*pi(j-1, i-1)/pi(j,i)  - b2_j(j,i) ! end of the year
!                endif  
!            enddo
!            b_j(:,i) = (b_scale_factor(i)*b1_j(:,i) + b2_j(:,i))!*(1 - tL(i))
!        enddo
!        
!    if (switch_pension == 1) then  ! 0 = all are in new pension scheme in transitionFF; 1 = old cohorts remain in the old system in transitionFF
!        do i = 2,bigT,1
!            do j = 2,bigJ,1
!                if (j >= jbar_t(1)+i-1) then 
!                    b1_j(j,i) = valor_mult(i)*b1_j(j-1,i-1)
!                    b2_j(j,i) = 0.0_dp
!                else
!                    if ((j-i+2 > ofe_u) .and. (j >= jbar_t(i))) then
!                        if (j == jbar_t(i)) then
!                            if (jbar_t(i) == jbar_t(i-1)+1) then
!                                b1_j(j,i) = valor_mult(i)*b1_j(j-1,i-1)
!                                b2_j(j,i) = 0.0_dp
!                            else
!                                b1_j(j,i) = rho_1*avg_wl(i) !! rho_1*average_w_10(i)
!                                b2_j(j,i) = 0.0_dp
!                            endif
!                        elseif (b1_j(j-1,i-1) == 0) then ! had pensions already in the old ss
!                            b1_j(j,i) = rho_1*avg_wl(i) 
!                            b2_j(j,i) = 0.0_dp                                               
!                        else
!                            b1_j(j,i) = valor_mult(i)*b1_j(j-1,i-1)
!                            b2_j(j,i) = 0.0_dp
!                        endif
!                    endif
!                endif 
!            enddo
!            b_j(:,i) = (b_scale_factor(i)*b1_j(:,i) + b2_j(:,i))
!        enddo
!    endif
    ! macro agg        
    ! we can update savings decysions
    if ( (switch_see_ret == 1) .and. (switch_type_2 == 1)) then
        do i = 2,bigT,1
            do j = 1, bigJ, 1 
                if (j == 1) then
                    sv_j_el(j,i) =  s_pom_j_vfi(j,i) -  l_j_vfi(j,i)*w_pom_trans_implicit_vfi(j,i)
                else                                           
                    sv_j_el(j,i) =  s_pom_j_vfi(j,i) - r_vfi(i)*(s_pom_j_vfi(j-1,i-1) - sv_j_el(j-1,i-1))/gam_t(i) &
                                    - l_j_vfi(j,i)*w_pom_trans_implicit_vfi(j,i)  -  (b_pom_j(j,i) -b_j(j,i))
                endif 
            enddo  
        enddo   
    else
        sv_j_el=  s_pom_j_vfi
    endif