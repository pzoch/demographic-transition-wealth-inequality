!##############################################################################
! MODULE matrixtools
! 
! Module for some matrix tools.
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
module matrixtools


!##############################################################################
! Declaration of modules used
!##############################################################################

! for assertion of equality in dimensions
use assertions, only: assert_eq

! for throwing error messages
use errwarn

implicit none

save


!##############################################################################
! Interface declarations
!##############################################################################


!##############################################################################
! INTERFACE mat_mult
! 
! Multiplies up to 6 matrices.
!##############################################################################
interface mat_mult

    ! define methods used
    module procedure mat_mult2, mat_mult3, mat_mult4, mat_mult5, mat_mult6
        
end interface


!##############################################################################
! Subroutines and functions                                               
!##############################################################################

contains


!##############################################################################
! FUNCTION mat_trans
! 
! Transposes a matrix.
!##############################################################################
function mat_trans(a)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! matrix of the system
    real*8, intent(in) :: a(:, :)

    ! the inverse of the matrix
    real*8 :: mat_trans(size(a, 2), size(a, 1))
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: j
    
        
    !##### ROUTINE CODE #######################################################
	
	! sucessively transpose
	do j = 1, size(a,1)
	    mat_trans(:, j) = a(j, :)
	enddo

end function mat_trans


!##############################################################################
! FUNCTION mat_mult2
! 
! Multiplies two matrices a*b.
!##############################################################################
function mat_mult2(a, b) result(mat)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! matrix number one
    real*8, intent(in) :: a(:, :)

    ! matrix number two
    real*8, intent(in) :: b(:, :)
    
    ! the result
    real*8 :: mat(size(a, 1), size(b, 2))
    
    
    !##### OTHER VARIABLES ####################################################
        
    integer :: j, k, n
    
        
    !##### ROUTINE CODE #######################################################
    
    ! assert equality of dimensions
    n = assert_eq(size(a, 2), size(b, 1), 'mat_mult')    
	
	! sucessively multiply rows and columns
	do j = 1, size(a,1)
	    do k = 1, size(b, 2)
	        mat(j, k) = sum(a(j, :)*b(:, k))
	    enddo	 
	enddo

end function mat_mult2


!##############################################################################
! FUNCTION mat_mult3
! 
! Multiplies three matrices a*b*c.
!##############################################################################
function mat_mult3(a, b, c) result(mat)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! matrix number one
    real*8, intent(in) :: a(:, :)

    ! matrix number two
    real*8, intent(in) :: b(:, :)
    
    ! matrix number three
    real*8, intent(in) :: c(:, :)
    
    ! the result
    real*8 :: mat(size(a, 1), size(c, 2))
    
    
    !##### OTHER VARIABLES ####################################################
    
        
    !##### ROUTINE CODE #######################################################   
	
	! sucessively multiply rows and columns
	mat = mat_mult2(a, mat_mult2(b, c))

end function mat_mult3


!##############################################################################
! FUNCTION mat_mult4
! 
! Multiplies four matrices a*b*c*d.
!##############################################################################
function mat_mult4(a, b, c, d) result(mat)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! matrix number one
    real*8, intent(in) :: a(:, :)

    ! matrix number two
    real*8, intent(in) :: b(:, :)
    
    ! matrix number three
    real*8, intent(in) :: c(:, :)
    
    ! matrix number four
    real*8, intent(in) :: d(:, :)
    
    ! the result
    real*8 :: mat(size(a, 1), size(d, 2))
    
    
    !##### OTHER VARIABLES ####################################################
    
        
    !##### ROUTINE CODE #######################################################   
	
	! sucessively multiply rows and columns
	mat = mat_mult2(a, mat_mult3(b, c, d))

end function mat_mult4


!##############################################################################
! FUNCTION mat_mult5
! 
! Multiplies four matrices a*b*c*d*e.
!##############################################################################
function mat_mult5(a, b, c, d, e) result(mat)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! matrix number one
    real*8, intent(in) :: a(:, :)

    ! matrix number two
    real*8, intent(in) :: b(:, :)
    
    ! matrix number three
    real*8, intent(in) :: c(:, :)
    
    ! matrix number four
    real*8, intent(in) :: d(:, :)
    
    ! matrix number five
    real*8, intent(in) :: e(:, :)
    
    ! the result
    real*8 :: mat(size(a, 1), size(e, 2))
    
    
    !##### OTHER VARIABLES ####################################################
    
        
    !##### ROUTINE CODE #######################################################   
	
	! sucessively multiply rows and columns
	mat = mat_mult2(a, mat_mult4(b, c, d, e))

end function mat_mult5


!##############################################################################
! FUNCTION mat_mult6
! 
! Multiplies four matrices a*b*c*d*e*f.
!##############################################################################
function mat_mult6(a, b, c, d, e, f) result(mat)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! matrix number one
    real*8, intent(in) :: a(:, :)

    ! matrix number two
    real*8, intent(in) :: b(:, :)
    
    ! matrix number three
    real*8, intent(in) :: c(:, :)
    
    ! matrix number four
    real*8, intent(in) :: d(:, :)
    
    ! matrix number five
    real*8, intent(in) :: e(:, :)
    
    ! matrix number six
    real*8, intent(in) :: f(:, :)
    
    ! the result
    real*8 :: mat(size(a, 1), size(f, 2))
    
    
    !##### OTHER VARIABLES ####################################################
    
        
    !##### ROUTINE CODE #######################################################   
	
	! sucessively multiply rows and columns
	mat = mat_mult2(a, mat_mult5(b, c, d, e, f))

end function mat_mult6



!##############################################################################
! SUBROUTINE lu_solve
! 
! Solves a linear equation system by lu-decomposition.
!##############################################################################
subroutine lu_solve(a, b)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! matrix of the system
    real*8, intent(in) :: a(:, :)

    ! right side of equation and solution of the system
    real*8, intent(inout) :: b(:)    
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: indx(size(b))
    real*8 :: worka(size(a, 1), size(a, 2))
    real*8 :: d
    integer :: n
    
        
    !##### ROUTINE CODE #######################################################

    ! assert size equality
	n = assert_eq(size(a,1), size(a,2), size(b), 'lu_solve')
	
	! copy matrix to working matrix
	worka = a
	
	! decompose matrix
	call lu_decomp(worka, indx, d)
	
	! solve system
	call lu_back(worka, indx, b)

end subroutine lu_solve


!##############################################################################
! FUNCTION lu_invert
! 
! Inverts a matrix by lu-decomposition.
!##############################################################################
function lu_invert(a)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! matrix of the system
    real*8, intent(in) :: a(:, :)

    ! the inverse of the matrix
    real*8 :: lu_invert(size(a, 1), size(a, 2))
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: j, n
    
        
    !##### ROUTINE CODE #######################################################

    ! assert size equality
	n = assert_eq(size(a,1), size(a,2), 'lu_invert')
	
	! set up unity matrix
	lu_invert = 0d0
	do j = 1, n
	    lu_invert(j, j) = 1d0
	enddo
	
	! succesively solve the system with unity matrix
	do j = 1, n
	    call lu_solve(a, lu_invert(:, j))
	enddo	

end function lu_invert


!##############################################################################
! SUBROUTINE lu_decomp
! 
! Calculates lu-decomposition of matrices.
!##############################################################################
subroutine lu_decomp(a, indx, d)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! matrix that shall be decomposed
    real*8, intent(inout) :: a(:, :)

    ! row permutation indicator due to pivoting
    real*8, intent(out) :: indx(:)

    ! indicates whether number of row permutations was even or odd
    real*8, intent(out) :: d    
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: vv(size(a,1))
	real*8, parameter :: tiny = 1.0e-20
	integer :: j, n, imax
    
        
    !##### ROUTINE CODE #######################################################
	
	! check array sizes
	n = assert_eq(size(a,1), size(a,2), size(indx),'lu_decomp')
	
	! initialize permutation indicator
	d = 1d0
	
	! get maximum value in every row
	vv = maxval(abs(a), dim=2)
	
	! if there is a zero row then matrix is singular
	if (any(vv == 0d0)) call error('lu_decomp', 'matrix is singular')
	
	! invert v
	vv = 1d0/vv
	
	! start lu-decomposition process
	do j = 1, n
	    
	    ! get index of pivot element
		imax = (j-1)+imaxloc(vv(j:n)*abs(a(j:n,j)))
		
		! do pivoting if pivot element is not the first element
		if(j /= imax)then
			call swap(a(imax,:), a(j,:))
			d = -d
			vv(imax) = vv(j)
		endif
				
	    ! indicate pivot element
		indx(j) = imax
		
		! prevent division by 0
		if(a(j,j) == 0d0)call error('lu_decomp', 'matrix is singular')
		
		! calculate new elements
		a(j+1:n, j) = a(j+1:n,j)/a(j,j)
		a(j+1:n, j+1:n) = a(j+1:n,j+1:n)-outerprod(a(j+1:n,j), a(j,j+1:n))
	enddo
	
	
	!##### SUBROUTINES AND FUNCTIONS ##########################################
	
	contains  
	  
	
	function outerprod(a, b)
    
        real*8, intent(in) :: a(:), b(:)
        real*8 :: outerprod(size(a, 1),size(b, 1))
        
        outerprod = spread(a, dim=2, ncopies=size(b, 1)) * &
            spread(b, dim=1, ncopies=size(a, 1))
        
    end function outerprod
    
    
    subroutine swap(a, b)
    
	    real*8, intent(inout) :: a(:), b(:)
	    real*8 :: dum(size(a))
	    
	    dum = a
	    a = b
	    b = dum
	    
	end subroutine swap
	
	
	function imaxloc(arr)
	
	    real*8, intent(in) :: arr(:)
	    integer :: imaxloc
        integer :: imax(1)
	    
	    imax = maxloc(arr(:))
	    imaxloc = imax(1)
	    
	end function imaxloc

end subroutine lu_decomp



!##############################################################################
! SUBROUTINE lu_dec
! 
! Calculates lu-decomposition of matrices and returns L and U matrix.
!##############################################################################
subroutine lu_dec(a, l, u)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! matrix that shall be decomposed
    real*8, intent(in) :: a(:, :)

    ! row permutation indicator due to pivoting
    real*8, intent(out) :: l(:, :)

    ! indicates whether number of row permutations was even of odd
    real*8, intent(out) :: u(:, :)    
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: Awork(size(a,1), size(a,2))
    real*8 :: indx(size(a,1))
    real*8 :: d
    integer :: n, j
	
    
        
    !##### ROUTINE CODE #######################################################
	
	! check array sizes
	n = assert_eq((/size(a,1), size(a,2), size(l, 1), size(l, 2), &
        size(u, 1), size(u, 2)/), 'lu_dec')
	
	! copy matrix
    Awork(:, :) = A(:, :)
    
    ! calculate decomposition
    call lu_decomp(Awork, indx, d)
    
    ! initialize matrices
    L(:, :) = 0d0
    U(:, :) = 0d0
    
    ! set up new matrices
    do j = 1, n
        
        ! diagonal element of L
        L(j, j) = 1d0
        
        ! other elements of L
        L(j, 1:j-1) = Awork(j, 1:j-1)
        
        ! elements of U
        U(j, j:n) = AWork(j, j:n)
    enddo

end subroutine lu_dec


!##############################################################################
! SUBROUTINE lu_back
! 
! Solves a lu decomposed matrix by backsubstitution.
!##############################################################################
subroutine lu_back(a, indx, b)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! lu-decomposed matrix that defines system
    real*8, intent(in) :: a(:, :)

    ! row permutation indicator due to pivoting
    real*8, intent(in) :: indx(:)

    ! right side of equation and solution of the system
    real*8, intent(inout) :: b(:)
    
    
    !##### OTHER VARIABLES ####################################################
    
    real*8 :: summ
	integer :: i, n, ii, ll
    
        
    !##### ROUTINE CODE #######################################################

    ! assert size equality
	n = assert_eq(size(a,1), size(a,2), size(indx), size(b), 'lu_back')
	
	! start backward solving provess
	ii = 0
	do i = 1, n
		
		ll = indx(i)		
		summ = b(ll)
		b(ll) = b(i)
		if(ii /= 0)then
			summ = summ-dot_product(a(i,ii:i-1), b(ii:i-1))
		elseif (summ /= 0.0) then
			ii = i
		endif
		b(i)=summ
	enddo
	do i=n, 1, -1
		b(i) = (b(i)-dot_product(a(i,i+1:n), b(i+1:n)))/a(i,i)
	enddo

end subroutine lu_back



!##############################################################################
! SUBROUTINE cholesky
! 
! Calculates cholesky factorization of a symmetric matrix.
!##############################################################################
subroutine cholesky(a, l)


    !##### INPUT/OUTPUT VARIABLES #############################################

    ! the matrix that should be decomposed
    real*8, intent(in) :: a(:, :)
    
    ! the cholesky factor
    real*8, intent(out) :: l(:, :)
    

    !##### OTHER VARIABLES ####################################################
   
    integer :: i, n
    real*8 :: summ, p(size(a,1))
    

   !##### ROUTINE CODE #######################################################
   
    ! assert equalities
    n = assert_eq(size(a,1), size(a,2), size(l, 1), size(l, 2), &
        size(p), 'normal_discrete')
        
    ! copy matrix
    l = a
    
    ! decompose matrix
    do i = 1, n
        summ = l(i,i)-dot_product(l(i,1:i-1), l(i,1:i-1))
        if(summ <= 0d0)call error('normal_discrete', &
            'Cholesky decomposition failed')
        p(i) = sqrt(summ)
        l(i+1:n,i) = (l(i,i+1:n)-matmul(l(i+1:n,1:i-1),l(i,1:i-1)))/p(i)
    enddo
    
    ! copy matrix
    do i = 1, n
        l(i, i) = p(i)
        l(i, i+1:n) = 0d0
    enddo
    
end subroutine cholesky


end module matrixtools