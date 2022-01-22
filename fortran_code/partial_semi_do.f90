    
    do i = 2, bigT, 1    
        r_bar(i) = r_bar(1)
        rI(i) = rI(1)
        b_scale_factor(i) = b_scale_factor(1)
    enddo
    
    ! adjust of implicit tax to take into account higher tax rate
        include 'implicit_tax_trans.f90'
    
    ! assign macro variables
        do i = 1, bigT,1
            w_pom_trans_vfi(:,i) = (1 - t1(:,i) - t2(:,i))*omega(:,i)*w_bar(1)
            w_pom_trans_implicit_vfi(:,i) = (t1_contrib(:,i)*tau1_s_t(:,i) + t2(:,i)*tau2_s_t(:,i))*omega(:,i)*w_bar(1)
            b_j_vfi(:,i) = b_pom_j(:,1)
            bequest_j_vfi(:,i) =  bequest_j(:,1)
        enddo
        r_vfi = r - 1d0 
        tc_vfi = tc(1) + 1.0_dp
        upsilon_vfi = upsilon(1)
    
    ! solve household problem
        call agent_vf_trans() 
        
    ! adjust pillar 
        include 'pillar_partial.f90'      
        
    ! update savings decysions
    sv_j_el=  s_pom_j_vfi
    if ( (switch_see_ret == 1) .and. (switch_type_2 == 1)) then
        do i = 2,bigT,1
            do j = 1, bigJ, 1 
                if (j == 1) then
                    sv_j_el(j,i) =  s_pom_j_vfi(j,i) -  l_j_vfi(j,i)*w_pom_trans_implicit_vfi(j,i) - (b_pom_j(j,i) -b_j(j,i)) 
                else                                           
                    sv_j_el(j,i) =  s_pom_j_vfi(j,i) - r_vfi(i)*(s_pom_j_vfi(j-1,i-1) - sv_j(j-1,i-1))/gam_t(i) &
                                    - l_j_vfi(j,i)*w_pom_trans_implicit_vfi(j,i)  -  (b_pom_j(j,i) -b_j(j,i))
                endif 
            enddo  
        enddo   
    endif
    
    
