print *, "iter ", iter              
write(*,*) "cum_err = ", sum(err) 
feasibility(1)  =   abs(((y(1) - consumption_gross(1) - g(1))/y(1) - (gam_t(1)*nu(1)*k(1) + (depr-1)*k(1))/y(1)))
do i = 2, bigT-1, 1
    feasibility(i) = abs(((y(i) - consumption_gross(i) - g(i))/y(i) - (gam_t(i+1)*nu(i+1)*k(i+1) + (depr-1)*k(i))/y(i)))
enddo
feasibility(bigT) = abs(((y(bigT) - consumption_gross(bigT) - g(bigT))/y(bigT) - (gam_t(bigT)*nu(bigT)*k(bigT) + (depr-1)*k(bigT))/y(bigT) ))
print*, 'worst feasibility = ', maxval((feasibility),1), 'at period', maxloc((feasibility),1)
print*, 'max error = ', maxval(abs(err),1), 'at period', maxloc(abs(err),1)
open(unit=123,  FILE = "feasibility")
    do i = 1,bigT,1 
        write(123,  '(F20.10)') feasibility(i)
    enddo
close(123)

