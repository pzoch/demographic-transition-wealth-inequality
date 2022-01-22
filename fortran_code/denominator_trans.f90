! WHAT   :  Denominator_j(i) is part of lifetime remaining income of agent in age j that is consumed at age j to optimize her decision 
! TAKE   :  preferences for leisure [[phi]],  time-consistent (exponential) preferences [[beta]], the standard discount factor [[delta]], mortality [[pi]], parameter for CES utility function [[theta]] 
! DO     :  calculate denominator for both utility function 
! RETURN :  denominator 

do i = 2,n_p+1,1   
    do j = 1,bigJ,1
                ! CD utility function
        if (j < jbar_t(i)) then
            denominator_j(j,i) = 1/phi * (1.0_dp + tc(i)) 
        else
            denominator_j(j,i) = 1 * (1.0_dp + tc(i))   
        endif
        do s = 1,bigJ-j,1    
            if (j < jbar_t(i)) then
                if (j+s < jbar_t(i)) then
                    denominator_j(j,i) = denominator_j(j,i) +  (1.0_dp + tc(i))* (1/phi)*beta*delta**s*pi(j+s,i+s)/pi(j,i)       
                else
                    denominator_j(j,i) = denominator_j(j,i) + (1.0_dp + tc(i))*beta*delta**s*pi(j+s,i+s)/pi(j,i)               
                endif
            else
                denominator_j(j,i) = denominator_j(j,i) + (1.0_dp + tc(i))*beta*delta**s*pi(j+s,i+s)/pi(j,i)                   
            endif
        enddo
    enddo
enddo