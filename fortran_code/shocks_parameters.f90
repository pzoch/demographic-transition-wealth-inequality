! shocks    

    
    ! these need to be corrected to allow for unequal bequests
! definie initial distributions
    n_sp_initial = int(n_sp_risk/2)+1
    n_sr_initial = int(n_sr/2)+1
    n_sd_initial = int(n_sd/2)+1
if (n_sp_risk>5) then
    n_sp_initial = int((n_sp_risk-2)/2)+1  ! do not allow for people to be born as superstars
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

! implement correction of epsilons
    do m = 1,bigM,1
        if (switch_epsilon_corr == 1) then
            epsilon_correction_t_big(:,m) = - (sigma2_epsilon_t_big(:,m)/(1.0d0 - zeta_p(m) ** 2d0)) / 2.0d0

        else
             epsilon_correction_t_big(:,m) = 0.0d0
        endif
    
        epsilon_correction_ss_old_big(m) = epsilon_correction_t_big(1,m)
        epsilon_correction_ss_new_big(m) = epsilon_correction_t_big(bigT,m)
    
    enddo
    
if (n_sp_risk>5) then 
        do m = 1,bigM, 1
            epsilon_correction_t =  epsilon_correction_t_big(:,m)
            sigma2_epsilon_t     =  sigma2_epsilon_t_big(:,m)
            epsilon_correction_ss_old =  epsilon_correction_ss_old_big(m)
            sigma2_epsilon_ss_old     =  sigma2_epsilon_ss_old_big(m)
            epsilon_correction_ss_new =  epsilon_correction_ss_new_big(m)
            sigma2_epsilon_ss_new     =  sigma2_epsilon_ss_new_big(m)
            
            do t = 1, bigT, 1
                call discretize_AR(zeta_p(m), epsilon_correction_t(t), sigma2_epsilon_t(t), n_sp_risk_value_trans(1:n_sp_risk-2,t), pi_ip_risk_trans(1:n_sp_risk-2,1:n_sp_risk-2,t))
          

            enddo
        
            n_sp_value_trans = exp(n_sp_value_trans)  
        
        
            ! get steady state shock realizations and transition matrices
            call discretize_AR(zeta_p(m), epsilon_correction_ss_old, sigma2_epsilon_ss_old, n_sp_risk_value_ss_old(1:n_sp_risk-2), pi_ip_ss_old(1:n_sp_risk-2,1:n_sp_risk-2))
            call discretize_AR(zeta_p(m), epsilon_correction_ss_new, sigma2_epsilon_ss_new, n_sp_risk_value_ss_new(1:n_sp_risk-2), pi_ip_ss_new(1:n_sp_risk-2,1:n_sp_risk-2))
        
            n_sp_risk_value_ss_old = exp(n_sp_risk_value_ss_old) 
            n_sp_risk_value_ss_new = exp(n_sp_risk_value_ss_new)     
        
            n_sp_risk_value = exp(n_sp_risk_value)  
        
        
            !pi_i_6 = 5e-3
            !pi_6_6 = 0.95d0
            !pi_6_7 = 0.0025d0
            !pi_7_7 = 0.73d0
        
            n_sp_risk_value_trans(n_sp_risk-1,:) = superstar_factor_1*n_sp_risk_value_trans(n_sp_risk-2,:)
            n_sp_risk_value_trans(n_sp_risk,:) = superstar_factor_2*n_sp_risk_value_trans(n_sp_risk-1,:)
            n_sp_risk_value_ss_old(n_sp_risk-1) = superstar_factor_1*n_sp_risk_value_ss_old(n_sp_risk-2)
            n_sp_risk_value_ss_old(n_sp_risk) = superstar_factor_2*n_sp_risk_value_ss_old(n_sp_risk-1)
            n_sp_risk_value_ss_new(n_sp_risk-1) = superstar_factor_1*n_sp_risk_value_ss_new(n_sp_risk-2)
            n_sp_risk_value_ss_new(n_sp_risk) = superstar_factor_2*n_sp_value_ss_new(n_sp_risk-1)
        
        
        
        
        
        
            pi_ip_risk_trans = (1d0-pi_i_6)*pi_ip_risk_trans
            pi_ip_risk_ss_old = (1d0-pi_i_6)*pi_ip_risk_ss_old
            pi_ip_risk_ss_new = (1d0-pi_i_6)*pi_ip_risk_ss_new
        
        do s=1, n_sp_risk-2,1
            pi_ip_risk_trans(s,n_sp_risk-1,:) = pi_i_6
            pi_ip_risk_ss_old(s,n_sp_risk-1) = pi_i_6
            pi_ip_risk_ss_new(s,n_sp_risk-1) = pi_i_6
        enddo
        
        pi_ip_risk_trans(n_sp_risk-1,n_sp_risk-1,:)= pi_6_6
        pi_ip_risk_trans(n_sp_risk-1,n_sp_risk,:)  = pi_6_7
        pi_ip_risk_trans(n_sp_risk-1,3,:)     = 1d0 - pi_6_7 -  pi_6_6 ! note it goes back to point = 3!
        pi_ip_risk_trans(n_sp_risk,n_sp_risk,:)    = pi_7_7  
        pi_ip_risk_trans(n_sp_risk,n_sp_risk-1,:)  = 1d0 - pi_7_7
        
        pi_ip_risk_ss_old(n_sp_risk-1,n_sp_risk-1) = pi_6_6
        pi_ip_risk_ss_old(n_sp_risk-1,n_sp_risk)   = pi_6_7
        pi_ip_risk_ss_old(n_sp_risk-1,3)      = 1d0 - pi_6_7 -  pi_6_6 ! note it goes back to point = 3!
        pi_ip_risk_ss_old(n_sp_risk,n_sp_risk)     = pi_7_7  
        pi_ip_risk_ss_old(n_sp_risk,n_sp_risk-1)   = 1d0 - pi_7_7
        
        pi_ip_risk_ss_new(n_sp_risk-1,n_sp_risk-1) = pi_6_6
        pi_ip_risk_ss_new(n_sp_risk-1,n_sp_risk)   = pi_6_7
        pi_ip_risk_ss_new(n_sp_risk-1,3)      = 1d0 - pi_6_7 -  pi_6_6 ! note it goes back to point = 3!
        pi_ip_risk_ss_new(n_sp_risk,n_sp_risk)      = pi_7_7  
        pi_ip_risk_ss_new(n_sp_risk,n_sp_risk-1)    = 1d0 - pi_7_7
        
        
        
        ! now do initial things
        
        if (switch_initial_dispersion == 1) then
            do t = 1, bigT, 1
                do ip = 1 , n_sp_risk, 1
                        pi_ip_risk_init_trans(ip,t) = pi_ip_risk_trans(n_sp_initial,ip,t)
                enddo
            enddo                
            do ip = 1 , n_sp_risk, 1
                pi_ip_risk_init_ss_old(ip) = pi_ip_risk_ss_old(n_sp_initial,ip)
                pi_ip_risk_init_ss_new(ip) = pi_ip_risk_ss_new(n_sp_initial,ip)
            enddo
            
        elseif (switch_initial_dispersion == 0) then
            do t = 1, bigT, 1
                        pi_ip_risk_init_trans(:,t) = 0.0d0
                        pi_ip_risk_init_trans(n_sp_initial,t) = 1.0d0
            enddo        
            pi_ip_risk_init_ss_old(:) = 0.0d0
            pi_ip_risk_init_ss_new(:) = 0.0d0
            pi_ip_risk_init_ss_old(n_sp_initial) = 1.0d0
            pi_ip_risk_init_ss_new(n_sp_initial) = 1.0d0    
        endif
            
        
        
        

        
        
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
            
     
            
        ! now do initial things
        if (switch_initial_dispersion == 1) then
            do t = 1, bigT, 1
                do ip = 1 , n_sp_risk, 1
                        pi_ip_risk_init_trans(ip,t) = pi_ip_risk_trans(n_sp_initial,ip,t)
                enddo
            enddo                
            do ip = 1 , n_sp_risk, 1
                pi_ip_risk_init_ss_old(ip) = pi_ip_risk_ss_old(n_sp_initial,ip)
                pi_ip_risk_init_ss_new(ip) = pi_ip_risk_ss_new(n_sp_initial,ip)
            enddo
            
        elseif (switch_initial_dispersion == 0) then
            do t = 1, bigT, 1
                        pi_ip_risk_init_trans(:,t) = 0.0d0
                        pi_ip_risk_init_trans(n_sp_initial,t) = 1.0d0
            enddo        
            pi_ip_risk_init_ss_old(:) = 0.0d0
            pi_ip_risk_init_ss_new(:) = 0.0d0
            pi_ip_risk_init_ss_old(n_sp_initial) = 1.0d0
            pi_ip_risk_init_ss_new(n_sp_initial) = 1.0d0    
        endif

        
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
  
    
    
        ! now do initial things
    do m=  1, bigM, 1
    do t = 1, bigT, 1
        do ip = 1 , n_sp_risk, 1
                if (switch_initial_dispersion == 1) then
                    pi_ip_risk_init_trans_big(ip,m,t) = pi_ip_risk_trans_big(n_sp_initial,ip,m,t)
                elseif (switch_initial_dispersion == 0) then
                    pi_ip_risk_init_trans_big(:,m,t) = 0.0d0
                    pi_ip_risk_init_trans_big(n_sp_initial,m,t) = 1.0d0
                endif
        enddo
    enddo             
    
     if (switch_initial_dispersion == 1) then
        pi_ip_risk_init_ss_old_big(:,m) = pi_ip_risk_ss_old_big(n_sp_initial,:,m)
        pi_ip_risk_init_ss_new_big(:,m) = pi_ip_risk_ss_new_big(n_sp_initial,:,m)
     elseif (switch_initial_dispersion == 0) then
        pi_ip_risk_init_ss_old_big(:,m) = 0.0d0
        pi_ip_risk_init_ss_new_big(:,m) = 0.0d0
        pi_ip_risk_init_ss_old_big(n_sp_initial,m) = 1.0d0
        pi_ip_risk_init_ss_new_big(n_sp_initial,m) = 1.0d0      
    endif
    enddo


    
    
!call discretize_AR(zeta_r, 1d0, sigma_nu_r, n_sr_value, pi_ir)
 if (n_sd> 1) then 
    call discretize_AR(zeta_d, 0d0, sigma_nu_d, n_sd_value, pi_id)
    
   ! approximately stationary dist
   do t = 1,10, 1
   pi_id = matmul(pi_id,pi_id)
   enddo
   pi_id_init = pi_id(1,:)/sum(pi_id(1,:))
   call discretize_AR(zeta_d, 0d0, sigma_nu_d, n_sd_value, pi_id)
   
 endif
 
    if (switch_persistent_delta == 1) then
    call normal_discrete_1(n_sd_value, prob_norm_d, 1d0, sigma_nu_d)


     pi_id(:,:) = 0.0d0
    do  s = 1, n_sd, 1
        pi_id_init(s) = prob_norm_d(s)
        pi_id(s,s) = 1.0d0     
    enddo
    
    elseif (switch_persistent_delta == 2) then
         pi_id(:,:) = 0.0d0
    do  s = 1, n_sd, 1
        n_sd_value(s) = - delta_half_width + 2 * delta_half_width / (n_sd - 1) * (s - 1) 
        pi_id_init(s) = 1.0/float(n_sd)
        pi_id(s,s) = 1.0d0     
        
    enddo
endif
    

    
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
            
            delta_H = 1.6;
            frac_pat = 0.02;
            n_sd_value(1) = 1.0d0/((1.0d0-frac_pat)*(1.0d0-htm_shock_freq)) * (delta - frac_pat * (delta_H)) - delta
            n_sd_value(2) = delta_H  - delta
           !n_sd_value(:) = 0.0d0
            n_sd_value(n_sd) =  - delta/1.00
            !pi_id(:,1:(n_sd-1)) = (1.0d0 - htm_shock_freq)/float(n_sd-1)
            pi_id(1,1) = 1.0d0 - htm_shock_freq
            pi_id(1,2) = 0.0d0
            pi_id(1,3) = htm_shock_freq
            
            pi_id(2,2) = 1.0d0
            
            pi_id(3,1) =  1.0d0 - htm_shock_freq
            pi_id(3,2) =  0.0d0 
            pi_id(3,3) = htm_shock_freq
            pi_id(2,1) = 0.0d0
            pi_id(2,3) = 0.0d0
            !pi_id(:,n_sd) = htm_shock_freq
            pi_id_init(:) = pi_id(1,:) 
            pi_id_init(1) = (1.0d0 - frac_pat) * (1.0d0 - htm_shock_freq)
            pi_id_init(2) = frac_pat
            pi_id_init(3) = (1.0d0 - frac_pat) *  htm_shock_freq
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
         
            if (switch_income_fixed_effect == 0) then 
                n_sp_value_trans_big((i-1)*n_sp_risk+1:i*n_sp_risk,m,:) = n_sp_risk_value_trans_big(:,m,:)
                n_sp_value_ss_old_big((i-1)*n_sp_risk+1:i*n_sp_risk,m) = n_sp_risk_value_ss_old_big(:,m) 
                n_sp_value_ss_new_big((i-1)*n_sp_risk+1:i*n_sp_risk,m) = n_sp_risk_value_ss_new_big(:,m)
            else
                n_sp_value_trans_big((i-1)*n_sp_risk+1:i*n_sp_risk,m,:) = exp(log(n_sp_risk_value_trans_big(:,m,:) + n_sp_fix_value(i,m) - sigma2_fix(m)/ 2.0d0 ))
                n_sp_value_ss_old_big((i-1)*n_sp_risk+1:i*n_sp_risk,m) = exp(log(n_sp_risk_value_ss_old_big(:,m)  + n_sp_fix_value(i,m) - sigma2_fix(m)/ 2.0d0 ))
                n_sp_value_ss_new_big((i-1)*n_sp_risk+1:i*n_sp_risk,m) = exp(log(n_sp_risk_value_ss_new_big(:,m)  + n_sp_fix_value(i,m) - sigma2_fix(m)/ 2.0d0 ))
            endif
        
    enddo
    enddo
    
    
    
