!##############################################################################
! MODULE assertions 
! 
! Contains several assertion methods.
!
! copyright: Fabian Kindermann
!            University of Wuerzburg
!            kindermann.fabian@uni-wuerzburg.de
!
! Large parts of the procedures were taken from:
!     Press, Teukolsky, Vetterling and Flannery (1992): "Numerical Recipes in
!     FORTRAN: The Art of Scientific Computing", 2nd edition, Cambridge
!     Univeristy Press, Cambridge.
!##############################################################################

module assertions


!##############################################################################
! Declaration of modules used
!##############################################################################

! For throwing error and warning messages
use errwarn

implicit none

save


!##############################################################################
! Interface declarations
!##############################################################################


!##############################################################################
! INTERFACE assert_eq
! 
! Interface for equality assertions by assert_eqx functions.
!##############################################################################
interface assert_eq

    ! define methods used
    module procedure assert_eq2, assert_eq3, assert_eq4, assert_eq5, &
        assert_eqn
        
end interface


!##############################################################################
! Subroutines and functions                                               
!##############################################################################

contains


!##############################################################################
! FUNCTION assert_eq2 
! 
! Checks equality for two integers.
!##############################################################################
function assert_eq2(n1, n2, string)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! integers to compare for equality
    integer, intent(in) :: n1, n2

    ! routine from which error should be thrown
	character(len=*), intent(in) :: string	
	
	! return value
	integer :: assert_eq2
	
	
	!##### ROUTINE CODE #######################################################
	
	! if equality, set return value to n1
	if (n1 == n2)then
		assert_eq2 = n1
		
	! else throw error message
	else
	    call error(string, 'an assertion failed in assert_eq2')		
	end if

end function assert_eq2


!##############################################################################
! FUNCTION assert_eq3
! 
! Checks equality for three integers.    
!##############################################################################
function assert_eq3(n1, n2, n3, string)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! integers to compare for equality
    integer, intent(in) :: n1, n2, n3

    ! routine from which error should be thrown
	character(len=*), intent(in) :: string	
	
	! return value
	integer :: assert_eq3
	
	
	!##### ROUTINE CODE #######################################################
	
	! if equality, set return value to n1
	if (n1 == n2 .and. n2 == n3)then
		assert_eq3 = n1
		
	! else throw error message
	else
		call error(string, 'an assertion failed in assert_eq3')
	end if

end function assert_eq3


!##############################################################################
! FUNCTION assert_eq4
! 
! Checks equality for four integers.    
!##############################################################################
function assert_eq4(n1, n2, n3, n4, string)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! integers to compare for equality
    integer, intent(in) :: n1, n2, n3, n4

    ! routine from which error should be thrown
	character(len=*), intent(in) :: string	
	
	! return value
	integer :: assert_eq4
	
	
	!##### ROUTINE CODE #######################################################
	
	! if equality, set return value to n1
	if (n1 == n2 .and. n2 == n3 .and. n3 == n4)then
		assert_eq4 = n1
		
	! else throw error message
	else
		call error(string, 'an assertion failed in assert_eq4')
	end if

end function assert_eq4


!##############################################################################
! FUNCTION assert_eq5
! 
! Checks equality for five integers.    
!##############################################################################
function assert_eq5(n1, n2, n3, n4, n5, string)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! integers to compare for equality
    integer, intent(in) :: n1, n2, n3, n4, n5

    ! routine from which error should be thrown
	character(len=*), intent(in) :: string	
	
	! return value
	integer :: assert_eq5
	
	
	!##### ROUTINE CODE #######################################################
	
	! if equality, set return value to n1
	if (n1 == n2 .and. n2 == n3 .and. n3 == n4 .and. n4 == n5)then
		assert_eq5 = n1
		
	! else throw error message
	else
		call error(string, 'an assertion failed in assert_eq5')
	end if

end function assert_eq5


!##############################################################################
! FUNCTION assert_eqn
! 
! Checks equality for n integers.    
!##############################################################################
function assert_eqn(nn, string)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! integers to compare for equality
    integer, intent(in) :: nn(:)

    ! routine from which error should be thrown
	character(len=*), intent(in) :: string	
	
	! return value
	integer :: assert_eqn
	
	
	!##### ROUTINE CODE #######################################################
	
	! if equality, set return value to n1
	if (all(nn(2:) == nn(1)))then
		assert_eqn = nn(1)
		
	! else throw error message
	else
		call error(string, 'an assertion failed in assert_eqn')
	end if

end function assert_eqn
	

end module assertions