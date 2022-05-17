    valor_mult(1) = (1 + valor_share*(gam_t(1)*nu(1)  - 1))/gam_t(1)
    valor_mult(2) = (1 + valor_share*(gam_t(1)*nu(1)  - 1))/gam_t(2)
    
    do m = 1,bigM,1
        wl_bar = wl_bar +  bigM_share_ss(m) * sum( N_t_j*l_j(:,m,:)*w_bar(m,:), dim=1)   
    enddo
    
    do i = 3,bigT,1
        valor_mult(i) = (1 + valor_share*(gam_t(i-1)*(wl_bar(i-1))/(wl_bar(i-2))-1))/gam_t(i)
    enddo 
    
    
    rI(1) = gam_t(1)*nu(1) - 1 
    rI(2) = gam_t(1)*nu(1) - 1
    do i = 3,n_p+1,1
        rI(i) = gam_t(i-1)*(wl_bar(i-1))/(wl_barl(i-2))-1 !*(N_t(i-1)/N_t(i-2))-1 !(gam_t(i-1)*w_bar(i-1)*bigl(i-1)*N_t(i-1))/(w_bar(i-2)*bigl(i-2)*N_t(i-2))-1
    enddo
    rI(n_p+2:bigT) = nu(n_p+1)*gam_t(n_p+2) - 1
    

    do i = 1, bigT, 1
        avg_wl(i) = 0d0
        
        do j = 1, jbar_t(max(i-1,1)) -1
            avg_wl(i) = avg_wl(i) + bigM_share_ss(m) * w_j(jbar_t(max(i-1,1)) -j, m, max(i-j,1)) *l_j(jbar_t(max(i-1,1)) -j,m,max(i-j,1))    
        enddo
        avg_wl(i) = avg_wl(i)/real(jbar_t(max(i-1,1)) -1)
    enddo 
    

    
    !!!!!!!!!!!!!!!!! DB pension system !!!!!!!!!!!!!!!!!
    ! indivdual pension benefits 
 
    do i = 2,bigT,1
        b1_j(1:jbar_t(i)-1,:,i) = 0
        b2_j(1:jbar_t(i)-1,:,i) = 0
            do j = jbar_t(i),bigJ,1
                if (j == jbar_t(i)) then
                    if (jbar_t(i) == jbar_t(i-1)+1) then
                        b1_j(j,:,i) = valor_mult(i)*b1_j(j-1,:,i-1)
                        b2_j(j,:,i) = 0
                    else
                        if( i< bigJ) then 
                            b1_j(j,:,i) = ((bigJ-i)*rho_1+ i*rho_2)/float(bigJ)*avg_wl(i) 
                        else 
                            b1_j(j,:,i) = rho_2*avg_wl(i) 
                        endif
                        b2_j(j,:,i) = 0
                    endif
                    else if (b1_j(j-1,:,i-1) == 0) then
                        if( i< bigJ) then 
                            b1_j(j,:,i) = ((bigJ-i)*rho_1+ i*rho_2)/float(bigJ)*avg_wl(i) 
                        else 
                            b1_j(j,:,i) = rho_2*avg_wl(i) 
                        endif
                        b2_j(j,:,i) = 0                                                
                    else
                        b1_j(j,:,i) = valor_mult(i)*b1_j(j-1,:,i-1)
                        b2_j(j,:,i) = 0
                endif        
            enddo 
        b_j(:,:,i) = b_scale_factor(i)*b1_j(:,:,i)    
        do j = 1, bigJ, 1
            subsidy_j(j,i) = sum_b_weight_trans(min(max(i + jbar_t_yob(max(i-j+1, -bigj)) -j,1), bigT))*b_j(j,i) - t1(j,i)*w_bar(i)* l_j(j,i)   
        enddo
        contribution_j(:,i) = t1(:,i)*w_bar(i)*l_j(:,i)
    enddo 
    
    subsidy_j(:,1) = (sum_b_weight_trans(1)*b_j(:,1) - t1(:,1))*w_bar(1)*l_j(:,1)   
    contribution_j(:,1) = t1(:,1)*w_bar(1)*l_j(:,1)
 
     ! macro agg    
	subsidy = sum(N_t_j*subsidy_j, dim=1)/bigl   
    contribution = sum(N_t_j*contribution_j, dim=1)/bigl 
    do i = 1, bigT, 1
    sum_b(i) = 0d0
        do j = jbar_t(i), bigJ, 1
            sum_b(i) = sum_b(i) + sum_b_weight_trans(max(i + jbar_t_yob(max(i-j+1, -bigj)) -j,1))*b_j(j,i)*N_t_j(j,i)/bigl(i)
        enddo
    enddo  
