!===============================================================================
! FILE: shocks_parameters.f90
!
! DESCRIPTION:
!   Initializes shock distributions and transition probabilities for income,
!   discount factor, and return risk in the OLG model. Sets up discrete grids.
!
! SCRIPT (not a module)
!   Included/executed during globals initialization to populate shock arrays.
!
! KEY OPERATIONS:
!   - Defines initial distributions for income (ε), discount (δ), return (r) shocks
!   - Sets n_sp_initial, n_sr_initial, n_sd_initial (starting grid points)
!   - Constructs pi_ip_risk (income transition matrix)
!   - Builds n_sp_risk_value, n_sr_value, n_sd_value (discrete state values)
!   - Implements epsilon correction: ensures E[ε] = 0 accounting for persistence
!   - Handles superstar state (n_superstar > 0) if enabled
!
! KEY VARIABLES:
!   - n_sp_risk_ordinary: Regular income states (excludes superstar)
!   - pi_ir_init, pi_id_init: Initial probability vectors for return/discount shocks
!   - sigma2_epsilon_*_big: Variance arrays by cohort/time/type
!   - epsilon_correction_*: Mean correction terms for log-normal transformation
!
! SWITCHES:
!   - switch_discount_risk: Enables discount factor heterogeneity (0/1/2)
!   - n_superstar: Number of superstar states in income distribution
!
! DEPENDENCIES:
!   - global_vars: All shock grid parameters (n_sp, n_sr, n_sd, bigM, bigT, bigJ)
!
! NOTES:
!   This is an included script, not a standalone module. Executed inside
!   globals/set_globals setup. Order-dependent - must run after grid sizes defined.
!   Epsilon correction critical for correct wage level in equilibrium.
!===============================================================================
! shocks    

    

! definie initial distributions
    
    n_sp_risk_ordinary = n_sp_risk - n_superstar
    n_sp_initial = int(n_sp_risk/2)+1
    n_sr_initial = int(n_sr/2)+1
    n_sd_initial = int((n_sd)/2)+1
if (switch_discount_risk == 2)    then
    n_sd_initial = int((n_sd-1)/2)+1
    endif
    
if (n_superstar>0) then
    n_sp_initial = int((n_sp_risk_ordinary)/2)+1  ! do not allow for people to be born as superstars
    endif
    
        
! temporary
        do ir = 1 , n_sr, 1
                pi_ir_init(ir) = 1.0d0 / n_sr
        enddo 
        
        do id = 1 , n_sd, 1
                pi_id_init(id) = 1.0d0 / n_sd
        enddo 
        


pi_ip_risk = 0d0
pi_ir = 1d0
pi_id = 1d0
n_sp_risk_value = 0d0
n_sr_value = 0d0
n_sd_value = 0d0


sigma2_epsilon_ss_old_big = sigma2_epsilon_t_big(1,:)
sigma2_epsilon_ss_new_big = sigma2_epsilon_t_big(bigT,:)

! implement correction of epsilons - this is to ensure that the mean is zero
do m = 1,bigM,1
        epsilon_correction_t_big(:,m) = - (sigma2_epsilon_t_big(:,m)/(1.0d0 - zeta_p(m) ** 2d0)) / 2.0d0
        epsilon_correction_ss_old_big(m) = epsilon_correction_t_big(1,m)
        epsilon_correction_ss_new_big(m) = epsilon_correction_t_big(bigT,m)
enddo
    
if (n_superstar>0) then 
        do m = 1,bigM, 1
            
            epsilon_correction_t =  epsilon_correction_t_big(:,m)
            sigma2_epsilon_t     =  sigma2_epsilon_t_big(:,m)
            epsilon_correction_ss_old =  epsilon_correction_ss_old_big(m)
            sigma2_epsilon_ss_old     =  sigma2_epsilon_ss_old_big(m)
            epsilon_correction_ss_new =  epsilon_correction_ss_new_big(m)
            sigma2_epsilon_ss_new     =  sigma2_epsilon_ss_new_big(m)
            
            do t = 1, bigT, 1
                call discretize_AR(zeta_p(m), epsilon_correction_t(t), sigma2_epsilon_t(t), n_sp_risk_value_trans(1:n_sp_risk_ordinary,t), pi_ip_risk_trans(1:n_sp_risk_ordinary,1:n_sp_risk_ordinary,t))
          

            enddo
        
            n_sp_risk_value_trans = exp(n_sp_risk_value_trans)  
        
        
            ! get steady state shock realizations and transition matrices
            call discretize_AR(zeta_p(m), epsilon_correction_ss_old, sigma2_epsilon_ss_old, n_sp_risk_value_ss_old(1:n_sp_risk_ordinary), pi_ip_risk_ss_old(1:n_sp_risk_ordinary,1:n_sp_risk_ordinary))
            call discretize_AR(zeta_p(m), epsilon_correction_ss_new, sigma2_epsilon_ss_new, n_sp_risk_value_ss_new(1:n_sp_risk_ordinary), pi_ip_risk_ss_new(1:n_sp_risk_ordinary,1:n_sp_risk_ordinary))
        
            n_sp_risk_value_ss_old = exp(n_sp_risk_value_ss_old) 
            n_sp_risk_value_ss_new = exp(n_sp_risk_value_ss_new)     
        


            
            do i = 1,n_superstar
            
                
            n_sp_risk_value_trans(n_sp_risk_ordinary+i,:)   =superstar_factor_mat(m,i)*n_sp_risk_value_trans(n_sp_risk_ordinary+i-1,:)
            n_sp_risk_value_ss_old(n_sp_risk_ordinary+i)    =superstar_factor_mat(m,i)*n_sp_risk_value_ss_old(n_sp_risk_ordinary+i-1)
            n_sp_risk_value_ss_new(n_sp_risk_ordinary+i)    =superstar_factor_mat(m,i)*n_sp_risk_value_ss_new(n_sp_risk_ordinary+i-1)
            
            
            if (i == n_superstar) then
                
            ! adjust to have the extreme state constant
            n_sp_risk_value_trans(n_sp_risk_ordinary+i,:) =  superstar_factor_mat(m,i)*n_sp_risk_value_trans(n_sp_risk_ordinary+i-1,:)
            n_sp_risk_value_trans(n_sp_risk_ordinary+i,:) = sum(n_sp_risk_value_trans(n_sp_risk_ordinary+i,1:20)) / 20! - division by 20 because there are 20 periods
            
            ! note that we divide by type_mutliplier because later it is multiplied by type multiplier
            
            ! these numbers are hard coded - need to modify it
            !if (m == 1) then
            !n_sp_risk_value_trans(n_sp_risk_ordinary+i,:) = n_sp_risk_value_trans(n_sp_risk_ordinary+i,:) * superstar_factor_mat(m,1)
            !else
            !n_sp_risk_value_trans(n_sp_risk_ordinary+i,:) = n_sp_risk_value_trans(n_sp_risk_ordinary+i,:) * superstar_factor_mat(m,1)
            !endif
            n_sp_risk_value_ss_old(n_sp_risk_ordinary+i) = n_sp_risk_value_trans(n_sp_risk_ordinary+i,1)
            n_sp_risk_value_ss_new(n_sp_risk_ordinary+i) = n_sp_risk_value_trans(n_sp_risk_ordinary+i,bigT)
            endif
            
            enddo
            
            

            
        
        
        ! probabilities 
                        
        pi_ip_risk_trans = (1d0-superstar_pi_mat(m,1))*pi_ip_risk_trans
        pi_ip_risk_ss_old = (1d0-superstar_pi_mat(m,1))*pi_ip_risk_ss_old
        pi_ip_risk_ss_new = (1d0-superstar_pi_mat(m,1))*pi_ip_risk_ss_new
            
        do s=1, n_sp_risk_ordinary,1
        pi_ip_risk_trans(s,n_sp_risk_ordinary+1,:) = superstar_pi_mat(m,1)
        pi_ip_risk_ss_old(s,n_sp_risk_ordinary+1) = superstar_pi_mat(m,1)
        pi_ip_risk_ss_new(s,n_sp_risk_ordinary+1) = superstar_pi_mat(m,1)
        enddo
            
            
        
        ! stay at the top
        pi_ip_risk_trans(n_sp_risk_ordinary+n_superstar,n_sp_risk_ordinary+n_superstar,:)   = superstar_pi_mat(m,2)
        pi_ip_risk_ss_old(n_sp_risk_ordinary+n_superstar,n_sp_risk_ordinary+n_superstar)    = superstar_pi_mat(m,2)
        pi_ip_risk_ss_new(n_sp_risk_ordinary+n_superstar,n_sp_risk_ordinary+n_superstar)    = superstar_pi_mat(m,2)
        
        if (n_superstar > 1) then
            pi_ip_risk_trans(n_sp_risk_ordinary+n_superstar,n_sp_risk_ordinary+n_superstar-1,:) = 1.0 -  superstar_pi_mat(m,2)
            pi_ip_risk_ss_old(n_sp_risk_ordinary+n_superstar,n_sp_risk_ordinary+n_superstar-1)  = 1.0 -  superstar_pi_mat(m,2)
            pi_ip_risk_ss_new(n_sp_risk_ordinary+n_superstar,n_sp_risk_ordinary+n_superstar-1)  = 1.0 -  superstar_pi_mat(m,2)
        else
            pi_ip_risk_trans(n_sp_risk_ordinary+n_superstar,n_sp_initial,:) = 1.0 -  superstar_pi_mat(m,2)
            pi_ip_risk_ss_old(n_sp_risk_ordinary+n_superstar,n_sp_initial)  = 1.0 -  superstar_pi_mat(m,2)
            pi_ip_risk_ss_new(n_sp_risk_ordinary+n_superstar,n_sp_initial)  = 1.0 -  superstar_pi_mat(m,2)
        endif
        
        if (n_superstar > 1) then
        do i = 1, (n_superstar-1)
            pi_ip_risk_trans(n_sp_risk_ordinary+i,n_sp_risk_ordinary+i,:)   = superstar_pi_mat(m,2+i)
            pi_ip_risk_trans(n_sp_risk_ordinary+i,n_sp_risk_ordinary+i+1,:) = superstar_pi_mat(m,2+i+1)
            pi_ip_risk_ss_old(n_sp_risk_ordinary+i,n_sp_risk_ordinary+i)    = superstar_pi_mat(m,2+i)
            pi_ip_risk_ss_old(n_sp_risk_ordinary+i,n_sp_risk_ordinary+i+1)  = superstar_pi_mat(m,2+i+1)
            pi_ip_risk_ss_new(n_sp_risk_ordinary+i,n_sp_risk_ordinary+i)    = superstar_pi_mat(m,2+i)
            pi_ip_risk_ss_new(n_sp_risk_ordinary+i,n_sp_risk_ordinary+i+1)  = superstar_pi_mat(m,2+i+1)
            if (i == 1) then
            pi_ip_risk_trans(n_sp_risk_ordinary+i,n_sp_initial,:)       = 1 -superstar_pi_mat(m,2+i) -superstar_pi_mat(m,2+i+1)
            pi_ip_risk_ss_old(n_sp_risk_ordinary+i,n_sp_initial)        = 1 -superstar_pi_mat(m,2+i) -superstar_pi_mat(m,2+i+1)
            pi_ip_risk_ss_new(n_sp_risk_ordinary+i,n_sp_initial)        = 1 -superstar_pi_mat(m,2+i) -superstar_pi_mat(m,2+i+1)
            else
            pi_ip_risk_trans(n_sp_risk_ordinary+i,n_sp_risk_ordinary+i-1,:) = 1- superstar_pi_mat(m,2+i) - superstar_pi_mat(m,2+i+1)
            pi_ip_risk_ss_old(n_sp_risk_ordinary+i,n_sp_risk_ordinary+i-1)  = 1- superstar_pi_mat(m,2+i) - superstar_pi_mat(m,2+i+1)
            pi_ip_risk_ss_new(n_sp_risk_ordinary+i,n_sp_risk_ordinary+i-1)  = 1- superstar_pi_mat(m,2+i) - superstar_pi_mat(m,2+i+1)
            endif
        enddo
        endif
      

        
        
        
        ! now do initial things - everyone born the same (initial_dispersion=0)
        do t = 1, bigT, 1
                    pi_ip_risk_init_trans(:,t) = 0.0d0
                    pi_ip_risk_init_trans(n_sp_initial,t) = 1.0d0
        enddo        
        pi_ip_risk_init_ss_old(:) = 0.0d0
        pi_ip_risk_init_ss_new(:) = 0.0d0
        pi_ip_risk_init_ss_old(n_sp_initial) = 1.0d0
        pi_ip_risk_init_ss_new(n_sp_initial) = 1.0d0
            
        
        
        

        
        
        ! pack
        
        pi_ip_risk_init_ss_old_big(:,m)   = pi_ip_risk_init_ss_old
        pi_ip_risk_init_ss_new_big(:,m)   = pi_ip_risk_init_ss_new
        
        pi_ip_risk_init_trans_big(:,m,:)  = pi_ip_risk_init_trans
        
        n_sp_risk_value_trans_big(:,m,:)  = n_sp_risk_value_trans
        
        n_sp_risk_value_ss_old_big(:,m) = n_sp_risk_value_ss_old
        n_sp_risk_value_ss_new_big(:,m) = n_sp_risk_value_ss_new
        
        pi_ip_risk_trans_big(:,:,m,:) =  pi_ip_risk_trans
        
        pi_ip_risk_ss_old_big(:,:,m)  =  pi_ip_risk_ss_old
        pi_ip_risk_ss_new_big(:,:,m)  =  pi_ip_risk_ss_new
        enddo
        

    
    
    
elseif (n_sp_risk>1)  then

    ! need to decide whether to do it here or later
    do m = 1,bigM,1
            epsilon_correction_t =  epsilon_correction_t_big(:,m)
            sigma2_epsilon_t     =  sigma2_epsilon_t_big(:,m)
            epsilon_correction_ss_old =  epsilon_correction_ss_old_big(m)
            sigma2_epsilon_ss_old     =  sigma2_epsilon_ss_old_big(m)
            epsilon_correction_ss_new =  epsilon_correction_ss_new_big(m)
            sigma2_epsilon_ss_new     =  sigma2_epsilon_ss_new_big(m)
         
            do t = 1, bigT, 1
                call discretize_AR(zeta_p(m), epsilon_correction_t(t), sigma2_epsilon_t(t), n_sp_risk_value_trans(1:n_sp_risk,t), pi_ip_risk_trans(1:n_sp_risk,1:n_sp_risk,t))
          
                    !pi_ip_risk_init_trans(n_sp_risk_initial,t) = 1.0d0
            enddo
        
            n_sp_risk_value_trans = exp(n_sp_risk_value_trans)  

        
            ! get steady state shock realizations and transition matrices
            call discretize_AR(zeta_p(m), epsilon_correction_ss_old, sigma2_epsilon_ss_old, n_sp_risk_value_ss_old(1:n_sp_risk), pi_ip_risk_ss_old(1:n_sp_risk,1:n_sp_risk))
            call discretize_AR(zeta_p(m), epsilon_correction_ss_new, sigma2_epsilon_ss_new, n_sp_risk_value_ss_new(1:n_sp_risk), pi_ip_risk_ss_new(1:n_sp_risk,1:n_sp_risk))
        
            n_sp_risk_value_ss_old = exp(n_sp_risk_value_ss_old) 
            n_sp_risk_value_ss_new = exp(n_sp_risk_value_ss_new)     

            n_sp_risk_value = exp(n_sp_risk_value)  
            
     
            
        ! now do initial things - everyone born the same (initial_dispersion=0)
        do t = 1, bigT, 1
                    pi_ip_risk_init_trans(:,t) = 0.0d0
                    pi_ip_risk_init_trans(n_sp_initial,t) = 1.0d0
        enddo        
        pi_ip_risk_init_ss_old(:) = 0.0d0
        pi_ip_risk_init_ss_new(:) = 0.0d0
        pi_ip_risk_init_ss_old(n_sp_initial) = 1.0d0
        pi_ip_risk_init_ss_new(n_sp_initial) = 1.0d0

        
            ! pack
        
            pi_ip_risk_init_ss_old_big(:,m)   = pi_ip_risk_init_ss_old
            pi_ip_risk_init_ss_new_big(:,m)   = pi_ip_risk_init_ss_new
            pi_ip_risk_init_trans_big(:,m,:)  = pi_ip_risk_init_trans
        
            n_sp_risk_value_trans_big(:,m,:)  = n_sp_risk_value_trans
            n_sp_risk_value_ss_old_big(:,m) = n_sp_risk_value_ss_old
            n_sp_risk_value_ss_new_big(:,m) = n_sp_risk_value_ss_new
        
            pi_ip_risk_trans_big(:,:,m,:) =  pi_ip_risk_trans
            pi_ip_risk_ss_old_big(:,:,m)  =  pi_ip_risk_ss_old
            pi_ip_risk_ss_new_big(:,:,m)  =  pi_ip_risk_ss_new
        
    enddo
    

 
else      
    pi_ip_risk = 1d0
    n_sp_risk_value = 1d0 
    
    pi_ip_risk_init_ss_old_big = 1d0 
    pi_ip_risk_init_ss_new_big = 1d0 
    pi_ip_risk_init_trans_big = 1d0 
    pi_ip_risk_ss_new = 1d0
    pi_ip_risk_ss_old = 1d0
    n_sp_risk_value_trans_big = 1d0 
    n_sp_risk_value_ss_old_big = 1d0 
    n_sp_risk_value_ss_new_big = 1d0 
    
    pi_ip_risk_trans_big = 1d0 
    pi_ip_risk_ss_old_big = 1d0 
    pi_ip_risk_ss_new_big = 1d0 
    endif
  
    
    
        ! now do initial things - everyone born the same (initial_dispersion=0)
    do m=  1, bigM, 1
    do t = 1, bigT, 1
        pi_ip_risk_init_trans_big(:,m,t) = 0.0d0
        pi_ip_risk_init_trans_big(n_sp_initial,m,t) = 1.0d0
    enddo             
    
    pi_ip_risk_init_ss_old_big(:,m) = 0.0d0
    pi_ip_risk_init_ss_new_big(:,m) = 0.0d0
    pi_ip_risk_init_ss_old_big(n_sp_initial,m) = 1.0d0
    pi_ip_risk_init_ss_new_big(n_sp_initial,m) = 1.0d0      
    enddo


    
    
!call discretize_AR(zeta_r, 1d0, sigma_nu_r, n_sr_value, pi_ir)
    
 if (n_sd> 1) then 
          pi_id_init(:) = 0.0d0
    if (switch_discount_risk == 2) then
    call discretize_AR(zeta_d, 0d0, sigma_nu_d, n_sd_value(1:n_sd-1), pi_id(1:n_sd-1,1:n_sd-1),pi_id_init(1:n_sd-1))
         pi_id_init(1:n_sd-1) = pi_id_init(1:n_sd-1) * (1 - htm_shock_freq)
         pi_id_init(n_sd) = htm_shock_freq
    else
    call discretize_AR(zeta_d, 0d0, sigma_nu_d, n_sd_value, pi_id,pi_id_init)
         endif




 endif
 
    ! switch_persistent_delta removed - was always 0 (AR1 shocks to patience)
    ! The discretize_AR call above handles delta shocks when n_sd > 1
    

    
if (n_sr >1) then 
     call normal_discrete_1(n_sr_value, prob_norm, 0d0, sigma_nu_r)


     pi_ir(:,:) = 0.0d0
        do  s = 1, n_sr, 1
        pi_ir_init(s) = prob_norm(s)
        pi_ir(s,:) = prob_norm   
    
        enddo

endif   





         if (switch_income_risk == 0) then
             n_sp_risk_value_trans_big(:,:,:) = 1.0d0
             n_sp_risk_value_ss_old_big(:,:)  = 1.0d0
             n_sp_risk_value_ss_new_big(:,:)  = 1.0d0
             sigma2_epsilon_t_big(:,:) = 0.d0
             epsilon_correction_t_big(:,:) = 0.0d0

            epsilon_correction_ss_old_big(:) = 0.0d0
            sigma2_epsilon_ss_old_big(:) = 0.0d0
            epsilon_correction_ss_new_big(:) = 0.0d0
            sigma2_epsilon_ss_new_big(:) = 0.0d0
             

           
        endif
    
         if (switch_discount_risk == 0) then
             n_sd_value(:) = 0.0d0
    elseif (switch_discount_risk == 2) then
    !        
    !        delta_H = 1.6;
    !        frac_pat = 0.02;
    !        n_sd_value(1) = 1.0d0/((1.0d0-frac_pat)*(1.0d0-htm_shock_freq)) * (delta - frac_pat * (delta_H)) - delta
    !        n_sd_value(2) = delta_H  - delta
            
            n_sd_value(n_sd) =  - delta/1.00
    !        !pi_id(:,1:(n_sd-1)) = (1.0d0 - htm_shock_freq)/float(n_sd-1)
            pi_id(:,n_sd) = htm_shock_freq
            pi_id(:,1:(n_sd-1)) = (1 -  htm_shock_freq) * pi_id(:,1:(n_sd-1))
            pi_id(n_sd,:) = 0.0d0
            pi_id(n_sd,n_sd) = htm_shock_freq
            pi_id(n_sd,n_sd_initial) = 1-htm_shock_freq
            
            ! this is a new one, verify it it works!
            pi_id(n_sd,:) = pi_id_init
            !pi_id(2,1) = 1.0d0 - htm_shock_freq
            !pi_id(2,2) = htm_shock_freq        
    !        pi_id(2,2) = 1.0d0
    !        
    !        pi_id(3,1) =  1.0d0 - htm_shock_freq
    !        pi_id(3,2) =  0.0d0 
    !        pi_id(3,3) = htm_shock_freq
    !        pi_id(2,1) = 0.0d0
    !        pi_id(2,3) = 0.0d0
    !        !pi_id(:,n_sd) = htm_shock_freq
            !pi_id_init(:) = pi_id(1,:) 
    !        pi_id_init(1) = (1.0d0 - frac_pat) * (1.0d0 - htm_shock_freq)
    !        pi_id_init(2) = frac_pat
    !        pi_id_init(3) = (1.0d0 - frac_pat) *  htm_shock_freq
        endif
    
        if (switch_return_risk == 0) then
             n_sr_value(:) = 0.0d0

    endif
    
    
    
! income fixed effects added here
    pi_ip_trans_big = 0.0d0
    pi_ip_ss_old_big = 0.0d0
    pi_ip_ss_new_big = 0.0d0
    
    pi_ip_init_ss_old_big = 0.0d0
    pi_ip_init_ss_new_big = 0.0d0
    pi_ip_init_trans_big  = 0.0d0
    
    do m = 1,bigM,1
        
        call normal_discrete_1(n_sp_fix_value(:,m), prob_norm_fix, 0d0, sigma2_fix(m))
        
        do i = 1,n_sp_fix,1
    

            pi_ip_init_ss_old_big((i-1)*n_sp_risk+1:i*n_sp_risk,m) = pi_ip_risk_init_ss_old_big(:,m) * prob_norm_fix(i)
            pi_ip_init_ss_new_big((i-1)*n_sp_risk+1:i*n_sp_risk,m) = pi_ip_risk_init_ss_new_big(:,m) * prob_norm_fix(i)
            pi_ip_init_trans_big((i-1)*n_sp_risk+1:i*n_sp_risk,m,:) = pi_ip_risk_init_trans_big(:,m,:) * prob_norm_fix(i)

            pi_ip_trans_big((i-1)*n_sp_risk+1:i*n_sp_risk,(i-1)*n_sp_risk+1:i*n_sp_risk,m,:) =  pi_ip_risk_trans_big(:,:,m,:)
            pi_ip_ss_old_big((i-1)*n_sp_risk+1:i*n_sp_risk,(i-1)*n_sp_risk+1:i*n_sp_risk,m)  =  pi_ip_risk_ss_old_big(:,:,m)
            pi_ip_ss_new_big((i-1)*n_sp_risk+1:i*n_sp_risk,(i-1)*n_sp_risk+1:i*n_sp_risk,m)  =  pi_ip_risk_ss_new_big(:,:,m)
         
            ! switch_income_fixed_effect removed - was always 0 (no income fixed effects)
            n_sp_value_trans_big((i-1)*n_sp_risk+1:i*n_sp_risk,m,:) = n_sp_risk_value_trans_big(:,m,:)
            n_sp_value_ss_old_big((i-1)*n_sp_risk+1:i*n_sp_risk,m) = n_sp_risk_value_ss_old_big(:,m) 
            n_sp_value_ss_new_big((i-1)*n_sp_risk+1:i*n_sp_risk,m) = n_sp_risk_value_ss_new_big(:,m)
        
    enddo
    enddo
    
    
    
