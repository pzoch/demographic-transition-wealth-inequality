!===============================================================================
! FILE: pension_system_ss.f90
!
! DESCRIPTION:
!   Computes pension benefits in steady state for both PAYG and fully-funded
!   pension systems. Calculates Pillar I (PAYG or notional accounts) and 
!   Pillar II (funded accounts) benefits based on contributions and returns.
!
! INCLUDED IN: steady_state.f90 via include statement
!
! PURPOSE:
!   Calculate steady state pension benefits for all ages using either:
!   - PAYG system (switch_type=0): Benefits based on replacement rate
!   - Funded system (switch_type=1): Benefits based on accumulated accounts
!
! SWITCH_TYPE = 0 (PAYG SYSTEM):
!   Formula:
!     - Before retirement (j < jbar_ss): b1_ss_j(j) = 0
!     - At retirement (j = jbar_ss): b1_ss_j(j) = rho * avg_wl
!     - After retirement (j > jbar_ss): b1_ss_j(j) = valor_mult_ss * b1_ss_j(j-1)
!     - Total: b_ss_j = b_scale_factor_ss * b1_ss_j
!     - Subsidy: subsidy_ss_j = sum_b_weight_ss * b_ss_j - t1_ss * w_bar_ss * l_ss_j
!   
!   Where:
!     - rho: Replacement rate (target benefit as fraction of pre-retirement wage)
!     - avg_wl: Average wage-earnings over working life
!     - valor_mult_ss: Valorization factor for benefit indexation
!     - b_scale_factor_ss: Scaling to ensure budget balance
!
! SWITCH_TYPE = 1 (FUNDED SYSTEM):
!   Pillar I (Notional Defined Contribution):
!     - Accumulation (j < jbar_ss):
!         pillarI_ss_j(j) = (1+rI_ss) * pillarI_ss_j(j-1)/gam_ss * pi_ss(j-1)/pi_ss(j) + contributionI_ss_j(j)
!     - At retirement: accountI_ss = accumulated balance
!     - Annuitization: b1_ss_j(jbar_ss) = accountI_ss / life_exp(jbar_ss)
!     - Drawdown (j > jbar_ss): Account balance evolves with rI_ss, pays benefit b1_ss_j
!   
!   Pillar II (Funded Defined Contribution):
!     - Same logic but uses market return r_bar_ss instead of notional rI_ss
!     - Accumulation rate: (1 + r_bar_ss)
!     - Benefits indexed to (1 + r_bar_ss)/gam_ss
!   
!   Total benefit: b_ss_j = b1_ss_j + b2_ss_j
!
! KEY VARIABLES:
!   INPUT (from steady state iteration):
!     - w_ss_j, l_ss_j: Wages and labor supply by age
!     - w_bar_ss: Average wage
!     - jbar_ss: Retirement age
!     - gam_ss, nu_ss: TFP and population growth
!     - pi_ss: Survival probabilities
!     - life_exp: Remaining life expectancy
!     - r_bar_ss: Gross interest rate
!     - t1_ss, t2_ss: Contribution rates (Pillar I and II)
!     - rho: Replacement rate (PAYG)
!     - switch_type: System type (0=PAYG, 1=funded)
!   
!   OUTPUT:
!     - b1_ss_j, b2_ss_j: Pillar I and II benefits by age
!     - b_ss_j: Total pension benefits by age
!     - pillarI_ss_j, pillarII_ss_j: Account balances by age (funded system)
!     - subsidy_ss_j: Implicit subsidy/tax per person
!     - subsidy_ss: Aggregate subsidy per effective labor
!     - sum_b_ss: Aggregate benefits per effective labor
!     - contributionI_ss_j, contributionII_ss_j: Contributions by age
!
! VALORIZATION:
!   - valor_mult_ss: Benefit indexation factor in steady state
!   - rI_ss: Notional return in Pillar I (typically wage growth = gam_ss*nu_ss - 1)
!   - Benefits after retirement grow at valorization rate
!
! ANNUITIZATION:
!   In funded system, accumulated balance converted to annuity at retirement:
!     Annual benefit = Account balance / Life expectancy
!   Assumes actuarially fair pricing with survival probabilities
!
! BUDGET BALANCE:
!   - b_scale_factor_ss adjusts benefits to satisfy pension budget constraint
!   - subsidy_ss captures implicit transfers in PAYG system
!   - In funded system, subsidy_ss should be near zero (actuarially fair)
!
! NOTES:
!   - Pillar II currently inactive in most scenarios (t2_ss = 0)
!   - PAYG system more common in applications
!   - Funded system requires longer computational time (tracks accounts)
!   - Both systems ensure no benefits before retirement age jbar_ss
!===============================================================================

if (switch_type == 0)  then     
    b2_ss_j = 0  
    b1_ss_j(1:jbar_ss-1) = 0

    avg_wl = sum(w_ss_j(1:jbar_ss-1)*l_ss_j(1:jbar_ss-1))/(real(jbar_ss-1))

    b1_ss_j(jbar_ss) = rho*avg_wl !w_ss_j(jbar_ss-1)*l_ss_j(jbar_ss-1) 
    do j = jbar_ss+1,bigJ,1
        b1_ss_j(j) = valor_mult_ss*b1_ss_j(j-1)
    enddo
    
    b_ss_j = b_scale_factor_ss*b1_ss_j 
    sum_b_ss = sum_b_weight_ss*sum(b_ss_j*N_ss_j(1:bigJ))/bigl_ss
    subsidy_ss_j = sum_b_weight_ss*b_ss_j - t1_ss*w_bar_ss*l_ss_j       
    subsidy_ss = sum(N_ss_j*subsidy_ss_j(1:bigJ))/bigl_ss
else    
    contributionI_ss_j = t1_ss*w_bar_ss*l_ss_j
    contributionII_ss_j = t2_ss*w_bar_ss*l_ss_j
    b1_ss_j(1:jbar_ss-1) = 0d0
    b2_ss_j(1:jbar_ss-1) = 0
    pillarI_ss_j(1)  = contributionI_ss_j(1) 
    pillarII_ss_j(1) = contributionII_ss_j(1)
    accountI_ss = 0   
    accountII_ss = 0
    do j = 2,bigj,1
        if (j < jbar_ss) then
            pillarI_ss_j(j) = (1 + rI_ss)*pillarI_ss_j(j-1)/gam_ss*pi_ss(j-1)/pi_ss(j) + contributionI_ss_j(j) 
            pillarII_ss_j(j) = (1 + r_bar_ss)*pillarII_ss_j(j-1)/gam_ss*pi_ss(j-1)/pi_ss(j) + contributionII_ss_j(j)
        elseif (j == jbar_ss) then      
            accountI_ss  = (1 + rI_ss)*pillarI_ss_j(j-1)/gam_ss*pi_ss(j-1)/pi_ss(j) 
            accountII_ss = (1 + r_bar_ss)*pillarII_ss_j(j-1)/gam_ss*pi_ss(j-1)/pi_ss(j)
            b1_ss_j(j) = accountI_ss/life_exp(j) 
            b2_ss_j(j) = accountII_ss/life_exp(j)
            pillarI_ss_j(j) = (1 + rI_ss)*pillarI_ss_j(j-1)/gam_ss*pi_ss(j-1)/pi_ss(j) - b1_ss_j(j)
            pillarII_ss_j(j) = (1 + r_bar_ss)*pillarII_ss_j(j-1)/gam_ss*pi_ss(j-1)/pi_ss(j) - b2_ss_j(j)
        else 
            b1_ss_j(j) = valor_mult_ss*b1_ss_j(j-1)   
		    b2_ss_j(j) = b2_ss_j(j-1)*(1 + r_bar_ss)/gam_ss 
            pillarI_ss_j(j) = (1 + rI_ss)*pillarI_ss_j(j-1)/gam_ss*pi_ss(j-1)/pi_ss(j) - b1_ss_j(j)
            pillarII_ss_j(j) = (1 + r_bar_ss)*pillarII_ss_j(j-1)/gam_ss*pi_ss(j-1)/pi_ss(j)  - b2_ss_j(j)
        endif
    enddo
    b_ss_j = b_scale_factor_ss*b1_ss_j + b2_ss_j
        
    PillarI_ss = sum(N_ss_j*pillarI_ss_j(1:bigJ))/(bigl_ss) 
    PillarII_ss = sum(N_ss_j*pillarII_ss_j(1:bigJ))/(bigl_ss)

    sum_b_ss = sum((b_scale_factor_ss*b1_ss_j+b2_ss_j)*N_ss_j(1:bigJ))/bigl_ss 
                 
    subsidy_ss_j = b_scale_factor_ss*b1_ss_j  - t1_ss*w_bar_ss*l_ss_j  
    !subsidy_ss_j = b2_ss_j  - t2_ss*omega_ss*w_bar_ss*l_ss_j 
    subsidy_ss = sum(subsidy_ss_j*N_ss_j(1:bigJ))/bigl_ss
endif
