!===============================================================================
! FILE: print_iter.f90
!
! DESCRIPTION:
!   Prints iteration diagnostics during transition path solution. Displays
!   convergence metrics and feasibility checks to monitor solver progress.
!
! SCRIPT (included code fragment)
!   Executed periodically (every MOD(iter,1)==0) within transition_iterations.f90.
!
! OUTPUT:
!   Console display showing:
!   - iter: Current iteration number
!   - cum_err: Cumulative error sum(err) across all periods
!   - worst feasibility: Max resource constraint violation and its time period
!   - max error: Maximum single-period error and its time period
!
! FEASIBILITY CHECK:
!   For each period i:
!   feasibility(i) = |[Y - C - G]/Y - [γ*ν*K' + (δ-1)*K]/Y|
!   Measures deviation from resource constraint: Y(t) = C(t) + G(t) + I(t)
!
! FILE OUTPUT:
!   Writes feasibility(1:bigT) to "feasibility" file (unit 123) for inspection.
!
! VARIABLES (from global scope):
!   - err(bigT): Period-specific convergence errors
!   - y, consumption_gross, g, k: Aggregate variables
!   - gam_t, nu, depr_t: Demographic/depreciation parameters
!
! NOTES:
!   Controlled by switch_print==1 in transition_iterations.f90. Helps diagnose
!   non-convergence issues (oscillation, divergence, constraint violations).
!   Format uses ES10.3 for scientific notation with 3 decimals.
!===============================================================================
write(*,'(A,I5)') 'iter ', iter              
write(*,'(A,ES10.3)') 'cum_err = ', sum(err) 
feasibility(1)  =   abs(((y(1) - consumption_gross(1) - g(1))/y(1) - (gam_t(1)*nu(1)*k(1) + (depr_t(1)-1)*k(1))/y(1)))
do i = 2, bigT-1, 1
    feasibility(i) = abs(((y(i) - consumption_gross(i) - g(i))/y(i) - (gam_t(i+1)*nu(i+1)*k(i+1) + (depr_t(i)-1)*k(i))/y(i)))
enddo
feasibility(bigT) = abs(((y(bigT) - consumption_gross(bigT) - g(bigT))/y(bigT) - (gam_t(bigT)*nu(bigT)*k(bigT) + (depr_t(bigT)-1)*k(bigT))/y(bigT) ))
write(*,'(A,ES10.3,A,I5)') 'worst feasibility = ', maxval((feasibility),1), ' in period ', maxloc((feasibility),1)

write(*,'(A,ES10.3,A,I5)') 'max error = ', maxval(abs(err),1), ' in period ', maxloc(abs(err),1)
open(unit=123,  FILE = "feasibility")
    do i = 1,bigT,1 
        write(123,  '(F20.10)') feasibility(i)
    enddo
close(123)

