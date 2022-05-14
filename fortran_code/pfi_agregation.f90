!***************************************************************************************
! find aggegate variables for steady state

    subroutine aggregation_ss()
    
        implicit none
        
        integer :: ij, ial, iar, ia_last, tt
        real*8 :: check_e(bigJ), check_euler_cum, euler_max(bigJ), w_sum(0:bigJ), bc,  ERHS_ss(bigJ, 0:n_a,  n_sp, n_sr,n_sd),  sum_y, dist 
        real*8 :: sum_help, p_1_5(bigJ)
    
       ! write(*,*) c_ss(1,0,3)
        ! calculate cohort aggregates
        savings_cohort_ten = 0d0
        c_ss_j_vfi(:) = 0d0
        V_ss_j_vfi(:) = 0d0
        l_ss_j_vfi(:) = 0d0
        s_pom_ss_j_vfi(:) = 0d0
        lab_ss_j_vfi(:) = 0d0
        asset_pom_ss_j(:) = 0d0
        l_ss_pen_j_vfi(:) = 0d0
        w_sum(0) = 0d0
        ERHS_ss = 0d0
        top_ten(:) = 0d0 
        top_ten_coh(:) =0d0
        top_100 =0d0
        savings_top_100 = 0d0
        lab_high_ss_j_vfi(:)= 0d0
        gini_weight_sv = 0d0
        gini_weight_consumption = 0d0
        sum_b_weight_ss = 0d0
        
        share_neg = 0d0
        share_nonpos = 0d0
        
        labor_tax_ss_j_vfi(:) = 0d0
        lw_lambda_ss_j_vfi(:) = 0d0
        lw_ss_j_vfi(:) = 0d0
        t = 10
        tt =100
        if (n_sp > 5) then
            do j=1,bigJ,1
                p_1_5(j) = sum(prob_ss(j,:,:,1:5,:,:))
            enddo
        else 
            do j=1,bigJ,1
                p_1_5(j) = 1d0
            enddo
        endif
        savings_top_ten =0d0
        cons_proc_top_ten_coh(:)= 0d0
        consumption_top_ten = 0d0
        call linear_int(0d0, ial, iar, dist, sv, n_a, a_grow)
                                        ial = min(ial, n_a)
                                        iar = min(iar, n_a)
                                        dist = min(dist, 1d0)
                                        
        ia_last = n_a
            do ia = n_a, 0 , -1
                do i_aime = n_aime, 0 , -1
                    do j = 1, bigJ 
                        do ip = 1, n_sp, 1  
                            do ir=1, n_sr, 1
                                do id = 1, n_sd, 1
                                    gini_weight_sv(j,ia) = gini_weight_sv(j,ia) + prob_ss(j, ia, i_aime, ip, ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                    gini_weight_consumption(j, ia, i_aime, ip,ir, id) = gini_weight_consumption(j, ia, i_aime, ip,ir, id) + prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                    gini_income(j, ia, i_aime, ip,ir, id) = omega_ss(j)*n_sp_value(ip)*l_ss(j, ia, i_aime, ip, ir, id)*w_pom_ss_vfi(j)
                                    if (top_ten(t) >= 0.1d0) then 
                                        t = t-1
                                        top_ten(t) =  top_ten(t) + prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                        savings_top_ten(t) = savings_top_ten(t) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)*N_ss_j_vfi(j)
                                    else
                                        top_ten(t) =  top_ten(t) + prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                        savings_top_ten(t) = savings_top_ten(t) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)*N_ss_j_vfi(j)
                                    endif
                                    
                                        
                                    if (ia < ial) then
                                        share_neg = share_neg +  prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                    endif
                                
                                    if (ia <= iar) then
                                        share_nonpos =  share_nonpos + prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                    endif
                                    !if (top_ten(t) < -0.00001d0) then 
                                    !    write(*,*) prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                    !endif
                                     if (top_100(tt) >= 0.01d0) then 
                                        tt = tt-1
                                        top_100(tt) =  top_100(tt) + prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                        savings_top_100(tt) = savings_top_100(tt) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)*N_ss_j_vfi(j)
                                    else
                                        top_100(tt) =  top_100(tt) + prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                        savings_top_100(tt) = savings_top_100(tt) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)*N_ss_j_vfi(j)
                                    endif
                                    if (top_ten_coh(j) <= 0.1d0 ) then 
                                
                                        top_ten_coh(j) =  top_ten_coh(j) + prob_ss(j, ia, i_aime, ip,ir, id)
                                        savings_cohort_ten(1,j) = savings_cohort_ten(1,j) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)*10d0
                                        savings_cohort_ten(3,j) = savings_cohort_ten(3,j) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)
                                        consumption_top_ten(1,j) =  consumption_top_ten(1,j) + c_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)*10d0
                                        consumption_top_ten(3,j) =  consumption_top_ten(3,j) + c_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)
                                    elseif(top_ten_coh(j) >= 0.9d0)then
                                        top_ten_coh(j) =  top_ten_coh(j) + prob_ss(j, ia, i_aime, ip,ir, id)
                                        savings_cohort_ten(2,j) = savings_cohort_ten(2,j) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)*10
                                        savings_cohort_ten(3,j) = savings_cohort_ten(3,j) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)
                                        consumption_top_ten(3,j) =  consumption_top_ten(3,j) + c_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)
                                        consumption_top_ten(2,j) =  consumption_top_ten(2,j) + c_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)*10
                                    else
                                        top_ten_coh(j) =  top_ten_coh(j) + prob_ss(j, ia, i_aime, ip,ir, id)
                                        savings_cohort_ten(3,j) = savings_cohort_ten(3,j) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)
                                        consumption_top_ten(3,j) =  consumption_top_ten(3,j) + c_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)
                                    endif
                            
                                    c_ss_j_vfi(j) = c_ss_j_vfi(j) + c_ss(j, ia, i_aime, ip, ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)
                            
                                    if(ip<6)then
                                        l_ss_pen_j_vfi(j) = l_ss_pen_j_vfi(j) + omega_ss(j)*n_sp_value(ip)*l_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)/p_1_5(j)
                                    endif 
                                    if(ip>=6)then
                                        lab_high_ss_j_vfi(j) = lab_high_ss_j_vfi(j) + l_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)/(1d0-p_1_5(j))
                                    endif
                                    l_ss_j_vfi(j) = l_ss_j_vfi(j) + omega_ss(j)*n_sp_value(ip)*l_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)
                                    lab_ss_j_vfi(j) = lab_ss_j_vfi(j) + l_ss(j, ia, i_aime, ip, ir, id)*prob_ss(j, ia, i_aime, ip, ir, id) 
                                    labor_tax_ss_j_vfi(j) = labor_tax_ss_j_vfi(j) + labor_tax(j, ia, i_aime, ip, ir, id)*prob_ss(j, ia, i_aime, ip, ir, id)
                                    lw_lambda_ss_j_vfi(j) = lw_lambda_ss_j_vfi(j) + (omega_ss(j)*n_sp_value(ip)*w_pom_ss_vfi(j)*l_ss(j, ia, i_aime, ip,ir, id))**(1-lambda)*prob_ss(j, ia, i_aime, ip,ir, id)
                                    lw_ss_j_vfi(j) = lw_ss_j_vfi(j) + omega_ss(j)*n_sp_value(ip)*w_pom_ss_vfi(j)*l_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip, ir, id) 
                                    s_pom_ss_j_vfi(j) = s_pom_ss_j_vfi(j) + svplus_ss(j, ia, i_aime, ip, ir, id)*prob_ss(j, ia, i_aime, ip, ir, id)
                                    asset_pom_ss_j(j) = asset_pom_ss_j(j) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id) 
                                    !if (prob_ss(j, ia, i_aime, ip, ir, id) > 1d-10) then 
                                        V_ss_j_vfi(j)  =  V_ss_j_vfi(j) + V_ss(j, ia, i_aime, ip, ir, id)*prob_ss(j, ia, i_aime, ip, ir, id)
                                   ! endif
                                    sum_y = sum_y + prob_ss(j, ia, i_aime, ip, ir, id)  
                                enddo
                            enddo
                        enddo
                        if(j>1)then
                            w_sum(j) = w_sum(j-1) + aime_replacement_rate(i_aime)*b_ss_j_vfi(j) + l_ss_j_vfi(j)*w_pom_ss_vfi(j) + bequest_ss_j_vfi(j) - upsilon_ss_vf 
                        else
                            w_sum(j) = 0d0 + aime_replacement_rate(i_aime)*b_ss_j_vfi(j) + l_ss_j_vfi(j)*w_pom_ss_vfi(j) + bequest_ss_j_vfi(j) - upsilon_ss_vf 
                        endif
               
                    enddo
               
                    ia_last = ia
                enddo
            enddo
            
            do i_aime = 0, n_aime   
                sum_b_weight_ss_vfi = sum_b_weight_ss_vfi + aime_replacement_rate(i_aime)*sum(prob_ss(jbar_ss_vf, :, i_aime, :, :, :))
                !!! this has to be correct
            enddo

            do j = 1,bigJ-1,1
                check_e(j)=sum(ERHS_ss(j,:,:, :,:)) ! check euler (only of theta = 1) with other theta marginal utility is not linear 
            enddo
            check_euler_cum = sum(check_e)
       
            bc = sum(c_ss_j_vfi(1:bigJ)*tc_ss_vfi)- (r_ss_vfi/gam_ss_vfi-1d0)*sum(s_pom_ss_j_vfi(1:bigJ)) - w_sum(bigJ) ! budget constraint 
    !        write(*,*) check_euler_cum
            euler_max = abs(check_e)

        open(unit = 104, file= "euler_ss.csv")
            do j = 2,bigJ,1
                write(104, '(F20.10)') check_e(j)
            enddo
        close(104)
        
        
        if (switch_run_1 == 1)then
            check_euler_trans(:,1) = check_e
        endif
        
    end subroutine

!***************************************************************************************

! find aggegate variables for transition
    subroutine aggregation_trans(i)
    
        implicit none
        integer, intent(in) :: i 
        integer :: j, ial, iar, tp, year_birth
        real*8 ::  check_euler_trans_cum, euler_trans_max(bigJ), lab_j_vfi(bigJ,bigT), w_sum(0:bigJ), bc, sum_y, sum_help, dist, p_1_5_trans(bigJ,bigT), sum_n 
        
        t = 10
       ! write(*,*) c_trans(1,0,3)
        ! calculate cohort aggregates
        c_j_vfi(:,i) = 0d0
        V_j_vfi(:,i) = 0d0
        l_j_vfi(:,i) = 0d0
        avg_aime_replacement_rate(:,i) = 0d0
        labor_tax_j_vfi(:,i) = 0d0
        lw_lambda_j_vfi(:,i) = 0d0
        lw_j_vfi(:,i) = 0d0
        l_pen_j_vfi(:,i) = 0d0
        s_pom_j_vfi(:,i) = 0d0
        lab_j_vfi(:,i) = 0d0
        asset_trans(:,i) = 0d0
        top_ten_trans(:,i) = 0d0
        savings_top_ten_trans(:,i) = 0d0
        sum_n= sum(N_t_j_vfi(:,i))
        w_sum(0) = 0d0
        ERHS_trans(:,:,:,:,:,:,i) = 0d0
        sum_b_weight_trans(i) = 0d0
        if (n_sp>5) then 
            do j=1,bigJ,1
                p_1_5_trans(j,i) = sum(prob_trans(j,:,:,1:5,:,:,i))
            enddo
        else 
            do j=1,bigJ,1
                p_1_5_trans(j,i) = 1d0
            enddo
        endif
        gini_weight_trans(:,:, i) = 0.0d0
        do ia = n_a, 0, -1 
            do i_aime = n_aime, 0 , -1
                do j = 1, bigJ
                    
                                ! this is new, NEED TO ADD TIME-SPECIFIC VARIANCES
                                year_birth = i - j + 1  ! get year of birth to assign correct sigma2_epsilon


                                tp = year_birth 

                                if (tp < 1) then
                                tp = 1
                                elseif (tp > bigT) then
                                tp = bigT
                                endif
            
                    do ip = 1, n_sp, 1
                        do ir=1, n_sr, 1
                            do id =1, n_sd, 1
                                c_j_vfi(j,i) = c_j_vfi(j,i) + c_trans(j, ia, i_aime, ip, ir, id, i)*prob_trans(j, ia, i_aime, ip, ir, id,i)
                                l_j_vfi(j,i) = l_j_vfi(j,i) + omega(j,i)*n_sp_value_trans(ip,tp)*l_trans(j, ia, i_aime, ip, ir, id,i)*prob_trans(j, ia, i_aime, ip, ir, id,i)
                                lab_j_vfi(j,i) = lab_j_vfi(j,i) + l_trans(j, ia, i_aime, ip, ir, id, i)*prob_trans(j, ia, i_aime, ip, ir, id,i)  
                                labor_tax_j_vfi(j,i) = labor_tax_j_vfi(j,i) + labor_tax_trans(j, ia, i_aime, ip, ir, id, i)*prob_trans(j, ia, i_aime, ip, ir, id,i)  
                            
                                lw_j_vfi(j,i) = lw_j_vfi(j,i) + omega(j,i)*n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, i)*l_trans(j, ia, i_aime, ip, ir, id,i)*prob_trans(j, ia, i_aime, ip, ir, id,i)
                                lw_lambda_j_vfi(j,i) = lw_lambda_j_vfi(j,i) + (omega(j,i)*n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, i)*l_trans(j, ia, i_aime, ip, ir, id,i))**(1-lambda)*prob_trans(j, ia, i_aime, ip, ir, id,i)  
                            
                                s_pom_j_vfi(j,i) = s_pom_j_vfi(j,i) + svplus_trans(j, ia, i_aime, ip, ir, id,i)*prob_trans(j, ia, i_aime, ip, ir, id,i)
                                !if (prob_trans(j, ia, i_aime, ip, ir,i)>1d-8) then  
                                    V_j_vfi(j,i)   =   V_j_vfi(j,i) + V_trans(j, ia, i_aime, ip, ir, id,i)*prob_trans(j, ia, i_aime, ip, ir, id,i) 
                                !endif 
                                gini_weight_trans(j,ia, i) = gini_weight_trans(j,ia,i) + prob_trans(j, ia, i_aime, ip,ir, id, i)*N_t_j_vfi(j,i)/sum_n
                                asset_trans(j,i) = asset_trans(j,i) + sv(ia)*prob_trans(j, ia, i_aime, ip, ir, id,i)    
                                !if (top_ten_trans(t,i) >= 0.1d0) then ! todotodotodot
                                !    t = t-1
                                !    top_ten_trans(t,i) =  top_ten_trans(t,i) + prob_trans(j, ia, i_aime, ip,ir, id,i)*N_t_j_vfi(j,i)/sum_n
                                !    savings_top_ten_trans(t,i) = savings_top_ten_trans(t,i) + sv(ia)*prob_trans(j, ia, i_aime, ip,ir, id,i)*N_t_j_vfi(j,i)
                                !else
                                !    top_ten_trans(t,i) =  top_ten_trans(t,i) + prob_trans(j, ia, i_aime, ip,ir, id,i)*N_t_j_vfi(j,i)/sum_n
                                !    savings_top_ten_trans(t,i) = savings_top_ten_trans(t,i) + sv(ia)*prob_trans(j, ia, i_aime, ip,ir, id,i)*N_t_j_vfi(j,i)
                                !endif                                                   
                                if(ip<6)then
                                    l_pen_j_vfi(j,i) = l_pen_j_vfi(j,i) + omega(j,i)*n_sp_value_trans(ip,tp)*l_trans(j, ia, i_aime, ip, ir, id,i)*prob_trans(j, ia, i_aime, ip, ir, id,i)/p_1_5_trans(j,i)
                                endif
                                if ((prob_trans(j, ia, i_aime, ip, ir, id,i)>1d-10) .and. (j<bigJ)) then
                                    sum_help = 0.0d0
                                    call linear_int(svplus_trans(j, ia, i_aime, ip, ir, id,i), ial, iar, dist, sv, n_a, a_grow)
                                    do ip_p = 1, n_sp,1
                                        do ir_r=1, n_sr, 1
                                            do id_d =1, n_sd, 1
                                                sum_help  = sum_help + dist*pi_ip(ip, ip_p)*pi_ir(ir,ir_r)*pi_id(id, id_d)*(delta+n_sd_value(id))&
                                                            *margu(c_trans(j+1, ial, i_aime, ip_p, ir_r, id_d, min(i+1, bigT)),l_trans(j+1,ial, i_aime, ip_p, ir_r, id_d, min(i+1, bigT)),tc_vfi(min(i+1, bigT)) )
                                                sum_help  = sum_help + (1-dist)*pi_ip(ip, ip_p)*pi_ir(ir,ir_r)*pi_id(id, id_d)*(delta+n_sd_value(id))&
                                                            *margu(c_trans(j+1, iar, i_aime, ip_p, ir_r, id_d, min(i+1, bigT)),l_trans(j+1,iar, i_aime, ip_p, ir_r, id_d, min(i+1, bigT)),tc_vfi(min(i+1, bigT)) )
                                            enddo
                                        enddo
                                    enddo
                                    ! this is not correct!!!
                                    ERHS_trans(j, ia, i_aime, ip, ir, id,i) = abs(margu(c_trans(j, ia, i_aime, ip, ir, id, i),l_trans(j, ia, i_aime, ip, ir, id,i), tc_vfi(i)) - sum_help*beta*r_vfi(min(i+1, bigT))*n_sr_value(ir)/gam_vfi(min(i+1, bigT))*pi_trans_vfi_cond(j+1,min(i+1, bigT)))
                                endif
                                sum_y = sum_y + prob_trans(j, ia, i_aime, ip, ir, id,i)
                                avg_aime_replacement_rate(j,i) = aime_replacement_rate(i_aime)*prob_trans(j, ia, i_aime, ip, ir, id,i)
                            enddo
                        enddo
                    enddo
                enddo
            enddo
        enddo
        do j =1,bigJ-1,1
            check_euler_trans(j,i) = sum(ERHS_trans(j,:,:,:,:,:,i))
        enddo
        if ((switch_partial_efficiency == 0) .and. ( switch_partial_semi == 0)) then 
            do i_aime = 0, n_aime   
                sum_b_weight_trans(i) = sum_b_weight_trans(i) + aime_replacement_rate(i_aime)*sum(prob_trans(jbar_t_vfi(i), :, i_aime, :, :, :, i))
            enddo
        endif

    end subroutine

!**************************************************************************************
