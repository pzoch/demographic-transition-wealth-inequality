!===============================================================================
! FILE: data.f90
!
! DESCRIPTION:
!   Module for loading external data files containing demographic projections,
!   economic time series, and policy parameters. Processes raw data and prepares
!   time-varying arrays for steady state and transition path computations.
!
! MODULE: get_data
!   Contains data reading and processing routines
!
! SUBROUTINES:
!   - read_data: Master data loading routine that reads all external data files
!
! DATA FILES READ (from Data/ directory):
!   - _data_Nn_US_*.txt: Population by age and time
!   - _data_gamma*.txt: TFP growth rates
!   - _data_pi_*.txt: Conditional survival probabilities
!   - _data_omega_*.txt: Age-efficiency profiles
!   - _data_sigma2eps_*.txt: Earnings shock variances
!   - _data_tau*.txt: Tax rate time series (L, K, C)
!   - _data_lambda.txt: Bequest tax rates
!   - _data_skill_premium.txt: College wage premium
!   - _data_college_share.txt: Population share by education
!   - _data_contrib*.txt: Pension contribution rates
!   - _data_depr.txt: Depreciation rates
!   - _data_rho_*.txt: Pension replacement rates
!   - _data_exog_rate_*.txt: Exogenous interest rates
!   - _data_gy_*.txt: Government spending ratios
!
! PROCESSING:
!   - Extends data series to full transition horizon using last available values
!   - Calculates implied survival probabilities from population data
!   - Computes cumulative TFP growth and labor efficiency measures
!   - Applies cohort and period-specific shocks and mortality patterns
!
! RETURNS:
!   Time-varying arrays (*_d suffix) for all demographic and policy variables
!===============================================================================

MODULE get_data
use global_vars
IMPLICIT NONE
CONTAINS

!-------------------------------------------------------------------------------
! SUBROUTINE: read_data
!
! PURPOSE:
!   Master data loading routine. Reads all external demographic, economic, and
!   policy data files from Data/ directory and prepares time-varying arrays.
!
! ARGUMENTS:
!   All intent(out) arrays for demographic and policy time series:
!   - omega_ss_d: Age-efficiency profile (steady state)
!   - gam_d, gam_cum_d: TFP growth (period and cumulative)
!   - zet_d: Effective labor per capita
!   - pi_d_big, pi_big_weight_d: Survival probabilities (conditional and from age 1)
!   - Nn_d_big: Population by age, type, and time
!   - jbar_d: Retirement age by period
!   - t1_d: Pension contribution rate
!   - tauL_d, tauK_d, tauC_d: Tax rates (labor, capital, consumption)
!   - lambda_d: Bequest tax rate
!   - debt_constr_d: Government debt constraint
!   - alpha_d: Capital share in production
!   - type_multiplier_d: Skill premium (college vs non-college)
!   - gy_factor_d: Government spending adjustment factor
!   - type_share_d: Population share by education type
!   - depr_d: Depreciation rate
!   - rho_d: Pension replacement rate
!   - exog_rate_d: Exogenous interest rate (if used)
!
! DATA SOURCES:
!   Reads from text files in Data/ directory. Data availability typically spans
!   1935-2100, with different end dates for different series. Missing future
!   values are filled by extending last observed value.
!
! NOTES:
!   - start_year = 1935 (model time t=1)
!   - break_index = 5 corresponds to year 1955
!   - last_data_* variables define data availability for each series
!   - Applies switch_* settings to control which data series are active
!-------------------------------------------------------------------------------
subroutine read_data(omega_ss_d, gam_d, gam_cum_d, zet_d, pi_d_big, pi_big_weight_d, Nn_d_big, jbar_d, t1_d, tauL_d, tauK_d, tauC_d, lambda_d, debt_constr_d, alpha_d, type_multiplier_d, gy_factor_d, type_share_d, depr_d, rho_d, exog_rate_d)
      integer :: bigJT
      real(dp)::  sum_N_temp , N_temp ! pop summation
      real(dp), dimension(bigT)::  N_temp_vec ! pop summation
      real(dp), dimension(bigT)::  a_d ! temp labor augmenting
      real(dp), dimension(bigJ,bigT)::  Nn_d ! total population
      real(dp), dimension(bigT)::  efficiency_t, raw_labor, eff_labor ! various measures of labor
   
      real(dp), dimension(bigJ,bigT)::  pi_implied_d ! implied probabilities
      real(dp), dimension(bigM,bigT)::  bigl_type ! for calculating labor augmenting growth
      real(dp), dimension(bigJ,bigM), intent(out) :: omega_ss_d
      real(dp), dimension(bigT), intent(out) :: gam_d, gam_cum_d, zet_d, t1_d, tauL_d, tauK_d, tauC_d, lambda_d, debt_constr_d, alpha_d, gy_factor_d, depr_d,  rho_d, exog_rate_d
     ! real(dp), dimension(bigJ, bigT), intent(out) :: Nn_d! pi_d, pi_weight_d
      real(dp), dimension(bigJ,bigM, bigT), intent(out) :: pi_d_big, pi_big_weight_d, Nn_d_big
      real(dp), dimension(bigM,bigT),  intent(out) :: type_multiplier_d, type_share_d
      integer, dimension(bigT), intent(out) :: jbar_d
      
      integer :: start_year ! first year for which we have data
      integer :: break_index ! last period for which we take data
      integer :: last_data_demo, last_data_gamma, last_data_tauL, last_data_tauK, last_data_lambda, last_data_sigma2_epsilon, last_data_debt, last_data_sl, last_data_depr, last_data_gy, last_data_type_multiplier, last_data_type_share, last_data_t1, last_data_tauC, last_data_rho, last_data_exog_rate ! number of years for which we have data --- at least for mortality, NEED to make it consistent with other datasets! THIS WORKS ONLY for J = 16!
call chdir(cwd_r)

  


! -------------------------------- FIRST YEAR? -------------------------

        start_year = 1935

        break_index = 5 ! this period corresponds this corresponds to year 1955
        
        ! end dates here correspond to our data availability
        last_data_demo = 33 ! for demography
        last_data_gamma = 34 ! for tfp
        last_data_lambda = 34 ! for lambda
        last_data_tauL = 34 ! for tauL
        last_data_tauK = 34 ! for tauK
        last_data_gy   = 34 ! for gy
        last_data_sigma2_epsilon = 15 ! for sigma2_epsilon
        last_data_debt           = 34 ! debt/gdp
        last_data_exog_rate      = 34 ! rate
        
        
        last_data_sl = 34 ! for sl
        last_data_type_multiplier= 34 ! type multipier
        last_data_type_share= 34 ! type share
        last_data_t1 = 34 ! SS contrib
        last_data_tauC = 34 ! for tauC
        last_data_depr= 34 ! for depr
        last_data_rho = 17 ! for rho
    

        
        
        

! -------------------------------- OMEGA -------------------------------
        Open(unit = 3, FILE = "_data_omega_mostdrop_hhslabinc_avghourlyhh.txt")
     
     do m = 1, bigM, 1
       do j = 1, bigJ, 1
        read(3,*) omega_ss_d(j,m)
       end do
     end do

    close(3)
    
! -------------------------------- rho -------------------------------
        Open(unit = 5, FILE = "_data_rho_1935.txt")


     if (switch_change_rho == 1) then
        ! Read all available data (allows rho to change over time)
        do i = 1, last_data_rho, 1
            read(5,*) rho_d(i)
        enddo
        rho_d(last_data_rho+1:) = rho_d(last_data_rho)

     else
        ! Freeze at break_index (no change after 1955)
        do i = 1, break_index, 1
            read(5,*) rho_d(i)
        enddo
        rho_d(break_index+1:) = rho_d(break_index)

    endif

    close(5)


! -------------------------------- rate -------------------------------
        Open(unit = 5, FILE = "_data_exog_rate_1935.txt")  

        do i = 1, last_data_exog_rate, 1
            read(5,*) exog_rate_d(i)
        enddo
        exog_rate_d(last_data_exog_rate+1:) = exog_rate_d(last_data_exog_rate)
            


    close(5)
    
      
! -------------------------------- SIGMA2_EPSILON -------------------------------
        Open(unit = 8, FILE = "_data_sigma2eps_mostdrop_hhslabinc_avghourlyhh.txt")
    
    
    ! reading sigma2_epsilon_t
     if (switch_sigma2_epsilon_t == 1) then 
        do m = 1,bigM,1
            do i = 1, last_data_sigma2_epsilon, 1
                read(8,*) sigma2_epsilon_t_big(i,m)
            enddo
            sigma2_epsilon_t_big(last_data_sigma2_epsilon+1:,m) = sigma2_epsilon_t_big(last_data_sigma2_epsilon,m)
        enddo
     elseif (switch_sigma2_epsilon_t == 0) then   
        do m = 1,bigM,1
            do i = 1, last_data_sigma2_epsilon, 1
                read(8,*) sigma2_epsilon_t_big(i,m)
            enddo
            
            last_data_sigma2_epsilon = break_index ! make it more mechanically
            sigma2_epsilon_t_big(last_data_sigma2_epsilon+1:,m) = sigma2_epsilon_t_big(last_data_sigma2_epsilon,m)
        enddo
        endif
        close(8)
        

    do m = 1,bigM,1
    sigma2_epsilon_t_big(:,m) =  sigma2_epsilon_t_big(:,m) * (1-zeta_p(m)**(2.0d0*zbar))/(1-zeta_p(m)**2.0d0) ! increased
    enddo

! -------------------------------- type multiplier - load --------------------
     Open(unit = 8, FILE = "_data_skill_premium.txt")

    ! reading type_mutliplier (skill premium)
    ! Always read all available data - freeze happens later if switch_change_premium == 0

        do m = 1,bigM,1
            do i = 1, last_data_type_multiplier, 1
                read(8,*) type_multiplier_d(m,i)
            enddo
            type_multiplier_d(m,last_data_type_multiplier+1:) = type_multiplier_d(m,last_data_type_multiplier)
        enddo

    close(8)

    ! -------------------------------- type share - load --------------------
        Open(unit = 8, FILE = "_data_college_share.txt")

    ! reading type_share (education composition)
    ! Always read all available data - freeze happens later if switch_change_type_share == 0

        do m = 1,bigM,1
            do i = 1, last_data_type_share, 1
                read(8,*) type_share_d(m,i)
            enddo
            type_share_d(m,last_data_type_share+1:) = type_share_d(m,last_data_type_share)
        enddo




  ! ensure it sums up to 1
     do i = 1,bigT,1
     type_share_d(:,i) = type_share_d(:,i)/sum(type_share_d(:,i))
     enddo
    close(8)
    
    
    
! -------------------------------- JBAR -------------------------------
      jbar_d = switch_fix_retirement_age

     
 ! -------------------------------- LABOR SHARE -------------------------------
        Open(unit = 5, FILE = "_data_labsh.txt")

    ! Always read all available data - freeze happens later if switch_change_sl == 0
         do i = 1, last_data_sl, 1
            read(5,*) alpha_d(i)
         enddo
         alpha_d(last_data_sl+1:) = alpha_d(last_data_sl)
        close(5)


    alpha_d = 1.0d0 - alpha_d / 100.0d0
    
    
    ! -------------------------------- DEPRECIATION RATE -------------------------------

        Open(unit = 5, FILE = "_data_depr.txt")


    if (switch_change_depr == 1) then
        ! Read all available data (allows depr to change over time)
        do i = 1, last_data_depr, 1
            read(5,*) depr_d(i)
        enddo
        depr_d(last_data_depr+1:) = depr_d(last_data_depr)

     else  ! switch_change_depr == 0
        ! Freeze at break_index (no change after 1955)
        do i = 1, break_index, 1
            read(5,*) depr_d(i)
        enddo
        depr_d(break_index+1:) = depr_d(break_index)
    endif
    

    ! -------------------------------- TAU_K -------------------------------

        Open(unit = 7, FILE = "_data_tauK.txt")

     if (switch_change_tauK == 1) then
        ! Read all available data (allows tauK to change over time)
        do i = 1, last_data_tauK, 1
            read(7,*) tauK_d(i)
        enddo
        tauK_d(last_data_tauK+1:) = tauK_d(last_data_tauK)

     else  ! switch_change_tauK == 0
        ! Freeze at break_index (no change after 1955)
        do i = 1, break_index, 1
            read(7,*) tauK_d(i)
        enddo
        tauK_d(break_index+1:) = tauK_d(break_index)
    endif
    close(7)

! -------------------------------- TAU_L -------------------------------
        Open(unit = 5, FILE = "_data_tauL.txt")

     if (switch_change_tauL == 1) then
        ! Read all available data (allows tauL to change over time)
        do i = 1, last_data_tauL, 1
            read(5,*) tauL_d(i)
        enddo
        tauL_d(last_data_tauL+1:) = tauL_d(last_data_tauL)

     else  ! switch_change_tauL == 0
        ! Freeze at break_index (no change after 1955)
        do i = 1, break_index, 1
            read(5,*) tauL_d(i)
        enddo
        tauL_d(break_index+1:) = tauL_d(break_index)
    endif


    close(5)
    
! -------------------------------- TAU_C -------------------------------

        Open(unit = 5, FILE = "_data_tauC.txt")

     if (switch_change_tauC == 1) then
        ! Read all available data (allows tauC to change over time)
        do i = 1, last_data_tauC, 1
            read(5,*) tauC_d(i)
        enddo
        tauC_d(last_data_tauC+1:) = tauC_d(last_data_tauC)

     else  ! switch_change_tauC == 0
        ! Freeze at break_index (no change after 1955)
        do i = 1, break_index, 1
            read(5,*) tauC_d(i)
        enddo
        tauC_d(break_index+1:) = tauC_d(break_index)
    endif

    close(5)
    
  !    -------------------------------- DEBT/GDP -------------------------------
            !set debt to 0 in all periods
            debt_constr_d = 0.0d0

    
 ! -------------------------------- LAMBDA -------------------------------


        Open(unit = 6, FILE = "_data_lambda.txt")


     if (switch_change_lambda == 1) then
        ! Read all available data (allows lambda to change over time)
        do i = 1, last_data_lambda, 1
            read(6,*) lambda_d(i)
        enddo
        lambda_d(last_data_lambda+1:) = lambda_d(last_data_lambda)

     else  ! switch_change_lambda == 0
        ! Freeze at break_index (no change after 1955)
        do i = 1, break_index, 1
            read(6,*) lambda_d(i)
        enddo
        lambda_d(break_index+1:) = lambda_d(break_index)
    endif
        
    close(6)
! -------------------------------- N & PI -------------------------------
    bigJT = bigJ*bigT
    
 ! -------------------------------- BIGJ = 16 - US
        
    if (switch_het_mortality == 0) then
    


        Open(unit = 121, FILE = "_data_pi_cond_US_since1935.txt")  
        Open(unit = 122, FILE = "_data_Nn_US_1935_2100.txt")
        Open(unit = 123, FILE = "_data_Nn_US_1935_init_old.txt")

    do i = 1,last_data_demo ,1 
            do j = 1, bigJ
                read(121,*) pi_d_big(j,1,i)
            enddo 
        read(122,*) Nn_d(1,i)
    enddo
    
    do i = last_data_demo+1, bigT, 1 
         pi_d_big(:,:,i)=  pi_d_big(:,:,last_data_demo)    
    enddo
    
    do m = 1, bigM, 1
        pi_d_big(:,m,:) =  pi_d_big(:,1,:)
    enddo

   do i = 1,last_data_demo ,1 
        
        do m = 1,bigM,1

            Nn_d_big(1,m,i) = type_share_d(m,i) * Nn_d(1,i)
        enddo
    enddo

    elseif (switch_het_mortality == 1) then
        
 
        Open(unit = 121, FILE = "_data_het_pi_US_since1935_all.txt")  
        Open(unit = 122, FILE = "_data_Nn_US_1935_2100.txt")
        Open(unit = 123, FILE = "_data_Nn_US_1935_init_old.txt")     
  
    
    do i = 1,last_data_demo ,1 
        read(122,*) Nn_d(1,i)
    enddo
    
     do m = 1,bigM,1
         do i = 1,last_data_demo,1
            do j = 1, bigJ
                read(121,*) pi_d_big(j,m,i)
            enddo 
            Nn_d_big(1,m,i) = type_share_d(m,i) * Nn_d(1,i)
        enddo
    enddo
    
    do i = last_data_demo+1, bigT, 1
        do m = 1,bigM,1
            do j = 1, bigJ
            pi_d_big(j,m,i)=  pi_d_big(j,m,last_data_demo)
            enddo
        enddo
    enddo
    
    endif
    
    close(121)
    close(122)
    close(123)

    

    ! -------------------------------- unstable demography (loaded from parameter files)
    ! nu_ss_old and nu_ss_new are now read from parameter files in set_globals.f90
    ! Typical values: nu_ss_old = 1.055 (5.5%/period), nu_ss_new = 1.003210472 (UN projection)
    
     
    ! calculate conditional probabilities

    do i = 1,bigT, 1
        do m = 1,bigM,1
            pi_d_big(1,m,i) = 1.0_dp
            do j = 2, bigJ
                pi_d_big(j,m,i) = pi_d_big(j-1,m,max(i-1,1))*pi_d_big(j,m,i)
            enddo
        enddo      
    enddo
    
    
    do j = 1, bigJ, 1
        do m = 1, bigM, 1
        if (switch_steady_demo == 1)  then !if this switch is set to 1 replace initial population from the data with something calculated by assuming that birth rate and mortality was always the same in the past
            !=Nn_d(1,1) = 1.0_dp ! temporary
            Nn_d_big(j,m,1) = nu_ss_old**(-j+1)*pi_d_big(j,m,1)/pi_d_big(1,m,1) * Nn_d_big(1,m,1)
             
        endif
        enddo
    Nn_d(j,1) = sum(Nn_d_big(j,:,1))
    enddo



    do i = last_data_demo+1, bigT, 1
        Nn_d(1,i) = Nn_d(1,i-1)*nu_ss_new
        Nn_d_big(1,:,i) = Nn_d_big(1,:,i-1)*nu_ss_new
    enddo
    
    
    
    do i = 2,bigT, 1
        do j = 2, bigJ
            do m = 1, bigM, 1
                Nn_d_big(j,m,i) = pi_d_big(j,m,i)/pi_d_big(j-1,m,i-1)*Nn_d_big(j-1,m,i-1)
            enddo
            Nn_d(j,i) = sum(Nn_d_big(j,:,i))
        enddo
    enddo



    ! pi_weight seems to be needed to calculate relative masses in steady states
    ! along the transition path these masses are handled by N
    pi_big_weight_d = pi_d_big
    !pi_weight_d = pi_d
    
    

    
    
        
   ! --------------------------------calculate GAMMA now -------------------------------
 
        Open(unit = 4, FILE = "_data_gamma.txt") 
        !Open(unit = 4, FILE = "_data_gamma_robustness.txt") 

    if (switch_go_to_lower_gamma .ne. 0) then 
        do i = 1, last_data_gamma, 1
            read(4,*) gam_d(i)
        enddo
        gam_d(last_data_gamma+1:) = gam_d(last_data_gamma)
    elseif (switch_go_to_lower_gamma == 0) then
        last_data_gamma= break_index
        do i = 1, last_data_gamma, 1
            read(4,*) gam_d(i)
        enddo
        gam_d(last_data_gamma+1:) = gam_d(last_data_gamma)
    endif
    
    gam_d = gam_d + 1.00d0 + 0.00d0
        
    close(4)
    
     if (switch_go_to_lower_gamma == -1) then !this one sets growth rate to a constant
      gam_d(:) = 1.02d0 ** 5   
     endif
     
     
    ! need to convert it to labor augmenting 
    ! this requires some assumptions about the average hours of each agent

    ! calculate effective labor in each period
    do i = 1,bigT,1
        do m = 1,bigM,1
        do j = 1,jbar_d(i)-1,1
            eff_labor(i) =  eff_labor(i) + type_multiplier_d(m,i) * (omega_ss_d(j,m)  * labor_constant * Nn_d_big(j,m,i)) ** rho_subst
            raw_labor(i) =  raw_labor(i)                                              + labor_constant * Nn_d_big(j,m,i)
        enddo   
        enddo
        eff_labor(i)    = eff_labor(i)  ** (1.0d0/rho_subst)
        efficiency_t(i) = eff_labor(i) / raw_labor(i)
    enddo
    
    ! effective labor growth

    zet_d(1) = 1
    do i = 2,bigT,1
        zet_d(i) = zet_d(i-1)*gam_d(i)    
    enddo
    
    !a_d(1) = 1 / efficiency_t(1)
    do i = 1,bigT,1
        a_d(i) = zet_d(i) **  ( 1/(1-alpha_d(i))) / efficiency_t(i) 
    enddo
    
    !gam_d(1) = gam_d(1) !** (1/(1-alpha_d(1)))  
    do i = 2,bigT,1
        gam_d(i) =  a_d(i) /  a_d(i-1)
    enddo
    
    zet_d = a_d
    
    gam_cum_d(1) = gam_d(1)
    do i = 2,bigT,1
        gam_cum_d(i) = gam_cum_d(i-1)*gam_d(i)
    enddo
    
    if (switch_go_to_lower_gamma == 2) then !this one sets growth rate used in the model to a constant
        last_data_gamma= break_index
      gam_d(last_data_gamma+1:) = gam_d(last_data_gamma)  
    endif
    
    
! --------------------------------end calculating GAMMA  -------------------------------





  ! ensure it sums up to 1
     do i = 1,bigT,1
     type_share_d(:,i) = type_share_d(:,i)/sum(type_share_d(:,i))
     enddo

! -------------------------------- fix type multiplier (skill premium)
     if (switch_change_premium == 0) then
        do m = 1,bigM,1
            type_multiplier_d(m,break_index+1:) = type_multiplier_d(m,break_index)
        enddo
     endif

! -------------------------------- fix type share (education composition)
    if (switch_change_type_share == 0) then
        do m = 1,bigM,1
            type_share_d(m,break_index+1:) = type_share_d(m,break_index)
        enddo
     endif

! -------------------------------- fix labor share
    if (switch_change_sl == 0) then
        alpha_d(break_index+1:) = alpha_d(break_index)
    endif

! recalculate population to adjust to fixed type shares
      ! -------------------------------- BIGJ = 16 - US

        
    if (switch_het_mortality == 0) then
    
    ! NEED TO MAKE THIS MORE AUTOMATIC!    

        Open(unit = 121, FILE = "_data_pi_cond_US_since1935.txt")  
        Open(unit = 122, FILE = "_data_Nn_US_1935_2100.txt")
        Open(unit = 123, FILE = "_data_Nn_US_1935_init_old.txt")

    
    do i = 1,last_data_demo ,1 
            do j = 1, bigJ
                read(121,*) pi_d_big(j,1,i)
            enddo 
        read(122,*) Nn_d(1,i)
    enddo
    
    do i = last_data_demo+1, bigT, 1 
         pi_d_big(:,:,i)=  pi_d_big(:,:,last_data_demo)    
    enddo
    
    do m = 1, bigM, 1
        pi_d_big(:,m,:) =  pi_d_big(:,1,:)
    enddo

   do i = 1,last_data_demo ,1 
        
        do m = 1,bigM,1

            Nn_d_big(1,m,i) = type_share_d(m,i) * Nn_d(1,i)
        enddo
    enddo

elseif (switch_het_mortality == 1) then
        
         
        Open(unit = 121, FILE = "_data_het_pi_US_since1935_all.txt")  
        Open(unit = 122, FILE = "_data_Nn_US_1935_2100.txt")
        Open(unit = 123, FILE = "_data_Nn_US_1935_init_old.txt")     
  
        
    do i = 1,last_data_demo ,1 
        read(122,*) Nn_d(1,i)
    enddo    
     do m = 1,bigM,1
         do i = 1,last_data_demo,1
            do j = 1, bigJ
                read(121,*) pi_d_big(j,m,i)
            enddo 
            Nn_d_big(1,m,i) = type_share_d(m,i) * Nn_d(1,i)
        enddo
    enddo
    
    do i = last_data_demo+1, bigT, 1
        do m = 1,bigM,1
            do j = 1, bigJ
            pi_d_big(j,m,i)=  pi_d_big(j,m,last_data_demo)
            enddo
        enddo
    enddo
    
endif
    
close(121)
close(122)
close(123)

    ! -------------------------------- unstable demography (loaded from parameter files)
    ! nu_ss_old and nu_ss_new are now read from parameter files in set_globals.f90
    ! NOTE: If nu_ss_old != 1, must have switch_steady_demo == 1
    
     
    ! calculate conditional probabilities

    do i = 1,bigT, 1
        do m = 1,bigM,1
            pi_d_big(1,m,i) = 1.0_dp
            do j = 2, bigJ
                pi_d_big(j,m,i) = pi_d_big(j-1,m,max(i-1,1))*pi_d_big(j,m,i)
            enddo
        enddo      
    enddo
    
    
    do j = 1, bigJ, 1
        do m = 1, bigM, 1
        if (switch_steady_demo == 1)  then !if this switch is set to 1 replace initial population from the data with something calculated by assuming that birth rate and mortality was always the same in the past
            !=Nn_d(1,1) = 1.0_dp ! temporary
            Nn_d_big(j,m,1) = nu_ss_old**(-j+1)*pi_d_big(j,m,1)/pi_d_big(1,m,1) * Nn_d_big(1,m,1)
             
        endif
        enddo
    Nn_d(j,1) = sum(Nn_d_big(j,:,1))
    enddo



    do i = last_data_demo+1, bigT, 1
        Nn_d(1,i) = Nn_d(1,i-1)*nu_ss_new
        Nn_d_big(1,:,i) = Nn_d_big(1,:,i-1)*nu_ss_new
    enddo
    
    
    
    do i = 2,bigT, 1
        do j = 2, bigJ
            do m = 1, bigM, 1
                Nn_d_big(j,m,i) = pi_d_big(j,m,i)/pi_d_big(j-1,m,i-1)*Nn_d_big(j-1,m,i-1)
            enddo
            Nn_d(j,i) = sum(Nn_d_big(j,:,i))
        enddo
    enddo



    ! pi_weight seems to be needed to calculate relative masses in steady states
    ! along the transition path these masses are handled by N
    pi_big_weight_d = pi_d_big
    !pi_weight_d = pi_d
     
    
 ! -------------------------------- SOCIAL SECURITY CONTRIBUTIONS -------------------------------
     OPEN (unit=5, FILE = "_data_contrib_to_gdp.txt")
     if (switch_change_contrib == 1) then
        ! Read all available data (allows contrib to change over time)
        do i = 1, last_data_t1, 1
            read(5,*) t1_d(i)
        enddo
        t1_d(last_data_t1+1:) = t1_d(last_data_t1)

     else  ! switch_change_contrib == 0
        ! Freeze at break_index (no change after 1955)
        do i = 1, break_index, 1
            read(5,*) t1_d(i)
        enddo
        t1_d(break_index+1:) = t1_d(break_index) 
    endif
    
    ! the above were contributions to gdp, now obtain contrib. rates:
    t1_d = t1_d / (1-alpha_d)

    close(5)
    
    
! -------------------------------- there is no mortality
if (switch_mortality == 0) then 
    pi_d_big = 1.0_dp
    
    do j = 1, bigJ, 1
        do m = 1, bigM, 1

        if (switch_steady_demo == 1)  then !if this switch is set to 1 replace initial population from the data with something calculated by assuming that birth rate and mortality was always the same in the past
            !=Nn_d(1,1) = 1.0_dp ! temporary
            Nn_d_big(j,m,1) = nu_ss_old**(-j+1)*pi_d_big(j,m,1)/pi_d_big(1,m,1) * Nn_d_big(1,m,1)
             
        endif
        enddo

    enddo
    
    
    do i = 2,bigT, 1
        do m = 1,bigM,1        
            do j = 2, bigJ
                Nn_d_big(j,m,i) = Nn_d_big(j-1,m,max(i-1,1))
            enddo
        enddo
    enddo
    
    pi_big_weight_d = pi_d_big  
    
elseif (switch_mortality == 3) then 
    do i = 2, bigT,1
        do m = 1, bigM, 1
            do j = 2, bigJ, 1   
                pi_d_big(j,m,i) = pi_d_big(j,m,1)
                Nn_d_big(j,m,i) = pi_d_big(j,m,i-1)/pi_d_big(j-1,m,max(i-2,1))*Nn_d_big(j-1,m,i-1)
            enddo    
        enddo
    enddo
            pi_big_weight_d = pi_d_big  
    
    
elseif (switch_mortality == 4) then 
    do i = 2, bigT,1
        do m = 1, bigM, 1
            do j = 2, bigJ, 1   
                pi_d_big(j,m,i) = pi_d_big(j,m,1)
            enddo    
        enddo
    enddo
    
    do i = 1, bigT,1
        do m = 1, bigM, 1
        Nn_d_big(1,m,i) = 1d0 * type_share_d(m,i)
            do j = 2, bigJ, 1   
                Nn_d_big(j,m,i) = pi_d_big(j,m,max(i-1,1))/pi_d_big(j-1,m,max(i-2,1))*Nn_d_big(j-1,m,max(i-1,1))
            enddo    
        enddo
    enddo
    
        pi_big_weight_d = pi_d_big  
     
elseif (switch_mortality == 5) then  !this changes  subjective probability of survival to the initial ones but keeps the nunber of people born equal to the data
    pi_big_weight_d = pi_d_big
    do i = 2, bigT,1
        do j = 2, bigJ, 1   
            pi_d_big(j,:,i) = pi_d_big(j,:,break_index)
        enddo    
    enddo  
    
    
elseif (switch_mortality == 6) then !this changes  objective probability  of survival to the initial ones but keeps the nunber of people born equal to the data
       
    do i = 2, bigT,1
        do m = 1, bigM, 1
            do j = 2, bigJ, 1   
                pi_d_big(j,m,i) = pi_d_big(j,m,break_index)
                Nn_d_big(j,m,i) = pi_d_big(j,m,i)/pi_d_big(j-1,m,i-1)*Nn_d_big(j-1,m,i-1) 
            enddo
        enddo
    enddo
    pi_big_weight_d = pi_d_big

  
    
  elseif (switch_mortality == 7) then ! this will keep the population structure as in the initial period  (mortality) and will let the number of j=1 agents grow at nu_ss_new rate - nu_ss is recalculated here
        
    do i = 1,bigT,1
    N_temp_vec(i) = sum(Nn_d_big(:,:,i))
    enddo
    nu_ss_new = (N_temp_vec(break_index)/N_temp_vec(break_index-1))
    
    do i = 1,bigT,1
    N_temp_vec(i) = sum(Nn_d_big(1,:,i))
    enddo
    do i = (break_index+1), bigT,1

        do m = 1, bigM, 1
        do j = 2, bigJ, 1   
            pi_d_big(j,m,i) = pi_d_big(j,m,break_index)
            pi_big_weight_d(j,m,i) = pi_d_big(j,m,i)
        enddo    
        enddo
    enddo

    do i = (break_index+1), bigT,1
        N_temp_vec(i) = N_temp_vec(i-1) * nu_ss_new 
        do m = 1, bigM, 1
        Nn_d_big(1,m,i) = N_temp_vec(i) * type_share_d(m,i)
            do j = 2, bigJ, 1   
                Nn_d_big(j,m,i) = pi_d_big(j,m,max(i-1,1))/pi_d_big(j-1,m,max(i-2,1))*Nn_d_big(j-1,m,max(i-1,1))
            enddo
        enddo    
    enddo 
    
   elseif (switch_mortality == 8) then !this keep mortality at the fixed level, but subjective probabilities are as in the data to the data
       
    do i = 2, bigT,1
        do m = 1, bigM, 1
            do j = 2, bigJ, 1   
                pi_big_weight_d(j,m,i) = pi_big_weight_d(j,m,break_index)
                Nn_d_big(j,m,i) = pi_big_weight_d(j,m,i)/pi_big_weight_d(j-1,m,i-1)*Nn_d_big(j-1,m,i-1) 
            enddo
        enddo
    enddo

    
    
endif
CLOSE(3)
CLOSE(4)
CLOSE(9)
do i = 1,bigT,1
    do j =1,bigJ,1
        Nn_d(j,i) = sum(Nn_d_big(j,:,i))
    enddo
enddo

  !!!!PZ: HACK 
      type_share_d(1,:) = 0.0d0  

call chdir(cwd_w)
open(unit = 1, file= version//experiment//closure//"population.csv")
    do i = 1,bigT,1
        write(1, '(1x, F, 16(",", F))') (Nn_d(j,i), j = 1,bigJ)
    enddo
close(1)







! SETTING TO FIXED

if (switch_keep_fixed == 1) then
    gy_factor_d(2:) = gy_factor_d(1)
    do m = 1,bigM,1
   !sigma2_epsilon_t_big(2:,m) = sigma2_epsilon_t_big(1,m)  
   sigma2_epsilon_t_big(1:,1) = sigma2_epsilon_t_big(1,1)  
   !sigma2_epsilon_t_big(1:,2) = sigma2_epsilon_t_big(1,2)  
     
    type_multiplier_d(m,:) = 1.0
    type_share_d(m,2:) = type_share_d(m,1)
    type_multiplier_d(m,2:) = type_multiplier_d(m,1)
    omega_ss_d(:,1) = omega_ss_d(1,1) 
    omega_ss_d(:,2) = omega_ss_d(1,1)
    
    enddo
   tauK_d(2:) = tauK_d(1)
    tauL_d(2:) = tauL_d(1)
    tauC_d(2:) = tauC_d(1)
    alpha_d(2:) = alpha_d(1)
    debt_constr_d(2:) = debt_constr_d(1)
    lambda_d(2:) = lambda_d(1)
    gam_d(2:) = gam_d(1)
    depr_d(2:) = depr_d(1)
    t1_d(2:) = t1_d(1)
    nu_ss_new = 1.00d0
    rho_d(2:) = rho_d(1)
    do i = 2, bigT,1
        pi_d_big(1,:,i) = pi_d_big(1,:,1)
        Nn_d_big(1,:,i) = Nn_d_big(1,:,i-1) * nu_ss_new
        do j = 2, bigJ, 1   
            pi_d_big(j,:,i) = pi_d_big(j,:,1)
            Nn_d_big(j,:,i) = pi_d_big(j,:,1)/pi_d_big(j-1,:,1)*Nn_d_big(j-1,:,i-1)
           
        enddo
     enddo
    
    do i = 1,bigT,1
    type_share_d(:,i) = type_share_d(:,i)/sum(type_share_d(:,i))
     enddo
     
     do i = 2,bigT,1
        pi_big_weight_d(:,:,i) = pi_big_weight_d(:,:,1)
     enddo
    
    !pi_weight_d = pi_d
    nu_ss_old = 1.0d0
    nu_ss_new = nu_ss_old
endif




call chdir(cwd_w)

!!! here output aggregate pi from our model
        OPEN (unit=111, FILE = "implied_pi.txt")
        do i = 1, bigT,1
        pi_implied_d(1,i) = 1.0d0
        write(111,'(F20.10)'), pi_implied_d(1,i)
        do j = 2, bigJ, 1   
            pi_implied_d(j,i) = sum(Nn_d_big(j,:,i)) / sum(Nn_d_big(j-1,:,max(i-1,1)))
        write(111,'(F20.10)'), pi_implied_d(j,i)
        enddo
        enddo
        CLOSE(111)

        
        
end subroutine read_data

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
end module  get_data