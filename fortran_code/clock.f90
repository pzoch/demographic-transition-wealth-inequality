!===============================================================================
! FILE: clock.f90
!
! DESCRIPTION:
!   Simple timing utilities for measuring elapsed CPU and wall-clock time.
!   Used for profiling model solution performance.
!
! MODULE: clock
!   Lightweight timer for performance measurement.
!
! SUBROUTINES:
!   - tic: Starts CPU timer (records start time)
!   - toc: Stops CPU timer and reports elapsed time in seconds
!   - tic_real: Starts real (wall-clock) timer
!   - toc_real: Stops real timer and reports elapsed wall-clock time
!
! VARIABLES (private):
!   - starttime_cpu: CPU time at tic() call
!   - starttime_real: Wall-clock time array at tic_real() call (8 integers)
!
! USAGE:
!   call tic()
!   [... code to time ...]
!   call toc()
!   ! Prints: "Elapsed time: X.XXX seconds"
!
! NOTES:
!   CPU time measures processor time used by current process. Wall-clock time
!   measures actual elapsed time (includes I/O wait, system interrupts).
!   Use toc_real for parallel code; tic/toc for serial performance.
!   Minimal overhead (~microseconds per call).
!
! COPYRIGHT:
!   Fabian Kindermann, University of Wuerzburg
!   kindermann.fabian@uni-wuerzburg.de
!##############################################################################

module clock

implicit none

save

!##############################################################################
! Declaration of Variables
!##############################################################################

! starting time for cpu timer
real*8, private :: starttime_cpu

! starting time real time timer
integer, private :: starttime_real(8)


!##############################################################################
! Subroutines and functions                                               
!##############################################################################

contains


!##############################################################################
! SUBROUTINE tic
! 
! Starts cpu timer.
!##############################################################################
subroutine tic()

    
    !##### ROUTINE CODE #######################################################
    
    ! get cpu time
    call cpu_time(starttime_cpu)

end subroutine tic


!##############################################################################
! SUBROUTINE toc
! 
! Stops cpu timer.
!##############################################################################
subroutine toc(file)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! optional file identifier
    integer, intent(in), optional :: file


    !##### OTHER VARIABLES ####################################################
    
    real*8 :: time
    integer :: outfile
    real*8 :: times(4)
    
    
    !##### ROUTINE CODE #######################################################        
    
    ! get output file identifier
    if(present(file))then
        outfile = file
    else
        outfile = 0
    endif
    
    ! get cpu time
    call cpu_time(time)            
    
    ! calculate time difference
    time = time - starttime_cpu    
    
    ! get number of days
    times(1) = floor(time/(24d0*60d0*60d0))
    time = time - times(1)*24d0*60d0*60d0    
        
    ! get number of hours
    times(2) = floor(time/(60d0*60d0))
    time = time - times(2)*60d0*60d0
        
    ! get number of minutes
    times(3) = floor(time/60d0)
    time = time - times(3)*60d0
        
    ! get number of seconds
    times(4) = time
    
    call outTime(times, outfile)

end subroutine toc


!##############################################################################
! SUBROUTINE outTime
! 
! Writes time to file.
!##############################################################################
subroutine outTime(times, file)

    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! time as integer array
    real*8, intent(in) :: times(4)
    
    ! the output file identifier
    integer, intent(in) :: file
    
    !##### OTHER VARIABLES ####################################################
    
    character(len=200) :: output1, output2
    
    
    !##### ROUTINE CODE #######################################################        

    ! set up output
    write(output1, '(a)')'Time elapsed: '
    output2 = output1

    ! write time values
    if(times(1) > 0d0)then
        write(output1, '(a,1x,i3,a)') trim(output2), int(times(1)), ' d  '
	    output2 = output1
    endif
    if(times(2) > 0d0)then
        write(output1, '(a,1x,i3,a)') trim(output2), int(times(2)), ' h  '
	    output2 = output1
    endif
    if(times(3) > 0d0) then
        write(output1, '(a,1x,i3,a)')trim(output2), int(times(3)), ' min  '
	    output2 = output1
    endif
    
    write(output1, '(a,1x,f7.3,a)')trim(output2), times(4), ' s  '

    if(file > 0) then
        write(file, '(/a/)')trim(output1)
    else 
        write(*, '(/a/)')trim(output1)
    endif
    
end subroutine outTime

end module clock