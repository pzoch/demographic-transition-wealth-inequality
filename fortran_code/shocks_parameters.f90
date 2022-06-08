! shocks    

                
        
        zeta_p = zeta_p**zbar   
        zeta_r = 0.00 ! this does not do anything
        sigma_nu_r = 0.008d0 ** 2.0d0
        
        zeta_d = 0.995d0
        sigma_nu_d = 0.01d0 ** 2.0d0 
        sigma_nu_d = sigma_nu_d*(1-zeta_d**zbar)/(1-zeta_d)
        zeta_d = zeta_d**zbar 
         
        a_l    = 0.0d0   !dla bigJ = 80, a_l = -2d0, inaczej -8d0
        a_u    = 60d0   !dla bigJ = 80, a_u = 10d0, inaczej 30d0
        a_grow = 0.04d0 !dla bigJ = 80, a_grow = 0.05d0, inaczej 0.04d0        
        aime_l    = 0d0
    
        aime_u    = 9165d0/3921d0 ! to capture Old-Age, Survivors, and Disability Insurance (OASDI) tax cap
                            ! based on https://fas.org/sgp/crs/misc/R43542.pdf
                            ! and https://www.thebalancecareers.com/average-salary-information-for-us-workers-2060808
        
        aime_cap = 9165d0/3921d0 ! to capture Old-Age, Survivors, and Disability Insurance (OASDI) tax cap
                    ! based on https://fas.org/sgp/crs/misc/R43542.pdf
                    ! and https://www.thebalancecareers.com/average-salary-information-for-us-workers-2060808

! definie initial distributions
    n_sp_initial = int(n_sp/2)+1
    n_sr_initial = int(n_sr/2)+1
    n_sd_initial = int(n_sd/2)+1
if (n_sp>5) then
    n_sp_initial = int((n_sp-2)/2)+1  ! do not allow for people to be born as superstars
    endif
    

    


        
! temporary

        do ir = 1 , n_sr, 1
                pi_ir_init(ir) = 1.0d0 / n_sr
        enddo 
        
        do id = 1 , n_sd, 1
                pi_id_init(id) = 1.0d0 / n_sd
        enddo 
        


pi_ip = 0d0
pi_ir = 1d0
pi_id = 1d0
n_sp_value = 0d0
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
    
if (n_sp>5) then 
        !do m = 1,bigM, 1
        !    epsilon_correction_t =  epsilon_correction_t_big(:,m)
        !    sigma2_epsilon_t     =  sigma2_epsilon_t_big(:,m)
        !    epsilon_correction_ss_old =  epsilon_correction_ss_old_big(m)
        !    sigma2_epsilon_ss_old     =  sigma2_epsilon_ss_old_big(m)
        !    epsilon_correction_ss_new =  epsilon_correction_ss_new_big(m)
        !    sigma2_epsilon_ss_new     =  sigma2_epsilon_ss_new_big(m)
        !    
        !    do t = 1, bigT, 1
        !        call discretize_AR(zeta_p(m), epsilon_correction_t(t), sigma2_epsilon_t(t), n_sp_value_trans(1:n_sp-2,t), pi_ip_trans(1:n_sp-2,1:n_sp-2,t))
        !  
        !            !pi_ip_init_trans(n_sp_initial,t) = 1.0d0
        !    enddo
        !
        !    n_sp_value_trans = exp(n_sp_value_trans)  
        !
        !
        !    ! get steady state shock realizations and transition matrices
        !    call discretize_AR(zeta_p(m), epsilon_correction_ss_old, sigma2_epsilon_ss_old, n_sp_value_ss_old(1:n_sp-2), pi_ip_ss_old(1:n_sp-2,1:n_sp-2))
        !    call discretize_AR(zeta_p(m), epsilon_correction_ss_new, sigma2_epsilon_ss_new, n_sp_value_ss_new(1:n_sp-2), pi_ip_ss_new(1:n_sp-2,1:n_sp-2))
        !
        !    n_sp_value_ss_old = exp(n_sp_value_ss_old) 
        !    n_sp_value_ss_new = exp(n_sp_value_ss_new)     
        !
        !    n_sp_value = exp(n_sp_value)  
        !
        !
        !    pi_i_6 = 5e-3
        !    pi_6_6 = 0.975d0
        !    pi_6_7 = 0.008d0
        !    pi_7_7 = 0.4d0
        !
        !    n_sp_value_trans(n_sp-1,:) = superstar_factor_1*n_sp_value_trans(n_sp-2,:)
        !    n_sp_value_trans(n_sp,:) = superstar_factor_2*n_sp_value_trans(n_sp-1,:)
        !    n_sp_value_ss_old(n_sp-1) = superstar_factor_1*n_sp_value_ss_old(n_sp-2)
        !    n_sp_value_ss_old(n_sp) = superstar_factor_2*n_sp_value_ss_old(n_sp-1)
        !    n_sp_value_ss_new(n_sp-1) = superstar_factor_1*n_sp_value_ss_new(n_sp-2)
        !    n_sp_value_ss_new(n_sp) = superstar_factor_2*n_sp_value_ss_new(n_sp-1)
        !
        !
        !
        !
        !
        !
        !    pi_ip_trans = (1d0-pi_i_6)*pi_ip_trans
        !    pi_ip_ss_old = (1d0-pi_i_6)*pi_ip_ss_old
        !    pi_ip_ss_new = (1d0-pi_i_6)*pi_ip_ss_new
        !
        !do s=1, n_sp-2,1
        !    pi_ip_trans(s,n_sp-1,:) = pi_i_6
        !    pi_ip_ss_old(s,n_sp-1) = pi_i_6
        !    pi_ip_ss_new(s,n_sp-1) = pi_i_6
        !enddo
        !
        !pi_ip_trans(n_sp-1,n_sp-1,:)= pi_6_6
        !pi_ip_trans(n_sp-1,n_sp,:)  = pi_6_7
        !pi_ip_trans(n_sp-1,3,:)     = 1d0 - pi_6_7 -  pi_6_6 ! note it goes back to point = 3!
        !pi_ip_trans(n_sp,n_sp,:)    = pi_7_7  
        !pi_ip_trans(n_sp,n_sp-1,:)  = 1d0 - pi_7_7
        !
        !pi_ip_ss_old(n_sp-1,n_sp-1) = pi_6_6
        !pi_ip_ss_old(n_sp-1,n_sp)   = pi_6_7
        !pi_ip_ss_old(n_sp-1,3)      = 1d0 - pi_6_7 -  pi_6_6 ! note it goes back to point = 3!
        !pi_ip_ss_old(n_sp,n_sp)     = pi_7_7  
        !pi_ip_ss_old(n_sp,n_sp-1)   = 1d0 - pi_7_7
        !
        !pi_ip_ss_new(n_sp-1,n_sp-1) = pi_6_6
        !pi_ip_ss_new(n_sp-1,n_sp)   = pi_6_7
        !pi_ip_ss_new(n_sp-1,3)      = 1d0 - pi_6_7 -  pi_6_6 ! note it goes back to point = 3!
        !pi_ip_ss_new(n_sp,n_sp)      = pi_7_7  
        !pi_ip_ss_new(n_sp,n_sp-1)    = 1d0 - pi_7_7
        !
        !
        !
        !! now do initial things
        !do t = 1, bigT, 1
        !    do ip = 1 , n_sp, 1
        !            pi_ip_init_trans(ip,t) = pi_ip_trans(n_sp_initial,ip,t)
        !    enddo
        !enddo                
        !
        !
        !
        !
        !do ip = 1 , n_sp, 1
        !pi_ip_init_ss_old(ip) = pi_ip_ss_old(n_sp_initial,ip)
        !pi_ip_init_ss_new(ip) = pi_ip_ss_new(n_sp_initial,ip)
        !enddo
        !
        !
        !! pack
        !
        !pi_ip_init_ss_old_big(:,m)   = pi_ip_init_ss_old
        !pi_ip_init_ss_new_big(:,m)   = pi_ip_init_ss_new
        !
        !pi_ip_init_trans_big(:,m,:)  = pi_ip_init_trans
        !
        !n_sp_value_trans_big(:,m,:)  = n_sp_value_trans
        !
        !n_sp_value_ss_old_big(:,m) = n_sp_value_ss_old
        !n_sp_value_ss_new_big(:,m) = n_sp_value_ss_new
        !
        !pi_ip_trans_big(:,:,m,:) =  pi_ip_trans
        !
        !pi_ip_ss_old_big(:,:,m)  =  pi_ip_ss_old
        !pi_ip_ss_new_big(:,:,m)  =  pi_ip_ss_new
        !enddo
        !

    
    
    
elseif (n_sp>1)  then

    ! need to decide whether to do it here or later
    do m = 1,bigM,1
            epsilon_correction_t =  epsilon_correction_t_big(:,m)
            sigma2_epsilon_t     =  sigma2_epsilon_t_big(:,m)
            epsilon_correction_ss_old =  epsilon_correction_ss_old_big(m)
            sigma2_epsilon_ss_old     =  sigma2_epsilon_ss_old_big(m)
            epsilon_correction_ss_new =  epsilon_correction_ss_new_big(m)
            sigma2_epsilon_ss_new     =  sigma2_epsilon_ss_new_big(m)
         
            do t = 1, bigT, 1
                call discretize_AR(zeta_p(m), epsilon_correction_t(t), sigma2_epsilon_t(t), n_sp_value_trans(1:n_sp,t), pi_ip_trans(1:n_sp,1:n_sp,t))
          
                    !pi_ip_init_trans(n_sp_initial,t) = 1.0d0
            enddo
        
            n_sp_value_trans = exp(n_sp_value_trans)  

        
            ! get steady state shock realizations and transition matrices
            call discretize_AR(zeta_p(m), epsilon_correction_ss_old, sigma2_epsilon_ss_old, n_sp_value_ss_old(1:n_sp), pi_ip_ss_old(1:n_sp,1:n_sp))
            call discretize_AR(zeta_p(m), epsilon_correction_ss_new, sigma2_epsilon_ss_new, n_sp_value_ss_new(1:n_sp), pi_ip_ss_new(1:n_sp,1:n_sp))
        
            n_sp_value_ss_old = exp(n_sp_value_ss_old) 
            n_sp_value_ss_new = exp(n_sp_value_ss_new)     

            n_sp_value = exp(n_sp_value)  
            
     
            
        ! now do initial things
        do t = 1, bigT, 1
            do ip = 1 , n_sp, 1
                    pi_ip_init_trans(ip,t) = pi_ip_trans(n_sp_initial,ip,t)
            enddo
        enddo                
    

    
    
            do ip = 1 , n_sp, 1
            pi_ip_init_ss_old(ip) = pi_ip_ss_old(n_sp_initial,ip)
            pi_ip_init_ss_new(ip) = pi_ip_ss_new(n_sp_initial,ip)
            enddo

        
            ! pack
        
            pi_ip_init_ss_old_big(:,m)   = pi_ip_init_ss_old
            pi_ip_init_ss_new_big(:,m)   = pi_ip_init_ss_new
            pi_ip_init_trans_big(:,m,:)  = pi_ip_init_trans
        
            n_sp_value_trans_big(:,m,:)  = n_sp_value_trans
            n_sp_value_ss_old_big(:,m) = n_sp_value_ss_old
            n_sp_value_ss_new_big(:,m) = n_sp_value_ss_new
        
            pi_ip_trans_big(:,:,m,:) =  pi_ip_trans
            pi_ip_ss_old_big(:,:,m)  =  pi_ip_ss_old
            pi_ip_ss_new_big(:,:,m)  =  pi_ip_ss_new
        
    enddo
    

 
else      
    pi_ip = 1d0
    n_sp_value = 1d0 
    
    pi_ip_init_ss_old_big = 1d0 
    pi_ip_init_ss_new_big = 1d0 
    pi_ip_init_trans_big = 1d0 
    pi_ip_ss_new = 1d0
    pi_ip_ss_old = 1d0
    n_sp_value_trans_big = 1d0 
    n_sp_value_ss_old_big = 1d0 
    n_sp_value_ss_new_big = 1d0 
    
    pi_ip_trans_big = 1d0 
    pi_ip_ss_old_big = 1d0 
    pi_ip_ss_new_big = 1d0 
    endif
  
    
    
        ! now do initial things
    do m=  1, bigM, 1
    do t = 1, bigT, 1
        do ip = 1 , n_sp, 1
                pi_ip_init_trans_big(ip,m,t) = pi_ip_trans_big(n_sp_initial,ip,m,t)
        enddo
    enddo             
    
    pi_ip_init_ss_old_big(:,m) = pi_ip_ss_old(n_sp_initial,:)
    pi_ip_init_ss_new_big(:,m) = pi_ip_ss_new(n_sp_initial,:)
    
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
endif
    

    
if (n_sr >1) then 
     call normal_discrete_1(n_sr_value, prob_norm, 0d0, sigma_nu_r)


     pi_ir(:,:) = 0.0d0
        do  s = 1, n_sr, 1
        pi_ir_init(s) = prob_norm(s)
        pi_ir(s,:) = prob_norm   
    
        enddo
    !call normal_discrete_1(n_sr_value, prob_norm, 1d0, sigma_nu_r)
    !do  s = 1, n_sr, 1
    !    pi_ir(s,:) = prob_norm     
    !enddo
endif   


!! to do model is deterministic (evry state is the same) but we use vfi to solve it 
!n_sp_value = 1d0
!n_sr_value = 0d0
!n_sd_value = 0d0


         if (switch_income_risk == 0) then
             n_sp_value_trans_big(:,:,:) = 1.0d0
             n_sp_value_ss_old_big(:,:)  = 1.0d0
             n_sp_value_ss_new_big(:,:)  = 1.0d0
           
        endif
    
         if (switch_discount_risk == 0) then
             n_sd_value(:) = 0.0d0
  
        endif
    
        if (switch_return_risk == 0) then
             n_sr_value(:) = 0.0d0

        endif