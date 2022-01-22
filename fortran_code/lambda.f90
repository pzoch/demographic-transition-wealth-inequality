! WHAT   : Utility ( -> consumption) effect of the reform for each cohort  
! TAKE   : consumption in baseline [[c_p]] and reform scenario [[c_f]], time-consistent (exponential) preferences [[beta]], standard discount factor [[delta]], mortality [[pi]], 
!          probability of reversing the reform [[phi]], labor suply [[l_]], consumption tax, technological progress [[zet]] 
! DO     : calculate consumption equivalent -> utility (consumption) effect of the reform 
! RETURN : percentage of consumption that after reform the consumer would need to give up to keep the same level of (x_j) calculated in lambda file, unif, sum_eq  

    zet = 1d0
!!! We calculate the utility in the reform
        do i = 1,bigT,1
            do j = 1,bigJ,1
                    !u_j_f(j,i) = log(((c_f(j,i)*zet(i))**phi)*((1 - l_f(j,i))**(1 - phi)))
                    u_j_f(j,i) = log(((c_f(j,i))**phi)*((1 - l_f(j,i))**(1 - phi)))
            enddo
        enddo
        u_f = 0
        do i = 1,n_p+2,1
            do j = 1,bigJ,1
                if (j == 1) then
                    u_f(i) = u_j_f(1,i)
                else
                    u_f(i) = u_f(i) + beta*delta**(j-1)*(pi(j,i-1+j)/pi(1,i))*u_j_f(j,i-1+j)   
                endif
            enddo
        enddo
        u_init_old_f = 0
        do j = 2,bigJ,1
           do s = 0,bigJ-j,1
               if (s == 0) then
                   u_init_old_f(j) = u_j_f(j,1)
               else
                   u_init_old_f(j) = u_init_old_f(j) + beta*delta**(s)*(pi(j+s,1+s)/pi(j,1))*u_j_f(j+s,1+s)   
               endif       
           enddo 
        enddo

        !!! We calculate the utility in the basline
        do i = 1,bigT,1
            do j = 1,bigJ,1
                    u_j_p(j,i) = log(((c_p(j,i)*zet(i))**phi)*((1 - l_p(j,i))**(1 - phi)))
                    u_j_p(j,i) = log(((c_p(j,i))**phi)*((1 - l_p(j,i))**(1 - phi)))
            enddo
        enddo
        u_p = 0
        do i = 1,n_p+2,1
            do j = 1,bigJ,1
                if (j == 1) then
                    u_p(i) = u_j_p(1,i)
                else
                    u_p(i) = u_p(i) + beta*delta**(j-1)*(pi(j,i-1+j)/pi(1,i))*u_j_p(j,i-1+j)   
                endif
            enddo
        enddo
        u_init_old_p = 0
        do j = 2,bigJ,1
           do s = 0,bigJ-j,1
               if (s == 0) then
                   u_init_old_p(j) = u_j_p(j,1)
               else
                   u_init_old_p(j) = u_init_old_p(j) + beta*delta**(s)*(pi(j+s,1+s)/pi(j,1))*u_j_p(j+s,1+s)   
               endif       
           enddo 
    enddo
    
    
    ! lifetime utility driven by public spendings 
    ! given as 
    ! for newborn
    do i = 1, n_p +2, 1 
        u_g_p(i) = 0d0
        u_g_f(i) = 0d0
        do j = 1, bigJ, 1
            u_g_p(i) = u_g_p(i) !+ log(g_per_capita_p(i-1+j))*beta*delta**(j-1)*(pi(j,i-1+j)/pi(1,i))
            u_g_f(i) = u_g_f(i) !+ log(g_per_capita_f(i-1+j))*beta*delta**(j-1)*(pi(j,i-1+j)/pi(1,i))
        enddo 
    enddo 
    ! for init old 
    do j = 2, bigJ, 1 
        u_g_init_old_p(j) = 0d0
        u_g_init_old_f(j) = 0d0
        do s = 1, bigJ - j, 1
            u_g_init_old_p(j)  = u_g_init_old_p(j) !+ log(g_per_capita_p(s))* beta*delta**(s)*(pi(j+s,1+s)/pi(j,1))
            u_g_init_old_f(j)  = u_g_init_old_f(j) !+ log(g_per_capita_f(s))* beta*delta**(s)*(pi(j+s,1+s)/pi(j,1))  
        enddo 
    enddo
    
    ! in value function case 
    if (switch_vf > 0) then    
        !! for newborn
        do i = 2, n_p +2, 1 
            u_p(i) = V_20_years_old_p(i) 
            u_f(i) = V_20_years_old_f(i) 
        enddo 
        !! for init old 
        u_p(1) = V_j_vfi_p(1,1)    - beta*delta*(pi(2,1)/pi(1,1))*V_j_vfi_p(2,1)  &
                                   + beta*delta*(pi(2,2)/pi(1,1))*V_j_vfi_p(2,2)  
        u_f(1) = V_j_vfi_f(1,1)    - beta*delta*(pi(2,1)/pi(1,1))*V_j_vfi_f(2,1)  &
                                   + beta*delta*(pi(2,2)/pi(1,1))*V_j_vfi_f(2,2)  
        do j = 2, bigJ-1, 1 
            u_init_old_p(j) = V_j_vfi_p(j,1)    - beta*delta*(pi(j+1,1)/pi(j,1))*V_j_vfi_p(j+1,1)  &
                                                + beta*delta*(pi(j+1,2)/pi(j,1))*V_j_vfi_p(j+1,2)  
            u_init_old_f(j) = V_j_vfi_f(j,1)    - beta*delta*(pi(j+1,1)/pi(j,1))*V_j_vfi_f(j+1,1)  &
                                                + beta*delta*(pi(j+1,2)/pi(j,1))*V_j_vfi_f(j+1,2) 
        enddo 
        u_init_old_p(bigJ) = V_j_vfi_p(bigJ,1)
        u_init_old_f(bigJ) = V_j_vfi_f(bigJ,1) 

    endif
    ! 20-year-olds
    mult = 0
    do i = 1,n_p+2,1      
        do j = 1,bigJ,1
            if (j == 1) then
                mult(1,i) = 1
            else
                mult(1,i) = mult(1,i) + beta*delta**(j-1)*(pi(j,i-1+j)/pi(1,i))
            endif
        enddo
    enddo 
    ! initial old
    do j = 2,bigJ,1
        do s = 0,bigJ-j,1
            if (s == 0) then
                mult(j,1) = 1
            else
                mult(j,1) = mult(j,1) + beta*delta**(s)*(pi(j+s,1+s)/pi(j,1))   
            endif       
        enddo 
    enddo
    mult = phi*mult
    
    open(unit = 104, file= "mult_trans.csv")
    open(unit = 105, file= "V_j_vfi_p.csv")
    open(unit = 106, file= "V_j_vfi_f.csv")
        do j = 1, bigJ,1  
            do i = 1,bigT,1
                write(104, '(F20.10)', advance='no') mult(j, i)
                write(104, '(A)', advance='no') ";"
                
                write(105, '(F20.10)', advance='no') V_j_vfi_p(j, i)
                write(105, '(A)', advance='no') ";"
                
                write(106, '(F20.10)', advance='no') V_j_vfi_f(j, i)
                write(106, '(A)', advance='no') ";"
            enddo
             write(104, '(F20.10)') mult(j, bigT)
             write(105, '(F20.10)') V_j_vfi_p(j, bigT)
             write(106, '(F20.10)') V_j_vfi_f(j, bigT)
        enddo      
    close(104)
    close(105)
    close(106)
    


    
    
    x_j = 0

    do j = 1,bigJ,1 ! initial old !trR1
        !x_j(j,1) = exp((u_init_old_f(j) - u_init_old_p(j))/mult(j,1)) - 1
        if (theta == 1) then 
            x_j(j,1) =  -exp((u_init_old_p(j) - u_init_old_f(j))/mult(j,1)) +1d0
        else
            x_j(j,1) = -(u_init_old_p(j) / u_init_old_f(j))**(1d0/(phi*(1-theta)))+1d0
        endif
    enddo

    do i = 1,n_p+2,1 ! 20-year-olds !trR2
        !x_j(1,i) = exp((u_f(i) - u_p(i))/mult(1,i)) - 1
        if (theta == 1) then 
            x_j(1,i) =  -exp((u_p(i) - u_f(i))/mult(1,i)) +1d0
        else
            x_j(1,i) = -(u_p(i) / u_f(i))**(1d0/(phi*(1-theta))) + 1d0
        endif
		!we can interpret x as how much percent of consumption consumer after reform would need to give up to stay the same		
		! positive x means she gains
    enddo 
    
open(unit = 104, file= version//closure//"utility_check.csv")
write(104, '(A)') "mult;Vp;Vk;xj"
do j= 1, bigJ
    write(104, '(F20.10,A,F20.10,A,F20.10,A,F20.10)') &
                mult(j, n_p), ";", & 
                V_j_vfi_p(j, n_p), ";", & 
                V_j_vfi_f(j, n_p) , ";",  & 
                x_j(j, n_p) 
enddo   
close(104) 
    