    call clear_globals
    call globals         
    
    ! to do to do 
    !read(*,*) theta
    theta = 2d0
    
    ! values to calibrate 
    tL_ss = 0.09d0 ! marked to data, includes excise, with ref. to PIT share in labour income in NA data
    tk_ss = 0.28d0   
    tc_ss = 0.044d0 ! marked to data, includes excise, with ref. to individual consumption      
            depr = (1.0d0 + 0.047d0)**zbar - 1.0d0 
            delta =  1.0150d0**(zbar)   !(0.9862_dp)
            phi = 0.39d0
            rho_1 = 0.85d0 !0.225_dp!*0.0d0
        
    best_table(1)  = tl_ss
    best_table(2)  = tk_ss
    best_table(3)  = tc_ss
    best_table(4)  = delta
    best_table(5)  = phi
    best_table(6)  = rho_1
    
    
    calib_iter = 0
    ! bisection to match pension system size 
    open(unit = 1111, file= "errors_from_simul.csv")
    write(1111, '(A)') "calib_iter ; error_labor; error_pen_sys ; error_tl; error_tc; error_tk; error_delta; varphi_u;varphi_l;varphi ;rho_u;rho_l; rho_1;tl_u; tl_l ;tl_ss ;tc_u; tc_l; tc_ss ;tk_u;tk_l; tk_ss ;delta_u;delta_l;delta;depr_u;depr_l;depr"
    error_max  = 1d0
    error_tot_min = 100 
    do while ((calib_iter <30) .AND. (error_max>0.005d0))
        
        ! tetermine if initial values are ok
            call steady(switch_residual_1, switch_param_1, switch_type_1, rho_1, k_ss_1, r_ss_1, r_bar_ss_1, w_bar_ss_1, l_ss_j_1, w_ss_j_1, s_ss_j_1, c_ss_j_1, b_ss_j_1, upsilon_r_ss_1, t1_ss_1, g_per_capita_ss_1, b1_ss_j_1, b2_ss_j_1, pillar1_ss_j_1, pillar2_ss_j_1) 
            !
                        write(1111, '(I2,24(A,F20.10))') calib_iter &
            , ";", error_labor, ";", error_pen_sys , ";", error_tl, ";", error_tc, ";", error_tk, ";", error_delta&
            , ";", phi_u, ";", phi_l, ";", phi &
            , ";", rho_u, ";", rho_l, ";", rho_1 &
            , ";",tl_u, ";", tl_l , ";", tl_ss &
            , ";",tc_u, ";", tc_l, ";", tc_ss  &
            , ";",tk_u, ";", tk_l, ";", tk_ss &
            , ";",delta_u, ";",delta_l, ";",delta
                        
            error_table(1)  = abs(error_tl) !TODO TODO
            error_table(2)  = abs(error_tk)
            error_table(3)  = abs(error_tc) 
            error_table(4)  = abs(error_delta)
            error_table(5)  = abs(error_labor)
            error_table(6)  = abs(error_pen_sys)
      
            ! tables of errors 
            
           if (sum(error_table)< error_tot_min) then 
                best_table(1)  = tl_ss
                best_table(2)  = tk_ss
                best_table(3)  = tc_ss
                best_table(4)  = delta
                best_table(5)  = phi
                best_table(6)  = rho_1
            
                
                error_tot_min = sum(error_table)
            endif 
    
            
            which_correct = maxloc(abs(error_table),1)
            error_max = maxval(abs(error_table),1) 
            if (error_max>0.005d0) then
            select case (which_correct)             
            case(1)
                if (error_tl>0) then 
                  tl_u = tL_ss
                else
                 tl_l = tL_ss
                endif   
                
                tL_ss = (tl_l+tl_u)/2d0
                
                !if (abs(error_tl)>100*abs(tl_u - tl_l)) then
                !    if (error_tl>0) then 
                !        tl_u = tL_ss+0.01
                !    else
                !        tl_l = tL_ss-0.01
                !     endif
                !endif
    
            case(2)
                if (error_tk>0 ) then
                   tk_u = tk_ss
                else
                   tk_l = tk_ss
                endif
                tk_ss = (tk_u+tk_l)/2d0
                
                !if (abs(error_tk)>100*abs(tk_u - tk_l)) then
                !    if (error_tl>0) then 
                !        tk_u = tk_ss+0.01
                !    else
                !        tk_l = tk_ss-0.01
                !     endif
                !endif
    
           case(3)
                if (error_tc>0) then 
                  tc_u = tc_ss
                else
                 tc_l = tc_ss
                endif               
                tc_ss = (tc_l+tc_u)/2d0
                       
            case(4)
                if (error_delta >0 ) then
                   delta_u = delta
                else
                   delta_l = delta
                endif
                delta = (delta_u+delta_l)/2d0
                
        case(5)
                if (error_labor>0) then 
                  phi_u = phi
                else
                    phi_l = phi
                endif               
                phi = (phi_l+phi_u)/2d0
                       
            case(6)
                if (error_pen_sys>0 ) then
                   rho_u = rho_1
                else
                   rho_l = rho_1
                endif
                rho_1= (rho_u+rho_l)/2d0
                
    
                
            endselect
            
    
            endif
            calib_iter = calib_iter+1 
    enddo  
    
     tl_ss = best_table(1) 
     tk_ss = best_table(2)  
     tc_ss = best_table(3)  
     delta = best_table(4)  
     phi   = best_table(5) 
     rho_1 = best_table(6)  
    rho_2 = rho_1

    
    call steady(switch_residual_1, switch_param_1, switch_type_1, rho_1, k_ss_1, r_ss_1, r_bar_ss_1, w_bar_ss_1, l_ss_j_1, w_ss_j_1, s_ss_j_1, c_ss_j_1, b_ss_j_1, upsilon_r_ss_1, t1_ss_1, g_per_capita_ss_1, b1_ss_j_1, b2_ss_j_1, pillar1_ss_j_1, pillar2_ss_j_1) 
    
    close(1111)
    
    ! HERE we run 2nd and 3 stady state 
    switch_run_1 = 0 ! otherwise we would rewrite value at period 1 in vf tables 
    call steady(switch_residual_2, switch_param_2, switch_type_1, rho_2, k_ss_2, r_ss_2, r_bar_ss_2, w_bar_ss_2, &
               l_ss_j_2, w_ss_j_2, s_ss_j_2, c_ss_j_2, b_ss_j_2, upsilon_r_ss_2, t1_ss_2, g_per_capita_ss_2,&
               b1_ss_j_2, b2_ss_j_2, pillar1_ss_j_2, pillar2_ss_j_2)

    
    write(*,*) '****************************************'
   
        write(*,*) closure,' - steady new DC '
        switch_ref_run_now = 1
        !define policy shape
        version = 'ref__'
        switch_type_2 = 1
        t1_ss_new = (1d0-0.5d0)*t1_ss_old
        t1_ss_contrib = t1_ss_new
        t2_ss_new = 0.5d0*t1_ss_old
        switch_pension = abs(switch_type_1 - switch_type_2) 

        k_ss_2 = 0
        r_ss_2 = 0
        r_bar_ss_2 = 0 
        w_bar_ss_2 = 0
        l_ss_j_2 = 0
        w_ss_j_2 = 0
        s_ss_j_2 = 0
        c_ss_j_2 = 0
        b_ss_j_2 = 0
        upsilon_r_ss_2 = 0
        switch_run_1 = 0 ! otherwise we would rewrite value at period 1 in vf tables 

            
       call steady(switch_residual_2, switch_param_2, switch_type_2, rho_2, k_ss_2, r_ss_2, r_bar_ss_2, w_bar_ss_2, &
                   l_ss_j_2, w_ss_j_2, s_ss_j_2, c_ss_j_2, b_ss_j_2, upsilon_r_ss_2, t1_ss_2, g_per_capita_ss_2, &
                   b1_ss_j_2, b2_ss_j_2, pillar1_ss_j_2, pillar2_ss_j_2)
    
    
    
