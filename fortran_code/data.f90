! WHAT   :  read initial data and inital values from world without the reform
! TAKE   :  data files and output files from base scenario (without reform) 
! DO     :  read data from files to variables and parameters 
! RETURN :  base variable CRUCIAL to the next run on the path 

MODULE get_data
use global_vars
IMPLICIT NONE
CONTAINS

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine read_data(omega_ss_d, gam_d, gam_cum_d, zet_d, pi_d_big, pi_big_weight_d, Nn_d_big, jbar_d, tauL_d, tauK_d, lambda_d, debt_constr_d, alpha_d, type_multiplier_d, gy_factor_d, type_share_d)
      integer :: bigJT
      real(dp)::  sum_N_temp , N_temp ! pop summation
      real(dp), dimension(bigT)::  N_temp_vec ! pop summation
      real(dp), dimension(bigT)::  a_d ! temp labor augmenting
      real(dp), dimension(bigJ,bigT)::  Nn_d ! total population
      real(dp), dimension(bigT)::  efficiency_t, raw_labor, eff_labor ! various measures of labor
   
      real(dp), dimension(bigJ,bigT)::  pi_implied_d ! implied probabilities
      real(dp), dimension(bigM,bigT)::  bigl_type ! for calculating labor augmenting growth
      real(dp), dimension(bigJ,bigM), intent(out) :: omega_ss_d
      real(dp), dimension(bigT), intent(out) :: gam_d, gam_cum_d, zet_d, tauL_d, tauK_d, lambda_d, debt_constr_d, alpha_d, gy_factor_d
     ! real(dp), dimension(bigJ, bigT), intent(out) :: Nn_d! pi_d, pi_weight_d
      real(dp), dimension(bigJ,bigM, bigT), intent(out) :: pi_d_big, pi_big_weight_d, Nn_d_big
      real(dp), dimension(bigM,bigT),  intent(out) :: type_multiplier_d, type_share_d
      integer, dimension(bigT), intent(out) :: jbar_d
      
      integer :: start_year ! first year for which we have data
      integer :: last_data, last_data_gamma, last_data_tauL, last_data_tauK, last_data_lambda, last_data_sigma2_epsilon, last_data_debt, last_data_sl, last_data_gy, last_data_type_multiplier, last_data_type_share ! number of years for which we have data --- at least for mortality, NEED to make it consistent with other datasets! THIS WORKS ONLY for J = 16!
call chdir(cwd_r)

  
OPEN (unit=9, FILE = "_data_jbar.txt")


! -------------------------------- FIRST YEAR? -------------------------

    if (switch_starting_year == 0) then 
        start_year = 1935
        last_data = 33 ! for demography
        last_data_gamma = 17 ! for tfp
        last_data_lambda = 17 ! for lambda
        last_data_tauL = 17 ! for tauL
        last_data_tauK = 17 ! for tauK
        last_data_sl = 17 ! for sl
        last_data_sigma2_epsilon = 15 ! for sigma2_epsilon
        last_data_debt           = 19 ! debt/gdp
        last_data_type_multiplier= 17 ! type multip
        last_data_type_share= 17 ! type share
    elseif (switch_starting_year == 1) then
        start_year = 1960
        last_data = 28 ! for demography
        last_data_gamma = 12 ! for tfp
        last_data_lambda = 12 ! for lambda
        last_data_tauL = 12 ! for tauL
        last_data_tauK = 12 ! for tauK
        last_data_sl = 12 ! for sl
        last_data_sigma2_epsilon = 12 ! for sigma2_epsilon
        last_data_type_multiplier= 12 ! type multip
        last_data_type_share= 12 ! type share
     elseif (switch_starting_year == 2) then
        start_year = 1950
        last_data = 30 ! for demography
        last_data_gamma = 14 ! for tfp
        last_data_lambda = 14 ! for lambda
        last_data_tauL = 14 ! for tauL    
        last_data_tauK = 14 ! for tauK
        last_data_sigma2_epsilon = 14 ! for sigma2_epsilon
        last_data_type_multiplier= 14 ! type multip
        last_data_type_share= 14 ! type share
    elseif (switch_starting_year == 3) then
        start_year = 1935
        last_data = 33 ! for demography
        last_data_gamma = 25 ! for tfp
        last_data_lambda = 17 ! for lambda
        last_data_tauL = 17 ! for tauL
        last_data_tauK = 17 ! for tauK
        last_data_gy = 17 ! for gy
        last_data_sigma2_epsilon = 15 ! for sigma2_epsilon
        last_data_debt           = 19 ! debt/gdp
        last_data_sl = 17 ! for sl
        last_data_type_multiplier= 17 ! type multip
        last_data_type_share= 17 ! type share
    endif
    

! -------------------------------- OMEGA -------------------------------
     OPEN (unit=3, FILE = "_data_omega_jeden.txt")    
     do m = 1, bigM, 1
       do j = 1, bigJ, 1
        read(3,*) omega_ss_d(j,m)
       end do
    end do


    close(3)
! -------------------------------- gy -------------------------------
      
        Open(unit = 5, FILE = "_data_gy_1935.txt")  

        
     if (switch_change_gy == 1) then 
        do i = 1, last_data_gy, 1
            read(5,*) gy_factor_d(i)
        enddo
        gy_factor_d(last_data_gy+1:) = gy_factor_d(last_data_gy)
            
     elseif (switch_change_gy == 0 .AND. switch_starting_year == 3) then
         last_data_gy = 5
         do i = 1, last_data_gy, 1
            read(5,*) gy_factor_d(i)
        enddo
        gy_factor_d(last_data_gy+1:) = gy_factor_d(last_data_gy) 
        
    elseif (switch_change_gy == 0.AND.switch_starting_year.NE. 3) then   
        read(5,*) gy_factor_d(1)
        gy_factor_d(2:) = gy_factor_d(1)
    endif

    close(5)

      
      
! -------------------------------- SIGMA2_EPSILON -------------------------------
    !zeta_p = 0.985d0
    !zeta_p(1)  =  0.9640d0
    !zeta_p(2)  =  0.9799d0
     if (switch_starting_year == 0) then 
        Open(unit = 8, FILE = "_data_sigma2eps_1935.txt")  

    elseif (switch_starting_year == 1) then
        Open(unit = 8, FILE = "_data_sigma2eps_1960.txt")  

    elseif (switch_starting_year == 2) then
        Open(unit = 8, FILE = "_data_sigma2eps_1950.txt")  
    
    elseif (switch_starting_year == 3) then
        Open(unit = 8, FILE = "_data_sigma2eps_deaton_1935.txt")  
    endif
    
    ! reading sigma2_epsilon_t
     if (switch_sigma2_epsilon_t == 1) then 
        do m = 1,bigM,1
            do i = 1, last_data_sigma2_epsilon, 1
                read(8,*) sigma2_epsilon_t_big(i,m)
            enddo
            sigma2_epsilon_t_big(last_data_sigma2_epsilon+1:,m) = sigma2_epsilon_t_big(last_data_sigma2_epsilon,m)
        enddo
     elseif (switch_sigma2_epsilon_t == 0.AND.switch_starting_year == 3) then   

        do m = 1,bigM,1
            do i = 1, last_data_sigma2_epsilon, 1
                read(8,*) sigma2_epsilon_t_big(i,m)
            enddo
            
            last_data_sigma2_epsilon = 5
            sigma2_epsilon_t_big(last_data_sigma2_epsilon+1:,m) = sigma2_epsilon_t_big(last_data_sigma2_epsilon,m)
        enddo

        
        
       
       
     elseif (switch_sigma2_epsilon_t == 0.AND.switch_starting_year .NE. 3) then
        do m = 1,bigM,1 
            read(8,*) sigma2_epsilon_t_big(1,m)
             sigma2_epsilon_t_big(2:,m) = sigma2_epsilon_t_big(1,m)
        enddo
        
    endif
    close(8)

    do m = 1,bigM,1
    sigma2_epsilon_t_big(:,m) =  sigma2_epsilon_t_big(:,m) * (1-zeta_p(m)**(2.0d0*zbar))/(1-zeta_p(m)**2.0d0) ! increased
    enddo

! -------------------------------- type multiplier --------------------
    
       if (switch_starting_year == 0) then 
        Open(unit = 8, FILE = "_data_type_mutliplier_1935.txt")  

    elseif (switch_starting_year == 1) then
        Open(unit = 8, FILE = "_data_type_mutliplier_1960.txt")  

    elseif (switch_starting_year == 2) then
        Open(unit = 8, FILE = "_data_type_mutliplier_1950.txt")  
    
    elseif (switch_starting_year == 3) then
        Open(unit = 8, FILE = "_data_type_mutliplier_1935.txt")  
    endif
    
    ! reading type_mutliplier
    
     
        do m = 1,bigM,1
            do i = 1, last_data_type_multiplier, 1
                read(8,*) type_multiplier_d(m,i)
            enddo
            type_multiplier_d(m,last_data_type_multiplier+1:) = type_multiplier_d(m,last_data_type_multiplier)
        enddo
        


     if (switch_change_premium == 0.AND.switch_starting_year == 3) then   

        do m = 1,bigM,1
    last_data_type_multiplier = 5
             type_multiplier_d(m,last_data_type_multiplier+1:) = type_multiplier_d(m,last_data_type_multiplier)  
        enddo
        
      
       
       
     elseif (switch_change_premium == 0.AND.switch_starting_year .NE. 3) then
        do m = 1,bigM,1 
            last_data_type_multiplier = 1
            
             type_multiplier_d(m,last_data_type_multiplier+1:) = type_multiplier_d(m,last_data_type_multiplier) 
        enddo
        
    endif
    close(8)

    ! -------------------------------- type share --------------------
    
    if (switch_starting_year == 0) then 
        Open(unit = 8, FILE = "_data_type_share_1935.txt")  

    elseif (switch_starting_year == 1) then
        Open(unit = 8, FILE = "_data_type_share_1960.txt")  

    elseif (switch_starting_year == 2) then
        Open(unit = 8, FILE = "_data_type_share_1950.txt")  
    
    elseif (switch_starting_year == 3) then
        Open(unit = 8, FILE = "_data_type_share_1935.txt")  
    endif
    
    ! reading type_share
    
     
        do m = 1,bigM,1
            do i = 1, last_data_type_share, 1
                read(8,*) type_share_d(m,i)
            enddo
            type_share_d(m,last_data_type_share+1:) = type_share_d(m,last_data_type_share)
        enddo
    
        if (switch_change_type_share == 0.AND.switch_starting_year == 3) then   
            last_data_type_share = 5
            do m = 1,bigM,1
                type_share_d(m,last_data_type_share+1:) = type_share_d(m,last_data_type_share)  
            enddo
        
       
       
       
     elseif (switch_change_type_share == 0.AND.switch_starting_year .NE. 3) then
        last_data_type_share = 1
        do m = 1,bigM,1 
            type_share_d(m,last_data_type_share+1:) = type_share_d(m,last_data_type_share)  
        enddo
        
     endif
     
  ! ensure it sums up to 1
     do i = 1,bigT,1
     type_share_d(:,i) = type_share_d(:,i)/sum(type_share_d(:,i))
     enddo
    close(8)
    
    
    
! -------------------------------- JBAR -------------------------------

  
      jbar_d = switch_fix_retirement_age

    
! -------------------------------- TAU_K -------------------------------    
     if (switch_starting_year == 0) then 
        Open(unit = 7, FILE = "_data_tauK_1935.txt")  

    elseif (switch_starting_year == 1) then
        Open(unit = 7, FILE = "_data_tauK_1960.txt")  

    elseif (switch_starting_year == 2) then
        Open(unit = 7, FILE = "_data_tauK_1950.txt")  
        
    elseif (switch_starting_year == 3) then
        Open(unit = 7, FILE = "_data_tauK_1935.txt")  
    endif
        
     if (switch_change_tauK == 1) then 
        do i = 1, last_data_tauK, 1
            read(7,*) tauK_d(i)
        enddo
        tauK_d(last_data_tauK+1:) = tauK_d(last_data_tauK)
            
     elseif (switch_change_tauK == 0.AND. switch_starting_year == 3) then
        last_data_tauK = 5
        do i = 1, last_data_tauK, 1
            read(7,*) tauK_d(i)
        enddo
        tauK_d(last_data_tauK+1:) = tauK_d(last_data_tauK)  
         
     elseif (switch_change_tauK == 0.AND. switch_starting_year .NE. 3) then    
        read(7,*) tauK_d(1)
        tauK_d(2:) = tauK_d(1)
    endif
    close(7)

! -------------------------------- TAU_L -------------------------------
    if (switch_starting_year == 0) then 
        Open(unit = 5, FILE = "_data_tauL_1935.txt")  

    elseif (switch_starting_year == 1) then
        Open(unit = 5, FILE = "_data_tauL_1960.txt")  

    elseif (switch_starting_year == 2) then
        Open(unit = 5, FILE = "_data_tauL_1950.txt")  
        
    elseif (switch_starting_year == 3) then
        Open(unit = 5, FILE = "_data_tauL_1935.txt")  
    endif
        
     if (switch_change_tauL == 1) then 
        do i = 1, last_data_tauL, 1
            read(5,*) tauL_d(i)
        enddo
        tauL_d(last_data_tauL+1:) = tauL_d(last_data_tauL)
            
     elseif (switch_change_tauL == 0 .AND. switch_starting_year == 3) then
         last_data_tauL = 5
         do i = 1, last_data_tauL, 1
            read(5,*) tauL_d(i)
        enddo
        tauL_d(last_data_tauL+1:) = tauL_d(last_data_tauL) 
        
    elseif (switch_change_tauL == 0.AND.switch_starting_year.NE. 3) then   
        read(5,*) tauL_d(1)
        tauL_d(2:) = tauL_d(1)
    endif
        
    close(5)
    
    
    ! -------------------------------- LABOR SHARE -------------------------------
    if (switch_starting_year == 0) then 
        Open(unit = 5, FILE = "_data_sl_1935.txt")  

    elseif (switch_starting_year == 1) then
        Open(unit = 5, FILE = "_data_sl_1960.txt")  

    elseif (switch_starting_year == 2) then
        Open(unit = 5, FILE = "_data_sl_1950.txt")  
        
    elseif (switch_starting_year == 3) then
        Open(unit = 5, FILE = "_data_sl_1935.txt")  
    endif
        
    if (switch_change_sl == 1) then 
        do i = 1, last_data_sl, 1
            read(5,*) alpha_d(i)
        enddo
        alpha_d(last_data_sl+1:) = alpha_d(last_data_sl)
            
     elseif (switch_change_sl == 0 .AND. switch_starting_year == 3) then
         last_data_sl = 5
         do i = 1, last_data_sl, 1
            read(5,*) alpha_d(i)
        enddo
        alpha_d(last_data_sl+1:) = alpha_d(last_data_sl) 
        
    elseif (switch_change_sl == 0.AND.switch_starting_year.NE. 3) then   
        read(5,*) alpha_d(1)
        alpha_d(2:) = alpha_d(1)
    endif
    

    
    alpha_d = 1.0d0 - alpha_d / 100.0d0
    
    
    close(5)
    
    if (switch_change_sl == -1) then
        alpha_d(1:) = 0.35d0
        
    endif
    
  !    -------------------------------- DEBT/GDP -------------------------------
    if (switch_starting_year == 0) then 
        Open(unit = 5, FILE = "_data_debt_1935.txt")  

    elseif (switch_starting_year == 1) then
        Open(unit = 5, FILE = "_data_debt_1960.txt")  

    elseif (switch_starting_year == 2) then
        Open(unit = 5, FILE = "_data_debt_1950.txt")  
        
    elseif (switch_starting_year == 3) then
        Open(unit = 5, FILE = "_data_debt_1935.txt")  
    endif
        
     if (switch_change_debt == 1) then 
        do i = 1, last_data_debt, 1
            read(5,*) debt_constr_d(i)
        enddo
        debt_constr_d(last_data_debt+1:) = debt_constr_d(last_data_debt)
            
     elseif (switch_change_debt == 0 .AND. switch_starting_year == 3) then
         last_data_debt = 5
         do i = 1, last_data_debt, 1
            read(5,*) debt_constr_d(i)
        enddo
        debt_constr_d(last_data_debt+1:) = debt_constr_d(last_data_debt) 
        
    elseif (switch_change_debt == 0.AND.switch_starting_year.NE. 3) then   
        read(5,*) debt_constr_d(1)
        debt_constr_d(2:) = debt_constr_d(1)
    endif
        debt_constr_d = debt_constr_d/100   / zbar
    close(5)
    
    
    
 ! -------------------------------- LAMBDA -------------------------------
    if (switch_starting_year == 0) then 
        Open(unit = 6, FILE = "_data_lambda_1935.txt")  

    elseif (switch_starting_year == 1) then
        Open(unit = 6, FILE = "_data_lambda_1960.txt")  

    elseif (switch_starting_year == 2) then
        Open(unit = 6, FILE = "_data_lambda_1950.txt")  
        
    elseif (switch_starting_year == 3) then

        Open(unit = 6, FILE = "_data_lambda_1935.txt")      
        
    endif
    
     if (switch_change_lambda == 1) then 
        do i = 1, last_data_lambda, 1
            read(6,*) lambda_d(i)
        enddo
        lambda_d(last_data_lambda+1:) = lambda_d(last_data_lambda)
            
     elseif (switch_change_lambda == 0 .AND. switch_starting_year == 3 ) then
        last_data_lambda = 5
        do i = 1, last_data_lambda+1, 1
            read(6,*) lambda_d(i)
        enddo
        lambda_d(last_data_lambda+1:) = lambda_d(last_data_lambda)
        
    elseif (switch_change_lambda == 0 .AND. switch_starting_year .NE. 3 ) then   
        read(6,*) lambda_d(1)
        lambda_d(2:) = lambda_d(1)
    endif
        
    close(6)
! -------------------------------- N & PI -------------------------------
    bigJT = bigJ*bigT
    
 ! -------------------------------- BIGJ = 16 - US

        
    if (switch_het_mortality == 0) then
    
    ! NEED TO MAKE THIS MORE AUTOMATIC!    
    if (switch_starting_year == 0) then 
        Open(unit = 121, FILE = "_data_pi_cond_US_since1935.txt")  
        Open(unit = 122, FILE = "_data_Nn_US_1935_2100.txt")
        Open(unit = 123, FILE = "_data_Nn_US_1935_init_old.txt")
    elseif (switch_starting_year == 1) then
        Open(unit = 121, FILE = "_data_pi_cond_US_since1960.txt")  
        Open(unit = 122, FILE = "_data_Nn_US_1960_2100.txt")
        Open(unit = 123, FILE = "_data_Nn_US_1960_init_old.txt")
    elseif (switch_starting_year == 2) then
        Open(unit = 121, FILE = "_data_pi_cond_US_since1950.txt")  
        Open(unit = 122, FILE = "_data_Nn_US_1950_2100.txt")
        Open(unit = 123, FILE = "_data_Nn_US_1950_init_old.txt")
    elseif (switch_starting_year == 3) then 
        Open(unit = 121, FILE = "_data_pi_cond_US_since1935.txt")  
        Open(unit = 122, FILE = "_data_Nn_US_1935_2100.txt")
        Open(unit = 123, FILE = "_data_Nn_US_1935_init_old.txt")     
    endif
    
    do i = 1,last_data ,1 
            do j = 1, bigJ
                read(121,*) pi_d_big(j,1,i)
            enddo 
        read(122,*) Nn_d(1,i)
    enddo
    
    do i = last_data+1, bigT, 1 
         pi_d_big(:,:,i)=  pi_d_big(:,:,last_data)    
    enddo
    
    do m = 1, bigM, 1
        pi_d_big(:,m,:) =  pi_d_big(:,1,:)
    enddo

   do i = 1,last_data ,1 
        
        do m = 1,bigM,1

            Nn_d_big(1,m,i) = type_share_d(m,i) * Nn_d(1,i)
        enddo
    enddo
    
    

    
    
    elseif (switch_het_mortality == 1) then
        
    if (switch_starting_year == 0) then 
        Open(unit = 121, FILE = "_data_pi_cond_het_US_since1935.txt")  
        Open(unit = 122, FILE = "_data_Nn_US_1935_2100.txt")
        Open(unit = 123, FILE = "_data_Nn_US_1935_init_old.txt")
    elseif (switch_starting_year == 1) then
        Open(unit = 121, FILE = "_data_pi_cond_het_US_since1960.txt")  
        Open(unit = 122, FILE = "_data_Nn_US_1960_2100.txt")
        Open(unit = 123, FILE = "_data_Nn_US_1960_init_old.txt")
    elseif (switch_starting_year == 2) then
        Open(unit = 121, FILE = "_data_pi_cond_het_US_since1950.txt")  
        Open(unit = 122, FILE = "_data_Nn_US_1950_2100.txt")
        Open(unit = 123, FILE = "_data_Nn_US_1950_init_old.txt")
    elseif (switch_starting_year == 3) then 
        Open(unit = 121, FILE = "_data_pi_cond_het_US_since1935.txt")  
        Open(unit = 122, FILE = "_data_Nn_US_1935_2100.txt")
        Open(unit = 123, FILE = "_data_Nn_US_1935_init_old.txt")     
    endif   
        
    do i = 1,last_data ,1 
        read(122,*) Nn_d(1,i)
        do m = 1,bigM,1
            do j = 1, bigJ
                read(121,*) pi_d_big(j,m,i)
            enddo 
            Nn_d_big(1,m,i) = type_share_d(m,i) * Nn_d(1,i)
        enddo
    enddo
    
    do i = last_data+1, bigT, 1
        do m = 1,bigM,1
            pi_d_big(:,m,i)=  pi_d_big(:,m,last_data)
        enddo
    enddo
    
    endif
    
            ! fill in population and mortality matrix
    

    
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
    


    
    
    !! fill in population and mortality matrix
    !do i = 1,last_data ,1 
    !    do j = 1, bigJ
    !        read(121,*) pi_d(j,i)
    !    enddo 
    !    read(122,*) Nn_d(1,i)
    !enddo
    !
    !do i = last_data+1, bigT, 1
    ! pi_d(:,i)=  pi_d(:,last_data)
    !enddo
     
     
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
        read(123,*) Nn_d(j,1) 
        do m = 1, bigM, 1
        Nn_d_big(j,m,1) =    Nn_d(j,1) * type_share_d(m,1)
        if (switch_steady_demo == 1)  then !if this switch is set to 1 replace initial population from the data with something calculated by assuming that birth rate and mortality was always the same in the past
            !=Nn_d(1,1) = 1.0_dp ! temporary
            Nn_d_big(j,m,1) = nu_ss_old**(-j+1)*pi_d_big(j,m,1)/pi_d_big(1,m,1) * Nn_d_big(1,m,1)
             
        endif
        enddo

    enddo

    close(121) 
    close(122)
    close(123)
   

    do i = last_data+1, bigT, 1
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
    
! -------------------------------- there is no mortality
if (switch_mortality == 0) then 
    pi_d_big = 1.0_dp
    do i = 1,bigT, 1
        do m = 1,bigM,1
            Nn_d_big(1,m,i) = 1.0d0 * type_share_d(m,i)
        
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
    
     
     
elseif (switch_mortality == 5.AND. switch_starting_year .NE.3) then  !this changes subjective probability of survival to the initial ones but keeps the nunber of people born as in the data
    pi_big_weight_d = pi_d_big
    do i = 2, bigT,1
        do j = 2, bigJ, 1   
            pi_d_big(j,:,i) = pi_d_big(j,:,1)
        enddo    
    enddo
    

  
elseif (switch_mortality == 5.AND. switch_starting_year ==3) then  !this changes  subjective probability of survival to the initial ones but keeps the nunber of people born equal to the data
    pi_big_weight_d = pi_d_big
    do i = 6, bigT,1
        do j = 2, bigJ, 1   
            pi_d_big(j,:,i) = pi_d_big(j,:,5)
        enddo    
    enddo  
    
    
elseif (switch_mortality == 6.AND. switch_starting_year .NE.3) then !this changes  objective probability  of survival to the initial ones but keeps the nunber of people born equal to the data
       
    do i = 2, bigT,1
        do m = 1, bigM, 1
            do j = 2, bigJ, 1   
                pi_d_big(j,m,i) = pi_d_big(j,m,5)
                Nn_d_big(j,m,i) = pi_d_big(j,m,i)/pi_d_big(j-1,m,i-1)*Nn_d_big(j-1,m,i-1) 
            enddo
        enddo
    enddo
    pi_big_weight_d = pi_d_big
    
   elseif (switch_mortality == 6.AND. switch_starting_year ==3) then !this changes  objective probability  of survival to the initial ones but keeps the nunber of people born equal to the data
       
    do i = 2, bigT,1
        do m = 1, bigM, 1
            do j = 2, bigJ, 1   
                pi_d_big(j,m,i) = pi_d_big(j,m,5)
                Nn_d_big(j,m,i) = pi_d_big(j,m,i)/pi_d_big(j-1,m,i-1)*Nn_d_big(j-1,m,i-1) 
            enddo
        enddo
    enddo
    pi_big_weight_d = pi_d_big

  
    
  elseif (switch_mortality == 7 .AND. switch_starting_year .NE.3) then ! this will keep the population structure as in the initial period (mortality) and will let the number of j=1 agents grow at nu_ss_new rate
    
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
    
    
  elseif (switch_mortality == 7 .AND. switch_starting_year ==3) then ! this will keep the population structure as in the initial period  (mortality) and will let the number of j=1 agents grow at nu_ss_new rate - nu_ss is recalculated here
        

    N_temp_vec = sum(sum(Nn_d_big, dim=1),dim=1)
    nu_ss_new = N_temp_vec(5)/N_temp_vec(4)
    
    
    do i = 6, bigT,1

        do m = 1, bigM, 1
        do j = 2, bigJ, 1   
            pi_d_big(j,m,i) = pi_d_big(j,m,5)
            pi_big_weight_d(j,m,i) = pi_d_big(j,m,i)
        enddo    
        enddo
    enddo

    do i = 6, bigT,1
        N_temp_vec(i) = N_temp_vec(i-1) * nu_ss_new 
        do m = 1, bigM, 1
        Nn_d_big(1,m,i) = N_temp_vec(i) * type_share_d(m,i)
            do j = 2, bigJ, 1   
                Nn_d_big(j,m,i) = pi_d_big(j,m,max(i-1,1))/pi_d_big(j-1,m,max(i-2,1))*Nn_d_big(j-1,m,max(i-1,1))
            enddo
        enddo    
    enddo 
    
endif
CLOSE(3)
CLOSE(4)
CLOSE(9)

open(unit = 1, file= "population.csv")
    do i = 1,bigT,1
        write(1, '(1x, F, 16(",", F))') (Nn_d(j,i), j = 1,bigJ)
    enddo
close(1)





    
! -------------------------------- GAMMA -------------------------------
    if (switch_starting_year == 0) then 
        Open(unit = 4, FILE = "_data_gamma_tfp_1935.txt")  

    elseif (switch_starting_year == 1) then
        Open(unit = 4, FILE = "_data_gamma_tfp_1960.txt")  

    
    elseif (switch_starting_year == 2) then
        Open(unit = 4, FILE = "_data_gamma_tfp_1950.txt")  
        
    elseif (switch_starting_year == 3) then
        !Open(unit = 4, FILE = "_data_gamma_tfp_1935.txt")  
        Open(unit = 4, FILE = "_data_gamma_tfpadj_1935.txt") 
        
    endif
     
    
    
    if (switch_go_to_lower_gamma == 1) then ! the name of this switch is a bit confusing - need to figure out a set of switches for experiments + a set of switches that control what we vary!
        do i = 1, last_data_gamma, 1
            read(4,*) gam_d(i)
        enddo
        gam_d(last_data_gamma+1:) = 1.03
    elseif (switch_go_to_lower_gamma == 0 .AND. switch_starting_year == 3) then
        last_data_gamma= 5
        do i = 1, last_data_gamma, 1
            read(4,*) gam_d(i)
        enddo
        gam_d(last_data_gamma+1:) = gam_d(last_data_gamma)
        
    elseif (switch_go_to_lower_gamma == 0 .AND. switch_starting_year .NE. 3) then
        read(4,*) gam_d(1)
        gam_d(2:) = gam_d(1)
    endif
        
        
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

! SETTING TO FIXED

if (switch_keep_fixed == 1) then
    gy_factor_d(2:) = gy_factor_d(1)
    do m = 1,bigM,1
    sigma2_epsilon_t_big(2:,m) = sigma2_epsilon_t_big(1,m)  
    type_multiplier_d(m,:) = 1.0
    type_share_d(m,2:) = type_share_d(m,1)
    

    
    enddo
    tauK_d(2:) = tauK_d(1)
    tauL_d(2:) = tauL_d(1)
    alpha_d(2:) = alpha_d(1)
    debt_constr_d(2:) = debt_constr_d(1)
    lambda_d(2:) = lambda_d(1)
    gam_d(2:) = gam_d(1)
    
    do i = 2, bigT,1
        pi_d_big(1,:,i) = pi_d_big(1,:,1)
        Nn_d_big(1,:,i) = Nn_d_big(1,:,1)
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