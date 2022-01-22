!##############################################################################
! MODULE splines
! 
! Module for multidimensional spline interpolation.
!
! copyright: Fabian Kindermann
!            University of Wuerzburg
!            kindermann.fabian@uni-wuerzburg.de
!##############################################################################
module splines


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
! INTERFACE grid_Val_Inv
! 
! Interface for inverting gridpoints.
!##############################################################################
interface grid_Val_Inv

    ! define methods used
    module procedure grid_Val_Inv_1, grid_Val_Inv_m
        
end interface


!##############################################################################
! INTERFACE spline_interp
! 
! Interface for one- or multidimensional spline interpolation.
!##############################################################################
interface spline_interp

    ! define methods used
    module procedure spline_interp1, spline_interp2, spline_interp3, &
        spline_interp4, spline_interp5, spline_interp6, spline_interp7
        
end interface


!##############################################################################
! INTERFACE spline_eval
! 
! Interface for evaluation of one- or multidimensional spline.
!##############################################################################
interface spline_eval

    ! define methods used
    module procedure &
        spline1, spline1_grid, &
        spline2, spline2_grid, &
        spline3, spline3_grid, &
        spline4, spline4_grid, &
        spline5, spline5_grid, &
        spline6, spline6_grid, &
        spline7, spline7_grid   
        
end interface


!##############################################################################
! INTERFACE spline
! 
! Interface for complete interpolation and evaluation of one- or 
!     multidimensional spline.
!##############################################################################
interface spline

    ! define methods used
    module procedure &
        spline1_complete, spline1_complete_m , &
        spline2_complete, spline2_complete_m, &
        spline3_complete, spline3_complete_m , &
        spline4_complete, spline4_complete_m, &
        spline5_complete, spline5_complete_m, &
        spline6_complete, spline6_complete_m, &
        spline7_complete, spline7_complete_m
        
end interface
    


!##############################################################################
! Subroutines and functions                                               
!##############################################################################

contains


!##############################################################################
! FUNCTION grid_Cons_prim
! 
! Constructs a whole non-growing of growing grid on [left, right].
!##############################################################################
function grid_Cons_prim(left, right, mid, n, growth,g)

    real*8, intent(in) :: left, right, mid
    integer, intent(in) :: n
    real*8, intent(in) :: growth
    real*8 :: grid_Cons_prim(0:n)
    real*8 :: h
    integer, intent(in):: g
    integer :: j
    
    
     
     grid_Cons_prim(0)=left
     do j=1, g-1, 1
         grid_Cons_prim(j)=(grid_Cons_prim(j-1)-mid)/growth + mid
     enddo
     grid_Cons_prim(g) = mid
     grid_Cons_prim(n) = right
     do j=n-1, g+1, -1
         grid_Cons_prim(j) = (grid_Cons_prim(j+1)-mid)/growth + mid
     enddo
    
    
end function grid_Cons_prim

!##############################################################################
! FUNCTION grid_Cons
! 
! Constructs a whole non-growing of growing grid on [left, right].
!##############################################################################
function grid_Cons(left, right, n, growth)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! left and right interval point
    real*8, intent(in) :: left, right    

    ! last grid point: 0,1,...,n
    integer, intent(in) :: n
    
    ! growth rate
    real*8, intent(in), optional :: growth
    
    ! value at the grid point x \in [0,n]
    real*8 :: grid_Cons(0:n)
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: h
    integer :: j
    
        
    !##### ROUTINE CODE #######################################################
    
    ! check for left <= right
    if(left >= right)call error('grid_Cons', &
        'left interval point greater than right point')
    
    ! if grid is growing
    if(present(growth))then
        if(growth > 0d0)then
        
            ! calculate factor
            h = (right-left)/((1+growth)**n-1)
            
            ! calculate grid value
            grid_Cons = h*((1+growth)**(/(dble(j), j=0,n)/)-1)+left
        
        ! if grid is not growing
        else
        
            ! calculate distance between grid points
            h = (right-left)/n
            
            ! calculate grid value
            grid_Cons = h*(/(dble(j), j=0,n)/)+left
        
        endif  
    else     
    
        ! calculate distance between grid points
        h = (right-left)/n
            
        ! calculate grid value
        grid_Cons = h*(/(dble(j), j=0,n)/)+left
        
    endif      

end function grid_Cons


!##############################################################################
! FUNCTION grid_Val
! 
! Calculates single gridpoint of a non-growing or growing grid.
!##############################################################################
function grid_Val(x, left, right, n, growth)


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
    real*8 :: grid_Val
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: h
    
        
    !##### ROUTINE CODE #######################################################
    
    ! check for left <= right
    if(left >= right)call error('grid_Val', &
        'left interval point greater than right point')
    
    ! if grid is growing
    if(present(growth))then
        if(growth > 0d0)then
        
            ! calculate factor
            h = (right-left)/((1+growth)**n-1)
            
            ! calculate grid value
            grid_Val = h*((1+growth)**x-1)+left
        
        ! if grid is not growing
        else
        
            ! calculate distance between grid points
            h = (right-left)/n
            
            ! calculate grid value
            grid_Val = h*x+left
        
        endif  
    else     
    
        ! calculate distance between grid points
        h = (right-left)/n
            
        ! calculate grid value
        grid_Val = h*x+left
        
    endif      

end function grid_Val

!##############################################################################
! FUNCTION grid_Val_Inv_prim
! 
! Calculates inverse of gridpoints of a non-growing or growing grid.
!##############################################################################
function grid_Val_Inv_prim(x, left, right, mid, n, growth,g)
    real*8, intent(in) :: x
    real*8, intent(in) :: left, right, mid
    integer, intent(in) :: n
    real*8, intent(in) :: growth
    real*8 :: grid_Val_Inv_prim
    real*8 :: h
    integer, intent(in):: g
   
    
    
    
    if(x==mid) then
        grid_Val_Inv_prim = g
    endif
    if(x<mid) then
        grid_Val_Inv_prim = log((left-mid)/x)/log(growth)
        if(grid_Val_Inv_prim>=g) then
            grid_Val_Inv_prim = g-1
        endif
    endif
    if(x>mid) then
        grid_Val_Inv_prim = n-log((right-mid)/x)/log(growth)
        if(grid_Val_Inv_prim<g) then
            grid_Val_Inv_prim = g
        endif
    endif
    if(grid_Val_Inv_prim<0d0) then
        grid_Val_Inv_prim = 0
    endif
    if(grid_Val_Inv_prim>n) then
        grid_Val_Inv_prim = n
    endif
    
end function grid_Val_Inv_prim
!##############################################################################
! FUNCTION grid_Val_Inv_1
! 
! Calculates inverse of gridpoints of a non-growing or growing grid.
!##############################################################################
function grid_Val_Inv_1(x, left, right, n, growth)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! point that shall be calculated
    real*8, intent(in) :: x

    ! left and right interval point
    real*8, intent(in) :: left, right    

    ! last grid point: 0,1,...,n
    integer, intent(in) :: n
    
    ! growth rate
    real*8, intent(in), optional :: growth
    
    ! value of the inverse of the gridpoint x \in [left, right]
    real*8 :: grid_Val_Inv_1
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: h
    
        
    !##### ROUTINE CODE #######################################################
    
    ! check for left <= right
    if(left >= right)call error('grid_Val_Inv', &
        'left interval point greater than right point')
    
    ! if grid is growing
    if(present(growth))then
        if(growth > 0d0)then
        
            ! calculate factor
            h = (right-left)/((1+growth)**n-1)
            
            ! calculate grid value
            grid_Val_Inv_1 = log((x-left)/h+1)/log(1+growth)
        
        ! if grid is not growing
        else
        
            ! calculate distance between grid points
            h = (right-left)/n
            
            ! calculate grid value
            grid_Val_Inv_1 = (x-left)/h
        
        endif  
    else     
    
        ! calculate distance between grid points
        h = (right-left)/n
            
        ! calculate grid value
        grid_Val_Inv_1 = (x-left)/h
        
    endif      

end function grid_Val_Inv_1


!##############################################################################
! FUNCTION grid_Val_Inv_m
! 
! Calculates inverse of gridpoints of a non-growing or growing grid.
!##############################################################################
function grid_Val_Inv_m(x, left, right, n, growth)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! point that shall be calculated
    real*8, intent(in) :: x(:)

    ! left and right interval point
    real*8, intent(in) :: left, right    

    ! last grid point: 0,1,...,n
    integer, intent(in) :: n
    
    ! growth rate
    real*8, intent(in), optional :: growth
    
    ! value of the inverse of the gridpoint x \in [left, right]
    real*8 :: grid_Val_Inv_m(size(x, 1))
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: h
    
        
    !##### ROUTINE CODE #######################################################
    
    ! check for left <= right
    if(left >= right)call error('grid_Val_Inv', &
        'left interval point greater than right point')
    
    ! if grid is growing
    if(present(growth))then
        if(growth > 0d0)then
        
            ! calculate factor
            h = (right-left)/((1+growth)**n-1)
            
            ! calculate grid value
            grid_Val_Inv_m = log((x-left)/h+1)/log(1+growth)
        
        ! if grid is not growing
        else
        
            ! calculate distance between grid points
            h = (right-left)/n
            
            ! calculate grid value
            grid_Val_Inv_m = (x-left)/h
        
        endif  
    else     
    
        ! calculate distance between grid points
        h = (right-left)/n
            
        ! calculate grid value
        grid_Val_Inv_m = (x-left)/h
        
    endif      

end function grid_Val_Inv_m


!##############################################################################
! SUBROUTINE spline_interp1
! 
! Subroutine for one-dimensional spline interpolation.
!##############################################################################
subroutine spline_interp1(y, c)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! interpolation data
    real*8, intent(in) :: y(0:)
    
    ! coefficients for spline interpolation
    real*8, intent(out) :: c(1:)
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, j
    real*8, allocatable :: r(:), d(:)
    
    
    !##### ROUTINE CODE #######################################################
    
    ! assert sizes for the two arrays do fit    
    n = assert_eq(size(y,1)+2, size(c,1), 'spline_interp')
    
    ! deallocate help arrays
    if(allocated(r))deallocate(r)
    if(allocated(d))deallocate(d)
    
    ! allocate help arrays
    allocate(r(n))
    allocate(d(n))
    
    ! calculate real n
    n = n-3
    
    ! calculate numerical derivatives at end points
    r(1) = (2d0*y(0)-5d0*y(1)+4d0*y(2)-y(3))/6d0
    r(n+3) = (2d0*y(n)-5d0*y(n-1)+4d0*y(n-2)-y(n-3))/6d0

    ! set rest of right side of equation system
    r(2:n+2) = y(0:n)

    ! solve the spline interpolation equation system
    c(2) = (y(0)-r(1))/6d0
    c(n+2) = (y(n)-r(n+3))/6d0

    d(3) = 4d0
    r(3) = y(1)-c(2)
    r(n+1) = y(n-1)-c(n+2)
      
    do j = 4, n+1
        d(j) = 4d0-1d0/d(j-1)
        r(j) = r(j)-r(j-1)/d(j-1)
    enddo
      
    c(n+1) = r(n+1)/d(n+1)
      
    do j = n, 3, -1
        c(j) = (r(j)-c(j+1))/d(j)
    enddo
      
    c(1) = r(1)+2d0*c(2)-c(3)
    c(n+3) = r(n+3)+2d0*c(n+2)-c(n+1)
    
end subroutine spline_interp1


!##############################################################################
! SUBROUTINE spline_interp2
! 
! Subroutine for two-dimensional spline interpolation.
!##############################################################################
subroutine spline_interp2(y, c)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! interpolation data
    real*8, intent(in) :: y(0:, 0:)
    
    ! coefficients for spline interpolation
    real*8, intent(out) :: c(1:, 1:)
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n(2), j
    real*8, allocatable :: tempc(:, :)
    
    
    !##### ROUTINE CODE #######################################################      
    
    ! calculate array sizes    
    do j = 1, 2
        n(j) = assert_eq(size(y,j)+2, size(c,j), 'spline_interp')
    enddo    
        
    ! calculate real n
    n = n-3    
    
    ! deallocate tempc
    if(allocated(tempc))deallocate(tempc)
    
    ! allocate tempc
    allocate(tempc(n(1)+3, 0:n(2)))        
    
    ! calculate temporary coefficients
    do j = 0, n(2)
        call spline_interp1(y(:, j), tempc(:, j))
    enddo
    
    ! calculate actual coefficients
    do j = 1, n(1)+3
        call spline_interp1(tempc(j, :), c(j, :))
    enddo    
    
end subroutine spline_interp2


!##############################################################################
! SUBROUTINE spline_interp3
! 
! Subroutine for three-dimensional spline interpolation.
!##############################################################################
subroutine spline_interp3(y, c)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! interpolation data
    real*8, intent(in) :: y(0:, 0:, 0:)
    
    ! coefficients for spline interpolation
    real*8, intent(out) :: c(1:, 1:, 1:)
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n(3), j, j2
    real*8, allocatable :: tempc(:, :, :)
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate array sizes    
    do j = 1, 3
        n(j) = assert_eq(size(y,j)+2, size(c,j), 'spline_interp')
    enddo
    
    ! calculate real n
    n = n-3    
    
    ! deallocate tempc
    if(allocated(tempc))deallocate(tempc)
    
    ! allocate tempc
    allocate(tempc(n(1)+3, n(2)+3, 0:n(3)))        
    
    ! calculate temporary coefficients
    do j = 0, n(3)
        call spline_interp2(y(:, :, j), tempc(:, :, j))
    enddo    
    
    ! calculate actual coefficients
    do j = 1, n(1)+3
        do j2 = 1, n(2)+3
            call spline_interp1(tempc(j, j2, :), c(j, j2, :))
        enddo
    enddo    
    
end subroutine spline_interp3


!##############################################################################
! SUBROUTINE spline_interp4
! 
! Subroutine for four-dimensional spline interpolation.
!##############################################################################
subroutine spline_interp4(y, c)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! interpolation data
    real*8, intent(in) :: y(0:, 0:, 0:, 0:)
    
    ! coefficients for spline interpolation
    real*8, intent(out) :: c(1:, 1:, 1:, 1:)
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n(4), j, j2, j3
    real*8, allocatable :: tempc(:, :, :, :)
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate array sizes    
    do j = 1, 4
        n(j) = assert_eq(size(y,j)+2, size(c,j), 'spline_interp')
    enddo
    
    ! calculate real n
    n = n-3
    
    ! deallocate tempc
    if(allocated(tempc))deallocate(tempc)
    
    ! allocate tempc
    allocate(tempc(n(1)+3, n(2)+3, n(3)+3, 0:n(4)))        
    
    ! calculate temporary coefficients
    do j = 0, n(4)
        call spline_interp3(y(:, :, :, j), tempc(:, :, :, j))
    enddo    
    
    ! calculate actual coefficients
    do j = 1, n(1)+3
        do j2 = 1, n(2)+3
            do j3 = 1, n(3)+3
                call spline_interp1(tempc(j, j2, j3, :), c(j, j2, j3, :))
            enddo
        enddo
    enddo    
    
end subroutine spline_interp4


!##############################################################################
! SUBROUTINE spline_interp5
! 
! Subroutine for five-dimensional spline interpolation.
!##############################################################################
subroutine spline_interp5(y, c)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! interpolation data
    real*8, intent(in) :: y(0:, 0:, 0:, 0:, 0:)
    
    ! coefficients for spline interpolation
    real*8, intent(out) :: c(1:, 1:, 1:, 1:, 1:)
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n(5), j, j2, j3, j4
    real*8, allocatable :: tempc(:, :, :, :, :)
    
    
    !##### ROUTINE CODE #######################################################   
    
    ! calculate array sizes    
    do j = 1, 5
        n(j) = assert_eq(size(y,j)+2, size(c,j), 'spline_interp')
    enddo
    
    ! calculate real n
    n = n-3
    
    ! deallocate tempc
    if(allocated(tempc))deallocate(tempc)
    
    ! allocate tempc
    allocate(tempc(n(1)+3, n(2)+3, n(3)+3, n(4)+3, 0:n(5)))
    
    ! calculate temporary coefficients
    do j = 0, n(5)
        call spline_interp4(y(:, :, :, :, j), tempc(:, :, :, :, j))
    enddo    
    
    ! calculate actual coefficients
    do j = 1, n(1)+3
        do j2 = 1, n(2)+3
            do j3 = 1, n(3)+3
                do j4 = 1, n(4)+3
                    call spline_interp1(tempc(j, j2, j3, j4, :), &
                        c(j, j2, j3, j4, :))
                enddo
            enddo
        enddo
    enddo    
    
end subroutine spline_interp5


!##############################################################################
! SUBROUTINE spline_interp6
! 
! Subroutine for six-dimensional spline interpolation.
!##############################################################################
subroutine spline_interp6(y, c)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! interpolation data
    real*8, intent(in) :: y(0:, 0:, 0:, 0:, 0:, 0:)
    
    ! coefficients for spline interpolation
    real*8, intent(out) :: c(1:, 1:, 1:, 1:, 1:, 1:)
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n(6), j, j2, j3, j4, j5
    real*8, allocatable :: tempc(:, :, :, :, :, :)
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate array sizes    
    do j = 1, 6
        n(j) = assert_eq(size(y,j)+2, size(c,j), 'spline_interp')
    enddo
    
    ! calculate real n
    n = n-3
    
    ! deallocate tempc
    if(allocated(tempc))deallocate(tempc)
    
    ! allocate tempc
    allocate(tempc(n(1)+3, n(2)+3, n(3)+3, n(4)+3, n(5)+3, 0:n(6)))
    
    ! calculate temporary coefficients
    do j = 0, n(6)
        call spline_interp5(y(:, :, :, :, :, j), tempc(:, :, :, :, :, j))
    enddo    
    
    ! calculate actual coefficients
    do j = 1, n(1)+3
        do j2 = 1, n(2)+3
            do j3 = 1, n(3)+3
                do j4 = 1, n(4)+3
                    do j5 = 1, n(5)+3
                        call spline_interp1(tempc(j, j2, j3, j4, j5, :), &
                            c(j, j2, j3, j4, j5, :))
                    enddo
                enddo
            enddo
        enddo
    enddo    
    
end subroutine spline_interp6


!##############################################################################
! SUBROUTINE spline_interp7
! 
! Subroutine for seven-dimensional spline interpolation.
!##############################################################################
subroutine spline_interp7(y, c)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! interpolation data
    real*8, intent(in) :: y(0:, 0:, 0:, 0:, 0:, 0:, 0:)
    
    ! coefficients for spline interpolation
    real*8, intent(out) :: c(1:, 1:, 1:, 1:, 1:, 1:, 1:)
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n(7), j, j2, j3, j4, j5, j6
    real*8, allocatable :: tempc(:, :, :, :, :, :, :)
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate array sizes    
    do j = 1, 7
        n(j) = assert_eq(size(y,j)+2, size(c,j), 'spline_interp')
    enddo
    
    ! calculate real n
    n = n-3
    
    ! deallocate tempc
    if(allocated(tempc))deallocate(tempc)
    
    ! allocate tempc
    allocate(tempc(n(1)+3, n(2)+3, n(3)+3, n(4)+3, n(5)+3, n(6)+3, 0:n(7)))
    
    ! calculate temporary coefficients
    do j = 0, n(7)
        call spline_interp6(y(:, :, :, :, :, :, j), tempc(:, :, :, :, :, :, j))
    enddo    
    
    ! calculate actual coefficients
    do j = 1, n(1)+3
        do j2 = 1, n(2)+3
            do j3 = 1, n(3)+3
                do j4 = 1, n(4)+3
                    do j5 = 1, n(5)+3
                        do j6 = 1, n(6)+3
                            call spline_interp1(tempc(j, j2, j3, &
                                j4, j5, j6, :),c(j, j2, j3, j4, j5, j6, :))
                        enddo
                    enddo
                enddo
            enddo
        enddo
    enddo    
    
end subroutine spline_interp7


!##############################################################################
! FUNCTION spline1
! 
! Function for evaluation of one-dimensional spline.
!##############################################################################
function spline1(x, c)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x
    
    ! coefficients for spline interpolation
    real*8, intent(in) :: c(1:)
    
    ! value of spline function
    real*8 :: spline1
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n1, j1, p1, q1
    real*8 :: phi1, xtemp1
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of points used
    n1 = size(c, 1)

    ! calculate left and right summation end point
    p1 = max(floor(x)+1, 1)    
    q1 = min(p1+3, n1)
  
    spline1 = 0d0

    do j1 = p1, q1   
  
        ! calculate value where to evaluate basis function
        xtemp1 = abs(x-j1+2)
        
        ! calculate basis function
        if(xtemp1 <= 1d0)then
            phi1 = 4d0+xtemp1**2*(3d0*xtemp1-6d0)
        elseif(xtemp1 <= 2d0)then
            phi1 = (2d0-xtemp1)**3
        else
            phi1 = 0d0
        endif
  
        ! calculate spline value
        spline1 = spline1+c(j1)*phi1
    enddo
    
end function spline1


!##############################################################################
! FUNCTION spline1_grid
! 
! Function for evaluation of one-dimensional spline, includes inverting grid.
!##############################################################################
function spline1_grid(x, c, left, right, growth)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x
    
    ! coefficients for spline interpolation
    real*8, intent(in) :: c(1:)
    
    ! left interval endpoint
    real*8, intent(in) :: left
    
    ! right interval endpoint
    real*8, intent(in) :: right
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth
    
    ! value of spline function
    real*8 :: spline1_grid
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n
    real*8 :: xtemp       
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of grid-points
    n = size(c, 1)-3

    ! invert grid
    if(present(growth))then
        xtemp = grid_Val_Inv(x, left, right, n, growth)
    else 
        xtemp = grid_Val_Inv(x, left, right, n)
    endif
    
    ! calculate spline value
    spline1_grid = spline1(xtemp, c)
    
end function spline1_grid


!##############################################################################
! FUNCTION spline1_complete
! 
! Function for evaluation of one-dimensional spline, includes inverting grid
!     and interpolation method for a single point.
!##############################################################################
function spline1_complete(x, y, left, right, growth)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x
    
    ! data for spline interpolation
    real*8, intent(in) :: y(0:)
    
    ! left interval endpoint
    real*8, intent(in) :: left
    
    ! right interval endpoint
    real*8, intent(in) :: right
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth
    
    ! value of spline function
    real*8 :: spline1_complete
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: spline_temp(1)
    integer :: n
    
    
    !##### ROUTINE CODE #######################################################       

    ! invert grid for every evaluation point
    if(present(growth))then       
        spline_temp = spline1_complete_m((/x/), y, left, right, growth)
    else 
        spline_temp = spline1_complete_m((/x/), y, left, right)
    endif
    
    ! paste data
    spline1_complete = spline_temp(1)
    
end function spline1_complete


!##############################################################################
! FUNCTION spline1_complete_m
! 
! Function for evaluation of one-dimensional spline, includes inverting grid
!     and interpolation method for many points.
!##############################################################################
function spline1_complete_m(x, y, left, right, growth)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(1:)
    
    ! data for spline interpolation
    real*8, intent(in) :: y(0:)
    
    ! left interval endpoint
    real*8, intent(in) :: left
    
    ! right interval endpoint
    real*8, intent(in) :: right
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth
    
    ! value of spline function
    real*8 :: spline1_complete_m(size(x, 1))
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: c(1:size(y, 1)+2)
    real*8 :: xtemp(1:size(x, 1))
    integer :: n, m, j    
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of grid-points
    n = size(y, 1)-1
    
    ! calculate number of evaluation points
    m = size(x, 1)

    ! invert grid for every evaluation point
    if(present(growth))then
        xtemp(:) = grid_Val_Inv(x(:), left, right, n, growth)        
    else 
        xtemp(:) = grid_Val_Inv(x(:), left, right, n)
    endif
    
    ! interpolate data
    call spline_interp1(y, c)
        
    ! calculate spline values at point
    do j = 1, m
        spline1_complete_m(j) = spline1(xtemp(j), c)
    enddo
    
end function spline1_complete_m


!##############################################################################
! FUNCTION spline2
! 
! Function for evaluation of two-dimensional spline.
!##############################################################################
function spline2(x, c)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(2)
    
    ! coefficients for spline interpolation
    real*8, intent(in) :: c(1:, 1:)
    
    ! value of spline function
    real*8 :: spline2
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n(2), p(2), q(2)
    integer :: j1, j2
    real*8 :: phi1, xtemp1, phi2, xtemp2
    real*8 :: s2
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of points used
    n(1) = size(c, 1)
    n(2) = size(c, 2)

    ! calculate left and right summation end point
    p = max(floor(x)+1, 1)    
    q = min(p+3, n)
  
    spline2 = 0d0

    do j1 = p(1), q(1)
  
        ! calculate value where to evaluate basis function
        xtemp1 = abs(x(1)-j1+2)
        
        ! calculate basis function
        if(xtemp1 <= 1d0)then
            phi1 = 4d0+xtemp1**2*(3d0*xtemp1-6d0)
        elseif(xtemp1 <= 2d0)then
            phi1 = (2d0-xtemp1)**3
        else
            phi1 = 0d0
        endif
        
        
        !#### calculate spline for second dimension ###########################
        
        s2 = 0d0

        do j2 = p(2), q(2)   
      
            ! calculate value where to evaluate basis function
            xtemp2 = abs(x(2)-j2+2)
            
            ! calculate basis function
            if(xtemp2 <= 1d0)then
                phi2 = 4d0+xtemp2**2*(3d0*xtemp2-6d0)
            elseif(xtemp2 <= 2d0)then
                phi2 = (2d0-xtemp2)**3
            else
                phi2 = 0d0
            endif
      
            ! calculate spline value
            s2 = s2+c(j1, j2)*phi2
        enddo
  
        ! calculate spline value
        spline2 = spline2+s2*phi1
    enddo
    
end function spline2


!##############################################################################
! FUNCTION spline2_grid
! 
! Function for evaluation of two-dimensional spline, includ inverting grid.
!##############################################################################
function spline2_grid(x, c, left, right, growth)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(2)
    
    ! coefficients for spline interpolation
    real*8, intent(in) :: c(1:, 1:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(2)
    
    ! right interval endpoint
    real*8, intent(in) :: right(2)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(2)
    
    ! value of spline function
    real*8 :: spline2_grid
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, j
    real*8 :: xtemp(2)
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of grid-points
    do j = 1, size(x, 1)
        n = size(c, j)-3

        ! invert grid
        if(present(growth))then
            xtemp(j) = grid_Val_Inv(x(j), left(j), right(j), n, growth(j))
        else 
            xtemp(j) = grid_Val_Inv(x(j), left(j), right(j), n)
        endif
    enddo
    
    ! calculate spline value
    spline2_grid = spline2(xtemp, c)
    
end function spline2_grid


!##############################################################################
! FUNCTION spline2_complete
! 
! Function for evaluation of one-dimensional spline, includes inverting grid
!     and interpolation method for a single point.
!##############################################################################
function spline2_complete(x, y, left, right, growth)


    integer, parameter :: dim = 2 

    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(dim)
    
    ! data for spline interpolation
    real*8, intent(in) :: y(0:, 0:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(dim)
    
    ! right interval endpoint
    real*8, intent(in) :: right(dim)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(dim)
    
    ! value of spline function
    real*8 :: spline2_complete
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: xtemp(1, dim)
    real*8 :: spline_temp(1)
    integer :: n
    
    
    !##### ROUTINE CODE #######################################################       

    ! set xtemp
    xtemp(1, :) = x

    ! invert grid for every evaluation point
    if(present(growth))then       
        spline_temp = spline2_complete_m(xtemp, y, left, right, growth)
    else 
        spline_temp = spline2_complete_m(xtemp, y, left, right)
    endif
    
    ! paste data
    spline2_complete = spline_temp(1)
    
end function spline2_complete


!##############################################################################
! FUNCTION spline2_complete_m
! 
! Function for evaluation of one-dimensional spline, includes inverting grid
!     and interpolation method for many points.
!##############################################################################
function spline2_complete_m(x, y, left, right, growth)    

    integer, parameter :: dim = 2

    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(1:, 1:)
    
    ! data for spline interpolation
    real*8, intent(in) :: y(0:, 0:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(dim)
    
    ! right interval endpoint
    real*8, intent(in) :: right(dim)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(dim)
    
    ! value of spline function
    real*8 :: spline2_complete_m(size(x, 1))
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: c(1:size(y, 1)+2, 1:size(y, 2)+2)
    real*8 :: xtemp(1:size(x, 1), dim)
    integer :: n, m, j, k       
    
    
    !##### ROUTINE CODE #######################################################        
    
    ! calculate number of evaluation points
    m = size(x, 1)
    
    ! check whether x has the right dimension
    n = assert_eq(size(x, 2), dim, 'spline')

    ! invert grid for every evaluation point
    if(present(growth))then
        do k = 1, dim
            ! calculate number of grid-points
            n = size(y, k)-1
            
            xtemp(:, k) = grid_Val_Inv(x(:, k), &
                    left(k), right(k), n, growth(k))
        enddo
    else 
        do k = 1, dim
            ! calculate number of grid-points
            n = size(y, k)-1
            
            xtemp(:, k) = grid_Val_Inv(x(:, k), left(k), right(k), n)
        enddo
    endif
    
    ! interpolate data
    call spline_interp2(y, c)
        
    ! calculate spline values at point
    do j = 1, m
        spline2_complete_m(j) = spline2(xtemp(j, :), c)
    enddo
    
end function spline2_complete_m


!##############################################################################
! FUNCTION spline3
! 
! Function for evaluation of three-dimensional spline.
!##############################################################################
function spline3(x, c)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(3)
    
    ! coefficients for spline interpolation
    real*8, intent(in) :: c(1:, 1:, 1:)
    
    ! value of spline function
    real*8 :: spline3
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n(3), p(3), q(3)
    integer :: j1, j2, j3
    real*8 :: phi1, xtemp1, phi2, xtemp2, phi3, xtemp3
    real*8 :: s2, s3
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of points used
    n(1) = size(c, 1)
    n(2) = size(c, 2)
    n(3) = size(c, 3)

    ! calculate left and right summation end point
    p = max(floor(x)+1, 1)    
    q = min(p+3, n)
  
    spline3 = 0d0

    do j1 = p(1), q(1)   
  
        ! calculate value where to evaluate basis function
        xtemp1 = abs(x(1)-j1+2)
        
        ! calculate basis function
        if(xtemp1 <= 1d0)then
            phi1 = 4d0+xtemp1**2*(3d0*xtemp1-6d0)
        elseif(xtemp1 <= 2d0)then
            phi1 = (2d0-xtemp1)**3
        else
            phi1 = 0d0
        endif
        
        
        !#### calculate spline for second dimension ###########################
        
        s2 = 0d0

        do j2 = p(2), q(2)
      
            ! calculate value where to evaluate basis function
            xtemp2 = abs(x(2)-j2+2)
            
            ! calculate basis function
            if(xtemp2 <= 1d0)then
                phi2 = 4d0+xtemp2**2*(3d0*xtemp2-6d0)
            elseif(xtemp2 <= 2d0)then
                phi2 = (2d0-xtemp2)**3
            else
                phi2 = 0d0
            endif
            
            
            !#### calculate spline for second dimension #######################
                                    
            s3 = 0d0

            do j3 = p(3), q(3)   
          
                ! calculate value where to evaluate basis function
                xtemp3 = abs(x(3)-j3+2)
                
                ! calculate basis function
                if(xtemp3 <= 1d0)then
                    phi3 = 4d0+xtemp3**2*(3d0*xtemp3-6d0)
                elseif(xtemp3 <= 2d0)then
                    phi3 = (2d0-xtemp3)**3
                else
                    phi3 = 0d0
                endif
          
                ! calculate spline value
                s3 = s3+c(j1, j2, j3)*phi3
            enddo
      
            ! calculate spline value
            s2 = s2+s3*phi2
        enddo
  
        ! calculate spline value
        spline3 = spline3+s2*phi1
    enddo
    
end function spline3


!##############################################################################
! FUNCTION spline3_grid
! 
! Function for evaluation of three-dimensional spline, includes inverting grid.
!##############################################################################
function spline3_grid(x, c, left, right, growth)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(3)
    
    ! coefficients for spline interpolation
    real*8, intent(in) :: c(1:, 1:, 1:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(3)
    
    ! right interval endpoint
    real*8, intent(in) :: right(3)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(3)
    
    ! value of spline function
    real*8 :: spline3_grid
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, j
    real*8 :: xtemp(3)
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of grid-points
    do j = 1, size(x, 1)
        n = size(c, j)-3

        ! invert grid
        if(present(growth))then
            xtemp(j) = grid_Val_Inv(x(j), left(j), right(j), n, growth(j))
        else 
            xtemp(j) = grid_Val_Inv(x(j), left(j), right(j), n)
        endif
    enddo
    
    ! calculate spline value
    spline3_grid = spline3(xtemp, c)
    
end function spline3_grid


!##############################################################################
! FUNCTION spline3_complete
! 
! Function for evaluation of one-dimensional spline, includes inverting grid
!     and interpolation method for a single point.
!##############################################################################
function spline3_complete(x, y, left, right, growth)


    integer, parameter :: dim = 3 

    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(dim)
    
    ! data for spline interpolation
    real*8, intent(in) :: y(0:, 0:, 0:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(dim)
    
    ! right interval endpoint
    real*8, intent(in) :: right(dim)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(dim)
    
    ! value of spline function
    real*8 :: spline3_complete
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: xtemp(1, dim)
    real*8 :: spline_temp(1)
    integer :: n
    
    
    !##### ROUTINE CODE #######################################################       

    ! set xtemp
    xtemp(1, :) = x

    ! invert grid for every evaluation point
    if(present(growth))then       
        spline_temp = spline3_complete_m(xtemp, y, left, right, growth)
    else 
        spline_temp = spline3_complete_m(xtemp, y, left, right)
    endif
    
    ! paste data
    spline3_complete = spline_temp(1)
    
end function spline3_complete


!##############################################################################
! FUNCTION spline3_complete_m
! 
! Function for evaluation of one-dimensional spline, includes inverting grid
!     and interpolation method for many points.
!##############################################################################
function spline3_complete_m(x, y, left, right, growth)    

    integer, parameter :: dim = 3 

    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(1:, 1:)
    
    ! data for spline interpolation
    real*8, intent(in) :: y(0:, 0:, 0:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(dim)
    
    ! right interval endpoint
    real*8, intent(in) :: right(dim)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(dim)
    
    ! value of spline function
    real*8 :: spline3_complete_m(size(x, 1))
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: c(1:size(y, 1)+2, 1:size(y, 2)+2, 1:size(y, 3)+2)
    real*8 :: xtemp(1:size(x, 1), dim)
    integer :: n, m, j, k       
    
    
    !##### ROUTINE CODE #######################################################        
    
    ! calculate number of evaluation points
    m = size(x, 1)
    
    ! check whether x has the right dimension
    n = assert_eq(size(x, 2), dim, 'spline')

    ! invert grid for every evaluation point
    if(present(growth))then
        do k = 1, dim
            ! calculate number of grid-points
            n = size(y, k)-1
            
            xtemp(:, k) = grid_Val_Inv(x(:, k), &
                    left(k), right(k), n, growth(k))
        enddo
    else 
        do k = 1, dim
            ! calculate number of grid-points
            n = size(y, k)-1
            
            xtemp(:, k) = grid_Val_Inv(x(:, k), left(k), right(k), n)
        enddo
    endif
    
    ! interpolate data
    call spline_interp3(y, c)
        
    ! calculate spline values at point
    do j = 1, m
        spline3_complete_m(j) = spline3(xtemp(j, :), c)
    enddo
    
end function spline3_complete_m


!##############################################################################
! FUNCTION spline4
! 
! Function for evaluation of four-dimensional spline.
!##############################################################################
function spline4(x, c)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(4)
    
    ! coefficients for spline interpolation
    real*8, intent(in) :: c(1:, 1:, 1:, 1:)
    
    ! value of spline function
    real*8 :: spline4
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, j, p, q
    real*8 :: phi, xtemp       
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of points used
    n = size(c, 1)

    ! calculate left and right summation end point
    p = max(floor(x(1))+1, 1)    
    q = min(p+3, n)
  
    spline4 = 0d0

    do j = p, q   
  
        ! calculate value where to evaluate basis function
        xtemp = abs(x(1)-j+2)
        
        ! calculate basis function
        if(xtemp <= 1d0)then
            phi = 4d0+xtemp**2*(3d0*xtemp-6d0)
        elseif(xtemp <= 2d0)then
            phi = (2d0-xtemp)**3
        else
            phi = 0d0
        endif
  
        ! calculate spline value
        spline4 = spline4+spline3(x(2:4), c(j, :, :, :))*phi
    enddo
    
end function spline4


!##############################################################################
! FUNCTION spline4_grid
! 
! Function for evaluation of four-dimensional spline, includes inverting grid.
!##############################################################################
function spline4_grid(x, c, left, right, growth)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(4)
    
    ! coefficients for spline interpolation
    real*8, intent(in) :: c(1:, 1:, 1:, 1:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(4)
    
    ! right interval endpoint
    real*8, intent(in) :: right(4)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(4)
    
    ! value of spline function
    real*8 :: spline4_grid
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, j
    real*8 :: xtemp(4)
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of grid-points
    do j = 1, size(x, 1)
        n = size(c, j)-3

        ! invert grid
        if(present(growth))then
            xtemp(j) = grid_Val_Inv(x(j), left(j), right(j), n, growth(j))
        else 
            xtemp(j) = grid_Val_Inv(x(j), left(j), right(j), n)
        endif
    enddo
    
    ! calculate spline value
    spline4_grid = spline4(xtemp, c)
    
end function spline4_grid


!##############################################################################
! FUNCTION spline4_complete
! 
! Function for evaluation of one-dimensional spline, includes inverting grid
!     and interpolation method for a single point.
!##############################################################################
function spline4_complete(x, y, left, right, growth)


    integer, parameter :: dim = 4 

    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(dim)
    
    ! data for spline interpolation
    real*8, intent(in) :: y(0:, 0:, 0:, 0:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(dim)
    
    ! right interval endpoint
    real*8, intent(in) :: right(dim)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(dim)
    
    ! value of spline function
    real*8 :: spline4_complete
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: xtemp(1, dim)
    real*8 :: spline_temp(1)
    integer :: n
    
    
    !##### ROUTINE CODE #######################################################       

    ! set xtemp
    xtemp(1, :) = x

    ! invert grid for every evaluation point
    if(present(growth))then       
        spline_temp = spline4_complete_m(xtemp, y, left, right, growth)
    else 
        spline_temp = spline4_complete_m(xtemp, y, left, right)
    endif
    
    ! paste data
    spline4_complete = spline_temp(1)
    
end function spline4_complete


!##############################################################################
! FUNCTION spline4_complete_m
! 
! Function for evaluation of one-dimensional spline, includes inverting grid
!     and interpolation method for many points.
!##############################################################################
function spline4_complete_m(x, y, left, right, growth)    

    integer, parameter :: dim = 4 

    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(1:, 1:)
    
    ! data for spline interpolation
    real*8, intent(in) :: y(0:, 0:, 0:, 0:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(dim)
    
    ! right interval endpoint
    real*8, intent(in) :: right(dim)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(dim)
    
    ! value of spline function
    real*8 :: spline4_complete_m(size(x, 1))
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: c(1:size(y, 1)+2, 1:size(y, 2)+2, 1:size(y, 3)+2, &
        1:size(y, 4)+2)
    real*8 :: xtemp(1:size(x, 1), dim)
    integer :: n, m, j, k       
    
    
    !##### ROUTINE CODE #######################################################        
    
    ! calculate number of evaluation points
    m = size(x, 1)
    
    ! check whether x has the right dimension
    n = assert_eq(size(x, 2), dim, 'spline')

    ! invert grid for every evaluation point
    if(present(growth))then
        do k = 1, dim
            ! calculate number of grid-points
            n = size(y, k)-1
            
            xtemp(:, k) = grid_Val_Inv(x(:, k), &
                    left(k), right(k), n, growth(k))
        enddo
    else 
        do k = 1, dim
            ! calculate number of grid-points
            n = size(y, k)-1
            
            xtemp(:, k) = grid_Val_Inv(x(:, k), left(k), right(k), n)
        enddo
    endif
    
    ! interpolate data
    call spline_interp4(y, c)
        
    ! calculate spline values at point
    do j = 1, m
        spline4_complete_m(j) = spline4(xtemp(j, :), c)
    enddo
    
end function spline4_complete_m


!##############################################################################
! FUNCTION spline5
! 
! Function for evaluation of five-dimensional spline.
!##############################################################################
function spline5(x, c)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(5)
    
    ! coefficients for spline interpolation
    real*8, intent(in) :: c(1:, 1:, 1:, 1:, 1:)
    
    ! value of spline function
    real*8 :: spline5
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, j, p, q
    real*8 :: phi, xtemp       
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of points used
    n = size(c, 1)

    ! calculate left and right summation end point
    p = max(floor(x(1))+1, 1)    
    q = min(p+3, n)
  
    spline5 = 0d0

    do j = p, q   
  
        ! calculate value where to evaluate basis function
        xtemp = abs(x(1)-j+2)
        
        ! calculate basis function
        if(xtemp <= 1d0)then
            phi = 4d0+xtemp**2*(3d0*xtemp-6d0)
        elseif(xtemp <= 2d0)then
            phi = (2d0-xtemp)**3
        else
            phi = 0d0
        endif
  
        ! calculate spline value
        spline5 = spline5+spline4(x(2:5), c(j, :, :, :, :))*phi
    enddo
    
end function spline5


!##############################################################################
! FUNCTION spline5_grid
! 
! Function for evaluation of five-dimensional spline, includes inverting grid.
!##############################################################################
function spline5_grid(x, c, left, right, growth)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(5)
    
    ! coefficients for spline interpolation
    real*8, intent(in) :: c(1:, 1:, 1:, 1:, 1:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(5)
    
    ! right interval endpoint
    real*8, intent(in) :: right(5)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(5)
    
    ! value of spline function
    real*8 :: spline5_grid
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, j
    real*8 :: xtemp(5)
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of grid-points
    do j = 1, size(x, 1)
        n = size(c, j)-3

        ! invert grid
        if(present(growth))then
            xtemp(j) = grid_Val_Inv(x(j), left(j), right(j), n, growth(j))
        else 
            xtemp(j) = grid_Val_Inv(x(j), left(j), right(j), n)
        endif
    enddo
    
    ! calculate spline value
    spline5_grid = spline5(xtemp, c)
    
end function spline5_grid


!##############################################################################
! FUNCTION spline5_complete
! 
! Function for evaluation of one-dimensional spline, includes inverting grid
!     and interpolation method for a single point.
!##############################################################################
function spline5_complete(x, y, left, right, growth)


    integer, parameter :: dim = 5 

    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(dim)
    
    ! data for spline interpolation
    real*8, intent(in) :: y(0:, 0:, 0:, 0:, 0:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(dim)
    
    ! right interval endpoint
    real*8, intent(in) :: right(dim)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(dim)
    
    ! value of spline function
    real*8 :: spline5_complete
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: xtemp(1, dim)
    real*8 :: spline_temp(1)
    integer :: n
    
    
    !##### ROUTINE CODE #######################################################       

    ! set xtemp
    xtemp(1, :) = x

    ! invert grid for every evaluation point
    if(present(growth))then       
        spline_temp = spline5_complete_m(xtemp, y, left, right, growth)
    else 
        spline_temp = spline5_complete_m(xtemp, y, left, right)
    endif
    
    ! paste data
    spline5_complete = spline_temp(1)
    
end function spline5_complete


!##############################################################################
! FUNCTION spline5_complete_m
! 
! Function for evaluation of one-dimensional spline, includes inverting grid
!     and interpolation method for many points.
!##############################################################################
function spline5_complete_m(x, y, left, right, growth)    

    integer, parameter :: dim = 5 

    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(1:, 1:)
    
    ! data for spline interpolation
    real*8, intent(in) :: y(0:, 0:, 0:, 0:, 0:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(dim)
    
    ! right interval endpoint
    real*8, intent(in) :: right(dim)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(dim)
    
    ! value of spline function
    real*8 :: spline5_complete_m(size(x, 1))
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: c(1:size(y, 1)+2, 1:size(y, 2)+2, 1:size(y, 3)+2, &
        1:size(y, 4)+2, 1:size(y, 5)+2)
    real*8 :: xtemp(1:size(x, 1), dim)
    integer :: n, m, j, k       
    
    
    !##### ROUTINE CODE #######################################################        
    
    ! calculate number of evaluation points
    m = size(x, 1)
    
    ! check whether x has the right dimension
    n = assert_eq(size(x, 2), dim, 'spline')

    ! invert grid for every evaluation point
    if(present(growth))then
        do k = 1, dim
            ! calculate number of grid-points
            n = size(y, k)-1
            
            xtemp(:, k) = grid_Val_Inv(x(:, k), &
                    left(k), right(k), n, growth(k))
        enddo
    else 
        do k = 1, dim
            ! calculate number of grid-points
            n = size(y, k)-1
            
            xtemp(:, k) = grid_Val_Inv(x(:, k), left(k), right(k), n)
        enddo
    endif
    
    ! interpolate data
    call spline_interp5(y, c)
        
    ! calculate spline values at point
    do j = 1, m
        spline5_complete_m(j) = spline5(xtemp(j, :), c)
    enddo
    
end function spline5_complete_m


!##############################################################################
! FUNCTION spline6
! 
! Function for evaluation of six-dimensional spline.
!##############################################################################
function spline6(x, c)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(6)
    
    ! coefficients for spline interpolation
    real*8, intent(in) :: c(1:, 1:, 1:, 1:, 1:, 1:)
    
    ! value of spline function
    real*8 :: spline6
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, j, p, q
    real*8 :: phi, xtemp       
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of points used
    n = size(c, 1)

    ! calculate left and right summation end point
    p = max(floor(x(1))+1, 1)    
    q = min(p+3, n)
  
    spline6 = 0d0

    do j = p, q   
  
        ! calculate value where to evaluate basis function
        xtemp = abs(x(1)-j+2)
        
        ! calculate basis function
        if(xtemp <= 1d0)then
            phi = 4d0+xtemp**2*(3d0*xtemp-6d0)
        elseif(xtemp <= 2d0)then
            phi = (2d0-xtemp)**3
        else
            phi = 0d0
        endif
  
        ! calculate spline value
        spline6 = spline6+spline5(x(2:6), c(j, :, :, :, :, :))*phi
    enddo
    
end function spline6


!##############################################################################
! FUNCTION spline6_grid
! 
! Function for evaluation of six-dimensional spline, includes inverting grid.
!##############################################################################
function spline6_grid(x, c, left, right, growth)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(6)
    
    ! coefficients for spline interpolation
    real*8, intent(in) :: c(1:, 1:, 1:, 1:, 1:, 1:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(6)
    
    ! right interval endpoint
    real*8, intent(in) :: right(6)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(6)
    
    ! value of spline function
    real*8 :: spline6_grid
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, j
    real*8 :: xtemp(6)
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of grid-points
    do j = 1, size(x, 1)
        n = size(c, j)-3

        ! invert grid
        if(present(growth))then
            xtemp(j) = grid_Val_Inv(x(j), left(j), right(j), n, growth(j))
        else 
            xtemp(j) = grid_Val_Inv(x(j), left(j), right(j), n)
        endif
    enddo
    
    ! calculate spline value
    spline6_grid = spline6(xtemp, c)
    
end function spline6_grid


!##############################################################################
! FUNCTION spline6_complete
! 
! Function for evaluation of one-dimensional spline, includes inverting grid
!     and interpolation method for a single point.
!##############################################################################
function spline6_complete(x, y, left, right, growth)


    integer, parameter :: dim = 6

    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(dim)
    
    ! data for spline interpolation
    real*8, intent(in) :: y(0:, 0:, 0:, 0:, 0:, 0:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(dim)
    
    ! right interval endpoint
    real*8, intent(in) :: right(dim)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(dim)
    
    ! value of spline function
    real*8 :: spline6_complete
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: xtemp(1, dim)
    real*8 :: spline_temp(1)
    integer :: n
    
    
    !##### ROUTINE CODE #######################################################       

    ! set xtemp
    xtemp(1, :) = x

    ! invert grid for every evaluation point
    if(present(growth))then       
        spline_temp = spline6_complete_m(xtemp, y, left, right, growth)
    else 
        spline_temp = spline6_complete_m(xtemp, y, left, right)
    endif
    
    ! paste data
    spline6_complete = spline_temp(1)
    
end function spline6_complete


!##############################################################################
! FUNCTION spline6_complete_m
! 
! Function for evaluation of one-dimensional spline, includes inverting grid
!     and interpolation method for many points.
!##############################################################################
function spline6_complete_m(x, y, left, right, growth)    

    integer, parameter :: dim = 6 

    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(1:, 1:)
    
    ! data for spline interpolation
    real*8, intent(in) :: y(0:, 0:, 0:, 0:, 0:, 0:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(dim)
    
    ! right interval endpoint
    real*8, intent(in) :: right(dim)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(dim)
    
    ! value of spline function
    real*8 :: spline6_complete_m(size(x, 1))
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: c(1:size(y, 1)+2, 1:size(y, 2)+2, 1:size(y, 3)+2, &
        1:size(y, 4)+2, 1:size(y, 5)+2, 1:size(y, 6)+2)
    real*8 :: xtemp(1:size(x, 1), dim)
    integer :: n, m, j, k       
    
    
    !##### ROUTINE CODE #######################################################        
    
    ! calculate number of evaluation points
    m = size(x, 1)
    
    ! check whether x has the right dimension
    n = assert_eq(size(x, 2), dim, 'spline')

    ! invert grid for every evaluation point
    if(present(growth))then
        do k = 1, dim
            ! calculate number of grid-points
            n = size(y, k)-1
            
            xtemp(:, k) = grid_Val_Inv(x(:, k), &
                    left(k), right(k), n, growth(k))
        enddo
    else 
        do k = 1, dim
            ! calculate number of grid-points
            n = size(y, k)-1
            
            xtemp(:, k) = grid_Val_Inv(x(:, k), left(k), right(k), n)
        enddo
    endif
    
    ! interpolate data
    call spline_interp6(y, c)
        
    ! calculate spline values at point
    do j = 1, m
        spline6_complete_m(j) = spline6(xtemp(j, :), c)
    enddo
    
end function spline6_complete_m


!##############################################################################
! FUNCTION spline7
! 
! Function for evaluation of seven-dimensional spline.
!##############################################################################
function spline7(x, c)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(7)
    
    ! coefficients for spline interpolation
    real*8, intent(in) :: c(1:, 1:, 1:, 1:, 1:, 1:, 1:)
    
    ! value of spline function
    real*8 :: spline7
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, j, p, q
    real*8 :: phi, xtemp       
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of points used
    n = size(c, 1)

    ! calculate left and right summation end point
    p = max(floor(x(1))+1, 1)    
    q = min(p+3, n)
  
    spline7 = 0d0

    do j = p, q   
  
        ! calculate value where to evaluate basis function
        xtemp = abs(x(1)-j+2)
        
        ! calculate basis function
        if(xtemp <= 1d0)then
            phi = 4d0+xtemp**2*(3d0*xtemp-6d0)
        elseif(xtemp <= 2d0)then
            phi = (2d0-xtemp)**3
        else
            phi = 0d0
        endif
  
        ! calculate spline value
        spline7 = spline7+spline6(x(2:7), c(j, :, :, :, :, :, :))*phi
    enddo
    
end function spline7


!##############################################################################
! FUNCTION spline7_grid
! 
! Function for evaluation of seven-dimensional spline, includes inverting grid.
!##############################################################################
function spline7_grid(x, c, left, right, growth)


    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(7)
    
    ! coefficients for spline interpolation
    real*8, intent(in) :: c(1:, 1:, 1:, 1:, 1:, 1:, 1:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(7)
    
    ! right interval endpoint
    real*8, intent(in) :: right(7)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(7)
    
    ! value of spline function
    real*8 :: spline7_grid
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, j
    real*8 :: xtemp(7)
    
    
    !##### ROUTINE CODE #######################################################
    
    ! calculate number of grid-points
    do j = 1, size(x, 1)
        n = size(c, j)-3

        ! invert grid
        if(present(growth))then
            xtemp(j) = grid_Val_Inv(x(j), left(j), right(j), n, growth(j))
        else 
            xtemp(j) = grid_Val_Inv(x(j), left(j), right(j), n)
        endif
    enddo
    
    ! calculate spline value
    spline7_grid = spline7(xtemp, c)
    
end function spline7_grid


!##############################################################################
! FUNCTION spline7_complete
! 
! Function for evaluation of one-dimensional spline, includes inverting grid
!     and interpolation method for a single point.
!##############################################################################
function spline7_complete(x, y, left, right, growth)


    integer, parameter :: dim = 7

    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(dim)
    
    ! data for spline interpolation
    real*8, intent(in) :: y(0:, 0:, 0:, 0:, 0:, 0:, 0:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(dim)
    
    ! right interval endpoint
    real*8, intent(in) :: right(dim)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(dim)
    
    ! value of spline function
    real*8 :: spline7_complete
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: xtemp(1, dim)
    real*8 :: spline_temp(1)
    integer :: n
    
    
    !##### ROUTINE CODE #######################################################       

    ! set xtemp
    xtemp(1, :) = x

    ! invert grid for every evaluation point
    if(present(growth))then       
        spline_temp = spline7_complete_m(xtemp, y, left, right, growth)
    else 
        spline_temp = spline7_complete_m(xtemp, y, left, right)
    endif
    
    ! paste data
    spline7_complete = spline_temp(1)
    
end function spline7_complete


!##############################################################################
! FUNCTION spline7_complete_m
! 
! Function for evaluation of one-dimensional spline, includes inverting grid
!     and interpolation method for many points.
!##############################################################################
function spline7_complete_m(x, y, left, right, growth)    

    integer, parameter :: dim = 7

    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! value where to evaluate spline
    real*8, intent(in) :: x(1:, 1:)
    
    ! data for spline interpolation
    real*8, intent(in) :: y(0:, 0:, 0:, 0:, 0:, 0:, 0:)
    
    ! left interval endpoint
    real*8, intent(in) :: left(dim)
    
    ! right interval endpoint
    real*8, intent(in) :: right(dim)
    
    ! growth rate of grid
    real*8, intent(in), optional :: growth(dim)
    
    ! value of spline function
    real*8 :: spline7_complete_m(size(x, 1))
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: c(1:size(y, 1)+2, 1:size(y, 2)+2, 1:size(y, 3)+2, &
        1:size(y, 4)+2, 1:size(y, 5)+2, 1:size(y, 6)+2, 1:size(y, 7)+2)
    real*8 :: xtemp(1:size(x, 1), dim)
    integer :: n, m, j, k       
    
    
    !##### ROUTINE CODE #######################################################        
    
    ! calculate number of evaluation points
    m = size(x, 1)
    
    ! check whether x has the right dimension
    n = assert_eq(size(x, 2), dim, 'spline')

    ! invert grid for every evaluation point
    if(present(growth))then
        do k = 1, dim
            ! calculate number of grid-points
            n = size(y, k)-1
            
            xtemp(:, k) = grid_Val_Inv(x(:, k), &
                    left(k), right(k), n, growth(k))
        enddo
    else 
        do k = 1, dim
            ! calculate number of grid-points
            n = size(y, k)-1
            
            xtemp(:, k) = grid_Val_Inv(x(:, k), left(k), right(k), n)
        enddo
    endif
    
    ! interpolate data
    call spline_interp7(y, c)
        
    ! calculate spline values at point
    do j = 1, m
        spline7_complete_m(j) = spline7(xtemp(j, :), c)
    enddo
    
end function spline7_complete_m


end module splines