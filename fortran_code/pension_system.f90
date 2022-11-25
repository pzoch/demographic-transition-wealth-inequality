    valor_mult(1) = (1 + valor_share*(gam_t(1)*nu(1)  - 1))/gam_t(1)
    valor_mult(2) = (1 + valor_share*(gam_t(1)*nu(1)  - 1))/gam_t(2)
    wl_bar = 0.0d0
    do i = 1,bigT,1
    do m = 1,bigM,1
        wl_bar(i) = wl_bar(i) +  sum( N_big_t_j(:,m,i)  * l_j(:,m,i)*w_bar(m,i), dim=1)   
    enddo
    enddo
    do i = 3,bigT,1
        valor_mult(i) = (1 + valor_share*(gam_t(i-1)*(wl_bar(i-1))/(wl_bar(i-2))-1))/gam_t(i)
    enddo 
    
    
    rI(1) = gam_t(1)*nu(1) - 1 
    rI(2) = gam_t(1)*nu(1) - 1
    do i = 3,n_p+1,1
        rI(i) = gam_t(i-1)*(wl_bar(i-1))/(wl_bar(i-2))-1 !*(N_t(i-1)/N_t(i-2))-1 !(gam_t(i-1)*w_bar(i-1)*bigl(i-1)*N_t(i-1))/(w_bar(i-2)*bigl(i-2)*N_t(i-2))-1
    enddo
    rI(n_p+2:bigT) = nu(n_p+1)*gam_t(n_p+2) - 1
    
    
    do i = 1, bigT, 1
        avg_wl(i) = 0d0
        do m = 1,bigM,1
        do j = 1, jbar_t(max(i-1,1)) -1
            avg_wl(i) = avg_wl(i) + type_share_j_t(jbar_t(max(i-1,1)) -j,m,max(i-j,1)) *w_j(jbar_t(max(i-1,1)) -j, m, max(i-j,1)) *l_j(jbar_t(max(i-1,1)) -j,m,max(i-j,1))    
        enddo
        enddo 
        avg_wl(i) = avg_wl(i)/real(jbar_t(max(i-1,1)) -1)
    enddo
    
    !!!!!!!!!!!!!!!!! DB pension system !!!!!!!!!!!!!!!!!
    ! indivdual pension benefits 
    do m = 1,bigM,1
    do i = 2,bigT,1
        b1_j(1:jbar_t(i)-1,m,i) = 0
        b2_j(1:jbar_t(i)-1,m,i) = 0
            do j = jbar_t(i),bigJ,1
                if (j == jbar_t(i)) then
                    if (jbar_t(i) == jbar_t(i-1)+1) then
                        b1_j(j,m,i) = valor_mult(i)*b1_j(j-1,m,i-1)
                        b2_j(j,m,i) = 0
                    else
                        if( i< bigJ) then 
                            b1_j(j,m,i) = ((bigJ-i)*rho_1+ i*rho_2)/float(bigJ)*avg_wl(i) 
                        else 
                            b1_j(j,m,i) = rho_2*avg_wl(i) 
                        endif
                        b2_j(j,m,i) = 0
                    endif
                    
                    
                    else if (b1_j(j-1,m,i-1) == 0) then
                        if( i< bigJ) then 
                            b1_j(j,m,i) = ((bigJ-i)*rho_1+ i*rho_2)/float(bigJ)*avg_wl(i) 
                        else 
                            b1_j(j,m,i) = rho_2*avg_wl(i) 
                        endif
                        b2_j(j,m,i) = 0                                                
                    else
                        b1_j(j,m,i) = valor_mult(i)*b1_j(j-1,m,i-1)
                        b2_j(j,m,i) = 0
                endif        
            enddo 
        b_j(:,m,i) = b_scale_factor(i)*b1_j(:,m,i)    
        do j = 1, bigJ, 1
            subsidy_j(j,m,i) = sum_b_weight_trans_outer(min(max(i + jbar_t_yob(max(i-j+1, -bigj)) -j,1), bigT))*b_j(j,m,i) - t1(j,i)*w_bar(m,i)* l_j(j,m,i)   
        enddo
        contribution_j(:,m,i) = t1(:,i)*w_bar(m,i)*l_j(:,m,i)
    enddo 
    
    subsidy_j(:,m,1) = (sum_b_weight_trans_outer(1)*b_j(:,m,1) - t1(:,1))*w_bar(m,1)*l_j(:,m,1)   
    contribution_j(:,m,1) = t1(:,1)*w_bar(m,1)*l_j(:,m,1)
    enddo
     ! macro agg   
    subsidy = 0.0d0
    contribution = 0.0d0
    do m = 1,bigM,1
    
	subsidy = subsidy +  sum(N_t_j*type_share_j_t(:,m,:)*subsidy_j(:,m,:), dim=1)/bigl   
    contribution = contribution +   sum(N_t_j*type_share_j_t(:,m,:)*contribution_j(:,m,:), dim=1)/bigl 
    enddo
    
    do i = 1, bigT, 1
    sum_b(i) = 0d0
    do m = 1, bigM, 1
        do j = jbar_t(i), bigJ, 1
            sum_b(i) = sum_b(i) +    sum_b_weight_trans_outer(max(i + jbar_t_yob(max(i-j+1, -bigj)) -j,1))*b_j(j,m,i)*type_share_j_t(j,m,i)*N_t_j(j,i)/bigl(i)
        enddo
    enddo
    
    enddo  
