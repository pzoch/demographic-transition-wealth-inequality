
    
    OPEN (unit=666, FILE = version//experiment//closure//"information.txt")
    
    
        write(666, '(A)') '******* INFORMATION *******'
        write(666, '(A)')
        write(666, '(A)') '*********************************'
        write(666, '(A)') 'THIS CODE WAS INITIALIZED WITH THE FOLLOWING SWITCHES' 
        write(666, '(A)')
        write(666,'(A30,I5.1)') 'switch_mortality =',  switch_mortality          
        write(666,'(A30,I5.1)') 'switch_go_to_lower_gamma =',  switch_go_to_lower_gamma 
        write(666,'(A30,I5.1)') 'switch_change_tauL =', switch_change_tauL
        write(666,'(A30,I5.1)') 'switch_change_lambda =', switch_change_lambda            
        write(666,'(A30,I5.1)') 'switch_change_tauK =',    switch_change_tauK        
        write(666,'(A30,I5.1)') 'switch_steady_demo =',    switch_steady_demo
        write(666,'(A30,I5.1)') 'switch_sigma2_epsilon_t =', switch_sigma2_epsilon_t       
        write(666,'(A30,I5.1)') 'switch_change_premium =',  switch_change_premium    
        write(666,'(A30,I5.1)') 'switch_change_type_share =', switch_change_type_share
        write(666,'(A30,I5.1)') 'switch_change_sl =', switch_change_sl
        write(666,'(A30,I5.1)') 'switch_keep_fixed =', switch_keep_fixed
        write(666,'(A30,I5.1)') 'switch_labor_choice =', switch_labor_choice
        write(666,'(A30,I5.1)') 'switch_cohort_ps =',  switch_cohort_ps        
        write(666,'(A30,I5.1)') 'switch_fix_labor =', switch_fix_labor
        write(666,'(A30,I5.1)') 'switch_tauK_gross =',  switch_tauK_gross          
        write(666,'(A30,I5.1)') 'switch_unequal_bequest =', switch_unequal_bequest          
        write(666,'(A30,I5.1)') 'switch_reduce_pension =', switch_reduce_pension  
        write(666,'(A30,I5.1)') 'switch_persistent_delta =',switch_persistent_delta  
        write(666,'(A30,I5.1)') 'switch_epsilon_corr =',    switch_epsilon_corr            
        write(666,'(A30,I5.1)') 'switch_income_risk =', switch_income_risk
        write(666,'(A30,I5.1)') 'switch_discount_risk =', switch_discount_risk
        write(666,'(A30,I5.1)') 'switch_return_risk =', switch_return_risk
        write(666,'(A30,I5.1)') 'switch_initial_dispersion =', switch_initial_dispersion
        write(666,'(A30,I5.1)') 'switch_run_1 =', switch_run_1
        write(666,'(A30,I5.1)') 'switch_run_2 =', switch_run_2
        write(666,'(A30,I5.1)') 'switch_run_t =', switch_run_t
        write(666,'(A30,I5.1)') 'switch_param_1 =', switch_param_1
        write(666,'(A30,I5.1)') 'switch_param_2 =', switch_param_2
        write(666,'(A30,I5.1)') 'switch_ss_write =', switch_ss_write
        write(666,'(A30,I5.1)') 'switch_profile =', switch_profile
        write(666,'(A30,I5.1)') 'beq_age =', beq_age
        write(666, '(A)') '*********************************'
        write(666, '(A)') 'GRIDS ARE INITIALIZED AS' 
        write(666, '(A)') 
        write(666,'(A30,I5.3)') 'Assets grid points =', n_a
        write(666,'(A30,I5.3)') 'AIME grid points =', n_aime
        write(666,'(A30,I5.3)') 'Income grid points =', n_sp
        write(666,'(A30,I5.3)') 'Delta grid points =', n_sd
        write(666,'(A30,I5.3)') 'Return grid points =', n_sr
        write(666, '(A)') '*********************************'
        write(666, '(A)') 'THIS CODE WAS INITIALIZED WITH THE FOLLOWING PARAMETERS' 
        write(666, '(A)') 
         write(666,'(A30,F9.5 )') 'err_tol =',  err_tol  
         write(666,'(A30,F9.5 )') 'err_ss_tol =',     err_ss_tol  
         write(666,'(A30,F9.5 )') 'up_ss =',     up_ss  
         write(666,'(A30,F9.5 )') 'up_t =',     up_t  
         write(666,'(A30,F9.5 )') 'valor_share =',     valor_share  
         write(666,'(A30,F9.5 )') 'up_tc =',     up_tc  
         write(666,'(A30,F9.5 )') 'g_share_ss =',     g_share_ss / gy_factor_t(1)
         write(666,'(A30,F9.5 )') 'superstar_factor_1 =',     superstar_factor_1  
         write(666,'(A30,F9.5 )') 'superstar_factor_2 =',     superstar_factor_2  
         write(666,'(A30,F9.5 )') 'alpha =',     alpha  
         write(666,'(A30,F9.5 )') 'theta =',     theta          
         write(666,'(A30,F9.5 )') 'err_tol =',     err_tol  
         write(666,'(A30,F9.5 )') 'beta =',     beta  
         write(666,'(A30,F9.5 )') 'frisch =',     frisch  
         write(666,'(A30,F9.5 )') 'depr =',     depr  
         write(666,'(A30,F9.5 )') 'rho_subst =',     rho_subst  
         write(666,'(A30,F9.5 )') 'delta =',     delta  
         write(666,'(A30,F9.5 )') 'phi =',     phi  
         write(666,'(A30,F9.5 )') 'rho_1 =',     rho_1  
         write(666,'(A30,F9.5 )') 'rho_2 =',     rho_2  
         write(666,'(A30,F9.5 )') 't1_ss_old =',     t1_ss_old  
         write(666,'(A30,F9.5 )') 't1_ss_new =',     t1_ss_new  
         write(666,'(A30,F9.5 )') 't2_ss_old =',     t2_ss_old  
         write(666,'(A30,F9.5 )') 't2_ss_new =',     t2_ss_new  
         write(666,'(A30,F9.5 )') 'delta_half_width =',     delta_half_width  
         write(666, '(A)') 'NOTE: ' 
         write(666, '(A)') 'THIS DOES NOT MEAN IT RUNS WITH THESE PARAMETERS ' 
         write(666, '(A)') 'THEY WERE POSSIBLY MODIFIED LATER ' 
         write(666, '(A)') 'SEE OTHER TXT FILES ' 
         CLOSE(666)