!##############################################################################
! MODULE normalProb
! 
! Module for calculation of (cumulated) normal density function.
!
! copyright: Fabian Kindermann
!            University of Wuerzburg
!            kindermann.fabian@uni-wuerzburg.de
!
! normal_discrete is taken from:
!     Miranda and Fackler (1992): "Applied Computational Economics and 
!     Finance", MIT Press, 2002.
!##############################################################################
module normalProb


!##############################################################################
! Declaration of modules used
!##############################################################################

! for throwing error and warning messages
use errwarn

! for asserting array sizes
use assertions

implicit none

save


!##############################################################################
! Variable declaration
!##############################################################################

! coefficients for normal distribution
real*8, private :: nCoeffs(503)

! coefficients for inverse normal distribution
real*8, private :: iCoeffs(503)

! derivative of normal cdf at 5
real*8, private :: derNormal

! derivative of inverse normal cdf at 0.999999
real*8, private :: derNormalInv

! is normal distribution loaded
logical, private :: normal_loaded = .false.


!##############################################################################
! Interface declarations
!##############################################################################


!##############################################################################
! INTERFACE normal_discrete
! 
! Discretizes normal distribution.
!##############################################################################
interface normal_discrete

    ! define methods used
    module procedure normal_discrete_1, normal_discrete_2
        
end interface

interface log_normal_discrete

    ! define methods used
    module procedure log_normal_discrete_1, log_normal_discrete_2
        
end interface


interface simulate_uniform

    ! define methods used
    module procedure simulate_uniform_1, simulate_uniform_n
        
end interface


interface simulate_normal

    ! define methods used
    module procedure simulate_normal_1, simulate_normal_n
        
end interface

interface simulate_log_normal

    ! define methods used
    module procedure simulate_log_normal_1, simulate_log_normal_n
        
end interface

contains


!##############################################################################
! FUNCTION normalCDF
! 
! Calculates cumulated normal distribution at point p.
!##############################################################################
function normalCDF(p, mu, sigma)

    implicit none


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! point where to calculate function
    real*8, intent(in) :: p
    
    ! expectation of distribution
    real*8, optional :: mu
    
    ! variance of distribution
    real*8, optional :: sigma
    
    ! value of the spline function at p
    real*8 :: normalCDF
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: ptrans, ptemp, t, phi, mu_c, sigma_c
    integer :: l, r, k    
    
    
    !##### ROUTINE CODE #######################################################
    
    ! test whether normal distribution was loaded
    if(.not. normal_loaded)call loadNormal()

    ! initialize expectation and variance
    mu_c = 0d0
    if(present(mu))mu_c = mu
    sigma_c = 1d0
    if(present(sigma))sigma_c = sigma

    ! standardize evaluation point
    ptrans = (p - mu_c)/sqrt(sigma_c)
    
    ! map to right side if ptemp < 0
    if(ptrans < 0) ptrans = -ptrans
    
    ! store ptrans for other calculations
    ptemp = ptrans    
    
    ! restrict evaluation point to interpolation interval
    ptemp = max(ptemp, 0d0)
    ptemp = min(ptemp, 5d0)
    
    ptemp = (ptemp - 0d0) / 0.01d0

    ! set up left and right calculation end point
    l = floor(ptemp) + 1
    r = min(l + 3, 503)

    normalCDF = 0d0

    do k = l, r

        ! set up point where to evaluate phi function
        t = abs(ptemp - k + 2)
        
        ! calculate spline function
        if(t < 1d0)then
            phi = 4d0 + t**2d0 * (3d0 * t - 6d0)
        elseif(t <= 2d0)then
            phi = (2d0 - t)**3d0
        else
            phi = 0d0
        endif        
        
        ! calculate final spline value
        normalCDF = normalCDF + nCoeffs(k) * phi
    enddo    
    
    ! extrapolate if ptrans > 5
    if(ptrans > 5d0) then
        normalCDF = normalCDF + derNormal * (ptrans - 5d0)
        normalCDF = min(normalCDF, 1d0)
    endif
    
    ! again invert if ptemp was < 0
    if(p - mu_c < 0d0) normalCDF = 1d0 - normalCDF

end function normalCDF


!##############################################################################
! FUNCTION normalPDF
! 
! Calculates normal density functions at point p.
!##############################################################################
function normalPDF(p, mu, sigma)

    implicit none


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! point where to calculate function
    real*8, intent(in) :: p
    
    ! expectation of distribution
    real*8, optional :: mu
    
    ! variance of distribution
    real*8, optional :: sigma 
    
    ! value of normal density at p
    real*8 :: normalPDF
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: mu_c, sigma_c
    real*8, parameter :: pi = 3.1415926535897d0
    
    
    !##### ROUTINE CODE #######################################################

    ! initialize expectation and variance
    mu_c = 0d0
    if(present(mu))mu_c = mu
    sigma_c = 1d0
    if(present(sigma))sigma_c = sqrt(sigma)
    
    normalPDF = 1/(sigma_c*sqrt(2*pi))*exp(-((p-mu_c)/sigma_c)**2/2)
    
end function normalPDF


!##############################################################################
! FUNCTION normalCDF_Inv
! 
! Calculates inverse cumulated normal distribution at point p.
!##############################################################################
function normalCDF_Inv(p, mu, sigma)

    implicit none


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! point where to calculate function
    real*8 :: p
    
    ! expectation of distribution
    real*8, optional :: mu
    
    ! variance of distribution
    real*8, optional :: sigma
    
    ! value of the spline function at p
    real*8 :: normalCDF_Inv
    
    
    !##### OTHER VARIABLES ####################################################
        
    real*8 :: ptemp, t, phi, mu_c, sigma_c            
    integer :: l, r, k        
    
    
    !##### ROUTINE CODE #######################################################

    ! test whether normal distribution was loaded
    if(.not. normal_loaded)call loadNormal()

    ! initialize expectation and variance
    mu_c = 0d0
    if(present(mu))mu_c = mu
    sigma_c = 1d0
    if(present(sigma))sigma_c = sqrt(sigma)

    ! store for further calculations
    ptemp = p
    
    ! map to right side if ptemp < 0.5
    if(ptemp < 0.5d0) ptemp = 1d0 - ptemp
    
    ! restrict evaluation point to interpolation interval
    ptemp = max(ptemp, 0.5d0)
    ptemp = min(ptemp, 0.999999713348428d0)
    
    ptemp = (ptemp - 0.5d0) / (0.999999713348428d0 - 0.5d0) * 500d0

    ! set up left and right calculation end point
    l = floor(ptemp) + 1
    r = min(l + 3, 503)

    normalCDF_Inv = 0d0

    do k = l, r

        ! set up point where to evaluate phi function
        t = abs(ptemp - k + 2)
        
        ! calculate spline function
        if(t < 1d0)then
            phi = 4d0 + t**2d0 * (3d0 * t - 6d0)
        elseif(t <= 2d0)then
            phi = (2d0 - t)**3d0
        else
            phi = 0d0
        endif        
        
        ! calculate final spline value
        normalCDF_Inv = normalCDF_Inv + iCoeffs(k) * phi
    enddo    
    
    ! extrapolate if ptrans > 4
    if(p > 0.999999713348428d0) then
        normalCDF_Inv = normalCDF_Inv + derNormalInv * (p - 0.999999713348428d0)
    endif
    
    ! again invert if ptemp was < 0
    if(p < 0.5d0) normalCDF_Inv = - normalCDF_Inv
    
    ! transfer to mu and sigma
    normalCDF_Inv = mu_c + sigma_c*normalCDF_Inv

end function normalCDF_Inv


!##############################################################################
! SUBROUTINE simulate_uniform_1
! 
! Simulates one draw from a uniform distribution.
!##############################################################################
subroutine simulate_uniform_1(x, a, b)

    implicit none


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! point into which the draw should be saved
    real*8, intent(out) :: x

    ! left end of the distribution
    real*8, optional :: a
    
    ! right end of the distribution
    real*8, optional :: b


    !##### OTHER VARIABLES ####################################################
        
    real*8 :: a_c, b_c
    
    
    !##### ROUTINE CODE #######################################################

    ! initialize expectation and variance
    a_c = 0d0
    if(present(a))a_c = a
    b_c = 1d0
    if(present(b))b_c = b

    ! set the random seed
    call random_seed()

    ! draw the random number
    call random_number(x)

    x = a_c + (b_c-a_c)*x
    
end subroutine simulate_uniform_1


!##############################################################################
! SUBROUTINE simulate_uniform_n
! 
! Simulates a series draw from a uniform distribution.
!##############################################################################
subroutine simulate_uniform_n(x, a, b)

    implicit none


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! point into which the draw should be saved
    real*8, intent(out) :: x(:)

    ! left end of the distribution
    real*8, optional :: a
    
    ! right end of the distribution
    real*8, optional :: b


    !##### OTHER VARIABLES ####################################################
        
    real*8 :: a_c, b_c
    
    
    !##### ROUTINE CODE #######################################################

    ! initialize expectation and variance
    a_c = 0d0
    if(present(a))a_c = a
    b_c = 1d0
    if(present(b))b_c = b

    ! set the random seed
    call random_seed()

    call random_number(x)

    x = a_c + (b_c-a_c)*x
    
end subroutine simulate_uniform_n


!##############################################################################
! SUBROUTINE simulate_normal_1
! 
! Simulates one draw from a uniform distribution using 
!     Box-Muller tranformation.
!##############################################################################
subroutine simulate_normal_1(x, mu, sigma)

    implicit none


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! point into which the draw should be saved
    real*8, intent(out) :: x
    
    ! expectation of distribution
    real*8, optional :: mu
    
    ! variance of distribution
    real*8, optional :: sigma


    !##### OTHER VARIABLES ####################################################
    
    real*8 :: uni1, uni2, mu_c, sigma_c
    real*8 :: pi = 3.141592653589793d0
    
    
    !##### ROUTINE CODE #######################################################

    ! initialize expectation and variance
    mu_c = 0d0
    if(present(mu))mu_c = mu
    sigma_c = 1d0
    if(present(sigma))sigma_c = sigma

    ! simulate a uniform variable draw
    call simulate_uniform_1(uni1)
    call simulate_uniform_1(uni2)

    ! transform by Box-Muller transformation
    x = sqrt(-2d0*log(uni1))*cos(2d0*pi*uni2)

    ! transform to mean and variance
    x = mu_c + sqrt(sigma_c)*x
    
end subroutine simulate_normal_1


!##############################################################################
! SUBROUTINE simulate_normal_n
! 
! Simulates one draw from a uniform distribution using 
!     Box-Muller tranformation.
!##############################################################################
subroutine simulate_normal_n(x, mu, sigma)

    implicit none


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! point into which the draw should be saved
    real*8, intent(out) :: x(:)
    
    ! expectation of distribution
    real*8, optional :: mu
    
    ! variance of distribution
    real*8, optional :: sigma


    !##### OTHER VARIABLES ####################################################
        
    real*8 :: uni1(size(x, 1)), uni2(size(x, 1)), mu_c, sigma_c
    integer :: n, in
    real*8 :: pi = 3.141592653589793d0
    
    
    !##### ROUTINE CODE #######################################################

    ! initialize expectation and variance
    mu_c = 0d0
    if(present(mu))mu_c = mu
    sigma_c = 1d0
    if(present(sigma))sigma_c = sigma

    ! get size of x
    n = size(x, 1)
    
    ! simulate a uniform variable draw
    call simulate_uniform_n(uni1)
    call simulate_uniform_n(uni2)

    ! transform by Box-Muller transformation
    do in = 1, n
        x(in) = sqrt(-2d0*log(uni1(in)))*cos(2d0*pi*uni2(in))
    enddo

    ! transform to mean and variance
    x = mu_c + sqrt(sigma_c)*x
    
end subroutine simulate_normal_n


!##############################################################################
! SUBROUTINE simulate_lognormal_1
! 
! Simulates one draw from a uniform distribution.
!##############################################################################
subroutine simulate_log_normal_1(x, mu, sigma)

    implicit none


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! point into which the draw should be saved
    real*8, intent(out) :: x
    
    ! expectation of distribution
    real*8, optional :: mu
    
    ! variance of distribution
    real*8, optional :: sigma


    !##### OTHER VARIABLES ####################################################
        
    real*8 :: mu_c, sigma_c
    
    
    !##### ROUTINE CODE #######################################################

    ! initialize expectation and variance
    mu_c = 1d0
    if(present(mu))mu_c = mu
    sigma_c = 1d0
    if(present(sigma))sigma_c = sigma
      
    ! get expectation and variance
    sigma_c = log(1d0+sigma_c/mu_c**2)
    mu_c  = log(mu_c)-0.5d0*sigma_c

    ! simulate normal and convert to log_normal
    call simulate_normal_1(x, mu_c, sigma_c)

    ! transform to log normal
    x = exp(x)
    
end subroutine simulate_log_normal_1


!##############################################################################
! SUBROUTINE simulate_log_normal_n
! 
! Simulates one draw from a uniform distribution.
!##############################################################################
subroutine simulate_log_normal_n(x, mu, sigma)

    implicit none


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! point into which the draw should be saved
    real*8, intent(out) :: x(:)
    
    ! expectation of distribution
    real*8, optional :: mu
    
    ! variance of distribution
    real*8, optional :: sigma


    !##### OTHER VARIABLES ####################################################
        
    real*8 :: mu_c, sigma_c
    
    
    !##### ROUTINE CODE #######################################################

    ! initialize expectation and variance
    mu_c = 1d0
    if(present(mu))mu_c = mu
    sigma_c = 1d0
    if(present(sigma))sigma_c = sigma    

    ! get expectation and variance
    sigma_c = log(1d0+sigma_c/mu_c**2)
    mu_c  = log(mu_c)-0.5d0*sigma_c

    ! simulate normal and convert to log_normal
    call simulate_normal_n(x, mu_c, sigma_c)
    
    ! transform to log normal
    x = exp(x)
    
end subroutine simulate_log_normal_n


!##############################################################################
! SUBROUTINE normal_discrete_1
! 
! Creates n points and probabilities for a normal distribution.
!
! Taken from Miranda and Fackler's CompEcon Toolkit
!##############################################################################
subroutine normal_discrete_1(x, prob, mu, sigma)

    implicit none


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! discrete points of normal distribution
    real*8, intent(out) :: x(:)
    
    ! probability weights
    real*8, intent(out) :: prob(:)
    
    ! expectation of distribution
    real*8, optional :: mu
    
    ! variance of distribution
    real*8, optional :: sigma
    
    
    !##### OTHER VARIABLES ####################################################
        
    real*8 :: mu_c, sigma_c, pim4, z, z1, p1, p2, p3, pp
    integer :: n, m, i, j, its
    integer, parameter :: maxit = 200
    real*8, parameter :: pi = 3.1415926535897932d0
    
    
    !##### ROUTINE CODE #######################################################

    ! initialize expectation and variance
    mu_c = 0d0
    if(present(mu))mu_c = mu
    sigma_c = 1d0
    if(present(sigma))sigma_c = sqrt(sigma)
    
    ! check for right array sizes
    n = assert_eq(size(x,1), size(prob,1), 'normal_discrete')

    ! calculate 1/pi^0.25
    pim4 = 1d0/pi**0.25d0
    
    ! get number of points
    m = (n+1)/2
    
    ! initialize x and prob
    x = 0d0
    prob = 0d0
    
    ! start iteration
    do i = 1, m
        
        ! set reasonable starting values 
        if(i == 1)then
            z = sqrt(dble(2*n+1))-1.85575d0*(dble(2*n+1)**(-1d0/6d0))
        elseif(i == 2)then 
            z = z - 1.14d0*(dble(n)**0.426d0)/z
        elseif(i == 3)then
            z = 1.86d0*z+0.86d0*x(1)
        elseif(i == 4)then
            z = 1.91d0*z+0.91d0*x(2);
        else
            z = 2d0*z+x(i-2);
        endif
        
        ! root finding iterations 
        its = 0
        do while(its < maxit)
            its = its+1
            p1 = pim4
            p2 = 0d0
            do j = 1, n
                p3 = p2
                p2 = p1
                p1 = z*sqrt(2d0/dble(j))*p2-sqrt(dble(j-1)/dble(j))*p3
            enddo
            pp = sqrt(2d0*dble(n))*p2
            z1 = z
            z  = z1-p1/pp
            if(abs(z-z1) < 1e-14)exit
        enddo
        if(its >= maxit)then
            call error('normal_discrete', &
                'Could not discretize normal distribution')
        endif
        x(n+1-i) = z
        x(i) = -z
        prob(i) = 2d0/pp**2
        prob(n+1-i) = prob(i)
    enddo
    
    ! set output data
    prob = prob/sqrt(pi)
    x = x*sqrt(2d0)*sigma_c + mu_c
    
end subroutine normal_discrete_1


!##############################################################################
! SUBROUTINE normal_discrete_2
! 
! Creates n1*n2 points and probabilities for a two-dimensional normal 
!     distribution.
!
! Taken from Miranda and Fackler's CompEcon Toolkit
!##############################################################################
subroutine normal_discrete_2(n, x, prob, mu, sigma, rho)

    ! matrix tools module
    use matrixtools

    implicit none


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! number of points in every direction
    integer, intent(in) :: n(2)
    
    ! discrete points of normal distribution
    real*8, intent(out) :: x(:, :)
    
    ! probability weights
    real*8, intent(out) :: prob(:)
    
    ! expectation of distribution
    real*8, optional :: mu(2)
    
    ! variance of distribution
    real*8, optional :: sigma(2)
    
    ! correlation of distribution
    real*8, optional :: rho
    
    
    !##### OTHER VARIABLES ####################################################
        
    real*8 :: mu_c(2), sig_c(2), rho_c, sigma_c(2,2), l(2,2)
    real*8 :: x1(n(1)), x2(n(2)), p1(n(1)), p2(n(2))
    integer :: m, j, k

    
    !##### ROUTINE CODE #######################################################

    ! initialize expectation and variance
    mu_c = 0d0
    if(present(mu))mu_c = mu
    sig_c(1) = 1d0
    if(present(sigma))sig_c = sigma
    rho_c = 0d0
    if(present(rho))rho_c = rho
    
    ! set up variance covariance matrix
    sigma_c(1, 1) = sig_c(1)
    sigma_c(2, 2) = sig_c(2)  
    sigma_c(1, 2) = rho_c*sqrt(sig_c(1)*sig_c(2))
    sigma_c(2, 1) = sigma_c(1, 2)    
    
    ! check for right array sizes
    m = assert_eq(size(x,1), size(prob,1), n(1)*n(2), 'normal_discrete')
    m = assert_eq(size(x,2), 2, 'normal_discrete')
    
    ! check whether sigma is symmetric
    if(any(abs(transpose(sigma_c) - sigma_c) > 1d-20)) &
        call error('normal_discrete', &
        'Variance-Covariance matrix is not symmetric')
    
    ! get standard normal distributed random variables
    call normal_discrete(x1, p1, 0d0, 1d0)
    call normal_discrete(x2, p2, 0d0, 1d0)        
    
    ! get joint distribution
    m = 1
    do k = 1, n(2)
        do j = 1, n(1)
            prob(m) = p1(j)*p2(k)
            x(m, :) = (/x1(j), x2(k)/)
            m = m+1
        enddo
    enddo
    
    ! decompose var-cov matrix
    if(.not.any(sig_c == 0d0))then
        call cholesky(sigma_c, l)
    else
        l = 0d0
        l(1,1) = sqrt(sig_c(1))
        l(2,2) = sqrt(sig_c(2))
    endif
    
    ! calculate distribution    
    x = matmul(x, transpose(l))
    x(:, 1) = x(:, 1) + mu_c(1)
    x(:, 2) = x(:, 2) + mu_c(2)    
    
end subroutine normal_discrete_2


!##############################################################################
! SUBROUTINE log_normal_discrete_1
! 
! Creates n points and probabilities for a log-normal distribution.
!
! Taken from Miranda and Fackler's CompEcon Toolkit
!##############################################################################
subroutine log_normal_discrete_1(x, prob, mu, sigma)

    implicit none


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! discrete points of normal distribution
    real*8, intent(out) :: x(:)
    
    ! probability weights
    real*8, intent(out) :: prob(:)
    
    ! expectation of distribution
    real*8, optional :: mu
    
    ! variance of distribution
    real*8, optional :: sigma
    
    
    !##### OTHER VARIABLES ####################################################
        
    real*8 :: mu_c, sigma_c
    integer :: n    
    
    !##### ROUTINE CODE #######################################################

    ! initialize expectation and variance
    mu_c = 1d0
    if(present(mu))mu_c = mu
    sigma_c = 1d0
    if(present(sigma))sigma_c = sigma
    
    ! get expectation and variance
    sigma_c = log(1d0+sigma_c/mu_c**2)
    mu_c  = log(mu_c)-0.5d0*sigma_c
    
    ! check for right array sizes
    n = assert_eq(size(x,1), size(prob,1), 'normal_discrete')
    
    call normal_discrete(x, prob, mu_c, sigma_c)
    
    x = exp(x)
    
end subroutine log_normal_discrete_1


!##############################################################################
! SUBROUTINE log_normal_discrete_2
! 
! Creates n1*n2 points and probabilities for a two-dimensional log-normal 
!     distribution.
!
! Taken from Miranda and Fackler's CompEcon Toolkit
!##############################################################################
subroutine log_normal_discrete_2(n, x, prob, mu, sigma, rho)

    ! matrix tools module
    use matrixtools

    implicit none


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! number of points in every direction
    integer, intent(in) :: n(2)
    
    ! discrete points of normal distribution
    real*8, intent(out) :: x(:, :)
    
    ! probability weights
    real*8, intent(out) :: prob(:)
    
    ! expectation of distribution
    real*8, optional :: mu(2)
    
    ! variance of distribution
    real*8, optional :: sigma(2)
    
    ! correlation of distribution
    real*8, optional :: rho
    
    
    !##### OTHER VARIABLES ####################################################
        
    real*8 :: mu_c(2), sig_c(2), rho_c, sigma_c(2,2), l(2,2)
    real*8 :: x1(n(1)), x2(n(2)), p1(n(1)), p2(n(2))
    integer :: m, j, k

    
    !##### ROUTINE CODE #######################################################

    ! initialize expectation and variance
    mu_c = 1d0
    if(present(mu))mu_c = mu
    sig_c(:) = 1d0
    if(present(sigma))sig_c = sigma
    rho_c = 0d0
    if(present(rho))rho_c = rho
    
    ! get expectation and variances
    sig_c = log(1d0+sig_c/mu_c**2)
    mu_c  = log(mu_c)-0.5d0*sig_c
    
    ! set up covariance matrix
    sigma_c(1, 1) = sig_c(1)
    sigma_c(2, 2) = sig_c(2)  
    sigma_c(1, 2) = log(rho_c*sqrt(exp(sig_c(1))-1d0)* &
        sqrt(exp(sig_c(2))-1d0)+1d0)
    sigma_c(2, 1) = sigma_c(1, 2)
    
    ! check for right array sizes
    m = assert_eq(size(x,1), size(prob,1), n(1)*n(2), 'normal_discrete')
    m = assert_eq(size(x,2), 2, 'normal_discrete')
    
    ! check whether sigma is symmetric
    if(any(abs(transpose(sigma_c) - sigma_c) > 1d-20)) &
        call error('normal_discrete', &
        'Variance-Covariance matrix is not symmetric')
    
    ! get standard normal distributed random variables
    call normal_discrete(x1, p1, 0d0, 1d0)
    call normal_discrete(x2, p2, 0d0, 1d0)
    
    ! get joint distribution
    m = 1
    do k = 1, n(2)
        do j = 1, n(1)
            prob(m) = p1(j)*p2(k)
            x(m, :) = (/x1(j), x2(k)/)
            m = m+1
        enddo
    enddo
    
    ! decompose var-cov matrix
    if(.not.any(sig_c == 0d0))then
        call cholesky(sigma_c, l)
    else
        l = 0d0
        l(1,1) = sqrt(sig_c(1))
        l(2,2) = sqrt(sig_c(2))
    endif
    
    ! calculate distribution    
    x = matmul(x, transpose(l))
    x(:, 1) = x(:, 1) + mu_c(1)
    x(:, 2) = x(:, 2) + mu_c(2)
    x = exp(x)
    
end subroutine log_normal_discrete_2


!##############################################################################
! SUBROUTINE loadNormal
! 
! Loads coefficients of standard normal distribution. No Inputs no Outputs.
!##############################################################################
subroutine loadNormal()

    implicit none
    

    ! coefficients for normal distribution
    nCoeffs(1  ) = 0.08266842952037d0
    nCoeffs(2  ) = 0.08333333333666d0
    nCoeffs(3  ) = 0.08399823713300d0
    nCoeffs(4  ) = 0.08466307444597d0
    nCoeffs(5  ) = 0.08532777880002d0
    nCoeffs(6  ) = 0.08599228376807d0
    nCoeffs(7  ) = 0.08665652298054d0
    nCoeffs(8  ) = 0.08732043014815d0
    nCoeffs(9  ) = 0.08798393908098d0
    nCoeffs(10 ) = 0.08864698370847d0
    nCoeffs(11 ) = 0.08930949809913d0
    nCoeffs(12 ) = 0.08997141648018d0
    nCoeffs(13 ) = 0.09063267325717d0
    nCoeffs(14 ) = 0.09129320303345d0
    nCoeffs(15 ) = 0.09195294062960d0
    nCoeffs(16 ) = 0.09261182110270d0
    nCoeffs(17 ) = 0.09326977976551d0
    nCoeffs(18 ) = 0.09392675220552d0
    nCoeffs(19 ) = 0.09458267430386d0
    nCoeffs(20 ) = 0.09523748225408d0
    nCoeffs(21 ) = 0.09589111258072d0
    nCoeffs(22 ) = 0.09654350215782d0
    nCoeffs(23 ) = 0.09719458822711d0
    nCoeffs(24 ) = 0.09784430841619d0
    nCoeffs(25 ) = 0.09849260075636d0
    nCoeffs(26 ) = 0.09913940370038d0
    nCoeffs(27 ) = 0.09978465613992d0
    nCoeffs(28 ) = 0.10042829742287d0
    nCoeffs(29 ) = 0.10107026737037d0
    nCoeffs(30 ) = 0.10171050629368d0
    nCoeffs(31 ) = 0.10234895501070d0
    nCoeffs(32 ) = 0.10298555486238d0
    nCoeffs(33 ) = 0.10362024772873d0
    nCoeffs(34 ) = 0.10425297604471d0
    nCoeffs(35 ) = 0.10488368281574d0
    nCoeffs(36 ) = 0.10551231163298d0
    nCoeffs(37 ) = 0.10613880668836d0
    nCoeffs(38 ) = 0.10676311278921d0
    nCoeffs(39 ) = 0.10738517537278d0
    nCoeffs(40 ) = 0.10800494052022d0
    nCoeffs(41 ) = 0.10862235497049d0
    nCoeffs(42 ) = 0.10923736613378d0
    nCoeffs(43 ) = 0.10984992210470d0
    nCoeffs(44 ) = 0.11045997167510d0
    nCoeffs(45 ) = 0.11106746434664d0
    nCoeffs(46 ) = 0.11167235034289d0
    nCoeffs(47 ) = 0.11227458062122d0
    nCoeffs(48 ) = 0.11287410688430d0
    nCoeffs(49 ) = 0.11347088159122d0
    nCoeffs(50 ) = 0.11406485796828d0
    nCoeffs(51 ) = 0.11465599001946d0
    nCoeffs(52 ) = 0.11524423253650d0
    nCoeffs(53 ) = 0.11582954110857d0
    nCoeffs(54 ) = 0.11641187213170d0
    nCoeffs(55 ) = 0.11699118281768d0
    nCoeffs(56 ) = 0.11756743120273d0
    nCoeffs(57 ) = 0.11814057615572d0
    nCoeffs(58 ) = 0.11871057738604d0
    nCoeffs(59 ) = 0.11927739545108d0
    nCoeffs(60 ) = 0.11984099176332d0
    nCoeffs(61 ) = 0.12040132859708d0
    nCoeffs(62 ) = 0.12095836909488d0
    nCoeffs(63 ) = 0.12151207727333d0
    nCoeffs(64 ) = 0.12206241802879d0
    nCoeffs(65 ) = 0.12260935714252d0
    nCoeffs(66 ) = 0.12315286128547d0
    nCoeffs(67 ) = 0.12369289802275d0
    nCoeffs(68 ) = 0.12422943581766d0
    nCoeffs(69 ) = 0.12476244403529d0
    nCoeffs(70 ) = 0.12529189294588d0
    nCoeffs(71 ) = 0.12581775372763d0
    nCoeffs(72 ) = 0.12633999846928d0
    nCoeffs(73 ) = 0.12685860017217d0
    nCoeffs(74 ) = 0.12737353275205d0
    nCoeffs(75 ) = 0.12788477104040d0
    nCoeffs(76 ) = 0.12839229078547d0
    nCoeffs(77 ) = 0.12889606865292d0
    nCoeffs(78 ) = 0.12939608222599d0
    nCoeffs(79 ) = 0.12989231000551d0
    nCoeffs(80 ) = 0.13038473140932d0
    nCoeffs(81 ) = 0.13087332677149d0
    nCoeffs(82 ) = 0.13135807734110d0
    nCoeffs(83 ) = 0.13183896528071d0
    nCoeffs(84 ) = 0.13231597366444d0
    nCoeffs(85 ) = 0.13278908647571d0
    nCoeffs(86 ) = 0.13325828860466d0
    nCoeffs(87 ) = 0.13372356584521d0
    nCoeffs(88 ) = 0.13418490489180d0
    nCoeffs(89 ) = 0.13464229333577d0
    nCoeffs(90 ) = 0.13509571966143d0
    nCoeffs(91 ) = 0.13554517324182d0
    nCoeffs(92 ) = 0.13599064433414d0
    nCoeffs(93 ) = 0.13643212407487d0
    nCoeffs(94 ) = 0.13686960447458d0
    nCoeffs(95 ) = 0.13730307841244d0
    nCoeffs(96 ) = 0.13773253963042d0
    nCoeffs(97 ) = 0.13815798272726d0
    nCoeffs(98 ) = 0.13857940315206d0
    nCoeffs(99 ) = 0.13899679719767d0
    nCoeffs(100) = 0.13941016199375d0
    nCoeffs(101) = 0.13981949549964d0
    nCoeffs(102) = 0.14022479649686d0
    nCoeffs(103) = 0.14062606458146d0
    nCoeffs(104) = 0.14102330015605d0
    nCoeffs(105) = 0.14141650442162d0
    nCoeffs(106) = 0.14180567936913d0
    nCoeffs(107) = 0.14219082777086d0
    nCoeffs(108) = 0.14257195317152d0
    nCoeffs(109) = 0.14294905987916d0
    nCoeffs(110) = 0.14332215295591d0
    nCoeffs(111) = 0.14369123820844d0
    nCoeffs(112) = 0.14405632217830d0
    nCoeffs(113) = 0.14441741213199d0
    nCoeffs(114) = 0.14477451605098d0
    nCoeffs(115) = 0.14512764262136d0
    nCoeffs(116) = 0.14547680122355d0
    nCoeffs(117) = 0.14582200192164d0
    nCoeffs(118) = 0.14616325545274d0
    nCoeffs(119) = 0.14650057321607d0
    nCoeffs(120) = 0.14683396726198d0
    nCoeffs(121) = 0.14716345028082d0
    nCoeffs(122) = 0.14748903559165d0
    nCoeffs(123) = 0.14781073713089d0
    nCoeffs(124) = 0.14812856944082d0
    nCoeffs(125) = 0.14844254765799d0
    nCoeffs(126) = 0.14875268750152d0
    nCoeffs(127) = 0.14905900526133d0
    nCoeffs(128) = 0.14936151778628d0
    nCoeffs(129) = 0.14966024247223d0
    nCoeffs(130) = 0.14995519725000d0
    nCoeffs(131) = 0.15024640057335d0
    nCoeffs(132) = 0.15053387140685d0
    nCoeffs(133) = 0.15081762921365d0
    nCoeffs(134) = 0.15109769394332d0
    nCoeffs(135) = 0.15137408601959d0
    nCoeffs(136) = 0.15164682632804d0
    nCoeffs(137) = 0.15191593620381d0
    nCoeffs(138) = 0.15218143741931d0
    nCoeffs(139) = 0.15244335217185d0
    nCoeffs(140) = 0.15270170307132d0
    nCoeffs(141) = 0.15295651312786d0
    nCoeffs(142) = 0.15320780573956d0
    nCoeffs(143) = 0.15345560468012d0
    nCoeffs(144) = 0.15369993408657d0
    nCoeffs(145) = 0.15394081844705d0
    nCoeffs(146) = 0.15417828258851d0
    nCoeffs(147) = 0.15441235166460d0
    nCoeffs(148) = 0.15464305114346d0
    nCoeffs(149) = 0.15487040679567d0
    nCoeffs(150) = 0.15509444468217d0
    nCoeffs(151) = 0.15531519114231d0
    nCoeffs(152) = 0.15553267278188d0
    nCoeffs(153) = 0.15574691646132d0
    nCoeffs(154) = 0.15595794928392d0
    nCoeffs(155) = 0.15616579858408d0
    nCoeffs(156) = 0.15637049191578d0
    nCoeffs(157) = 0.15657205704098d0
    nCoeffs(158) = 0.15677052191823d0
    nCoeffs(159) = 0.15696591469131d0
    nCoeffs(160) = 0.15715826367800d0
    nCoeffs(161) = 0.15734759735896d0
    nCoeffs(162) = 0.15753394436670d0
    nCoeffs(163) = 0.15771733347468d0
    nCoeffs(164) = 0.15789779358648d0
    nCoeffs(165) = 0.15807535372517d0
    nCoeffs(166) = 0.15825004302275d0
    nCoeffs(167) = 0.15842189070971d0
    nCoeffs(168) = 0.15859092610475d0
    nCoeffs(169) = 0.15875717860458d0
    nCoeffs(170) = 0.15892067767398d0
    nCoeffs(171) = 0.15908145283580d0
    nCoeffs(172) = 0.15923953366129d0
    nCoeffs(173) = 0.15939494976049d0
    nCoeffs(174) = 0.15954773077272d0
    nCoeffs(175) = 0.15969790635731d0
    nCoeffs(176) = 0.15984550618444d0
    nCoeffs(177) = 0.15999055992611d0
    nCoeffs(178) = 0.16013309724729d0
    nCoeffs(179) = 0.16027314779723d0
    nCoeffs(180) = 0.16041074120091d0
    nCoeffs(181) = 0.16054590705063d0
    nCoeffs(182) = 0.16067867489785d0
    nCoeffs(183) = 0.16080907424505d0
    nCoeffs(184) = 0.16093713453790d0
    nCoeffs(185) = 0.16106288515746d0
    nCoeffs(186) = 0.16118635541264d0
    nCoeffs(187) = 0.16130757453281d0
    nCoeffs(188) = 0.16142657166051d0
    nCoeffs(189) = 0.16154337584441d0
    nCoeffs(190) = 0.16165801603239d0
    nCoeffs(191) = 0.16177052106482d0
    nCoeffs(192) = 0.16188091966793d0
    nCoeffs(193) = 0.16198924044747d0
    nCoeffs(194) = 0.16209551188243d0
    nCoeffs(195) = 0.16219976231898d0
    nCoeffs(196) = 0.16230201996458d0
    nCoeffs(197) = 0.16240231288223d0
    nCoeffs(198) = 0.16250066898487d0
    nCoeffs(199) = 0.16259711603006d0
    nCoeffs(200) = 0.16269168161466d0
    nCoeffs(201) = 0.16278439316979d0
    nCoeffs(202) = 0.16287527795595d0
    nCoeffs(203) = 0.16296436305822d0
    nCoeffs(204) = 0.16305167538173d0
    nCoeffs(205) = 0.16313724164721d0
    nCoeffs(206) = 0.16322108838675d0
    nCoeffs(207) = 0.16330324193970d0
    nCoeffs(208) = 0.16338372844873d0
    nCoeffs(209) = 0.16346257385602d0
    nCoeffs(210) = 0.16353980389969d0
    nCoeffs(211) = 0.16361544411029d0
    nCoeffs(212) = 0.16368951980749d0
    nCoeffs(213) = 0.16376205609692d0
    nCoeffs(214) = 0.16383307786715d0
    nCoeffs(215) = 0.16390260978683d0
    nCoeffs(216) = 0.16397067630194d0
    nCoeffs(217) = 0.16403730163326d0
    nCoeffs(218) = 0.16410250977393d0
    nCoeffs(219) = 0.16416632448711d0
    nCoeffs(220) = 0.16422876930390d0
    nCoeffs(221) = 0.16428986752129d0
    nCoeffs(222) = 0.16434964220027d0
    nCoeffs(223) = 0.16440811616413d0
    nCoeffs(224) = 0.16446531199680d0
    nCoeffs(225) = 0.16452125204142d0
    nCoeffs(226) = 0.16457595839893d0
    nCoeffs(227) = 0.16462945292691d0
    nCoeffs(228) = 0.16468175723840d0
    nCoeffs(229) = 0.16473289270097d0
    nCoeffs(230) = 0.16478288043584d0
    nCoeffs(231) = 0.16483174131713d0
    nCoeffs(232) = 0.16487949597123d0
    nCoeffs(233) = 0.16492616477627d0
    nCoeffs(234) = 0.16497176786173d0
    nCoeffs(235) = 0.16501632510810d0
    nCoeffs(236) = 0.16505985614672d0
    nCoeffs(237) = 0.16510238035967d0
    nCoeffs(238) = 0.16514391687977d0
    nCoeffs(239) = 0.16518448459069d0
    nCoeffs(240) = 0.16522410212715d0
    nCoeffs(241) = 0.16526278787521d0
    nCoeffs(242) = 0.16530055997267d0
    nCoeffs(243) = 0.16533743630952d0
    nCoeffs(244) = 0.16537343452852d0
    nCoeffs(245) = 0.16540857202584d0
    nCoeffs(246) = 0.16544286595180d0
    nCoeffs(247) = 0.16547633321163d0
    nCoeffs(248) = 0.16550899046642d0
    nCoeffs(249) = 0.16554085413405d0
    nCoeffs(250) = 0.16557194039022d0
    nCoeffs(251) = 0.16560226516953d0
    nCoeffs(252) = 0.16563184416672d0
    nCoeffs(253) = 0.16566069283783d0
    nCoeffs(254) = 0.16568882640156d0
    nCoeffs(255) = 0.16571625984060d0
    nCoeffs(256) = 0.16574300790308d0
    nCoeffs(257) = 0.16576908510400d0
    nCoeffs(258) = 0.16579450572684d0
    nCoeffs(259) = 0.16581928382508d0
    nCoeffs(260) = 0.16584343322386d0
    nCoeffs(261) = 0.16586696752170d0
    nCoeffs(262) = 0.16588990009220d0
    nCoeffs(263) = 0.16591224408580d0
    nCoeffs(264) = 0.16593401243165d0
    nCoeffs(265) = 0.16595521783947d0
    nCoeffs(266) = 0.16597587280139d0
    nCoeffs(267) = 0.16599598959395d0
    nCoeffs(268) = 0.16601558028006d0
    nCoeffs(269) = 0.16603465671097d0
    nCoeffs(270) = 0.16605323052837d0
    nCoeffs(271) = 0.16607131316638d0
    nCoeffs(272) = 0.16608891585371d0
    nCoeffs(273) = 0.16610604961574d0
    nCoeffs(274) = 0.16612272527667d0
    nCoeffs(275) = 0.16613895346170d0
    nCoeffs(276) = 0.16615474459919d0
    nCoeffs(277) = 0.16617010892290d0
    nCoeffs(278) = 0.16618505647417d0
    nCoeffs(279) = 0.16619959710420d0
    nCoeffs(280) = 0.16621374047627d0
    nCoeffs(281) = 0.16622749606802d0
    nCoeffs(282) = 0.16624087317374d0
    nCoeffs(283) = 0.16625388090661d0
    nCoeffs(284) = 0.16626652820105d0
    nCoeffs(285) = 0.16627882381500d0
    nCoeffs(286) = 0.16629077633222d0
    nCoeffs(287) = 0.16630239416459d0
    nCoeffs(288) = 0.16631368555449d0
    nCoeffs(289) = 0.16632465857703d0
    nCoeffs(290) = 0.16633532114244d0
    nCoeffs(291) = 0.16634568099833d0
    nCoeffs(292) = 0.16635574573206d0
    nCoeffs(293) = 0.16636552277304d0
    nCoeffs(294) = 0.16637501939499d0
    nCoeffs(295) = 0.16638424271833d0
    nCoeffs(296) = 0.16639319971241d0
    nCoeffs(297) = 0.16640189719786d0
    nCoeffs(298) = 0.16641034184880d0
    nCoeffs(299) = 0.16641854019521d0
    nCoeffs(300) = 0.16642649862513d0
    nCoeffs(301) = 0.16643422338694d0
    nCoeffs(302) = 0.16644172059162d0
    nCoeffs(303) = 0.16644899621496d0
    nCoeffs(304) = 0.16645605609979d0
    nCoeffs(305) = 0.16646290595821d0
    nCoeffs(306) = 0.16646955137377d0
    nCoeffs(307) = 0.16647599780362d0
    nCoeffs(308) = 0.16648225058074d0
    nCoeffs(309) = 0.16648831491603d0
    nCoeffs(310) = 0.16649419590048d0
    nCoeffs(311) = 0.16649989850726d0
    nCoeffs(312) = 0.16650542759386d0
    nCoeffs(313) = 0.16651078790409d0
    nCoeffs(314) = 0.16651598407025d0
    nCoeffs(315) = 0.16652102061508d0
    nCoeffs(316) = 0.16652590195381d0
    nCoeffs(317) = 0.16653063239621d0
    nCoeffs(318) = 0.16653521614851d0
    nCoeffs(319) = 0.16653965731538d0
    nCoeffs(320) = 0.16654395990190d0
    nCoeffs(321) = 0.16654812781546d0
    nCoeffs(322) = 0.16655216486763d0
    nCoeffs(323) = 0.16655607477611d0
    nCoeffs(324) = 0.16655986116650d0
    nCoeffs(325) = 0.16656352757422d0
    nCoeffs(326) = 0.16656707744623d0
    nCoeffs(327) = 0.16657051414291d0
    nCoeffs(328) = 0.16657384093974d0
    nCoeffs(329) = 0.16657706102911d0
    nCoeffs(330) = 0.16658017752200d0
    nCoeffs(331) = 0.16658319344969d0
    nCoeffs(332) = 0.16658611176545d0
    nCoeffs(333) = 0.16658893534614d0
    nCoeffs(334) = 0.16659166699389d0
    nCoeffs(335) = 0.16659430943769d0
    nCoeffs(336) = 0.16659686533495d0
    nCoeffs(337) = 0.16659933727306d0
    nCoeffs(338) = 0.16660172777095d0
    nCoeffs(339) = 0.16660403928057d0
    nCoeffs(340) = 0.16660627418839d0
    nCoeffs(341) = 0.16660843481686d0
    nCoeffs(342) = 0.16661052342585d0
    nCoeffs(343) = 0.16661254221407d0
    nCoeffs(344) = 0.16661449332045d0
    nCoeffs(345) = 0.16661637882554d0
    nCoeffs(346) = 0.16661820075280d0
    nCoeffs(347) = 0.16661996106999d0
    nCoeffs(348) = 0.16662166169043d0
    nCoeffs(349) = 0.16662330447431d0
    nCoeffs(350) = 0.16662489122990d0
    nCoeffs(351) = 0.16662642371482d0
    nCoeffs(352) = 0.16662790363726d0
    nCoeffs(353) = 0.16662933265712d0
    nCoeffs(354) = 0.16663071238726d0
    nCoeffs(355) = 0.16663204439455d0
    nCoeffs(356) = 0.16663333020107d0
    nCoeffs(357) = 0.16663457128517d0
    nCoeffs(358) = 0.16663576908260d0
    nCoeffs(359) = 0.16663692498750d0
    nCoeffs(360) = 0.16663804035350d0
    nCoeffs(361) = 0.16663911649474d0
    nCoeffs(362) = 0.16664015468682d0
    nCoeffs(363) = 0.16664115616783d0
    nCoeffs(364) = 0.16664212213929d0
    nCoeffs(365) = 0.16664305376710d0
    nCoeffs(366) = 0.16664395218244d0
    nCoeffs(367) = 0.16664481848270d0
    nCoeffs(368) = 0.16664565373234d0
    nCoeffs(369) = 0.16664645896379d0
    nCoeffs(370) = 0.16664723517823d0
    nCoeffs(371) = 0.16664798334649d0
    nCoeffs(372) = 0.16664870440983d0
    nCoeffs(373) = 0.16664939928072d0
    nCoeffs(374) = 0.16665006884363d0
    nCoeffs(375) = 0.16665071395579d0
    nCoeffs(376) = 0.16665133544793d0
    nCoeffs(377) = 0.16665193412500d0
    nCoeffs(378) = 0.16665251076687d0
    nCoeffs(379) = 0.16665306612903d0
    nCoeffs(380) = 0.16665360094329d0
    nCoeffs(381) = 0.16665411591840d0
    nCoeffs(382) = 0.16665461174071d0
    nCoeffs(383) = 0.16665508907482d0
    nCoeffs(384) = 0.16665554856414d0
    nCoeffs(385) = 0.16665599083158d0
    nCoeffs(386) = 0.16665641648004d0
    nCoeffs(387) = 0.16665682609306d0
    nCoeffs(388) = 0.16665722023531d0
    nCoeffs(389) = 0.16665759945318d0
    nCoeffs(390) = 0.16665796427532d0
    nCoeffs(391) = 0.16665831521312d0
    nCoeffs(392) = 0.16665865276121d0
    nCoeffs(393) = 0.16665897739802d0
    nCoeffs(394) = 0.16665928958617d0
    nCoeffs(395) = 0.16665958977300d0
    nCoeffs(396) = 0.16665987839103d0
    nCoeffs(397) = 0.16666015585833d0
    nCoeffs(398) = 0.16666042257905d0
    nCoeffs(399) = 0.16666067894377d0
    nCoeffs(400) = 0.16666092532995d0
    nCoeffs(401) = 0.16666116210230d0
    nCoeffs(402) = 0.16666138961320d0
    nCoeffs(403) = 0.16666160820305d0
    nCoeffs(404) = 0.16666181820066d0
    nCoeffs(405) = 0.16666201992359d0
    nCoeffs(406) = 0.16666221367853d0
    nCoeffs(407) = 0.16666239976158d0
    nCoeffs(408) = 0.16666257845867d0
    nCoeffs(409) = 0.16666275004578d0
    nCoeffs(410) = 0.16666291478934d0
    nCoeffs(411) = 0.16666307294647d0
    nCoeffs(412) = 0.16666322476532d0
    nCoeffs(413) = 0.16666337048533d0
    nCoeffs(414) = 0.16666351033750d0
    nCoeffs(415) = 0.16666364454471d0
    nCoeffs(416) = 0.16666377332193d0
    nCoeffs(417) = 0.16666389687649d0
    nCoeffs(418) = 0.16666401540836d0
    nCoeffs(419) = 0.16666412911034d0
    nCoeffs(420) = 0.16666423816833d0
    nCoeffs(421) = 0.16666434276155d0
    nCoeffs(422) = 0.16666444306275d0
    nCoeffs(423) = 0.16666453923844d0
    nCoeffs(424) = 0.16666463144908d0
    nCoeffs(425) = 0.16666471984931d0
    nCoeffs(426) = 0.16666480458810d0
    nCoeffs(427) = 0.16666488580898d0
    nCoeffs(428) = 0.16666496365022d0
    nCoeffs(429) = 0.16666503824498d0
    nCoeffs(430) = 0.16666510972151d0
    nCoeffs(431) = 0.16666517820332d0
    nCoeffs(432) = 0.16666524380931d0
    nCoeffs(433) = 0.16666530665397d0
    nCoeffs(434) = 0.16666536684750d0
    nCoeffs(435) = 0.16666542449598d0
    nCoeffs(436) = 0.16666547970149d0
    nCoeffs(437) = 0.16666553256227d0
    nCoeffs(438) = 0.16666558317284d0
    nCoeffs(439) = 0.16666563162416d0
    nCoeffs(440) = 0.16666567800370d0
    nCoeffs(441) = 0.16666572239561d0
    nCoeffs(442) = 0.16666576488083d0
    nCoeffs(443) = 0.16666580553718d0
    nCoeffs(444) = 0.16666584443950d0
    nCoeffs(445) = 0.16666588165975d0
    nCoeffs(446) = 0.16666591726709d0
    nCoeffs(447) = 0.16666595132801d0
    nCoeffs(448) = 0.16666598390641d0
    nCoeffs(449) = 0.16666601506371d0
    nCoeffs(450) = 0.16666604485891d0
    nCoeffs(451) = 0.16666607334871d0
    nCoeffs(452) = 0.16666610058758d0
    nCoeffs(453) = 0.16666612662784d0
    nCoeffs(454) = 0.16666615151975d0
    nCoeffs(455) = 0.16666617531157d0
    nCoeffs(456) = 0.16666619804964d0
    nCoeffs(457) = 0.16666621977846d0
    nCoeffs(458) = 0.16666624054075d0
    nCoeffs(459) = 0.16666626037751d0
    nCoeffs(460) = 0.16666627932812d0
    nCoeffs(461) = 0.16666629743035d0
    nCoeffs(462) = 0.16666631472044d0
    nCoeffs(463) = 0.16666633123319d0
    nCoeffs(464) = 0.16666634700196d0
    nCoeffs(465) = 0.16666636205877d0
    nCoeffs(466) = 0.16666637643432d0
    nCoeffs(467) = 0.16666639015807d0
    nCoeffs(468) = 0.16666640325826d0
    nCoeffs(469) = 0.16666641576197d0
    nCoeffs(470) = 0.16666642769517d0
    nCoeffs(471) = 0.16666643908275d0
    nCoeffs(472) = 0.16666644994857d0
    nCoeffs(473) = 0.16666646031550d0
    nCoeffs(474) = 0.16666647020546d0
    nCoeffs(475) = 0.16666647963944d0
    nCoeffs(476) = 0.16666648863758d0
    nCoeffs(477) = 0.16666649721914d0
    nCoeffs(478) = 0.16666650540260d0
    nCoeffs(479) = 0.16666651320565d0
    nCoeffs(480) = 0.16666652064521d0
    nCoeffs(481) = 0.16666652773753d0
    nCoeffs(482) = 0.16666653449812d0
    nCoeffs(483) = 0.16666654094186d0
    nCoeffs(484) = 0.16666654708298d0
    nCoeffs(485) = 0.16666655293512d0
    nCoeffs(486) = 0.16666655851130d0
    nCoeffs(487) = 0.16666656382403d0
    nCoeffs(488) = 0.16666656888522d0
    nCoeffs(489) = 0.16666657370632d0
    nCoeffs(490) = 0.16666657829825d0
    nCoeffs(491) = 0.16666658267147d0
    nCoeffs(492) = 0.16666658683598d0
    nCoeffs(493) = 0.16666659080134d0
    nCoeffs(494) = 0.16666659457670d0
    nCoeffs(495) = 0.16666659817080d0
    nCoeffs(496) = 0.16666660159201d0
    nCoeffs(497) = 0.16666660484831d0
    nCoeffs(498) = 0.16666660794734d0
    nCoeffs(499) = 0.16666661089641d0
    nCoeffs(500) = 0.16666661370249d0
    nCoeffs(501) = 0.16666661637226d0
    nCoeffs(502) = 0.16666661891201d0
    nCoeffs(503) = 0.16666662132813d0
       
    ! coefficients for inverse distribution    
    iCoeffs(1  ) = -0.00041777129562d0
    iCoeffs(2  ) = 0.00000000000002d0
    iCoeffs(3  ) = 0.00041777129555d0
    iCoeffs(4  ) = 0.00083554521604d0
    iCoeffs(5  ) = 0.00125332438654d0
    iCoeffs(6  ) = 0.00167111143232d0
    iCoeffs(7  ) = 0.00208890897904d0
    iCoeffs(8  ) = 0.00250671965277d0
    iCoeffs(9  ) = 0.00292454608021d0
    iCoeffs(10 ) = 0.00334239088872d0
    iCoeffs(11 ) = 0.00376025670647d0
    iCoeffs(12 ) = 0.00417814616256d0
    iCoeffs(13 ) = 0.00459606188715d0
    iCoeffs(14 ) = 0.00501400651153d0
    iCoeffs(15 ) = 0.00543198266827d0
    iCoeffs(16 ) = 0.00584999299134d0
    iCoeffs(17 ) = 0.00626804011620d0
    iCoeffs(18 ) = 0.00668612667993d0
    iCoeffs(19 ) = 0.00710425532138d0
    iCoeffs(20 ) = 0.00752242868122d0
    iCoeffs(21 ) = 0.00794064940211d0
    iCoeffs(22 ) = 0.00835892012881d0
    iCoeffs(23 ) = 0.00877724350826d0
    iCoeffs(24 ) = 0.00919562218976d0
    iCoeffs(25 ) = 0.00961405882504d0
    iCoeffs(26 ) = 0.01003255606838d0
    iCoeffs(27 ) = 0.01045111657676d0
    iCoeffs(28 ) = 0.01086974300997d0
    iCoeffs(29 ) = 0.01128843803069d0
    iCoeffs(30 ) = 0.01170720430466d0
    iCoeffs(31 ) = 0.01212604450079d0
    iCoeffs(32 ) = 0.01254496129125d0
    iCoeffs(33 ) = 0.01296395735162d0
    iCoeffs(34 ) = 0.01338303536101d0
    iCoeffs(35 ) = 0.01380219800217d0
    iCoeffs(36 ) = 0.01422144796162d0
    iCoeffs(37 ) = 0.01464078792976d0
    iCoeffs(38 ) = 0.01506022060101d0
    iCoeffs(39 ) = 0.01547974867392d0
    iCoeffs(40 ) = 0.01589937485133d0
    iCoeffs(41 ) = 0.01631910184041d0
    iCoeffs(42 ) = 0.01673893235289d0
    iCoeffs(43 ) = 0.01715886910510d0
    iCoeffs(44 ) = 0.01757891481815d0
    iCoeffs(45 ) = 0.01799907221804d0
    iCoeffs(46 ) = 0.01841934403577d0
    iCoeffs(47 ) = 0.01883973300748d0
    iCoeffs(48 ) = 0.01926024187461d0
    iCoeffs(49 ) = 0.01968087338397d0
    iCoeffs(50 ) = 0.02010163028790d0
    iCoeffs(51 ) = 0.02052251534443d0
    iCoeffs(52 ) = 0.02094353131733d0
    iCoeffs(53 ) = 0.02136468097634d0
    iCoeffs(54 ) = 0.02178596709724d0
    iCoeffs(55 ) = 0.02220739246197d0
    iCoeffs(56 ) = 0.02262895985883d0
    iCoeffs(57 ) = 0.02305067208255d0
    iCoeffs(58 ) = 0.02347253193447d0
    iCoeffs(59 ) = 0.02389454222264d0
    iCoeffs(60 ) = 0.02431670576198d0
    iCoeffs(61 ) = 0.02473902537441d0
    iCoeffs(62 ) = 0.02516150388900d0
    iCoeffs(63 ) = 0.02558414414208d0
    iCoeffs(64 ) = 0.02600694897743d0
    iCoeffs(65 ) = 0.02642992124635d0
    iCoeffs(66 ) = 0.02685306380788d0
    iCoeffs(67 ) = 0.02727637952888d0
    iCoeffs(68 ) = 0.02769987128423d0
    iCoeffs(69 ) = 0.02812354195691d0
    iCoeffs(70 ) = 0.02854739443821d0
    iCoeffs(71 ) = 0.02897143162783d0
    iCoeffs(72 ) = 0.02939565643406d0
    iCoeffs(73 ) = 0.02982007177390d0
    iCoeffs(74 ) = 0.03024468057323d0
    iCoeffs(75 ) = 0.03066948576697d0
    iCoeffs(76 ) = 0.03109449029920d0
    iCoeffs(77 ) = 0.03151969712335d0
    iCoeffs(78 ) = 0.03194510920233d0
    iCoeffs(79 ) = 0.03237072950868d0
    iCoeffs(80 ) = 0.03279656102476d0
    iCoeffs(81 ) = 0.03322260674288d0
    iCoeffs(82 ) = 0.03364886966548d0
    iCoeffs(83 ) = 0.03407535280525d0
    iCoeffs(84 ) = 0.03450205918534d0
    iCoeffs(85 ) = 0.03492899183952d0
    iCoeffs(86 ) = 0.03535615381230d0
    iCoeffs(87 ) = 0.03578354815915d0
    iCoeffs(88 ) = 0.03621117794662d0
    iCoeffs(89 ) = 0.03663904625254d0
    iCoeffs(90 ) = 0.03706715616621d0
    iCoeffs(91 ) = 0.03749551078850d0
    iCoeffs(92 ) = 0.03792411323210d0
    iCoeffs(93 ) = 0.03835296662164d0
    iCoeffs(94 ) = 0.03878207409392d0
    iCoeffs(95 ) = 0.03921143879803d0
    iCoeffs(96 ) = 0.03964106389558d0
    iCoeffs(97 ) = 0.04007095256082d0
    iCoeffs(98 ) = 0.04050110798091d0
    iCoeffs(99 ) = 0.04093153335604d0
    iCoeffs(100) = 0.04136223189960d0
    iCoeffs(101) = 0.04179320683846d0
    iCoeffs(102) = 0.04222446141305d0
    iCoeffs(103) = 0.04265599887763d0
    iCoeffs(104) = 0.04308782250045d0
    iCoeffs(105) = 0.04351993556395d0
    iCoeffs(106) = 0.04395234136498d0
    iCoeffs(107) = 0.04438504321494d0
    iCoeffs(108) = 0.04481804444005d0
    iCoeffs(109) = 0.04525134838153d0
    iCoeffs(110) = 0.04568495839577d0
    iCoeffs(111) = 0.04611887785460d0
    iCoeffs(112) = 0.04655311014544d0
    iCoeffs(113) = 0.04698765867155d0
    iCoeffs(114) = 0.04742252685225d0
    iCoeffs(115) = 0.04785771812308d0
    iCoeffs(116) = 0.04829323593610d0
    iCoeffs(117) = 0.04872908376003d0
    iCoeffs(118) = 0.04916526508055d0
    iCoeffs(119) = 0.04960178340047d0
    iCoeffs(120) = 0.05003864223996d0
    iCoeffs(121) = 0.05047584513682d0
    iCoeffs(122) = 0.05091339564669d0
    iCoeffs(123) = 0.05135129734326d0
    iCoeffs(124) = 0.05178955381855d0
    iCoeffs(125) = 0.05222816868314d0
    iCoeffs(126) = 0.05266714556640d0
    iCoeffs(127) = 0.05310648811675d0
    iCoeffs(128) = 0.05354620000188d0
    iCoeffs(129) = 0.05398628490906d0
    iCoeffs(130) = 0.05442674654534d0
    iCoeffs(131) = 0.05486758863782d0
    iCoeffs(132) = 0.05530881493393d0
    iCoeffs(133) = 0.05575042920169d0
    iCoeffs(134) = 0.05619243522995d0
    iCoeffs(135) = 0.05663483682869d0
    iCoeffs(136) = 0.05707763782928d0
    iCoeffs(137) = 0.05752084208475d0
    iCoeffs(138) = 0.05796445347010d0
    iCoeffs(139) = 0.05840847588254d0
    iCoeffs(140) = 0.05885291324180d0
    iCoeffs(141) = 0.05929776949043d0
    iCoeffs(142) = 0.05974304859406d0
    iCoeffs(143) = 0.06018875454175d0
    iCoeffs(144) = 0.06063489134623d0
    iCoeffs(145) = 0.06108146304424d0
    iCoeffs(146) = 0.06152847369685d0
    iCoeffs(147) = 0.06197592738972d0
    iCoeffs(148) = 0.06242382823348d0
    iCoeffs(149) = 0.06287218036401d0
    iCoeffs(150) = 0.06332098794277d0
    iCoeffs(151) = 0.06377025515714d0
    iCoeffs(152) = 0.06421998622073d0
    iCoeffs(153) = 0.06467018537375d0
    iCoeffs(154) = 0.06512085688333d0
    iCoeffs(155) = 0.06557200504384d0
    iCoeffs(156) = 0.06602363417731d0
    iCoeffs(157) = 0.06647574863371d0
    iCoeffs(158) = 0.06692835279135d0
    iCoeffs(159) = 0.06738145105726d0
    iCoeffs(160) = 0.06783504786749d0
    iCoeffs(161) = 0.06828914768757d0
    iCoeffs(162) = 0.06874375501282d0
    iCoeffs(163) = 0.06919887436877d0
    iCoeffs(164) = 0.06965451031154d0
    iCoeffs(165) = 0.07011066742824d0
    iCoeffs(166) = 0.07056735033735d0
    iCoeffs(167) = 0.07102456368915d0
    iCoeffs(168) = 0.07148231216611d0
    iCoeffs(169) = 0.07194060048333d0
    iCoeffs(170) = 0.07239943338895d0
    iCoeffs(171) = 0.07285881566455d0
    iCoeffs(172) = 0.07331875212564d0
    iCoeffs(173) = 0.07377924762205d0
    iCoeffs(174) = 0.07424030703842d0
    iCoeffs(175) = 0.07470193529460d0
    iCoeffs(176) = 0.07516413734617d0
    iCoeffs(177) = 0.07562691818485d0
    iCoeffs(178) = 0.07609028283901d0
    iCoeffs(179) = 0.07655423637413d0
    iCoeffs(180) = 0.07701878389330d0
    iCoeffs(181) = 0.07748393053769d0
    iCoeffs(182) = 0.07794968148709d0
    iCoeffs(183) = 0.07841604196038d0
    iCoeffs(184) = 0.07888301721605d0
    iCoeffs(185) = 0.07935061255274d0
    iCoeffs(186) = 0.07981883330977d0
    iCoeffs(187) = 0.08028768486765d0
    iCoeffs(188) = 0.08075717264867d0
    iCoeffs(189) = 0.08122730211743d0
    iCoeffs(190) = 0.08169807878137d0
    iCoeffs(191) = 0.08216950819143d0
    iCoeffs(192) = 0.08264159594252d0
    iCoeffs(193) = 0.08311434767422d0
    iCoeffs(194) = 0.08358776907127d0
    iCoeffs(195) = 0.08406186586428d0
    iCoeffs(196) = 0.08453664383026d0
    iCoeffs(197) = 0.08501210879331d0
    iCoeffs(198) = 0.08548826662520d0
    iCoeffs(199) = 0.08596512324608d0
    iCoeffs(200) = 0.08644268462507d0
    iCoeffs(201) = 0.08692095678098d0
    iCoeffs(202) = 0.08739994578294d0
    iCoeffs(203) = 0.08787965775115d0
    iCoeffs(204) = 0.08836009885749d0
    iCoeffs(205) = 0.08884127532633d0
    iCoeffs(206) = 0.08932319343516d0
    iCoeffs(207) = 0.08980585951539d0
    iCoeffs(208) = 0.09028927995306d0
    iCoeffs(209) = 0.09077346118960d0
    iCoeffs(210) = 0.09125840972261d0
    iCoeffs(211) = 0.09174413210662d0
    iCoeffs(212) = 0.09223063495394d0
    iCoeffs(213) = 0.09271792493537d0
    iCoeffs(214) = 0.09320600878113d0
    iCoeffs(215) = 0.09369489328161d0
    iCoeffs(216) = 0.09418458528826d0
    iCoeffs(217) = 0.09467509171444d0
    iCoeffs(218) = 0.09516641953632d0
    iCoeffs(219) = 0.09565857579372d0
    iCoeffs(220) = 0.09615156759108d0
    iCoeffs(221) = 0.09664540209833d0
    iCoeffs(222) = 0.09714008655187d0
    iCoeffs(223) = 0.09763562825550d0
    iCoeffs(224) = 0.09813203458138d0
    iCoeffs(225) = 0.09862931297106d0
    iCoeffs(226) = 0.09912747093643d0
    iCoeffs(227) = 0.09962651606079d0
    iCoeffs(228) = 0.10012645599988d0
    iCoeffs(229) = 0.10062729848290d0
    iCoeffs(230) = 0.10112905131365d0
    iCoeffs(231) = 0.10163172237156d0
    iCoeffs(232) = 0.10213531961288d0
    iCoeffs(233) = 0.10263985107174d0
    iCoeffs(234) = 0.10314532486136d0
    iCoeffs(235) = 0.10365174917520d0
    iCoeffs(236) = 0.10415913228816d0
    iCoeffs(237) = 0.10466748255783d0
    iCoeffs(238) = 0.10517680842570d0
    iCoeffs(239) = 0.10568711841841d0
    iCoeffs(240) = 0.10619842114908d0
    iCoeffs(241) = 0.10671072531863d0
    iCoeffs(242) = 0.10722403971704d0
    iCoeffs(243) = 0.10773837322480d0
    iCoeffs(244) = 0.10825373481423d0
    iCoeffs(245) = 0.10877013355096d0
    iCoeffs(246) = 0.10928757859528d0
    iCoeffs(247) = 0.10980607920370d0
    iCoeffs(248) = 0.11032564473037d0
    iCoeffs(249) = 0.11084628462865d0
    iCoeffs(250) = 0.11136800845264d0
    iCoeffs(251) = 0.11189082585876d0
    iCoeffs(252) = 0.11241474660740d0
    iCoeffs(253) = 0.11293978056449d0
    iCoeffs(254) = 0.11346593770324d0
    iCoeffs(255) = 0.11399322810583d0
    iCoeffs(256) = 0.11452166196514d0
    iCoeffs(257) = 0.11505124958655d0
    iCoeffs(258) = 0.11558200138971d0
    iCoeffs(259) = 0.11611392791045d0
    iCoeffs(260) = 0.11664703980258d0
    iCoeffs(261) = 0.11718134783991d0
    iCoeffs(262) = 0.11771686291814d0
    iCoeffs(263) = 0.11825359605686d0
    iCoeffs(264) = 0.11879155840166d0
    iCoeffs(265) = 0.11933076122613d0
    iCoeffs(266) = 0.11987121593403d0
    iCoeffs(267) = 0.12041293406146d0
    iCoeffs(268) = 0.12095592727905d0
    iCoeffs(269) = 0.12150020739426d0
    iCoeffs(270) = 0.12204578635364d0
    iCoeffs(271) = 0.12259267624522d0
    iCoeffs(272) = 0.12314088930091d0
    iCoeffs(273) = 0.12369043789893d0
    iCoeffs(274) = 0.12424133456635d0
    iCoeffs(275) = 0.12479359198166d0
    iCoeffs(276) = 0.12534722297734d0
    iCoeffs(277) = 0.12590224054258d0
    iCoeffs(278) = 0.12645865782599d0
    iCoeffs(279) = 0.12701648813838d0
    iCoeffs(280) = 0.12757574495563d0
    iCoeffs(281) = 0.12813644192162d0
    iCoeffs(282) = 0.12869859285116d0
    iCoeffs(283) = 0.12926221173306d0
    iCoeffs(284) = 0.12982731273326d0
    iCoeffs(285) = 0.13039391019800d0
    iCoeffs(286) = 0.13096201865702d0
    iCoeffs(287) = 0.13153165282700d0
    iCoeffs(288) = 0.13210282761483d0
    iCoeffs(289) = 0.13267555812120d0
    iCoeffs(290) = 0.13324985964408d0
    iCoeffs(291) = 0.13382574768241d0
    iCoeffs(292) = 0.13440323793981d0
    iCoeffs(293) = 0.13498234632837d0
    iCoeffs(294) = 0.13556308897257d0
    iCoeffs(295) = 0.13614548221329d0
    iCoeffs(296) = 0.13672954261184d0
    iCoeffs(297) = 0.13731528695420d0
    iCoeffs(298) = 0.13790273225528d0
    iCoeffs(299) = 0.13849189576328d0
    iCoeffs(300) = 0.13908279496421d0
    iCoeffs(301) = 0.13967544758649d0
    iCoeffs(302) = 0.14026987160563d0
    iCoeffs(303) = 0.14086608524907d0
    iCoeffs(304) = 0.14146410700115d0
    iCoeffs(305) = 0.14206395560812d0
    iCoeffs(306) = 0.14266565008336d0
    iCoeffs(307) = 0.14326920971271d0
    iCoeffs(308) = 0.14387465405991d0
    iCoeffs(309) = 0.14448200297217d0
    iCoeffs(310) = 0.14509127658593d0
    iCoeffs(311) = 0.14570249533272d0
    iCoeffs(312) = 0.14631567994521d0
    iCoeffs(313) = 0.14693085146335d0
    iCoeffs(314) = 0.14754803124074d0
    iCoeffs(315) = 0.14816724095114d0
    iCoeffs(316) = 0.14878850259513d0
    iCoeffs(317) = 0.14941183850696d0
    iCoeffs(318) = 0.15003727136160d0
    iCoeffs(319) = 0.15066482418194d0
    iCoeffs(320) = 0.15129452034622d0
    iCoeffs(321) = 0.15192638359562d0
    iCoeffs(322) = 0.15256043804210d0
    iCoeffs(323) = 0.15319670817639d0
    iCoeffs(324) = 0.15383521887628d0
    iCoeffs(325) = 0.15447599541508d0
    iCoeffs(326) = 0.15511906347029d0
    iCoeffs(327) = 0.15576444913262d0
    iCoeffs(328) = 0.15641217891512d0
    iCoeffs(329) = 0.15706227976270d0
    iCoeffs(330) = 0.15771477906179d0
    iCoeffs(331) = 0.15836970465040d0
    iCoeffs(332) = 0.15902708482837d0
    iCoeffs(333) = 0.15968694836797d0
    iCoeffs(334) = 0.16034932452477d0
    iCoeffs(335) = 0.16101424304889d0
    iCoeffs(336) = 0.16168173419649d0
    iCoeffs(337) = 0.16235182874164d0
    iCoeffs(338) = 0.16302455798860d0
    iCoeffs(339) = 0.16369995378435d0
    iCoeffs(340) = 0.16437804853160d0
    iCoeffs(341) = 0.16505887520213d0
    iCoeffs(342) = 0.16574246735056d0
    iCoeffs(343) = 0.16642885912855d0
    iCoeffs(344) = 0.16711808529938d0
    iCoeffs(345) = 0.16781018125309d0
    iCoeffs(346) = 0.16850518302198d0
    iCoeffs(347) = 0.16920312729665d0
    iCoeffs(348) = 0.16990405144257d0
    iCoeffs(349) = 0.17060799351710d0
    iCoeffs(350) = 0.17131499228713d0
    iCoeffs(351) = 0.17202508724725d0
    iCoeffs(352) = 0.17273831863853d0
    iCoeffs(353) = 0.17345472746787d0
    iCoeffs(354) = 0.17417435552805d0
    iCoeffs(355) = 0.17489724541840d0
    iCoeffs(356) = 0.17562344056613d0
    iCoeffs(357) = 0.17635298524848d0
    iCoeffs(358) = 0.17708592461550d0
    iCoeffs(359) = 0.17782230471365d0
    iCoeffs(360) = 0.17856217251026d0
    iCoeffs(361) = 0.17930557591875d0
    iCoeffs(362) = 0.18005256382476d0
    iCoeffs(363) = 0.18080318611323d0
    iCoeffs(364) = 0.18155749369635d0
    iCoeffs(365) = 0.18231553854259d0
    iCoeffs(366) = 0.18307737370674d0
    iCoeffs(367) = 0.18384305336097d0
    iCoeffs(368) = 0.18461263282712d0
    iCoeffs(369) = 0.18538616861011d0
    iCoeffs(370) = 0.18616371843257d0
    iCoeffs(371) = 0.18694534127078d0
    iCoeffs(372) = 0.18773109739197d0
    iCoeffs(373) = 0.18852104839301d0
    iCoeffs(374) = 0.18931525724051d0
    iCoeffs(375) = 0.19011378831258d0
    iCoeffs(376) = 0.19091670744210d0
    iCoeffs(377) = 0.19172408196169d0
    iCoeffs(378) = 0.19253598075050d0
    iCoeffs(379) = 0.19335247428278d0
    iCoeffs(380) = 0.19417363467841d0
    iCoeffs(381) = 0.19499953575548d0
    iCoeffs(382) = 0.19583025308497d0
    iCoeffs(383) = 0.19666586404771d0
    iCoeffs(384) = 0.19750644789362d0
    iCoeffs(385) = 0.19835208580345d0
    iCoeffs(386) = 0.19920286095313d0
    iCoeffs(387) = 0.20005885858082d0
    iCoeffs(388) = 0.20092016605678d0
    iCoeffs(389) = 0.20178687295628d0
    iCoeffs(390) = 0.20265907113575d0
    iCoeffs(391) = 0.20353685481209d0
    iCoeffs(392) = 0.20442032064566d0
    iCoeffs(393) = 0.20530956782687d0
    iCoeffs(394) = 0.20620469816670d0
    iCoeffs(395) = 0.20710581619134d0
    iCoeffs(396) = 0.20801302924114d0
    iCoeffs(397) = 0.20892644757417d0
    iCoeffs(398) = 0.20984618447462d0
    iCoeffs(399) = 0.21077235636628d0
    iCoeffs(400) = 0.21170508293150d0
    iCoeffs(401) = 0.21264448723579d0
    iCoeffs(402) = 0.21359069585852d0
    iCoeffs(403) = 0.21454383903007d0
    iCoeffs(404) = 0.21550405077571d0
    iCoeffs(405) = 0.21647146906673d0
    iCoeffs(406) = 0.21744623597924d0
    iCoeffs(407) = 0.21842849786106d0
    iCoeffs(408) = 0.21941840550722d0
    iCoeffs(409) = 0.22041611434471d0
    iCoeffs(410) = 0.22142178462693d0
    iCoeffs(411) = 0.22243558163851d0
    iCoeffs(412) = 0.22345767591123d0
    iCoeffs(413) = 0.22448824345171d0
    iCoeffs(414) = 0.22552746598169d0
    iCoeffs(415) = 0.22657553119170d0
    iCoeffs(416) = 0.22763263300908d0
    iCoeffs(417) = 0.22869897188130d0
    iCoeffs(418) = 0.22977475507574d0
    iCoeffs(419) = 0.23086019699690d0
    iCoeffs(420) = 0.23195551952250d0
    iCoeffs(421) = 0.23306095235967d0
    iCoeffs(422) = 0.23417673342283d0
    iCoeffs(423) = 0.23530310923477d0
    iCoeffs(424) = 0.23644033535269d0
    iCoeffs(425) = 0.23758867682113d0
    iCoeffs(426) = 0.23874840865386d0
    iCoeffs(427) = 0.23991981634695d0
    iCoeffs(428) = 0.24110319642551d0
    iCoeffs(429) = 0.24229885702679d0
    iCoeffs(430) = 0.24350711852265d0
    iCoeffs(431) = 0.24472831418451d0
    iCoeffs(432) = 0.24596279089449d0
    iCoeffs(433) = 0.24721090990657d0
    iCoeffs(434) = 0.24847304766201d0
    iCoeffs(435) = 0.24974959666397d0
    iCoeffs(436) = 0.25104096641631d0
    iCoeffs(437) = 0.25234758443255d0
    iCoeffs(438) = 0.25366989732133d0
    iCoeffs(439) = 0.25500837195546d0
    iCoeffs(440) = 0.25636349673238d0
    iCoeffs(441) = 0.25773578293495d0
    iCoeffs(442) = 0.25912576620222d0
    iCoeffs(443) = 0.26053400812100d0
    iCoeffs(444) = 0.26196109795067d0
    iCoeffs(445) = 0.26340765449454d0
    iCoeffs(446) = 0.26487432813332d0
    iCoeffs(447) = 0.26636180303776d0
    iCoeffs(448) = 0.26787079957991d0
    iCoeffs(449) = 0.26940207696481d0
    iCoeffs(450) = 0.27095643610742d0
    iCoeffs(451) = 0.27253472278280d0
    iCoeffs(452) = 0.27413783108146d0
    iCoeffs(453) = 0.27576670720623d0
    iCoeffs(454) = 0.27742235365205d0
    iCoeffs(455) = 0.27910583381629d0
    iCoeffs(456) = 0.28081827709420d0
    iCoeffs(457) = 0.28256088452207d0
    iCoeffs(458) = 0.28433493504105d0
    iCoeffs(459) = 0.28614179246526d0
    iCoeffs(460) = 0.28798291325225d0
    iCoeffs(461) = 0.28985985518940d0
    iCoeffs(462) = 0.29177428712984d0
    iCoeffs(463) = 0.29372799993420d0
    iCoeffs(464) = 0.29572291880292d0
    iCoeffs(465) = 0.29776111721759d0
    iCoeffs(466) = 0.29984483275103d0
    iCoeffs(467) = 0.30197648505630d0
    iCoeffs(468) = 0.30415869640678d0
    iCoeffs(469) = 0.30639431523595d0
    iCoeffs(470) = 0.30868644322070d0
    iCoeffs(471) = 0.31103846657066d0
    iCoeffs(472) = 0.31345409233622d0
    iCoeffs(473) = 0.31593739073687d0
    iCoeffs(474) = 0.31849284475431d0
    iCoeffs(475) = 0.32112540854577d0
    iCoeffs(476) = 0.32384057663740d0
    iCoeffs(477) = 0.32664446638658d0
    iCoeffs(478) = 0.32954391690101d0
    iCoeffs(479) = 0.33254660853587d0
    iCoeffs(480) = 0.33566120835051d0
    iCoeffs(481) = 0.33889754862615d0
    iCoeffs(482) = 0.34226684793211d0
    iCoeffs(483) = 0.34578198755313d0
    iCoeffs(484) = 0.34945786091584d0
    iCoeffs(485) = 0.35331182031270d0
    iCoeffs(486) = 0.35736425629338d0
    iCoeffs(487) = 0.36163935709830d0
    iCoeffs(488) = 0.36616613153999d0
    iCoeffs(489) = 0.37097976970068d0
    iCoeffs(490) = 0.37612364937436d0
    iCoeffs(491) = 0.38165175247824d0
    iCoeffs(492) = 0.38763384153846d0
    iCoeffs(493) = 0.39415707842176d0
    iCoeffs(494) = 0.40135193157999d0
    iCoeffs(495) = 0.40934625195816d0
    iCoeffs(496) = 0.41852139102809d0
    iCoeffs(497) = 0.42870670111883d0
    iCoeffs(498) = 0.44247426151116d0
    iCoeffs(499) = 0.45345768744521d0
    iCoeffs(500) = 0.49146550996677d0
    iCoeffs(501) = 0.45882630283799d0
    iCoeffs(502) = 0.76343194636976d0
    iCoeffs(503) = 1.68678349423578d0
        
    ! derivative of cumulative normal distribution
    derNormal = 1.486719514734298d0 * 1E-6
        
    ! derivative of inverse cumulative normal distribution
    derNormalInv = 1d0 / derNormal
    
    ! set normal loaded to true
    normal_loaded = .true.

end subroutine loadNormal

end module normalProb
