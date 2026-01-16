!===============================================================================
! FILE: pfi_agregation.f90
!
! DESCRIPTION:
!   Aggregates individual policy functions over the state space distribution to
!   compute cohort-level and economy-wide statistics. Bridges the micro household
!   problem with macro equilibrium conditions by integrating heterogeneous decisions.
!
! PURPOSE:
!   Given solved policy functions {c, l, a'} and equilibrium distribution prob(j,⋅),
!   this module computes:
!   1. Age-specific averages for life-cycle profiles
!   2. Economy-wide aggregates for market clearing
!   3. Distributional statistics (Gini, wealth shares, etc.)
!   4. Euler equation residuals for solution accuracy checks
!
! SUBROUTINES:
!   - aggregation_ss: Steady-state aggregation
!       Computes: cohort_avg(j) = ∑_{a,aime,ε,δ,r} prob_ss(j,⋅) * policy_ss(j,⋅)
!       For all ages j=1,...,bigJ and all policy/value functions
!
!   - aggregation_trans: Transition path aggregation (cohort-period tracking)
!       Same as aggregation_ss but for each period i=2,...,bigT
!       Accounts for cohort-specific shocks (time-varying σ²_ε, skill premium, etc.)
!
! COHORT AGGREGATES (steady state):
!   For each age j ∈ {1,...,bigJ}, computes expected values:
!   - c_ss_j_vfi(j): Average consumption
!   - l_ss_j_vfi(j): Average labor supply (efficiency units)
!   - lab_ss_j_vfi(j): Average labor hours (raw)
!   - s_pom_ss_j_vfi(j): Average savings (next period assets)
!   - asset_pom_ss_j_vfi(j): Average current assets
!   - V_ss_j_vfi(j): Average lifetime utility
!   - lab_income_ss_j_vfi(j): Average after-tax labor income
!   - lab_income_pretax_ss_j_vfi(j): Average pre-tax labor income
!   - pension_ss_j_vfi(j): Average pension benefits received
!   - labor_tax_ss_j_vfi(j): Average labor tax paid
!   - lw_ss_j_vfi(j): Average labor income (w*ε*l)
!   - lw_lambda_ss_j_vfi(j): Average (w*ε*l)^(1-λ) for progressive tax
!
! ECONOMY-WIDE AGGREGATES:
!   Weighted by cohort size N_ss_j_vfi(j) to get totals:
!   - bigC_ss = ∑_j N_ss_j * c_ss_j_vfi(j): Total consumption
!   - bigL_ss = ∑_j N_ss_j * l_ss_j_vfi(j): Total effective labor supply
!   - bigK_ss = ∑_j N_ss_j * s_pom_ss_j_vfi(j): Total capital stock
!   - bequest_ss_vfi: Total bequests left by decedents
!   (Economy totals computed in steady_state.f90, not here)
!
! DISTRIBUTIONAL STATISTICS:
!   - gini_weight_sv(j,ia): Wealth distribution weights for Gini calculation
!   - gini_weight_consumption(j,ia,i_aime,ip,ir,id): Consumption weights
!   - gini_income(j,ia,i_aime,ip,ir,id): Labor income for Gini
!   - top_ten(10): Wealth held by each decile from top down
!   - top_100(100): Wealth held by each percentile from top down
!   - savings_top_ten(10), savings_top_100(100): Total wealth in each group
!   - savings_cohort_ten(1:3,j): Top 10%, bottom 10%, all (by age)
!   - consumption_top_ten(1:3,j): Same for consumption
!   - share_0_sav: Fraction of working-age (j=2-9) at zero savings
!   - share_neg: Fraction with negative wealth (a < 0)
!   - share_nonpos: Fraction with non-positive wealth (a ≤ 0)
!
! AGGREGATION ALGORITHM:
!   For steady state (similar for transition):
!   1. Initialize all aggregates to zero
!   2. Loop over ages j = 1,...,bigJ:
!      a. Loop over all states (ia, i_aime, ip, ir, id):
!         - Add prob_ss(j,ia,i_aime,ip,ir,id) * policy_ss(j,ia,i_aime,ip,ir,id)
!           to corresponding cohort average
!         - Accumulate distributional statistics (Gini weights, top shares)
!      b. Cohort averages are now E[policy | age=j]
!   3. Economy-wide totals computed in calling routine (steady_state.f90)
!
! STATE SPACE:
!   Five-dimensional heterogeneity (plus age):
!   - ia ∈ {0,...,n_a}: Asset holdings
!   - i_aime ∈ {0,...,n_aime}: Average indexed monthly earnings (Social Security)
!   - ip ∈ {1,...,n_sp}: Permanent/persistent productivity shock
!   - ir ∈ {1,...,n_sr}: Return shock (portfolio return heterogeneity)
!   - id ∈ {1,...,n_sd}: Discount factor shock (preference heterogeneity)
!
! ACCURACY DIAGNOSTICS:
!   - check_e(j): Euler equation error at each age (sum over all states)
!   - euler_max(j): Maximum absolute Euler error by age
!   - Euler residuals written to euler_ss.csv (steady state only)
!
! DEPENDENCIES:
!   - global_vars: All policy functions (c_ss, l_ss, svplus_ss, etc.),
!                  distributions (prob_ss, prob_trans), grids (sv, aime),
!                  parameters (N_ss_j_vfi, omega_ss, n_sp_value, etc.)
!   - gini_calc: For gini() function (called in steady_state.f90, not here)
!   - linint: For linear_int() to find zero-wealth point
!
! NOTES FOR REPLICATION:
!   - Aggregation loops are performance-critical (5D state space × bigJ ages)
!   - Distributional statistics computed top-down (wealth-ordered) for efficiency
!   - Cohort averages include both workers (j < jbar) and retirees (j ≥ jbar)
!   - pension_ss_j_vfi uses AIME-dependent replacement rate (US Social Security formula)
!   - Top wealth shares accumulate probability mass until threshold reached (0.1, 0.01)
!   - Transition aggregation handles cohort-specific parameters via year_birth indexing
!   - sum_b_weight_ss_vfi: Average AIME replacement rate at retirement (jbar_ss_vf)
!
! OUTPUT:
!   All aggregates stored in global_vars module. Key variables:
!   - *_ss_j_vfi: Cohort averages (steady state)
!   - *_j_vfi(*,i): Cohort averages by period (transition)
!   - gini_weight_*, top_*, share_*: Distributional moments
!   - check_euler_trans(*,1): Euler errors (written to CSV)
!===============================================================================
!***************************************************************************************
! find aggegate variables for steady state

    subroutine aggregation_ss()
    
        implicit none
        
        integer :: ij, ial, iar, ia_last, tt
        real*8 :: check_e(bigJ), check_euler_cum, euler_max(bigJ), w_sum(0:bigJ), bc,  ERHS_ss(bigJ, 0:n_a,  n_sp, n_sr,n_sd),  sum_y, dist 
        real*8 :: sum_help, p_1_5(bigJ)
    
       ! write(*,*) c_ss(1,0,3)
        
        ! calculate cohort aggregates
        savings_cohort_ten = 0d0
        c_ss_j_vfi(:) = 0d0
        V_ss_j_vfi(:) = 0d0
        lab_income_ss_j_vfi(:) = 0d0
        lab_income_pretax_ss_j_vfi(:) = 0d0
        tot_income_pretax_ss_j_vfi(:) = 0d0
        tot_income_ss_j_vfi(:) = 0d0
        l_ss_j_vfi(:) = 0d0
        s_pom_ss_j_vfi(:) = 0d0
        lab_ss_j_vfi(:) = 0d0
        asset_pom_ss_j_vfi(:) = 0d0
        l_ss_pen_j_vfi(:) = 0d0
        w_sum(0) = 0d0
        ERHS_ss = 0d0
        top_ten(:) = 0d0 
        top_ten_coh(:) =0d0
        top_100 =0d0
        savings_top_100 = 0d0
        lab_high_ss_j_vfi(:)= 0d0
        gini_weight_sv = 0d0
        gini_weight_consumption = 0d0
        pension_ss_j_vfi(:) = 0d0
        share_0_sav = 0d0
        share_neg = 0d0
        share_nonpos = 0d0
        sum_b_weight_ss_vfi = 0d0
        labor_tax_ss_j_vfi(:) = 0d0
        lw_lambda_ss_j_vfi(:) = 0d0
        lw_ss_j_vfi(:) = 0d0
        t = 10
        tt =100
        if (n_sp > 5) then
            do j=1,bigJ,1
                p_1_5(j) = sum(prob_ss(j,:,:,1:5,:,:))
            enddo
        else 
            do j=1,bigJ,1
                p_1_5(j) = 1d0
            enddo
        endif
        savings_top_ten =0d0
        cons_proc_top_ten_coh(:)= 0d0
        consumption_top_ten = 0d0
        call linear_int(0d0, ial, iar, dist, sv, n_a, a_grow)
                                        ial = min(ial, n_a)
                                        iar = min(iar, n_a)
                                        dist = min(dist, 1d0)
                                        
        ia_last = n_a
            do ia = n_a, 0 , -1
                do i_aime = n_aime, 0 , -1
                    do j = 1, bigJ 
                        do ip = 1, n_sp, 1  
                            do ir=1, n_sr, 1
                                do id = 1, n_sd, 1
                                    gini_weight_sv(j,ia) = gini_weight_sv(j,ia) + prob_ss(j, ia, i_aime, ip, ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                    gini_weight_consumption(j, ia, i_aime, ip,ir, id) = gini_weight_consumption(j, ia, i_aime, ip,ir, id) + prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                    gini_income(j, ia, i_aime, ip,ir, id) = omega_ss(j)*n_sp_value(ip)*l_ss(j, ia, i_aime, ip, ir, id)*w_pom_ss_vfi(j)
                                    if (top_ten(t) >= 0.1d0) then 
                                        t = t-1
                                        top_ten(t) =  top_ten(t) + prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                        savings_top_ten(t) = savings_top_ten(t) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)*N_ss_j_vfi(j)
                                    else
                                        top_ten(t) =  top_ten(t) + prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                        savings_top_ten(t) = savings_top_ten(t) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)*N_ss_j_vfi(j)
                                    endif
                                                           
                                    if ((svplus_ss(j, ia, i_aime, ip, ir, id) == a_l) .and. (j > 1 ) .and. (j < 10)) then
                                        share_0_sav = share_0_sav + prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi(2:9))
                                    endif
                                        
                                    if (ia < ial) then
                                        share_neg = share_neg +  prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                    endif
                                
                                    if (ia <= iar) then
                                        share_nonpos =  share_nonpos + prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                    endif
                                    !if (top_ten(t) < -0.00001d0) then 
                                    !    write(*,*) prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                    !endif
                                     if (top_100(tt) >= 0.01d0) then 
                                        tt = tt-1
                                        top_100(tt) =  top_100(tt) + prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                        savings_top_100(tt) = savings_top_100(tt) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)*N_ss_j_vfi(j)
                                    else
                                        top_100(tt) =  top_100(tt) + prob_ss(j, ia, i_aime, ip,ir, id)*N_ss_j_vfi(j)/sum(N_ss_j_vfi)
                                        savings_top_100(tt) = savings_top_100(tt) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)*N_ss_j_vfi(j)
                                    endif
                                    if (top_ten_coh(j) <= 0.1d0 ) then 
                                
                                        top_ten_coh(j) =  top_ten_coh(j) + prob_ss(j, ia, i_aime, ip,ir, id)
                                        savings_cohort_ten(1,j) = savings_cohort_ten(1,j) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)*10d0
                                        savings_cohort_ten(3,j) = savings_cohort_ten(3,j) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)
                                        consumption_top_ten(1,j) =  consumption_top_ten(1,j) + c_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)*10d0
                                        consumption_top_ten(3,j) =  consumption_top_ten(3,j) + c_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)
                                    elseif(top_ten_coh(j) >= 0.9d0)then
                                        top_ten_coh(j) =  top_ten_coh(j) + prob_ss(j, ia, i_aime, ip,ir, id)
                                        savings_cohort_ten(2,j) = savings_cohort_ten(2,j) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)*10
                                        savings_cohort_ten(3,j) = savings_cohort_ten(3,j) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)
                                        consumption_top_ten(3,j) =  consumption_top_ten(3,j) + c_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)
                                        consumption_top_ten(2,j) =  consumption_top_ten(2,j) + c_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)*10
                                    else
                                        top_ten_coh(j) =  top_ten_coh(j) + prob_ss(j, ia, i_aime, ip,ir, id)
                                        savings_cohort_ten(3,j) = savings_cohort_ten(3,j) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id)
                                        consumption_top_ten(3,j) =  consumption_top_ten(3,j) + c_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)
                                    endif
                                    pension_ss_j_vfi(j) = pension_ss_j_vfi(j) + aime_replacement_rate(i_aime)*b_ss_j_vfi(j)*prob_ss(j, ia, i_aime, ip,ir, id)
                                    c_ss_j_vfi(j) = c_ss_j_vfi(j) + c_ss(j, ia, i_aime, ip, ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)
                                    lab_income_ss_j_vfi(j) = lab_income_ss_j_vfi(j) + lab_income_ss(j, ia, i_aime, ip, ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)
                                    lab_income_pretax_ss_j_vfi(j) = lab_income_pretax_ss_j_vfi(j) + lab_income_pretax_ss(j, ia, i_aime, ip, ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)
                                    tot_income_ss_j_vfi(j) = tot_income_ss_j_vfi(j) + tot_income_ss(j, ia, i_aime, ip, ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)
                                    tot_income_pretax_ss_j_vfi(j) = tot_income_pretax_ss_j_vfi(j) + tot_income_pretax_ss(j, ia, i_aime, ip, ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)
                                    if(ip<6)then
                                        l_ss_pen_j_vfi(j) = l_ss_pen_j_vfi(j) + omega_ss(j)*n_sp_value(ip)*l_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)/p_1_5(j)
                                    endif 
                                    if(ip>=6)then
                                        lab_high_ss_j_vfi(j) = lab_high_ss_j_vfi(j) + l_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)/(1d0-p_1_5(j))
                                    endif
                                     if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                        l_ss_j_vfi(j) = l_ss_j_vfi(j) + n_sp_value(ip)*l_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)

                                    else
                                        l_ss_j_vfi(j) = l_ss_j_vfi(j) + omega_ss(j)*n_sp_value(ip)*l_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip,ir, id)

                                    endif                                
                                    lab_ss_j_vfi(j) = lab_ss_j_vfi(j) + l_ss(j, ia, i_aime, ip, ir, id)*prob_ss(j, ia, i_aime, ip, ir, id) 
                                    labor_tax_ss_j_vfi(j) = labor_tax_ss_j_vfi(j) + labor_tax(j, ia, i_aime, ip, ir, id)*prob_ss(j, ia, i_aime, ip, ir, id)
                                    lw_lambda_ss_j_vfi(j) = lw_lambda_ss_j_vfi(j) + (omega_ss(j)*n_sp_value(ip)*w_pom_ss_vfi(j)*l_ss(j, ia, i_aime, ip,ir, id))**(1-lambda)*prob_ss(j, ia, i_aime, ip,ir, id)
                                    lw_ss_j_vfi(j) = lw_ss_j_vfi(j) + omega_ss(j)*n_sp_value(ip)*w_pom_ss_vfi(j)*l_ss(j, ia, i_aime, ip,ir, id)*prob_ss(j, ia, i_aime, ip, ir, id) 
                                    s_pom_ss_j_vfi(j) = s_pom_ss_j_vfi(j) + svplus_ss(j, ia, i_aime, ip, ir, id)*prob_ss(j, ia, i_aime, ip, ir, id)
                                    asset_pom_ss_j_vfi(j) = asset_pom_ss_j_vfi(j) + sv(ia)*prob_ss(j, ia, i_aime, ip, ir, id) 
                                    !if (prob_ss(j, ia, i_aime, ip, ir, id) > 1d-10) then 
                                        V_ss_j_vfi(j)  =  V_ss_j_vfi(j) + V_ss(j, ia, i_aime, ip, ir, id)*prob_ss(j, ia, i_aime, ip, ir, id)
                                   ! endif
                                      
                                enddo
                            enddo
                        enddo
                        !if(j>1)then
                        !    w_sum(j) = w_sum(j-1) + aime_replacement_rate(i_aime)*b_ss_j_vfi(j) + l_ss_j_vfi(j)*w_pom_ss_vfi(j) + bequest_ss_j_vfi(j)  
                        !else
                        !    w_sum(j) = 0d0 + aime_replacement_rate(i_aime)*b_ss_j_vfi(j) + l_ss_j_vfi(j)*w_pom_ss_vfi(j) + bequest_ss_j_vfi(j)  
                        !endif
                       enddo
               
                    ia_last = ia
                enddo
            enddo
            
            do i_aime = 0, n_aime   
                sum_b_weight_ss_vfi = sum_b_weight_ss_vfi + aime_replacement_rate(i_aime)*sum(prob_ss(jbar_ss_vf, :, i_aime, :, :, :))
                !!! this has to be correct
            enddo

            do j = 1,bigJ-1,1
                check_e(j)=sum(ERHS_ss(j,:,:, :,:)) ! check euler (only of theta = 1) with other theta marginal utility is not linear 
            enddo
            check_euler_cum = sum(check_e)
       
            bc = sum(c_ss_j_vfi(1:bigJ)*tc_ss_vfi)- (r_ss_vfi/gam_ss_vfi-1d0)*sum(s_pom_ss_j_vfi(1:bigJ)) - w_sum(bigJ) ! budget constraint 
    !        write(*,*) check_euler_cum
            euler_max = abs(check_e)

        open(unit = 104, file= "euler_ss.csv")
            do j = 2,bigJ,1
                write(104, '(F20.10)') check_e(j)
            enddo
        close(104)
        
        
        if (switch_run_1 == 1)then
            check_euler_trans(:,1) = check_e
        endif
        
    end subroutine

!***************************************************************************************

! find aggegate variables for transition
    subroutine aggregation_trans(i)
    
        implicit none
        integer, intent(in) :: i 
        integer :: j, ial, iar, tp, year_birth
        real*8 ::  check_euler_trans_cum, euler_trans_max(bigJ), w_sum(0:bigJ), bc, sum_y, sum_help, dist, p_1_5_trans(bigJ,bigT), sum_n 
        
        t = 10
       ! write(*,*) c_trans(1,0,3)
        ! calculate cohort aggregates
        c_j_vfi(:,i) = 0d0
        V_j_vfi(:,i) = 0d0
        l_j_vfi(:,i) = 0d0
        avg_aime_replacement_rate(:,i) = 0d0
        labor_tax_j_vfi(:,i) = 0d0
        lw_lambda_j_vfi(:,i) = 0d0
        lw_j_vfi(:,i) = 0d0
        l_pen_j_vfi(:,i) = 0d0
        s_pom_j_vfi(:,i) = 0d0
        lab_j_vfi(:,i) = 0d0
        labor_tax_j_vfi(:,i) = 0d0
        asset_trans(:,i) = 0d0
        top_ten_trans(:,i) = 0d0
        savings_top_ten_trans(:,i) = 0d0
        sum_n= sum(N_t_j_vfi(:,i))
        w_sum(0) = 0d0
        sum_b_weight_trans(i) = 0d0
        if (n_sp>5) then 
            do j=1,bigJ,1
                p_1_5_trans(j,i) = sum(prob_trans(j,:,:,1:5,:,:,i))
            enddo
        else 
            do j=1,bigJ,1
                p_1_5_trans(j,i) = 1d0
            enddo
        endif
        gini_weight_trans(:,:, i) = 0.0d0
        do ia = n_a, 0, -1 
            do i_aime = n_aime, 0 , -1
                do j = 1, bigJ
                    
                                ! this is new, NEED TO ADD TIME-SPECIFIC VARIANCES
                                year_birth = i - j + 1  ! get year of birth to assign correct sigma2_epsilon


                                tp = year_birth 

                                if (tp < 1) then
                                tp = 1
                                elseif (tp > bigT) then
                                tp = bigT
                                endif
            
                    do ip = 1, n_sp, 1
                        do ir=1, n_sr, 1
                            do id =1, n_sd, 1
                                c_j_vfi(j,i) = c_j_vfi(j,i) + c_trans(j, ia, i_aime, ip, ir, id, i)*prob_trans(j, ia, i_aime, ip, ir, id,i)

                                
                                 if ( (mod(ip,n_sp_risk) == 0) .and. n_superstar> 0) then
                                    l_j_vfi(j,i) = l_j_vfi(j,i) + n_sp_value_trans(ip,tp)*l_trans(j, ia, i_aime, ip, ir, id,i)*prob_trans(j, ia, i_aime, ip, ir, id,i)    
                                else
                                    l_j_vfi(j,i) = l_j_vfi(j,i) + omega(j,i)*n_sp_value_trans(ip,tp)*l_trans(j, ia, i_aime, ip, ir, id,i)*prob_trans(j, ia, i_aime, ip, ir, id,i)
                                endif
                                
                                lab_j_vfi(j,i) = lab_j_vfi(j,i) + l_trans(j, ia, i_aime, ip, ir, id, i)*prob_trans(j, ia, i_aime, ip, ir, id,i)  
                                labor_tax_j_vfi(j,i) = labor_tax_j_vfi(j,i) + labor_tax_trans(j, ia, i_aime, ip, ir, id, i)*prob_trans(j, ia, i_aime, ip, ir, id,i)  
                            
                                lw_j_vfi(j,i) = lw_j_vfi(j,i) + omega(j,i)*n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, i)*l_trans(j, ia, i_aime, ip, ir, id,i)*prob_trans(j, ia, i_aime, ip, ir, id,i)
                                lw_lambda_j_vfi(j,i) = lw_lambda_j_vfi(j,i) + (omega(j,i)*n_sp_value_trans(ip,tp)*w_pom_trans_vfi(j, i)*l_trans(j, ia, i_aime, ip, ir, id,i))**(1-lambda)*prob_trans(j, ia, i_aime, ip, ir, id,i)  
                            
                                s_pom_j_vfi(j,i) = s_pom_j_vfi(j,i) + svplus_trans(j, ia, i_aime, ip, ir, id,i)*prob_trans(j, ia, i_aime, ip, ir, id,i)
                                !if (prob_trans(j, ia, i_aime, ip, ir,i)>1d-8) then  
                                    V_j_vfi(j,i)   =   V_j_vfi(j,i) + V_trans(j, ia, i_aime, ip, ir, id,i)*prob_trans(j, ia, i_aime, ip, ir, id,i) 
                                !endif 
                                gini_weight_trans(j,ia, i) = gini_weight_trans(j,ia,i) + prob_trans(j, ia, i_aime, ip,ir, id, i)*N_t_j_vfi(j,i)/sum_n
                                asset_trans(j,i) = asset_trans(j,i) + sv(ia)*prob_trans(j, ia, i_aime, ip, ir, id,i)    

                                
                                
                                if(ip<6)then
                                    l_pen_j_vfi(j,i) = l_pen_j_vfi(j,i) + omega(j,i)*n_sp_value_trans(ip,tp)*l_trans(j, ia, i_aime, ip, ir, id,i)*prob_trans(j, ia, i_aime, ip, ir, id,i)/p_1_5_trans(j,i)
                                endif
                                if ((prob_trans(j, ia, i_aime, ip, ir, id,i)>1d-10) .and. (j<bigJ)) then
                                    sum_help = 0.0d0
                                    call linear_int(svplus_trans(j, ia, i_aime, ip, ir, id,i), ial, iar, dist, sv, n_a, a_grow)
                                    do ip_p = 1, n_sp,1
                                        do ir_r=1, n_sr, 1
                                            do id_d =1, n_sd, 1
                                                sum_help  = sum_help + dist*pi_ip(ip, ip_p)*pi_ir(ir,ir_r)*pi_id(id, id_d)*(delta+n_sd_value(id))&
                                                            *margu(c_trans(j+1, ial, i_aime, ip_p, ir_r, id_d, min(i+1, bigT)),l_trans(j+1,ial, i_aime, ip_p, ir_r, id_d, min(i+1, bigT)),tc_vfi(min(i+1, bigT)) )
                                                sum_help  = sum_help + (1-dist)*pi_ip(ip, ip_p)*pi_ir(ir,ir_r)*pi_id(id, id_d)*(delta+n_sd_value(id))&
                                                            *margu(c_trans(j+1, iar, i_aime, ip_p, ir_r, id_d, min(i+1, bigT)),l_trans(j+1,iar, i_aime, ip_p, ir_r, id_d, min(i+1, bigT)),tc_vfi(min(i+1, bigT)) )
                                            enddo
                                        enddo
                                    enddo

                                endif
                              
                                avg_aime_replacement_rate(j,i) = aime_replacement_rate(i_aime)*prob_trans(j, ia, i_aime, ip, ir, id,i)
                            enddo
                        enddo
                    enddo
                enddo
            enddo
        enddo
        
        
            do i_aime = 0, n_aime   
                sum_b_weight_trans(i) = sum_b_weight_trans(i) + aime_replacement_rate(i_aime)*sum(prob_trans(jbar_t_vfi(i), :, i_aime, :, :, :, i))
            enddo


    end subroutine

!**************************************************************************************

