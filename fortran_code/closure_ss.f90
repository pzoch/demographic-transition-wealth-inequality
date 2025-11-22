    labor_tax_revenue_ss = 0.0d0
    do j = 1,bigJ,1
    do m = 1,bigM,1
       labor_tax_revenue_ss = labor_tax_revenue_ss +  N_big_ss_j(j,m)*labor_tax_ss_j(j,m)
    enddo
    enddo
    

    ! Case 6 - g is residual (hardcoded)
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