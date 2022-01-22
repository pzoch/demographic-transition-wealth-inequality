!##############################################################################
! MODULE errwarn 
! 
! Throws warning and error messages.
!
! copyright: Fabian Kindermann
!            University of Wuerzburg
!            kindermann.fabian@uni-wuerzburg.de
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