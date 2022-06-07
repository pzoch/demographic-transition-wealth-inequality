! WHAT   : PENSION SYSTEM bequest within each cohort
! TAKE   : unchanged in routine:  size of each cohort [[N_t]], interest rate [[r]], amount of private [[sv]] and in 2nd pillar [[phllarII]] savings,
!        : unchanged in routine:  labor force growth [[nu(i)=big_l(i)/big_l(i-1)]], change in technological progress [[gam = z_t/z_(t-1)]]
!          changed   in routine:  bequest 
! DO     : called in transition and REV subroutine to update bequest
! RETURN : updated bequest for next iteration on transition path 
    
if (switch_unequal_bequest==0) then       
    do m = 1,bigM,1

        do i = 1,bigT,1
            do j = 2,jbar_t(i),1
                 bequest_left_j(j-1,m,max(i-1,1)) = (N_t_j(j-1,max(i-1,1)) - N_t_j(j,i))*r(i)*sv_j(j-1,m,max(i-1,1))/(gam_t(i))   
            enddo
            do j = jbar_t(i)+1,bigJ,1
                bequest_left_j(j-1,m,max(i-1,1)) = (N_t_j(j-1,max(i-1,1)) - N_t_j(j,i))*(r(i)*sv_j(j-1,m,max(i-1,1)))/(gam_t(i))
            enddo
            bequest_left_j(bigJ,m,max(i-1,1)) = (N_t_j(bigJ,max(i-1,1)))*(r(i)*sv_j(bigJ,m,max(i-1,1)))/(gam_t(i))    
        enddo        
        
        
        bequest(m,:) = sum(bequest_left_j(1:bigJ,m,:), dim=1)
            
        do i = 1,bigT,1  
            bequest_j(1,m,:) = 0  
            do j = 2,bigJ,1
                bequest_j(j,m,i) = bequest_left_j(j-1,m,max(i-1,1))/N_t_j(j,i) 
            enddo              
        enddo
        
    enddo
    

    elseif (switch_unequal_bequest==1) then
      do m = 1,bigM,1  
      do i = 1,bigT,1
        do j = 2,jbar_t(i),1
             bequest_left_j(j-1,m,max(i-1,1)) = type_share_j_t(j-1,m,max(i-1,1)) * (N_t_j(j-1,max(i-1,1)) - N_t_j(j,i))*sv_j(j-1,m,max(i-1,1))   
        enddo
        do j = jbar_t(i)+1,bigJ,1
            bequest_left_j(j-1,m,max(i-1,1)) = type_share_j_t(j-1,m,max(i-1,1))* (N_t_j(j-1,max(i-1,1)) - N_t_j(j,i))*sv_j(j-1,m,max(i-1,1))
        enddo
        bequest_left_j(bigJ,m,max(i-1,1)) = type_share_j_t(j-1,m,max(i-1,1)) * (N_t_j(bigJ,max(i-1,1)))*(sv_j(bigJ,m,max(i-1,1)))    
      enddo
      enddo
      
    do m = 1,bigM,1   
    do i = 1,bigT,1               
    bequest(m,i) = sum(bequest_left_j(1:bigJ,m,max(i-1,1)), dim=1)
    enddo
    enddo
    bequest_j(:,:,:) = 0d0
    endif