!===============================================================================
! FILE: main.f90
!
! DESCRIPTION:
!   Main entry point (program olg2). Sets up paths, loads parameters and data,
!   allocates transition arrays, then includes main_base_transition.f90 for
!   steady-state and transition-path computation.
!
! USAGE: 5Gtrans.exe <version> <experiment> <closure>
!   e.g.: 5Gtrans.exe psid_ all_ govt__
!===============================================================================

program olg2
    use global_vars
    use steady_state
    use global_vars2
    use transition_DB
    use get_data
    use clock
 
    
    implicit none
    integer :: num_args
    character(len=256) :: arg_buffer

    ! set paths for inputs and outputs
    call getcwd(cwd)
    cwd_i = trim(cwd)//"/Instructions"
    cwd_r = trim(cwd)//"/Data"
    cwd_w = trim(cwd)//"/Results"
    cwd_p = trim(cwd)//"/Parameters"

    ! Read scenario from command line or use defaults
    num_args = command_argument_count()

    if (num_args >= 3) then
        ! Read version, experiment, closure from command line
        call get_command_argument(1, arg_buffer)
        version = trim(arg_buffer)
        call get_command_argument(2, arg_buffer)
        experiment = trim(arg_buffer)
        call get_command_argument(3, arg_buffer)
        closure = trim(arg_buffer)
    else
        ! Use default scenario
        version = 'psid_'
        experiment = 'all_'
        closure = 'govt__'
        print *, "No command-line arguments. Using default scenario."
        print *, "Usage: 5Gtrans.exe <version> <experiment> <closure>"
    endif

    ! Display scenario name prominently
    print *, ""
    print *, "============================================================"
    print *, "  SCENARIO: ", trim(version)//trim(experiment)//trim(closure)
    print *, "============================================================"
    print *, ""

    ! Validate that required configuration files exist
    call validate_config_files(cwd_i, cwd_p, version, experiment, closure)

    ! Construct scenario output folder path and create it
    cwd_scenario = trim(cwd_w)//'/'//trim(version)//trim(experiment)//trim(closure)

    ! Create directory (Windows-style mkdir works on Windows, will fail silently with 2>nul on error)
    call system('mkdir "'//trim(cwd_scenario)//'" 2>nul')

    ! Remove files produced by obsolete output routines so an in-place rerun
    ! cannot leave legacy artifacts beside the current scenario outputs.
    call delete_if_exists(trim(cwd_scenario)//'/b_j_trans.csv')
    call delete_if_exists(trim(cwd_scenario)//'/c_j_trans.csv')
    call delete_if_exists(trim(cwd_scenario)//'/fort.30')
    call delete_if_exists(trim(cwd_scenario)//'/l_j_trans.csv')
    call delete_if_exists(trim(cwd_scenario)//'/mass_trans_beq.csv')
    call delete_if_exists(trim(cwd_scenario)//'/sv_j_trans.csv')
    call delete_if_exists(trim(cwd_scenario)//'/u_j_trans.csv')

    ! Copy instructions and parameters files to results folder for reproducibility
    call system('copy "'//trim(cwd_i)//'/'//trim(version)//trim(experiment)//trim(closure)//'instructions.txt" "'//trim(cwd_scenario)//'/" >nul 2>&1')
    call system('copy "'//trim(cwd_p)//'/'//trim(version)//trim(experiment)//trim(closure)//'parameters.txt" "'//trim(cwd_scenario)//'/" >nul 2>&1')

    call globals         ! globals is a subroutine in global_vars2 module
    call clear_globals
                                                   

call tic()
allocate(svplus_trans(bigJ, 0:n_a, 0:n_aime, n_sp, n_sr, n_sd, bigT))
allocate(svplus_trans_big(bigJ, 0:n_a, 0:n_aime, n_sp, n_sr, n_sd, bigM, bigT))
allocate(svplus_beq_trans(n_beq, 0:n_a, 0:n_aime, n_sp, n_sr, n_sd, bigT))
allocate(svplus_beq_trans_big(n_beq, 0:n_a, 0:n_aime, n_sp, n_sr, n_sd, bigM, bigT))

allocate(l_trans, labor_tax_trans, c_trans, RHS_trans, prob_trans, lab_income_trans, tot_income_trans, tot_income_pretax_trans, lab_income_pretax_trans, bequest_j_trans,  &
         sv_tempo_trans, V_trans, EV_trans, aime_plus_trans, source = svplus_trans)
allocate(asset_income_trans, asset_base_trans, source = svplus_trans)

allocate(l_beq_trans, labor_tax_beq_trans, c_beq_trans, RHS_beq_trans, prob_beq_trans, lab_income_beq_trans, tot_income_beq_trans, tot_income_pretax_beq_trans, lab_income_pretax_beq_trans,  &
         sv_tempo_beq_trans, V_beq_trans, V_after_beq_trans, EV_beq_trans, EV_after_beq_trans, ERHS_beq_trans, aime_plus_beq_trans, RHS_after_beq_trans, source = svplus_beq_trans)
allocate(asset_income_beq_trans, asset_base_beq_trans, source = svplus_beq_trans)

allocate(l_trans_big, lab_trans_big,labor_tax_trans_big, c_trans_big, RHS_trans_big, prob_trans_big, lab_income_trans_big, tot_income_trans_big, tot_income_pretax_trans_big, lab_income_pretax_trans_big, bequest_j_trans_big,  &
         sv_tempo_trans_big, V_trans_big, EV_trans_big, aime_plus_trans_big, source = svplus_trans_big)
allocate(asset_income_trans_big, asset_base_trans_big, source = svplus_trans_big)

allocate(l_beq_trans_big, lab_beq_trans_big,labor_tax_beq_trans_big, c_beq_trans_big, RHS_beq_trans_big, lab_income_beq_trans_big, tot_income_beq_trans_big, tot_income_pretax_beq_trans_big, lab_income_pretax_beq_trans_big,  &
         sv_tempo_beq_trans_big, V_beq_trans_big, V_after_beq_trans_big, EV_beq_trans_big, EV_after_beq_trans_big, ERHS_beq_trans_big, aime_plus_beq_trans_big, source = svplus_beq_trans_big)
allocate(asset_income_beq_trans_big, asset_base_beq_trans_big, source = svplus_beq_trans_big)
    sv_tempo_trans = 0.0d0


    switch_print = 1

        include 'main_base_transition.f90'
     write (*,*) 'computations completed'

call toc()
!deallocate(svplus_trans)
deallocate(asset_income_trans, asset_base_trans, asset_income_trans_big, asset_base_trans_big)
deallocate(asset_income_beq_trans, asset_base_beq_trans, asset_income_beq_trans_big, asset_base_beq_trans_big)
deallocate(svplus_trans, l_trans, labor_tax_trans, c_trans, RHS_trans,  tot_income_trans, tot_income_pretax_trans, lab_income_trans, lab_income_pretax_trans,  &
           sv_tempo_trans, V_trans, EV_trans, prob_trans, aime_plus_trans, bequest_j_trans)


! read*  ! Commented out to allow batch processing without user input


contains

subroutine delete_if_exists(file_path)
    implicit none

    character(len=*), intent(in) :: file_path
    integer :: delete_unit, ios
    logical :: file_exists

    inquire(file=trim(file_path), exist=file_exists)
    if (.not. file_exists) return

    open(newunit=delete_unit, file=trim(file_path), status='old', action='readwrite', iostat=ios)
    if (ios == 0) then
        close(delete_unit, status='delete')
    else
        print *, 'WARNING: Could not remove obsolete output: ', trim(file_path)
    endif
end subroutine delete_if_exists

!===============================================================================
! SUBROUTINE: validate_config_files
!
! Validates that required configuration files exist and have correct format
!===============================================================================
subroutine validate_config_files(cwd_i, cwd_p, version, experiment, closure)
    implicit none

    character(len=*), intent(in) :: cwd_i, cwd_p, version, experiment, closure
    character(len=512) :: instructions_file, parameters_file
    logical :: file_exists
    integer :: ios, line_num, switch_val, unit_test

    ! Construct file paths
    instructions_file = trim(cwd_i)//'/'//trim(version)//trim(experiment)//trim(closure)//'instructions.txt'
    parameters_file = trim(cwd_p)//'/'//trim(version)//trim(experiment)//trim(closure)//'parameters.txt'

    ! Check instructions file exists
    inquire(file=trim(instructions_file), exist=file_exists)
    if (.not. file_exists) then
        print *, ''
        print *, '=========================================='
        print *, 'FATAL ERROR: Instructions file not found!'
        print *, '=========================================='
        print *, 'Expected file: ', trim(instructions_file)
        print *, ''
        print *, 'Available scenarios in Instructions folder:'
        call system('dir /B "'//trim(cwd_i)//'\*instructions.txt"')
        print *, ''
        stop 1
    endif

    ! Check parameters file exists
    inquire(file=trim(parameters_file), exist=file_exists)
    if (.not. file_exists) then
        print *, ''
        print *, '========================================='
        print *, 'FATAL ERROR: Parameters file not found!'
        print *, '========================================='
        print *, 'Expected file: ', trim(parameters_file)
        print *, ''
        print *, 'Available scenarios in Parameters folder:'
        call system('dir /B "'//trim(cwd_p)//'\*parameters.txt"')
        print *, ''
        stop 1
    endif

    ! Validate instructions file format (should have exactly 35 lines of integers)
    unit_test = 999
    open(unit=unit_test, file=trim(instructions_file), action='read', status='old', iostat=ios)

    if (ios /= 0) then
        print *, 'FATAL ERROR: Cannot open instructions file for validation'
        print *, 'File: ', trim(instructions_file)
        stop 1
    endif

    ! Read and validate 35 switch lines
    do line_num = 1, 35
        read(unit_test, *, iostat=ios) switch_val
        if (ios /= 0) then
            print *, ''
            print *, '============================================='
            print *, 'FATAL ERROR: Instructions file format error!'
            print *, '============================================='
            print *, 'File: ', trim(instructions_file)
            print *, 'Line:', line_num
            print *, 'Expected: Integer value (0, 1, or 2)'
            print *, 'Problem: Could not read integer value'
            print *, ''
            print *, 'Instructions files must have exactly 35 lines,'
            print *, 'each containing an integer followed by optional comment.'
            print *, 'Format: VALUE // comment'
            print *, ''
            close(unit_test)
            stop 1
        endif

        ! Warn about unusual values (most switches are 0, 1, or 2; switch_mortality allows up to 8)
        if (switch_val < 0 .or. switch_val > 8) then
            print *, 'WARNING: Line', line_num, 'has unusual value:', switch_val
            print *, 'File: ', trim(instructions_file)
            print *, 'Expected range: 0-8 (most switches use 0-2)'
        endif
    enddo

    close(unit_test)

    print *, 'Configuration files validated successfully.'
    print *, ''

end subroutine validate_config_files

endprogram olg2
