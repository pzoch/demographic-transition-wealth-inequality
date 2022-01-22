!##############################################################################
! MODULE minimization
! 
! Minimizes a one- or multidimensional function on a rectangular interval.
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

module minimization


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
real*8,  private  :: gftol = 1e-8

! Maximum number of iterations
integer, private  :: itermax_min = 200

! Maximum number of iterations for brent_pow
integer, parameter, private  :: itermax_pow_b = 150

! Left optimization interval endpoints
real*8, allocatable, private :: minn(:)

! Right optimization interval endpoints
real*8, allocatable, private :: maxx(:)


!##############################################################################
! Communication variables                                               
!##############################################################################

! Point
real*8, allocatable, private :: pcom(:)

! Number of dimensions
integer, private :: ncom

! Directions
real*8, allocatable, private :: xicom(:)


!##############################################################################
! Interface declarations
!##############################################################################


!##############################################################################
! INTERFACE fminsearch
! 
! Finds minimum of a function.
!##############################################################################
interface fminsearch

    ! define methods used
    module procedure brent, powell
        
end interface


!##############################################################################
! Subroutines and functions                                               
!##############################################################################

contains


!##############################################################################
! SUBROUTINE settol_min
! 
! For setting global tolerance level.
!##############################################################################
subroutine settol_min(tol)
        
    implicit none
    
    
    !##### INPUT/OUTPUT VARIABLES #############################################

    ! tolerance level
    real*8, intent(in) :: tol
	
	
	!##### ROUTINE CODE #######################################################
	
	! check whether tolerance level is valid
	if(tol > 0d0)then
	    gftol = tol
	else
	    call warning('settol_min', 'tolerance level is not valid')    
	endif

end subroutine settol_min


!##############################################################################
! SUBROUTINE setiter_min
! 
! For setting maximum number of iterations.
!##############################################################################
subroutine setiter_min(iter)
        
    implicit none
    
    
    !##### INPUT/OUTPUT VARIABLES #############################################

    ! tolerance level
    integer, intent(in) :: iter
	
	
	!##### ROUTINE CODE #######################################################
	
	! check whether tolerance level is valid
	if(iter > 0)then
	    itermax_min = iter
	else
	    call warning('setiter_min', 'number of iterations is not valid')    
	endif

end subroutine setiter_min


!##############################################################################
! SUBROUTINE brent 
!
! Minimizes a one dimensional function.                         
!##############################################################################
subroutine brent(xmin, fret, minimum, maximum, func)

	implicit none
	
	
	!##### INPUT/OUTPUT VARIABLES #############################################
	
	! minimum value found
	real*8, intent(out) :: xmin
    
    ! function value at minimum
	real*8, intent(out) :: fret
	
	! left, middle and right interval points
	real*8, intent(in) :: minimum, maximum	
	
	
	!##### OTHER VARIABLES ####################################################
	
	real*8 :: tol    
	real*8, parameter :: cgold = 0.3819660d0
	real*8, parameter :: zeps = 1.0e-3*epsilon(xmin)
	real*8 :: a, b, d, e, etemp, fu, fv, fw, fx, p, q, r, tol1, tol2, &
	    u, v, w, x, xm, ax, bx, cx
    integer :: iter
	
	
	!##### INTERFACES #########################################################
	
	! interface for the function
    interface
        function func(p)
		    implicit none
		    real*8 :: p
            real*8 :: func
		end function func
	end interface
	
	
	!##### ROUTINE CODE #######################################################
	
	! set tolerance level
	tol =  gftol
    
    ! set ax, bx and cx
    ax = minimum
    cx = maximum
    bx = (ax+cx)/2d0
	
	a = min(ax, cx)
	b = max(ax, cx)
	v = bx
	w = v
	x = v
	e = 0d0
	fx = func(x)
	fv = fx
	fw = fx
	
	do iter = 1,itermax_min
		xm = 0.5d0*(a+b)
		tol1 = tol*abs(x)+zeps
		tol2 = 2.0d0*tol1
		
		if(abs(x-xm) <= (tol2-0.5d0*(b-a)))then
			xmin = x
			fret = fx
			return
		endif
		
		if(abs(e) > tol1)then
			r = (x-w)*(fx-fv)
			q = (x-v)*(fx-fw)
			p = (x-v)*q-(x-w)*r
			q = 2.0d0*(q-r)
			if (q > 0.0d0) p = -p
			q = abs(q)
			etemp = e
			e = d
			if(abs(p) >= abs(0.5d0*q*etemp) .or. &
				p <= q*(a-x) .or. p >= q*(b-x))then
				e = merge(a-x, b-x, x >= xm )
				d = CGOLD*e
			else
				d = p/q
				u = x+d
				if(u-a < tol2 .or. b-u < tol2) d = sign(tol1, xm-x)
			endif

		else
			e = merge(a-x, b-x, x >= xm )
			d = CGOLD*e
		endif
		u = merge(x+d, x+sign(tol1, d), abs(d) >= tol1 )
		fu = func(u)
		if(fu <= fx)then
			if(u >= x)then
				a = x
			else
				b = x
			endif
			call shft(v, w, x, u)
			call shft(fv, fw, fx, fu)
		else
			if(u < x)then
				a = u
			else
				b = u
			endif
			if(fu <= fw .or. w == x)then
				v = w
				fv = fw
				w = u
				fw = fu
			elseif(fu <= fv .or. v == x .or. v == w)then
				v = u
				fv = fu
			endif
		endif
	enddo
	call warning('fminsearch', 'maximum iterations exceeded')
	
	
	!##### SUBROUTINES AND FUNCTIONS ##########################################
	
	contains


    !##########################################################################
    ! SUBROUTINE shft
    !
    ! Shifts b to a, c to b and d to c.                         
    !##########################################################################
	subroutine shft(a, b, c, d)
	
	    implicit none
	    
	    
	    !##### INPUT/OUTPUT VARIABLES #########################################
	    
	    real*8, intent(out)   :: a
	    real*8, intent(inout) :: b, c
	    real*8, intent(in   ) :: d
	    
	    
	    !##### ROUTINE CODE ###################################################
	    a = b
	    b = c
	    c = d
	end subroutine shft
	
end subroutine brent



!##############################################################################
! SUBROUTINE powell 
! 
! Powell is a multidimensional function minimizer.
!##############################################################################
subroutine powell(p, fret, minimum, maximum, func)
    
    implicit none
    
    
    !##### INPUT/OUTPUT VARIABLES #############################################

    ! starting and ending point
    real*8, intent(inout) :: p(:)
	
	! value of function in minimum
	real*8, intent(out) :: fret	
	
	! minimum optimization interval point
	real*8, intent(in) :: minimum(:)
	
	! maximum optimization interval point
	real*8, intent(in) :: maximum(:)
	
	
    !##### OTHER VARIABLES ####################################################
	
	real*8 :: xi(size(p, 1), size(p, 1))
	real*8 :: ftol	
	real*8, parameter :: tiny = 1.0e-25
	integer :: i, ibig, n, iter
	real*8 :: del, fp, fptt, t
	real*8, dimension(size(p)) :: pt, ptt, xit	
	
	
	!##### INTERFACES #########################################################
	
	! interface for the function
    interface
		function func(p)
		    implicit none
		    real*8 :: p(:)
            real*8 :: func
		end function func
	end interface
	
	
	!##### ROUTINE CODE #######################################################
	
	! set tolerance level
	ftol = gftol
	
	! Set number of points
	n = assert_eq(size(p), size(minimum, 1), size(maximum,1), 'fminsearch')
    
    ! initialize direction set
    xi = 0d0
    do i = 1, n
        xi(i, i) = 1d0
    enddo
	
	! Allocate communication variables
	call setMinMax(minimum, maximum, n)
	
	! calculate function value
	fret = func(p)
	
	! store old p
	pt(:) = p(:)
	
	! start iteration
	iter = 0
	do
	    ! step counter
		iter = iter+1
		
		! save old function value
		fp = fret
		
		! ibig will be direction of steepest decline
		ibig = 0
		del = 0.0d0
		
		! iterate over all dimensions
		do i = 1, n
		
		    ! copy direction i and store old function value
			xit(:) = xi(:,i)
			fptt = fret
			
			! minimize along this direction
			call linmin(p, xit, n, fret, func)
			
			! store i into i big if i is the direction of steepest decline
			if (fptt-fret > del) then
				del=fptt-fret
				ibig=i
			endif
		enddo
		
		! termination criterion
		if (2d0*(fp - fret) <= ftol*(abs(fp) + abs(fret)) + tiny) return
		
		! quit if maximum iterations reached
		if (iter == itermax_min)then
		    call warning('fminsearch', 'maximum iterations exceeded')
		endif
			
	    ! construct extrapolated point
		ptt(:) = 2d0*p(:) - pt(:)
		xit(:) = p(:) - pt(:)
		pt(:) = p(:)
		
		! calculate function value at extrapolated point
		fptt = func(ptt)
		
		! if function value greater than actual value 
		! -> no change of directions
		if (fptt >= fp) cycle
		
		! calculate t
		t = 2d0*(fp - 2d0*fret + fptt) * (fp - fret - del)**2 &
		    - del*(fp - fptt)**2
		    
		! if t > 0 -> no change of directions
		if (t >= 0d0) cycle
		
		! else minimize along new direction and start new iteration
		call linmin(p, xit, n, fret, func)
		xi(:, ibig) = xi(:, n)
		xi(:,n) = xit(:)
	enddo
	
	
	!##### SUBROUTINES AND FUNCTIONS ##########################################
	
	contains
      
    
    !##########################################################################
    ! SUBROUTINE setMinMax 
    !
    ! Sets minimum and maximum of multidimensional maximization interval and 
    !     allocates communication variables.
    !##########################################################################
    subroutine setMinMax(minimum, maximum, n)

        implicit none


        !##### INPUT/OUTPUT VARIABLES #########################################

        ! left and right interval endpoint
        real*8, intent(in) :: minimum(n), maximum(n)
        
        ! number of dimensions to use
        integer, intent(in) :: n
        
        
        !##### ROUTINE CODE ###################################################
        
        ! deallocate endpoints if allocated
        if(allocated(minn))deallocate(minn)
        if(allocated(maxx))deallocate(maxx)
        
        ! allocate endpoints in right dimension
        allocate(minn(n))
        allocate(maxx(n))
        
        ! set interval endpoints
        minn(:) = minimum(:)
        maxx(:) = maximum(:)
        
        ! deallocate communication variables if allocated
        if(allocated(pcom))deallocate(pcom)
        if(allocated(xicom))deallocate(xicom)
        
        ! allocate communication variables
        allocate(pcom(n))
        allocate(xicom(n))

    end subroutine setMinMax


    !##########################################################################
    ! SUBROUTINE linmin 
    !
    ! Minimizes multidimensional function along a given direction.
    !##########################################################################
    subroutine linmin(p, xi, n, fret, func)
       
        implicit none
       
       
        !##### INPUT/OUTPUT VARIABLES #########################################
        
        ! point where to start and minimum if minimization is done
        real*8, intent(inout) :: p(n)
        
        ! direction in which to optimize
        real*8, intent(inout) :: xi(n)
        
        ! number of dimensions
        integer, intent(in) :: n
        
        ! value of function at minimum
        real*8, intent(out)  :: fret
        
        
        !##### OTHER VARIABLES ################################################
        
        real*8 :: tol
        real*8  :: ax, bx, cx, xmin    
        
        
        !##### INTERFACES #####################################################
    	
	    ! interface for the function
        interface
		    function func(p)
		        implicit none
		        real*8 :: p(:)
                real*8 :: func
		    end function func
	    end interface
    	
    	
	    !##### ROUTINE CODE ###################################################

        ! set tolerance level
        tol = gftol

        ! Copy communication variables
        ncom = n
        pcom(:) = p(:)
        xicom(:) = xi(:)

        ! get optimization interval
        call getintervall(ax, bx, cx)

        ! minimize function using one dimensional optimizer
        fret = brent_pow(ax, bx, cx, tol, xmin, func)

        ! calculate new direction and endpoint
        xi(:) = xmin*xi(:)
        p(:) = p(:)+xi(:)    
          
    end subroutine linmin


    !##########################################################################
    ! SUBROUTINE getinterval 
    !
    ! Calculates optimization interval along a given direction.
    !##########################################################################
    subroutine getintervall(ax, bx, cx)
      
        implicit none
      
        
        !##### INPUT/OUTPUT VARIABLES #########################################
        
        ! left, middle and right interval point
        real*8, intent(out) :: ax, bx, cx
        
        
        !##### OTHER VARIABLES ################################################
        
        integer :: i
        real*8  :: w(0:1,ncom)    


        !##### ROUTINE CODE ###################################################

        ! calculate right interval point
        cx = -1.e20
        do i = 1, ncom
            if(xicom(i) /= 0d0)then
                w(0,i) = (extr(i, 0, xicom(i))-pcom(i))/xicom(i)
            else
                w(0,i) = -1.e20
            endif
            if(w(0,i) > cx)cx = w(0, i)
        enddo

        ! calculate left interval point
        ax = 1.e20
        do i=1, ncom
            if(xicom(i) /= 0d0)then
                w(1,i) = (extr(i, 1, xicom(i))-pcom(i))/xicom(i)
            else
                w(1,i) = 1.e20
            endif
            if(w(1,i) < ax)ax = w(1,i)
        enddo
        
        ! calculate point in between [ax, cx]
        bx = 0d0
          
    end subroutine getintervall


    !##########################################################################
    ! FUNCTION extr
    !
    ! Calculates interval endpoint in a given dimension.
    !##########################################################################
    real*8 function extr(dim, maxxx, richt)
      
        implicit none
        
        
        !##### INPUT/OUTPUT VARIABLES #########################################
      
        ! dimension in which to search
        integer, intent(in) :: dim
        
        ! do you want the maximum or minimum endpoint
        integer, intent(in) :: maxxx 
        
        ! what is the optimization direction
        real*8 :: richt

        
        !##### ROUTINE CODE ###################################################

        if(richt > 0d0 .and. maxxx == 1 .or. richt < 0d0 .and. maxxx == 0)then
            extr = maxx(dim)
        else
            extr = minn(dim)
        endif    
          
    end function extr


    !##########################################################################
    ! FUNCTION f1dim
    !
    ! Maps multidimensional function and point/direction combo into 
    !     one-dimensional function.
    !##########################################################################
    function f1dim(x, func)

        implicit none


        !##### INPUT/OUTPUT VARIABLES #########################################
        
        ! point where to evaluate the multidimensional function
        real*8, intent(in)  :: x
        
        ! function value
        real*8 :: f1dim     
        
        
        !##### OTHER VARIABLES ################################################
        
        real*8 :: xt(ncom)
        
        
        !##### INTERFACES #####################################################
        
        ! interface for the function
        interface
		    function func(p)		
		        implicit none		    
		        real*8 :: p(:)
		        real*8 :: func
		    end function func
	    end interface
        
        
        !##### ROUTINE CODE ###################################################
        
        ! create point where to evaluate func
        xt(:) = pcom(:)+x*xicom(:)
        
        ! evaluate func at this point
        f1dim = func(xt)

    end function f1dim


    !##########################################################################
    ! FUNCTION brent_pow 
    !
    ! Minimizes a one dimensional function.                         
    !##########################################################################
    function brent_pow(ax, bx, cx, tol, xmin, func)

	    implicit none
    	
    	
	    !##### INPUT/OUTPUT VARIABLES #########################################
    	
	    ! left, middle and right interval points
	    real*8, intent(in) :: ax, bx, cx
    	
	    ! level of tolerance
	    real*8, intent(in) :: tol
    	
	    ! minimum value found
	    real*8, intent(out) :: xmin
    	
	    ! function value at minimum
	    real*8 :: brent_pow
    	
    	
	    !##### OTHER VARIABLES ################################################
    	
	    real*8, parameter :: cgold = 0.3819660d0
	    real*8, parameter :: zeps=1.0e-3*epsilon(ax)
	    integer :: iter
	    real*8 :: a, b, d, e, etemp, fu, fv, fw, fx, p, q, r, tol1, tol2, &
	        u, v, w, x, xm
    	
    	
	    !##### INTERFACES #####################################################
    	
	    ! interface for the function
        interface
		    function func(p)		
		        implicit none
		        real*8 :: p(:)
		        real*8 :: func
		    end function func
	    end interface
    	
    	
	    !##### ROUTINE CODE ###################################################
    	
	    a = min(ax, cx)
	    b = max(ax, cx)
	    v = bx
	    w = v
	    x = v
	    e = 0d0
	    fx = f1dim(x, func)
	    fv = fx
	    fw = fx
    	
	    do iter = 1,itermax_pow_b
		    xm = 0.5d0*(a+b)
		    tol1 = tol*abs(x)+zeps
		    tol2 = 2.0d0*tol1
    		
		    if(abs(x-xm) <= (tol2-0.5d0*(b-a)))then
			    xmin = x
			    brent_pow = fx
			    return
		    endif
    		
		    if(abs(e) > tol1)then
			    r = (x-w)*(fx-fv)
			    q = (x-v)*(fx-fw)
			    p = (x-v)*q-(x-w)*r
			    q = 2.0d0*(q-r)
			    if (q > 0.0d0) p = -p
			    q = abs(q)
			    etemp = e
			    e = d
			    if(abs(p) >= abs(0.5d0*q*etemp) .or. &
				    p <= q*(a-x) .or. p >= q*(b-x))then
				    e = merge(a-x, b-x, x >= xm )
				    d = CGOLD*e
			    else
				    d = p/q
				    u = x+d
				    if(u-a < tol2 .or. b-u < tol2) d = sign(tol1, xm-x)
			    endif

		    else
			    e = merge(a-x, b-x, x >= xm )
			    d = CGOLD*e
		    endif
		    u = merge(x+d, x+sign(tol1, d), abs(d) >= tol1 )
		    fu = f1dim(u, func)
		    if(fu <= fx)then
			    if(u >= x)then
				    a = x
			    else
				    b = x
			    endif
			    call shft(v, w, x, u)
			    call shft(fv, fw, fx, fu)
		    else
			    if(u < x)then
				    a = u
			    else
				    b = u
			    endif
			    if(fu <= fw .or. w == x)then
				    v = w
				    fv = fw
				    w = u
				    fw = fu
			    elseif(fu <= fv .or. v == x .or. v == w)then
				    v = u
				    fv = fu
			    endif
		    endif
	    enddo
	    call warning('brent', 'maximum iterations exceeded')
    	
    end function brent_pow


    !##########################################################################
    ! SUBROUTINE shft
    !
    ! Shifts b to a, c to b and d to c.                         
    !##########################################################################
	subroutine shft(a, b, c, d)
	
	    implicit none
	    
	    
	    !##### INPUT/OUTPUT VARIABLES #########################################
	    
	    real*8, intent(out)   :: a
	    real*8, intent(inout) :: b, c
	    real*8, intent(in   ) :: d
	    
	    
	    !##### ROUTINE CODE ###################################################
	    a = b
	    b = c
	    c = d
	end subroutine shft
    
end subroutine powell

end module minimization