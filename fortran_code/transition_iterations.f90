! WHAT   : iteration for transition path for PAYG 
! TAKE   : unchanged in routine: productivity (omega), the size of each cohort [[N_t_j]], contribution to the pension system rate [[t1, t1_a, t2]], replacement rate [[rho1, [[rho2]]
!          unchanged in routine: percentage of change in technological progress used to indexation of pension benefit (valor_share)
!          changed   in routine: change in technological progress [[gam = z_t/z_(t-1)]], tax rate (labor, capital, consumption), multiplier for indexation in 1st pillar of pension system [[valor_mult]],
!          changed   in routine: wage (w), interest rate (r), government subsidy to pension system (subsidy_j),  capital (k),  
! DO     : start iteration, variable_new = f(variable_old) etc. since sum|variable_new(i) - variable_old(i)|> err_tol
! RETURN : generated transition path 


do iter = 1,n_iter_t,1
 


      if (switch_print == 1) then
       
            if  (MOD(iter,50) == 0) then            
                include 'print_iter.f90'            
            endif


      endif
  
    pillarI_old_j = pillarI_j
    pillarII_old_j = pillarII_j   
    bequest_j_old  = bequest_j 
    b_j_old    = b_j
    
    
    bigl_type = 0.0d0
    bigl      = 0d0
    do m = 1,bigM,1
        bigl_type(m,:)         = sum(N_big_t_j(:,m,:) * l_j(:,m,:), dim = 1 )
        bigl                   = bigl + type_multiplier_t(m,:) * bigl_type(m,:) ** rho_subst 

    enddo
    
    do i = 1,bigT,1
        bigl(i) = bigl(i)  ** (1.0d0/rho_subst)
    enddo

    nu(1) = nu_ss_old
    do i = 2,bigT,1
        nu(i) = bigl(i)/bigl(i-1)
    enddo
    
    sv_old_j = sv_j
    sv_old_pom_j = sv_old_j
    tau1_s_t_old = tau1_s_t
    tau2_s_t_old = tau2_s_t


        r_bar = zbar*alpha_t*k**(alpha_t - 1) - depr
        include 'ces_production.f90'
        y = zbar*k**(alpha_t)
        
    do i = 1,bigT,1
        if (r_bar(i) < -0.05_dp) then
            r_bar(i) = -0.05_dp
        endif
    enddo
    do j = 1,bigJ,1
        do m = 1,bigM,1
        w_j(j,m,:) = (1-tl(:))*(1 - t1(j,:)-t2(j,:))*w_bar(m,:)
        enddo
    enddo
    if (switch_tauK_gross == 0) then
        r = 1+ (1 - tk)*r_bar  
    else
        r = 1+ (1 - tk)*(r_bar+depr) - depr 
    endif
    
    r_f = 1 + r_bar

if (switch_g_const == 1) then 
    g = g_per_capita*N_t/bigL
elseif (switch_g_const == 0) then  
    g = g_share * y 
endif

    
   if ((switch_residual .NE. 6) .OR. (switch_residual .NE. 7)) then
    ! we are not using debt adjustment to smooth tax adjustment 
    debt = debt_constr_t*y
    sum_priv_sv(1) = k(1)*gam_t(1)*nu(1) + debt(1) - PillarII(1)
 	do i = 2,bigT,1 
 	    if (i > n_p+2) then 
            sum_priv_sv(i) = k(i)*gam_t(i)*nu(i) + debt(i) - PillarII(i)
        else 
 	        sum_priv_sv(i) = k(i+1)*gam_t(i+1)*nu(i+1) + debt(i) - PillarII(i)
        endif 
    enddo 
   endif

include 'pension_system.f90'
include 'closures.f90'


    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

            if (switch_tauK_gross == 0) then
                r_vfi = (1 - tk)*r_bar  
            else
                r_vfi = (1 - tk)*(r_bar+depr) - depr 
            endif
            
            if (switch_tauK_gross == 0) then
                r_vfi_pretax = r_bar  
            else
                r_vfi_pretax = r_bar 
            endif
            sum_b_weight_trans_outer = 0.0d0
            
        do m = 1,bigM, 1

            
            pi(:,:) = pi_big(:,m,:)
            pi_vfi = pi
            
            do i = 1, bigT,1
                w_pom_trans_vfi(:,i) = (1 - t1(:,i) - t2(:,i))*w_bar(m,i) !w_j(:,1:bigT)
                w_pom_trans_implicit_vfi(:,i) = (t1_contrib(:,i)*tau1_s_t(:,i) + t2(:,i)*tau2_s_t(:,i))*w_bar(m,i)
            enddo
            
            w_bar_vfi = w_bar(m,:)
            

            
            tc_vfi = tc + 1.0_dp
            gam_vfi = gam_t
            N_t_j_vfi = N_big_t_j(:,m,:)
            b_j_vfi   = b_j(:,m,:)
            bequest_vfi = bequest(m,:)
            bequest_j_vfi =  bequest_j(:,m,:)
            bequest_j_vfi_dif = bequest_j(:,m,:) - bequest_j_old(:,m,:)
            jbar_t_vfi = jbar_t !switch_fix_retirement_age
            upsilon_vfi = upsilon
            upsilon_dif = upsilon - upsilon_old
            b_pom_j_dif(:,:) = b_j(:,m,:) - b_j_old(:,m,:)
            aime_plus_trans  = aime_plus_trans_big(:, :, :, :, :, :,m,:)
            c_j_vfi = c_j(:,m,:)
            l_j_vfi = l_j(:,m,:)
            s_pom_j_vfi = sv_j(:,m,:)   
            labor_tax_j_vfi = labor_tax_j(:,m,:) 
            l_pen_j_vfi(:,:) = l_j(:,m,:)
            
            do i = 1,bigT
                do j = 1,bigJ
                prob_trans(j,:,:,:,:,:,i) =  prob_trans_big(j,:,:,:,:,:,m,i)
                enddo
            enddo

            iter_com = iter
            EV_trans = EV_trans_big(:, :, :, :, :, :,m,:)
            V_trans = V_trans_big(:, :, :, :, :, :,m,:)
            labor_tax_trans = labor_tax_trans_big(:, :, :, :, :, : ,m,:)        
            c_trans = c_trans_big(:, :, :, :, :, : ,m,:) 
            l_trans = l_trans_big(:, :, :, :, :, : ,m,:) 
            svplus_trans = svplus_trans_big(:, :, :, :, :, :,m,:) 
            pi_ip_trans = pi_ip_trans_big(:,:,m,:)
            
            lab_income_trans    = lab_income_trans_big(:, :, :, :, :, :,m,:)
            lab_income_pretax_trans = lab_income_pretax_trans_big(:, :, :, :, :, :,m,:)
            tot_income_trans      = tot_income_trans_big(:, :, :, :, :, :,m,:)
            tot_income_pretax_trans = tot_income_pretax_trans_big(:, :, :, :, :, :,m,:)
            n_sp_value_trans = n_sp_value_trans_big(:,m,:)
            pi_ip_init_trans = pi_ip_init_trans_big(:,m,:)
            omega = omega_big(:,m,:)




            
            call agent_vf_trans()
            
        
            do i = 2,bigT
            do j = 1,bigJ
            prob_trans_big(j,:,:,:,:,:,m,i)               =  prob_trans(j,:,:,:,:,:,i) 
            enddo
            enddo
            aime_plus_trans_big(:,:,:,:,:,:,m,:)            = aime_plus_trans(:,:,:,:,:,:,:) 
            c_trans_big(:, :, :, :, :, : ,m,:)              = c_trans(:,:,:,:,:,:,:) 
            l_trans_big(:, :, :, :, :, : ,m,:)              = l_trans(:,:,:,:,:,:,:) 
            lab_income_trans_big(:, :, :, :, :, :,m,:)      = lab_income_trans(:,:,:,:,:,:,:) 
            lab_income_pretax_trans_big(:, :, :, :, :, :,m,:) = lab_income_pretax_trans(:,:,:,:,:,:,:) 
            tot_income_trans_big(:, :, :, :, :, :,m,:)        = tot_income_trans(:,:,:,:,:,:,:) 
            tot_income_pretax_trans_big(:, :, :, :, :, :,m,:) = tot_income_pretax_trans(:,:,:,:,:,:,:) 
            labor_tax_trans_big(:, :, :, :, :, :,m,:)         = labor_tax_trans(:,:,:,:,:,:,:) 
            svplus_trans_big(:, :, :, :, :, :,m,:)            = svplus_trans(:,:,:,:,:,:,:) 
            V_trans_big(:, :, :, :, :, :,m,:)                 = V_trans(:,:,:,:,:,:,:) 
            EV_trans_big(:, :, :, :, :, :,m,:)                = EV_trans(:,:,:,:,:,:,:) 
            
            c_j(:,m,:) = c_j_vfi(:,:)
            l_j(:,m,:) = l_j_vfi(:,:)
            sv_j(1:bigJ-1,m,:) = s_pom_j_vfi(1:bigJ-1,:) 
            w_pom_trans(:,m,:) = w_pom_trans_vfi(:,:) 
            labor_tax_j(:,m,:) = labor_tax_j_vfi(:,:)
            l_pen_j(:,m,:)  = l_pen_j_vfi(:,:)
            ! what to do with this?
            !sum_b_weight_ss(:) = sum_b_weight_ss + bigM_share_ss(m) * sum_b_weight_ss_vfi
            do i = 1,bigT
            sum_b_weight_trans_outer(i) = sum_b_weight_trans_outer(i) +  N_big_t_j(jbar_t_vfi(i),m,i) / N_t_j(jbar_t_vfi(i),i)   * sum_b_weight_trans(i)
            enddo
        enddo
        avg_ef_l_supply_trans(2:bigT)     = 0d0
        LabIncAVG_vfi(2:bigT)             = 0d0
      ! aggregation
        sv_pom_j(:,:,1) = sv_j(:,:,1)
        do i  = 2,bigT
            sv_pom_j(1:bigJ-1,:,i) = up_t*sv_old_pom_j(1:bigJ-1,:,i) + (1-up_t)*sv_j(1:bigJ-1,:,i)
            
            do m = 1,bigM,1
            avg_ef_l_supply_trans(i) = avg_ef_l_supply_trans(i)  + sum(N_big_t_j(:,m,i) *l_j(:,m,i))/sum(N_t_j(1:jbar_t(i)-1,i)) 
            LabIncAVG_vfi(i)        =  LabIncAVG_vfi(i)          + sum(N_big_t_j(:,m,i) *l_j(:,m,i)*w_pom_trans(:,m,i))/sum(N_t_j(1:jbar_t(i)-1,i))   
            enddo
            
        enddo
        
        l_new_j = l_j
        sv_j=  sv_pom_j

        
        
        bigl = 0.0d0
    do m = 1,bigM,1
        bigl_type(m,:)         = sum(N_big_t_j(:,m,:) * l_j(:,m,:), dim = 1 )
        bigl                   = bigl + type_multiplier_t(m,:) * bigl_type(m,:) ** rho_subst 

    enddo

    do i = 1,bigT,1
    bigl(i) = bigl(i) ** (1.0d0/rho_subst)
    enddo
    nu(1) = nu_ss_old
    do i = 2,bigT,1
        nu(i) = bigl(i)/bigl(i-1)
    enddo
    

    do i = 1,bigT,1
         
        do m = 1,bigM,1  
        average_l(i) = average_l(i) + sum(N_big_t_j(1:jbar_t(i)-1,m,i) *  l_j(1:jbar_t(i)-1,m,i),dim=1)/sum(N_t_j(1:jbar_t(i)-1,i),dim=1)
        average_w(i) = average_w(i) + sum(N_big_t_j(1:jbar_t(i)-1,m,i) *  w_j(1:jbar_t(i)-1,m,i)*l_j(1:jbar_t(i)-1,m,i),dim=1)/sum(N_t_j(1:jbar_t(i)-1,i),dim=1)
        enddo
    enddo    


    consumption_gross_j = c_j     
    consumption_gross = 0.0d0 
    do m=1,bigM,1
        consumption_gross = consumption_gross + sum(N_big_t_j(:,m,:) * consumption_gross_j(:,m,:), dim=1)/bigl       
    enddo
    
    consumption_gross_new = consumption_gross!up_t*consumption_gross_new + (1.0_dp-up_t)*consumption_gross
        
    savings_j = sv_j + pillarII_j
    
    savings = 0.0d0
    do i=1,bigT,1
    do m=1,bigM,1
        savings(i) = savings(i) +  sum(N_big_t_j(:,m,i) *savings_j(:,m,i), dim=1)
    enddo
    savings(i) = savings(i) /bigl(i)
    enddo

    
    include 'bequest.f90'
    
    k_new(1) = k(1)
    k_new(n_p+1) = (savings(n_p+1) - debt(n_p+1))/(nu(n_p+1)*gam_t(n_p+1))
    do i = 2,n_p+1,1
        k_new(i) = (savings(i-1) - debt(i-1))/(nu(i)*gam_t(i))
        err(i) = abs(k_new(i) - k(i))
        k(i) = up_t*k(i) + (1 - up_t)*k_new(i)
        l_j(:,:,i) =l_new_j(:,:,i) !up_t*l_j(:,:,i) + (1 - up_t)*l_new_j(:,:,i)
    enddo    
    
    cum_err(iter) = sum(err)

    if (iter < n_iter_t+1) then         
        if (cum_err(iter) < err_tol) then 
            write (*,*) 'We`re leaving the iter loop.' 
            exit ! iterations end
        endif
    endif

    replacement = 0.d0
    do m = 1,bigM,1
            replacement(1) = replacement(1) + N_big_t_j(jbar_t(1),m,1) / N_t_j(jbar_t(1),1)  * sum_b_weight_trans(1)* b_j(jbar_t(1),m,1)/(w_j(jbar_t(1)-1,m,1)*l_pen_j(jbar_t(1)-1,m, 1))  
    enddo
    

  
    do i = 2,bigT,1
        do m = 1,bigM,1
            replacement(i) = replacement(i) +N_big_t_j(jbar_t(i),m,i) / N_t_j(jbar_t(i),i) * sum_b_weight_trans(i)*b_j(jbar_t(i),m,i)/(w_bar(m,i)*l_pen_j(jbar_t(i)-1,m, i-1)) 
        enddo
    enddo
    
enddo