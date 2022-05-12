    write (*,*) 'We are performing base transition path' 

    !include 'switch_setting.f90'
    call clear_globals
    call globals         

    ! this has to be examined
    priv_share = 0.0d0

    

    


! do iter_theta = 0, 10, 1 
! theta = 1.0d0 + real(iter_theta)/100d0
    if (switch_run_1 == 1) then
        call steady(switch_residual_1, switch_tauK_gross, switch_unequal_bequest, switch_param_1, switch_type_1, rho_1,k_ss_1, r_ss_1, r_bar_ss_1, w_bar_ss_1, w_bar_ss_L_1, w_bar_ss_H_1, l_ss_j_H_1, w_ss_j_H_1, s_ss_j_H_1, c_ss_j_H_1, b_ss_j_H_1, l_ss_j_L_1, w_ss_j_L_1, s_ss_j_L_1, c_ss_j_L_1, b_ss_j_L_1,upsilon_r_ss_1, t1_ss_1, g_per_capita_ss_1, b1_ss_j_1, b2_ss_j_1, b1_ss_j_1_L, b2_ss_j_1_L, b1_ss_j_1_H, b2_ss_j_1_H, pillar1_ss_j_1, pillar2_ss_j_1)       
    endif ! run_1
    write(*,*) V_ss_j_vfi(1)
! enddo 
    
    
        ! what is happening here?    
        priv_share = 0.0d0
        t1_ss_new = t1_ss_old
        t1_ss_contrib = t1_ss_new
        t2_ss_new = t2_ss_old
        switch_pension = abs(switch_type_1 - switch_type_2) 
        
    switch_run_1 = 0 ! to be sure that we are running 2nd ss, in pfi procedure we are fullfiling 2nd part of transition
    if (switch_run_2 == 1) then
        call steady(switch_residual_2, switch_tauK_gross, switch_unequal_bequest, switch_param_2, switch_type_2, rho_2,k_ss_2, r_ss_2, r_bar_ss_2, w_bar_ss_2, w_bar_ss_L_2, w_bar_ss_H_2, l_ss_j_H_2, w_ss_j_H_2, s_ss_j_H_2, c_ss_j_H_2, b_ss_j_H_2, l_ss_j_L_2, w_ss_j_L_2, s_ss_j_L_2, c_ss_j_L_2, b_ss_j_L_2,upsilon_r_ss_2, t1_ss_2, g_per_capita_ss_2, b1_ss_j_2, b2_ss_j_2, b1_ss_j_2_L, b2_ss_j_2_L, b1_ss_j_2_H, b2_ss_2_1_H,pillar1_ss_2_1, pillar2_ss_2_1)       
    endif ! run_2
    
    if (switch_run_2 == 1 .AND. switch_run_t == 1) then
       call transition_path_DB(switch_residual_t, switch_tauK_gross, switch_unequal_bequest,switch_param_2, l_db, c_db, tax_c_db, r_db,  V_20_years_old_db, g_per_capita_db)
    endif
    
