! WHAT   :  First guess for transition_db
! TAKE   :  values from steady_1 and steady_2  
! DO     :  read them for first guess at the end of the transition path, jump wise with data from steady state
! RETURN :  base variable CRUCIAL to next run on the path

! from the old steady state
    k(1) = k_ss_1                                            
    l_j(:,:,1) = l_ss_j_1
    c_j(:,:,1) = c_ss_j_1
    sv_j(:,:,1) = s_ss_j_1
    b_j(:,:,1) = b_ss_j_1 
    l_pen_j(:,:,1) =  l_ss_pen_j_1
    b1_j(:,:,1) = b1_ss_j_1
    b2_j(:,:,1) = b2_ss_j_1
    
    pillarI_j(:,1) =  pillar1_ss_j_1
    pillarII_j(:,1) =  pillar2_ss_j_1
    bequest_left_j(:,:,1) = bequest_left_ss_j_1
    
! from the new steady state
do i = 3, bigT, 1 ! n_p+2,bigT,1
    k(i) = k_ss_2 
    l_j(:,:,i) = l_ss_j_2
    c_j(:,:,i) = c_ss_j_2
    sv_j(:,:,i) = s_ss_j_2
    b_j(:,:,i) = b_ss_j_2
    l_pen_j(:,:,i) =  l_ss_pen_j_2
    b1_j(:,:,i) = b1_ss_j_2
    b2_j(:,:,i) = b2_ss_j_2
    
    pillarI_j(:,i) =  pillar1_ss_j_2
    pillarII_j(:,i) =  pillar2_ss_j_2
    bequest_left_j(:,:,i) = bequest_left_ss_j_2
enddo
    
! on the transition path
! jump-wise filling, from the old steady state
do i = 2,2, 1 !n_p+1,1
    k(i) = k_ss_1  
    l_j(:,:,i) = l_ss_j_1
    c_j(:,:,i) = c_ss_j_1
    sv_j(:,:,i) = s_ss_j_1
    b_j(:,:,i) = b_ss_j_1
    l_pen_j(:,:,i) =  l_ss_pen_j_1
    b1_j(jbar_t(i):bigJ,:,i) = b1_ss_j_1(jbar_t(i):bigJ,:)
    b2_j(jbar_t(i):bigJ,:,i) = b2_ss_j_1(jbar_t(i):bigJ,:)
    pillarI_j(:,i) =  pillar1_ss_j_1
    pillarII_j(:,i) =  pillar2_ss_j_1
    bequest_left_j(:,:,i) = bequest_left_ss_j_2
    enddo      
    
g_per_capita(1) = g_per_capita_ss_1 
g_per_capita(2:) = g_per_capita_ss_2 
b_scale_factor(1) = 1d0 !b_scale_factor_old 
b_scale_factor(2:) = 1d0 !b_scale_factor_new
        

if (switch_type_1 == 0) then
    b2_j(:,:,1) = 0
    pillarI_j(:,1) =  0
    pillarII_j(:,1) =  0
else
    b2_j(:,:,1) = b2_ss_j_1
    pillarI_j(:,1) =  pillar1_ss_j_1
    pillarII_j(:,1) =  pillar2_ss_j_1
endif
    
    do i = -bigJ, n_p +1 ,1
        sv_pom_j(:,:,max(i,1)) = s_pom_ss_j_1(:,:)
        tau1_s_t(:,i) = tau1_ss_1(:)
        tau2_s_t(:,i) = tau2_ss_1(:)
        w_pom_j(:,:,i)  = w_pom_ss_j_1(:,:)
    enddo
        
    do i = n_p+2,bigT,1
        sv_pom_j(:,:,i) = s_pom_ss_j_2(:,:)
        tau2_s_t(:,i) = tau2_ss_2(:)
        tau1_s_t(:,i) = tau1_ss_2(:)
        w_pom_j(:,:,i)  = w_pom_ss_j_2(:,:)
    enddo
    
