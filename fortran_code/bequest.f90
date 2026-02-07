!===============================================================================
! FILE: bequest.f90
!
! DESCRIPTION:
!   Calculates bequest distribution and receipts for transition path.
!   Handles accidental bequests from mortality and distributes them according
!   to specified rules (equal, per capita, or unequal Zipf distribution).
!
! INCLUDED IN: transition.f90 via include statement
!
! PURPOSE:
!   Compute bequests left by deceased agents and distribute them to surviving
!   cohorts. Supports three distribution mechanisms via switch_unequal_bequest.
!
! BEQUEST MECHANISMS (switch_unequal_bequest):
!   
!   0 = EQUAL DISTRIBUTION WITHIN AGE GROUP:
!      - Deaths at age j-1 leave savings sv_j(j-1,m,i-1)
!      - Bequest grossed up by interest: r(i) * sv_j(j-1,m,i-1) / gam_t(i)
!      - Distributed equally to all survivors of age j at time i
!      - Formula: bequest_j(j,m,i) = bequest_left_j(j-1,m,i-1) / N_big_t_j(j,m,i)
!   
!   1 = PER CAPITA TO NEWBORNS:
!      - All bequests pooled: bequest(m,i) = sum of all deaths' savings
!      - Distributed only to age-1 cohort (newborns)
!      - Formula: bequest(m,i) = total_bequests / N_big_t_j(1,m,i)
!      - bequest_j set to 0 for all ages (pooled into aggregate bequest)
!   
!   2 = UNEQUAL DISTRIBUTION (ZIPF LAW):
!      - Bequests distributed at specific age (beq_age, typically age 2)
!      - Receivers drawn from Zipf distribution with parameter zipf
!      - n_beq quantiles defined, with probability p_beq_trans(ibeq) ∝ 1/ibeq^zipf
!      - Top quantile receives much larger bequest
!      - Formula: beq_zipf_trans_big(ibeq,m,i) = bequest(m,i) * scaling / p_beq_trans(ibeq)
!      - Creates wealth inequality matching empirical top shares
!
! BEQUEST CALCULATION:
!   Deaths between periods:
!     bequest_left_j(j-1,m,i-1) = [N(j-1,m,i-1) - N(j,m,i)] * sv(j-1,m,i-1)
!   
!   Adjusted for:
!     - Interest earnings: r(i)
!     - TFP growth: /gam_t(i)
!     - Retirement status: Different treatment for workers vs retirees
!   
!   Total bequests by type:
!     bequest(m,i) = sum over ages of bequest_left_j(:,m,i)
!
! KEY VARIABLES:
!   INPUT (from transition iteration):
!     - sv_j(j,m,i): Savings by age, type, time
!     - N_big_t_j(j,m,i): Population by age, type, time
!     - r(i): Net interest rate
!     - gam_t(i): TFP growth rate
!     - jbar_t(i): Retirement age at time i
!     - switch_unequal_bequest: Distribution mechanism
!     - zipf: Parameter for Zipf distribution (if switch=2)
!     - beq_age: Age at which bequests received (if switch=2)
!     - n_beq: Number of bequest quantiles (if switch=2)
!   
!   OUTPUT:
!     - bequest_left_j(j,m,i): Bequests left by age-j deaths
!     - bequest(m,i): Aggregate bequests by type and time
!     - bequest_j(j,m,i): Bequest receipts by age, type, time (switch=0 or 2)
!     - beq_zipf_trans_big(ibeq,m,i): Bequest amounts by quantile (switch=2)
!     - p_beq_trans(ibeq,i): Probability of each bequest quantile
!
! MORTALITY TIMING:
!   - Agent at age j-1 in period i-1 may die before reaching age j in period i
!   - Survival probability: pi(j) = N(j,i) / N(j-1,i-1)
!   - Deaths: N(j-1,i-1) - N(j,i)
!   - Savings of deceased distributed to survivors
!
! ZIPF DISTRIBUTION DETAILS (switch_unequal_bequest=2):
!   - const_zipf = sum_{k=1}^{n_beq} 1/k^zipf (normalizing constant)
!   - Probability mass: p_beq(k) = (1/k^zipf) / const_zipf
!   - Higher zipf → more unequal (larger concentration in top quantile)
!   - Typical values: zipf ∈ [1.5, 3.0]
!   - Matches wealth concentration in top 1%, 5%, etc.
!
! EXAMPLES:
!   If switch_unequal_bequest = 0:
!     All age-30 survivors share bequests from age-29 deaths
!   
!   If switch_unequal_bequest = 1:
!     Newborns receive pooled bequests equally
!   
!   If switch_unequal_bequest = 2, zipf=2.5, n_beq=10:
!     Top 10% receive ~40% of bequests, bottom 10% receive ~2%
!
! NOTES:
!   - Accidental bequests (unintended, from mortality risk)
!   - No strategic bequest motive in utility function
!   - Bequest tax (lambda) applied in government budget
!   - Switch=0 most common for baseline, switch=2 for wealth inequality
!   - Retirement status matters: different asset composition pre/post jbar_t
!===============================================================================

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
            bequest_left_j(j-1,m,max(i-1,1)) = (N_big_t_j(j-1,m,max(i-1,1)) - N_big_t_j(j,m,i))*sv_j(j-1,m,max(i-1,1))
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
            bequest_left_j(j-1,m,max(i-1,1)) = (N_big_t_j(j-1,m,max(i-1,1)) - N_big_t_j(j,m,i))*r(i)*sv_j(j-1,m,max(i-1,1))/(gam_t(i))  
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