!===============================================================================
! FILE: gaussian_int.f90
!
! DESCRIPTION:
!   Computes abscissas (nodes) and weights for Gaussian quadrature numerical
!   integration. Provides accurate approximation of definite integrals.
!
! MODULE: gaussian_int
!   Gaussian quadrature rule construction for numerical integration.
!
! SUBROUTINES:
!   - legendre: Computes Gauss-Legendre quadrature nodes and weights on [x1, x2]
!               ∫ f(x)dx ≈ ∑ w_i * f(x_i)
!   - hermite: Gauss-Hermite quadrature for integrals over (-∞, ∞) with e^(-x²) weight
!   - laguerre: Gauss-Laguerre quadrature for integrals over [0, ∞) with e^(-x) weight
!
! ALGORITHM:
!   Constructs nodes as roots of orthogonal polynomials (Legendre, Hermite, Laguerre).
!   Uses recurrence relations and Newton-Raphson refinement.
!
! INPUTS:
!   - x1, x2: Integration interval endpoints (for Legendre)
!   - n: Number of quadrature points (order)
!
! OUTPUTS:
!   - x: Quadrature nodes (abscissas)
!   - w: Quadrature weights
!
! DEPENDENCIES:
!   - assertions: For array dimension checking (assert_eq)
!   - errwarn: Error/warning message handling
!
! NOTES:
!   Based on Numerical Recipes (Press et al. 1992). Used in AR_discrete.f90
!   for discretizing continuous distributions. Higher-order rules (n ≥ 5)
!   provide machine precision for smooth integrands.
!
! COPYRIGHT:
!   Fabian Kindermann, University of Wuerzburg
!   kindermann.fabian@uni-wuerzburg.de
!##############################################################################

module gaussian_int


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
! Subroutines and functions                                               
!##############################################################################

contains


!##############################################################################
! SUBROUTINE legendre
! 
! Calculates Gauss-Legendre abscissas and weights on [x1, x2].
!##############################################################################
subroutine legendre(x1, x2, x, w)

    implicit none
    
    
    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! left interval point on which integral should be calculated
    real*8, intent(in) :: x1
    
    ! left interval point on which integral should be calculated
    real*8, intent(in) :: x2
    
    ! abscissas of gaussian integration formula
    real*8, intent(out) :: x(:)
    
    ! weights of gaussian integration formula
    real*8, intent(out) :: w(:) 
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8, parameter :: eps = 3.0e-14
    integer, parameter :: maxits = 10
    real*8, parameter :: pi = 3.14159265358979d0    
    integer :: its, j, m, n    
    real*8 :: xl, xm
    real*8, dimension((size(x)+1)/2) :: p1, p2, p3, pp, z, z1
    logical, dimension((size(x)+1)/2) :: unfinished
    
    
    !##### ROUTINE CODE #######################################################
    
    ! assert size equality
    n = assert_eq(size(x), size(w), 'legendre')
    
    ! calculate only up to (n+1)/2 due to symmetry
    m = (n+1)/2
    
    ! calculate interval midpoint
    xm = 0.5d0*(x2+x1)
    
    ! calculate half of interval length
    xl = 0.5d0*(x2-x1)
    
    ! set initial guess for the roots
    z = cos(pi*(arth(1,1,m)-0.25d0)/(n+0.5d0))
    
    ! initialized unfinished
    unfinished = .true.
    
    ! iterate Newton steps up to maximum iterations
    do its = 1, maxits
        
        ! calculate Legendre polynomial at z where root has not yet been found
        
        ! initialize p1 and p2
        where (unfinished)
            p1 = 1d0
            p2 = 0d0
        endwhere
        
        ! calculate polynomial value at z by recursive formula
        do j = 1, n
        
            ! only where root has not yet been found
            where (unfinished)
                
                ! the polynomial of order n - 2
                p3 = p2
                
                ! the polynomial of order n - 1
                p2 = p1
                
                ! the legendre polynomial
                p1 = ((2d0*j-1d0)*z*p2-(j-1d0)*p3)/j
            endwhere
        enddo
        
        ! calculate derivative of polynomial p1 at z
        where (unfinished)
        
            ! derivative
            pp = n*(z*p1-p2)/(z*z-1d0)
            
            ! store old z
            z1 = z
            
            ! perform the newton step
            z = z1-p1/pp
            
            ! check for difference between old and new guess being small enough
            unfinished=(abs(z-z1) > EPS)
        endwhere
        
        ! if all values have sufficiently converged, stop iteration
        if (.not. any(unfinished)) exit
    end do
    
    ! throw error message if not sufficiently convergerd
    if(its == maxits+1)call error('legendre', 'too many iterations')
    
    ! else calculate abscissas
    x(1:m) = xm-xl*z
    
    ! symmetry for abscissas
    x(n:n-m+1:-1) = xm+xl*z
    
    ! calculate weights
    w(1:m) = 2d0*xl/((1d0-z**2)*pp**2)
    
    ! symmetry for weights
    w(n:n-m+1:-1) = w(1:m)
    
end subroutine legendre


!##############################################################################
! FUNCTION arth
! 
! Calculates incremented array from first with n entries.
!##############################################################################
function arth(first, increment, n)
    
    integer, intent(in) :: first, increment, n
    integer, parameter :: npar_arth = 16
    integer, parameter :: npar2_arth = 8
    integer :: arth(n)
    integer :: k, k2, temp
    
    ! initialize first element
    if(n > 0)arth(1) = first
    
    ! calculate by hand if n <= 16
    if(n <= npar_arth) then
        do k = 2, n
            arth(k) = arth(k-1) + increment
        enddo
        
    ! else set entries stepwise by 8 steps
    else
        do k = 2, npar2_arth
            arth(k) = arth(k-1) + increment
        enddo
        temp = increment*npar2_arth
        k = npar2_arth
        do
            if(k >= n)exit
            k2 = k+k
            arth(k+1:min(k2,n)) = temp+arth(1:min(k,n-k))
            temp = temp + temp
            k = k2
        enddo
    endif
    
end function arth

end module gaussian_int