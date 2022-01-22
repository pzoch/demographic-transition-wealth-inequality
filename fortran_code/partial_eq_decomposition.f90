V_j_vfi_const_lambda = V_j_vfi
lambda_trans(1) = lambda_old

do i = 2,bigT,1
    lambda_trans(i) = lambda_old*1.01d0
enddo
!!!!!!!!!!!!!!!
call agent_vf_trans()   
!!!!!!!!!!!!!!!
do i  = 2,bigT
    c_j_higher_lambda(:,i) = c_j_vfi(:,i)
    sv_j_higher_lambda(1:bigJ-1,i) = s_pom_j_vfi(1:bigJ-1,i)
enddo
l_j_higher_lambda = l_j_vfi          
V_j_vfi_higher_lambda = V_j_vfi

include 'lambda_partial.f90'

! Sklejone equivalent_rate_20 z odwróconym equivalent_rate_init_old
OPEN (unit=5, FILE = "equivalent_rate_all_partial_deterministic_DC.txt") 
    do i = 1,bigT,1
        if (i < bigJ-1) then
            write(5, '(F20.10)') x_j_higher_lambda(bigJ-i,1)
        else
            write(5, '(F20.10)') x_j_higher_lambda(1,i-(bigj-2))
        endif
    enddo
close(5)

!!!!!!!!!!!!
V_j_vfi =  V_j_vfi_const_lambda 
!!!!!!!!!!!!

    
    
open(unit = 111, file= "c_j_partial_DC.csv")
open(unit = 112, file= "l_j_partial_DC.csv")
open(unit = 113, file= "sv_j_partial_DC.csv")


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


  

