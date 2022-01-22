! WHAT   :  Denominator_j(i) is a part of lifetime remaining income of agent in age j that is consumed at age j to optimize her decision 
! TAKE   :  preferences for leisure [[phi]],  time-consistent (exponential) preferences [[beta]], the standard discount factor [[delta]], mortality [[pi]], parameter for CES utility function [[theta]] 
! DO     :  calculate denominator for both utility functions 
! RETURN :  denominator 

do j = 1,bigJ,1
    if (j < jbar_ss) then
        denominator_j(j) = 1/phi*(1.0d0+tc_ss)
    else
        denominator_j(j) = 1*(1+tc_ss)
    endif
    do s = 1,bigJ-j,1
        if (j < jbar_ss) then !working
            if (j+s < jbar_ss) then
                denominator_j(j) = denominator_j(j) + (1.0d0+tc_ss)*(1/phi)*beta*delta**s*pi_ss(j+s)/pi_ss(j)         
	        else
                denominator_j(j) = denominator_j(j) + (1.0d0+tc_ss)*beta*delta**s*pi_ss(j+s)/pi_ss(j)                   
            endif
        else !retired
            denominator_j(j) = denominator_j(j) + (1.0d0+tc_ss)*beta*delta**s*pi_ss(j+s)/pi_ss(j)                       
        endif
    enddo
enddo