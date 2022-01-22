!##############################################################################
! MODULE linint
! 
! Module for multidimensional linear interpolation.
!
! copyright: Fabian Kindermann
!            University of Wuerzburg
!            kindermann.fabian@uni-wuerzburg.de
!##############################################################################
module linint


!##############################################################################
! Declaration of modules used
!##############################################################################

! for assertion of equality in dimensions
use assertions, only: assert_eq

! for throwing error and warning messages
use errwarn

implicit none

save


!##############################################################################
! Declaration of interfaces
!##############################################################################


!##############################################################################
! INTERFACE linear
! 
! Interface for evaluation of one- or multidimensional linear interpolation
!     function.
!##############################################################################
interface linear

    ! define methods used
    module procedure linear1_o, linear1_m, linear2_o, linear2_m, &
        linear3_o, linear3_m
        
end interface


!##############################################################################
! Subroutines and functions                                               
!##############################################################################

contains


!##############################################################################
! FUNCTION gridVal
! 
! Calculates gridpoints of a non-growing or growing grid.
!##############################################################################
function gridVal(x, left, right, n, growth)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! point that shall be calculated
    real*8, intent(in) :: x

    ! left and right interval point
    real*8, intent(in) :: left, right    

    ! last grid point: 0,1,...,n
    integer, intent(in) :: n
    
    ! growth rate
    real*8, intent(in), optional :: growth
    
    ! value at the grid point x \in [0,n]
    real*8 :: gridVal
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: h
    
        
    !##### ROUTINE CODE #######################################################
    
    ! check for left <= right
    if(left >= right)call error('gridVal', &
        'left interval point greater than right point')
    
    ! if grid is growing
    if(present(growth))then
        if(growth > 0d0)then
        
            ! calculate factor
            h = (right-left)/((1+growth)**n-1)
            
            ! calculate grid value
            gridVal = h*((1+growth)**x-1)+left
        
        ! if grid is not growing
        else
        
            ! calculate distance between grid points
            h = (right-left)/n
            
            ! calculate grid value
            gridVal = h*x+left
        
        endif  
    else     
    
        ! calculate distance between grid points
        h = (right-left)/n
            
        ! calculate grid value
        gridVal = h*x+left
        
    endif      

end function gridVal


!##############################################################################
! FUNCTION linear1_o
! 
! Function for evaluation of one-dimensional linear interpolation function at
!     one value.
!##############################################################################
function linear1_o(x, x_d, y_d) result(lin_int)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate linear interpolation function
    real*8, intent(in) :: x
    
    ! x data for linear interpolation 
    real*8, intent(in) :: x_d(0:)
    
    ! y data for linear interpolation 
    real*8, intent(in) :: y_d(0:)
    
    ! value of linear function
    real*8 :: lin_int
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, p, q
    real*8 :: phi       
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of points used
    n = assert_eq(size(x_d, 1)-1, size(y_d, 1)-1, 'linear')

    ! calculate left and right grid point
    p = min(minloc(x-x_d, 1, x-x_d >= 0), n)-1
    do while(x_d(p) == x_d(min(p+1, n)) .and. p < n)
        p = p+1
    enddo
    q = p+1

    ! mass of point q
    phi = (x - x_d(p))/(x_d(q) - x_d(p))
  
    ! calculate value of linear function
    lin_int = (1d0-phi)*y_d(p)+phi*y_d(q)
    
end function linear1_o


!##############################################################################
! FUNCTION linear1_m
! 
! Function for evaluation of one-dimensional linear interpolation function at
!     several values.
!##############################################################################
function linear1_m(x, x_d, y_d) result(lin_int)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate linear interpolation function
    real*8, intent(in) :: x(1:)
    
    ! x data for linear interpolation 
    real*8, intent(in) :: x_d(0:)
    
    ! y data for linear interpolation 
    real*8, intent(in) :: y_d(0:)
    
    ! value of linear function
    real*8 :: lin_int(size(x, 1))
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, j, p(size(x, 1)), q(size(x, 1))
    real*8 :: phi(size(x, 1))       
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of points used
    n = assert_eq(size(x_d, 1)-1, size(y_d, 1)-1, 'linear')
    
    do j = 1, size(x, 1)
        
        ! calculate left and right grid point
        p(j) = min(minloc(x(j)-x_d, 1, x(j)-x_d >= 0), n)-1
        do while(x_d(p(j)) == x_d(min(p(j)+1, n)) .and. p(j) < n)
            p(j) = p(j)+1
        enddo
        q(j) = p(j)+1
        
        ! mass of point q
        phi(j) = (x(j) - x_d(p(j)))/(x_d(q(j)) - x_d(p(j)))    
  
        ! calculate value of linear function
        lin_int(j) = (1d0-phi(j))*y_d(p(j))+phi(j)*y_d(q(j))
    enddo
    
end function linear1_m


!##############################################################################
! FUNCTION linear2_o
! 
! Function for evaluation of two-dimensional linear interpolation function at
!     one value.
!##############################################################################
function linear2_o(x, x_d1, x_d2, y_d) result(lin_int)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate linear interpolating function
    real*8, intent(in) :: x(2)
    
    ! x data 21 for linear interpolation
    real*8, intent(in) :: x_d1(0:)
    
    ! x data 2 for linear interpolation
    real*8, intent(in) :: x_d2(0:)
    
    ! y data for linear interpolation
    real*8, intent(in) :: y_d(0:, 0:)
    
    ! value of linear function
    real*8 :: lin_int
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, p, q
    real*8 :: phi        
    
    
    !##### ROUTINE CODE #######################################################
        
    ! calculate number of points used
    n = assert_eq(size(x_d1, 1)-1, size(y_d, 1)-1, 'linear')

    ! calculate left and right grid point
    p = min(minloc(x(1)-x_d1, 1, x(1)-x_d1 >= 0), n)-1
    do while(x_d1(p) == x_d1(min(p+1, n)) .and. p < n)
        p = p+1
    enddo
    q = p+1

    ! mass of point q
    phi = (x(1) - x_d1(p))/(x_d1(q) - x_d1(p))
  
    ! calculate value of linear function
    lin_int = (1d0-phi)*linear1_o(x(2), x_d2, y_d(p, :))+ &
        phi*linear1_o(x(2), x_d2, y_d(q, :))
    
end function linear2_o


!##############################################################################
! FUNCTION linear2_m
! 
! Function for evaluation of two-dimensional linear interpolation function at
!     several values.
!##############################################################################
function linear2_m(x, x_d1, x_d2, y_d) result(lin_int)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate linear interpolating function
    real*8, intent(in) :: x(1:, 1:)
    
    ! x data 21 for linear interpolation
    real*8, intent(in) :: x_d1(0:)
    
    ! x data 2 for linear interpolation
    real*8, intent(in) :: x_d2(0:)
    
    ! y data for linear interpolation
    real*8, intent(in) :: y_d(0:, 0:)
    
    ! value of linear function
    real*8 :: lin_int(size(x, 2))
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, j, p(size(x, 2)), q(size(x, 2))
    real*8 :: phi(size(x, 2))
    
    
    !##### ROUTINE CODE #######################################################
        
    ! calculate number of points used
    n = assert_eq(size(x, 1), 2, 'linear')
    n = assert_eq(size(x_d1, 1)-1, size(y_d, 1)-1, 'linear')    

    do j = 1, size(x, 2)
    
        ! calculate left and right grid point
        p(j) = min(minloc(x(1,j)-x_d1, 1, x(1,j)-x_d1 >= 0), n)-1
        do while(x_d1(p(j)) == x_d1(min(p(j)+1, n)) .and. p(j) < n)
            p(j) = p(j)+1
        enddo
        q(j) = p(j)+1

        ! mass of point q
        phi(j) = (x(1,j) - x_d1(p(j)))/(x_d1(q(j)) - x_d1(p(j)))
      
        ! calculate value of linear function
        lin_int(j) = (1d0-phi(j))*linear1_o(x(2,j), x_d2, y_d(p(j), :))+ &
            phi(j)*linear1_o(x(2, j), x_d2, y_d(q(j), :))
    enddo
    
end function linear2_m


!##############################################################################
! FUNCTION linear3_o
! 
! Function for evaluation of three-dimensional linear interpolation function at
!     one value.
!##############################################################################
function linear3_o(x, x_d1, x_d2, x_d3, y_d) result(lin_int)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate linear interpolating function
    real*8, intent(in) :: x(2)
    
    ! x data 21 for linear interpolation
    real*8, intent(in) :: x_d1(0:)
    
    ! x data 2 for linear interpolation
    real*8, intent(in) :: x_d2(0:)
    
    ! x data 3 for linear interpolation
    real*8, intent(in) :: x_d3(0:)
    
    ! y data for linear interpolation
    real*8, intent(in) :: y_d(0:, 0:, 0:)
    
    ! value of linear function
    real*8 :: lin_int
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, p, q
    real*8 :: phi        
    
    
    !##### ROUTINE CODE #######################################################
        
    ! calculate number of points used
    n = assert_eq(size(x_d1, 1)-1, size(y_d, 1)-1, 'linear')

    ! calculate left and right grid point
    p = min(minloc(x(1)-x_d1, 1, x(1)-x_d1 >= 0), n)-1
    do while(x_d1(p) == x_d1(min(p+1, n)) .and. p < n)
        p = p+1
    enddo
    q = p+1

    ! mass of point q
    phi = (x(1) - x_d1(p))/(x_d1(q) - x_d1(p))
  
    ! calculate value of linear function
    lin_int = (1d0-phi)*linear2_o(x(2:3), x_d2, x_d3, y_d(p, :, :))+ &
        phi*linear2_o(x(2:3), x_d2, x_d3, y_d(q, :, :))
    
end function linear3_o


!##############################################################################
! FUNCTION linear3_m
! 
! Function for evaluation of three-dimensional linear interpolation function at
!     several values.
!##############################################################################
function linear3_m(x, x_d1, x_d2, x_d3, y_d) result(lin_int)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate linear interpolating function
    real*8, intent(in) :: x(1:, 1:)
    
    ! x data 21 for linear interpolation
    real*8, intent(in) :: x_d1(0:)
    
    ! x data 2 for linear interpolation
    real*8, intent(in) :: x_d2(0:)
    
    ! x data 3 for linear interpolation
    real*8, intent(in) :: x_d3(0:)
    
    ! y data for linear interpolation
    real*8, intent(in) :: y_d(0:, 0:, 0:)
    
    ! value of linear function
    real*8 :: lin_int(size(x, 2))
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, j, p(size(x, 2)), q(size(x, 2))
    real*8 :: phi(size(x, 2))
    
    
    !##### ROUTINE CODE #######################################################
        
    ! calculate number of points used
    n = assert_eq(size(x, 1), 3, 'linear')
    n = assert_eq(size(x_d1, 1)-1, size(y_d, 1)-1, 'linear')    

    do j = 1, size(x, 2)
    
        ! calculate left and right grid point
        p(j) = min(minloc(x(1,j)-x_d1, 1, x(1,j)-x_d1 >= 0), n)-1
        do while(x_d1(p(j)) == x_d1(min(p(j)+1, n)) .and. p(j) < n)
            p(j) = p(j)+1
        enddo
        q(j) = p(j)+1

        ! mass of point q
        phi(j) = (x(1,j) - x_d1(p(j)))/(x_d1(q(j)) - x_d1(p(j)))
      
        ! calculate value of linear function
        lin_int(j) = (1d0-phi(j))*linear2_o(x(2:3,j), x_d2, x_d3, &
            y_d(p(j), :, :))+ phi(j)*linear2_o(x(2:3, j), &
            x_d2, x_d3, y_d(q(j), :, :))
    enddo
    
end function linear3_m

end module linint