! WHAT   : iteration for transition path for PAYG 
! TAKE   : unchanged in routine: productivity (omega), the size of each cohort [[N_t_j]], contribution to the pension system rate [[t1, t1_a, t2]], replacement rate [[rho1, [[rho2]]
!          unchanged in routine: percentage of change in technological progress used to indexation of pension benefit (valor_share)
!          changed   in routine: change in technological progress [[gam = z_t/z_(t-1)]], tax rate (labor, capital, consumption), multiplier for indexation in 1st pillar of pension system [[valor_mult]],
!          changed   in routine: wage (w), interest rate (r), government subsidy to pension system (subsidy_j),  capital (k),  
! DO     : start iteration, variable_new = f(variable_old) etc. since sum|variable_new(i) - variable_old(i)|> err_tol
! RETURN : generated transition path 


do iter = 1,n_iter_t,1
 

include 'denominator_trans.f90'
      if (switch_print == 1) then
        if ((switch_vf == 0)) then 
            if  (MOD(iter,50) == 0) then            
                include 'print_iter.f90'            
            endif
        else 
            include 'print_iter.f90'
        endif
      endif
  
    pillarI_old_j = pillarI_j
    pillarII_old_j = pillarII_j   
    bequest_j_old  = bequest_j 
    b_j_old    = b_j
    bigl_j =N_t_j*l_j
    bigl_j_aux = N_t_j*l_j

    bigl = sum(bigl_j, dim=1)
    bigl_aux = sum(bigl_j_aux, dim=1)

    nu(1) = nu_ss_old
    do i = 2,bigT,1
        nu(i) = bigl(i)/bigl(i-1)
    enddo
    sv_old_j = sv_j
    sv_old_pom_j = sv_pom_j
    tau1_s_t_old = tau1_s_t
    tau2_s_t_old = tau2_s_t


    if (bigJ /= 80) then 
        r_bar = zbar*alpha_t*k**(alpha_t - 1) - depr
        w_bar = zbar*(1 - alpha_t)*k**alpha_t
        y = zbar*k**(alpha_t)
    else
        r_bar = alpha_t*k**(alpha_t - 1) - depr
        w_bar = (1 - alpha_t)*k**alpha_t
        y = k**(alpha_t)
    endif
    do i = 1,bigT,1
        if (r_bar(i) < 0) then
            r_bar(i) = 0.0_dp
        endif
    enddo
    do j = 1,bigJ,1
        w_j(j,:) = (1-tl(:))*(1 - t1(j,:)-t2(j,:))*w_bar(:)
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
include 'implicit_tax_trans.f90'


    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    if (switch_vf == 0) then
            include 'lti_trans.f90'
            l_pen_j = l_j
            do i = 1, bigT, 1
                labor_tax_j_vfi(:,i) = tl(i)*(1 - t1(:,i)-t2(:,i))*w_bar(i)*l_j(:,i)
            enddo
    elseif (switch_vf > 0) then

            do i = 1, bigT,1
                w_pom_trans_vfi(:,i) = (1 - t1(:,i) - t2(:,i))*w_bar(i) !w_j(:,1:bigT)
                w_pom_trans_implicit_vfi(:,i) = (t1_contrib(:,i)*tau1_s_t(:,i) + t2(:,i)*tau2_s_t(:,i))*w_bar(i)
            enddo
            
            w_bar_vfi = w_bar
            
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
            
            
            tc_vfi = tc + 1.0_dp
            gam_vfi = gam_t
            N_t_j_vfi = N_t_j
            b_j_vfi= b_pom_j
            bequest_vfi = bequest
            bequest_j_vfi =  bequest_j
            bequest_j_vfi_dif = bequest_j - bequest_j_old
            jbar_t_vfi = jbar_t !switch_fix_retirement_age
            upsilon_vfi = upsilon
            upsilon_dif = upsilon - upsilon_old
            b_pom_j_dif = b_j - b_j_old
            iter_com = iter

        call agent_vf_trans()
        do i  = 2,bigT
            c_j(:,i) = c_j_vfi(:,i)
            sv_pom_j(1:bigJ-1,i) = up_t*sv_old_pom_j(1:bigJ-1,i) + (1-up_t)*s_pom_j_vfi(1:bigJ-1,i)
            avg_ef_l_suply_trans(i) =  sum(N_t_j(:,i)*l_j_vfi(:,i))/sum(N_t_j(1:jbar_t(i)-1,i))      
            LabIncAVG_vfi(i) =  sum(N_t_j(:,i)*l_j_vfi(:,i)*w_pom_trans_vfi(:,i))/sum(N_t_j(1:jbar_t(i)-1,i))   
        enddo
        l_new_j = l_j_vfi 
        if ( (switch_see_ret == 1) .and. (switch_type_2 == 1)) then
            do i = 2,n_p+1,1
                do j = 1, bigJ, 1 
                    if (j == 1) then
                        sv_j(j,i) =  sv_pom_j(j,i) - l_new_j(j,i)*w_pom_trans_implicit_vfi(j,i) - (b_pom_j(j,i) -b_j(j,i)) 
                    else                                           
                        sv_j(j,i) =  sv_pom_j(j,i) - r(i)*(sv_pom_j(j-1,i-1) - sv_j(j-1,i-1))/gam_t(i) - l_new_j(j,i)*w_pom_trans_implicit_vfi(j,i) -  (b_pom_j(j,i) -b_j(j,i))
                    endif 
                enddo  
            enddo   
        else
            sv_j=  sv_pom_j
        endif
    endif  

    bigl_j = N_t_j*l_j
    bigl = sum(bigl_j, dim=1)
    nu(1) = nu_ss_old
    do i = 2,bigT,1
        nu(i) = bigl(i)/bigl(i-1)
    enddo
        
    do i = 1,bigT,1
        average_l(i) = sum(N_t_j(1:jbar_t(i)-1,i)*l_j(1:jbar_t(i)-1,i),dim=1)/sum(N_t_j(1:jbar_t(i)-1,i),dim=1)
        average_w(i) = sum(N_t_j(1:jbar_t(i)-1,i)*w_j(1:jbar_t(i)-1,i)*l_j(1:jbar_t(i)-1,i),dim=1)/sum(N_t_j(1:jbar_t(i)-1,i),dim=1)
    enddo
    consumption_gross_j = c_j     
    consumption_gross = sum(N_t_j*consumption_gross_j, dim=1)/bigl
    consumption_gross_new = up_t*consumption_gross_new + (1.0_dp-up_t)*consumption_gross
        
    savings_j = sv_j + pillarII_j
    savings = sum(N_t_j*savings_j, dim=1)/bigl

include 'bequest.f90'

    k_new(1) = k(1)
    k_new(n_p+1) = (savings(n_p+1) - debt(n_p+1))/(nu(n_p+1)*gam_t(n_p+1))
    do i = 2,n_p+1,1
        k_new(i) = (savings(i-1) - debt(i-1))/(nu(i)*gam_t(i))
        err(i) = abs(k_new(i) - k(i))
        k(i) = up_t*k(i) + (1 - up_t)*k_new(i)
        l_j(:,i) = up_t*l_j(:,i) + (1 - up_t)*l_new_j(:,i)
    enddo    
        
    cum_err(iter) = sum(err)

    if (iter < n_iter_t+1) then         
        if (cum_err(iter) < err_tol) then 
            write (*,*) 'We`re leaving the iter loop.' 
            exit ! iterations end
        endif
    endif
    replacement(1) = sum_b_weight_trans(1)*b_j(jbar_t(1),1)/(w_bar(i)*l_pen_j(jbar_t(1)-1,1)) 
    !replacement(1) = b_j(jbar_t(1),1)/(w_j(jbar_t(1)-1,1)*l_pen_j(jbar_t(1)-1, 1))    
    do i = 2,bigT,1
            !replacement(i) = b_j(jbar_t(i),i)/(w_j(jbar_t(i)-1,i-1)*l_pen_j(jbar_t(i)-1, i-1)) 
            replacement(i) = sum_b_weight_trans(i)*b_j(jbar_t(i),i)/(w_bar(i)*l_pen_j(jbar_t(i)-1, i-1)) 
    enddo
    
enddo