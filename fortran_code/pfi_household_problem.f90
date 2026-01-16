!===============================================================================
! FILE: pfi_household_problem.f90
!
! DESCRIPTION:
!   Solves household optimization problem via policy function iteration (PFI)
!   using backward induction. Computes value functions and policy functions for
!   consumption, labor supply, and savings decisions across the lifecycle.
!   Core computational routine for steady state equilibrium.
!
! KEY SUBROUTINES:
!   - household_endo: Main PFI solver for endogenous labor choice
!   - household_exo: Variant with exogenous/fixed labor supply
!   - foc_solver: Solves first-order conditions for {c, l} given state
!
! HOUSEHOLD PROBLEM:
!   Agent maximizes expected lifetime utility:
!     V(j,a,aime,ε,δ,r) = max_{c,l,a'} u(c,l,j) + β(j,δ)*pi(j)*E[V(j+1,a',aime',ε',δ',r')]
!   Subject to:
!     Budget: (1+tauC)*c + a' = (1+r(r))*a/gam + (1-tauL)*(1-t1)*w*omega(j)*ε*l + b(j) + beq(j)
!     Borrowing: a' >= 0 (or small negative value)
!     Labor: 0 <= l <= 1 (if j < jbar), l = 0 (if j >= jbar, retired)
!     AIME: aime' = update based on wage history (for pension calculation)
!
!   Where:
!     u(c,l,j) = utility function (CRRA with labor disutility)
!     β(j,δ) = time preference (possibly age-dependent, shock δ)
!     pi(j) = survival probability to age j+1
!     r(r) = return shock (affects asset returns)
!     ε = income shock (productivity)
!     δ = discount factor shock
!     omega(j) = age-efficiency profile
!     b(j) = pension benefits (0 before retirement)
!     beq(j) = bequest receipts (typically at young ages)
!
! STATE SPACE:
!   6-dimensional state: (j, a, aime, ip, ir, id)
!   - j: Age (1:bigJ, where bigJ ≈ 16 corresponding to age 80 in 5-year periods)
!   - a: Assets (0:n_a, typically n_a=50-100 grid points)
!   - aime: Average Indexed Monthly Earnings for pension (0:n_aime, typically 20-40)
!   - ip: Income shock state (1:n_sp, e.g., n_sp=7 for permanent shocks)
!   - ir: Return shock state (1:n_sr, e.g., n_sr=3 for return heterogeneity)
!   - id: Discount factor shock state (1:n_sd, e.g., n_sd=3 for preference heterogeneity)
!
! POLICY FUNCTIONS (output):
!   - c_ss(j,a,aime,ip,ir,id): Consumption c(state)
!   - l_ss(j,a,aime,ip,ir,id): Labor supply l(state) in [0,1]
!   - svplus_ss(j,a,aime,ip,ir,id): Savings a'(state)
!   - V_ss(j,a,aime,ip,ir,id): Value function V(state)
!   - lab_ss(j,a,aime,ip,ir,id): Labor participation indicator
!   - srate_ss(j,a,aime,ip,ir,id): Savings rate
!   - lab_income_ss(j,a,aime,ip,ir,id): After-tax labor income
!   - tot_income_ss(j,a,aime,ip,ir,id): Total income (labor + capital + transfers)
!
! ALGORITHM (backward induction):
!   1. TERMINAL CONDITION (age bigJ):
!      V(bigJ,a,aime,ε,δ,r) = u(consume all) + warm_glow(a')
!      (or continuation value from bequest motive)
!
!   2. BACKWARD INDUCTION (j = bigJ-1 down to 1):
!      a. Compute expected continuation value (EV):
!         EV(j+1,a',aime',ip,ir,id) = sum over (ip',ir',id') of
!           pi_eps(ip,ip') * pi_r(ir,ir') * pi_delta(id,id') * V(j+1,a',aime',ip',ir',id')
!
!      b. For each state (a,aime,ip,ir,id):
!         - Compute cash-on-hand: coh = (1+r)*a/gam + after_tax_income + benefits + bequests
!         - IF j >= jbar (retired): l = 0, solve for c and a'
!         - IF j < jbar (working): solve FOCs for optimal {c, l, a'}
!         - Store: c_ss(j,⋅), l_ss(j,⋅), svplus_ss(j,⋅), V_ss(j,⋅)
!
!      c. Interpolate EV(a') for off-grid points using linear interpolation
!
!   3. CONVERGENCE CHECK:
!      After full backward pass, check if V_ss has converged
!      (typically converges in first pass with good terminal condition)
!
! FIRST-ORDER CONDITIONS (interior solution):
!   1. Consumption Euler equation:
!      u_c(c,l) = β*pi(j)*(1+r)/(gam*(1+tauC))*E[u_c(c',l')]
!
!   2. Labor supply:
!      -u_l(c,l) / u_c(c,l) = (1-tauL)*(1-t1)*w*omega(j)*ε
!
!   3. Envelope condition:
!      V_a(j,a,aime,ε,δ,r) = u_c(c,l)*(1+r)/gam
!
! UTILITY FUNCTION:
!   u(c,l,j) = [c^(1-sigma) / (1-sigma)] - disutil(j) * [l^(1+1/frisch) / (1+1/frisch)]
!   Where:
!     sigma = risk aversion parameter (typically 1.5-3)
!     frisch = Frisch elasticity of labor supply (typically 0.5-1.0)
!     disutil(j) = age-dependent disutility weight
!
! BEQUEST HANDLING:
!   If switch_unequal_bequest == 2:
!     - Bequests distributed via Zipf law across n_beq quantiles
!     - beq_zipf_ss(ibeq) = bequest amount for quantile ibeq
!     - p_beq(ibeq) = probability of being in quantile ibeq
!     - Introduces wealth inequality at young ages
!     - Separate value function V_beq_ss for bequest recipients
!
! AIME UPDATING:
!   AIME (Average Indexed Monthly Earnings) used for Social Security benefits:
!   - Tracks earnings history during working years
!   - Updated each period: aime' = f(aime, current_earnings, j)
!   - Capped at maximum (aime_cap)
!   - Used to calculate pension benefits at retirement
!
! OPTIMIZATION METHOD:
!   - Grid search over savings a' in discrete grid
!   - For each a', solve FOCs for {c, l} given budget constraint
!   - Choose a' that maximizes V(j,a,aime,ε,δ,r)
!   - Handles corner solutions (l=0, l=1, a'=0)
!
! DEPENDENCIES:
!   - global_vars: All model parameters, grids, and transition matrices
!   - linint: Linear interpolation for off-grid value function
!
! PERFORMANCE NOTES:
!   - Critical computational bottleneck (called for each type m)
!   - Loops over 6-dimensional state space (j × a × aime × ip × ir × id)
!   - Pre-computed transition matrices (pi_ip, pi_ir, pi_id) speed up expectations
!   - Parallelization possible over (a, aime, ip, ir, id) at each age j
!
! ECONOMIC INTERPRETATION:
!   - Agents face uncertainty: income shocks, return shocks, mortality
!   - Lifecycle savings: accumulate during working years, decumulate in retirement
!   - Labor-leisure tradeoff: higher wages increase labor supply (substitution)
!                             but also increase wealth (income effect)
!   - Precautionary savings: uncertainty increases savings
!   - Pension system: reduces need for retirement savings (crowd-out effect)
!===============================================================================
!*******************************************************************************************
! find futur assets for every age, assets grid point, state  
! steady state
subroutine household_endo()

implicit none
real*8 :: available, EV_prim, c_opt, w_opt, c_ss_endo(0:n_a), l_ss_endo(0:n_a), lab_income, lab_income_pretax
real*8 :: av, wage, wage_non_tax, foc(3), optimal_choice(2)
real*8 :: dist, c_help, l_help
real*8 :: EV_prim_after_beq 


!initialization to get rid of anything from before
                    
                    lab_income_ss =0d0
                    lab_income_pretax_ss =0d0
                    tot_income_ss = 0d0
                    tot_income_pretax_ss = 0d0
                    labor_tax = 0d0
                    svplus_ss=0d0 
                    c_ss=0d0
                    V_ss=0d0
                    l_ss = 0.001d0
                    sv_tempo = 0.0d0
                    sv_tempo_beq = 0.0d0
                    lab_income_beq_ss =0d0
                    lab_income_pretax_beq_ss =0d0
                    tot_income_beq_ss = 0d0
                    tot_income_pretax_beq_ss = 0d0

                    svplus_beq_ss=0d0 
                    c_beq_ss=0d0
                    V_beq_ss=0d0
                    l_beq_ss = 0.001d0
                    V_after_beq_ss=0d0
                    
                if((switch_unequal_bequest==2))then

                
                do ibeq=n_beq,1,-1
                    p_beq(ibeq) = 1d0/ibeq**(zipf)/const_zipf !zipf law p.d.f. 
                    beq_zipf_ss(ibeq) =  1d0 * 1d0/(2d0**(n_beq-ibeq+1))* bequest_ss_vfi/(p_beq(ibeq)) ! 1d0/(2d0**(n_beq-ind+1)) - number of people in one sub-cohort,  bequest_ss_vfi - sum of bequest, 
                    beq_zipf_ss(2) = 1d0/(2d0**(n_beq-2))* bequest_ss_vfi/p_beq(2)
                    beq_zipf_ss(1) = 0d0
                enddo
                endif
    
!p_beq(1) = 1.0d0 / float(n_beq)
!p_beq(2) = 0.1d0
!p_beq(3) = 1.0d0 - p_beq(2) - p_beq(1)
!beq_zipf_ss(1) = 0.0d0
!beq_zipf_ss(2) = 0.1d0
!beq_zipf_ss(n_beq) = (bequest_ss_vfi - p_beq(2) *  beq_zipf_ss(2)) / p_beq(3)
                
do ia = 0, n_a, 1 
    do i_aime=0, n_aime,1
        do ip=1, n_sp, 1
            do ir =1, n_sr,1
                do id = 1, n_sd,1
                    c_ss(bigj, ia, i_aime, ip, ir, id) = max(((1d0+(1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)*sv(ia)/gam_ss_vfi + aime_replacement_rate(i_aime)*b_ss_j_vfi(bigJ) + bequest_ss_j_vfi(bigJ))/tc_ss_vfi, 1d-10)
                    l_ss(bigj, ia, i_aime, ip, ir, id) = 0d0
                    lab_income_ss(bigj, ia, i_aime, ip, ir, id) =0d0
                    lab_income_pretax_ss(bigj, ia, i_aime, ip, ir, id) =0d0
                    tot_income_ss(bigj, ia, i_aime, ip, ir, id) = lab_income_ss(bigj, ia, i_aime, ip, ir, id) + ((1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)*sv(ia)/gam_ss_vfi + aime_replacement_rate(i_aime)*b_ss_j_vfi(bigJ)
                    tot_income_pretax_ss(bigj, ia, i_aime, ip, ir, id) = lab_income_pretax_ss(bigj, ia, i_aime, ip, ir, id) + (n_sr_value(ir)+r_ss_pretax_vfi)*sv(ia)/gam_ss_vfi + aime_replacement_rate(i_aime)*b_ss_j_vfi(bigJ)
                    labor_tax(bigj, ia, i_aime, ip, ir, id) = 0d0
                    svplus_ss(bigj, ia, i_aime, ip, ir, id)=0d0
                    aime_plus_ss(bigJ, ia, i_aime, ip, ir, id) = aime(i_aime)
                    disposable_ss(bigJ, ia, i_aime, ip, ir, id) =  tot_income_ss(bigJ, ia, i_aime, ip, ir, id) + sv(ia)/gam_ss_vfi + bequest_ss_j_vfi(bigJ) 
                    V_ss(bigj, ia, i_aime, ip, ir, id) = valuefunc(0d0, aime_plus_ss(bigJ, ia, i_aime, ip, ir, id), c_ss(bigj, ia, i_aime, ip, ir, id),l_ss(bigJ,ia, i_aime, ip, ir, id), bigJ, ip, ir, id)
                enddo
            enddo
        enddo
    enddo
enddo
do ia=0, n_a, 1 
    do i_aime=0, n_aime,1
        do ip = 1, n_sp, 1
             do ir = 1, n_sr, 1
                do id = 1, n_sd, 1   
                    EV_prim = 0d0
                    EV_ss(bigj, ia, i_aime, ip, ir, id)  = 0d0
                    do ir_r= 1, n_sr, 1
                        do id_d= 1, n_sd, 1
                            do ip_p = 1, n_sp,1
                                if(theta == 1_dp)then
                                    EV_prim = EV_prim + (1d0+r_ss_vfi+(1.0d0-tk_ss)*n_sr_value(ir_r))/gam_ss_vfi*pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id,id_d)/c_ss(bigj, ia, i_aime, ip_p, ir_r, id_d)    
                                else
                                    EV_prim = EV_prim + (1d0+r_ss_vfi+(1.0d0-tk_ss)*n_sr_value(ir_r))/gam_ss_vfi*pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id,id_d)*c_ss(bigj, ia, i_aime, ip_p, ir_r, id_d)**(phi -theta*phi -1)
                                endif 
                                EV_ss(bigj, ia, i_aime, ip, ir, id)  = EV_ss(bigj, ia, i_aime, ip, ir, id) + pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id,id_d)*V_ss(bigj, ia, i_aime, ip_p, ir_r, id_d)
                            enddo
                        enddo
                    enddo
                    if(theta == 1)then
                        RHS_ss(bigj, ia, i_aime, ip, ir, id) = 1d0/((delta+n_sd_value(id))*pi_ss_vfi_cond(bigJ)*EV_prim)
                    else
                        RHS_ss(bigj, ia, i_aime, ip, ir, id) = (delta+n_sd_value(id))*pi_ss_vfi_cond(bigJ)*EV_prim
                        EV_ss(bigj, ia, i_aime, ip, ir, id)  = ((1d0-theta)*EV_ss(bigj, ia, i_aime, ip, ir, id))**(1d0/(1d0-theta))
                        
                    endif
                    
                enddo
            enddo
        enddo
    enddo
enddo

do j = bigJ-1, 1, -1
    poss_ass_sum_ss(j) = 0d0
        do i= j, bigJ, 1
            if(i < jbar_ss_vf .and. ((i .ne. beq_age) .or. (switch_unequal_bequest .ne. 2)))then
                poss_ass_sum_ss(j) = poss_ass_sum_ss(j) + ((1 - tL_ss)*(w_pom_ss_vfi(i)*omega_ss(j)*n_sp_value(1))**(1-lambda) + omega_ss(j)*n_sp_value(1)*w_pom_ss_implicit_vfi(i) + bequest_ss_j_vfi(i))/((1d0+(1.0d0-tk_ss)*n_sr_value(1)+r_ss_vfi)/gam_ss_vfi)**(i-j) 
            elseif (i == beq_age .and. switch_unequal_bequest == 2) then
                                poss_ass_sum_ss(j) = poss_ass_sum_ss(j) + ((1 - tL_ss)*(w_pom_ss_vfi(i)*omega_ss(j)*n_sp_value(1))**(1-lambda) + omega_ss(j)*n_sp_value(1)*w_pom_ss_implicit_vfi(i) + beq_zipf_ss(1))/((1d0+(1.0d0-tk_ss)*n_sr_value(1)+r_ss_vfi)/gam_ss_vfi)**(i-j) 
            else
                poss_ass_sum_ss(j) = poss_ass_sum_ss(j) + (aime_replacement_rate(n_aime)*b_ss_j_vfi(i)             + bequest_ss_j_vfi(i))/((1d0+(1.0d0-tk_ss)*n_sr_value(1)+r_ss_vfi)/gam_ss_vfi)**(i-j)              
            endif         
        enddo   
    do ia=0, n_a, 1
        do i_aime=0, n_aime,1
            do ip=1, n_sp,1
                do ir = 1, n_sr,1
                    do id =1, n_sd,1
                       
                        if((sv(ia)*(1d0+(1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)/gam_ss_vfi + poss_ass_sum_ss(j))  <a_l) then
                            
                            c_ss(j, ia, i_aime, ip, ir, id) = 1d-10 
                            
                            if((j < jbar_ss_vf) .and. (j == beq_age) .and. (switch_unequal_bequest == 2)) then
                                
                                do ibeq = 1,n_beq,1
                                l_beq_ss(ibeq, ia, i_aime, ip, ir, id) = 1d0 
                                
                                if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                    lab_income = (1 - tL_ss)*(n_sp_value(ip)*w_pom_ss_vfi(j)/LabIncAVG_ss_vfi)**(1-lambda)*LabIncAVG_ss_vfi + n_sp_value(ip)*w_pom_ss_implicit_vfi(j)
                                    lab_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) =lab_income
                                    lab_income_pretax = n_sp_value(ip)*w_pom_ss_vfi(j)  
                                else
                                    lab_income = (1 - tL_ss)*omega_ss(j)*(n_sp_value(ip)*w_pom_ss_vfi(j)/LabIncAVG_ss_vfi)**(1-lambda)*LabIncAVG_ss_vfi + omega_ss(j)*n_sp_value(ip)*w_pom_ss_implicit_vfi(j)
                                    lab_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) =lab_income
                                    lab_income_pretax = omega_ss(j)*n_sp_value(ip)*w_pom_ss_vfi(j)  
                                endif
                                
                                lab_income_pretax_beq_ss(ibeq, ia, i_aime, ip, ir, id) =lab_income_pretax
                                tot_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) =  lab_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) + sv(ia)*((1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)/gam_ss_vfi + beq_zipf_ss(ibeq)
                                tot_income_pretax_beq_ss(ibeq, ia, i_aime, ip, ir, id) = lab_income_pretax_beq_ss(ibeq, ia, i_aime, ip, ir, id) + sv(ia)*(n_sr_value(ir)+r_ss_pretax_vfi)/gam_ss_vfi   +aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                                disposable_beq_ss(ibeq, ia, i_aime, ip, ir, id) =  tot_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) + sv(ia)/gam_ss_vfi + aime_replacement_rate(i_aime)*b_ss_j_vfi(j) + beq_zipf_ss(ibeq)
                                
                                c_beq_ss(ibeq, ia, i_aime, ip, ir, id) = 1d-10 
                                l_ss(j, ia, i_aime, ip, ir, id)  = p_beq(ibeq) * l_beq_ss(ibeq, ia, i_aime, ip, ir, id) + l_ss(j, ia, i_aime, ip, ir, id)
                                lab_income_ss(j, ia, i_aime, ip, ir, id) = p_beq(ibeq) * lab_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) + lab_income_ss(j, ia, i_aime, ip, ir, id)
                                lab_income_pretax_ss(j, ia, i_aime, ip, ir, id) = p_beq(ibeq) * lab_income_pretax_beq_ss(ibeq, ia, i_aime, ip, ir, id) + lab_income_pretax_ss(j, ia, i_aime, ip, ir, id)
                                tot_income_ss(j, ia, i_aime, ip, ir, id) =   p_beq(ibeq) *tot_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) + tot_income_ss(j, ia, i_aime, ip, ir, id)
                                tot_income_pretax_ss(j, ia, i_aime, ip, ir, id) = p_beq(ibeq) * tot_income_pretax_beq_ss(ibeq, ia, i_aime, ip, ir, id) + tot_income_pretax_ss(j, ia, i_aime, ip, ir, id)
                                disposable_ss(j, ia, i_aime, ip, ir, id) =  p_beq(ibeq) * disposable_beq_ss(ibeq, ia, i_aime, ip, ir, id) + disposable_ss(j, ia, i_aime, ip, ir, id)
                                
                                enddo
                                
                                
                            elseif(((j .ne. beq_age) .or. (switch_unequal_bequest .ne. 2))) then
                            if (j<jbar_ss_vf) then
                                l_ss(j, ia, i_aime, ip, ir, id) = 1d0 
                                 if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                    lab_income = (1 - tL_ss)*(n_sp_value(ip)*w_pom_ss_vfi(j)/LabIncAVG_ss_vfi)**(1-lambda)*LabIncAVG_ss_vfi +n_sp_value(ip)*w_pom_ss_implicit_vfi(j)
                                    lab_income_ss(j, ia, i_aime, ip, ir, id) =lab_income
                                    lab_income_pretax = n_sp_value(ip)*w_pom_ss_vfi(j)  
                                else
                                    lab_income = (1 - tL_ss)*omega_ss(j)*(n_sp_value(ip)*w_pom_ss_vfi(j)/LabIncAVG_ss_vfi)**(1-lambda)*LabIncAVG_ss_vfi + omega_ss(j)*n_sp_value(ip)*w_pom_ss_implicit_vfi(j)
                                    lab_income_ss(j, ia, i_aime, ip, ir, id) =lab_income
                                    lab_income_pretax = omega_ss(j)*n_sp_value(ip)*w_pom_ss_vfi(j)                                                           
                                endif
                                
                                lab_income_pretax_ss(j, ia, i_aime, ip, ir, id) =lab_income_pretax
                                tot_income_ss(j, ia, i_aime, ip, ir, id) =  lab_income_ss(j, ia, i_aime, ip, ir, id) +  aime_replacement_rate(i_aime)*b_ss_j_vfi(j) + sv(ia)*((1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)/gam_ss_vfi
                                tot_income_pretax_ss(j, ia, i_aime, ip, ir, id) = lab_income_pretax_ss(j, ia, i_aime, ip, ir, id) + sv(ia)*(n_sr_value(ir)+r_ss_pretax_vfi)/gam_ss_vfi   +aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                                disposable_ss(j, ia, i_aime, ip, ir, id) =  tot_income_ss(j, ia, i_aime, ip, ir, id) + sv(ia)/gam_ss_vfi + bequest_ss_j_vfi(j) + aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                                
                            else
                                l_ss(j,ia, i_aime, ip, ir, id) = 0d0
                                lab_income = 0d0
                                lab_income_ss(j, ia, i_aime, ip, ir, id) = lab_income
                                lab_income_pretax = 0d0
                                lab_income_pretax_ss(j, ia, i_aime, ip, ir, id) = lab_income_pretax
                                tot_income_ss(j, ia, i_aime, ip, ir, id) =  lab_income_ss(j, ia, i_aime, ip, ir, id) + + aime_replacement_rate(i_aime)*b_ss_j_vfi(j) + sv(ia)*((1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)/gam_ss_vfi 
                                tot_income_pretax_ss(j, ia, i_aime, ip, ir, id) = lab_income_pretax_ss(j, ia, i_aime, ip, ir, id) + sv(ia)*(n_sr_value(ir)+r_ss_pretax_vfi)/gam_ss_vfi  +aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                                disposable_ss(j, ia, i_aime, ip, ir, id) =  tot_income_ss(j, ia, i_aime, ip, ir, id) + sv(ia)/gam_ss_vfi + bequest_ss_j_vfi(j) + aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                            endif
                            
                            
                            if( j == beq_age .and. switch_unequal_bequest == 2) then
                                sv_tempo(j, ia, i_aime, ip, ir, id) = 0.0d0
                                do ibeq = 1,n_beq,1
                                    
                                sv_tempo_beq(ibeq, ia, i_aime, ip, ir, id) = (tc_ss_vfi* c_beq_ss(ibeq, ia, i_aime, ip, ir, id)+sv(ia)-lab_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) &
                                                                  -aime_replacement_rate(i_aime)*b_ss_j_vfi(j)-beq_zipf_ss(ibeq))/((1d0+(1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)/gam_ss_vfi)
                                
                                sv_tempo(j, ia, i_aime, ip, ir, id) = p_beq(ibeq) * sv_tempo_beq(ibeq, ia, i_aime, ip, ir, id) + sv_tempo(j, ia, i_aime, ip, ir, id)
                                enddo
                            else
                                
                                sv_tempo(j, ia, i_aime, ip, ir, id) = (tc_ss_vfi*c_ss(j, ia, i_aime, ip, ir, id)+sv(ia)-lab_income&
                                                                  -aime_replacement_rate(i_aime)*b_ss_j_vfi(j)-  bequest_ss_j_vfi(j))/((1d0+(1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)/gam_ss_vfi)
                            endif
                            
                                endif
                        
                        else 
                            if(j>=jbar_ss_vf) then ! retired thus labor choice is trivial 
                                    l_ss(j, ia, i_aime, ip, ir, id) = 0d0
                                    lab_income = 0d0 
                                    lab_income_ss(j, ia, i_aime, ip, ir, id) =lab_income
                                    lab_income_pretax = 0d0 
                                    lab_income_pretax_ss(j, ia, i_aime, ip, ir, id) =lab_income_pretax
                                    tot_income_ss(j, ia, i_aime, ip, ir, id) =  lab_income_ss(j, ia, i_aime, ip, ir, id) +  aime_replacement_rate(i_aime)*b_ss_j_vfi(j)+  sv(ia)*((1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)/gam_ss_vfi
                                    tot_income_pretax_ss(j, ia, i_aime, ip, ir, id) = lab_income_pretax_ss(j, ia, i_aime, ip, ir, id) + sv(ia)*(n_sr_value(ir)+r_ss_pretax_vfi)/gam_ss_vfi  +aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                                    disposable_ss(j, ia, i_aime, ip, ir, id) =  tot_income_ss(j, ia, i_aime, ip, ir, id) + sv(ia)/gam_ss_vfi + bequest_ss_j_vfi(j) + aime_replacement_rate(i_aime)*b_ss_j_vfi(j)

                                    if(theta == 1)then ! consumption can be calculated diractly from RHS
                                        c_ss(j, ia, i_aime, ip, ir, id) = max(RHS_ss(j+1, ia, i_aime, ip, ir, id),1d-15)
                                    else
                                        c_ss(j, ia, i_aime, ip, ir, id) = max(RHS_ss(j+1, ia, i_aime, ip, ir, id)**(1d0/(phi -theta*phi -1)),1d-15)
                                    endif
                                    
                                                  sv_tempo(j, ia, i_aime, ip, ir, id) = (tc_ss_vfi*c_ss(j, ia, i_aime, ip, ir, id)+sv(ia)&
                                                                  - lab_income-aime_replacement_rate(i_aime)*b_ss_j_vfi(j)&
                                                                  - bequest_ss_j_vfi(j))/((1d0+(1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)/gam_ss_vfi )    
                            else
                                    
                                 if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                    wage            = n_sp_value(ip)*w_pom_ss_vfi(j)
                                    wage_non_tax    = n_sp_value(ip)*w_pom_ss_implicit_vfi(j)                                
                                else
                                    wage            = omega_ss(j)*n_sp_value(ip)*w_pom_ss_vfi(j)
                                    wage_non_tax    = omega_ss(j)*n_sp_value(ip)*w_pom_ss_implicit_vfi(j)  
                                endif     
                                    if  (j == beq_age .and. switch_unequal_bequest == 2) then
                                        
                                    sv_tempo(j, ia, i_aime, ip, ir, id) = 0.0d0
                                    do ibeq = 1,n_beq
                                        
                                    if(theta == 1)then
                                        
                                            c_beq_ss(ibeq, ia, i_aime, ip, ir, id) = max(RHS_after_beq_ss(ibeq, ia, i_aime, ip, ir, id),1d-15)
                                            c_opt = tc_ss_vfi*c_beq_ss(ibeq, ia, i_aime, ip, ir, id) 
                                            l_beq_ss(ibeq, ia, i_aime, ip, ir, id) = optimal_labor(c_opt, wage, wage_non_tax, phi, tL_ss, lambda, LabIncAVG_ss_vfi,tc_ss_vfi )
                                    else
                                            
                                            if ((switch_discount_risk .ne. 2) .or. (id .ne. n_sd)) then
                                            optimal_choice = optimal_consumption_and_labor_new(RHS_after_beq_ss(ibeq, ia, i_aime, ip, ir, id), phi, theta, tL_ss, lambda, wage,     wage_non_tax, tc_ss_vfi, LabIncAVG_ss_vfi)
                                            c_beq_ss(ibeq, ia, i_aime, ip, ir, id)  = optimal_choice(1)
                                            l_beq_ss(ibeq, ia, i_aime, ip, ir, id)  = optimal_choice(2)
                                            

                                            
                                            endif
                                            

                                    endif
                                    
                                    lab_income = (1d0 - tL_ss)*(wage*l_beq_ss(ibeq, ia, i_aime, ip, ir, id)/LabIncAVG_ss_vfi)**(1-lambda)*LabIncAVG_ss_vfi &
                                                 +  wage_non_tax*l_beq_ss(ibeq, ia, i_aime, ip, ir, id)
                                    lab_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) = lab_income
                                    
                                     if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                        lab_income_pretax = n_sp_value(ip)*w_pom_ss_vfi(j)*l_beq_ss(ibeq, ia, i_aime, ip, ir, id)  +  wage_non_tax*l_beq_ss(ibeq, ia, i_aime, ip, ir, id)
                                    else
                                        lab_income_pretax = omega_ss(j) * n_sp_value(ip)*w_pom_ss_vfi(j)*l_beq_ss(ibeq, ia, i_aime, ip, ir, id)  +  wage_non_tax*l_beq_ss(ibeq, ia, i_aime, ip, ir, id)
                                    endif
                                    lab_income_pretax_beq_ss(ibeq, ia, i_aime, ip, ir, id) = lab_income_pretax
                                    tot_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) =  lab_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) + sv(ia)*((1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)/gam_ss_vfi
                                    tot_income_pretax_beq_ss(ibeq, ia, i_aime, ip, ir, id) = lab_income_pretax_beq_ss(ibeq, ia, i_aime, ip, ir, id) + sv(ia)*(n_sr_value(ir)+r_ss_pretax_vfi)/gam_ss_vfi  +aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                                    disposable_beq_ss(ibeq, ia, i_aime, ip, ir, id) =  tot_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) + sv(ia)/gam_ss_vfi + beq_zipf_ss(ibeq)  + aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                                    
                                    sv_tempo_beq(ibeq, ia, i_aime, ip, ir, id) = (tc_ss_vfi*c_beq_ss(ibeq, ia, i_aime, ip, ir, id)+sv(ia)-lab_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) &
                                                                  -aime_replacement_rate(i_aime)*b_ss_j_vfi(j)-beq_zipf_ss(ibeq))/((1d0+(1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)/gam_ss_vfi)
                                    
                                    l_ss(j, ia, i_aime, ip, ir, id)  = p_beq(ibeq) * l_beq_ss(ibeq, ia, i_aime, ip, ir, id) + l_ss(j, ia, i_aime, ip, ir, id)
                                    lab_income_ss(j, ia, i_aime, ip, ir, id) = p_beq(ibeq) * lab_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) + lab_income_ss(j, ia, i_aime, ip, ir, id)
                                    lab_income_pretax_ss(j, ia, i_aime, ip, ir, id) = p_beq(ibeq) * lab_income_pretax_beq_ss(ibeq, ia, i_aime, ip, ir, id) + lab_income_pretax_ss(j, ia, i_aime, ip, ir, id)
                                    tot_income_ss(j, ia, i_aime, ip, ir, id) =   p_beq(ibeq) *tot_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) + tot_income_ss(j, ia, i_aime, ip, ir, id)
                                    tot_income_pretax_ss(j, ia, i_aime, ip, ir, id) = p_beq(ibeq) * tot_income_pretax_beq_ss(ibeq, ia, i_aime, ip, ir, id) + tot_income_pretax_ss(j, ia, i_aime, ip, ir, id)
                                    disposable_ss(j, ia, i_aime, ip, ir, id) =  p_beq(ibeq) * disposable_beq_ss(ibeq, ia, i_aime, ip, ir, id) + disposable_ss(j, ia, i_aime, ip, ir, id)
                                    
                                    sv_tempo(j, ia, i_aime, ip, ir, id) = p_beq(ibeq) * sv_tempo_beq(ibeq, ia, i_aime, ip, ir, id) + sv_tempo(j, ia, i_aime, ip, ir, id)
                                                                    
                                    enddo
                                    
                                    
                                    else
                                   
                                        
                                    if(theta == 1)then
                                            c_ss(j, ia, i_aime, ip, ir, id) = max(RHS_ss(j+1, ia, i_aime, ip, ir, id),1d-15)
                                            c_opt = tc_ss_vfi*c_ss(j, ia, i_aime, ip, ir, id) 
                                            l_ss(j, ia, i_aime, ip, ir, id) = optimal_labor(c_opt, wage, wage_non_tax, phi, tL_ss, lambda, LabIncAVG_ss_vfi,tc_ss_vfi )
                                    else
                                            
                                            if ((switch_discount_risk .ne. 2) .or. (id .ne. n_sd)) then

                                            optimal_choice = optimal_consumption_and_labor_new(RHS_ss(j+1, ia, i_aime, ip, ir, id), phi, theta, tL_ss, lambda, wage,     wage_non_tax, tc_ss_vfi, LabIncAVG_ss_vfi)
                                            c_ss(j, ia, i_aime, ip, ir, id) = optimal_choice(1)
                                            l_ss(j, ia, i_aime, ip, ir, id)  = optimal_choice(2)
                                            
                                            endif
                                    endif
                                    

                                    
                                    lab_income = (1d0 - tL_ss)*(wage*l_ss(j, ia, i_aime, ip, ir, id)/LabIncAVG_ss_vfi)**(1-lambda)*LabIncAVG_ss_vfi &
                                                 +  wage_non_tax*l_ss(j, ia, i_aime, ip, ir, id)
                                    lab_income_ss(j, ia, i_aime, ip, ir, id) = lab_income
                                    
                                     if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                        lab_income_pretax = n_sp_value(ip)*w_pom_ss_vfi(j)*l_ss(j, ia, i_aime, ip, ir, id)  +  wage_non_tax*l_ss(j, ia, i_aime, ip, ir, id)
                                    else
                                        lab_income_pretax = omega_ss(j)*n_sp_value(ip)*w_pom_ss_vfi(j)*l_ss(j, ia, i_aime, ip, ir, id)  +  wage_non_tax*l_ss(j, ia, i_aime, ip, ir, id)
                                    endif       
                                    lab_income_pretax_ss(j, ia, i_aime, ip, ir, id) = lab_income_pretax                                    
                                    tot_income_ss(j, ia, i_aime, ip, ir, id) =  lab_income_ss(j, ia, i_aime, ip, ir, id)  + aime_replacement_rate(i_aime)*b_ss_j_vfi(j) +  sv(ia)*((1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)/gam_ss_vfi
                                    tot_income_pretax_ss(j, ia, i_aime, ip, ir, id) = lab_income_pretax_ss(j, ia, i_aime, ip, ir, id) + sv(ia)*(n_sr_value(ir)+r_ss_pretax_vfi)/gam_ss_vfi  +aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                                    disposable_ss(j, ia, i_aime, ip, ir, id) =  tot_income_ss(j, ia, i_aime, ip, ir, id) + sv(ia)/gam_ss_vfi + bequest_ss_j_vfi(j)  + aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                                    
                                    
                                    sv_tempo(j, ia, i_aime, ip, ir, id) = (tc_ss_vfi*c_ss(j, ia, i_aime, ip, ir, id)+sv(ia)&
                                                                  - lab_income-aime_replacement_rate(i_aime)*b_ss_j_vfi(j)&
                                                                  - bequest_ss_j_vfi(j))/((1d0+(1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)/gam_ss_vfi )    
                                    endif
                                                                   
                            
                                                               

                                    endif   
                                    

                                     
                            
                            
                        endif
                        
                    enddo
                enddo
            enddo
        enddo
    enddo
    if (j == 1) then
         l_ss_endo = 0
    endif
    do i_aime=0, n_aime, 1
        do ip=1, n_sp, 1
             do ir=1, n_sr, 1
                do id=1, n_sd, 1
                    if ((switch_discount_risk .ne. 2) .or. (id .ne. n_sd)) then
                        
                        if (j == beq_age .and. switch_unequal_bequest == 2) then 
                            svplus_ss(j,:, i_aime, ip,ir, id) = 0.0d0
                            do ibeq = 1, n_beq
                            call change_grid_piecewise_lin_spline(sv_tempo_beq(ibeq,:, i_aime, ip, ir, id), sv,   sv, svplus_beq_ss(ibeq,:, i_aime, ip,ir, id))

                            enddo
                        else
                            call change_grid_piecewise_lin_spline(sv_tempo(j,:, i_aime, ip, ir, id), sv,   sv, svplus_ss(j,:, i_aime, ip,ir, id))   
                        endif
                    else
                        svplus_ss(j,:, i_aime, ip,ir, id) = 0.0d0
                    endif
                enddo
            enddo  
        enddo
    enddo
     do ia=0, n_a, 1  
         do i_aime=0, n_aime,1       
            do ip=1, n_sp, 1
                 do ir=1, n_sr, 1
                    do id= 1, n_sd, 1 
                        
                        if (j == beq_age .and. switch_unequal_bequest == 2) then 
                            
                            do ibeq = 1,n_beq
                                
                            if(svplus_beq_ss(ibeq, ia, i_aime, ip, ir, id)<a_l)then
                                svplus_beq_ss(ibeq, ia, i_aime, ip, ir, id) = a_l
                                
                            endif
                                svplus_ss(j, ia, i_aime, ip, ir, id) = p_beq(ibeq) *  svplus_beq_ss(ibeq, ia, i_aime, ip, ir, id) + svplus_ss(j, ia, i_aime, ip, ir, id) 
                            enddo
                            
                        else
                            if(svplus_ss(j, ia, i_aime, ip, ir, id)<a_l)then
                                svplus_ss(j, ia, i_aime, ip, ir, id) = a_l
                            endif
                        endif
                        
                        if(j>=jbar_ss_vf) then
                            
                           available = (1d0+(1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)*sv(ia)/gam_ss_vfi + aime_replacement_rate(i_aime)*b_ss_j_vfi(j)+ bequest_ss_j_vfi(j) &
                                        - svplus_ss(j, ia, i_aime, ip, ir, id)
                            
                            c_ss(j, ia, i_aime, ip, ir, id) = max( (available)/tc_ss_vfi, 1e-10)
                            l_ss(j, ia, i_aime, ip, ir, id)=0d0
                            lab_income = 0d0
                            lab_income_ss(j, ia, i_aime, ip, ir, id)=0d0
                            lab_income_pretax = 0d0
                            lab_income_pretax_ss(j, ia, i_aime, ip, ir, id)=0d0
                            labor_tax(j, ia, i_aime, ip, ir, id) = 0d0
                            aime_plus_ss(j, ia, i_aime, ip, ir, id) = aime(i_aime)
                            tot_income_ss(j, ia, i_aime, ip, ir, id) =  lab_income_ss(j, ia, i_aime, ip, ir, id) + sv(ia)*((1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)/gam_ss_vfi +  aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                            tot_income_pretax_ss(j, ia, i_aime, ip, ir, id) = lab_income_pretax_ss(j, ia, i_aime, ip, ir, id) + sv(ia)*(n_sr_value(ir)+r_ss_pretax_vfi)/gam_ss_vfi +aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                            disposable_ss(j, ia, i_aime, ip, ir, id) =  tot_income_ss(j, ia, i_aime, ip, ir, id) + sv(ia)/gam_ss_vfi + bequest_ss_j_vfi(j)  + aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                            srate_ss(j, ia, i_aime, ip, ir, id) = 1 - (tc_ss_vfi *  c_ss(j, ia, i_aime, ip, ir, id))  / ( tot_income_ss(j, ia, i_aime, ip, ir, id)   + aime_replacement_rate(i_aime)*b_ss_j_vfi(j)+ bequest_ss_j_vfi(j) ) 
                            V_ss(j, ia, i_aime, ip, ir, id) = valuefunc(svplus_ss(j, ia, i_aime, ip, ir, id), aime_plus_ss(j, ia, i_aime, ip, ir, id), c_ss(j, ia, i_aime, ip, ir, id), l_ss(j, ia, i_aime, ip, ir, id), j,  ip, ir, id) 
                        else                     
                            
                            
                             if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                wage            = n_sp_value(ip)*w_pom_ss_vfi(j)
                                wage_non_tax    = n_sp_value(ip)*w_pom_ss_implicit_vfi(j)                                
                            else
                                wage            = omega_ss(j)*n_sp_value(ip)*w_pom_ss_vfi(j)
                                wage_non_tax    = omega_ss(j)*n_sp_value(ip)*w_pom_ss_implicit_vfi(j)  
                            endif     
                            tl_com  = tl_ss
                            lambda_com = lambda
                            
                            if(j == beq_age .and. switch_unequal_bequest == 2) then                             
                                c_ss(j, ia, i_aime, ip, ir, id) = 0.0d0
                                l_ss(j, ia, i_aime, ip, ir, id) = 0.0d0
                                labor_tax(j, ia, i_aime, ip, ir, id) = 0.0d0
                                lab_income_ss(j, ia, i_aime, ip, ir, id) = 0.0d0
                                lab_income_pretax_ss(j, ia, i_aime, ip, ir, id) = 0.0d0
                                tot_income_ss(j, ia, i_aime, ip, ir, id) = 0.0d0
                                tot_income_pretax_ss(j, ia, i_aime, ip, ir, id) = 0.0d0
                                aime_plus_ss(j, ia, i_aime, ip, ir, id) = 0.0d0
                                disposable_ss(j, ia, i_aime, ip, ir, id) = 0.0d0
                                srate_ss(j, ia, i_aime, ip, ir, id)  = 0.0d0
                                V_ss(j, ia, i_aime, ip, ir, id) = 0.0d0
                            do ibeq = 1,n_beq,1
                                
                                
                                
                                
                                
                            available = (1d0+(1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)*sv(ia)/gam_ss_vfi + aime_replacement_rate(i_aime)*b_ss_j_vfi(j)+ beq_zipf_ss(ibeq) &
                                        - svplus_beq_ss(ibeq, ia, i_aime, ip, ir, id)    
                            if (switch_fix_labor == 0) then 
                                foc = foc_intratemp(available, wage, wage_non_tax, tc_ss_vfi, l_beq_ss(ibeq, ia, i_aime, ip, ir, id), LabIncAVG_ss_vfi)
                            else
                                foc = foc_intratemp(available, wage, wage_non_tax, tc_ss_vfi, switch_fix_labor, LabIncAVG_ss_vfi)
                            endif
                            
                            c_beq_ss(ibeq, ia, i_aime, ip, ir, id) = foc(1)
                            l_beq_ss(ibeq, ia, i_aime, ip, ir, id) = foc(2)
                            labor_tax_beq(ibeq, ia, i_aime, ip, ir, id) = foc(3) 
                            lab_income = (1d0 - tL_ss)*(wage*l_beq_ss(ibeq, ia, i_aime, ip, ir, id)/LabIncAVG_ss_vfi)**(1-lambda)*LabIncAVG_ss_vfi &
                                                 +  wage_non_tax*l_beq_ss(ibeq, ia, i_aime, ip, ir, id)
                            lab_income_beq_ss(ibeq, ia, i_aime, ip, ir, id)  =lab_income
                            
                             if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                lab_income_pretax =  n_sp_value(ip)*w_pom_ss_vfi(j)*l_beq_ss(ibeq, ia, i_aime, ip, ir, id) +  wage_non_tax*l_beq_ss(ibeq, ia, i_aime, ip, ir, id)
                                aime_plus_beq_ss(ibeq, ia, i_aime, ip, ir, id) =(float(j-1)* aime(i_aime) +  min(w_pom_ss_vfi(j)*n_sp_value(ip)*l_beq_ss(ibeq, ia, i_aime, ip, ir, id)/LabIncAVG_ss_vfi, aime_cap ))/float(j)
                            else
                                lab_income_pretax =  omega_ss(j)*n_sp_value(ip)*w_pom_ss_vfi(j)*l_beq_ss(ibeq, ia, i_aime, ip, ir, id) +  wage_non_tax*l_beq_ss(ibeq, ia, i_aime, ip, ir, id)    
                                aime_plus_beq_ss(ibeq, ia, i_aime, ip, ir, id) =(float(j-1)* aime(i_aime) +  min(w_pom_ss_vfi(j)*omega_ss(j)*n_sp_value(ip)*l_beq_ss(ibeq, ia, i_aime, ip, ir, id)/LabIncAVG_ss_vfi, aime_cap ))/float(j)
                            endif
                            

                            lab_income_pretax_beq_ss(ibeq, ia, i_aime, ip, ir, id)  = lab_income_pretax
                            tot_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) =  lab_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) + sv(ia)*((1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)/gam_ss_vfi
                            tot_income_pretax_beq_ss(ibeq, ia, i_aime, ip, ir, id) = lab_income_pretax_beq_ss(ibeq, ia, i_aime, ip, ir, id) + sv(ia)*(n_sr_value(ir)+r_ss_pretax_vfi)/gam_ss_vfi   +aime_replacement_rate(i_aime)*b_ss_j_vfi(j)

                            disposable_beq_ss(ibeq, ia, i_aime, ip, ir, id) =  tot_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) + sv(ia)/gam_ss_vfi + beq_zipf_ss(ibeq) + aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                            
                            srate_beq_ss(ibeq, ia, i_aime, ip, ir, id) = 1 - (tc_ss_vfi *  c_beq_ss(ibeq, ia, i_aime, ip, ir, id)) / ( tot_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) +  aime_replacement_rate(i_aime)*b_ss_j_vfi(j) +  beq_zipf_ss(ibeq) ) 
                            
                            V_beq_ss(ibeq, ia, i_aime, ip, ir, id) = valuefunc(svplus_beq_ss(ibeq, ia, i_aime, ip, ir, id), aime_plus_beq_ss(ibeq, ia, i_aime, ip, ir, id), c_beq_ss(ibeq, ia, i_aime, ip, ir, id), l_beq_ss(ibeq, ia, i_aime, ip, ir, id), j,  ip, ir, id) 
                            ! agg.
                            
                            c_ss(j, ia, i_aime, ip, ir, id) = p_beq(ibeq) * c_beq_ss(ibeq, ia, i_aime, ip, ir, id) + c_ss(j, ia, i_aime, ip, ir, id)
                            l_ss(j, ia, i_aime, ip, ir, id) = p_beq(ibeq) * l_beq_ss(ibeq, ia, i_aime, ip, ir, id) + l_ss(j, ia, i_aime, ip, ir, id)
                            labor_tax(j, ia, i_aime, ip, ir, id) = p_beq(ibeq) * labor_tax_beq(ibeq, ia, i_aime, ip, ir, id)  +  labor_tax(j, ia, i_aime, ip, ir, id)
                            lab_income_ss(j, ia, i_aime, ip, ir, id)  =  p_beq(ibeq) * lab_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) +  lab_income_ss(j, ia, i_aime, ip, ir, id)
                            lab_income_pretax_ss(j, ia, i_aime, ip, ir, id)  = p_beq(ibeq) * lab_income_pretax_beq_ss(ibeq, ia, i_aime, ip, ir, id) + lab_income_pretax_ss(j, ia, i_aime, ip, ir, id)
                            tot_income_ss(j, ia, i_aime, ip, ir, id) =  p_beq(ibeq) * tot_income_beq_ss(ibeq, ia, i_aime, ip, ir, id) + tot_income_ss(j, ia, i_aime, ip, ir, id)
                            tot_income_pretax_ss(j, ia, i_aime, ip, ir, id) = p_beq(ibeq) *  tot_income_pretax_beq_ss(ibeq, ia, i_aime, ip, ir, id) + tot_income_pretax_ss(j, ia, i_aime, ip, ir, id)
                            aime_plus_ss(j, ia, i_aime, ip, ir, id)  =  p_beq(ibeq) * aime_plus_beq_ss(ibeq, ia, i_aime, ip, ir, id) + aime_plus_ss(j, ia, i_aime, ip, ir, id)
                            disposable_ss(j, ia, i_aime, ip, ir, id) =  p_beq(ibeq) * disposable_beq_ss(ibeq, ia, i_aime, ip, ir, id) + disposable_ss(j, ia, i_aime, ip, ir, id)
                            srate_ss(j, ia, i_aime, ip, ir, id) = p_beq(ibeq) *  srate_beq_ss(ibeq, ia, i_aime, ip, ir, id) + srate_ss(j, ia, i_aime, ip, ir, id) 
                            V_ss(j, ia, i_aime, ip, ir, id)     = p_beq(ibeq) *  V_beq_ss(ibeq,ia,i_aime, ip, ir, id)  + V_ss(j, ia, i_aime, ip, ir, id)
                            
                            enddo
                            else
                           
                                
                            available = (1d0+(1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)*sv(ia)/gam_ss_vfi + aime_replacement_rate(i_aime)*b_ss_j_vfi(j)+ bequest_ss_j_vfi(j) &
                                        - svplus_ss(j, ia, i_aime, ip, ir, id)    
                                
                            if (switch_fix_labor == 0) then 
                                foc = foc_intratemp(available, wage, wage_non_tax, tc_ss_vfi, l_ss(j, ia, i_aime, ip, ir, id), LabIncAVG_ss_vfi)
                            else
                                foc = foc_intratemp(available, wage, wage_non_tax, tc_ss_vfi, switch_fix_labor, LabIncAVG_ss_vfi)
                            endif
                            
                            c_ss(j, ia, i_aime, ip, ir, id) = foc(1)
                            l_ss(j, ia, i_aime, ip, ir, id) = foc(2)
                            labor_tax(j, ia, i_aime, ip, ir, id) = foc(3) 
                            lab_income = (1d0 - tL_ss)*(wage*l_ss(j, ia, i_aime, ip, ir, id)/LabIncAVG_ss_vfi)**(1-lambda)*LabIncAVG_ss_vfi &
                                                 +  wage_non_tax*l_ss(j, ia, i_aime, ip, ir, id)
                            
                            lab_income_ss(j, ia, i_aime, ip, ir, id)  =lab_income
                             if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                lab_income_pretax =  n_sp_value(ip)*w_pom_ss_vfi(j)*l_ss(j, ia, i_aime, ip, ir, id) +  wage_non_tax*l_ss(j, ia, i_aime, ip, ir, id)
                                aime_plus_ss(j, ia, i_aime, ip, ir, id) =(float(j-1)* aime(i_aime) +  min(w_pom_ss_vfi(j)*n_sp_value(ip)*l_ss(j, ia, i_aime, ip, ir, id)/LabIncAVG_ss_vfi, aime_cap ))/float(j)
                            else
                                lab_income_pretax =  omega_ss(j)*n_sp_value(ip)*w_pom_ss_vfi(j)*l_ss(j, ia, i_aime, ip, ir, id) +  wage_non_tax*l_ss(j, ia, i_aime, ip, ir, id)
                                aime_plus_ss(j, ia, i_aime, ip, ir, id) =(float(j-1)* aime(i_aime) +  min(w_pom_ss_vfi(j)*omega_ss(j)*n_sp_value(ip)*l_ss(j, ia, i_aime, ip, ir, id)/LabIncAVG_ss_vfi, aime_cap ))/float(j)
                               endif
                            
                            lab_income_pretax_ss(j, ia, i_aime, ip, ir, id)  = lab_income_pretax
                            tot_income_ss(j, ia, i_aime, ip, ir, id) =  lab_income_ss(j, ia, i_aime, ip, ir, id) + sv(ia)*((1d0-tk_ss)*n_sr_value(ir)+r_ss_vfi)/gam_ss_vfi + + aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                            tot_income_pretax_ss(j, ia, i_aime, ip, ir, id) = lab_income_pretax_ss(j, ia, i_aime, ip, ir, id) + sv(ia)*(n_sr_value(ir)+r_ss_pretax_vfi)/gam_ss_vfi   +aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                            disposable_ss(j, ia, i_aime, ip, ir, id) =  tot_income_ss(j, ia, i_aime, ip, ir, id) + sv(ia)/gam_ss_vfi + bequest_ss_j_vfi(j) + aime_replacement_rate(i_aime)*b_ss_j_vfi(j)
                            srate_ss(j, ia, i_aime, ip, ir, id) = 1 - (tc_ss_vfi *  c_ss(j, ia, i_aime, ip, ir, id)) / ( tot_income_ss(j, ia, i_aime, ip, ir, id) +  aime_replacement_rate(i_aime)*b_ss_j_vfi(j) +  bequest_ss_j_vfi(j) ) 
                            pi_com = pi_ss_vfi_cond(j)
                            V_ss(j, ia, i_aime, ip, ir, id) = valuefunc(svplus_ss(j, ia, i_aime, ip, ir, id), aime_plus_ss(j, ia, i_aime, ip, ir, id), c_ss(j, ia, i_aime, ip, ir, id), l_ss(j, ia, i_aime, ip, ir, id), j,  ip, ir, id) 
                            
                            if(j == (beq_age + 1) .and. switch_unequal_bequest == 2) then      
                            V_after_beq_ss(:, ia, i_aime, ip, ir, id) = V_ss(j, ia, i_aime, ip, ir, id)
                            endif
                            
                            
                            endif
                        endif
                    enddo
                    
                    
                enddo
            enddo
        enddo
        do i_aime=0, n_aime,1 
            do ip=1, n_sp, 1
                do ir=1, n_sr, 1
                    do id =1, n_sd,1

                            if (j == beq_age .and. switch_unequal_bequest == 2) then
                                
                            call linear_int(aime_plus_ss(max(j-1,1), ia, i_aime, ip, ir, id), iaimel, iaimer, dist, aime(:), n_aime, aime_grow)    
                            EV_prim = 0d0
                            EV_ss(j, ia, i_aime, ip, ir, id)  = 0d0
                            
                            do ip_p=1, n_sp, 1
                                do ir_r=1, n_sr, 1
                                    do id_d=1, n_sd, 1  
                                        do ibeq=1,n_beq,1
                                                                                                                       
                                        c_help =       dist*c_beq_ss(ibeq, ia, iaimel, ip_p, ir_r, id_d) &
                                                +(1d0-dist)*c_beq_ss(ibeq, ia, iaimer, ip_p, ir_r, id_d)
                                        l_help =       dist*l_beq_ss(ibeq, ia, iaimel, ip_p, ir_r, id_d) &
                                                +(1d0-dist)*l_beq_ss(ibeq, ia, iaimer, ip_p, ir_r, id_d)
                                        
                                        if(theta == 1_dp)then
                                            EV_prim = EV_prim + (1d0+r_ss_vfi+(1.0d0-tk_ss)*n_sr_value(ir_r))/gam_ss_vfi*pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id,id_d)*p_beq(ibeq)*1/c_help
                                        else
                                            if(j<jbar_ss_vf)then
                                                EV_prim =  EV_prim + (1d0+r_ss_vfi+(1.0d0-tk_ss)*n_sr_value(ir_r))/gam_ss_vfi*pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id,id_d)*p_beq(ibeq) &
                                                                    *((1-l_help)/c_help)**((1d0-theta)*(1d0-phi))*c_help**(-theta)
                                            else
                                                EV_prim = EV_prim + (1d0+r_ss_vfi+(1.0d0-tk_ss)*n_sr_value(ir_r))/gam_ss_vfi*pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id,id_d)*p_beq(ibeq) &
                                                          *c_help**(phi -theta*phi -1)
                                            endif
                                        endif
                                        
                                                                     
                                        EV_ss(j, ia, i_aime, ip, ir, id)  = EV_ss(j, ia, i_aime, ip, ir, id) + pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id,id_d)*p_beq(ibeq)&
                                                                           *V_beq_ss(ibeq, ia, i_aime, ip_p, ir_r, id_d)
                                        
                            if(theta==1_dp)then
                            RHS_ss(j, ia, i_aime, ip, ir, id)=1d0/((delta+n_sd_value(id)) *pi_ss_vfi_cond(j)*EV_prim)  
                            else
                            RHS_ss(j, ia, i_aime, ip, ir, id)= (delta+n_sd_value(id)) *pi_ss_vfi_cond(j)*EV_prim
                            endif 
                            
                            if (theta == 1) then 
                                EV_ss(j, ia, i_aime, ip, ir, id) = EV_ss(j, ia, i_aime, ip, ir, id)
                            else 
                                EV_ss(j, ia, i_aime, ip, ir, id) = ((1d0-theta)*EV_ss(j, ia, i_aime, ip, ir, id))**(1d0/(1d0-theta))
                            endif                                        
                                        enddo
                                    enddo
                                enddo
                            enddo
                            
                                        
                                        
                            elseif(j == (beq_age+1) .and. switch_unequal_bequest == 2 ) then
                                
                                do ibeq=1,n_beq,1 
                                    
                                call linear_int(aime_plus_beq_ss(ibeq, ia, i_aime, ip, ir, id), iaimel, iaimer, dist, aime(:), n_aime, aime_grow)   
                                
                                
                                EV_prim_after_beq = 0d0
                                EV_after_beq_ss(ibeq, ia, i_aime, ip, ir, id)  = 0d0
                                
                                 do ip_p=1, n_sp, 1
                                    do ir_r=1, n_sr, 1
                                        do id_d=1, n_sd, 1  
                                        
                                        
                                            
                                        c_help =       dist*c_ss(j, ia, iaimel, ip_p, ir_r, id_d) &
                                                +(1d0-dist)*c_ss(j, ia, iaimer, ip_p, ir_r, id_d)
                                        l_help =       dist*l_ss(j, ia, iaimel, ip_p, ir_r, id_d) &
                                                +(1d0-dist)*l_ss(j, ia, iaimer, ip_p, ir_r, id_d)
                                        
                                        if(theta == 1_dp)then
                                            
                                            EV_prim_after_beq = EV_prim_after_beq + (1d0+r_ss_vfi+(1.0d0-tk_ss)*n_sr_value(ir_r))/gam_ss_vfi*pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id,id_d)*1/c_help
                                            
                                        else
                                            
                                            if(j<jbar_ss_vf)then 
                                                EV_prim_after_beq =  EV_prim_after_beq + (1d0+r_ss_vfi+(1.0d0-tk_ss)*n_sr_value(ir_r))/gam_ss_vfi*pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id,id_d)&
                                                                    *((1-l_help)/c_help)**((1d0-theta)*(1d0-phi))*c_help**(-theta)
                                            else
                                                EV_prim_after_beq = EV_prim_after_beq + (1d0+r_ss_vfi+(1.0d0-tk_ss)*n_sr_value(ir_r))/gam_ss_vfi*pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id,id_d)&
                                                          *c_help**(phi -theta*phi -1)
                                            endif
                                        endif
                                        
                                        
                                        if(theta==1_dp)then
                                            RHS_after_beq_ss(ibeq, ia, i_aime, ip, ir, id)=1d0/((delta+n_sd_value(id)) *pi_ss_vfi_cond(j)*EV_prim_after_beq)  
                                        else
                                            RHS_after_beq_ss(ibeq, ia, i_aime, ip, ir, id)= (delta+n_sd_value(id)) *pi_ss_vfi_cond(j)*EV_prim_after_beq
                                        endif 
                            
                                        if (theta == 1) then 
                                            EV_after_beq_ss(j, ia, i_aime, ip, ir, id) = EV_after_beq_ss(ibeq, ia, i_aime, ip, ir, id)
                                        else 
                                            EV_after_beq_ss(ibeq, ia, i_aime, ip, ir, id) = ((1d0-theta)*EV_after_beq_ss(ibeq, ia, i_aime, ip, ir, id))**(1d0/(1d0-theta))
                                        endif
                                        
                                        
                                        
                                                                                                         
                                        EV_after_beq_ss(ibeq, ia, i_aime, ip, ir, id)  = EV_after_beq_ss(ibeq, ia, i_aime, ip, ir, id) + pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id,id_d)&
                                                                           *V_after_beq_ss(ibeq, ia, i_aime, ip_p, ir_r, id_d)
                                        
                                        
                                        
                                        enddo
                                    enddo
                                    enddo
                                    enddo
                                
                            else
                            
                            call linear_int(aime_plus_ss(max(j-1,1), ia, i_aime, ip, ir, id), iaimel, iaimer, dist, aime(:), n_aime, aime_grow)    
                            EV_prim = 0d0
                            EV_ss(j, ia, i_aime, ip, ir, id)  = 0d0
                            
                            
                            do ip_p=1, n_sp, 1
                                do ir_r=1, n_sr, 1
                                    do id_d=1, n_sd, 1  
                                        
                                        
                                            
                                        c_help =       dist*c_ss(j, ia, iaimel, ip_p, ir_r, id_d) &
                                                +(1d0-dist)*c_ss(j, ia, iaimer, ip_p, ir_r, id_d)
                                        l_help =       dist*l_ss(j, ia, iaimel, ip_p, ir_r, id_d) &
                                                +(1d0-dist)*l_ss(j, ia, iaimer, ip_p, ir_r, id_d)
                                                
                                        if(theta == 1_dp)then
                                            EV_prim = EV_prim + (1d0+r_ss_vfi+(1.0d0-tk_ss)*n_sr_value(ir_r))/gam_ss_vfi*pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id,id_d)*1/c_help
                                            
                                        elseif (theta .ne. 1_dp) then
                                            
                                            if(j<jbar_ss_vf)then 
                                                EV_prim =  EV_prim + (1d0+r_ss_vfi+(1.0d0-tk_ss)*n_sr_value(ir_r))/gam_ss_vfi*pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id,id_d)&
                                                                    *((1-l_help)/c_help)**((1d0-theta)*(1d0-phi))*c_help**(-theta)
                                            else
                                                EV_prim = EV_prim + (1d0+r_ss_vfi+(1.0d0-tk_ss)*n_sr_value(ir_r))/gam_ss_vfi*pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id,id_d)&
                                                          *c_help**(phi -theta*phi -1)
                                            endif
                                        endif
                                        
                                                                         
                                        EV_ss(j, ia, i_aime, ip, ir, id)  = EV_ss(j, ia, i_aime, ip, ir, id) + pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id,id_d)&
                                                                           *V_ss(j, ia, i_aime, ip_p, ir_r, id_d)
                                        
                                    enddo
                                enddo
                            enddo
                            
                        if(theta==1_dp)then
                            RHS_ss(j, ia, i_aime, ip, ir, id)=1d0/((delta+n_sd_value(id)) *pi_ss_vfi_cond(j)*EV_prim)  
                        else
                            RHS_ss(j, ia, i_aime, ip, ir, id)= (delta+n_sd_value(id)) *pi_ss_vfi_cond(j)*EV_prim
                        endif 
                    
                        if (theta == 1) then 
                            EV_ss(j, ia, i_aime, ip, ir, id) = EV_ss(j, ia, i_aime, ip, ir, id)
                        else 
                            EV_ss(j, ia, i_aime, ip, ir, id) = ((1d0-theta)*EV_ss(j, ia, i_aime, ip, ir, id))**(1d0/(1d0-theta))
                        endif
                    endif
                            
                        
                    
                    enddo  
                enddo 
            enddo
        enddo
     enddo            
enddo
end subroutine

    
!*******************************************************************************************
!find future assets for every age, assets grid point, state  
!  trans
subroutine household_trans_endo(ij,ii)



implicit none
real*8 :: available, EV_prim, c_opt, w_opt, av, wage, wage_non_tax, foc(3), lab_income, lab_income_pretax, optimal_choice(2), c_help, l_help, dist
real*8 :: EV_prim_after_beq 
integer, intent(in) :: ii, ij
integer ::  j, it,i, k, ik 
integer ::  year_birth, tp
it = year(ii, ij, bigJ) ! if agent has age ij in period ii, he will have bigJ in period it

year_birth = ii - ij + 1  ! get year of birth to assign correct sigma2_epsilon

! shocks are cohort specific
tp = year_birth 

    if (tp < 1) then
    tp = 1
    elseif (tp > bigT) then
        tp = bigT
    endif
    
! later need to move this inside loops

do ia = 0, n_a, 1 
    do i_aime=0, n_aime,1 
        do ip=1, n_sp, 1
            do ir =1, n_sr,1
                do id = 1, n_sd,1
                    c_trans(bigj, ia, i_aime, ip, ir, id, it) = max(((1d0+(1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it) +  aime_replacement_rate(i_aime)*b_j_vfi(bigJ,it) + bequest_j_vfi(bigJ,it))/tc_vfi(it), 1d-10)
                    l_trans(bigj, ia, i_aime, ip, ir, id, it) = 0d0
                    lab_income_trans(bigj, ia, i_aime, ip, ir, id, it) = 0d0
                    bequest_j_trans(bigj, ia, i_aime, ip, ir, id, it) = bequest_j_vfi(bigJ,it)
                    lab_income_pretax_trans(bigj, ia, i_aime, ip, ir, id, it) = 0d0
                    tot_income_pretax_trans(bigj, ia, i_aime, ip, ir, id, it) = lab_income_pretax_trans(bigj, ia, i_aime, ip, ir, id, it) + (n_sr_value(ir)+r_vfi_pretax(it))*sv(ia)/gam_vfi(it)   +  aime_replacement_rate(i_aime)*b_j_vfi(bigJ,it)
                    tot_income_trans(bigj, ia, i_aime, ip, ir, id, it) = lab_income_trans(bigj, ia, i_aime, ip, ir, id, it) + ((1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it)

                    svplus_trans(bigj, ia, i_aime, ip, ir, id, it)=0d0
                    aime_plus_trans(bigJ, ia, i_aime, ip, ir, id, it) = aime(i_aime)

                    V_trans(bigj, ia, i_aime, ip, ir, id, it) = valuefunc_trans(0d0, aime(i_aime), c_trans(bigj, ia, i_aime, ip, ir, id, it),l_trans(bigJ,ia, i_aime, ip, ir, id,it), bigJ, ip, ir, id, it)
                enddo
            enddo
        enddo
    enddo
enddo

do ia=0, n_a, 1 
    do i_aime=0, n_aime,1 
        do ip = 1, n_sp, 1
             do ir =1, n_sr, 1
                do id = 1, n_sd, 1    
                    EV_prim = 0d0
                    EV_trans(bigj, ia, i_aime, ip, ir, id, it) =0d0
                    
                    do ir_r=1, n_sr, 1
                        do id_d=1, n_sd, 1
                            do ip_p=1,n_sp, 1
                                if(theta==1_dp)then
                                    EV_prim = EV_prim + (1d0+r_vfi(it)+(1-tk(it))*n_sr_value(ir_r))/gam_vfi(it)*pi_ip_trans(ip, ip_p, tp)*pi_ir(ir, ir_r)*pi_id(id,id_d)/c_trans(bigj, ia, i_aime, ip_p, ir_r, id_d, it)    
                                else
                                    EV_prim = EV_prim + (1d0+r_vfi(it)+(1-tk(it))*n_sr_value(ir_r))/gam_vfi(it)*pi_ip_trans(ip, ip_p, tp)*pi_ir(ir, ir_r)*pi_id(id,id_d)*c_trans(bigj, ia, i_aime, ip_p, ir_r, id_d, it)**(phi -theta*phi -1)   
                                endif 
                                EV_trans(bigj, ia, i_aime, ip, ir, id, it) = EV_trans(bigj, ia, i_aime, ip, ir, id, it) + pi_ip_trans(ip, ip_p, tp)*pi_ir(ir,ir_r)*pi_id(id, id_d)*V_trans(bigj, ia, i_aime, ip_p, ir_r, id_d, it)
                            enddo
                        enddo
                    enddo
                    if(theta==1_dp)then
                        RHS_trans(bigj, ia, i_aime, ip, ir, id, it)=1d0/(tc_vfi(max(it-1,1))/tc_vfi(it)*(delta+n_sd_value(id)) *pi_trans_vfi_cond(bigJ,it)*EV_prim)  
                    else
                        RHS_trans(bigj, ia, i_aime, ip, ir, id, it)= tc_vfi(max(it-1,1))/tc_vfi(it)*(delta+n_sd_value(id)) *pi_trans_vfi_cond(bigJ,it)*EV_prim
                    endif 
                
                    if (theta == 1) then 
                        EV_trans(bigj, ia, i_aime, ip, ir, id, it) = EV_trans(bigj, ia, i_aime, ip, ir, id, it)
                    else 
                        EV_trans(bigj, ia, i_aime, ip, ir, id, it) = ((1d0-theta)*EV_trans(bigj, ia, i_aime, ip, ir, id, it))**(1d0/(1d0-theta))
                    endif
                enddo
            enddo
        enddo
    enddo
enddo



do j = bigJ-1, ij, -1
    it = year(ii,ij,j)
    i = it
    if(i < jbar_t_vfi(it) .and. ((i .ne. beq_age) .or. (switch_unequal_bequest .ne. 2)))then
            poss_ass_sum_ss(j) = (1-tl(it))*(w_pom_trans_vfi(j,it)*omega(j,it)*n_sp_value_trans(1,tp))**(1-lambda_trans(it))+bequest_j_vfi(j,it) + w_pom_trans_implicit_vfi(j, it)*omega(j,it)*n_sp_value_trans(1,tp) 
        elseif (j == beq_age .and. switch_unequal_bequest == 2) then
            poss_ass_sum_ss(j) = (1-tl(it))*(w_pom_trans_vfi(j,it)*omega(j,it)*n_sp_value_trans(1,tp))**(1-lambda_trans(it))+beq_zipf_trans(1,it) + w_pom_trans_implicit_vfi(j, it)*omega(j,it)*n_sp_value_trans(1,tp) 
        else
        poss_ass_sum_ss(j) =aime_replacement_rate(n_aime)*b_j_vfi(j,it)+bequest_j_vfi(j,it)
    endif
    do k= j+1, bigJ, 1
        ik = year(ii, j, k)
        ! to do 
         if(k < jbar_t_vfi(ik) .and. ((i .ne. beq_age) .or. (switch_unequal_bequest .ne. 2)))then
            poss_ass_sum_ss(j) = poss_ass_sum_ss(j) +  w_pom_trans_implicit_vfi(k, ik)*omega(k,it)*n_sp_value_trans(1,tp) + ((1-tl(ik))*(w_pom_trans_vfi(k,ik)*omega(k,it)*n_sp_value_trans(1,tp))**(1-lambda_trans(ik))+bequest_j_vfi(k,ik))/product(1d0+r_vfi(it+1:ik)+(1.0d0-tk(it+1:ik))*n_sr_value(1))*product(gam_vfi(it+1:ik)) 
        elseif (k == beq_age .and. switch_unequal_bequest == 2) then
            poss_ass_sum_ss(j) = poss_ass_sum_ss(j) +  w_pom_trans_implicit_vfi(k, ik)*omega(k,it)*n_sp_value_trans(1,tp) + ((1-tl(ik))*(w_pom_trans_vfi(k,ik)*omega(k,it)*n_sp_value_trans(1,tp))**(1-lambda_trans(ik))+beq_zipf_trans(1,ik))/product(1d0+r_vfi(it+1:ik)+(1.0d0-tk(it+1:ik))*n_sr_value(1))*product(gam_vfi(it+1:ik)) 
        else
            poss_ass_sum_ss(j) = poss_ass_sum_ss(j) + ( aime_replacement_rate(n_aime)*b_j_vfi(k,ik)+bequest_j_vfi(k,ik))/product(1d0+r_vfi(it+1:ik)+(1.0d0-tk(it+1:ik))*n_sr_value(1))*product(gam_vfi(it+1:ik))
        endif
    enddo
    
    do ia=0, n_a, 1
        do i_aime=0, n_aime,1 
            do ip=1, n_sp,1
                do ir=1, n_sr, 1
                    do id = 1, n_sd, 1
                        
                       
                        if(((1d0+(1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it) + poss_ass_sum_ss(j)  <a_l)) then    ! is this (linr 450) boundary condition right - will it do neccesary steps ? 
                                c_trans(j, ia, i_aime, ip, ir, id, it) = 1d-10 
                                
                                if((j < jbar_t_vfi(it)) .and. (j == beq_age) .and. (switch_unequal_bequest == 2)) then
                                
                                    do ibeq = 1,n_beq,1
                                        
                                    sv_tempo(j, ia, i_aime, ip, ir, id) = 0.0d0
                                    
                                

                                
                                    l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = 1d0 
                                     if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                    lab_income = (1-tL(it))*(n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, it)/LabIncAVG_vfi(it))**(1-lambda_trans(it))*LabIncAVG_vfi(it) + &
                                                 + w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(1,tp)
                                    lab_income_pretax = n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, it) +  w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(1,tp)                                        
                                    else
                                    lab_income = (1-tL(it))*(omega(j,it)*n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, it)/LabIncAVG_vfi(it))**(1-lambda_trans(it))*LabIncAVG_vfi(it) + &
                                                 + w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(1,tp)
                                    lab_income_pretax = omega(j,it)*n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, it) +  w_pom_trans_implicit_vfi(j, it)*omega(j,it)*n_sp_value_trans(1,tp)                                        
                                    endif
                                    

                                    lab_income_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = lab_income
                                    lab_income_pretax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = lab_income_pretax
                                    tot_income_pretax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = lab_income_pretax + (n_sr_value(ir)+r_vfi_pretax(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it) + beq_zipf_trans(ibeq,it)
                                    tot_income_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = lab_income  + ((1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it)+ aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                    c_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = 1d-10 
                                    sv_tempo_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = (tc_vfi(it)*c_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)+sv(ia) -lab_income- aime_replacement_rate(i_aime)*b_j_vfi(j,it) -beq_zipf_trans(ibeq,it))/((1d0+(1d0-tk(it))*n_sr_value(ir)+r_vfi(it))/gam_vfi(it))
                                    l_trans(j, ia, i_aime, ip, ir, id, it) = p_beq_trans(ibeq,it) *  l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + l_trans(j, ia, i_aime, ip, ir, id, it)
                                    lab_income_trans(j, ia, i_aime, ip, ir, id, it) = p_beq_trans(ibeq,it) * lab_income_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + lab_income_trans(j, ia, i_aime, ip, ir, id, it) 
                                    lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = p_beq_trans(ibeq,it) * lab_income_pretax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it)
                                    tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = p_beq_trans(ibeq,it) * tot_income_pretax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) 
                                    tot_income_trans(j, ia, i_aime, ip, ir, id, it)        = p_beq_trans(ibeq,it) * tot_income_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + tot_income_trans(j, ia, i_aime, ip, ir, id, it)
                                    
                                    sv_tempo_trans(j, ia, i_aime, ip, ir, id, it) = p_beq_trans(ibeq,it) * sv_tempo_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + sv_tempo_trans(j, ia, i_aime, ip, ir, id, it)
                                    enddo
                                    
                                elseif(((j .ne. beq_age) .or. (switch_unequal_bequest .ne. 2))) then
                                    
                                if(j < jbar_t_vfi(it))then  
                                    l_trans(j, ia, i_aime, ip, ir, id, it) = 1d0 
                                    
                                     if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                        lab_income = (1-tL(it))*(n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, it)/LabIncAVG_vfi(it))**(1-lambda_trans(it))*LabIncAVG_vfi(it) + &
                                                     + w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(1,tp)
                                        lab_income_pretax = n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, it) +  w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(1,tp)
                                    else
                                        lab_income = (1-tL(it))*(omega(j,it)*n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, it)/LabIncAVG_vfi(it))**(1-lambda_trans(it))*LabIncAVG_vfi(it) + &
                                                     + w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(1,tp)
                                        lab_income_pretax = omega(j,it)*n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, it) +  w_pom_trans_implicit_vfi(j, it)*omega(j,it)*n_sp_value_trans(1,tp)

                                    endif
                                    
                    
                                    lab_income_trans(j, ia, i_aime, ip, ir, id, it) = lab_income
                                    bequest_j_trans(j, ia, i_aime, ip, ir, id, it) = bequest_j_vfi(j,it)
                                    lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax
                                    tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax + (n_sr_value(ir)+r_vfi_pretax(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                    tot_income_trans(j, ia, i_aime, ip, ir, id, it) = lab_income  + ((1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)

                                
                                else
                                    l_trans(j,ia, i_aime, ip, ir, id, it) = 0d0
                                    lab_income = 0d0
                                    lab_income_pretax = 0d0
                                    lab_income_trans(j, ia, i_aime, ip, ir, id, it) = lab_income
                                    bequest_j_trans(j, ia, i_aime, ip, ir, id, it) = bequest_j_vfi(j,it)
                                    lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax
                                    tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax + (n_sr_value(ir)+r_vfi_pretax(it))*sv(ia)/gam_vfi(it) +   aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                    tot_income_trans(j, ia, i_aime, ip, ir, id, it) = lab_income  + ((1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                endif
                                sv_tempo_trans(j, ia, i_aime, ip, ir, id, it) = (tc_vfi(it)*c_trans(j, ia, i_aime, ip, ir, id, it)+sv(ia) -lab_income- aime_replacement_rate(i_aime)*b_j_vfi(j,it) - bequest_j_vfi(j,it))/((1d0+(1d0-tk(it))*n_sr_value(ir)+r_vfi(it))/gam_vfi(it))
                                endif
                                
                        
                        else 
                             if(theta ==1)then
                                
                                

                                if(j>=jbar_t_vfi(it)) then
                                    c_trans(j, ia, i_aime, ip, ir, id, it) = max(RHS_trans(j+1, ia, i_aime, ip, ir, id, year(ii,ij,j+1)),1d-10)
                                    l_trans(j, ia, i_aime, ip, ir, id, it)=0d0
                                    lab_income = 0d0
                                    labor_tax_trans(j, ia, i_aime, ip, ir, id, it) = 0d0
                                    lab_income_pretax = 0d0
                                    lab_income_trans(j, ia, i_aime, ip, ir, id, it) = lab_income
                                    bequest_j_trans(j, ia, i_aime, ip, ir, id, it) = bequest_j_vfi(j,it)
                                    lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax
                                    tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax + (n_sr_value(ir)+r_vfi_pretax(it))*sv(ia)/gam_vfi(it) +    aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                    tot_income_trans(j, ia, i_aime, ip, ir, id, it) = lab_income  + ((1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                    
                                else
                                    if  (j == beq_age .and. switch_unequal_bequest == 2) then
                                        
                                    sv_tempo_trans(j, ia, i_aime, ip, ir, id, it) = 0.0d0   
                                    
                                    do ibeq = 1,n_beq
                                    c_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = max(RHS_after_beq_trans(ibeq, ia, i_aime, ip, ir, id, year(ii,ij,j+1)),1d-10)
                                    c_opt = tc_vfi(it)*c_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) 
                                    
                                     if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                        w_opt = n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, it) 
                                        wage_non_tax =  w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(ip,tp)
                                        l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = optimal_labor(c_opt, w_opt, wage_non_tax, phi, tL(it), lambda_trans(it),LabIncAVG_vfi(it),tc_vfi(it))
                                        lab_income = (1-tL(it))*(w_opt*l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)/LabIncAVG_vfi(it))**(1-lambda_trans(it)) *LabIncAVG_vfi(it)+ &
                                                     w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(ip,tp)*l_trans(j, ia, i_aime, ip, ir, id, it)
                                        lab_income_pretax = w_opt*l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) +  w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(ip,tp)*l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)
                                        
                                    else
                                        w_opt = omega(j,it)*n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, it) 
                                        wage_non_tax =  w_pom_trans_implicit_vfi(j, it)*omega(j,it)*n_sp_value_trans(ip,tp)
                                        l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = optimal_labor(c_opt, w_opt, wage_non_tax, phi, tL(it), lambda_trans(it),LabIncAVG_vfi(it),tc_vfi(it))
                                        lab_income = (1-tL(it))*(w_opt*l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)/LabIncAVG_vfi(it))**(1-lambda_trans(it)) *LabIncAVG_vfi(it)+ &
                                                     w_pom_trans_implicit_vfi(j, it)*omega(j,it)*n_sp_value_trans(ip,tp)*l_trans(j, ia, i_aime, ip, ir, id, it)
                                        lab_income_pretax = w_opt*l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) +  w_pom_trans_implicit_vfi(j, it)*omega(j,it)*n_sp_value_trans(ip,tp)*l_beq_trans(ibeq, ia, i_aime, ip, ir, id,it)   
                                    endif
                                    
                                                                       
                                    lab_income_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = lab_income
                                    lab_income_pretax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = lab_income_pretax
                                    tot_income_pretax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = lab_income_pretax + (n_sr_value(ir)+r_vfi_pretax(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                    tot_income_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = lab_income  + ((1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                    sv_tempo_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = (tc_vfi(it)*c_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)+sv(ia) -lab_income- aime_replacement_rate(i_aime)*b_j_vfi(j,it) -beq_zipf_trans(ibeq,it))/((1d0+(1d0-tk(it))*n_sr_value(ir)+r_vfi(it))/gam_vfi(it))
                                    l_trans(j, ia, i_aime, ip, ir, id, it) = p_beq_trans(ibeq,it) *  l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + l_trans(j, ia, i_aime, ip, ir, id, it)
                                    lab_income_trans(j, ia, i_aime, ip, ir, id, it) = p_beq_trans(ibeq,it) * lab_income_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + lab_income_trans(j, ia, i_aime, ip, ir, id, it) 
                                    lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = p_beq_trans(ibeq,it) * lab_income_pretax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it)
                                    tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = p_beq_trans(ibeq,it) * tot_income_pretax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) 
                                    tot_income_trans(j, ia, i_aime, ip, ir, id, it)        = p_beq_trans(ibeq,it) * tot_income_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + tot_income_trans(j, ia, i_aime, ip, ir, id, it)
                                    
                                    sv_tempo_trans(j, ia, i_aime, ip, ir, id, it) = p_beq_trans(ibeq,it) * sv_tempo_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + sv_tempo_trans(j, ia, i_aime, ip, ir, id, it) 
                                    
                                    enddo
                                    
                                    
                                    else
                                        
                                    c_trans(j, ia, i_aime, ip, ir, id, it) = max(RHS_trans(j+1, ia, i_aime, ip, ir, id, year(ii,ij,j+1)),1d-10)
                                    c_opt = tc_vfi(it)*c_trans(j, ia, i_aime, ip, ir, id, it) 
                                    
                                     if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                    w_opt = n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, it) 
                                    wage_non_tax =  w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(ip,tp)
                                    l_trans(j, ia, i_aime, ip, ir, id, it) = optimal_labor(c_opt, w_opt, wage_non_tax, phi, tL(it), lambda_trans(it),LabIncAVG_vfi(it),tc_vfi(it))
                                    lab_income = (1-tL(it))*(w_opt*l_trans(j, ia, i_aime, ip, ir, id, it)/LabIncAVG_vfi(it))**(1-lambda_trans(it)) *LabIncAVG_vfi(it)+ &
                                                 w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(ip,tp)*l_trans(j, ia, i_aime, ip, ir, id, it)
                                    lab_income_pretax = w_opt*l_trans(j, ia, i_aime, ip, ir, id, it) +  w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(ip,tp)*l_trans(j, ia, i_aime, ip, ir, id, it)
                                       
                                    else
                                     w_opt = omega(j,it)*n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, it) 
                                    wage_non_tax =  w_pom_trans_implicit_vfi(j, it)*omega(j,it)*n_sp_value_trans(ip,tp)
                                    l_trans(j, ia, i_aime, ip, ir, id, it) = optimal_labor(c_opt, w_opt, wage_non_tax, phi, tL(it), lambda_trans(it),LabIncAVG_vfi(it),tc_vfi(it))
                                    lab_income = (1-tL(it))*(w_opt*l_trans(j, ia, i_aime, ip, ir, id, it)/LabIncAVG_vfi(it))**(1-lambda_trans(it)) *LabIncAVG_vfi(it)+ &
                                                 w_pom_trans_implicit_vfi(j, it)*omega(j,it)*n_sp_value_trans(ip,tp)*l_trans(j, ia, i_aime, ip, ir, id, it)
                                    lab_income_pretax = w_opt*l_trans(j, ia, i_aime, ip, ir, id, it) +  w_pom_trans_implicit_vfi(j, it)*omega(j,it)*n_sp_value_trans(ip,tp)*l_trans(j, ia, i_aime, ip, ir, id, it)
                                       
                                    endif
                                    
                                        
                                    lab_income_trans(j, ia, i_aime, ip, ir, id, it) = lab_income
                                    bequest_j_trans(j, ia, i_aime, ip, ir, id, it) = bequest_j_vfi(j,it)
                                    lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax
                                    tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax + (n_sr_value(ir)+r_vfi_pretax(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                    tot_income_trans(j, ia, i_aime, ip, ir, id, it) = lab_income  + ((1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                    sv_tempo_trans(j, ia, i_aime, ip, ir, id, it) = (tc_vfi(it)*c_trans(j, ia, i_aime, ip, ir, id, it)+sv(ia)&
                                                                            -lab_income- aime_replacement_rate(i_aime)*b_j_vfi(j,it)&
                                                                            - bequest_j_vfi(j,it))/((1d0+(1d0-tk(it))*n_sr_value(ir)+r_vfi(it))/gam_vfi(it))
                                    endif
                                endif
                                
                            else    
                                 
                                if(j>=jbar_t_vfi(it)) then   
                                    
                                    l_trans(j, ia, i_aime, ip, ir, id, it) = 0d0
                                    labor_tax_trans(j, ia, i_aime, ip, ir, id, it) = 0d0
                                    
                                    lab_income = 0d0
                                    lab_income_pretax = 0d0
                                    lab_income_trans(j, ia, i_aime, ip, ir, id, it) = lab_income
                                    bequest_j_trans(j, ia, i_aime, ip, ir, id, it) = bequest_j_vfi(j,it)
                                    lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax
                                    tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax + (n_sr_value(ir)+r_vfi_pretax(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                    tot_income_trans(j, ia, i_aime, ip, ir, id, it) = lab_income  + ((1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                    
                                    
                                    c_trans(j, ia, i_aime, ip, ir, id, it) = max(RHS_trans(j+1, ia, i_aime, ip, ir, id, year(ii,ij,j+1))**(1d0/(phi -theta*phi -1)),1d-15)

                                    sv_tempo_trans(j, ia, i_aime, ip, ir, id, it) = (tc_vfi(it)*c_trans(j, ia, i_aime, ip, ir, id, it)+sv(ia)&
                                                                            -lab_income- aime_replacement_rate(i_aime)*b_j_vfi(j,it)&
                                                                            - bequest_j_vfi(j,it))/((1d0+(1d0-tk(it))*n_sr_value(ir)+r_vfi(it))/gam_vfi(it))                  
                                    
                                else
                                    
                                    if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                    w_opt = n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, it) 
                                    wage_non_tax = w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(ip,tp)
                                    else
                                    w_opt = n_sp_value_trans(ip,tp)*omega(j,it)*w_pom_trans_vfi(j, it) 
                                    wage_non_tax = w_pom_trans_implicit_vfi(j, it)*omega(j,it)*n_sp_value_trans(ip,tp)                                        
                                    endif
                                    
                                    
                                    if (j == beq_age .and. switch_unequal_bequest == 2) then
                                        
                                    sv_tempo_trans(j, ia, i_aime, ip, ir, id, it) = 0.0d0   
                                    
                                    do ibeq = 1,n_beq
                                        
                                    if ((switch_discount_risk .ne. 2) .or. (id .ne. n_sd)) then
                                       optimal_choice = optimal_consumption_and_labor_new(RHS_after_beq_trans(ibeq, ia, i_aime, ip, ir, id, year(ii,ij,j+1)), phi, theta, tl(it), lambda_trans(it), w_opt, wage_non_tax, tc_vfi(it), LabIncAVG_vfi(it) )
                                    c_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)  = optimal_choice(1)
                                    l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)  = optimal_choice(2)
                                    endif
                                    
                                    
                                     if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                        lab_income = (1-tL(it))*(w_opt*l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)/LabIncAVG_vfi(it))**(1-lambda_trans(it)) *LabIncAVG_vfi(it)+ &
                                                     w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(ip,tp)*l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)
                                        lab_income_pretax = w_opt*l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) +  w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(ip,tp)*l_beq_trans(ibeq, ia, i_aime, ip, ir, id,it)
                                    else
                                        lab_income = (1-tL(it))*(w_opt*l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)/LabIncAVG_vfi(it))**(1-lambda_trans(it)) *LabIncAVG_vfi(it)+ &
                                                     w_pom_trans_implicit_vfi(j, it)*omega(j,it)*n_sp_value_trans(ip,tp)*l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)
                                        lab_income_pretax = w_opt*l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) +  w_pom_trans_implicit_vfi(j, it)*omega(j,it)*n_sp_value_trans(ip,tp)*l_beq_trans(ibeq, ia, i_aime, ip, ir, id,it)
                                        
                                    endif
                                    
                                    lab_income_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = lab_income
                                    lab_income_pretax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = lab_income_pretax
                                    tot_income_pretax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = lab_income_pretax + (n_sr_value(ir)+r_vfi_pretax(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                    tot_income_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = lab_income  + ((1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)    
                                    
                                    sv_tempo_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = (tc_vfi(it)*c_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)+sv(ia) -lab_income- aime_replacement_rate(i_aime)*b_j_vfi(j,it) -beq_zipf_trans(ibeq,it))/((1d0+(1d0-tk(it))*n_sr_value(ir)+r_vfi(it))/gam_vfi(it))
                                    l_trans(j, ia, i_aime, ip, ir, id, it) = p_beq_trans(ibeq,it) *  l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + l_trans(j, ia, i_aime, ip, ir, id, it)
                                    lab_income_trans(j, ia, i_aime, ip, ir, id, it) = p_beq_trans(ibeq,it) * lab_income_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + lab_income_trans(j, ia, i_aime, ip, ir, id, it) 
                                    lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = p_beq_trans(ibeq,it) * lab_income_pretax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it)
                                    tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = p_beq_trans(ibeq,it) * tot_income_pretax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) 
                                    tot_income_trans(j, ia, i_aime, ip, ir, id, it)        = p_beq_trans(ibeq,it) * tot_income_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + tot_income_trans(j, ia, i_aime, ip, ir, id, it)
                                    
                                    sv_tempo_trans(j, ia, i_aime, ip, ir, id, it) = p_beq_trans(ibeq,it) * sv_tempo_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + sv_tempo_trans(j, ia, i_aime, ip, ir, id, it) 
                                    
                                    enddo     
                                        
                                    else
                                        
                                        

                                    if ((switch_discount_risk .ne. 2) .or. (id .ne. n_sd)) then
                                    optimal_choice = optimal_consumption_and_labor_new(RHS_trans(j+1, ia, i_aime, ip, ir, id, year(ii,ij,j+1)), phi, theta, tl(it), lambda_trans(it), w_opt, wage_non_tax, tc_vfi(it), LabIncAVG_vfi(it) )
                                    c_trans(j, ia, i_aime, ip, ir, id, it)  = optimal_choice(1)
                                    l_trans(j, ia, i_aime, ip, ir, id, it)  = optimal_choice(2)
                                    endif
                                    
                                     if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                        lab_income = (1-tL(it))*(w_opt/LabIncAVG_vfi(it)*l_trans(j, ia, i_aime, ip, ir, id, it))**(1-lambda_trans(it))*LabIncAVG_vfi(it)+ &
                                                     w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(ip,tp)*l_trans(j, ia, i_aime, ip, ir, id, it)
                                        lab_income_pretax = w_opt*l_trans(j, ia, i_aime, ip, ir, id, it) + w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(ip,tp)*l_trans(j, ia, i_aime, ip, ir, id, it)
                                   
                                    else
                                        lab_income = (1-tL(it))*(w_opt/LabIncAVG_vfi(it)*l_trans(j, ia, i_aime, ip, ir, id, it))**(1-lambda_trans(it))*LabIncAVG_vfi(it)+ &
                                                     w_pom_trans_implicit_vfi(j, it)*omega(j,it)*n_sp_value_trans(ip,tp)*l_trans(j, ia, i_aime, ip, ir, id, it)
                                        lab_income_pretax = w_opt*l_trans(j, ia, i_aime, ip, ir, id, it) + w_pom_trans_implicit_vfi(j, it)*omega(j,it)*n_sp_value_trans(ip,tp)*l_trans(j, ia, i_aime, ip, ir, id, it)
                                       
                                    endif
                                    
                                     labor_tax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax -lab_income 
                                    lab_income_trans(j, ia, i_aime, ip, ir, id, it) = lab_income
                                    bequest_j_trans(j, ia, i_aime, ip, ir, id, it) = bequest_j_vfi(j,it)
                                    lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax
                                    tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax + (n_sr_value(ir)+r_vfi_pretax(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                    tot_income_trans(j, ia, i_aime, ip, ir, id, it) = lab_income  + ((1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it)+ aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                    sv_tempo_trans(j, ia, i_aime, ip, ir, id, it) = (tc_vfi(it)*c_trans(j, ia, i_aime, ip, ir, id, it)+sv(ia)&
                                                                            -lab_income- aime_replacement_rate(i_aime)*b_j_vfi(j,it)&
                                                                            - bequest_j_vfi(j,it))/((1d0+(1d0-tk(it))*n_sr_value(ir)+r_vfi(it))/gam_vfi(it))                            
                                    endif
                                    
                                endif
                            endif
                            

                            if ((it == 2) .and. (j > 1) .and. (j<jbar_t_vfi(it))) then 
                                sv_tempo_trans(j, ia, i_aime, ip, ir, id, it) = sv_tempo_trans(j, ia, i_aime, ip, ir, id, it) - transfer_pfi(j-1)
                            endif
                            endif
                    enddo
                enddo
            enddo
        enddo
    enddo
    
    do i_aime=0, n_aime, 1
        do ip=1, n_sp, 1
            do ir=1, n_sr, 1
                do id = 1, n_sd, 1
                    if ((switch_discount_risk .ne. 2) .or. (id .ne. n_sd)) then
                        
                         if (j == beq_age .and. switch_unequal_bequest == 2) then 
                         svplus_trans(j, :, i_aime, ip, ir, id, it) = 0.0d0
                            do ibeq = 1, n_beq
                            call change_grid_piecewise_lin_spline(sv_tempo_beq_trans(ibeq,:, i_aime, ip, ir, id,it), sv,   sv, svplus_beq_trans(ibeq,:, i_aime, ip,ir, id,it))

                            enddo
                         else
                             
                             
                         call change_grid_piecewise_lin_spline(sv_tempo_trans(j, :, i_aime, ip, ir, id, it), sv, sv, svplus_trans(j, :, i_aime, ip, ir, id, it))
                         endif
                         
                    else    
                       svplus_trans(j, :, i_aime, ip, ir, id, it) = 0.0d0
                    endif
                enddo
            enddo
        enddo 
    enddo
     do ia=0, n_a, 1 
        do i_aime=0, n_aime,1 
            do ip=1, n_sp, 1
                do ir=1, n_sr, 1
                    do id =1, n_sd, 1
                        
                        
                        ! this segment seems redundant
                        if(j>=jbar_t_vfi(it)) then
                            if(svplus_trans(j, ia, i_aime, ip, ir, id, it)<a_l)then
                                svplus_trans(j, ia, i_aime, ip, ir, id, it) = a_l
                            endif
                            if ((it == 2) .and. (j > 1) .and. (j<jbar_t_vfi(it))) then 
                                available = (1d0+(1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*(sv(ia)+transfer_pfi(j-1))/gam_vfi(it) +  aime_replacement_rate(i_aime)*b_j_vfi(j,it)+ bequest_j_vfi(j,it)
                            else    
                                available = (1d0+(1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it) +  aime_replacement_rate(i_aime)*b_j_vfi(j,it)+ bequest_j_vfi(j,it)
                            endif
                            l_trans(j, ia, i_aime, ip, ir, id, it)=0d0
                            c_trans(j, ia, i_aime, ip, ir, id, it) = max( (available - svplus_trans(j, ia, i_aime, ip, ir, id, it))/tc_vfi(it), 1e-10)
                             labor_tax_trans(j, ia, i_aime, ip, ir, id, it) = 0d0
                            
                            labor_tax_trans(j, ia, i_aime, ip, ir, id, it) = 0d0
                            aime_plus_trans(j, ia, i_aime, ip, ir, id, it) = aime(i_aime)
                            bequest_j_trans(j, ia, i_aime, ip, ir, id, it) = bequest_j_vfi(j,it)
                            lab_income = 0
                            lab_income_pretax = 0
                            lab_income_trans(j, ia, i_aime, ip, ir, id, it) = lab_income
                            lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax
                            tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax + (n_sr_value(ir)+r_vfi_pretax(it))*sv(ia)/gam_vfi(it) +    aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                            tot_income_trans(j, ia, i_aime, ip, ir, id, it) = lab_income  + ((1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                            
                            
                        else
                            if(svplus_trans(j, ia, i_aime, ip, ir, id, it)<a_l)then
                                svplus_trans(j, ia, i_aime, ip, ir, id, it) = a_l
                            endif  
                            
                             if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                            wage = w_pom_trans_vfi(j,it)*n_sp_value_trans(ip,tp)
                            wage_non_tax = w_pom_trans_implicit_vfi(j, it)*n_sp_value_trans(ip,tp)
                                
                            else
                            wage = w_pom_trans_vfi(j,it)*omega(j,it)*n_sp_value_trans(ip,tp)
                            wage_non_tax = w_pom_trans_implicit_vfi(j, it)*omega(j,it)*n_sp_value_trans(ip,tp)
                                
                            endif
                            
                            tl_com = tl(it)
                            lambda_com = lambda_trans(it)
                            
                            if(j == beq_age .and. switch_unequal_bequest == 2) then    
                                
                                c_trans(j, ia, i_aime, ip, ir, id, it)  = 0.0d0
                                l_trans(j, ia, i_aime, ip, ir, id, it)  = 0.0d0
                                labor_tax_trans(j, ia, i_aime, ip, ir, id, it) = 0.0d0
                                lab_income_trans(j, ia, i_aime, ip, ir, id, it) = 0.0d0
                                lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = 0.0d0
                                aime_plus_trans(j, ia, i_aime, ip, ir, id, it) = 0.0d0
                                tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = 0.0d0
                                tot_income_trans(j, ia, i_aime, ip, ir, id, it) = 0.0d0
                                svplus_trans(j, ia, i_aime, ip, ir, id, it)  = 0.0d0
                                do ibeq = 1, n_beq, 1
                                    
                                if(svplus_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)<a_l)then
                                    svplus_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = a_l
                                
                                endif   
                                
                                av = (1d0+(1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it) - svplus_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + beq_zipf_trans(ibeq, it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)    
                                
                                if (switch_fix_labor == 0) then 
                                    foc = foc_intratemp(av, wage, wage_non_tax,  tc_vfi(it), l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it), LabIncAVG_vfi(it))
                                else
                                    foc = foc_intratemp(av, wage, wage_non_tax,  tc_vfi(it), switch_fix_labor, LabIncAVG_vfi(it))
                                endif                                
                                c_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)  = foc(1) 
                                l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)  = foc(2)  
                                labor_tax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = foc(3)
                                
                                lab_income = (1-tL(it))*(wage*l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)/LabIncAVG_vfi(it))**(1-lambda_trans(it)) *LabIncAVG_vfi(it)+ &
                                wage_non_tax*l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)
                                lab_income_pretax =  wage*l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) +  wage_non_tax*l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)
                                lab_income_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = lab_income
                                lab_income_pretax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = lab_income_pretax
                                aime_plus_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = (float(j-1)*aime(i_aime)+min(wage*l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)/LabIncAVG_vfi(it), aime_cap))/float(j)
                                tot_income_pretax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = lab_income_pretax + (n_sr_value(ir)+r_vfi_pretax(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                tot_income_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = lab_income  + ((1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                
                                pi_com = pi_trans_vfi_cond(j, it)
                                V_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = valuefunc_trans(svplus_beq_trans(ibeq, ia, i_aime, ip, ir, id, it), aime_plus_beq_trans(ibeq, ia, i_aime, ip, ir, id, it), &
                                                                                 c_beq_trans(ibeq, ia, i_aime, ip, ir, id, it), l_beq_trans(ibeq,ia, i_aime, ip, ir, id,it), j, ip, ir, id, it)
                              svplus_trans(j, ia, i_aime, ip, ir, id, it) = p_beq_trans(ibeq,it) * svplus_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + svplus_trans(j, ia, i_aime, ip, ir, id, it)   
                              c_trans(j, ia, i_aime, ip, ir, id, it)  = p_beq_trans(ibeq,it) *  c_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + c_trans(j, ia, i_aime, ip, ir, id, it)
                             l_trans(j, ia, i_aime, ip, ir, id, it)  = p_beq_trans(ibeq,it) *  l_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + l_trans(j, ia, i_aime, ip, ir, id, it)
                            labor_tax_trans(j, ia, i_aime, ip, ir, id, it)  = p_beq_trans(ibeq,it) *  labor_tax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + labor_tax_trans(j, ia, i_aime, ip, ir, id, it)
                            lab_income_trans(j, ia, i_aime, ip, ir, id, it)  = p_beq_trans(ibeq,it) *  lab_income_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + lab_income_trans(j, ia, i_aime, ip, ir, id, it)
                            lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it)  = p_beq_trans(ibeq,it) *  lab_income_pretax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it)
                            aime_plus_trans(j, ia, i_aime, ip, ir, id, it)  = p_beq_trans(ibeq,it) *  aime_plus_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + aime_plus_trans(j, ia, i_aime, ip, ir, id, it)
                            tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it)  = p_beq_trans(ibeq,it) *  tot_income_pretax_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it)      
                            tot_income_trans(j, ia, i_aime, ip, ir, id, it)  = p_beq_trans(ibeq,it) *  tot_income_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + tot_income_trans(j, ia, i_aime, ip, ir, id, it)                         
                            enddo
                            else
                                if(svplus_trans(j, ia, i_aime, ip, ir, id, it)<a_l)then
                                    svplus_trans(j, ia, i_aime, ip, ir, id, it) = a_l
                                endif    
                                av = (1d0+(1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it) - svplus_trans(j, ia, i_aime, ip, ir, id, it) + bequest_j_vfi(j, it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)


                                if (switch_fix_labor == 0) then 
                                    foc = foc_intratemp(av, wage, wage_non_tax,  tc_vfi(it), l_trans(j, ia, i_aime, ip, ir, id, it), LabIncAVG_vfi(it))
                                else
                                    foc = foc_intratemp(av, wage, wage_non_tax,  tc_vfi(it), switch_fix_labor, LabIncAVG_vfi(it))
                                endif                            
                                c_trans(j, ia, i_aime, ip, ir, id, it)  = foc(1)  ! max( (available - w_pom_ss_vfi(j)*omega(j,it)*n_sp_value(ip)*(1d0 -  l_ss(j, ia, i_aime, ip, ir, id)) - svplus_ss(j, ia, i_aime, ip, ir, id))/tc_ss_vfi, 1e-10)
                                l_trans(j, ia, i_aime, ip, ir, id, it)  = foc(2)  ! 1d0 - min( max( (1d0-phi)*(available - svplus_ss(j, ia, i_aime, ip, ir, id))/(w_pom_ss_vfi(j)*omega(j,it)*n_sp_value(ip)) , 0d0) , 1d0)
                                labor_tax_trans(j, ia, i_aime, ip, ir, id, it) = foc(3)
                            
                                lab_income = (1-tL(it))*(wage*l_trans(j, ia, i_aime, ip, ir, id, it)/LabIncAVG_vfi(it))**(1-lambda_trans(it)) *LabIncAVG_vfi(it)+ &
                                wage_non_tax*l_trans(j, ia, i_aime, ip, ir, id, it)
                                lab_income_pretax =  wage*l_trans(j, ia, i_aime, ip, ir, id, it) +  wage_non_tax*l_trans(j, ia, i_aime, ip, ir, id, it)
                                bequest_j_trans(j, ia, i_aime, ip, ir, id, it) = bequest_j_vfi(j,it)
                                lab_income_trans(j, ia, i_aime, ip, ir, id, it) = lab_income
                                lab_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax
                                aime_plus_trans(j, ia, i_aime, ip, ir, id, it) = (float(j-1)*aime(i_aime)+min(wage*l_trans(j, ia, i_aime, ip, ir, id, it)/LabIncAVG_vfi(it), aime_cap))/float(j)
                                tot_income_pretax_trans(j, ia, i_aime, ip, ir, id, it) = lab_income_pretax + (n_sr_value(ir)+r_vfi_pretax(it))*sv(ia)/gam_vfi(it) + aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                tot_income_trans(j, ia, i_aime, ip, ir, id, it) = lab_income  + ((1d0-tk(it))*n_sr_value(ir)+r_vfi(it))*sv(ia)/gam_vfi(it)+ aime_replacement_rate(i_aime)*b_j_vfi(j,it)
                                pi_com = pi_trans_vfi_cond(j, it)
                                V_trans(j, ia, i_aime, ip, ir, id, it) = valuefunc_trans(svplus_trans(j, ia, i_aime, ip, ir, id, it), aime_plus_trans(j, ia, i_aime, ip, ir, id, it), &
                                                                                 c_trans(j, ia, i_aime, ip, ir, id, it), l_trans(j,ia, i_aime, ip, ir, id,it), j, ip, ir, id, it)
                                
                                if(j == (beq_age + 1) .and. switch_unequal_bequest == 2) then      
                                V_after_beq_trans(:, ia, i_aime, ip, ir, id,it) = V_trans(j, ia, i_aime, ip, ir, id, it)
                                endif
                            endif
                            
                            
                            


                        endif

                    enddo
                enddo
            enddo
        enddo
        
        do i_aime=0, n_aime,1 
            do ip=1, n_sp, 1
               do ir=1,n_sr, 1
                   do id=1, n_sd, 1
                       
                       if (j == beq_age .and. switch_unequal_bequest == 2) then
                       
                       call linear_int(aime_plus_trans(max(j-1,1), ia, i_aime, ip, ir, id, max(it-1,1)), iaimel, iaimer, dist, aime(:), n_aime, aime_grow)    
                           
                        EV_prim = 0d0
                        EV_trans(j, ia, i_aime, ip, ir, id, it) =0d0
                        
                        do ip_p=1, n_sp, 1                
                            do ir_r=1, n_sr, 1
                                do id_d=1, n_sd, 1
                                    do ibeq = 1, n_beq, 1
                                    c_help = dist*c_beq_trans(ibeq, ia, iaimel, ip_p, ir_r, id_d, it)  + (1d0-dist)*c_beq_trans(ibeq, ia, iaimer, ip_p, ir_r, id_d, it)
                                    l_help = dist*l_beq_trans(ibeq, ia, iaimel, ip_p, ir_r, id_d, it)  + (1d0-dist)*l_beq_trans(ibeq, ia, iaimer, ip_p, ir_r, id_d, it)       
                                    
                                    if(theta == 1_dp)then
                                        EV_prim = EV_prim + (1d0+r_vfi(it)+(1-tk(it))*n_sr_value(ir_r))/gam_ss_vfi*pi_ip_trans(ip, ip_p,tp)*pi_ir(ir, ir_r)*pi_id(id,id_d)*p_beq_trans(ibeq,it)/c_help
                                    elseif (theta .ne. 1_dp) then
                                            if(j<jbar_t_vfi(it))then
                                                    EV_prim =  EV_prim + (1d0+r_vfi(it)+(1-tk(it))*n_sr_value(ir_r))/gam_vfi(it)*pi_ip_trans(ip, ip_p,tp)*pi_ir(ir, ir_r)*pi_id(id,id_d)&
                                                                         *p_beq_trans(ibeq,it)*((1d0-l_help)/c_help)**((1d0-theta)*(1d0-phi))&
                                                                         *c_help**(-theta) 
                                            else
                                                    EV_prim = EV_prim + (1d0+r_vfi(it)+(1-tk(it))*n_sr_value(ir_r))/gam_vfi(it)*pi_ip_trans(ip, ip_p,tp)*pi_ir(ir, ir_r)*pi_id(id,id_d)&
                                                                        *p_beq_trans(ibeq,it)*c_help**(phi -theta*phi -1)
                                            endif                                
                                    endif
                                    EV_trans(j, ia, i_aime, ip, ir, id, it) = EV_trans(j, ia, i_aime, ip, ir, id, it) + pi_ip_trans(ip, ip_p,tp)*pi_ir(ir,ir_r)*pi_id(id, id_d)*V_beq_trans(ibeq, ia, i_aime, ip_p, ir_r, id_d, it)
                                    

                                    
                                     if(theta == 1_dp)then
                                        RHS_trans(j, ia, i_aime, ip, ir, id, it)=1d0/(tc_vfi(max(it-1,1))/tc_vfi(it)*(delta+n_sd_value(id))*pi_trans_vfi_cond(j,it)*EV_prim)  
                                     else
                                        RHS_trans(j, ia, i_aime, ip, ir, id, it)= tc_vfi(max(it-1,1))/tc_vfi(it)*(delta+n_sd_value(id)) *pi_trans_vfi_cond(j,it)*EV_prim
                                     endif 
                                     if (theta == 1) then 
                                        EV_trans(j, ia, i_aime, ip, ir, id, it) = EV_trans(j, ia, i_aime, ip, ir, id, it)
                                     else 
                                        EV_trans(bigj, ia, i_aime, ip, ir, id, it) = ((1d0-theta)*EV_trans(bigj, ia, i_aime, ip, ir, id, it))**(1d0/(1d0-theta))
                                     endif
                                   enddo
                                enddo
                            enddo
                        enddo
                        
                        elseif(j == (beq_age+1) .and. switch_unequal_bequest == 2 ) then
                                        
                            do ibeq = 1,n_beq,1
                                
                              call linear_int(aime_plus_beq_trans(ibeq, ia, i_aime, ip, ir, id, max(it-1,1)), iaimel, iaimer, dist, aime(:), n_aime, aime_grow)    
                           
                                EV_prim_after_beq = 0d0
                                EV_after_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) =0d0       
                        
                            do ip_p=1, n_sp, 1                
                                do ir_r=1, n_sr, 1
                                    do id_d=1, n_sd, 1
                                    c_help = dist*c_trans(j, ia, iaimel, ip_p, ir_r, id_d, it)  + (1d0-dist)*c_trans(j, ia, iaimer, ip_p, ir_r, id_d, it)
                                    l_help = dist*l_trans(j, ia, iaimel, ip_p, ir_r, id_d, it)  + (1d0-dist)*l_trans(j, ia, iaimer, ip_p, ir_r, id_d, it)
                                    if(theta == 1_dp)then
                                        EV_after_beq_trans = EV_after_beq_trans + (1d0+r_vfi(it)+(1-tk(it))*n_sr_value(ir_r))/gam_ss_vfi*pi_ip_trans(ip, ip_p,tp)*pi_ir(ir, ir_r)*pi_id(id,id_d)/c_help  
                                    else
                                            if(j<jbar_t_vfi(it))then
                                                    EV_prim_after_beq =  EV_prim_after_beq + (1d0+r_vfi(it)+(1-tk(it))*n_sr_value(ir_r))/gam_vfi(it)*pi_ip_trans(ip, ip_p,tp)*pi_ir(ir, ir_r)*pi_id(id,id_d)&
                                                                         *((1d0-l_help)/c_help)**((1d0-theta)*(1d0-phi))&
                                                                         *c_help**(-theta) 
                                            else
                                                    EV_prim_after_beq = EV_prim_after_beq + (1d0+r_vfi(it)+(1-tk(it))*n_sr_value(ir_r))/gam_vfi(it)*pi_ip_trans(ip, ip_p,tp)*pi_ir(ir, ir_r)*pi_id(id,id_d)*&
                                                                        c_help**(phi -theta*phi -1)
                                            endif
                                    endif
                            
                            
                                    ! to do to do  pi_ir(ir,ir_r) vs pi_ir(ip,ir_r)
                                    EV_after_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = EV_after_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) + pi_ip_trans(ip, ip_p,tp)*pi_ir(ir,ir_r)*pi_id(id, id_d)*V_after_beq_trans(ibeq, ia, i_aime, ip_p, ir_r, id_d, it)
                                    
                                     if(theta == 1_dp)then
                                        RHS_after_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)=1d0/(tc_vfi(max(it-1,1))/tc_vfi(it)*(delta+n_sd_value(id))*pi_trans_vfi_cond(j,it)*EV_prim_after_beq)  
                                     else
                                        RHS_after_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)= tc_vfi(max(it-1,1))/tc_vfi(it)*(delta+n_sd_value(id)) *pi_trans_vfi_cond(j,it)*EV_prim_after_beq
                                     endif 
                                     if (theta == 1) then 
                                        EV_after_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = EV_after_beq_trans(ibeq, ia, i_aime, ip, ir, id, it)
                                     else 
                                        EV_after_beq_trans(ibeq, ia, i_aime, ip, ir, id, it) = ((1d0-theta)*EV_after_beq_trans(ibeq, ia, i_aime, ip, ir, id, it))**(1d0/(1d0-theta))
                                     endif
                                enddo
                            enddo
                            enddo      
                            enddo
                            
                        else   
                           
                           
                       call linear_int(aime_plus_trans(max(j-1,1), ia, i_aime, ip, ir, id, max(it-1,1)), iaimel, iaimer, dist, aime(:), n_aime, aime_grow)
                        EV_prim = 0d0
                        EV_trans(j, ia, i_aime, ip, ir, id, it) =0d0
                        do ip_p=1, n_sp, 1                
                            do ir_r=1, n_sr, 1
                                do id_d=1, n_sd, 1
                                    c_help = dist*c_trans(j, ia, iaimel, ip_p, ir_r, id_d, it)  + (1d0-dist)*c_trans(j, ia, iaimer, ip_p, ir_r, id_d, it)
                                    l_help = dist*l_trans(j, ia, iaimel, ip_p, ir_r, id_d, it)  + (1d0-dist)*l_trans(j, ia, iaimer, ip_p, ir_r, id_d, it)
                                    if(theta == 1_dp)then
                                        EV_prim = EV_prim + (1d0+r_vfi(it)+(1-tk(it))*n_sr_value(ir_r))/gam_ss_vfi*pi_ip_trans(ip, ip_p,tp)*pi_ir(ir, ir_r)*pi_id(id,id_d)/c_help  
                                    else
                                            if(j<jbar_t_vfi(it))then
                                                    EV_prim =  EV_prim + (1d0+r_vfi(it)+(1-tk(it))*n_sr_value(ir_r))/gam_vfi(it)*pi_ip_trans(ip, ip_p,tp)*pi_ir(ir, ir_r)*pi_id(id,id_d)&
                                                                         *((1d0-l_help)/c_help)**((1d0-theta)*(1d0-phi))&
                                                                         *c_help**(-theta) 
                                            else
                                                    EV_prim = EV_prim + (1d0+r_vfi(it)+(1-tk(it))*n_sr_value(ir_r))/gam_vfi(it)*pi_ip_trans(ip, ip_p,tp)*pi_ir(ir, ir_r)*pi_id(id,id_d)*&
                                                                        c_help**(phi -theta*phi -1)
                                            endif
                                    endif
                            
                            
                                    ! to do to do  pi_ir(ir,ir_r) vs pi_ir(ip,ir_r)
                                    EV_trans(j, ia, i_aime, ip, ir, id, it) = EV_trans(j, ia, i_aime, ip, ir, id, it) + pi_ip_trans(ip, ip_p,tp)*pi_ir(ir,ir_r)*pi_id(id, id_d)*V_trans(j, ia, i_aime, ip_p, ir_r, id_d, it)
                                enddo
                            enddo
                        enddo
                         if(theta == 1_dp)then
                            RHS_trans(j, ia, i_aime, ip, ir, id, it)=1d0/(tc_vfi(max(it-1,1))/tc_vfi(it)*(delta+n_sd_value(id))*pi_trans_vfi_cond(j,it)*EV_prim)  
                        else
                            RHS_trans(j, ia, i_aime, ip, ir, id, it)= tc_vfi(max(it-1,1))/tc_vfi(it)*(delta+n_sd_value(id)) *pi_trans_vfi_cond(j,it)*EV_prim
                        endif 
                        if (theta == 1) then 
                            EV_trans(j, ia, i_aime, ip, ir, id, it) = EV_trans(j, ia, i_aime, ip, ir, id, it)
                        else 
                            EV_trans(j, ia, i_aime, ip, ir, id, it) = ((1d0-theta)*EV_trans(j, ia, i_aime, ip, ir, id, it))**(1d0/(1d0-theta))
                        endif
                        
                    endif
            enddo
         enddo 
     enddo
enddo
enddo
enddo

end subroutine
