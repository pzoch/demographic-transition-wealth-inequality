! WHAT   : Consumer problem -> lifetime remaining income_ss of agent in age j, consumption, labor supply and savings on the transition path for both utility functions (GHH & CD)
! TAKE   : unchanged in routine:   change in technological progress [[gam = z_t/z_(t-1)]], consumption tax [[tc]], [the inverse of Frisch elasticity of labor [[ksi]],  the disutility of labor [[psi]]: use in GHH utility function]
!          unchanged in routine:   time-consistent (exponential) preferences [[beta]], the standard discount factor [[delta]], mortality [[pi]],  interest rate [[r]], pparameter for CES utility function [[theta]], implicit tax [[tau]] and unspecific (upsilon) for all cohorts, 
!          unchanged in routine:   bequest, [[b_j]] pension benefits
!          changed   in routine:   lti, consumption [[c_j]], labor supply [[l_j]], savings [[s_j]]
! DO     : called during iterations to findi optimal lti -> consumption -> saving choice with given unchanged variable (look up)
! RETURN : updated lti, consumption, saving for next iteration on the transition path

      
do i = 2,n_p+1,1   
    do j = 1,bigJ,1     
        lti_j(j,i)=0
        do s = 0,(bigJ-j),1   
            if (j < jbar_t(i)) then
                if (j+s < jbar_t(i+s)) then   ! working
                    if (s == 0) then
                            lti_j(j,i) = lti_j(j,i) + w_pom_j(j+s,i+s) - upsilon(i+s) + bequest_j(j+s,i+s)                       
                    else
                            lti_j(j,i) = lti_j(j,i) + (gam_cum(i+s)/gam_cum(i))*(w_pom_j(j+s,i+s)  - upsilon(i+s) + bequest_j(j+s,i+s))/product(r((i+1):(i+s)))                                                    
                    endif
                else
                  lti_j(j,i) = lti_j(j,i) + (gam_cum(i+s)/gam_cum(i))*(b_pom_j(j+s,i+s) - upsilon(i+s) + bequest_j(j+s,i+s))/product(r((i+1):(i+s)))                            
                endif
            else  !retired
                if (s == 0) then
                    lti_j(j,i) = lti_j(j,i) + b_pom_j(j+s,i+s)  - upsilon(i+s) + bequest_j(j+s,i+s)    
                else
                    lti_j(j,i) = lti_j(j,i) + (gam_cum(i+s)/gam_cum(i))*(b_pom_j(j+s,i+s)  - upsilon(i+s) + bequest_j(j+s,i+s))/product(r((i+1):(i+s)))
                endif
            endif
        enddo
    enddo
           
    do j = 1,bigJ,1
        if (j == 1) then
            c_j(j,i) =  lti_j(j,i)/denominator_j(j,i)
        else
            if (i>1) then 
                c_j(j,i) = (r(i)*sv_pom_j(j-1,i-1)/gam_t(i) + lti_j(j,i))/denominator_j(j,i)  
            else
                c_j(j,i) = (r(i)*sv_pom_j(j-1,1)/gam_t(i) + lti_j(j,i))/denominator_j(j,i)  
            endif                                            
        endif   

        if (j < jbar_t(i)) then
            l_new_j(j,i) = 1 - c_j(j,i)*(1.0_dp + tc(i))*(1-phi)/(phi*w_pom_j(j,i)) 
            if (l_new_j(j,i) < 0) then
                l_new_j(j,i) = 0 
            endif
        else
            l_new_j(j,i) = 0
        endif

        
        if (j == 1) then
            sv_pom_j(j,i) = up_t*sv_old_pom_j(j,i) + (1 - up_t)*(w_pom_j(j,i)*l_j(j,i) + b_pom_j(j,i) - c_j(j,i)*(1.0_dp + tc(i))  - upsilon(i) + bequest_j(j,i))
        else  
            if (i>1) then 
                sv_pom_j(j,i) = up_t*sv_old_pom_j(j,i) + (1 - up_t)*(r(i)*sv_pom_j(j-1,i-1)/gam_t(i) + w_pom_j(j,i)*l_new_j(j,i) + b_pom_j(j,i) - c_j(j,i)*(1.0_dp + tc(i))  - upsilon(i) + bequest_j(j,i))
            else
                sv_pom_j(j,i) = up_t*sv_old_pom_j(j,i) + (1 - up_t)*(r(i)*sv_pom_j(j-1,i)/gam_t(i) + w_pom_j(j,i)*l_new_j(j,i) + b_pom_j(j,i) - c_j(j,i)*(1.0_dp + tc(i))  - upsilon(i) + bequest_j(j,i))
            endif                                         
        endif 
        
        if (j == 1) then
            sv_j(j,i) = up_t*sv_old_j(j,i) + (1 - up_t)*(w_j(j,i)*l_new_j(j,i) + b_j(j,i) - c_j(j,i)*(1.0_dp + tc(i))  - upsilon(i) + bequest_j(j,i))
        else                                           
            sv_j(j,i) = up_t*sv_old_j(j,i) + (1 - up_t)*(r(i)*sv_j(j-1,i-1)/gam_t(i) + w_j(j,i)*l_new_j(j,i) + b_j(j,i) - c_j(j,i)*(1.0_dp + tc(i)) - upsilon(i) + bequest_j(j,i))
        endif                     
    enddo 
enddo