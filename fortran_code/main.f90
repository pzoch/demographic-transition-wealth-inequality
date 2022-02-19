program olg2
    use global_vars
    use steady_state
    use partial_eqm_calc
    use global_vars2
    use transition_DB
    use get_data
    use get_data
    use clock 
    !use geompack3
 
    
    implicit none

    ! set paths for inputs and outputs
    call getcwd(cwd)
    cwd_r = trim(cwd)//"/Data"
    cwd_w = trim(cwd)//"/Results"    
    
    
call clear_globals
call globals         ! globals is a subroutine in global_vars2 module                                                                

call tic()
allocate(svplus_trans(bigJ, 0:n_a, 0:n_aime, n_sp, n_sr, n_sd, bigT))
allocate(l_trans, labor_tax_trans, c_trans, RHS_trans, prob_trans, lab_income_trans, lab_income_pretax_trans,  &
         sv_tempo_trans, V_trans, EV_trans, ERHS_trans, aime_plus_trans, source = svplus_trans)


    version = 'base_'

    switch_print = 1


    
      

    !include 'switch_setting.f90'
    call clear_globals
    call globals         

    ! this has to be examined
    priv_share = 0.0d0

    

    

    if (switch_partial_eq == 0) then
      write (*,*) 'We are performing base transition path' 
        if (switch_run_1 == 1) then
            call steady(switch_residual_1, switch_tauK_gross, switch_unequal_bequest, switch_param_1, switch_type_1, rho_1,k_ss_1, r_ss_1, r_bar_ss_1, w_bar_ss_1, l_ss_j_1, w_ss_j_1, s_ss_j_1, c_ss_j_1, b_ss_j_1, upsilon_r_ss_1, t1_ss_1, g_per_capita_ss_1, b1_ss_j_1, b2_ss_j_1, pillar1_ss_j_1, pillar2_ss_j_1,bequest_ss_j_1)       
        endif ! run_1
        write(*,*) V_ss_j_vfi(1) 
    
    
        ! what is happening here?    
        priv_share = 0.0d0
        t1_ss_new = t1_ss_old
        t1_ss_contrib = t1_ss_new
        t2_ss_new = t2_ss_old
        switch_pension = abs(switch_type_1 - switch_type_2) 
        
    switch_run_1 = 0 ! to be sure that we are running 2nd ss, in pfi procedure we are fullfiling 2nd part of transition
    if (switch_run_2 == 1) then
       call steady(switch_residual_2, switch_tauK_gross, switch_unequal_bequest,switch_param_2, switch_type_2, rho_2,  k_ss_2, r_ss_2, r_bar_ss_2, w_bar_ss_2, l_ss_j_2, w_ss_j_2, s_ss_j_2, c_ss_j_2, b_ss_j_2, upsilon_r_ss_2, t1_ss_2, g_per_capita_ss_2, b1_ss_j_2, b2_ss_j_2, pillar1_ss_j_2, pillar2_ss_j_2,bequest_ss_j_2)
    endif ! run_2
    
    if (switch_run_2 == 1 .AND. switch_run_t == 1) then
       call transition_path_DB(switch_residual_t, switch_tauK_gross, switch_unequal_bequest,switch_param_2, l_db, c_db, tax_c_db, r_db,  V_20_years_old_db, g_per_capita_db)
    endif
    
    
    elseif (switch_partial_eq == 1) then
      write (*,*) 'We are doing partial equilibrium exercises'   
   
        if (switch_run_1 == 1) then
            call steady(switch_residual_1, switch_tauK_gross, switch_unequal_bequest, switch_param_1, switch_type_1, rho_1,k_ss_1, r_ss_1, r_bar_ss_1, w_bar_ss_1, l_ss_j_1, w_ss_j_1, s_ss_j_1, c_ss_j_1, b_ss_j_1, upsilon_r_ss_1, t1_ss_1, g_per_capita_ss_1, b1_ss_j_1, b2_ss_j_1, pillar1_ss_j_1, pillar2_ss_j_1,bequest_ss_j_1)       
        endif ! run_1
        write(*,*) V_ss_j_vfi(1)
        
        
        pi_id_hold = pi_id
        n_sd_value_hold = n_sd_value
        pi_ir_hold = pi_ir
        n_sr_value_hold = n_sr_value
        
        pi_id = pi_id_hold
        n_sd_value = n_sd_value_hold
        pi_ir = pi_ir_hold
        n_sr_value = n_sr_value_hold
        pi_id_ret = pi_id_hold
        n_sd_value_ret = n_sd_value_hold
        pi_ir_ret = pi_ir_hold
        n_sr_value_ret = n_sr_value_hold
        
        
        allocate(l_pe_j(bigJ, 8))
        allocate(s_pe_j(bigJ, 8))
        allocate(c_pe_j(bigJ, 8))
        allocate(asset_pe_j(bigJ, 8))
        allocate(lab_income_pe_j(bigJ, 8))
        allocate(gini_weight_pe(bigJ,n_a, 8))
        allocate(l_pe_j_var(bigJ, 8))
        allocate(s_pe_j_var(bigJ, 8))
        allocate(c_pe_j_var(bigJ, 8))
        allocate(asset_pe_j_var(bigJ, 8))
        allocate(lab_income_pe_j_var(bigJ, 8))

        
        i = 1
        
        write (*,*) 'PE exercise number 1'  
        
        ! PE exercise number 1
        ! set discount risk to 0 in all periods
            switch_discount_risk        = 0
            switch_return_risk          = 1
            switch_no_ret_delta_risk    = 0
            switch_no_ret_return_risk   = 0
            switch_longevity_pe         = 1
            switch_popweight_pe         = 1
            switch_taxes_pe             = 1
            call partial_eqm_solve(switch_residual_1, switch_tauK_gross, switch_unequal_bequest, switch_param_1, switch_type_1, rho_1, r_bar_ss_1, w_bar_ss_1, upsilon_r_ss_1, b_ss_j_1, l_pe_j(:,i), w_ss_j_1, s_pe_j(:,i), c_pe_j(:,i), asset_pe_j(:,i),  lab_income_pe_j(:,i), t1_ss_1, b1_ss_j_1, b2_ss_j_1, pillar1_ss_j_1, pillar2_ss_j_1,bequest_ss_j_1,l_pe_j_var(:,i), s_pe_j_var(:,i), c_pe_j_var(:,i), asset_pe_j_var(:,i), lab_income_pe_j_var(:,i), gini_weight_pe(:,:, i) )
        
        write (*,*) 'PE exercise number 2'    
        i = 2
        ! PE exercise number 2
        ! set return risk to 0 in all periods
            switch_discount_risk        = 1
            switch_return_risk          = 0
            switch_no_ret_delta_risk    = 0
            switch_no_ret_return_risk   = 0
            switch_longevity_pe         = 1
            switch_popweight_pe         = 1
            switch_taxes_pe             = 1
            call partial_eqm_solve(switch_residual_1, switch_tauK_gross, switch_unequal_bequest, switch_param_1, switch_type_1, rho_1, r_bar_ss_1, w_bar_ss_1, upsilon_r_ss_1, b_ss_j_1, l_pe_j(:,i), w_ss_j_1, s_pe_j(:,i), c_pe_j(:,i), asset_pe_j(:,i),  lab_income_pe_j(:,i), t1_ss_1, b1_ss_j_1, b2_ss_j_1, pillar1_ss_j_1, pillar2_ss_j_1,bequest_ss_j_1,l_pe_j_var(:,i), s_pe_j_var(:,i), c_pe_j_var(:,i), asset_pe_j_var(:,i), lab_income_pe_j_var(:,i), gini_weight_pe(:,:, i)  )       
        write (*,*) 'PE exercise number 3' 
        i = 3
        ! PE exercise number 3
        ! no discount risk after retirement (everyone has 0 shock)
            switch_discount_risk        = 1
            switch_return_risk          = 1
            switch_no_ret_delta_risk    = 1
            switch_no_ret_return_risk   = 0
            switch_longevity_pe         = 1
            switch_popweight_pe         = 1
            switch_taxes_pe             = 1           
            call partial_eqm_solve(switch_residual_1, switch_tauK_gross, switch_unequal_bequest, switch_param_1, switch_type_1, rho_1, r_bar_ss_1, w_bar_ss_1, upsilon_r_ss_1, b_ss_j_1, l_pe_j(:,i), w_ss_j_1, s_pe_j(:,i), c_pe_j(:,i), asset_pe_j(:,i),  lab_income_pe_j(:,i), t1_ss_1, b1_ss_j_1, b2_ss_j_1, pillar1_ss_j_1, pillar2_ss_j_1,bequest_ss_j_1,l_pe_j_var(:,i), s_pe_j_var(:,i), c_pe_j_var(:,i), asset_pe_j_var(:,i), lab_income_pe_j_var(:,i), gini_weight_pe(:,:, i)  )        
        write (*,*) 'PE exercise number 4'     
        i = 4
        ! PE exercise number 4
        ! no discount risk after retirement (everyone has jbar shock)
            switch_discount_risk        = 1
            switch_return_risk          = 1
            switch_no_ret_delta_risk    = 2
            switch_no_ret_return_risk   = 0
            switch_longevity_pe         = 1
            switch_popweight_pe         = 1
            switch_taxes_pe             = 1
            call partial_eqm_solve(switch_residual_1, switch_tauK_gross, switch_unequal_bequest, switch_param_1, switch_type_1, rho_1, r_bar_ss_1, w_bar_ss_1, upsilon_r_ss_1, b_ss_j_1, l_pe_j(:,i), w_ss_j_1, s_pe_j(:,i), c_pe_j(:,i), asset_pe_j(:,i),  lab_income_pe_j(:,i), t1_ss_1, b1_ss_j_1, b2_ss_j_1, pillar1_ss_j_1, pillar2_ss_j_1,bequest_ss_j_1,l_pe_j_var(:,i), s_pe_j_var(:,i), c_pe_j_var(:,i), asset_pe_j_var(:,i), lab_income_pe_j_var(:,i), gini_weight_pe(:,:, i)  )        
        write (*,*) 'PE exercise number 5'      
        i = 5
        ! PE exercise number 5
        ! no return risk after retirement (everyone has jbar shock)
            switch_discount_risk        = 1
            switch_return_risk          = 1
            switch_no_ret_delta_risk    = 0
            switch_no_ret_return_risk   = 1
            switch_longevity_pe         = 1
            switch_popweight_pe         = 1
            switch_taxes_pe             = 1
            call partial_eqm_solve(switch_residual_1, switch_tauK_gross, switch_unequal_bequest, switch_param_1, switch_type_1, rho_1, r_bar_ss_1, w_bar_ss_1, upsilon_r_ss_1, b_ss_j_1, l_pe_j(:,i), w_ss_j_1, s_pe_j(:,i), c_pe_j(:,i), asset_pe_j(:,i),  lab_income_pe_j(:,i), t1_ss_1, b1_ss_j_1, b2_ss_j_1, pillar1_ss_j_1, pillar2_ss_j_1,bequest_ss_j_1,l_pe_j_var(:,i), s_pe_j_var(:,i), c_pe_j_var(:,i), asset_pe_j_var(:,i), lab_income_pe_j_var(:,i), gini_weight_pe(:,:, i)  )        
        write (*,*) 'PE exercise number 6'       
        i = 6
        ! PE exercise number 6
        ! baseline
            switch_discount_risk        = 1
            switch_return_risk          = 1
            switch_no_ret_delta_risk    = 0
            switch_no_ret_return_risk   = 0
            switch_longevity_pe         = 1
            switch_popweight_pe         = 1
            switch_taxes_pe             = 1
            call partial_eqm_solve(switch_residual_1, switch_tauK_gross, switch_unequal_bequest, switch_param_1, switch_type_1, rho_1, r_bar_ss_1, w_bar_ss_1, upsilon_r_ss_1, b_ss_j_1, l_pe_j(:,i), w_ss_j_1, s_pe_j(:,i), c_pe_j(:,i), asset_pe_j(:,i),  lab_income_pe_j(:,i), t1_ss_1, b1_ss_j_1, b2_ss_j_1, pillar1_ss_j_1, pillar2_ss_j_1,bequest_ss_j_1,l_pe_j_var(:,i), s_pe_j_var(:,i), c_pe_j_var(:,i), asset_pe_j_var(:,i), lab_income_pe_j_var(:,i), gini_weight_pe(:,:, i)  )        
         write (*,*) 'PE exercise number 7' 
        i = 7
 
        ! PE exercise number 6
        ! longevity as in the 2nd ss
            switch_discount_risk        = 1
            switch_return_risk          = 1
            switch_no_ret_delta_risk    = 0
            switch_no_ret_return_risk   = 0
            switch_longevity_pe         = 2
            switch_popweight_pe         = 1
            switch_taxes_pe             = 1
            call partial_eqm_solve(switch_residual_1, switch_tauK_gross, switch_unequal_bequest, switch_param_1, switch_type_1, rho_1, r_bar_ss_1, w_bar_ss_1, upsilon_r_ss_1, b_ss_j_1, l_pe_j(:,i), w_ss_j_1, s_pe_j(:,i), c_pe_j(:,i), asset_pe_j(:,i),  lab_income_pe_j(:,i), t1_ss_1, b1_ss_j_1, b2_ss_j_1, pillar1_ss_j_1, pillar2_ss_j_1,bequest_ss_j_1,l_pe_j_var(:,i), s_pe_j_var(:,i), c_pe_j_var(:,i), asset_pe_j_var(:,i), lab_income_pe_j_var(:,i), gini_weight_pe(:,:, i)  )         
        write (*,*) 'PE exercise number 8'  
        i = 8

        ! PE exercise number 8
        ! taxes as in the 2nd ss
            switch_discount_risk        = 1
            switch_return_risk          = 1
            switch_no_ret_delta_risk    = 0
            switch_no_ret_return_risk   = 0
            switch_longevity_pe         = 1
            switch_popweight_pe         = 1
            switch_taxes_pe             = 2
            
            call partial_eqm_solve(switch_residual_1, switch_tauK_gross, switch_unequal_bequest, switch_param_1, switch_type_1, rho_1, r_bar_ss_1, w_bar_ss_1, upsilon_r_ss_1, b_ss_j_1, l_pe_j(:,i), w_ss_j_1, s_pe_j(:,i), c_pe_j(:,i), asset_pe_j(:,i),  lab_income_pe_j(:,i), t1_ss_1, b1_ss_j_1, b2_ss_j_1, pillar1_ss_j_1, pillar2_ss_j_1,bequest_ss_j_1,l_pe_j_var(:,i), s_pe_j_var(:,i), c_pe_j_var(:,i), asset_pe_j_var(:,i), lab_income_pe_j_var(:,i), gini_weight_sv(:,:, i)  )            
            
            ! allocate
     
      ! save output 
            open(unit = 108, FILE = version//"partial_eqm_results.csv")
        write(108, '(A)') "exercise;age;c;l;s;a;labinc;c_var;l_var;s_var;a_var;labinc_var;"
            do i = 1, 8, 1
                 do j = 1, bigJ, 1
                 write(108, '(I5,A,I5,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10)') &
                                i, ";", & !exercise number
                                j , ";",  & !age
                                c_pe_j(j,i), ";", & !consumption
                                l_pe_j(j,i), ";", & !hours
                                s_pe_j(j,i), ";", & !saving
                                asset_pe_j(j,i), ";", & !assets
                                lab_income_pe_j(j,i), ";", & !assets
                                c_pe_j_var(j,i), ";", & !assets
                                l_pe_j_var(j,i), ";", & !assets
                                s_pe_j_var(j,i), ";", & !assets
                                asset_pe_j_var(j,i), ";", & !assets
                                lab_income_pe_j_var(j,i) !labor income
            
                enddo
            enddo
            
            
    endif
      
        

    
    

     write (*,*) 'computations completed' 

call toc()
!deallocate(svplus_trans)
deallocate(svplus_trans, l_trans, labor_tax_trans, c_trans, RHS_trans, lab_income_trans, lab_income_pretax_trans,  &
           sv_tempo_trans, V_trans, EV_trans, ERHS_trans, prob_trans, aime_plus_trans)


read*
endprogram olg2