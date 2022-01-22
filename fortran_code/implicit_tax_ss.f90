b_pom_ss_j = b_ss_j
w_pom_ss_j = w_ss_j
tau1_ss = 0.0_dp
tau2_ss = 0.0_dp
    
if (switch_type == 1) then 
    if (switch_see_ret == 1) then
        b_pom_ss_j = 0.0_dp
        ! calculate implicit retirement tax rates
        w_pom_ss_j = w_ss_j
        ret1_help = 0.0_dp
        ret2_help = 0.0_dp
        do s = 0, bigJ-jbar_ss
            ret1_help = ret1_help + ((valor_mult_ss*gam_ss)/(r_ss))**s 
            ret2_help = ret2_help + ((1+r_bar_ss)/(r_ss))**s 
        enddo

        tau1_ss = 0.0_dp
        tau2_ss = 0.0_dp
        do j = 1, jbar_ss-1
            tau1_ss(j) = ((1+rI_ss)/(r_ss))**(jbar_ss-j)* & ! market interst rate
                         pi_ss(j)/pi_ss(jbar_ss)* &  ! annuity part
                         ret1_help/life_exp(jbar_ss)
            tau2_ss(j) = ((1+r_bar_ss)/(r_ss))**(jbar_ss-j)*&
                         pi_ss(j)/pi_ss(jbar_ss)*&
                         ret2_help/life_exp(jbar_ss)
        enddo
        

           w_pom_ss_j = (1.0_dp - tL_ss) &
                         *(1.0_dp - t1_ss -  t2_ss)*w_bar_ss &
                         + (t1_ss*tau1_ss + t2_ss*tau2_ss)*w_bar_ss       
     
        
        
        ret1_help = 0.0_dp
        ret2_help = 0.0_dp
        do s = 0, bigJ-jbar_ss
            ret1_help = ret1_help + ((valor_mult_ss*gam_ss)/(r_ss))**s 
            ret2_help = ret2_help + ((1+r_bar_ss)/(r_ss))**s 
        enddo
        
        ! implicit tax for retiree tau*pillar+sv =sv_pom
        do j = jbar_ss, bigJ -1
            nom1 = 0.0_dp
            denom1 = 0.0_dp
            
            nom2 = 0.0_dp
            denom2= 0.0_dp
            do s = 1, bigJ-j
                nom1 = (1+nom1)*(1+rI_ss)/(r_ss)
                denom1 = denom1 + pi_ss(j+s)/pi_ss(j)
                
                nom2 = (1+nom2)*(1+r_bar_ss)/(r_ss)
                denom2 = denom2 + pi_ss(j+s)/pi_ss(j)
            enddo
            
            tau1_ss(j) = nom1/denom1
            tau2_ss(j) = nom2/denom2
        enddo 
        endif
    endif