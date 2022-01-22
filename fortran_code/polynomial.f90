!##############################################################################
! MODULE polynomial
! 
! Module for onedimensional polynomial interpolation.
!
! copyright: Fabian Kindermann
!            University of Wuerzburg
!            kindermann.fabian@uni-wuerzburg.de
!##############################################################################
module polynomial


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
! INTERFACE poly_interpol
! 
! Interface for onedimensional polynomial interpolation.
!##############################################################################
interface poly_interpol

    ! define methods used
    module procedure poly_interpol_1, poly_interpol_m
        
end interface


!##############################################################################
! Subroutines and functions                                               
!##############################################################################

contains


!##############################################################################
! FUNCTION grid_Cons_Equi
! 
! Constructs a whole equidistant grid on [left,right].
!##############################################################################
function grid_Cons_Equi(left, right, n)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! left and right interval point
    real*8, intent(in) :: left, right    

    ! last grid point: 0,1,...,n
    integer, intent(in) :: n   
    
    ! value at the grid point x \in [0,n]
    real*8 :: grid_Cons_Equi(0:n)
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: h
    integer :: j
    
        
    !##### ROUTINE CODE #######################################################
    
    ! check for left <= right
    if(left >= right)call error('grid_Cons_Equi', &
        'left interval point greater than right point')
    
    ! calculate distance between grid points
    h = (right-left)/n
            
    ! calculate grid value
    grid_Cons_Equi = h*(/(dble(j), j=0,n)/)+left      

end function grid_Cons_Equi


!##############################################################################
! FUNCTION grid_Cons_Cheb
! 
! Constructs a whole grid on [left,right] using chebychev nodes.
!##############################################################################
function grid_Cons_Cheb(left, right, n)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! left and right interval point
    real*8, intent(in) :: left, right    

    ! last grid point: 0,1,...,n
    integer, intent(in) :: n   
    
    ! value at the grid point x \in [0,n]
    real*8 :: grid_Cons_Cheb(0:n)
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: j
    real*8, parameter :: pi = 3.1415926535897932d0
    
        
    !##### ROUTINE CODE #######################################################
    
    ! check for left <= right
    if(left >= right)call error('grid_Cons_Cheb', &
        'left interval point greater than right point')
            
    ! calculate grid value
    grid_Cons_Cheb = (left+right)/2d0 + (right-left)/2d0* &
        cos((dble(n)-(/(dble(j), j=0,n)/)+0.5d0)/dble(n+1)*pi)

end function grid_Cons_Cheb


!##############################################################################
! FUNCTION poly_interpol_1
! 
! Constructs interpolating polynomial given nodes xi and data yi.
!##############################################################################
function poly_interpol_1(x, xi, yi)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate polynomial
    real*8, intent(in) :: x
    
    ! nodes of interpolation
    real*8, intent(in) :: xi(0:)
    
    ! data of interpolation
    real*8, intent(in) :: yi(0:)
    
    ! return value
    real*8 :: poly_interpol_1
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: j, n, i
    real*8 :: lagrange_poly(0:size(xi, 1)-1)
    
    !##### ROUTINE CODE #######################################################
    
    ! get number of interpolation nodes
    n = assert_eq(size(xi, 1), size(yi, 1), 'poly_interpol') - 1
    
    ! initialize lagrange basis polynomials
    lagrange_poly(:) = 1d0
    
    ! span polynomials
    do j = 0, n        
        do i = 0, n
            if(j /= i)then
                lagrange_poly(j) = lagrange_poly(j) * (x-xi(i))/(xi(j)-xi(i))
            endif
        enddo                
    enddo
    
    poly_interpol_1 = sum(yi*lagrange_poly, 1)
    
end function poly_interpol_1


!##############################################################################
! FUNCTION poly_interpol_m
! 
! Constructs interpolating polynomial given nodes xi and data yi and several
!     points x.
!##############################################################################
function poly_interpol_m(x, xi, yi)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate polynomial
    real*8, intent(in) :: x(1:)
    
    ! nodes of interpolation
    real*8, intent(in) :: xi(0:)
    
    ! data of interpolation
    real*8, intent(in) :: yi(0:)
    
    ! return value
    real*8 :: poly_interpol_m(size(x, 1))
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: j, n, i
    real*8 :: lagrange_poly(size(x, 1), 0:size(xi, 1))
    
    
    !##### ROUTINE CODE #######################################################
    
    ! get number of interpolation nodes
    n = assert_eq(size(xi, 1), size(yi, 1), 'poly_interpol') - 1    
    
    ! initialize lagrange basis polynomials
    lagrange_poly(:, :) = 1d0    
    
    ! span polynomials
    do j = 0, n        
        do i = 0, n
            if(j /= i)then
                lagrange_poly(:, j) = lagrange_poly(:, j) * &
                    (x-xi(i))/(xi(j)-xi(i))
            endif
        enddo                
    enddo
        
    do j = 1, size(x, 1)
        poly_interpol_m(j) = sum(yi*lagrange_poly(j, :), 1)
    enddo
    
end function poly_interpol_m


end module polynomial