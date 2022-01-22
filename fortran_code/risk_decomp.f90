!This file provides a decomposition of the welfare effect obtained in pension system reform 
!into insurance and effectiveness components. 
!
!Reform from redistributive AIME system to DC (+FF) implies: 
!lost of insurance due to proportional benefits 
!and effectiveness gain due to a drop in effective labor taxation
! 
!We decompose this to effect by partial equilibrium exercise. 
!We assume that AIME provides an equal replacement rate 
!regardless of the value of accumulated assets identical 
!to the average replacement rate, 
!thus aimereplacemnt is equal aime and we rescale benefits to obtain the same  avg values (sum_b_weight). 
V_j_vfi_const_lambda = V_j_vfi    
switch_partial_efficiency = 1
aime_cap_ge = aime_cap
do i = 2, bigT, 1
    do j = 1, bigJ, 1
        b_j_vfi(j,i) = sum_b_weight_trans(min(max(i + jbar_t(i) -j,1), bigT))*b_j(j,i)
    enddo 
enddo
   
call agent_vf_trans() 

do i  = 2,bigT
    c_j_higher_lambda(:,i) = c_j_vfi(:,i)
    sv_j_higher_lambda(1:bigJ-1,i) = s_pom_j_vfi(1:bigJ-1,i)
enddo
    
l_j_higher_lambda = l_j_vfi          
V_j_vfi_higher_lambda = V_j_vfi

include 'lambda_partial.f90'


OPEN (unit=5, FILE = "welfare_no_insurance_no_effectivnes.txt") 
    do i = 1,bigT,1
        if (i < bigJ-1) then
            write(5, '(F20.10)') x_j_higher_lambda(bigJ-i,1)
        else
            write(5, '(F20.10)') x_j_higher_lambda(1,i-(bigj-2))
        endif
    enddo
close(5)
!
!!!!!!!!!!!!!
V_j_vfi =  V_j_vfi_const_lambda 
!!!!!!!!!!!!!

    
    
open(unit = 111, file= "c_j_no_insurance_no_effectivnes.csv")
open(unit = 112, file= "l_j_no_insurance_no_effectivnes.csv")
open(unit = 113, file= "sv_j_no_insurance_no_effectivnes.csv")


do j = 1, bigJ,1  
    do i = 1,bigT-1,1
        write(111, '(F20.10)', advance='no') c_j_higher_lambda(j, i)
        write(111, '(A)', advance='no') ";"
        write(112, '(F20.10)', advance='no') l_j_higher_lambda(j, i)
        write(112, '(A)', advance='no') ";"
        write(113, '(F20.10)', advance='no') sv_j_higher_lambda(j, i)
        write(113, '(A)', advance='no') ";"
      
    enddo
    write(111, '(F20.10)') c_j_higher_lambda(j, bigT)
    write(112, '(F20.10)') l_j_higher_lambda(j, bigT)
    write(113, '(F20.10)') sv_j_higher_lambda(j, bigT)

enddo       
close(111)
close(112)
close(113)

aime_cap = aime_cap_ge ! to restore orginal values of pension system cap 
switch_partial_efficiency = 0