    labor_tax_revenue_ss = 0.0d0
    do j = 1,bigJ,1
    do m = 1,bigM,1
       labor_tax_revenue_ss = labor_tax_revenue_ss +  N_big_ss_j(j,m)*labor_tax_ss_j(j,m)
    enddo
    enddo
    

    select case (switch_residual)
        
        
    case(0)
!       case 0 - upsilon is residual
        
        if (switch_tauK_gross == 0) then
            Tax_ss = tc_ss*consumption_ss_gross + tk_ss*(r_bar_ss)*(sum_priv_sv_ss)/(gam_ss*nu_ss) + labor_tax_revenue_ss/bigl_ss  !+ tL_ss*sum_b_ss   
            upsilon_ss = (subsidy_ss + g_ss + (1 + r_bar_ss)*debt_ss/(gam_ss*nu_ss) - debt_ss - Tax_ss)*bigl_ss/(sum(N_ss_j))
            upsilon_r_ss = (upsilon_ss*(sum(N_ss_j))/bigl_ss)/y_ss
            if (param_ss == 1) then
                upsilon_r_ss_1 = upsilon_ss
            endif  
            
        else
            Tax_ss = tc_ss*consumption_ss_gross + tk_ss*(r_bar_ss+depr)*(sum_priv_sv_ss-debt_ss+PillarII_ss)/(gam_ss*nu_ss) + labor_tax_revenue_ss/bigl_ss  !+ tL_ss*sum_b_ss   
            upsilon_ss = (subsidy_ss + g_ss + (r_ss)*debt_ss/(gam_ss*nu_ss) - debt_ss - Tax_ss)*bigl_ss/(sum(N_ss_j))
            upsilon_r_ss = (upsilon_ss*(sum(N_ss_j))/bigl_ss)/y_ss
            if (param_ss == 1) then
                upsilon_r_ss_1 = upsilon_ss
            endif
            
            endif
    case(1)             
!       case 1 - tC is residual
        if (switch_ref_run_now == 0) then
            upsilon_ss = upsilon_r_ss_1*y_ss*bigl_ss/(sum(N_ss_j))
            upsilon_r_ss_nr = upsilon_ss
        else 
            upsilon_ss = upsilon_r_ss_nr
        endif
        
        !deficit_ss =  (1 + r_bar_ss)/(gam_ss * nu_ss)  * debt_ss - debt_ss 
        if (switch_tauK_gross == 0) then
            
        deficit_ss =   (debt_ss * (1 - (1 + r_bar_ss) / (gam_ss * nu_ss)))    
        tc_ss = (subsidy_ss + g_ss - deficit_ss - tk_ss*r_bar_ss*k_ss  - 0.0d0 * tk_ss*r_bar_ss*debt_ss / (gam_ss * nu_ss)     - labor_tax_revenue_ss/bigl_ss - upsilon_ss/(bigl_ss/(sum(N_ss_j))))/consumption_ss_gross
          
             
        else
            
        deficit_ss =   (debt_ss * (1 - (r_ss) / (gam_ss * nu_ss)))       
        tc_ss = (subsidy_ss + g_ss - deficit_ss - tk_ss*(r_bar_ss + depr)*k_ss - labor_tax_revenue_ss/bigl_ss - upsilon_ss/(bigl_ss/(sum(N_ss_j))))/consumption_ss_gross
    
        endif
        
    case(2)             
!       case 2 - debt is residual


        if (switch_tauK_gross == 0) then
        deficit_ss  = subsidy_ss + g_ss - tc_ss *  consumption_ss_gross  - tk_ss*r_bar_ss*k_ss  - 0.0d0 * tk_ss*r_bar_ss*debt_ss / (gam_ss * nu_ss)     - labor_tax_revenue_ss/bigl_ss - upsilon_ss/(bigl_ss/(sum(N_ss_j)))
        debt_ss  =  deficit_ss * (1 - (r_bar_ss) / (gam_ss * nu_ss))**(-1)      
             
        else
        deficit_ss  =  subsidy_ss + g_ss -  tc_ss * consumption_ss_gross - tk_ss*(r_bar_ss + depr)*k_ss - labor_tax_revenue_ss/bigl_ss - upsilon_ss/(bigl_ss/(sum(N_ss_j)))
        debt_ss  =  deficit_ss * (1 - (r_ss) / (gam_ss * nu_ss))**(-1)      
        
        endif     
        
        
  
    
    case(6)
        if (switch_tauK_gross == 0) then
        deficit_ss =   (debt_ss * (1 - (1 + r_bar_ss) / (gam_ss * nu_ss)))    
            g_ss   =  tc_ss * consumption_ss_gross - (subsidy_ss - deficit_ss - tk_ss*r_bar_ss*k_ss  - 0.0d0 * tk_ss*r_bar_ss*debt_ss / (gam_ss * nu_ss)     -labor_tax_revenue_ss/bigl_ss - upsilon_ss/(bigl_ss/(sum(N_ss_j)))) 
            g_per_capita_ss = g_ss*bigl_ss/N_ss       
            g_share_ss = g_ss/y_ss 
        else
            deficit_ss =   (debt_ss * (1 - (r_ss) / (gam_ss * nu_ss)))       
            g_ss =    tc_ss * consumption_ss_gross - (subsidy_ss  - deficit_ss - tk_ss*(r_bar_ss + depr)*k_ss -labor_tax_revenue_ss/bigl_ss - upsilon_ss/(bigl_ss/(sum(N_ss_j)))) 
            g_per_capita_ss = g_ss*bigl_ss/N_ss       
            g_share_ss = g_ss/y_ss 
        endif
    end select