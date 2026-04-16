    call globals

    call clear_globals


    variant    = 'steadys_old_'
    if (switch_run_1 == 1) then
        write (*,*) ''
        write (*,*) '========================================'
        write (*,*) 'Computing INITIAL steady state...'
        write (*,*) '========================================'
        call steady(switch_tauK_gross, switch_unequal_bequest, 0, switch_type_1, &
            k_ss_1, r_ss_1, r_bar_ss_1, w_bar_ss_1, l_ss_j_1, w_ss_j_1, s_ss_j_1, c_ss_j_1, b_ss_j_1, &
            t1_ss_1, g_per_capita_ss_1, b1_ss_j_1, b2_ss_j_1, pillar1_ss_j_1, pillar2_ss_j_1, &
            bequest_ss_j_1, bequest_ss_1, lab_ss_j_1, &
            r_low_ss_1, asset_income_ss_j_1, asset_base_ss_j_1)
    endif ! run_1


    switch_run_1 = 0 ! to be sure that we are running 2nd ss, in pfi procedure we are fulfilling 2nd part of transition

    if (switch_run_2 == 1) then
        variant    = 'steadys_new_'
        write (*,*) ''
        write (*,*) '========================================'
        write (*,*) 'Computing FINAL steady state...'
        write (*,*) '========================================'
        call steady(switch_tauK_gross, switch_unequal_bequest, 1, switch_type_2, &
            k_ss_2, r_ss_2, r_bar_ss_2, w_bar_ss_2, l_ss_j_2, w_ss_j_2, s_ss_j_2, c_ss_j_2, b_ss_j_2, &
            t1_ss_2, g_per_capita_ss_2, b1_ss_j_2, b2_ss_j_2, pillar1_ss_j_2, pillar2_ss_j_2, &
            bequest_ss_j_2, bequest_ss_2, lab_ss_j_2, &
            r_low_ss_2, asset_income_ss_j_2, asset_base_ss_j_2)
    endif ! run_2

    if (switch_run_2 == 1 .and. switch_run_t == 1) then
       write (*,*) ''
       write (*,*) '========================================'
       write (*,*) 'Computing TRANSITION path...'
       write (*,*) '========================================'
       call transition_path_db(switch_tauk_gross, switch_unequal_bequest, l_db, c_db, s_db, tax_c_db, r_db, g_per_capita_db, lab_db)
    endif

