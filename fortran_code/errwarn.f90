!===============================================================================
! FILE: errwarn.f90
!
! DESCRIPTION:
!   Centralized error and warning message handling. Provides consistent diagnostic
!   output format and controlled program termination on fatal errors.
!
! MODULE: errwarn
!   Error/warning reporting routines.
!
! SUBROUTINES:
!   - error: Reports fatal error with routine name and message, then stops execution
!            Format: "ERROR <routine>: <message>"
!            Waits for user input before terminating (read(*,*))
!   - warning: Reports non-fatal warning with routine name and message
!              Format: "WARNING <routine>: <message>"
!              Execution continues after display
!
! USAGE:
!   call error('subroutine_name', 'Description of error')
!   call warning('subroutine_name', 'Description of warning')
!
! OUTPUT:
!   All messages written to standard output (unit *) with clear formatting.
!   Error messages include blank lines before/after for visibility.
!
! NOTES:
!   Used throughout toolbox modules for input validation and error detection.
!   The read(*,*) in error() allows inspection of state before termination.
!   Consider removing read(*,*) for batch/automated runs to avoid hanging.
!
! COPYRIGHT:
!   Fabian Kindermann, University of Wuerzburg
!   kindermann.fabian@uni-wuerzburg.de
!##############################################################################

module errwarn

implicit none

save


!##############################################################################
! Subroutines and functions                                               
!##############################################################################

contains


!##############################################################################
! SUBROUTINE error
! 
! Throws error message and stops program.
!##############################################################################
subroutine error(routine, message)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! routine in which error occured
    character(len=*), intent(in) :: routine
    
    ! error message
    character(len=*), intent(in) :: message
    
    
    !##### ROUTINE CODE #######################################################
    
    ! write error message
    write(*,'(/a,a,a,a/)')'ERROR ',routine,': ',message
    
    ! stop program
    read(*,*)
    stop

end subroutine error


!##############################################################################
! SUBROUTINE warning
! 
! Throws warning message
!##############################################################################
subroutine warning(routine, message)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! routine in which warning occured
    character(len=*), intent(in) :: routine
    
    ! warning message
    character(len=*), intent(in) :: message
    
    
    !##### ROUTINE CODE #######################################################
    
    ! write warning message
    write(*,'(/a,a,a,a/)')'WARNING ',routine,': ',message    

end subroutine warning

end module errwarn