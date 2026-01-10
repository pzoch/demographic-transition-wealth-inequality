!===============================================================================
! FILE: gini.f90
!
! DESCRIPTION:
!   Calculates Gini coefficient and constructs Lorenz curves for wealth and
!   income inequality measurement in the OLG model.
!
! MODULE: gini_calc
!   Inequality measures for distribution analysis.
!
! FUNCTIONS:
!   - gini: Computes Gini coefficient from population weights and values
!           Returns scalar Gini ∈ [0,1] where 0=perfect equality, 1=total inequality
!
! ALGORITHM:
!   1. Sort population by value (x_in) using quicksort
!   2. Compute cumulative distributions of population and value
!   3. Calculate Gini as area between Lorenz curve and 45-degree line
!   Formula: G = 1 - 2*∫Lorenz(p)dp
!
! INPUTS:
!   - x_in: Population weights/shares (e.g., cohort sizes)
!   - y_in: Values to measure inequality (e.g., wealth, income)
!
! DEPENDENCIES:
!   - sorting: For sort routine (quicksort implementation)
!
! NOTES:
!   Written by F. Kindermann. Used throughout model for wealth/income inequality
!   statistics. Arrays dynamically allocated/deallocated to handle varying sizes.
!   See: https://www.ce-fortran.com/forums/topic/gini-coefficient-and-lorenz-curve/
!===============================================================================
!include "toolbox.f90"

module gini_calc
    implicit none
    private 
    ! Percentiles, Gini and Lorenz curve:
    public :: gini

    contains
    
    function gini(x_in, y_in)
        ! DESCRIPTION: computes Lorenz curve and Gini coefficient
        ! Notes: written by F.Kindermann
        ! See: https://www.ce-fortran.com/forums/topic/gini-coefficient-and-lorenz-curve/#post-1951
        
        use sorting, only: sort

        real(8), intent(in) :: x_in(:), y_in(:)
        real(8) :: gini
        integer :: n, ic
        real(8), allocatable :: xs(:), ys(:), xcum(:), ycum(:), xcum_out(:)
        integer, allocatable :: iorder(:)
        

        ! get array size
        n = size(x_in, 1)

        ! ALLOCATE LARGE ARRAYS TO AVOID SIZE PROBLEMS
        
        ! first deallocate
        if(allocated(xs))deallocate(xs)
        if(allocated(ys))deallocate(ys)
        if(allocated(xcum))deallocate(xcum)
        if(allocated(xcum_out))deallocate(xcum_out)
        if(allocated(ycum))deallocate(ycum)
        if(allocated(iorder))deallocate(iorder)
        
        ! then allocate
        allocate(xs(n))
        allocate(ys(n))
        allocate(xcum(0:n))
        allocate(xcum_out(0:n))
        allocate(ycum(0:n))
        allocate(iorder(n))
        
        
        ! NOW CALCULATE GINI INDEX

        ! sort array
        xs = x_in
        call sort(xs, iorder)
            
        ! sort y's and normalize to 1
        do ic = 1, n
            ys(ic) = y_in(iorder(ic))
        enddo
        ys = ys/sum(ys)
        

        ! calculate cumulative distributions
        xcum(0) = 0d0
        ycum(0) = 0d0
        do ic = 1, n
            xcum(ic) = xcum(ic-1) + ys(ic)*xs(ic)
            ycum(ic) = ycum(ic-1) + ys(ic)
        enddo
        
        ! now normalize cumulated attributes
        xcum_out = xcum/xcum(n)
        deallocate(xcum)
        
        ! determine gini index
        gini = 0d0
        do ic = 1, n
            gini = gini + ys(ic)*(xcum_out(ic-1) + xcum_out(ic))
        enddo
        gini = 1d0 - gini
        
end function gini
end module gini_calc