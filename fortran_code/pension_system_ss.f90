if (switch_type == 0)  then     
    b2_ss_j = 0  
    b1_ss_j(1:jbar_ss-1) = 0

    avg_wl = sum(w_ss_j(1:jbar_ss-1)*l_ss_j(1:jbar_ss-1))/(real(jbar_ss-1))

    b1_ss_j(jbar_ss) = rho*avg_wl !w_ss_j(jbar_ss-1)*l_ss_j(jbar_ss-1) 
    do j = jbar_ss+1,bigJ,1
        b1_ss_j(j) = valor_mult_ss*b1_ss_j(j-1)
    enddo
    
    b_ss_j = b_scale_factor_ss*b1_ss_j 
    sum_b_ss = sum_b_weight_ss*sum(b_ss_j*N_ss_j(1:bigJ))/bigl_ss
    subsidy_ss_j = sum_b_weight_ss*b_ss_j - t1_ss*w_bar_ss*l_ss_j       
    subsidy_ss = sum(N_ss_j*subsidy_ss_j(1:bigJ))/bigl_ss
else    
    contributionI_ss_j = t1_ss*w_bar_ss*l_ss_j
    contributionII_ss_j = t2_ss*w_bar_ss*l_ss_j
    b1_ss_j(1:jbar_ss-1) = 0d0
    b2_ss_j(1:jbar_ss-1) = 0
    pillarI_ss_j(1)  = contributionI_ss_j(1) 
    pillarII_ss_j(1) = contributionII_ss_j(1)
    accountI_ss = 0   
    accountII_ss = 0
    do j = 2,bigj,1
        if (j < jbar_ss) then
            pillarI_ss_j(j) = (1 + rI_ss)*pillarI_ss_j(j-1)/gam_ss*pi_ss(j-1)/pi_ss(j) + contributionI_ss_j(j) 
            pillarII_ss_j(j) = (1 + r_bar_ss)*pillarII_ss_j(j-1)/gam_ss*pi_ss(j-1)/pi_ss(j) + contributionII_ss_j(j)
        elseif (j == jbar_ss) then      
            accountI_ss  = (1 + rI_ss)*pillarI_ss_j(j-1)/gam_ss*pi_ss(j-1)/pi_ss(j) 
            accountII_ss = (1 + r_bar_ss)*pillarII_ss_j(j-1)/gam_ss*pi_ss(j-1)/pi_ss(j)
            b1_ss_j(j) = accountI_ss/life_exp(j) 
            b2_ss_j(j) = accountII_ss/life_exp(j)
            pillarI_ss_j(j) = (1 + rI_ss)*pillarI_ss_j(j-1)/gam_ss*pi_ss(j-1)/pi_ss(j) - b1_ss_j(j)
            pillarII_ss_j(j) = (1 + r_bar_ss)*pillarII_ss_j(j-1)/gam_ss*pi_ss(j-1)/pi_ss(j) - b2_ss_j(j)
        else 
            b1_ss_j(j) = valor_mult_ss*b1_ss_j(j-1)   
		    b2_ss_j(j) = b2_ss_j(j-1)*(1 + r_bar_ss)/gam_ss 
            pillarI_ss_j(j) = (1 + rI_ss)*pillarI_ss_j(j-1)/gam_ss*pi_ss(j-1)/pi_ss(j) - b1_ss_j(j)
            pillarII_ss_j(j) = (1 + r_bar_ss)*pillarII_ss_j(j-1)/gam_ss*pi_ss(j-1)/pi_ss(j)  - b2_ss_j(j)
        endif
    enddo
    b_ss_j = b_scale_factor_ss*b1_ss_j + b2_ss_j
        
    PillarI_ss = sum(N_ss_j*pillarI_ss_j(1:bigJ))/(bigl_ss) 
    PillarII_ss = sum(N_ss_j*pillarII_ss_j(1:bigJ))/(bigl_ss)

    sum_b_ss = sum((b_scale_factor_ss*b1_ss_j+b2_ss_j)*N_ss_j(1:bigJ))/bigl_ss 
                 
    subsidy_ss_j = b_scale_factor_ss*b1_ss_j  - t1_ss*w_bar_ss*l_ss_j  
    !subsidy_ss_j = b2_ss_j  - t2_ss*omega_ss*w_bar_ss*l_ss_j 
    subsidy_ss = sum(subsidy_ss_j*N_ss_j(1:bigJ))/bigl_ss
endif
