!===============================================================================
! FILE: print_iter.f90
!
! DESCRIPTION:
!   Prints iteration progress and convergence diagnostics during transition
!   path computation. Shows cumulative error, worst feasibility violation,
!   and max interest rate error.
!
! INCLUDED IN: transition_iterations.f90
!
! KEY OUTPUTS: Console diagnostics, feasibility file (unit 123)
!===============================================================================
write(*,'(A,I5)') 'iter ', iter              
write(*,'(A,ES10.3)') 'cum_err = ', sum(err) 
feasibility(1)  =   abs(((y(1) - consumption_gross(1) - g(1))/y(1) - (gam_t(1)*nu(1)*k(1) + (depr_t(1)-1)*k(1))/y(1)))
do i = 2, bigT-1, 1
    feasibility(i) = abs(((y(i) - consumption_gross(i) - g(i))/y(i) - (gam_t(i+1)*nu(i+1)*k(i+1) + (depr_t(i)-1)*k(i))/y(i)))
enddo
feasibility(bigT) = abs(((y(bigT) - consumption_gross(bigT) - g(bigT))/y(bigT) - (gam_t(bigT)*nu(bigT)*k(bigT) + (depr_t(bigT)-1)*k(bigT))/y(bigT) ))
write(*,'(A,ES10.3,A,I5)') 'worst feasibility (frac. GDP) = ', maxval((feasibility),1), ' in period ', maxloc((feasibility),1)

write(*,'(A,ES10.3,A,I5)') 'max error (interest rate) = ', maxval(abs(err),1), ' in period ', maxloc(abs(err),1)
open(unit=123,  FILE = "feasibility")
    do i = 1,bigT,1 
        write(123,  '(F20.10)') feasibility(i)
    enddo
close(123)

