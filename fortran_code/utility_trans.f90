! WHAT   : Consumer problem -> value of utility function on transition path for both utility functions (GHH & CD)
! TAKE   : unchanged in routine:   technological progress [[z_(i)]], consumption [[c_j]], consumption tax [[tc]], [the inverse of Frisch elasticity of labor [[ksi]],  the disutility of labor [[psi]]: use in GHH utility function]
!          unchanged in routine:   labor supply [[l_ss]], probability of reversing thereform (phi),time-consistent (exponential) preferences [[beta]], the standard discount factor [[delta]], parameter for CES utility function [[theta]]
!          changed   in routine:   utility [[u_j]]
! DO     : called during iterations to calculate utility with given unchanged variables (look up)
! RETURN : updated utility for next iteration of transition path routine        
        
do i = 1,bigT,1
    do j = 1,bigJ,1
        u_j(j,i) = log((((c_j(j,i)/(1 + tc(i)))*zet(i))**phi)*((1 - l_j(j,i))**(1 - phi)))
    enddo
enddo
! common part 
u = 0
do i = 1,n_p+2,1
    do j = 1,bigJ,1
        if (j == 1) then
            u(i) = u_j(1,i)
        else
            u(i) = u(i) + beta*delta**(j-1)*(pi(j,i-1+j)/pi(1,i))*u_j(j,i-1+j)   
        endif
    enddo
enddo

do j = 2,bigJ,1
    do s = 0,bigJ-j,1
        if (s == 0) then
            u_init_old(j) = u_j(j,1)
        else
            u_init_old(j) = u_init_old(j) + beta*delta**(s)*(pi(j+s,1+s)/pi(j,1))*u_j(j+s,1+s)   
        endif       
    enddo 
enddo

! Sklejone u_20 z odwr�conym u_init_old
u_all = 0
do i = 1,bigj-2,1
    u_all(i) = u_init_old(bigj-i)
enddo
do i = 1,n_p+2,1
    u_all(bigj-2+i) = u(i)
enddo
    
! in case "to samo na to samo" we should get the same value for  V_20_years_old(2:)
! cause values for 20 years old are taken there, V_20_years_old(-78:1) represent 
! value function for 80, 79, ... , 21 years old so it should be increasing function
do i = 2, bigT, 1
    V_20_years_old(i) = V_j_vfi(1,i)
enddo 
! for init old 
do j = 2, bigJ, 1
    V_20_years_old(3-j) = V_j_vfi(j,2)
enddo