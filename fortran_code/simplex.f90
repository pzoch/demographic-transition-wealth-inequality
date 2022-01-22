!##############################################################################
! MODULE simplex
! 
! For applying the simplex algorithm to linear optimization problems.
!
! copyright: Fabian Kindermann
!            University of Wuerzburg
!            kindermann.fabian@uni-wuerzburg.de
!##############################################################################

module simplex


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
! SUBROUTINE solve_lin
! 
! For solving a linear program in normal form by means of the simplex 
!   algorithm.
!##############################################################################
subroutine solve_lin(x, c, A, b, numle, numge, numeq)
	
    implicit none
    
    
    !##### INPUT/OUTPUT VARIABLES #############################################
    
    ! solution of the linear program
    real*8, intent(inout) :: x(:)
    
    ! coefficients in the function to minimize
    real*8, intent(in) :: c(:)
    
    ! constraint matrix
    real*8, intent(in) :: A(:, :)
    
    ! target vectors of constraint
    real*8, intent(in) :: b(:)
    
    ! number of lower equal constraints
    integer, intent(in) :: numle
    
    ! number of greater equal constraints
    integer, intent(in) :: numge
    
    ! number of equality constraints
    integer, intent(in) :: numeq
    
    
    !##### OTHER VARIABLES ####################################################
    
    integer :: m, n, i1
    real*8 :: A_h(size(A, 1), size(A, 2)+numle+numge)
    real*8 :: c_h(size(c, 1)+numle+numge), b_h(size(b, 1))
    real*8 :: x_h(size(x, 1)+numle+numge)
    real*8 :: newA(size(A, 1), size(A, 2)+numle+numge)
    
    
    !##### ROUTINE CODE #######################################################

    ! check for sizes
    n = assert_eq(size(x, 1), size(c, 1), size(A, 2), 'solve_lin')
    m = assert_eq(size(A, 1), size(b, 1), 'solve_lin')
    
    ! check for correct inputs
    if(numle < 0)then
        call error('solve_lin', 'Number of lower equal constraints must '// &
            'not be negative')
    elseif(numge < 0)then
        call error('solve_lin', 'Number of greater equal constraints must '// &
            'not be negative')
    elseif(numeq < 0)then
        call error('solve_lin', 'Number of equality constraints must '// &
            'not be negative')
    elseif(numle+numge+numeq /= size(b,1))then
        call error('solve_lin', 'Number of equations does not match size of b')
    endif
    
    ! set up optimization problem
    A_h = 0d0
    A_h(1:m, 1:n) = A(:, :)
    do i1 = 1, numle
        A_h(i1, n+i1) = 1d0
    enddo
    do i1 = 1, numge
        A_h(numle+i1, n+numle+i1) = -1d0
    enddo
    
    ! check for negative bs
    b_h = b
    do i1 = 1, m
        if(b(i1) < 0d0)then
            A_h(i1, :) = -A_h(i1, :)
            b_h(i1) = -b_h(i1)
        endif
    enddo

    ! initialize c
    c_h = 0d0
    c_h(1:n) = c(:)
    
    call get_starting_value(x_h, A_h, b_h, newA)
        
    call solve_simplex(x_h, c_h, newA)
    

    write(*,*)x_h
    x = x_h(1:n)
    
    contains
    
    
    !##############################################################################
    ! SUBROUTINE get_starting_value
    ! 
    ! Calculates a starting value for the linear program.
    !##############################################################################
    subroutine get_starting_value(x0, A, b, newA)
    	
        implicit none
        
        
        !##### INPUT/OUTPUT VARIABLES #############################################
        
        ! starting value of the linear program
        real*8, intent(out) :: x0(:)        
        
        ! constraint matrix
        real*8, intent(in) :: A(:, :)
        
        ! target vectors of constraint
        real*8, intent(in) :: b(:)
        
        ! new matrix for simplex
        real*8, intent(out) :: newA(:, :)
        
        
        !##### OTHER VARIABLES ####################################################
        
        integer :: m, n, j
        real*8 :: Astart(size(A,1), size(A,1)+size(A,2))
        real*8 :: cstart(size(A,1)+size(A,2)), xstart(size(A,1)+size(A,2))
        
        !##### ROUTINE CODE #######################################################
        
        ! get sizes
        n = size(A, 2)
        m = size(A, 1)
        
        ! set up help problem
        cstart(1:n) = 0d0
        cstart(n+1:n+m) = 1d0
        
        ! set up help matrix
        Astart(1:m, 1:n) = A
        Astart(1:m, n+1:n+m) = 0d0
        do j = 1, m
            Astart(j,n+j) = 1d0
        enddo
        
        ! get initial guess
        xstart(1:n) = 0d0
        xstart(n+1:n+m) = b
        
        ! solve linear program
        call solve_simplex(xstart, cstart, Astart, newA)
                
        ! set starting value
        x0 = xstart(1:n)        
        
    end subroutine get_starting_value
    
    
    !##############################################################################
    ! SUBROUTINE solve_simplex
    ! 
    ! Solves a linear program in canonic form.
    !##############################################################################
    subroutine solve_simplex(x, c, A, newA)
    	
        implicit none
        
        
        !##### INPUT/OUTPUT VARIABLES #############################################
        
        ! starting value of the linear program and result
        real*8, intent(inout) :: x(:)
        
        ! coefficients of the program
        real*8, intent(in) :: c(:) 
        
        ! constraint matrix
        real*8, intent(in) :: A(:, :)
        
        ! new tableau if starting value calculation
        real*8, intent(out), optional :: newA(:, :)
        
        
        !##### OTHER VARIABLES ####################################################
        
        integer :: k, m, n, j, ibas, inot, piv(2), ihelp, i1, i2, n1
        integer :: bas(size(A, 1)), nbas(size(A, 2)-size(A, 1))
        real*8 :: alpha(size(A, 1), size(A,2)-size(A, 1))
        real*8 :: gamma(size(A, 2)-size(A,1)), x0(size(A, 1))
        real*8 :: pivcheck(size(A,1)), phelp, bhelp, alpha_h(size(alpha, 2))
        
        !##### ROUTINE CODE #######################################################
        
        ! get sizes        
        n = size(A, 2)
        m = size(A, 1)
        k = size(A, 2)-size(A,1)                                
        
        ! set up basis and non basis elements
        ibas = 1
        inot = 1
        do j = 1, n                    
            if(x(j) /= 0d0)then
                bas(ibas) = j
                ibas = ibas + 1
            else
                nbas(inot) = j
                inot = inot + 1
            endif            
        enddo                      
        
        ! set up x0 and c'x
        do ibas = 1, m
            x0(ibas) = x(bas(ibas))
        enddo                
        
        ! set up alphas
        do inot = 1, k
            alpha(:, inot) = -A(:, nbas(inot))
        enddo                
        
        ! set up gammas
        do inot = 1, k
            gamma(inot) = 0d0
            do ibas = 1, m
                gamma(inot) = gamma(inot) + alpha(ibas, inot)*c(bas(ibas))
            enddo            
            gamma(inot) = gamma(inot) + c(nbas(inot))
        enddo 

        ! start algorithm
        do
            
            ! choose pivot column
            piv = 0
            do inot = 1, k
                if(gamma(inot) < 0d0)then
                    piv(2) = inot
                    exit
                endif
            enddo
                        
            ! algorithm ends of no gamma < 0
            if(piv(2) == 0)exit                        

            ! else choose pivot row
            do ibas = 1, m
                if(alpha(ibas, piv(2)) /= 0d0)then
                    pivcheck(ibas) = x0(ibas)/alpha(ibas, piv(2))
                else
                    pivcheck(ibas) = -1d300
                endif
            enddo
            phelp = -1d300
            do ibas = 1, m
                if(alpha(ibas, piv(2)) < 0d0 .and. pivcheck(ibas) > phelp)then
                    phelp = pivcheck(ibas)
                    piv(1) = ibas
                endif
            enddo            
            
            ! no solution in piv(1) == 0
            if(piv(1) == 0)then
                call error('solve_lin','Problem has no solution')
            endif            
            
            ! Apply basis change
            Ihelp = nbas(piv(2))
            nbas(piv(2)) = bas(piv(1))
            bas(piv(1)) = Ihelp
            
            ! change pivot element
            alpha(piv(1), piv(2)) = 1d0/alpha(piv(1), piv(2))
            
            ! change pivot column
            do ibas = 1, m
                if(ibas /= piv(1))then
                    alpha(ibas, piv(2)) = alpha(ibas, piv(2))* &
                        alpha(piv(1), piv(2))
                endif
            enddo
            
            ! change pivot row
            do inot = 1, k
                if(inot /= piv(2))then
                    alpha(piv(1), inot) = -alpha(piv(1), inot)* &
                        alpha(piv(1), piv(2))
                endif
            enddo
            
            ! change other elements of alpha
            do ibas = 1, m
                do inot = 1, k
                    if(ibas /= piv(1) .and. inot /= piv(2))then
                        alpha(ibas, inot) = alpha(ibas, inot) + &
                            alpha(ibas, piv(2))*alpha(piv(1), inot)/ &
                            alpha(piv(1), piv(2))
                    endif
                enddo
            enddo
            
            ! change x0
            x0(piv(1)) = -x0(piv(1))*alpha(piv(1), piv(2))
            do ibas = 1, m
                if(ibas /= piv(1))then
                    x0(ibas) = x0(ibas) + alpha(ibas, piv(2))*x0(piv(1))/ &
                        alpha(piv(1), piv(2))
                endif
            enddo
            
            ! change gammas
            gamma(piv(2)) = gamma(piv(2))*alpha(piv(1), piv(2))
            do inot = 1, k
                if(inot /= piv(2))then
                    gamma(inot) = gamma(inot) + alpha(piv(1), inot)* &
                        gamma(piv(2))/alpha(piv(1), piv(2))
                endif
            enddo                           
         
        enddo
        
        ! get solution
        x = 0d0
        do ibas = 1, m
            x(bas(ibas)) = x0(ibas)
        enddo
        
        ! set up new tableau if needed
        if(present(newA))then
            
            ! check for existance of a solution
            do i1 = 1, n
                if(c(i1) > 0d0)then
                    n1 = i1
                    exit
                endif
            enddo
            if(any(x(n1:n) > 0d0))then
                call error('solve_lin', &
                    'Linear Program does not have a solution')
            endif
            
            ! sort tableau in ascending order
            do i1 = m-1,1,-1
                do i2 = 1, i1
                    if(bas(i2) > bas(i2+1))then
                        bhelp = bas(i2)
                        bas(i2) = bas(i2+1)
                        bas(i2+1) = bhelp
                        
                        alpha_h = alpha(i2, :)
                        alpha(i2, :) = alpha(i2+1, :)
                        alpha(i2+1, :) = alpha_h
                    endif
                enddo
            enddo                   
            
            ! get new matrix
            newA = 0d0            
            do i1 = 1, k                
                if(nbas(i1) <= n1-1)then    
                    newA(:, nbas(i1)) = -alpha(:, i1)
                endif
            enddo            
        endif
        
    end subroutine solve_simplex
    
end subroutine solve_lin

end module simplex