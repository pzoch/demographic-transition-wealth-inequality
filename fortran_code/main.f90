program olg2
    use global_vars
    use steady_state
    use prof_steady
    use global_vars2
    use transition_DB
    use get_data
    use get_data
    use clock 
    !use geompack3
 
    
    implicit none

    ! set paths for inputs and outputs
    call getcwd(cwd)
    cwd_i = trim(cwd)//"/Instructions"
    cwd_r = trim(cwd)//"/Data"
    cwd_w = trim(cwd)//"/Results"    
    cwd_p = trim(cwd)//"/Parameters"
    
call clear_globals
call globals         ! globals is a subroutine in global_vars2 module                                                                

call tic()
allocate(svplus_trans(bigJ, 0:n_a, 0:n_aime, n_sp, n_sr, n_sd, bigT))
allocate(svplus_trans_big(bigJ, 0:n_a, 0:n_aime, n_sp, n_sr, n_sd, bigM, bigT))
allocate(l_trans, labor_tax_trans, c_trans, RHS_trans, prob_trans, lab_income_trans, tot_income_trans, tot_income_pretax_trans, lab_income_pretax_trans, bequest_j_trans,  &
         sv_tempo_trans, V_trans, EV_trans, ERHS_trans, aime_plus_trans, source = svplus_trans)
allocate(l_trans_big, labor_tax_trans_big, c_trans_big, RHS_trans_big, prob_trans_big, lab_income_trans_big, tot_income_trans_big, tot_income_pretax_trans_big, lab_income_pretax_trans_big, bequest_j_trans_big,  &
         sv_tempo_trans_big, V_trans_big, EV_trans_big, ERHS_trans_big, aime_plus_trans_big, source = svplus_trans_big)
    sv_tempo_trans = 0.0d0


    switch_print = 1



        include 'main_base_transition.f90'
     write (*,*) 'computations completed' 

call toc()
!deallocate(svplus_trans)
deallocate(svplus_trans, l_trans, labor_tax_trans, c_trans, RHS_trans,  tot_income_trans, tot_income_pretax_trans, lab_income_trans, lab_income_pretax_trans,  &
           sv_tempo_trans, V_trans, EV_trans, ERHS_trans, prob_trans, aime_plus_trans, bequest_j_trans)


read*
endprogram olg2