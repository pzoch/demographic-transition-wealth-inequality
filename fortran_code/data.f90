! WHAT   :  read initial data and inital values from world without the reform
! TAKE   :  data files and output files from base scenario (without reform) 
! DO     :  read data from files to variables and parameters 
! RETURN :  base variable CRUCIAL to the next run on the path 

MODULE get_data
use global_vars
IMPLICIT NONE
CONTAINS

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

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
        break_index = 5 ! this corresponds to year 1955
        !break_index = 9 !use this for tax scenarios 
        
        
        last_data_demo = 33 ! for demography
        last_data_gamma = 34 ! for tfp
        last_data_lambda = 34 ! for lambda
        last_data_tauL = 34 ! for tauL
        last_data_tauK = 34 ! for tauK
        last_data_gy = 34 ! for gy
        last_data_sigma2_epsilon = 15 ! for sigma2_epsilon
        last_data_debt           = 34 ! debt/gdp
        last_data_exog_rate          = 17 ! debt/gdp
        
        
        last_data_sl = 34 ! for sl
        last_data_type_multiplier= 34 ! type multip
        last_data_type_share= 34 ! type share
        last_data_t1 = 34 ! SS contrib
        last_data_tauC = 34 ! for tauC
        last_data_depr= 34 ! for depr
        last_data_rho = 17 ! for rho
    

        
        
        

! -------------------------------- OMEGA -------------------------------
     if (switch_wage_vs_income == 0) then
         
        !OPEN (unit=3, FILE = "_data_omega_deaton_avghourlyhh.txt")    
         !Open(unit = 3, FILE = "_data_omega_busno_drop_hhslabinc_3_avghourlyhh.txt") 
         Open(unit = 3, FILE = "_data_omega_mostdrop_hhslabinc_avghourlyhh.txt") 
     elseif (switch_wage_vs_income == 1) then
         
        OPEN (unit=3, FILE = "_data_omega_deaton_hdslabinc.txt")    
     
     endif
     
     do m = 1, bigM, 1
       do j = 1, bigJ, 1
        read(3,*) omega_ss_d(j,m)
       end do
     end do

    close(3)
    

! -------------------------------- gy -------------------------------
      
    ! Open(unit = 5, FILE = "_data_gy_1935.txt")  
    !
    !    
    ! if (switch_change_gy == 1) then 
    !    do i = 1, last_data_gy, 1
    !        read(5,*) gy_factor_d(i)
    !    enddo
    !    gy_factor_d(last_data_gy+1:) = gy_factor_d(last_data_gy)
    !        
    ! elseif (switch_change_gy == 0 .AND. switch_starting_year == 1) then
    !     last_data_gy = break_index
    !     do i = 1, last_data_gy, 1
    !        read(5,*) gy_factor_d(i)
    !    enddo
    !    gy_factor_d(last_data_gy+1:) = gy_factor_d(last_data_gy) 
    !    
    !elseif (switch_change_gy == 0.AND.switch_starting_year.NE. 1) then   
    !    read(5,*) gy_factor_d(1)
    !    gy_factor_d(2:) = gy_factor_d(1)
    !endif
    !
    !close(5)
! -------------------------------- rho -------------------------------
      
        Open(unit = 5, FILE = "_data_rho_1935.txt")  

        
     if (switch_change_rho == 1) then 
        do i = 1, last_data_rho, 1
            read(5,*) rho_d(i)
        enddo
        rho_d(last_data_rho+1:) = rho_d(last_data_rho)
            
     else
         rho_d(:) = rho_d(1)

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
    !zeta_p = 0.985d0
    !zeta_p(1)  =  0.9640d0
    !zeta_p(2)  =  0.9799d0

    
    if (switch_wage_vs_income == 0) then
    
        !Open(unit = 8, FILE = "_data_sigma2eps_deaton_avghourlyhh.txt")  
        !Open(unit = 8, FILE = "_data_sigma2eps_busno_drop_hhslabinc_3_avghourlyhh.txt")  
        Open(unit = 8, FILE = "_data_sigma2eps_mostdrop_hhslabinc_avghourlyhh.txt")  
    
    elseif (switch_wage_vs_income == 1) then
        
        Open(unit = 8, FILE = "_data_sigma2eps_deaton_hdslabinc.txt")  
        
    endif
    
    
    ! reading sigma2_epsilon_t
     if (switch_sigma2_epsilon_t == 1) then 
        do m = 1,bigM,1
            do i = 1, last_data_sigma2_epsilon, 1
                read(8,*) sigma2_epsilon_t_big(i,m)
            enddo
            sigma2_epsilon_t_big(last_data_sigma2_epsilon+1:,m) = sigma2_epsilon_t_big(last_data_sigma2_epsilon,m)
        enddo
     elseif (switch_sigma2_epsilon_t == 0.AND.switch_starting_year == 1) then   

        do m = 1,bigM,1
            do i = 1, last_data_sigma2_epsilon, 1
                read(8,*) sigma2_epsilon_t_big(i,m)
            enddo
            
            last_data_sigma2_epsilon = break_index ! make it more mechanically
            sigma2_epsilon_t_big(last_data_sigma2_epsilon+1:,m) = sigma2_epsilon_t_big(last_data_sigma2_epsilon,m)
        enddo

     elseif (switch_sigma2_epsilon_t == 0.AND.switch_starting_year .NE. 1) then
        do m = 1,bigM,1 
            read(8,*) sigma2_epsilon_t_big(1,m)
             sigma2_epsilon_t_big(2:,m) = sigma2_epsilon_t_big(1,m)
        enddo
        
        endif
        close(8)
        

    do m = 1,bigM,1
    sigma2_epsilon_t_big(:,m) =  sigma2_epsilon_t_big(:,m) * (1-zeta_p(m)**(2.0d0*zbar))/(1-zeta_p(m)**2.0d0) ! increased
    enddo

! -------------------------------- type multiplier - load --------------------
    

  
     Open(unit = 8, FILE = "_data_skill_premium.txt")  

    ! reading type_mutliplier
    
     
        do m = 1,bigM,1
            do i = 1, last_data_type_multiplier, 1
                read(8,*) type_multiplier_d(m,i)
            enddo
            type_multiplier_d(m,last_data_type_multiplier+1:) = type_multiplier_d(m,last_data_type_multiplier)
        enddo

    close(8)

    ! -------------------------------- type share - load --------------------
    
    
        Open(unit = 8, FILE = "_data_college_share.txt")  

    ! reading type_share
    
     
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

         do i = 1, last_data_sl, 1
            read(5,*) alpha_d(i)
         enddo
         
         alpha_d(last_data_sl+1:) = alpha_d(last_data_sl)
        close(5)
     
    
    alpha_d = 1.0d0 - alpha_d / 100.0d0
    
    

    

    
    ! -------------------------------- DEPRECIATION RATE -------------------------------
    
        Open(unit = 5, FILE = "_data_depr.txt")  
    
        
    if (switch_change_depr == 1) then 
        do i = 1, last_data_sl, 1
            read(5,*) depr_d(i)
        enddo
        depr_d(last_data_depr+1:) = depr_d(last_data_depr)
            
     elseif (switch_change_depr == 0 .AND. switch_starting_year == 1) then
         last_data_sl = break_index
         do i = 1, last_data_depr, 1
            read(5,*) depr_d(i)
        enddo
        depr_d(last_data_depr+1:) = depr_d(last_data_depr) 
        
    elseif (switch_change_depr == 0.AND.switch_starting_year.NE. 1) then   
        read(5,*) depr_d(1)
        depr_d(2:) = depr_d(1)
    endif
    

    ! -------------------------------- TAU_K -------------------------------    

        Open(unit = 7, FILE = "_data_tauK.txt")  
        
     if (switch_change_tauK == 1) then 
        do i = 1, last_data_tauK, 1
            read(7,*) tauK_d(i)
        enddo
        tauK_d(last_data_tauK+1:) = tauK_d(last_data_tauK)
            
     elseif (switch_change_tauK == 0.AND. switch_starting_year == 1) then
        last_data_tauK = break_index
        do i = 1, last_data_tauK, 1
            read(7,*) tauK_d(i)
        enddo
        tauK_d(last_data_tauK+1:) = tauK_d(last_data_tauK)  
         
     elseif (switch_change_tauK == 0.AND. switch_starting_year .NE. 1) then    
        read(7,*) tauK_d(1)
        tauK_d(2:) = tauK_d(1)
    endif
    close(7)

! -------------------------------- TAU_L -------------------------------
    
        Open(unit = 5, FILE = "_data_tauL.txt")  
        
     if (switch_change_tauL == 1) then 
        do i = 1, last_data_tauL, 1
            read(5,*) tauL_d(i)
        enddo
        tauL_d(last_data_tauL+1:) = tauL_d(last_data_tauL)
            
     elseif (switch_change_tauL == 0 .AND. switch_starting_year == 1) then
         last_data_tauL = break_index
         do i = 1, last_data_tauL, 1
            read(5,*) tauL_d(i)
        enddo
        tauL_d(last_data_tauL+1:) = tauL_d(last_data_tauL) 
        
    elseif (switch_change_tauL == 0.AND.switch_starting_year.NE. 1) then   
        read(5,*) tauL_d(1)
        tauL_d(2:) = tauL_d(1)
    endif
        
    
    ! adjust for social security contributions
    ! tau_L_data = tau_L_true * (1-tau_ss) + tau_ss 
    ! tauL_d = (tauL_d - t1_d)/(1-t1_d)
    
    close(5)
    
! -------------------------------- TAU_C -------------------------------
  
        Open(unit = 5, FILE = "_data_tauC.txt")  
        
     if (switch_change_tauC == 1) then 
        do i = 1, last_data_tauC, 1
            read(5,*) tauC_d(i)
        enddo
        tauC_d(last_data_tauC+1:) = tauC_d(last_data_tauC)
            
     elseif (switch_change_tauC == 0 .AND. switch_starting_year == 1) then
         last_data_tauC = break_index
         do i = 1, last_data_tauC, 1
            read(5,*) tauC_d(i)
        enddo
        tauC_d(last_data_tauC+1:) = tauC_d(last_data_tauC) 
        
    elseif (switch_change_tauC == 0.AND.switch_starting_year.NE. 1) then   
        read(5,*) tauC_d(1)
        tauC_d(2:) = tauC_d(1)
    endif
        
    close(5)
    
  !    -------------------------------- DEBT/GDP -------------------------------
        if (switch_no_debt == 1) then
            !if there is switch_no_debt == 1 set debt to 0 in all periods
            
            debt_constr_d = 0.0d0
        else
    
    
        Open(unit = 5, FILE = "_data_debt_1935.txt")  
        
     if (switch_change_debt == 1) then 
        do i = 1, last_data_debt, 1
            read(5,*) debt_constr_d(i)
        enddo
        debt_constr_d(last_data_debt+1:) = debt_constr_d(last_data_debt)
            
     elseif (switch_change_debt == 0 .AND. switch_starting_year == 1) then
         last_data_debt = break_index
         do i = 1, last_data_debt, 1
            read(5,*) debt_constr_d(i)
        enddo
        debt_constr_d(last_data_debt+1:) = debt_constr_d(last_data_debt) 
        
    elseif (switch_change_debt == 0.AND.switch_starting_year.NE. 1) then   
        read(5,*) debt_constr_d(1)
        debt_constr_d(2:) = debt_constr_d(1)
    endif
        debt_constr_d = debt_constr_d/100   / zbar
    close(5)
    
        if (switch_no_debt == 2) then
                !if there is switch_no_debt == 2 shift debt so that it is 0 in the first period
        debt_constr_d = debt_constr_d - debt_constr_d(1)
        endif
        
        endif
        

    

    


     
    
 ! -------------------------------- LAMBDA -------------------------------
  

        Open(unit = 6, FILE = "_data_lambda.txt")      
        
    
     if (switch_change_lambda == 1) then 
        do i = 1, last_data_lambda, 1
            read(6,*) lambda_d(i)
        enddo
        lambda_d(last_data_lambda+1:) = lambda_d(last_data_lambda)
            
     elseif (switch_change_lambda == 0 .AND. switch_starting_year == 1 ) then
        last_data_lambda = break_index
        do i = 1, last_data_lambda+1, 1
            read(6,*) lambda_d(i)
        enddo
        lambda_d(last_data_lambda+1:) = lambda_d(last_data_lambda)
        
    elseif (switch_change_lambda == 0 .AND. switch_starting_year .NE. 1 ) then   
        read(6,*) lambda_d(1)
        lambda_d(2:) = lambda_d(1)
    endif
        
    close(6)
! -------------------------------- N & PI -------------------------------
    bigJT = bigJ*bigT
    
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

    

    
    ! -------------------------------- unstable demography
    if (switch_unstable_dem_ss == 1) then 

    !THESE THINGS DO NOT WORK IF NU_SS_OLD IS ~= 1, unless we switch_steady_demo == 1
    nu_ss_old =  1.055_dp!1.032998466_dp
    nu_ss_new =  1.003210472_dp  ! base on UN leads 
    
    elseif (switch_unstable_dem_ss == 0) then 
    nu_ss_old = 1.0_dp
    nu_ss_new = 1.0_dp  

    elseif (switch_unstable_dem_ss == -1) then 
    nu_ss_old =  1.055_dp!1.032998466_dp ! this gives us a good fit
    nu_ss_new =  1.055_dp   ! assume it remained constant
    endif
    
     
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


    if (switch_go_to_lower_gamma .ne. 0) then 
        do i = 1, last_data_gamma, 1
            read(4,*) gam_d(i)
        enddo
        gam_d(last_data_gamma+1:) = gam_d(last_data_gamma)
    elseif (switch_go_to_lower_gamma == 0 .AND. switch_starting_year == 1) then
        last_data_gamma= break_index
        do i = 1, last_data_gamma, 1
            read(4,*) gam_d(i)
        enddo
        gam_d(last_data_gamma+1:) = gam_d(last_data_gamma)
        
    elseif (switch_go_to_lower_gamma == 0 .AND. switch_starting_year .NE. 1) then
        read(4,*) gam_d(1)
        gam_d(2:) = gam_d(1)
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
    
    
         

! -------------------------------- fix type multiplier
     if (switch_change_premium == 0.AND.switch_starting_year == 1) then   

        do m = 1,bigM,1
        last_data_type_multiplier = break_index
             type_multiplier_d(m,last_data_type_multiplier+1:) = type_multiplier_d(m,last_data_type_multiplier)  
        enddo
             
     elseif (switch_change_premium == 0.AND.switch_starting_year .NE. 1) then
        do m = 1,bigM,1 
            last_data_type_multiplier = 1
            
             type_multiplier_d(m,last_data_type_multiplier+1:) = type_multiplier_d(m,last_data_type_multiplier) 
        enddo
        
     endif
    
! -------------------------------- fix type share
     
     
    if (switch_change_type_share == 0.AND.switch_starting_year == 1) then   
            last_data_type_share = break_index
            do m = 1,bigM,1
                type_share_d(m,last_data_type_share+1:) = type_share_d(m,last_data_type_share)  
            enddo
        
  
     elseif (switch_change_type_share == 0.AND.switch_starting_year .NE. 1) then
        last_data_type_share = 1
        do m = 1,bigM,1 
            type_share_d(m,last_data_type_share+1:) = type_share_d(m,last_data_type_share)  
        enddo
        
     endif
     
  ! ensure it sums up to 1
     do i = 1,bigT,1
     type_share_d(:,i) = type_share_d(:,i)/sum(type_share_d(:,i))
     enddo
 
  
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

    ! -------------------------------- unstable demography
    if (switch_unstable_dem_ss == 1) then 

    !THESE THINGS DO NOT WORK IF NU_SS_OLD IS ~= 1, unless we switch_steady_demo == 1
    nu_ss_old =  1.055_dp!1.032998466_dp
    nu_ss_new =  1.003210472_dp  ! base on UN leads 
    
    elseif (switch_unstable_dem_ss == 0) then 
    nu_ss_old = 1.0_dp
    nu_ss_new = 1.0_dp  

    elseif (switch_unstable_dem_ss == -1) then 
    nu_ss_old =  1.055_dp!1.032998466_dp ! this gives us a good fit
    nu_ss_new =  1.055_dp   ! assume it remained constant
    endif
    
     
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
    
! -------------------------------- fix labor share    
    
    Open(unit = 5, FILE = "_data_labsh.txt")    
    if (switch_change_sl == 0 .AND. switch_starting_year == 1) then
         last_data_sl = break_index
         do i = 1, last_data_sl, 1
            read(5,*) alpha_d(i)
        enddo
        alpha_d(last_data_sl+1:) = alpha_d(last_data_sl) 
        alpha_d = 1.0d0 - alpha_d / 100.0d0
        
    elseif (switch_change_sl == 0.AND.switch_starting_year.NE. 1) then   
        read(5,*) alpha_d(1)
        alpha_d(2:) = alpha_d(1)
        alpha_d = 1.0d0 - alpha_d / 100.0d0
    endif
     
    
 ! -------------------------------- SOCIAL SECURITY CONTRIBUTIONS -------------------------------
     OPEN (unit=5, FILE = "_data_contrib_to_gdp.txt")    
     if (switch_change_contrib == 1) then 
        do i = 1, last_data_t1, 1
            read(5,*) t1_d(i) 
        enddo
        t1_d(last_data_t1+1:) = t1_d(last_data_t1)
            
     elseif (switch_change_contrib == 0 .AND. switch_starting_year == 1) then
         last_data_t1 = break_index
         do i = 1, last_data_t1, 1
            read(5,*) t1_d(i)
        enddo
        t1_d(last_data_t1+1:) = t1_d(last_data_t1) 
        
    elseif (switch_change_contrib == 0.AND.switch_starting_year.NE. 1) then   
        read(5,*) t1_d(1)
        t1_d(2:) = t1_d(1)
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
     
elseif (switch_mortality == 5.AND. switch_starting_year .NE.1) then  !this changes subjective probability of survival to the initial ones but keeps the nunber of people born as in the data
    pi_big_weight_d = pi_d_big
    do i = 2, bigT,1
        do j = 2, bigJ, 1   
            pi_d_big(j,:,i) = pi_d_big(j,:,1)
        enddo    
    enddo
    

  
elseif (switch_mortality == 5.AND. switch_starting_year ==1) then  !this changes  subjective probability of survival to the initial ones but keeps the nunber of people born equal to the data
    pi_big_weight_d = pi_d_big
    do i = 2, bigT,1
        do j = 2, bigJ, 1   
            pi_d_big(j,:,i) = pi_d_big(j,:,break_index)
        enddo    
    enddo  
    
    
elseif (switch_mortality == 6.AND. switch_starting_year .NE.1) then !this changes  objective probability  of survival to the initial ones but keeps the nunber of people born equal to the data
       
    do i = 2, bigT,1
        do m = 1, bigM, 1
            do j = 2, bigJ, 1   
                pi_d_big(j,m,i) = pi_d_big(j,m,break_index)
                Nn_d_big(j,m,i) = pi_d_big(j,m,i)/pi_d_big(j-1,m,i-1)*Nn_d_big(j-1,m,i-1) 
            enddo
        enddo
    enddo
    pi_big_weight_d = pi_d_big
    
   elseif (switch_mortality == 6.AND. switch_starting_year ==1) then !this changes  objective probability  of survival to the initial ones but keeps the nunber of people born equal to the data
       
    do i = 2, bigT,1
        do m = 1, bigM, 1
            do j = 2, bigJ, 1   
                pi_d_big(j,m,i) = pi_d_big(j,m,break_index)
                Nn_d_big(j,m,i) = pi_d_big(j,m,i)/pi_d_big(j-1,m,i-1)*Nn_d_big(j-1,m,i-1) 
            enddo
        enddo
    enddo
    pi_big_weight_d = pi_d_big

  
    
  elseif (switch_mortality == 7 .AND. switch_starting_year .NE.1) then ! this will keep the population structure as in the initial period (mortality) and will let the number of j=1 agents grow at nu_ss_new rate
    
    do i = 2, bigT,1
        do m = 1, bigM, 1
            do j = 2, bigJ, 1   
                pi_d_big(j,m,i) = pi_d_big(j,m,1)
                pi_big_weight_d(j,m,i) = pi_d_big(j,m,i)
            enddo    
        enddo
    enddo
    
    do i = 2, bigT,1
        do m = 1, bigM, 1
        Nn_d_big(1,m,i) = Nn_d_big(1,m,i-1) * nu_ss_new * type_share_d(m,i) / type_share_d(m,i-1)
            do j = 2, bigJ, 1   
                Nn_d_big(j,m,i) = pi_d_big(j,m,max(i-1,1))/pi_d_big(j-1,m,max(i-2,1))*Nn_d_big(j-1,m,max(i-1,1))
            enddo    
        enddo
    enddo
    
    
  elseif (switch_mortality == 7 .AND. switch_starting_year ==1) then ! this will keep the population structure as in the initial period  (mortality) and will let the number of j=1 agents grow at nu_ss_new rate - nu_ss is recalculated here
        
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
    
    elseif (switch_mortality == 8.AND. switch_starting_year .NE.1) then !this keep mortality at the fixed level, but subjective probabilities are as in the data
       
    do i = 2, bigT,1
        do m = 1, bigM, 1
            do j = 2, bigJ, 1   
                pi_big_weight_d(j,m,i) = pi_big_weight_d(j,m,break_index)
                Nn_d_big(j,m,i) = pi_big_weight_d(j,m,i)/pi_big_weight_d(j-1,m,i-1)*Nn_d_big(j-1,m,i-1) 
            enddo
        enddo
    enddo
    
   elseif (switch_mortality == 8.AND. switch_starting_year ==1) then !this keep mortality at the fixed level, but subjective probabilities are as in the data to the data
       
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