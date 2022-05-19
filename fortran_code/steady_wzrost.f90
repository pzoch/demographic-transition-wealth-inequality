! WHAT   : stady state routine for PAYG 
! TAKE   : data on mortality [[pi]], retirement age [[jbar]], change in technological progress [[gamma = z_t/z_(t-1)]], the size of the cohort [[N_ss_j]], pension system parameters [[t1 - ZUS, [[t2 - OFE]]  <- constant during iteration
!          and guess for capital, labor force participation [[l_]], consumption, bequest , nu_ss population growth rate in steady state, N_ss_j population age structure
! DO     : during iterations update guess values to new ones in order to find optimal allocation in steady state; iterations end when difference between old and new value is really small (err_ss < 1e-8)
! RETURN : k_ss, c_ss, r_ss etc. that fullfil the condition of optimal allocation. It is one of the edge of transition path

MODULE steady_state
use global_vars
!use individual_vf
use pfi_trans


IMPLICIT NONE

CONTAINS

subroutine steady(switch_residual, switch_tauK_gross, switch_unequal_bequest, param_ss, switch_type,  rho, k_ss_o, r_ss, r_bar_ss, w_bar_ss,  l_ss_j, w_ss_j, s_ss_j, c_ss_j, b_ss_j,  upsilon_r_ss, t1_ss, g_per_capita_ss, b1_ss_j, b2_ss_j,  pillarI_ss_j, pillarII_ss_j)
    real(dp) :: k_ss, k_ss_new,  k_total_ss, k_star_ss, i_star_ss, err_ss, u_ss, &
                jbar_ss, gam_ss, N_ss, nu_ss, bigl_ss, subsidy_ss, y_ss,  consumption_ss_gross, &
                savings_ss, average_l_ss, average_w_ss, upsilon_ss, income_ss, &
                deficit_ss, debt_ss, Tax_ss, g_ss, sum_b_ss, sum_priv_sv_ss, valor_mult_ss, debt_constr, replacement_ss, labor_tax_revenue_ss
    
    real(dp), dimension(bigM) :: bequest_ss
    real(dp), dimension(bigj) :: pi_ss, life_exp, pi_weight_ss
    real(dp), dimension(bigj) :: lti_ss_j, N_ss_j,  income_ss_j, savings_ss_rate_j
    
    
	real(dp), dimension(bigj,bigM) :: denominator_j, subsidy_ss_j, consumption_ss_gross_j, bequest_left_ss_j, bequest_ss_j, bequest_ss_j_old, savings_ss_j
    real*8, dimension(0:n_a) :: prob_ss_marg
    real(dp), intent(in)  :: rho	
    integer, intent(in)   :: param_ss
    integer, intent(in)   :: switch_residual, switch_type, switch_tauK_gross, switch_unequal_bequest
    real(dp), intent(out) :: k_ss_o, r_ss, r_bar_ss, upsilon_r_ss, t1_ss, g_per_capita_ss
    real(dp), dimension(bigM), intent(out)  :: w_bar_ss
    real(dp), dimension(bigj,bigM), intent(out) :: l_ss_j, w_ss_j, s_ss_j, c_ss_j, b_ss_j
    ! pension system 
     real(dp), dimension(bigj,bigM) :: b1_ss_j, b2_ss_j, w_pom_ss_implicit
     real(dp), dimension(bigj) :: pillarI_ss_j, pillarII_ss_j, &
                                 contributionI_ss_j, contributionII_ss_j
     real(dp), dimension(bigM) :: w_pom_ss
     
     real(dp) ::  accountI_ss, accountII_ss, pillarI_ss, pillarII_ss, rI_ss, b_scale_factor_ss, t2_ss, &
                nom1, denom1, nom2, denom2
     real(dp), dimension(bigj) :: tau1_ss, tau1_a_ss, tau2_ss
     real(dp), dimension(bigj,bigM) :: w_pom_ss_j, s_pom_ss_j
     real(dp) :: avg_wl, mult_ss
     
     real(dp), dimension(bigj,bigM) :: l_ss_pen_j, labor_tax_ss_j
     !real*8, dimension(bigJ) :: V_ss_j_vfi, c_ss_j_vfi, s_pom_ss_j_vfi, l_ss_j_vfi, lab_ss_j_vfi, b_ss_j_vfi, &
     !                      bequest_ss_j_vfi, bequest_ss_j_vfi_dif, pi_ss_vfi, pi_ss_vfi_cond, l_ss_pen_j_vfi, &
     !                      labor_tax_ss_j_vfi, lw_ss_j_vfi, lw_lambda_ss_j_vfi, w_pom_ss_vfi, w_pom_ss_implicit_vfi, lab_high_j_vfi 
     real*8, dimension(bigJ, 0:n_a, 0:n_aime, n_sp, n_sr,n_sd,bigM) :: prob_ss_big
    
    real(dp), dimension(bigj, n_a) :: V_ss_j

    if (param_ss == 0) then ! 0 = with old parameters;  1 = with new parameters
        alpha = alpha_ss_old
        gam_ss = gam_ss_old
        pi_ss = pi_ss_old 
        pi_weight_ss = pi_weight_ss_old
        N_ss_j =  N_ss_old
        jbar_ss = jbar_ss_old
        nu_ss =  nu_ss_old
        t1_ss = t1_ss_old
        t2_ss = t2_ss_old
        tL_ss   = tauL_ss_old
        tK_ss   = tauK_ss_old
        lambda= lambda_ss_old
        debt_constr= debt_constr_ss_old
        pi_ip = pi_ip_ss_old
        n_sp_value = n_sp_value_ss_old
        pi_ip_init = pi_ip_init_ss_old
        g_share_ss = g_share_ss
        
    else 
        alpha = alpha_ss_new
        gam_ss = gam_ss_new
        pi_ss = pi_ss_new
        pi_weight_ss = pi_weight_ss_new
        N_ss_j =  N_ss_new
        jbar_ss = jbar_ss_new
        nu_ss = nu_ss_new
        t1_ss = t1_ss_new
        t2_ss = t2_ss_new
        tL_ss  = tauL_ss_new
        tK_ss   = tauK_ss_new
        lambda = lambda_ss_new
        pi_ip = pi_ip_ss_new
        debt_constr= debt_constr_ss_new
        n_sp_value = n_sp_value_ss_new
        pi_ip_init = pi_ip_init_ss_new
        g_share_ss = g_share_ss_2
    endif
!OPEN (unit=121, FILE = version//experiment//closure//"test_k_NEW.txt")
 
! force it to treat it as a 2nd steady state - for test purposes    
!switch_run_1 = 0
    
!normalized structure of population such as N_ss_j(1) = 1 (number of 20 years old)  --- MAYBE THIS IS THE KEY???
if (switch_run_1 == 0) then 
    n_ss_j(1) = 1.0_dp 
    do j = 2, bigj
        n_ss_j(j) = nu_ss**(-j+1)*pi_weight_ss(j)/pi_weight_ss(1)
    enddo
endif

if (switch_steady_demo == 1) then 
    n_ss_j(1) = 1.0_dp 
    do j = 2, bigj
        n_ss_j(j) = nu_ss**(-j+1)*pi_weight_ss(j)/pi_weight_ss(1)
    enddo
endif

life_exp = 0
do j = 1,bigJ,1       
    do s = 0,bigJ-j,1
        if (s /= bigJ-j) then
            life_exp(j) = life_exp(j) + (s+1)*(pi_ss(j+s)/pi_ss(j))*(1-pi_ss(j+s+1)/pi_ss(j+s))
        else ! i.e. s==bigJ-j
            life_exp(j) = life_exp(j) + (s+1)*pi_ss(j+s)/pi_ss(j)  
        endif
    enddo
enddo  
!write(*,*) "life  exp is equal to ", life_exp(10)*5d0 
write(*,*) "ret/work force  ", sum(N_ss_j(jbar_ss:))/sum(N_ss_j(:jbar_ss-1))

b_scale_factor_ss = 1d0
avg_ef_l_supply = 0.33 



valor_mult_ss = (1 + valor_share*(nu_ss*gam_ss - 1))/gam_ss 
    rI_ss = gam_ss*nu_ss - 1
    N_ss = sum(N_ss_j(1:bigJ))       

    ! guess 
    
    r_bar_ss = (1 + 0.03_dp)**(zbar) - 1 !(1 + 0.078_dp)**(zbar) - 1
    k_ss = ((r_bar_ss + depr)/(alpha*zbar))**(1/(alpha - 1))
    w_bar_ss(:) = zbar*(1 - alpha)*k_ss**alpha * type_multiplier
    LabIncAVG_ss_vfi = sum(0.33*w_bar_ss*bigM_share_ss)
    ! upsilon gess residual closure ( we need only upsil, other parameters are given in set globals)
    select case (switch_residual)
    case(0)
        upsilon_ss = 0d0 ! 0.0686986 !0.053_dp
    endselect

    bequest_ss = 0.0_dp
    bequest_ss_j = 0.0_dp
    bequest_left_ss_j = 0.0_dp
    bequest_ss_j_old = 0.0_dp
    
    
!!! ITERATIONS STARTS     
do iter = 1,n_iter_ss,1
        
    
    r_bar_ss = zbar*alpha*k_ss**(alpha - 1) - depr
    y_ss     = zbar* k_ss**(alpha)
    w_bar_ss(:) = zbar*(1 - alpha)*k_ss**alpha * type_multiplier
    
    if (r_bar_ss < 0) then
        r_bar_ss = 0
    endif
    
    if (switch_tauK_gross == 0) then
        r_ss = 1 + (1 - tk_ss)*r_bar_ss  
        else
        r_ss = 1 + (1 - tk_ss)*(r_bar_ss + depr) - depr
        endif
      


    
    ! g due to closure consruction is expresse as G/bigL
    if (switch_run_1 == 1) then ! in initial ss we keep g as a share of gdp
         if (switch_residual .ne. 6) then! unless it is used as closure 
            g_ss = g_share_ss*y_ss
            g_per_capita_ss = g_ss*bigl_ss/N_ss
         endif
         
         
    else 
        if (switch_g_const == 1) then ! 
            g_per_capita_ss = g_per_capita_ss_1 
            if (iter == 1) then ! we do not have big l in first iter 
                g_ss = g_share_ss_2*y_ss
            else
                g_ss = g_per_capita_ss*N_ss/bigl_ss 
            endif
        elseif (switch_g_const == 0) then
            g_ss = g_share_ss_2*y_ss
        endif
    endif  
    
    debt_ss = debt_constr*y_ss
    sum_priv_sv_ss = k_ss*gam_ss*nu_ss + debt_ss - PillarII_ss


! no interest is added when switch_unequal_bequest == 1
if ((switch_run_1 == 1).AND.(switch_steady_demo == 0)) then  ! this part is also weird! need to check!!!! 

        if (switch_unequal_bequest==0) then
            do m = 1,bigM,1
                do j = 2,bigJ,1
                    bequest_left_ss_j(j-1,m) = bigM_share_ss(m) * (N_ss_j(j-1) - N_ss_j(j))*(r_ss*s_ss_j(j-1,m))/gam_ss
                enddo
                
            bequest_left_ss_j(bigJ,m) = (N_ss_j(bigJ))*(r_ss*s_ss_j(bigJ,m))/gam_ss
            bequest_ss(m) = sum(bequest_left_ss_j(1:bigJ,m))
        
            bequest_ss_j_old(:,m) = bequest_ss_j(:,m)
            bequest_ss_j(1,m) = 0d0
    
            do j = 2,bigJ,1
                bequest_ss_j(j,m) = up_ss*bequest_ss_j_old(j,m) + (1 - up_ss)*bequest_left_ss_j(j-1,m)/(bigM_share_ss(m)*N_ss_j(j))  
            enddo 
            enddo
    
        elseif (switch_unequal_bequest==1) then
            do m = 1,bigM,1
             bequest_ss_j(1,m) = 0d0
            do j = 2,bigJ,1
                bequest_ss_j(j,m) = 0d0
                bequest_left_ss_j(j-1,m) = bigM_share_ss(m) *  (N_ss_j(j-1) - N_ss_j(j))*s_ss_j(j-1,m) 
            enddo
            bequest_left_ss_j(bigJ,m) = (N_ss_j(bigJ))*s_ss_j(bigJ,m) 
            bequest_ss(m) = sum(bequest_left_ss_j(1:bigJ,m))
            enddo

        endif
    
else
        if (switch_unequal_bequest==0) then
            do m = 1,bigM,1
            do j = 2,bigJ,1
            bequest_left_ss_j(j-1,m) = bigM_share_ss(m) * (pi_weight_ss(j-1) - pi_weight_ss(j))*(r_ss*s_ss_j(j-1,m))/gam_ss
            enddo
            bequest_left_ss_j(bigJ,m) = bigM_share_ss(m) *  (pi_weight_ss(bigJ))*(r_ss*s_ss_j(bigJ,m))/gam_ss

            
            bequest_ss(m)= sum(bequest_left_ss_j(1:bigJ,m))
            
            bequest_ss_j_old(:,m) = bequest_ss_j(:,m)
            bequest_ss_j(1,m) = 0d0
            
            do j = 2,bigJ,1
                bequest_ss_j(j,m) = up_ss*bequest_ss_j_old(j,m) + (1 - up_ss)*bequest_left_ss_j(j-1,m)/(bigM_share_ss(m) * pi_weight_ss(j))  
            enddo  
            enddo
        elseif (switch_unequal_bequest==1) then
            do m = 1,bigM,1
            bequest_ss_j(1,m) = 0d0
            
            do j = 2,bigJ,1
                bequest_ss_j(j,m) = 0d0
                bequest_left_ss_j(j-1,m) = bigM_share_ss(m) *  (pi_weight_ss(j-1) -   pi_weight_ss(j))*s_ss_j(j-1,m) / nu_ss**(j-1)
            enddo
            
            
            bequest_left_ss_j(bigj,m) = bigM_share_ss(m) *  pi_weight_ss(bigJ) * s_ss_j(bigj,m)       * nu_ss**(-bigj-1)
            bequest_ss(m) = sum(bequest_left_ss_j(1:bigJ,m)) 

            enddo
        endif
    
endif        




        
        if (switch_tauK_gross == 0) then
            r_ss_vfi = (1d0 - tk_ss)*r_bar_ss  
            else
            r_ss_vfi = (1d0 - tk_ss)*(r_bar_ss+depr) - depr
            endif
            
        if (switch_tauK_gross == 0) then
            r_ss_pretax_vfi = r_bar_ss  
            else
            r_ss_pretax_vfi = r_bar_ss
            endif  
            
            
        ! no implicit here, but need to keep track for these objects for conformability    
        do m = 1,bigM,1
            w_ss_j(:,m) = (1-tl_ss)*(1 - t1_ss-t2_ss)*w_bar_ss(m)
            w_pom_ss_implicit(:,m) =  (t1_ss*tau1_ss +  t2_ss*tau2_ss)*w_bar_ss(m) ! will be zero here
            w_pom_ss_j(:,m)=  (1 - t1_ss-t2_ss)*w_bar_ss(m)
        enddo   
        
        
        
        tc_ss_vfi = 1_dp + tc_ss
        gam_ss_vfi = gam_ss
        pi_ss_vfi = pi_ss
        jbar_ss_vf = ceiling(jbar_ss)
        N_ss_j_vfi =  N_ss_j
        iter_com = iter
        sum_b_weight_ss = 0.0d0
        

        ! calling each type separately

        do m = 1,bigM,1
            
            w_bar_ss_vfi = w_bar_ss(m)
            w_pom_ss_vfi =  w_pom_ss_j(:,m) 
            w_pom_ss_implicit_vfi = w_pom_ss_implicit(:,m)
            bequest_ss_vfi =  bequest_ss(m)
            b_ss_j_vfi = b_ss_j(:,m)

            bequest_ss_j_vfi(:) =  bequest_ss_j(:,m)
            bequest_ss_j_vfi_dif(:) = bequest_ss_j(:,m) - bequest_ss_j_old(:,m)
      
            call agent_vf()
            prob_ss_big(:, :, :, :, :, :,m) =  bigM_share_ss(m) * prob_ss
            print*, 'prob_ss sums to  = ', sum(prob_ss), 'for type ', m
            c_ss_j(:,m) = c_ss_j_vfi
            l_ss_j(:,m) = l_ss_j_vfi
            s_ss_j(1:bigJ-1,m) = s_pom_ss_j_vfi(1:bigJ-1) 
            sum_b_weight_ss = sum_b_weight_ss + bigM_share_ss(m) * sum_b_weight_ss_vfi
            labor_tax_ss_j(:,m) = labor_tax_ss_j_vfi(:)
        
        enddo
        
        
        consumption_ss_gross_j = c_ss_j
        savings_ss_j           = s_ss_j
        ! aggregation
        bigl_ss         = 0d0
        average_l_ss    = 0d0
        average_w_ss    = 0d0
        
        consumption_ss_gross = 0d0
        savings_ss = 0d0
        
        avg_ef_l_supply     = 0d0
        LabIncAVG_ss_vfi    = 0d0
        avg_wl              = 0d0
        bigl_ss             = 0d0
        
        do m = 1,bigM,1
            
            bigl_ss                 = bigl_ss + bigM_share_ss(m) * sum(N_ss_j(1:jbar_ss-1)  * l_ss_j(1:jbar_ss-1,m))
            average_l_ss            = average_l_ss + bigM_share_ss(m) * sum(N_ss_j(1:jbar_ss-1)  *  l_ss_j(1:jbar_ss-1,m))/sum(N_ss_j(1:jbar_ss-1)) 
            average_w_ss            = average_w_ss + bigM_share_ss(m) * sum(N_ss_j(1:jbar_ss-1)  *  w_ss_j(1:jbar_ss-1,m) * l_ss_j(1:jbar_ss-1,m))/sum(N_ss_j(1:jbar_ss-1))
            consumption_ss_gross    = consumption_ss_gross + bigM_share_ss(m) * sum(N_ss_j  * consumption_ss_gross_j(:,m))
            
            
            savings_ss              = savings_ss +  bigM_share_ss(m) * sum(N_ss_j  * savings_ss_j(:,m))
            
            
            LabIncAVG_ss_vfi        = LabIncAVG_ss_vfi + bigM_share_ss(m) * sum(N_ss_j(1:jbar_ss-1)*l_ss_j(1:jbar_ss-1,m)*w_pom_ss_j(1:jbar_ss-1,m))/sum(N_ss_j(1:jbar_ss-1)) 
            avg_ef_l_supply         = avg_ef_l_supply + bigM_share_ss(m) * sum(N_ss_j(1:jbar_ss-1)*l_ss_j(1:jbar_ss-1,m))/sum(N_ss_j(1:jbar_ss-1))
            avg_wl                  = avg_wl + bigM_share_ss(m) * sum(w_ss_j(1:jbar_ss-1,m) * l_ss_j(1:jbar_ss-1,m))/(real(jbar_ss-1))
            
        enddo
            consumption_ss_gross    =   consumption_ss_gross/bigl_ss
            savings_ss              =   savings_ss/bigl_ss
            
            
        ! calculate pensions again
            b2_ss_j = 0  
            b1_ss_j(1:jbar_ss-1,:) = 0

            b1_ss_j(jbar_ss,:) = rho*avg_wl !w_ss_j(jbar_ss-1)*l_ss_j(jbar_ss-1) 
            
            do j = jbar_ss+1,bigJ,1
            b1_ss_j(j,:) = valor_mult_ss*b1_ss_j(j-1,:)
            enddo
    
            b_ss_j = b_scale_factor_ss * b1_ss_j 
            
            sum_b_ss = 0.0d0
            do m = 1,bigM,1
                sum_b_ss = sum_b_ss + sum(sum_b_weight_ss*bigM_share_ss(m)*b_ss_j(:,m))/bigl_ss
            enddo
            
            subsidy_ss = 0.0d0
            do m = 1,bigM,1 
                subsidy_ss = subsidy_ss + bigM_share_ss(m)*sum(N_ss_j*(sum_b_weight_ss*b_ss_j(:,m) - t1_ss*w_bar_ss(m)*l_ss_j(:,m)))/bigl_ss
            enddo
           


    

   
   
    

    include 'closure_ss.f90'
         
    k_ss_new = (savings_ss - debt_ss)/(gam_ss*nu_ss)
    err_ss = abs(k_ss_new - k_ss)
    k_ss = up_ss*k_ss + (1 - up_ss)*k_ss_new
    
    
        if (mod(iter,1) == 0) then
            !print*, iter, 'err_ss:', err_ss, 'feas_ss:', abs((y_ss - consumption_ss_gross - g_ss)/y_ss - ((nu_ss*gam_ss+depr-1)*k_ss)/y_ss)
            print*, iter, 'err_ss:', err_ss, 'feas_ss:', abs((y_ss - consumption_ss_gross - g_ss)/y_ss - ((nu_ss*gam_ss+depr-1)*k_ss)/y_ss)
           ! write(121, '(F20.15)') k_ss_new
        endif
        if (err_ss < err_ss_tol ) then
            exit
        endif

    
enddo 
!close (121)

    !do j = 1,bigJ,1
    !    if (j == 1) then
    !        income_ss_j(j) = (1 - tl_ss)*w_ss_j(j)*l_ss_j(j) + sum_b_weight_ss*b_ss_j(j) - upsilon_ss + bequest_ss_j(j)
    !    else
    !        income_ss_j(j) = r_ss*s_ss_j(j-1)/gam_ss + (1 - tl_ss)*w_ss_j(j)*l_ss_j(j) + sum_b_weight_ss*b_ss_j(j)  - upsilon_ss + bequest_ss_j(j)
    !    endif
    !enddo
    !
    !income_ss = sum(N_ss_j*income_ss_j(1:bigJ))/bigl_ss
    !savings_ss_rate_j = s_ss_j/income_ss_j
    
    if (switch_run_1 == 1) then    
        l_ss_pen_j_1 = l_ss_pen_j
        sum_b_weight_trans(1) = sum_b_weight_ss
    else
        l_ss_pen_j_2 = l_ss_pen_j
         sum_b_weight_trans(2:) = sum_b_weight_ss
    endif

    tc_new = tc_ss
    tl_new = tl_ss
    
if (switch_run_1 == 1) then    
    s_pom_ss_j_1 = s_pom_ss_j
    tau1_ss_1 = tau1_ss
    tau2_ss_1 = tau2_ss
    w_pom_ss_j_1 = w_pom_ss_j
    bequest_left_ss_j_1 = bequest_left_ss_j
    labor_tax_j_ss_1 = labor_tax_ss_j
    g_share_ss = g_ss/y_ss
    g_share(1) = g_share_ss
else
    s_pom_ss_j_2 = s_pom_ss_j
    tau1_ss_2 = tau1_ss
    tau2_ss_2 = tau2_ss
    w_pom_ss_j_2 = w_pom_ss_j
    bequest_left_ss_j_2 = bequest_left_ss_j
    labor_tax_j_ss_2 = labor_tax_ss_j
    
    tc_new = tc_ss
    tk_new = tk_ss
    tl_new = tl_ss
endif

    mult_ss = 0   
    do j = 1,bigJ,1
        if (j == 1) then
            mult_ss = 1
        else
            mult_ss = mult_ss + beta*delta**(j-1)*pi_ss(j)/pi_ss(1)
        endif
    enddo

    
    !include 'utility_ss.f90' 

    !replacement_ss = sum_b_weight_ss*b_ss_j_vfi(jbar_ss)/((1 - t1_ss - t2_ss)*w_bar_ss*l_ss_pen_j(jbar_ss-1))   
    if (switch_print == 1) then
        include 'Print_steady_db.f90'
    endif
    
    k_ss_o = k_ss
    
    !! calculate marginal
    ! prob_ss_marg = 0d0
    !        do ia = 0, n_a, 1
    !             do j = 1, bigJ  
    !                 do i_aime = 0, n_aime, 1
    !                      do ip = 1 , n_sp, 1
    !                        do ir=1, n_sr, 1
    !                            do id=1,n_sd,1 
    !                            prob_ss_marg(ia) = prob_ss_marg(ia) + prob_ss(j, ia, i_aime, ip, ir, id)* N_ss_j(j)/N_ss
    !                            enddo
    !                        enddo
    !                    enddo
    !                enddo
    !            enddo
    !        enddo 

    

            
end subroutine steady

END MODULE steady_state