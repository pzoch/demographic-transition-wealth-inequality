!##############################################################################
! MODULE rootfinding
! 
! Finds zeros of multidimensional function.
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

module rootfinding


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
! Declaration of variables                                                  
!##############################################################################

! Level of tolerance for all routines
real*8,  private  :: gftol_root = 1e-8

! Maximum number of iterations for broydn
integer, private  :: itermax_root = 6000


!##############################################################################
! Communication variables                                               
!##############################################################################

! Value of the function that should be set to zero
real*8, allocatable, private :: fvec(:)


!##############################################################################
! Interface declarations
!##############################################################################


!##############################################################################
! INTERFACE fzero
! 
! Finds root of a function.
!##############################################################################
interface fzero

    ! define methods used
    module procedure newton_interpol, broydn
        
end interface


!##############################################################################
! Subroutines and functions                                               
!##############################################################################

contains


!##############################################################################
! SUBROUTINE settol_root
! 
! For setting global tolerance level.
!##############################################################################
subroutine settol_root(tol)
        
    implicit none
    
    
    !##### INPUT/OUTPUT VARIABLES #############################################

    ! tolerance level
    real*8, intent(in) :: tol
	
	
	!##### ROUTINE CODE #######################################################
	
	! check whether tolerance level is valid
	if(tol > 0d0)then
	    gftol_root = tol
	else
	    call warning('settol_root', 'tolerance level is not valid')    
	endif

end subroutine settol_root


!##############################################################################
! SUBROUTINE setiter_root
! 
! For setting maximum number of iterations.
!##############################################################################
subroutine setiter_root(iter)
        
    implicit none
    
    
    !##### INPUT/OUTPUT VARIABLES #############################################

    ! number of iterations
    integer, intent(in) :: iter
	
	
	!##### ROUTINE CODE #######################################################
	
	! check whether number of iterations is valid
	if(iter > 0)then
	    itermax_root = iter
	else
	    call warning('setiter_root', 'number of iterations is not valid')    
	endif

end subroutine setiter_root


!##############################################################################
! SUBROUTINE newton_interpol
! 
! Find root of one-dimensional function by interpolatory newton method.
!##############################################################################
subroutine newton_interpol(x, funcv, check_return)
	
    implicit none
    
    
    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! initial guess and root of the function
    real*8, intent(inout) :: x
    
    ! check is true if broydn converged to local minimum or can make no 
    !     further progress
    logical, intent(out), optional :: check_return
    
    !##### OTHER VARIABLES ####################################################
    
    real*8, parameter :: eps = epsilon(x)
    real*8 :: tolf, tolmin
    real*8, parameter :: tolx = eps
    real*8, parameter :: stpmx = 100d0
    real*8 :: x1, x2, f1, f2, xnew, fnew
    integer :: its
    logical :: check


    !##### INTERFACES #########################################################

    ! interface for the function
    interface
        function funcv(p)		
            implicit none
            real*8 :: p
            real*8 :: funcv
        end function funcv
    end interface
    
    
    !##### ROUTINE CODE #######################################################

    ! set tolerance levels
    tolf = gftol_root
    tolmin = gftol_root

    ! initialize values
    x1 = x
    x2 = x + 0.001d0
    
    ! calculate function values at x1, x2
    f1 = funcv(x1)
    f2 = funcv(x2)
    
    ! check if already in zero
    if(abs(f1) < tolf)then
        x = x1
        if(present(check_return))check_return = .false.
        return
    endif
    
    if(abs(f2) < tolf)then
        x = x2
        if(present(check_return))check_return = .false.
        return
    endif
    
    ! start iteration
    do its = 1, itermax_root
        
        ! calculate new point xnew
        xnew = x2 - (x2-x1)/(f2-f1)*f2
        
        ! calculate new function value
        fnew = funcv(xnew)
        
        ! check wether function is small enough
        if(abs(fnew) < tolf)then
            x = xnew
            if(present(check_return))check_return = .false.
            return
        endif
        
        ! check whether you are in a minimum or cannot proceed further
        if(abs((f2-f1)/(x2-x1)) < tolmin .or. &
            2d0*abs(xnew-x2) < tolx*abs(xnew+x2))then
            x = x2
            if(present(check_return))check_return = .true.
            return
        endif
        
        ! else set new data and repeat step
        x1 = x2
        f1 = f2
        x2 = xnew
        f2 = fnew
    enddo
    
    ! throw warning if newton didn't converge
!    call warning('fzero', 'fzero exceeds maximum iterations')	
    
    x = xnew
    
end subroutine newton_interpol


!##############################################################################
! SUBROUTINE broydn
! 
! Find root of multidimensional function of.
!##############################################################################
subroutine broydn(x, funcv, check_return)
	
    implicit none
    
    
    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! initial guess and root of the function
    real*8, intent(inout) :: x(:)
    
    ! check is true if broydn converged to local minimum or can make no 
    !     further progress
    logical, intent(out), optional :: check_return
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8, parameter :: eps = epsilon(x)
    real*8 :: tolf, tolmin
    real*8, parameter :: tolx = eps
    real*8, parameter :: stpmx = 100d0    
    integer :: i, j, k, its, n
    real*8 :: f, fold, stpmax
    real*8, dimension(size(x)) :: c, d, fvcold, g, p, s, t, w, xold
    real*8, dimension(size(x),size(x)) :: qt, r
    logical :: restrt, sing, check   


    !##### INTERFACES #########################################################

    ! interface for the function
    interface
        function funcv(p)		
            implicit none
            real*8 :: p(:)
            real*8 :: funcv(size(p, 1))
        end function funcv
    end interface
    
    
    !##### ROUTINE CODE #######################################################	
    
    ! set tolerance levels
    tolf = gftol_root
    tolmin = gftol_root
    
    ! get size of x
    n = size(x)
    
    ! allocate fvec
    if(allocated(fvec))deallocate(fvec)
    allocate(fvec(n))
    
    ! calculate function euklidean norm at starting point
    f = fmin(x, funcv)
    
    ! check if root has been found
    if (maxval(abs(fvec(:))) < 0.01d0*tolf) then
        if(present(check_return))check_return = .false.        
	    return
    endif
    	
    stpmax = stpmx*max(sqrt(dot_product(x(:),x(:))),dble(n))
    restrt=.true.
    
    ! iterate broydn steps
    do its=1,itermax_root
        
        ! If restart then calculate jacobian of function
        if (restrt) then
        
            ! calculate jacobian of func at x
            call fdjac(x, fvec, r, funcv)
            
            ! make q-r-decomposition of jacobian
            call qrdcmp(r, c, d, sing)
            
            ! throw error if jacobian is singular
            if(sing)call error('broydn', 'singular jacobian in broydn')
            
            ! create unity matrix 
            qt(:,:) = 0d0
	        do j = 1, n
		        qt(j, j) = 1d0
	        enddo
            
            ! for Q^T explicitly
            do k = 1, n-1
                if (c(k) /= 0d0) then
                    qt(k:n,:) = qt(k:n, :)-outerprod(r(k:n, k), &
                        matmul(r(k:n, k), qt(k:n, :)))/c(k)
                endif
            enddo
            where(lower_triangle(n,n))r(:, :) = 0d0
            
            ! puts diagonal elements of R matrix to r
            do j = 1, n
		        r(j, j) = d(j)
	        enddo
			
        ! else do Broydn update step
        else
            
            ! set up s as delta x
            s(:) = x(:)-xold(:)

            ! t = R*delta x
            do i = 1, n
                t(i) = dot_product(r(i,i:n), s(i:n))
            enddo
            
            ! w = delta f - B*s = delta f - R*s*Q^T
            w(:) = fvec(:)-fvcold(:)-matmul(t(:), qt(:,:))
            
            ! if w entries are small enough, set them to zero
            where(abs(w(:)) < EPS*(abs(fvec(:))+abs(fvcold(:)))) w(:) = 0d0
            
            ! update for non-noisy components of w
            if(any(w(:) /= 0.0))then
                
                ! update t and s
                t(:) = matmul(qt(:,:),w(:))
                s(:)=s(:)/dot_product(s,s)
                
                ! update R and Q^T
                call qrupdt(r,qt,t,s)
                
                ! get diagonal of matrix r
                do j = 1, size(r,1)
                    d(j) = r(j,j)
                enddo
				
                ! if any diagonal value of r is 0, then jacobian is singular
                if(any(d(:) == 0d0))&
                    call error('broydn', 'singular jacobian in broydn')
            endif
        endif
        
        ! perform the newton step by inverting jacobian		
        p(:) = -matmul(qt(:,:), fvec(:))
        do i = 1, n
            g(i) = -dot_product(r(1:i,i), p(1:i))
        enddo
        
        ! store old x, function value and function norm
        xold(:) = x(:)
        fvcold(:) = fvec(:)
        fold = f
        
        ! solve linear equation with upper triangular matrix r
        call rsolv(r, d, p)
        
        ! searches along the new gradient direction for new x and f
        call lnsrch(xold, fold, g, p, x, f, stpmax, check, funcv)
        
        ! check whether root was found
        if(maxval(abs(fvec(:))) < tolf)then
            if(present(check_return))check_return = .false.            
            return
        endif
		
		! if check is true 
        if(check)then
            
            ! check if improvement can be made, if not, return
            if(restrt .or. maxval(abs(g(:))*max(abs(x(:)), &
                1d0)/max(f, 0.5d0*n)) < tolmin)then
                if(present(check_return))check_return = check
                return
            endif
            
            ! else calculate new jacobian
            restrt=.true.
            
        ! if check is false
        else
            
            ! do broydn step
            restrt=.false.
            
            ! check for convergence
            if (maxval((abs(x(:)-xold(:)))/max(abs(x(:)), &
                1.0d0)) < tolx)then
                if(present(check_return))check_return = check
                return
            endif
        endif
    enddo
	
    ! throw warning if broydn didn't converge
!    call warning('fzero', 'fzero exceeds maximum iterations')	
    
    
    !##### SUBROUTINES AND FUNCTIONS ##########################################
    
    contains
    	
	
    !##########################################################################
    ! FUNCTION fdjac
    ! 
    ! Calculates finite difference jacobian.
    !##########################################################################
    subroutine fdjac(x, fvec, df, funcv)
        
        implicit none


        !##### INPUT/OUTPUT VARIABLES #########################################

        ! value where to calculate finite difference jacobian
        real*8, intent(inout) :: x(:)

        ! function value at x
        real*8, intent(in) :: fvec(:)	    

        ! resulting finite difference jacobian
        real*8, intent(out) :: df(:, :)


        !##### OTHER VARIABLES ################################################

        real*8, parameter :: eps = 1.0e-6
        integer :: j, n
        real*8, dimension(size(x)) :: xsav, xph, h


        !##### INTERFACES #####################################################

        ! interface for the function
        interface
            function funcv(p)
                implicit none
                real*8 :: p(:)
                real*8 :: funcv(size(p, 1))
            end function funcv
        end interface


        !##### ROUTINE CODE ###################################################

        ! check equality of sizes
        n = assert_eq(size(x), size(fvec), size(df,1), size(df,2), 'fdjac')

        ! store old x
        xsav = x

        ! calculate difference
        h = eps*abs(xsav)	    
        where(h == 0d0)h = EPS

        ! calculate x + h
        xph = xsav + h
        h = xph - xsav

        ! itertate over dimensions and calculate difference
        do j = 1, n
            x(j) = xph(j)
            df(:,j) = (funcv(x)-fvec(:))/h(j)
            x(j) = xsav(j)
        enddo

    end subroutine fdjac
	
	
	!##########################################################################
    ! FUNCTION lnsrch
    ! 
    ! Finds point along a line, given function value and gradient, where 
    !     function has decreased sufficiently (for one dimensional function).
    !##########################################################################
    subroutine lnsrch(xold, fold, g, p, x, f, stpmax, check, funcv)

        implicit none


        !##### INPUT/OUTPUT VARIABLES #########################################
        
        ! point where to start line search
        real*8, intent(in) :: xold(:)
        
        ! the old function value
        real*8, intent(in) :: fold
        
        ! gradient at this point
        real*8, intent(in) :: g(:)
        
        ! a line search direction
        real*8, intent(inout) :: p(:)
        
        ! new value along the search line
        real*8, intent(out) :: x(:)
        
        ! function value at new x
        real*8, intent(out) :: f
        
        ! maximum size of steps such that lnsrch does not search un undefined
        !     areas
        real*8, intent(in) :: stpmax
                        
        ! is true if x is too close at xold
        logical, intent(out) :: check
        
        
        !##### OTHER VARIABLES ################################################
        
        real*8, parameter :: alf = 1.0e-4
        real*8, parameter :: tolx = epsilon(x)
        integer :: ndum
        real*8 :: a, alam, alam2, alamin, b, disc, f2, pabs, rhs1, rhs2, &
            slope, tmplam
                        

        !##### INTERFACES #####################################################

        ! interface for the function
        interface
            function funcv(p)		
                implicit none
                real*8 :: p(:)
                real*8 :: funcv(size(p, 1))
            end function funcv
        end interface
        
        
        !##### ROUTINE CODE ###################################################    
        
        ! assert sizes or arrays
        ndum = assert_eq(size(g), size(p), size(x), size(xold), 'lnsrch')
        
        ! set check's default value
        check=.false.
        
        ! calculate norm of p
        pabs = sqrt(dot_product(p, p))
        
        ! restrict p to maximum stepsize
        if(pabs > stpmax)p(:) = p(:)*stpmax/pabs
        
        ! calculate slope
        slope = dot_product(g, p)
        
        ! throw error if you would go uphill
        if(slope >= 0d0)call error('lnsrch', &
            'roundoff problem, I cannot go uphill')

        ! calculate newton stepsize
        alamin = tolx/maxval(abs(p(:))/max(abs(xold(:)),1d0))
        alam = 1d0
        
        ! start iteration
        do
            ! calculate calculate new x
            x(:) = xold(:)+alam*p(:)
            
            ! calculate new function value at x
            f = fmin(x, funcv)
            
            ! if new x is not away enough return with check=true
            if(alam < alamin)then
                x(:) = xold(:)
                check = .true.
                return
            
            ! if optimal value found return with false
            elseif(f <= fold+alf*alam*slope)then
                return
                
            ! else do backtracking
            else
                if(alam == 1d0)then
                    tmplam = -slope/(2d0*(f-fold-slope))
                else
                    rhs1 = f-fold-alam*slope
                    rhs2 = f2-fold-alam2*slope
                    a = (rhs1/alam**2-rhs2/alam2**2)/(alam-alam2)
                    b = (-alam2*rhs1/alam**2+alam*rhs2/alam2**2)/(alam-alam2)
                    if(a == 0d0)then
                        tmplam = -slope/(2d0*b)
                    else
                        disc = b*b-3d0*a*slope
                        if(disc < 0d0)then
                            tmplam = 0.5d0*alam
                        elseif(b <= 0d0)then
                            tmplam = (-b+sqrt(disc))/(3d0*a)
                        else
                            tmplam = -slope/(b+sqrt(disc))
                        endif
                    endif
                    if(tmplam > 0.5d0*alam)tmplam = 0.5d0*alam
                endif
            endif
            alam2 = alam
            f2 = f
            alam = max(tmplam,0.1d0*alam)
        enddo

    end subroutine lnsrch
    
    
    !##########################################################################
    ! FUNCTION fmin
    ! 
    ! Calculates vector norm of multidimensional function.
    !##########################################################################
    function fmin(x, funcv)
    
        implicit none
        
        
        !##### INPUT/OUTPUT VARIABLES #########################################
        
        ! value where to evaluate function
        real*8, intent(in) :: x(:)
        
        ! euklidean square norm of function at x
        real*8 :: fmin


        !##### INTERFACES #####################################################

        ! interface for the function
        interface
            function funcv(p)		
                implicit none
                real*8 :: p(:)
                real*8 :: funcv(size(p, 1))
            end function funcv
        end interface
        
        ! calculate function value
        fvec = funcv(x)
        
        ! calculate squared norm
        fmin = 0.5d0*dot_product(fvec, fvec)
        
    end function fmin
	
	
	
	!##########################################################################
    !##### MATRIX TOOLS #######################################################
    !##########################################################################
    
    
    !##########################################################################
    ! SUBROUTINE qrdcmp
    ! 
    ! Calculates QR decomposition of a matrix.
    !##########################################################################
    subroutine qrdcmp(a, c, d, sing)
        
        implicit none
        
        real*8, intent(inout) :: a(:, :)
        real*8, intent(out) :: c(:), d(:)
        logical, intent(out) :: sing
        integer :: k, n
        real*8 :: scale, sigma
        
        n = assert_eq(size(a,1), size(a,2), size(c), size(d), 'qrdcmp')
        sing = .false.
        do k = 1, n-1
            scale = maxval(abs(a(k:n, k)))
            if(scale == 0d0)then
	            sing = .true.
	            c(k) = 0d0
	            d(k) = 0d0
            else
	            a(k:n, k) = a(k:n, k)/scale
	            sigma = sign(sqrt(dot_product(a(k:n, k),a(k:n, k))),a(k, k))
	            a(k,k) = a(k, k)+sigma
	            c(k) = sigma*a(k, k)
	            d(k) = -scale*sigma
	            a(k:n, k+1:n) = a(k:n, k+1:n)-outerprod(a(k:n, k),&
		            matmul(a(k:n, k),a(k:n, k+1:n)))/c(k)
            endif
        enddo
        d(n) = a(n, n)
        if (d(n) == 0d0) sing = .true.
        
    end subroutine qrdcmp
    
    
    !##########################################################################
    ! SUBROUTINE qrupdt
    ! 
    ! Updates qr-matrices.
    !##########################################################################
    subroutine qrupdt(r,qt,u,v)
        
        implicit none
        
        real*8, intent(inout) :: r(:, :), qt(:, :)
        real*8, intent(inout) :: u(:)
        real*8, intent(in) :: v(:)
        integer :: i, k, n
        
        n = assert_eq((/ size(r,1), size(r,2), size(qt,1), size(qt,2), &
            size(u), size(v)/), 'qrupdt')
        k = n+1-ifirstloc(u(n:1:-1) /= 0.0)
        if(k < 1)k=1
        do i = k-1, 1, -1
            call rotate(r,qt,i,u(i),-u(i+1))
            u(i) = pythag(u(i),u(i+1))
        enddo
        r(1,:) = r(1,:)+u(1)*v
        do i = 1,k-1
            call rotate(r,qt,i,r(i,i),-r(i+1,i))
        enddo
    end subroutine qrupdt
    
    !##########################################################################
    ! SUBROUTINE rsolv
    ! 
    ! Solves upper diagonal system.
    !##########################################################################
    subroutine rsolv(a, d, b)

        implicit none
        
        real*8, intent(in) :: a(:, :), d(:)
        real*8, intent(inout) :: b(:)
        integer :: i, n
        
        n = assert_eq(size(a,1), size(a,2), size(b), size(d), 'rsolv')
        b(n) = b(n)/d(n)
        do i = n-1, 1, -1
	        b(i) =( b(i)-dot_product(a(i, i+1:n),b(i+1:n)))/d(i)
        enddo
        
    end subroutine rsolv

    
    subroutine rotate(r, qt, i, a, b)
    
        implicit none
        
        real*8, intent(inout) :: r(:, :), qt(:, :)
        integer, intent(in) :: i
        real*8, intent(in) :: a, b        
        integer :: n
        real*8 :: c, fact, s, temp(size(r,1))
        
        n = assert_eq(size(r,1), size(r,2), size(qt,1), size(qt,2), 'rotate')
        if(a == 0d0)then
            c = 0d0
            s = sign(1d0, b)
        elseif(abs(a) > abs(b))then
            fact = b/a
            c = sign(1d0/sqrt(1d0+fact**2), a)
            s = fact*c
        else
            fact = a/b
            s = sign(1d0/sqrt(1d0+fact**2), b)
            c=fact*s
        endif
        temp(i:n) = r(i, i:n)
        r(i, i:n) = c*temp(i:n)-s*r(i+1, i:n)
        r(i+1, i:n) = s*temp(i:n)+c*r(i+1, i:n)
        temp = qt(i, :)
        qt(i, :) = c*temp-s*qt(i+1, :)
        qt(i+1, :) = s*temp+c*qt(i+1, :)
        
    end subroutine rotate
    
   
    function pythag(a, b)
        
        implicit none
        
        real*8, intent(in) :: a, b
        real*8 :: pythag
        real*8 :: absa, absb
        
        absa = abs(a)
        absb = abs(b)
        if(absa > absb)then
            pythag = absa*sqrt(1d0+(absb/absa)**2)
        else
            if(absb == 0d0)then
                pythag = 0d0
            else
                pythag = absb*sqrt(1d0+(absa/absb)**2)
            endif
        endif
        
    end function pythag
    
    
    function ifirstloc(mask)
    
        logical, intent(in) :: mask(:)
        integer :: ifirstloc, loca(1) 
        
        loca = maxloc(merge(1, 0, mask))
        ifirstloc = loca(1)
        if(.not. mask(ifirstloc))ifirstloc = size(mask)+1
        
    end function ifirstloc
    
    
    function lower_triangle(j, k, extra)

        integer, intent(in) :: j, k
        integer, intent(in), optional :: extra
        logical :: lower_triangle(j, k)
        integer :: n
        
        n = 0
        if(present(extra))n = extra
        
        lower_triangle = (outerdiff(arth_i(1, 1, j), arth_i(1, 1, k)) > -n)
        
    end function lower_triangle
    
    
    function outerdiff(a, b)
        
        integer, intent(in) :: a(:), b(:)
        integer :: outerdiff(size(a, 1),size(b, 1))
        
        outerdiff = spread(a, dim=2, ncopies=size(b, 1)) - &
            spread(b, dim=1, ncopies=size(a, 1))
            
    end function outerdiff
    
    
    function outerprod(a, b)
    
        real*8, intent(in) :: a(:), b(:)
        real*8 :: outerprod(size(a, 1),size(b, 1))
        
        outerprod = spread(a, dim=2, ncopies=size(b, 1)) * &
            spread(b, dim=1, ncopies=size(a, 1))
        
    end function outerprod
    
    
    function arth_i(first, increment, n)
    
        integer, intent(in) :: first, increment, n
        integer, parameter :: npar_arth = 16
        integer, parameter :: npar2_arth = 8
        integer :: arth_i(n)
        integer :: k, k2, temp
        
        if(n > 0)arth_i(1) = first
        if(n <= npar_arth) then
            do k = 2, n
                arth_i(k) = arth_i(k-1) + increment
            enddo
        else
            do k = 2, npar2_arth
                arth_i(k) = arth_i(k-1) + increment
            enddo
            temp = increment*npar2_arth
            k = npar2_arth
            do
                if(k >= n)exit
                k2 = k+k
                arth_i(k+1:min(k2,n)) = temp+arth_i(1:min(k,n-k))
                temp = temp + temp
                k = k2
            enddo
        endif
    end function arth_i
    
end subroutine broydn

end module rootfinding