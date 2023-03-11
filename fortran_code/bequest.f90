! WHAT   : PENSION SYSTEM bequest within each cohort
! TAKE   : unchanged in routine:  size of each cohort [[N_t]], interest rate [[r]], amount of private [[sv]] and in 2nd pillar [[phllarII]] savings,
!        : unchanged in routine:  labor force growth [[nu(i)=big_l(i)/big_l(i-1)]], change in technological progress [[gam = z_t/z_(t-1)]]
!          changed   in routine:  bequest 
! DO     : called in transition and REV subroutine to update bequest
! RETURN : updated bequest for next iteration on transition path 
    
if (switch_unequal_bequest==0) then       
    do m = 1,bigM,1

        do i = 1,bigT,1
            do j = 2,bigJ,1
                 bequest_left_j(j-1,m,max(i-1,1)) = (N_big_t_j(j-1,m,max(i-1,1)) - N_big_t_j(j,m,i))*r(i)*sv_j(j-1,m,max(i-1,1))/(gam_t(i))   

            enddo
            bequest_left_j(bigJ,m,max(i-1,1)) = (N_big_t_j(bigJ,m,max(i-1,1)))*(r(i)*sv_j(bigJ,m,max(i-1,1)))/(gam_t(i))    
        enddo        
        
        
        bequest(m,:) = sum(bequest_left_j(1:bigJ,m,:), dim=1)
            
        do i = 1,bigT,1  
            bequest_j(1,m,:) = 0  
            do j = 2,bigJ,1
                bequest_j(j,m,i) = bequest_left_j(j-1,m,max(i-1,1))/N_big_t_j(j,m,i) 
            enddo              
        enddo
        
    enddo
    

    elseif (switch_unequal_bequest==1) then
      do m = 1,bigM,1  
      do i = 1,bigT,1
        do j = 2,jbar_t(i),1
             bequest_left_j(j-1,m,max(i-1,1)) =  (N_big_t_j(j-1,m,max(i-1,1)) - N_big_t_j(j,m,i))*sv_j(j-1,m,max(i-1,1))   
        enddo
        do j = jbar_t(i)+1,bigJ,1
            bequest_left_j(j-1,m,max(i-1,1)) = (N_big_t_j(j-1,m,max(i-1,m,1)) - N_big_t_j(j,m,i))*sv_j(j-1,m,max(i-1,1))
        enddo
        bequest_left_j(bigJ,m,max(i-1,1)) = N_big_t_j(bigJ,m,max(i-1,1))*(sv_j(bigJ,m,max(i-1,1)))    
      enddo
      enddo
      
    do m = 1,bigM,1   
    do i = 1,bigT,1               
    bequest(m,i) = sum(bequest_left_j(1:bigJ,m,max(i-1,1)), dim=1)/N_big_t_j(1,m,i)
    enddo
    enddo
    bequest_j(:,:,:) = 0d0
    
    elseif (switch_unequal_bequest == 2) then
        
        do i = 1,bigT,1
            do ibeq = n_beq,1,-1
                p_beq_trans(ibeq,:) = 1d0/ibeq**(zipf)/const_zipf !zipf law p.d.f. 
            enddo
        enddo
        
        
        
     do m = 1,bigM,1  
      do i = 1,bigT,1
        do j = 2,jbar_t(i),1
             bequest_left_j(j-1,m,max(i-1,1)) =  (N_big_t_j(j-1,m,max(i-1,1)) - N_big_t_j(j,m,i))*r(i)*sv_j(j-1,m,max(i-1,1))/(gam_t(i))  
        enddo
        do j = jbar_t(i)+1,bigJ,1
            bequest_left_j(j-1,m,max(i-1,1)) = (N_big_t_j(j-1,m,max(i-1,m,1)) - N_big_t_j(j,m,i))*r(i)*sv_j(j-1,m,max(i-1,1))/(gam_t(i))  
        enddo
        bequest_left_j(bigJ,m,max(i-1,1)) = N_big_t_j(bigJ,m,max(i-1,1))*r(i)*(sv_j(bigJ,m,max(i-1,1)))/(gam_t(i))      
      enddo
     enddo
      
     
    do m = 1,bigM,1   
        do i = 1,bigT,1               
        bequest(m,i) = sum(bequest_left_j(1:bigJ,m,max(i-1,1)), dim=1)/N_big_t_j(beq_age,m,i)
            
            do ibeq = 1,n_beq,1
            beq_zipf_trans_big(ibeq,m,i) = 1d0 * 1d0/(2d0**(n_beq-ibeq+1))* bequest(m,i)/(p_beq_trans(ibeq,i)) 
            enddo
            beq_zipf_trans_big(2,m,i) = 1d0/(2d0**(n_beq-2))* bequest(m,i)/p_beq_trans(2,i)
            beq_zipf_trans_big(1,m,i) = 0.0d0
        enddo
    enddo
    bequest_j(:,:,:) = 0d0 
    
    
    endif