! WHAT   : this function takes some exogenous variables and calculates profiles


MODULE prof_steady
use global_vars
!use individual_vf
use pfi_trans


IMPLICIT NONE

CONTAINS

subroutine profile_steady(switch_tauK_gross, switch_unequal_bequest, param_ss, &
    rho, tc_ss, r_bar_ss, w_bar_ss, b_ss_j, bequest_ss_j, bequest_ss)
    real(dp) :: jbar_ss, gam_ss, N_ss, nu_ss, &
                upsilon_ss
    real(dp), dimension(bigM) :: type_multiplier_ss, type_share_ss
    real(dp), dimension(bigj) :: pi_ss, pi_weight_ss
    real(dp), dimension(bigj,bigM) :: N_big_ss_j, pi_big_ss, pi_big_weight_ss 
    real(dp)  :: aime_dist
    real(dp), intent(in)  :: rho, r_bar_ss, tc_ss
    
    real(dp), dimension(bigj,bigM),  intent(in)  :: bequest_ss_j, b_ss_j	
    real(dp),  dimension(bigM), intent(in)  :: bequest_ss
    integer, intent(in)   :: param_ss
    integer, intent(in)   :: switch_tauK_gross, switch_unequal_bequest

    real(dp), dimension(bigM), intent(in)  :: w_bar_ss
    integer :: it
    ! pension system 
     real(dp), dimension(bigj,bigM) :: w_pom_ss_implicit 
     real(dp), dimension(bigj) :: N_ss_j
     real(dp), dimension(bigM) :: w_pom_ss
     
     real(dp) :: b_scale_factor_ss, t1_ss, t2_ss
              
     real(dp), dimension(bigj) :: tau1_ss, tau1_a_ss, tau2_ss
     real(dp), dimension(bigj,bigM) :: w_pom_ss_j, s_pom_ss_j

     
     real(dp), dimension(bigj,bigM) ::w_ss_j, l_ss_pen_j, labor_tax_ss_j,c_ss_j,  l_ss_j, s_ss_j ,pension_ss_j, lab_ss_j, tot_income_ss_j, lab_income_ss_j, tot_income_pretax_ss_j, lab_income_pretax_ss_j, asset_ss_j

     !real*8, dimension(bigJ) :: V_ss_j_vfi, c_ss_j_vfi, s_pom_ss_j_vfi, l_ss_j_vfi, lab_ss_j_vfi, b_ss_j_vfi, &
     !                      bequest_ss_j_vfi, bequest_ss_j_vfi_dif, pi_ss_vfi, pi_ss_vfi_cond, l_ss_pen_j_vfi, &
     !                      labor_tax_ss_j_vfi, lw_ss_j_vfi, lw_lambda_ss_j_vfi, w_pom_ss_vfi, w_pom_ss_implicit_vfi, lab_high_j_vfi 
     real*8, dimension(bigJ, 0:n_a, 0:n_aime, n_sp, n_sr,n_sd,bigM) :: prob_ss_big, aime_plus_ss_big, aime_plus_ss_big_old
    
    real(dp), dimension(bigj, n_a) :: V_ss_j
write(*,*) 'Obtaining profiles... '
if (param_ss == 0) then ! 0 = with old parameters;  1 = with new parameters
        alpha = alpha_ss_old
        depr = depr_ss_old
        gam_ss = gam_ss_old
        pi_big_ss = pi_big_ss_old 
        pi_big_weight_ss = pi_big_weight_ss_old
        N_big_ss_j =  N_big_ss_old
        jbar_ss = jbar_ss_old
        nu_ss =  nu_ss_old
        t1_ss = t1_ss_old
        t2_ss = t2_ss_old
        tL_ss   = tauL_ss_old
        tK_ss   = tauK_ss_old
        lambda= lambda_ss_old
        debt_constr= debt_constr_ss_old
        pi_ip_big = pi_ip_ss_old_big
        n_sp_value_big = n_sp_value_ss_old_big
        pi_ip_init_big = pi_ip_init_ss_old_big
        g_share_ss = g_share_ss
        type_multiplier_ss =  type_multiplier_ss_old
        type_share_ss = type_share_ss_old
        
    else 
        alpha = alpha_ss_new
        depr = depr_ss_new
        gam_ss = gam_ss_new
        pi_big_ss = pi_big_ss_new
        pi_big_weight_ss = pi_big_weight_ss_new
        N_big_ss_j =  N_big_ss_new
        jbar_ss = jbar_ss_new
        nu_ss = nu_ss_new
        t1_ss = t1_ss_new
        t2_ss = t2_ss_new
        tL_ss  = tauL_ss_new
        tK_ss   = tauK_ss_new
        lambda = lambda_ss_new
        
        pi_ip_big = pi_ip_ss_new_big
        debt_constr= debt_constr_ss_new
        n_sp_value_big = n_sp_value_ss_new_big
        pi_ip_init_big = pi_ip_init_ss_new_big
        g_share_ss = g_share_ss_2
        type_multiplier_ss =  type_multiplier_ss_new
        type_share_ss = type_share_ss_new
         
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
        
        ! this is the main part
        ! calling each type separately
        V_ss_big = V_ss_big !* 0.d0    
        do it = 1,n_iter_prof,1
            aime_plus_ss_big_old = aime_plus_ss_big
        do m = 1,bigM,1
            
            ! load shock matrices
            omega_ss  = omega_ss_big(:,m)
            pi_ip = pi_ip_big(:,:,m)
            n_sp_value = n_sp_value_big(:,m)
            pi_ip_init = pi_ip_init_big(:,m)
            pi_ss(:) = pi_big_ss(:,m)
            pi_ss_vfi = pi_ss
            N_ss_j_vfi =  N_big_ss_j(:,m)
            w_bar_ss_vfi = w_bar_ss(m)
            w_pom_ss_vfi =  w_pom_ss_j(:,m) 
            w_pom_ss_implicit_vfi = w_pom_ss_implicit(:,m)
            bequest_ss_vfi =  bequest_ss(m)
            b_ss_j_vfi = b_ss_j(:,m)
            bequest_ss_j_vfi(:) =  bequest_ss_j(:,m)
            upsilon_ss_vf = 0d0
            aime_plus_ss  = aime_plus_ss_big(:, :, :, :, :, :,m)
            V_ss = V_ss_big(:, :, :, :, :, :,m)          
            
            
            call agent_vf()
            c_ss_j(:,m) = c_ss_j_vfi
            l_ss_j(:,m) = l_ss_j_vfi
            lab_ss_j(:,m) = lab_ss_j_vfi
            s_ss_j(1:bigJ-1,m) = s_pom_ss_j_vfi(1:bigJ-1) 
            labor_tax_ss_j(:,m) = labor_tax_ss_j_vfi(:)
            lab_ss_j(:,m) = lab_ss_j_vfi(:)
            pension_ss_j(:,m) = pension_ss_j_vfi(:)
            asset_ss_j(:,m) = asset_pom_ss_j(:)
            lab_income_ss_j(:,m) = lab_income_ss_j_vfi(:)
            lab_income_pretax_ss_j(:,m) = lab_income_pretax_ss_j_vfi(:)
            tot_income_ss_j(:,m) = tot_income_ss_j_vfi(:)
            tot_income_pretax_ss_j(:,m) = tot_income_pretax_ss_j_vfi(:)
            
            prob_ss_big(:, :, :, :, :, :,m)          = prob_ss
            aime_plus_ss_big(:, :, :, :, :, :, m)    = aime_plus_ss
            c_ss_big(:, :, :, :, :, : ,m)            = c_ss 
            srate_ss_big(:, :, :, :, :, : ,m)        = srate_ss 
            l_ss_big(:, :, :, :, :, : ,m)            = l_ss
            lab_income_ss_big(:, :, :, :, :, :,m)    = lab_income_ss
            lab_income_pretax_ss_big(:, :, :, :, :, :,m) = lab_income_pretax_ss
            tot_income_ss_big(:, :, :, :, :, :,m)        = tot_income_ss
            tot_income_pretax_ss_big(:, :, :, :, :, :,m) = tot_income_pretax_ss
            labor_tax_big(:, :, :, :, :, :,m)            = labor_tax
            svplus_ss_big(:, :, :, :, :, :,m)            = svplus_ss
            V_ss_big(:, :, :, :, :, :,m)                 = V_ss
            disposable_ss_big(:, :, :, :, :, :,m)        = disposable_ss
        enddo
        aime_dist = maxval(abs(aime_plus_ss_big - aime_plus_ss_big_old))
        write(*,'(A30,F10.7,A)') ' aime_dist = ', aime_dist
        if (aime_dist < err_prof_tol ) then
            exit
        endif
        enddo
   open(unit = 107, FILE = version//experiment//closure//variant//"profiles.csv")
     write(107, '(A)') "type;age;s;c;l;asset;lab_inc;lab_inc_pre;tot_inc;tot_inc_pre;lab_tax;pension"
   
            do j = 1, bigJ, 1
                do m = 1, bigM, 1
                                write(107, '(I5,A,I5,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10)') &
                                m , ";",  & !type
                                j , ";",  & !age
                                s_ss_j(j,m) , ";",  & !savings
                                c_ss_j(j,m) , ";",  & !consumpion
                                l_ss_j(j,m) , ";",  & !labor supply
                                asset_ss_j(j,m) , ";",  & !labor supply
                                lab_income_ss_j(j,m) , ";",  & !labor supply
                                lab_income_pretax_ss_j(j,m) , ";",  & !labor supply
                                tot_income_ss_j(j,m) , ";",  & !labor supply
                                tot_income_pretax_ss_j(j,m) , ";",  & !labor supply
                                tot_income_pretax_ss_j(j,m) , ";",  & !labor supply
                                labor_tax_ss_j(j,m) , ";",  &!labor tax
                                pension_ss_j(j,m)!pension
                                enddo        
                            enddo

             close(107)
             
    if (switch_ss_write == 1) then  
             open(unit = 108, FILE = version//experiment//closure//variant//"profiles_full.csv")
    write(108, '(A)') "value;mass;sav;asset;cons;hours;labinc;labinc_pretax;totinc;totinc_pretax;pension;disposable;srate;age;asset_ind;aime;inc_shock;ret_shock;type;disc_shock"
        do m = 1, bigM, 1
            do j = 1, bigJ, 1
                do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1, n_sp, 1
                            do ir = 1, n_sr, 1
                                do id = 1, n_sd, 1
                                write(108, '(F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5)') &
                                V_ss_big(j, ia, i_aime, ip, ir, id, m), ";", & ! value
                                prob_ss_big(j, ia, i_aime, ip, ir, id, m)*n_big_ss_j(j,m)/sum(n_big_ss_j(:,:)), ";", & ! mass
                                svplus_ss_big(j, ia, i_aime, ip, ir, id, m), ";", & ! savings
                                sv(ia), ";", & ! savings
                                c_ss_big(j, ia, i_aime, ip, ir, id, m), ";", & !consumption
                                l_ss_big(j, ia, i_aime, ip, ir, id, m), ";", & !hours
                                lab_income_ss_big(j, ia, i_aime, ip, ir, id, m), ";", & !lab income
                                lab_income_pretax_ss_big(j, ia, i_aime, ip, ir, id, m), ";", & !lab income pretax
                                tot_income_ss_big(j, ia, i_aime, ip, ir, id, m) , ";", & !tot income
                                tot_income_pretax_ss_big(j, ia, i_aime, ip, ir, id, m) , ";", & !tot income pretax
                                aime_replacement_rate(i_aime)*b_ss_j(j,m), ";", & !pension
                                disposable_ss_big(j, ia, i_aime, ip, ir, id, m), ";", & !beginning of period resources
                                srate_ss_big(j, ia, i_aime, ip, ir, id, m), ";", & ! savings rate
                                j , ";",  & !age
                                ia , ";",  & !asset
                                i_aime , ";",  & !aime
                                ip , ";",  & !income
                                ir , ";",  & !return
                                m , ";",  & !type
                                id  !discount
                                
                                enddo        
                            enddo
                        enddo
                    enddo
                enddo
            enddo
        enddo
    
    endif
             
end subroutine profile_steady

END MODULE prof_steady