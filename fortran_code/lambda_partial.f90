! WHAT   : Utility ( -> consumption) effect of the reform for each cohort  
! TAKE   : consumption in baseline [[c_p]] and reform scenario [[c_f]], time-consistent (exponential) preferences [[beta]], standard discount factor [[delta]], mortality [[pi]], 
!          probability of reversing the reform [[phi]], labor suply [[l_]], consumption tax, technological progress [[zet]] 
! DO     : calculate consumption equivalent -> utility (consumption) effect of the reform 
! RETURN : percentage of consumption that after reform the consumer would need to give up to keep the same level of (x_j) calculated in lambda file, unif, sum_eq  

    
    
!risk
! for newborn
do i = 2, n_p +2, 1 
    u_const_lambda(i) = V_j_vfi_const_lambda(1,i)
enddo 
u_const_lambda(1) = V_j_vfi_const_lambda(1,1) - beta*delta*(pi(2,1)/pi(1,1))*V_j_vfi_const_lambda(2,1)  &
                                              + beta*delta*(pi(2,2)/pi(1,1))*V_j_vfi_const_lambda(2,2)  
! for init old 
do j = 2, bigJ-1, 1 
    u_init_old_const_lambda(j) = V_j_vfi_const_lambda(j,1) - beta*delta*(pi(j+1,1)/pi(j,1))*V_j_vfi_const_lambda(j+1,1)  &
                                                           + beta*delta*(pi(j+1,2)/pi(j,1))*V_j_vfi_const_lambda(j+1,2) 
enddo 
u_init_old_const_lambda(bigJ) = V_j_vfi_const_lambda(bigJ,1)


!partial
! for newborn
do i = 2, n_p +2, 1 
    u_higher_lambda(i) = V_j_vfi_higher_lambda(1,i)
enddo 
u_higher_lambda(1) = V_j_vfi_higher_lambda(1,1) - beta*delta*(pi(2,1)/pi(1,1))*V_j_vfi_higher_lambda(2,1)  &
                                                + beta*delta*(pi(2,2)/pi(1,1))*V_j_vfi_higher_lambda(2,2)  
! for init old 
do j = 2, bigJ-1, 1 
    u_init_old_higher_lambda(j) = V_j_vfi_higher_lambda(j,1) - beta*delta*(pi(j+1,1)/pi(j,1))*V_j_vfi_higher_lambda(j+1,1)  &
                                                             + beta*delta*(pi(j+1,2)/pi(j,1))*V_j_vfi_higher_lambda(j+1,2) 
enddo 
u_init_old_higher_lambda(bigJ) = V_j_vfi_higher_lambda(bigJ,1)


    
    open(unit = 104, file= "utility.csv") 
            do i = 1,n_p-1,1
                write(104, '(F20.10)', advance='no')  u_const_lambda(i)
                write(104, '(A)', advance='no') ";"
            enddo
             write(104, '(F20.10)') u_const_lambda(n_p)     
           do i = 1,n_p-1,1
                write(104, '(F20.10)', advance='no') u_higher_lambda(i)
                write(104, '(A)', advance='no') ";"
            enddo
             write(104, '(F20.10)')u_higher_lambda(n_p)  
             do j = 2,bigJ,1
                write(104, '(F20.10)') u_init_old_higher_lambda(j)
            enddo
               do j = 2,bigJ,1
                write(104, '(F20.10)')  u_init_old_const_lambda(j)
            enddo
    close(104)
    
    
    !!! to do 
    !u_init_old_const_lambda = 0d0
    !u_init_old_partial = 0d0
    !! 20-year-olds
    mult_partial = 0
    do i = 1,n_p+2,1      
        do j = 1,bigJ-1,1
            if (j == 1) then
                mult_partial(1,i) = 1
            else
                mult_partial(1,i) = mult_partial(1,i) + beta*delta**(j-1)*(pi(j,i-1+j)/pi(1,i))
            endif
        enddo
    enddo 
    ! initial old
    do j = 2,bigJ,1
        do s = 0,bigJ-j,1
            if (s == 0) then
                mult_partial(j,1) = 1
            else
                mult_partial(j,1) = mult_partial(j,1) + beta*delta**(s)*(pi(j+s,1+s)/pi(j,1))   
            endif       
        enddo 
    enddo
    mult_partial = phi*mult_partial
    
    open(unit = 104, file= "mult_partial.csv")
        do j = 1, bigJ,1  
            do i = 1,bigT,1
                write(104, '(F20.10)', advance='no') mult_partial(j, i)
                write(104, '(A)', advance='no') ";"
            enddo
             write(104, '(F20.10)') mult_partial(j, bigT)
        enddo      
    close(104)
    
    x_j_higher_lambda = 0
    do j = 1,bigJ,1 ! initial old !trR1
        if (theta == 1d0) then 
            x_j_higher_lambda(j,1) =  exp((u_init_old_higher_lambda(j)-u_init_old_const_lambda(j))/mult_partial(j,1))-1d0
        else
            x_j_higher_lambda(j,1) =  (u_init_old_higher_lambda(j)/u_init_old_const_lambda(j))**(1d0/(phi*(1-theta)))-1d0
        endif
    enddo

    do i = 1,n_p+2,1 ! 20-year-olds !trR2
        if (theta == 1d0) then 
            x_j_higher_lambda(1,i) =  exp((u_higher_lambda(i)-u_const_lambda(i))/mult_partial(1,i)) -1d0
        else
            x_j_higher_lambda(1,i) = (u_higher_lambda(i)/u_const_lambda(i))**(1d0/(phi*(1-theta)))-1d0
        endif
		!we can interpret x as how much percent of consumption consumer after reform would need to give up to stay the same	level of utility as in baseline scenario	
    enddo 
    
    
!----------------------------------------------------------------------------------!
!                       CONSUMPTION EQUIVALENT BETWEEN SCENARIOS                   !
!----------------------------------------------------------------------------------!
    
do i = 2,n_p+2,1
    do j = 1,bigJ,1
        if (j == 1) then 
            x_c_j_higher_lambda(j,i) = x_j_higher_lambda(j,i)*c_j(j,i)
        else
            x_j_higher_lambda(j,i) = x_j_higher_lambda(j-1,i-1)
            x_c_j_higher_lambda(j,i) = x_j_higher_lambda(j,i)*c_j(j,i)
        endif
    enddo
enddo

do i = n_p+3,bigT,1
    do j = 1,bigJ,1
        x_j_higher_lambda(j,i) = x_j_higher_lambda(j,i-1)
        x_c_j_higher_lambda(j,i) = x_j_higher_lambda(j,i)*c_j(j,i)
    enddo
enddo
     
    x_c_higher_lambda = sum(x_c_j_higher_lambda*Nn_, dim=1)
    c_higher_lambda_tot = sum(c_j*Nn_, dim=1)
     
open(unit = 104, file= "x_j_partial.csv")
    do j = 1, bigJ,1  
        do i = 1,bigT,1
            write(104, '(F20.10)', advance='no') x_j_higher_lambda(j, i)
            write(104, '(A)', advance='no') ";"
        enddo
            write(104, '(F20.10)') x_j_higher_lambda(j, bigT)
    enddo      
close(104)
                  
LS_higher_lambda = x_c_higher_lambda(1)
S_C_higher_lambda = c_higher_lambda_tot(1)
disc_higher_lambda(1) = 1
! 20-year olds
do i = 2,n_p+1,1
    disc_higher_lambda(i) = gam_cum(i)/gam_cum(1)/product(r_f((2):(i))) ! OPIS 
    LS_higher_lambda  = LS_higher_lambda  + disc_higher_lambda(i)*x_c_higher_lambda(i)
    S_C_higher_lambda = S_C_higher_lambda + disc_higher_lambda(i)*c_higher_lambda_tot(i)            
enddo

disc_higher_lambda(n_p+2) = gam_cum(n_p+1)/product(r_f((1):(n_p+1)))
LS_higher_lambda  =  LS_higher_lambda  + x_c_higher_lambda(n_p+2)  *(gam_cum(n_p+2)/gam_cum(1)/product(r_f((2):(n_p+2))))*(r_f(n_p+2)/(r_f(n_p+2) - gam_t(n_p+2))) !the last part is the sum of infinite sequence
S_C_higher_lambda = S_C_higher_lambda  + c_higher_lambda_tot(n_p+2)*(gam_cum(n_p+2)/gam_cum(1)/product(r_f((2):(n_p+2))))*(r_f(n_p+2)/(r_f(n_p+2) - gam_t(n_p+2))) !the last part is the sum of infinite sequence
     
unif_higher_lambda = -LS_higher_lambda/S_C_higher_lambda  ! if we have something left, then you can lower lump-sums by this amount, hence the minus sign
sum_eq_higher_lambda = (x_j_higher_lambda + unif_higher_lambda)*c_j_higher_lambda
    
if ( -unif_higher_lambda > 0) then
    write(*,*) closure,' - unif_higher_lambda = ', -unif_higher_lambda, '> 0, i.e. the new policy is Pareto improving'
else 
    write(*,*) closure,' - unif_higher_lambda = ', -unif_higher_lambda , '< 0, i.e. the new policy is Pareto deteriorating'
endif 