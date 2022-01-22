! WHAT   : Consumer problem -> lifetime remaining income_ss of agent in age j, consumption, labor supply and savings in both steady states (PAYG & FF) and for both utility functions (GHH & CD)
! TAKE   : unchanged in routine:   change in technological progress [[gam = z_t/z_(t-1)]], consumption tax [[tc]], [the inverse of Frisch elasticity of labor [[ksi]],  the disutility of labor [[psi]]: use in GHH utility function]
!          unchanged in routine:   time-consistent (exponential) preferences [[beta]], the standard discount factor [[delta]], mortality [[pi]],  interest rate [[r_ss]], pparameter for CES utility function [[theta]], implicit tax [[tau]] and unspecific (upsilon) for all cohorts, 
!          unchanged in routine:   bequest, [[b_ss]] pension benefits
!          changed   in routine:   lti, consumption [[c_ss]], labor supply [[l_ss]], savings [[s_ss]]
! DO     : called during iterations to findi optimal lti -> consumption -> saving choice with given unchanged variable (look up)
! RETURN : updated lti, consumption, saving for next iteration of steady state routine

do j = 1,bigJ,1
! lifetime remaining income_ss of agent of age j
    lti_ss_j(j) = 0
    do s = 0,bigj-j,1
        if (j < jbar_ss) then
            if (j+s < jbar_ss) then ! working
                    lti_ss_j(j) = lti_ss_j(j) + (gam_ss**s)*(w_pom_ss_j(j+s)  - upsilon_ss + bequest_ss_j(j+s))/(r_ss**s)
			else
                    lti_ss_j(j) = lti_ss_j(j) + (gam_ss**s)*(b_pom_ss_j(j+s)  - upsilon_ss + bequest_ss_j(j+s))/(r_ss**s)
            endif
        else !retired
            lti_ss_j(j) = lti_ss_j(j) + (gam_ss**s)*(b_pom_ss_j(j+s)  - upsilon_ss + bequest_ss_j(j+s))/(r_ss**s)
        endif
    enddo
enddo

do j = 1,bigj,1  
    if (j == 1) then
        c_ss_j(j) =  lti_ss_j(j)/denominator_j(j)
    else              
        c_ss_j(j) = (r_ss*s_pom_ss_j(j-1)/gam_ss + lti_ss_j(j))/denominator_j(j)     
    endif   
            
    if (j < jbar_ss) then
        l_ss_j(j) = 1 - c_ss_j(j)*(1+tc_ss)*(1 - phi)/(phi*w_pom_ss_j(j))
        if (l_ss_j(j) < 0) then
            l_ss_j(j) = 0
        endif
    else
        l_ss_j(j) = 0
    endif

    if (j == 1) then
        s_pom_ss_j(j) = w_pom_ss_j(j)*l_ss_j(j) - c_ss_j(j)*(1+tc_ss)  - upsilon_ss + bequest_ss_j(j)
    else
        s_pom_ss_j(j) = r_ss*s_pom_ss_j(j-1)/gam_ss + w_pom_ss_j(j)*l_ss_j(j) + b_pom_ss_j(j) - c_ss_j(j)*(1+tc_ss)  - upsilon_ss + bequest_ss_j(j)
    endif

    if (j == 1) then
        s_ss_j(j) = w_ss_j(j)*l_ss_j(j) + b_ss_j(j) - c_ss_j(j)*(1+tc_ss)  - upsilon_ss + bequest_ss_j(j)
    else
        s_ss_j(j) = r_ss*s_ss_j(j-1)/gam_ss + w_ss_j(j)*l_ss_j(j) + b_ss_j(j) - c_ss_j(j)*(1+tc_ss)  - upsilon_ss + bequest_ss_j(j)
    endif
    if (iter>1) then
        if (j == 1) then
            s_ss_j(j) = up_ss*s_ss_j(j) + (1- up_ss)*( w_ss_j(j)*l_ss_j(j) + b_ss_j(j) - c_ss_j(j)*(1+tc_ss) - upsilon_ss + bequest_ss_j(j))
        else
            s_ss_j(j) = up_ss*s_ss_j(j) + (1- up_ss)*(r_ss*s_ss_j(j-1)/gam_ss + w_ss_j(j)*l_ss_j(j) + b_ss_j(j) - c_ss_j(j)*(1+tc_ss) - upsilon_ss + bequest_ss_j(j))
        endif
    endif  
enddo 