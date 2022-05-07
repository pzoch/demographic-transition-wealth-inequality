program olg2
    use global_vars
    use steady_state
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
allocate(l_trans, labor_tax_trans, c_trans, RHS_trans, prob_trans, lab_income_trans, tot_income_trans, tot_income_pretax_trans, lab_income_pretax_trans, bequest_j_trans,  &
         sv_tempo_trans, V_trans, EV_trans, ERHS_trans, aime_plus_trans, source = svplus_trans)


    version = 'base_'

    switch_print = 1



        include 'main_base_transition.f90'
     write (*,*) 'computations completed' 

call toc()
!deallocate(svplus_trans)
deallocate(svplus_trans, l_trans, labor_tax_trans, c_trans, RHS_trans,  tot_income_trans, tot_income_pretax_trans, lab_income_trans, lab_income_pretax_trans,  &
           sv_tempo_trans, V_trans, EV_trans, ERHS_trans, prob_trans, aime_plus_trans, bequest_j_trans)


read*
endprogram olg2