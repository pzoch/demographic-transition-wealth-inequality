!===============================================================================
! FILE: pfi_distribution.f90
!
! DESCRIPTION:
!   Computes the stationary distribution of households over the state space given
!   policy functions. Implements forward simulation (Young's method) to iterate from
!   initial distribution at age 1 to equilibrium distribution at all ages.
!
! PURPOSE:
!   Bridge between individual policy functions and aggregate statistics. Given
!   optimal savings a'(j,a,aime,ε,δ,r) and AIME accumulation aime'(⋅), compute
!   the measure of agents prob(j,a,aime,ε,δ,r) at each state and age.
!
! SUBROUTINES:
!   - get_distribution_ss: Steady-state distribution computation
!       Forward iteration: prob(j,⋅) → prob(j+1,⋅) using policy a'(⋅), aime'(⋅)
!       Loops j = 2,...,bigJ to fill prob_ss(j,⋅) from prob_ss(j-1,⋅)
!
!   - get_distribution_trans: Transition path variant (cohort-period tracking)
!       Same as steady state but for period i
!       Loops j = 2,...,bigJ using yesterday's distribution prob_trans(j-1,⋅,itm)
!       where itm = year(i,2,1) is previous period
!
! DISTRIBUTION EVOLUTION EQUATION:
!   prob_ss(j+1, a', aime', ε', δ', r') =
!       ∑_{a,aime,ε,δ,r} prob_ss(j, a, aime, ε, δ, r) ×
!                        Pr[a'|a,aime,ε,δ,r] × Pr[aime'|aime,ε] ×
!                        Pr[ε'|ε] × Pr[δ'|δ] × Pr[r'|r] × π(j)
!
!   Where:
!   - a' = svplus_ss(j,a,aime,ε,δ,r): Next period assets from policy function
!   - aime' = aime_plus_ss(j,a,aime,ε,δ,r): Updated AIME (Social Security earnings)
!   - π(j): Conditional survival probability to age j+1
!   - Pr[ε'|ε], Pr[δ'|δ], Pr[r'|r]: Shock transition matrices (pi_ip, pi_id, pi_ir)
!   - Pr[a'|⋅]: Linear interpolation weight (off-grid assets)
!
! INITIAL DISTRIBUTION (age j=1):
!   Newborns enter with:
!   - Assets (a): From bequest distribution (depends on switch_unequal_bequest)
!   - AIME: Zero (no work history yet)
!   - Shocks: Initial distributions (pi_ip_init, pi_id_init, pi_ir_init)
!
!   Bequest variants (switch_unequal_bequest):
!   - == 0: Equal bequests → all start with a ≈ 0
!   - == 1: Zipf distribution with n_beq classes → unequal initial wealth
!           ia_initial(ind) ∝ bequest_ss_vfi / (ind^zipf) for ind = 1,...,n_beq
!           Mimics wealth concentration at birth (intergenerational transfers)
!   - == 2: Alternative Zipf with bequest received at age beq_age + 1 (inheritance)
!
! INTERPOLATION MECHANICS:
!   Policy functions typically return off-grid values:
!   - call linear_int(a', ial, iar, dist, sv, n_a, a_grow)
!     Returns: ial, iar (bracket indices), dist ∈ [0,1] (weight on ial)
!   - Distribute probability: dist × prob to ial, (1-dist) × prob to iar
!   - Same for AIME grid using aime_plus_ss(⋅)
!   - Four combinations: (ial,aimel), (ial,aimer), (iar,aimel), (iar,aimer)
!
! SPECIAL CASE: BEQUEST RECEIPT (switch_unequal_bequest == 2):
!   At age j = beq_age + 1, agents receive bequests mid-life:
!   - Loop over n_beq bequest classes (ibeq = 1,...,n_beq)
!   - Use svplus_beq_ss(ibeq,a,aime,ε,δ,r) instead of svplus_ss
!   - Weight by bequest class probabilities p_beq(ibeq)
!   - Generates mid-life wealth dispersion spike
!
! STATE SPACE DIMENSIONS:
!   prob_ss(j, ia, i_aime, ip, ir, id):
!   - j ∈ {1,...,bigJ}: Age (5-year periods, e.g., 20-24, 25-29, ..., 95-99)
!   - ia ∈ {0,...,n_a}: Asset grid (typically n_a ≈ 50-100)
!   - i_aime ∈ {0,...,n_aime}: AIME grid (Social Security average earnings)
!   - ip ∈ {1,...,n_sp}: Permanent/persistent productivity shock
!   - ir ∈ {1,...,n_sr}: Return shock (portfolio returns)
!   - id ∈ {1,...,n_sd}: Discount factor shock (preference heterogeneity)
!
! NORMALIZATION:
!   For each age j: ∑_{ia,i_aime,ip,ir,id} prob_ss(j,ia,i_aime,ip,ir,id) = 1
!   Ensures distribution is a valid probability measure (integrates to 1)
!
! ALGORITHM (STEADY STATE):
!   1. Initialize prob_ss = 0 for all states
!   2. Set initial distribution at j=1:
!      a. Choose bequest distribution (equal or Zipf)
!      b. Interpolate to find grid brackets (ial, iar)
!      c. Assign prob_ss(1,ia,0,⋅,⋅,⋅) with initial shock probabilities
!   3. Forward iterate j = 2,...,bigJ:
!      a. Loop over yesterday's states (ia, i_aime, ip, ir, id) at age j-1
!      b. Retrieve policy: a' = svplus_ss(j-1,⋅), aime' = aime_plus_ss(j-1,⋅)
!      c. Interpolate a' and aime' to find brackets (ial,iar), (aimel,aimer)
!      d. Loop over tomorrow's shocks (ip', ir', id') using transition matrices
!      e. Accumulate: prob_ss(j, bracket, ⋅) += prob_ss(j-1,⋅) × weights × π(j-1)
!   4. Return prob_ss(j,⋅,⋅,⋅,⋅,⋅) for all j
!
! TRANSITION PATH VARIANT:
!   - Uses prob_trans(j,⋅,⋅,⋅,⋅,⋅,i) for period i
!   - Cohort-specific shocks: year_birth = i - j + 1 → tp indexing
!   - Time-varying transition matrices (pi_ip_trans) for cohort effects
!   - Otherwise identical to steady state algorithm
!
! OUTPUTS:
!   - prob_ss(j,ia,i_aime,ip,ir,id): Steady-state distribution
!   - prob_trans(j,ia,i_aime,ip,ir,id,i): Transition distribution at period i
!   Used in pfi_agregation.f90 to compute: aggregate(j) = ∑ prob(j,⋅) × policy(j,⋅)
!
! DEPENDENCIES:
!   - global_vars: Policy functions (svplus_ss, aime_plus_ss, svplus_beq_ss),
!                  grids (sv, aime), transition matrices (pi_ip, pi_id, pi_ir),
!                  survival probabilities (pi_ss, pi_trans), parameters (n_beq, zipf)
!   - linint: For linear_int() interpolation function
!
! NOTES FOR REPLICATION:
!   - Forward simulation is stable (no iteration needed) given convergent policies
!   - Main loop is over yesterday's states → distributes mass to tomorrow's grid
!   - Bequest distribution calibrated to match wealth inequality (Gini, top shares)
!   - AIME tracking essential for US Social Security (OASI) progressive formula
!   - Interpolation weights (dist, dist_aime) must be ∈ [0,1] for valid probabilities
!   - Survival probabilities (pi_j) already incorporated in policy function iteration
!   - Transition path handles cohort-specific σ²_ε via year_birth indexing (tp)
!
! PERFORMANCE:
!   - Nested loops: bigJ × n_a × n_aime × n_sp × n_sr × n_sd × n_sp × n_sr × n_sd
!   - With typical grids: 16 × 60 × 40 × 9 × 5 × 5 × 9 × 5 × 5 ≈ 10^9 operations
!   - Most time spent in inner shock loops (9×5×5 = 225 iterations per state)
!   - Vectorization opportunities limited by irregular interpolation patterns
!===============================================================================
!***************************************************************************************

! get distribution for every gridpoint and state for every age
! Steady state
    subroutine get_distribution_ss()

            implicit none

            integer :: j, ial, iar, iaimel, iaimer, ind
            real*8 :: dist, dist_aime, ia_initial(n_beq), p_initial(n_beq), const

            ! set distribution to zero
            prob_ss = 0d0

            
            if((switch_unequal_bequest==1))then
                !ia_initial(2) = bequest_ss_vfi / 
                !ia_initial(1) = 0d0

                
                do ind=n_beq,1,-1
                    p_initial(ind) = 1d0/ind**(zipf)/const_zipf !zipf law p.d.f. 
                    ia_initial(ind) = 1d0/(2d0**(n_beq-ind+1))* bequest_ss_vfi/(p_initial(ind)) ! 1d0/(2d0**(n_beq-ind+1)) - number of people in one sub-cohort,  bequest_ss_vfi - sum of bequest, 
                    !(p_initial(ind)*edu_rate*N_ss_j_vfi(1)) -  part of bequest which agent from ind- subcohort inherit  
                    !p_initial(ind) = 0.0d0
                    !ia_initial(ind) = 0.0d0
                enddo
               !     ia_initial(2) = 1d0/(2d0**(n_beq-2))* bequest_ss_vfi/(p_initial(2))
                    ia_initial(1) = 0d0
                    
                    const = sum(ia_initial)
                    const = sum(ia_initial * p_initial)
                    const = sum(p_initial)
                do ind=1,n_beq,1
                    call linear_int(ia_initial(ind), ial, iar, dist, sv, n_a, a_grow)
                    ial = min(ial, n_a)
                    iar = min(iar, n_a)
                    dist = min(dist, 1d0)

                    
                    prob_ss(1, ial, 0, :, :, :)  = prob_ss(1, ial, 0, :, :, :)  + p_initial(ind)*dist ! y-ss rename f_dens_ss ! poczatkowy rozk�ad
                    prob_ss(1, iar, 0, :,  :, :) = prob_ss(1, iar, 0, :, :, :) +  p_initial(ind)*(1d0 - dist)
                    
                    
                enddo
                  ! need to amend it to get initial dispersion
                const = 0.0d0
                 do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1 , n_sp, 1
                            do ir=1, n_sr, 1
                                do id=1,n_sd,1 
                                prob_ss(1, ia, i_aime, ip, ir, id) = prob_ss(1, ia, i_aime, ip, ir, id) * pi_ip_init(ip) * pi_id_init(id) * pi_ir_init(ir)
                                const = const + prob_ss(1, ia, i_aime, ip, ir, id)
                                enddo
                            enddo
                        enddo
                    enddo
              enddo
                
            else
            
            
            ! get initial distribution in age 1
            call linear_int(0d0, ial, iar, dist, sv, n_a, a_grow)
            ial = min(ial, n_a)
            iar = min(iar, n_a)
            dist = min(dist, 1d0)
            
            
            ! need to amend it to get initial dispersion
            
            prob_ss(1, ial, 0, :, :, :) = dist ! y-ss rename f_dens_ss ! poczatkowy rozk�ad
            prob_ss(1, iar, 0, :,  :, :) = 1d0 - dist
            
            
              do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1 , n_sp, 1
                            do ir=1, n_sr, 1
                                do id=1,n_sd,1 
                                prob_ss(1, ia, i_aime, ip, ir, id) = prob_ss(1, ia, i_aime, ip, ir, id) * pi_ip_init(ip) * pi_id_init(id) * pi_ir_init(ir)
                                enddo
                            enddo
                        enddo
                    enddo
              enddo

    
                        
            endif
            ! successively compute distribution over ages
            do j = 2, bigJ  
            ! iterate over yesterdays gridpoints
                do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1 , n_sp, 1
                            do ir=1, n_sr, 1
                                do id=1,n_sd,1 
                                    ! interpolate yesterday's savings decision
                                    
                                     !there is one special age - after bequest
                                    if(((j == (beq_age + 1)) .and. (switch_unequal_bequest == 2))) then
                                    
                                    do ibeq = 1,n_beq
                                        
                                    call linear_int(svplus_beq_ss(ibeq, ia, i_aime, ip, ir, id), ial, iar, dist, sv, n_a, a_grow)
                                    call linear_int(aime_plus_beq_ss(ibeq, ia, i_aime, ip, ir, id), iaimel, iaimer, dist_aime, aime(:), n_aime, aime_grow)    
                                        
                                        
                                    !call linear_int(svplus_ss(j-1, ia, i_aime, ip, ir, id), ial, iar, dist, sv, n_a, a_grow)
                                    !call linear_int(aime_plus_ss(j-1, ia, i_aime, ip, ir, id), iaimel, iaimer, dist_aime, aime(:), n_aime, aime_grow)
                                    ! restrict values to grid just in case               
                                    dist = min(abs(dist), 1d0)
                                    
                                    ! redistribute households
                                    do ip_p = 1, n_sp,1
                                        do ir_r=1, n_sr, 1
                                            do id_d =1, n_sd, 1
                                                prob_ss(j, ial, iaimel, ip_p, ir_r, id_d) = prob_ss(j, ial, iaimel, ip_p, ir_r, id_d) &
                                                                                            +p_beq(ibeq) * pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id, id_d)*dist       *dist_aime       *prob_ss(j-1, ia, i_aime, ip, ir, id)
                                                prob_ss(j, iar, iaimel, ip_p, ir_r, id_d) = prob_ss(j, iar, iaimel, ip_p, ir_r, id_d) &
                                                                                            +p_beq(ibeq) * pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id, id_d)*(1d0-dist) *dist_aime       *prob_ss(j-1, ia, i_aime, ip, ir, id) 
                                                prob_ss(j, ial, iaimer, ip_p, ir_r, id_d) = prob_ss(j, ial, iaimer, ip_p, ir_r, id_d) &
                                                                                            +p_beq(ibeq) * pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id, id_d)*dist       *(1d0-dist_aime) *prob_ss(j-1, ia, i_aime, ip, ir, id)
                                                prob_ss(j, iar, iaimer, ip_p, ir_r, id_d) = prob_ss(j, iar, iaimer, ip_p, ir_r, id_d) &
                                                                                            +p_beq(ibeq) * pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id, id_d)*(1d0-dist)  *(1d0-dist_aime)*prob_ss(j-1, ia, i_aime, ip, ir, id) 
                                            enddo
                                        enddo
                                    enddo
                                    enddo
                                    
                                    
                                    else
                                    call linear_int(svplus_ss(j-1, ia, i_aime, ip, ir, id), ial, iar, dist, sv, n_a, a_grow)
                                    call linear_int(aime_plus_ss(j-1, ia, i_aime, ip, ir, id), iaimel, iaimer, dist_aime, aime(:), n_aime, aime_grow)   
                                     do ip_p = 1, n_sp,1
                                        do ir_r=1, n_sr, 1
                                            do id_d =1, n_sd, 1
                                                prob_ss(j, ial, iaimel, ip_p, ir_r, id_d) = prob_ss(j, ial, iaimel, ip_p, ir_r, id_d) &
                                                                                            + pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id, id_d)*dist       *dist_aime       *prob_ss(j-1, ia, i_aime, ip, ir, id)
                                                prob_ss(j, iar, iaimel, ip_p, ir_r, id_d) = prob_ss(j, iar, iaimel, ip_p, ir_r, id_d) &
                                                                                            + pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id, id_d)*(1d0-dist) *dist_aime       *prob_ss(j-1, ia, i_aime, ip, ir, id) 
                                                prob_ss(j, ial, iaimer, ip_p, ir_r, id_d) = prob_ss(j, ial, iaimer, ip_p, ir_r, id_d) &
                                                                                            + pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id, id_d)*dist       *(1d0-dist_aime) *prob_ss(j-1, ia, i_aime, ip, ir, id)
                                                prob_ss(j, iar, iaimer, ip_p, ir_r, id_d) = prob_ss(j, iar, iaimer, ip_p, ir_r, id_d) &
                                                                                            + pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id, id_d)*(1d0-dist)  *(1d0-dist_aime)*prob_ss(j-1, ia, i_aime, ip, ir, id) 
                                            enddo
                                        enddo
                                     enddo
                                    endif
                                    
                                enddo
                            enddo
                        enddo
                    enddo
                enddo
            enddo 


        end subroutine
!***************************************************************************************

! get distribution for every gridpoint and state for every age
! for transition

    subroutine get_distribution_trans(i)



            implicit none
            integer, intent(in) :: i
            integer :: j, ial, iar, iaimel, iaimer, itm, year_birth, tp,ind
            real*8 :: dist, dist_aime, ia_initial(n_beq), p_initial(n_beq), const

            
            
            ! get yesterdays year
            itm = year(i, 2, 1) 
        
            ! set distribution to zero
            prob_trans(:,:,:,:,:,:,i) = 0d0 
            const = 0d0
            p_initial = 0d0
            ia_initial =0d0
            ! get initial distribution in age 1 
            
            
            if ((switch_unequal_bequest==1)) then
                !ia_initial(2) = bequest_ss_vfi 
                !ia_initial(1) = 0d0
                
                
                do ind=1,n_beq,1 !normalizing constant
                    const = const + 1/ind**(zipf)
                enddo
                
                do ind=n_beq,1,-1
                    p_initial(ind) = 1d0/ind**(zipf)/const !zipf law p.d.f. 
                    ia_initial(ind) = 1d0/(2d0**(n_beq-ind+1))* bequest_vfi(i)/(p_initial(ind)) ! 1d0/(2d0**(n_beq-ind+1)) - number of people in one sub-cohort,  bequest_ss_vfi - sum of bequest, 

                enddo
                !    ia_initial(2) = 1d0/(2d0**(n_beq-2))* bequest_vfi(i)/(p_initial(2))
                !    ia_initial(1) = 0d0
                do ind=1,n_beq,1
                    call linear_int(ia_initial(ind), ial, iar, dist, sv, n_a, a_grow)
                    ial = min(ial, n_a)
                    iar = min(iar, n_a)
                    dist = min(dist, 1d0)

                    prob_trans(1, ial, 0, :, :, :, i)  = prob_trans(1, ial, 0, :, :, :,i) +  p_initial(ind)*dist ! y-ss rename f_dens_ss ! poczatkowy rozk�ad
                    prob_trans(1, iar, 0, :, :, :, i) =  prob_trans(1, iar, 0, :, :, :,i) +  p_initial(ind)*(1d0 - dist)
                enddo
                
                    
                    

                  ! need to amend it to get initial dispersion
                const = 0.0d0
                
                
                   do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1 , n_sp, 1
                            do ir=1, n_sr, 1
                                do id=1,n_sd,1 
                                prob_trans(1, ia, i_aime, ip, ir, id, i) = prob_trans(1, ia, i_aime, ip, ir, id, i) * pi_ip_init_trans(ip,i) * pi_id_init(id) * pi_ir_init(ir)
                                enddo
                            enddo
                        enddo
                    enddo
              enddo
                   
                
            else
            
                    
            call linear_int(0d0, ial, iar, dist, sv, n_a, a_grow)
                    ial = min(ial, n_a)
                    iar = min(iar, n_a)
                    dist = min(dist, 1d0)
            prob_trans(1, ial, 0, :, :, :, i) = dist ! y-ss rename f_dens_ss ! poczatkowy rozk�ad
            prob_trans(1, iar, 0, :, :, :, i) = 1d0 - dist
            
            
              do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1 , n_sp, 1
                            do ir=1, n_sr, 1
                                do id=1,n_sd,1 
                                prob_trans(1, ia, i_aime, ip, ir, id, i) = prob_trans(1, ia, i_aime, ip, ir, id, i) * pi_ip_init_trans(ip,i) * pi_id_init(id) * pi_ir_init(ir)
                                enddo
                            enddo
                        enddo
                    enddo
              enddo
              
           endif     
            
            ! successively compute distribution over ages
            do j = 2, bigJ
                
        
            year_birth = i - j + 1  ! get year of birth to assign correct sigma2_epsilon -- so this seems to be cohort specific


            tp = year_birth 

            if (tp < 1) then
                tp = 1
            elseif (tp > bigT) then
                tp = bigT
            endif
            
                ! iterate over yesterdays gridpoints
                do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1 , n_sp, 1
                            do ir=1, n_sr, 1
                                do id =1, n_sd, 1
                                    
                                    if(((j == (beq_age + 1)) .and. (switch_unequal_bequest == 2))) then
                                    
                                    do ibeq = 1,n_beq
                                        
                                    call linear_int(svplus_beq_trans(ibeq, ia, i_aime, ip, ir, id,itm), ial, iar, dist, sv, n_a, a_grow)
                                    call linear_int(aime_plus_beq_trans(ibeq, ia, i_aime, ip, ir, id,itm), iaimel, iaimer, dist_aime, aime(:), n_aime, aime_grow)    
                                        
                                        
                                    !call linear_int(svplus_ss(j-1, ia, i_aime, ip, ir, id), ial, iar, dist, sv, n_a, a_grow)
                                    !call linear_int(aime_plus_ss(j-1, ia, i_aime, ip, ir, id), iaimel, iaimer, dist_aime, aime(:), n_aime, aime_grow)
                                    ! restrict values to grid just in case               
                                    dist = min(abs(dist), 1d0)
                                    
                                    ! redistribute households
                                    do ip_p = 1, n_sp,1
                                        do ir_r=1, n_sr, 1
                                            do id_d =1, n_sd, 1
                                                prob_trans(j, ial, iaimel, ip_p, ir_r, id_d,i) = prob_trans(j, ial, iaimel, ip_p, ir_r, id_d,i) &
                                                                                            +p_beq_trans(ibeq,i)  * pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id, id_d)*dist       *dist_aime       *prob_trans(j-1, ia, i_aime, ip, ir, id,itm)
                                                prob_trans(j, iar, iaimel, ip_p, ir_r, id_d,i) = prob_trans(j, iar, iaimel, ip_p, ir_r, id_d,i) &
                                                                                            +p_beq_trans(ibeq,i)  * pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id, id_d)*(1d0-dist) *dist_aime       *prob_trans(j-1, ia, i_aime, ip, ir, id,itm) 
                                                prob_trans(j, ial, iaimer, ip_p, ir_r, id_d,i) = prob_trans(j, ial, iaimer, ip_p, ir_r, id_d,i) &
                                                                                            +p_beq_trans(ibeq,i)  * pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id, id_d)*dist       *(1d0-dist_aime) *prob_trans(j-1, ia, i_aime, ip, ir, id,itm)
                                                prob_trans(j, iar, iaimer, ip_p, ir_r, id_d,i) = prob_trans(j, iar, iaimer, ip_p, ir_r, id_d,i) &
                                                                                            +p_beq_trans(ibeq,i) * pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id, id_d)*(1d0-dist)  *(1d0-dist_aime)*prob_trans(j-1, ia, i_aime, ip, ir, id,itm) 
                                            enddo
                                        enddo
                                    enddo
                                    enddo
                                    
                                    else
                                        
                                    ! interpolate_trans yesterday's savings decision
                                    call linear_int(   svplus_trans(j-1, ia, i_aime, ip, ir, id, itm), ial, iar, dist, sv, n_a, a_grow)
                                    call linear_int(aime_plus_trans(j-1, ia, i_aime, ip, ir, id, itm), iaimel, iaimer, dist_aime, aime(:), n_aime, aime_grow)
                                    ! restrict values to grid just in case
                                    ial = min(ial, n_a)
                                    iar = min(iar, n_a)
                                    dist = min(abs(dist), 1d0)
                                    ! redistribute household_transs
                                    do ip_p = 1, n_sp,1
                                        do ir_r=1, n_sr, 1
                                            do id_d =1, n_sd, 1
                                                prob_trans(j, ial, iaimel, ip_p, ir_r, id_d, i) = prob_trans(j, ial, iaimel, ip_p, ir_r, id_d, i) + pi_ip_trans(ip, ip_p, tp)*pi_ir(ir, ir_r)*pi_id(id, id_d)*dist*dist_aime            *prob_trans(j-1, ia, i_aime, ip, ir, id, itm)
                                                prob_trans(j, iar, iaimel, ip_p, ir_r, id_d, i) = prob_trans(j, iar, iaimel, ip_p, ir_r, id_d, i) + pi_ip_trans(ip, ip_p, tp)*pi_ir(ir, ir_r)*pi_id(id, id_d)*(1d0-dist)*dist_aime      *prob_trans(j-1, ia, i_aime, ip, ir, id, itm)
                                                prob_trans(j, ial, iaimer, ip_p, ir_r, id_d, i) = prob_trans(j, ial, iaimer, ip_p, ir_r, id_d, i) + pi_ip_trans(ip, ip_p, tp)*pi_ir(ir, ir_r)*pi_id(id, id_d)*dist*(1d0-dist_aime)      *prob_trans(j-1, ia, i_aime, ip, ir, id, itm)
                                                prob_trans(j, iar, iaimer, ip_p, ir_r, id_d, i) = prob_trans(j, iar, iaimer, ip_p, ir_r, id_d, i) + pi_ip_trans(ip, ip_p, tp)*pi_ir(ir, ir_r)*pi_id(id, id_d)*(1d0-dist)*(1d0-dist_aime)*prob_trans(j-1, ia, i_aime, ip, ir, id, itm)
                                            enddo
                                        enddo
                                    enddo
                                    endif
                                    
                                enddo
                            enddo
                        enddo
                    enddo
                enddo
            enddo 
    end subroutine