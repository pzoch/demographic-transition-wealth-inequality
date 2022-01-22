!##############################################################################
! MODULE AR_discrete
! 
! For discretizing autoregressive processes using the Rouwenhorst method
!     as described in Kopecky and Suen (2010).
!
! copyright: Fabian Kindermann
!            University of Wuerzburg
!            kindermann.fabian@uni-wuerzburg.de
!##############################################################################

module AR_discrete


!##############################################################################
! Declaration of modules used
!##############################################################################

! for assertion of equality in dimensions
use assertions, only: assert_eq

! for throwing error and warning messages
use errwarn

! for calculating normal probabilities
use normalProb

! for numerical integration
use gaussian_int, only: legendre

implicit none

save


!##############################################################################
! Subroutines and functions                                               
!##############################################################################

contains


!##############################################################################
! SUBROUTINE discretize_AR
! 
! Discretizes an AR(1) process of the form z_j = \rho*z_{j-1} + eps.
!##############################################################################
subroutine discretize_AR(rho, mu, sigma_eps, z, pi, w)

    implicit none
    
    
    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! autoregression parameter
    real*8, intent(in) :: rho
    
    ! unconditional mean of the process
    real*8, intent(in) :: mu
    
    ! variance of the shock
    real*8, intent(in) :: sigma_eps
    
    ! discrete shock values
    real*8, intent(out) :: z(:)
    
    ! transition matrix
    real*8, intent(out) :: pi(:, :)

    ! the stationary distribution
    real*8, intent(out), optional :: w(:)
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: n, in
    real*8 :: psi, sigma_eta
    
    
    !##### ROUTINE CODE #######################################################
            
    ! assert size equality and get approximation points
    n = assert_eq(size(z), size(pi,1), size(pi,2), 'tauchen')
    
    ! calculate variance of the overall process
    sigma_eta = sigma_eps/(1d0-rho**2)
    
    ! determine the transition matrix
    call rouwenhorst_matrix(rho, pi)
    
    ! determine the nodes
    psi = sqrt(dble(n-1))*sqrt(sigma_eta)
    do in = 1, n
        z(in) = -psi + 2d0*psi*dble(in-1)/dble(n-1)
    enddo
    z = z + mu
    
    if(present(w))then
        w = 1d0/dble(n)
        do in = 1, 10000
            w = matmul(transpose(pi), w)
        enddo
    endif
    
    !##########################################################################
    ! Subroutines and functions                                               
    !##########################################################################
    
    contains
    
    
    !##########################################################################
    ! subroutine rouwenhorst_matrix
    ! 
    ! Calculates value of function that should be integrated for pis.
    !##########################################################################
    recursive subroutine rouwenhorst_matrix(rho, pi_new)

        implicit none
        real*8, intent(in) :: rho
        real*8, intent(out) :: pi_new(:, :)
        integer :: n
        real*8 :: p, pi_old(size(pi_new,1)-1, size(pi_new,1)-1)
        
        n = size(pi_new, 1)
        p = (1d0 + rho)/2d0
        
        if(n == 2)then
            pi_new(1, :) = (/p, 1d0-p/)
            pi_new(2, :) = (/1d0-p, p/)
        else
            call rouwenhorst_matrix(rho, pi_old)
            pi_new = 0d0
            
            pi_new(1:n-1, 1:n-1) = pi_new(1:n-1, 1:n-1) + p*pi_old
            pi_new(1:n-1, 2:n  ) = pi_new(1:n-1, 2:n  ) + (1d0-p)*pi_old
            pi_new(2:n  , 1:n-1) = pi_new(2:n  , 1:n-1) + (1d0-p)*pi_old
            pi_new(2:n  , 2:n  ) = pi_new(2:n  , 2:n  ) + p*pi_old
            
            pi_new(2:n-1, :) = pi_new(2:n-1, :)/2d0
        endif
    end subroutine
    
end subroutine discretize_AR


!##############################################################################
! SUBROUTINE simulate_AR
! 
! Simulates a discrete AR(1) process.
!##############################################################################
subroutine simulate_AR(pi, shocks)

    implicit none
    
    
    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! transition matrix
    real*8, intent(in) :: pi(:, :) 
    
    ! simulated schocks
    integer, intent(out) :: shocks(:)
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: T, n, j
    
    
    !##### ROUTINE CODE #######################################################
            
    ! assert size equality and get number of simulated schocks
    n = assert_eq(size(pi,1), size(pi,2), 'tauchen')
    T = size(shocks)
        
    ! call random seed
    call random_seed()
    
    ! get first entry
    shocks(1) = n/2+1

    ! now calculate other shocks
    do j = 2, T
        shocks(j) = get_tomorrow(pi(shocks(j-1), :))
    enddo
    

    !##########################################################################
    ! Subroutines and functions                                               
    !##########################################################################
    
    contains
    
    
    !##########################################################################
    ! FUNCTION get_tomorrow
    ! 
    ! Calculates value of function that should be integrated for pis.
    !##########################################################################
    function get_tomorrow(pi)
    
        implicit none
    
        
        !##### INPUT/OUTPUT VARIABLES #########################################
        
        ! transition probabilities
        real*8, intent(in) :: pi(:)
        
        ! tomorrows shock
        integer :: get_tomorrow
        
        
        !##### OTHER VARIABLES ################################################
            
        real*8 :: rand
        integer :: i1
    
    
        !##### ROUTINE CODE ###################################################
        
        ! get random number
        call random_number(rand)
        
        ! get tomorrows value
        do i1 = 1, size(pi, 1)-1
            
            if(rand <= sum(pi(1:i1), 1))then    
                get_tomorrow = i1
                return
            endif
        enddo
        
        ! else choose last value
        get_tomorrow = i1
        return
        
    end function
    
end subroutine simulate_AR

end module AR_discrete