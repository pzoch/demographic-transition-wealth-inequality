    
    if ( switch_run_1 == 1) then 
    no_steady = 'ss1_'    
    else
    no_steady = 'ss2_'
    endif
    
    
    
    
    ! write on the screen
        write(*,*) '******* STEADY STATE PAYG *******'
        write(*,*)
        write(*,*) '*********************************'
        write(*,*)
        write(*,'(A30,F10.3,A)') ' err_ss = ', err_ss
        write(*,'(A30,F10.3,A)') ' k_ss = ', k_ss
        if (any(rate_adj /= 0.0d0)) then
            write(*,'(A30,F10.5,A)') ' r_low_ss = ', r_low_ss
            do m = 1,bigM,1
                write(*,'(A25,I2,A3,F10.5,A)') ' r_type_ss(', m, ') = ', r_type_ss(m)
            enddo
        endif
        write(*,'(A30,F10.3,A)') ' y_ss = ', y_ss
        write(*,'(A30,F10.3,A)') ' K_ss = ', k_ss*bigl_ss/N_ss_j(1)
        write(*,'(A30,F10.3,A)') ' L_ss = ', bigl_ss/N_ss_j(1)
        write(*,'(A30,F10.3,A)') ' capital output ratio = ', k_ss/(y_ss/zbar)
        write(*,'(A30,F10.3,A)') ' capital labour ratio = ', k_ss/bigl_ss
        write(*,'(A30,F10.3,A)') ' capital share = ', ((r_bar_ss + depr)*k_ss/y_ss)
        !write(*,'(A30,F10.7,A)') ' l_ss_pen_j(jbar-1) = ', l_ss_pen_j(jbar_ss-1)
        !write(*,'(A30,F10.7,A)') ' l_ss_j(jbar-1) = ', l_ss_j(jbar_ss-1)
            write(*,'(A30,F10.3,A)') ' N_ss = ', N_ss
        write(*,'(A30,F10.3,A)') ' bigl_ss = ', bigl_ss
        !write(*,'(A30,F10.3,A)') ' savings_top_ten = ',  savings_top_ten(10)/asset_pom_ss
        !write(*,'(A30,F10.3,A)') ' savings_top_100 = ',  savings_top_100(100)/asset_pom_ss
        write(*,'(A30,F10.3,A)') 'share negative assets =', share_neg
        write(*,'(A30,F10.3,A)') 'share nonpositive assets =', share_nonpos
        write(*,'(A30,F10.3,A)') ' tc = ',  tc_ss
        write(*,'(A30,F10.3,A)') ' tk = ',  tk_ss
        write(*,'(A30,F10.3,A)') ' tl = ',  tl_ss
        write(*,'(A30,F10.3,A)') ' rho (policy param) = ', rho
        write(*,'(A30,F10.3,A)') ' phi = ',  phi
        write(*,'(A30,F10.3,A)') ' delta = ', delta
        write(*,'(A30,F10.3,A)') ' b_scale_factor_ss = ', b_scale_factor_ss
        write(*,'(A30,F10.3,A)') ' contribution rate = ',  t1_ss
        write(*,'(A30,F10.3,A)') ' lambda = ',  lambda
        write(*,'(A30,F10.3,A)') ' repl. at retire (endg) = ',  replacement_ss
        write(*,'(A30,F10.6,A)') ' feasibility (frac. GDP) = ', abs((y_ss - consumption_ss_gross - g_ss)/y_ss - ((nu_ss*gam_ss+depr-1)*k_ss)/y_ss) 
        write(*,*) '********************************************'

!   
    OPEN (unit=666, FILE = variant//"information_run.txt")
         write(666, '(A)') '******* INFORMATION *******'
         write(666, '(A)')
         write(666, '(A)') '*********************************'
         write(666, '(A)') 'THIS STEADY STATE HAD THE FOLLOWING PARAMETERS' 
         write(666, '(A)')
         write(666,'(A30,F6.3 )') 'alpha =',  alpha  
         write(666,'(A30,F6.3 )') 'theta =',  theta 
         write(666,'(A30,F6.3 )') 'depr =',  depr 
         write(666,'(A30,F6.3 )') 'rho_subst =',  rho_subst 
         write(666,'(A30,F6.3 )') 'alpha =',  alpha 
         write(666,'(A30,F6.3 )') 'frisch =',  frisch 
         write(666,'(A30,F6.3 )') 'disutil =',  disutil 
         write(666,'(A30,F6.3 )') 'phi =',  phi 
         write(666,'(A30,F6.3 )') 'gam_ss =',     gam_ss  
         write(666,'(A30,F6.3 )') 'jbar_ss =',     jbar_ss  
         write(666,'(A30,F6.3 )') 'nu_ss =',     nu_ss  
         write(666,'(A30,F6.3 )') 't1_ss =',     t1_ss  
         write(666,'(A30,F6.3 )') 't2_ss =',     t2_ss  
         write(666,'(A30,F6.3 )') 'tL_ss =',     tL_ss
         write(666,'(A30,F6.3 )') 'tK_ss =',     tK_ss  
         write(666,'(A30,F6.3 )') 'tC_ss =',     tC_ss  
         write(666,'(A30,F6.3 )') 'rho =' ,      rho 
         write(666,'(A30,F6.3 )') 'lambda =',     lambda 
         write(666,'(A30,F6.3 )') 'debt_constr =',     debt_constr  
         write(666,'(A30,F6.3 )') 'g_share_ss =',     g_share_ss          
         write(666,'(A30,F6.3 )') 'err_tol =',     err_tol  
         write(666,'(A30,F6.3 )') 'frisch =',     frisch  
         write(666,'(A30,F6.3 )') 'depr =',     depr  
         write(666,'(A30,F6.3 )') 'rho_subst =',     rho_subst  
         write(666,'(A30,F6.3 )') 'delta =',     delta  
         write(666,'(A30,F6.3 )') 'phi =',     phi  
         write(666, '(A)')
         write(666, '(A)') '*********************************'
         write(666, '(A)') 'THIS STEADY STATE HAD THE FOLLOWING VALUES' 
         write(666, '(A)')
        
        write(666,'(A25,F10.5,A)') 'Gini on sav =  ', gini_val_sav
        write(666,'(A25,F10.3,A)') '100*beq_sum_ss/y =  ', 100*beq_sum_ss/y_ss
        write(666,'(A25,F10.3,A)') '100*sum_b/y =  ', 100*sum_b_ss/y_ss         
        write(666,'(A25,F10.3,A)') ' average hours (%) =  ', 100*average_lab_ss 
        write(666,'(A30,F10.3,A)') ' Pre-tax real interest rate (1y) = ', 100*((1 + r_bar_ss)**0.2_dp -1d0)
        write(666,'(A30,F10.3,A)') ' After-tax real interest rate (1y) = ', 100*(r_ss**0.2_dp -1d0)
        write(666,'(A25,F10.3,A)') ' investment rate (%) =  ', 100*(y_ss - consumption_ss_gross - g_ss)/y_ss 
        write(666,'(A20,F10.3,A)') ' Tax_C/y_ss = ',  100*tc_ss*consumption_ss_gross/y_ss 
        write(666,'(A20,F10.3,A)') ' Tax_K/y_ss = ',  100*tk_ss*(r_bar_ss + depr)*k_ss/y_ss
        write(666,'(A20,F10.3,A)') ' Tax_L/y_ss = ',  100*labor_tax_revenue_ss/bigl_ss/y_ss
        write(666,'(A20,F10.3,A)') 'r*debt/y = ', ((1 + r_bar_ss)*debt_ss/(gam_ss*nu_ss) - debt_ss)/y_ss
        write(666,'(A20,F10.3,A)') 'g/y = ',   g_ss/y_ss
        write(666,'(A20,F10.3,A)') 'debt/y (%) (1y) = ',  100*zbar * debt_share_ss
        
        write(666,'(A20,F10.3,A)') 'subsidy/y = ',   subsidy_ss/y_ss
        write(666,'(A20,F10.3,A)') 'gam_ss*nu_ss = ',   gam_ss*nu_ss
        
        write(666,*) '*********************************'
        write(666,*)
        write(666,'(A30,F10.3,A)') ' err_ss = ', err_ss
        write(666,'(A30,F10.3,A)') ' k_ss = ', k_ss
        if (any(rate_adj /= 0.0d0)) then
            write(666,'(A30,F10.5,A)') ' r_low_ss = ', r_low_ss
            do m = 1,bigM,1
                write(666,'(A25,I2,A3,F10.5,A)') ' r_type_ss(', m, ') = ', r_type_ss(m)
            enddo
        endif
        write(666,'(A30,F10.3,A)') ' y_ss = ', y_ss
        write(666,'(A30,F10.3,A)') ' K_ss = ', k_ss*bigl_ss/N_ss_j(1)
        write(666,'(A30,F10.3,A)') ' L_ss = ', bigl_ss/N_ss_j(1)
        write(666,'(A30,F10.3,A)') ' capital output ratio (1y) = ', k_ss/(y_ss/zbar)
        write(666,'(A30,F10.3,A)') ' capital share = ', ((r_bar_ss + depr)*k_ss/y_ss)
        !write(666,'(A30,F10.7,A)') ' l_ss_pen_j(jbar-1) = ', l_ss_pen_j(jbar_ss-1)
        !write(666,'(A30,F10.7,A)') ' l_ss_j(jbar-1) = ', l_ss_j(jbar_ss-1)
            write(666,'(A30,F10.3,A)') ' N_ss = ', N_ss
        write(666,'(A30,F10.3,A)') ' bigl_ss = ', bigl_ss
        !write(666,'(A30,F10.3,A)') ' savings_top_ten = ',  savings_top_ten(10)/asset_pom_ss
        !write(666,'(A30,F10.3,A)') ' savings_top_100 = ',  savings_top_100(100)/asset_pom_ss
        write(666,'(A30,F10.3,A)') 'share negative assets =', share_neg
        write(666,'(A30,F10.3,A)') 'share nonpositive assets =', share_nonpos
        write(666,'(A30,F10.3,A)') ' tc = ',  tc_ss
        write(666,'(A30,F10.3,A)') ' tk = ',  tk_ss
        write(666,'(A30,F10.3,A)') ' tl = ',  tl_ss

        write(666,'(A30,F10.3,A)') ' contribution rate = ',  t1_ss
        write(666,'(A30,F10.3,A)') ' lambda = ',  lambda
        write(666,'(A30,F10.3,A)') ' repl. at retire (endg) = ',  replacement_ss
        write(666,'(A30,F10.6,A)') ' feasibility (frac. GDP) = ', abs((y_ss - consumption_ss_gross - g_ss)/y_ss - ((nu_ss*gam_ss+depr-1)*k_ss)/y_ss) 
        
         write(666, '(A)')
         write(666, '(A)') 'OPTIONS THAT WERE USED:' 
         write(666, '(A)')
         write(666,'(A30,I5.1)') 'switch_fix_labor =', switch_fix_labor
         write(666,'(A30,I5.1)') 'switch_unequal_bequest =', switch_unequal_bequest
         write(666,'(A30,I5.1)') 'beq_age =', beq_age
         write(666,'(A30,I5.1)') 'zipf =', zipf
         write(666,'(A30,I5.1)') 'switch_tauK_gross =',  switch_tauK_gross              
         write(666,'(A30,I5.1)') 'switch_epsilon_corr =',    switch_epsilon_corr            
         write(666,'(A30,I5.1)') 'switch_steady_demo =', switch_steady_demo   
         write(666,'(A30,I5.1)') 'superstars =',   (n_p > 5)
         write(666, '(A)')
         write(666, '(A)') 'mortality was ...' 
         do i = 1,bigJ,1
            write(666,'(A30,F20.10 )') ' ', pi_ss(i)
         enddo
         write(666, '(A)')
         write(666, '(A)') 'population weights ...' 
         do m = 1,bigM,1
             do i = 1,bigJ,1
                write(666,'(A30,F20.10 )') ' ', pi_big_weight_ss(i,m)
             enddo
         enddo
         write(666, '(A)')
         write(666, '(A)') 'types income risk autocorrelation ...' 
         do m = 1,bigM,1
            write(666,'(A30,F20.10 )') ' ', zeta_p(m)
         enddo
         
         write(666, '(A)')
         write(666, '(A)') 'bequest probabilities was ...' 
         do i = 1,n_beq,1
            write(666,'(A30,F20.10 )') ' ', p_beq(i)
         enddo
        write(666, '(A)')
        write(666, '(A)') 'types income risk variance ...' 
        if (switch_run_1 == 1) then
         do m = 1,bigM,1
            write(666,'(A30,F20.10 )') ' ', sigma2_epsilon_t_big(1,m)
         enddo
        else 
        do m = 1,bigM,1
            write(666,'(A30,F20.10 )') ' ', sigma2_epsilon_t_big(bigT,m)
        enddo
        endif
         CLOSE(666)
    
!open(unit = 234, FILE = version//experiment//closure//variant//"mass_trans.csv")
!write(234, '(A)') "mass;cons;hours;labinc;labinc_pretax;totinc;totinc_pretax;sav;age;asset;aime;inc_shock;ret_shock;disc_shock;type"
!    do j = 1, bigJ, 1
!        do m = 1, bigM, 1
!            do ia = 0, n_a, 1
!                do i_aime = 0, n_aime, 1
!                    do ip = 1, n_sp, 1
!                        do ir = 1, n_sr, 1
!                            do id = 1, n_sd, 1
!                            write(234, '(F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5)') &
!                            prob_ss_big(j, ia, i_aime, ip, ir, id,m)*N_big_ss_j(j,m)/sum(N_big_ss_j(:,:)), ";", & ! mass
!                            c_ss_big(j, ia, i_aime, ip, ir, id,m), ";", & !consumption
!                            l_ss_big(j, ia, i_aime, ip, ir, id,m), ";", & !hours
!                            lab_income_ss_big(j, ia, i_aime, ip, ir, id,m), ";", & !lab income
!                            lab_income_pretax_ss_big(j, ia, i_aime, ip, ir, id,m), ";", & !lab income pretax
!                            tot_income_ss_big(j, ia, i_aime, ip, ir, id,m), ";", & !tot income
!                            tot_income_pretax_ss_big(j, ia, i_aime, ip, ir, id,m), ";", & !tot pretax income
!                            svplus_ss_big(j, ia, i_aime, ip, ir, id,m), ";", & !sav
!                            j , ";",  & !age
!                            ia , ";",  & !asset
!                            i_aime , ";",  & !aime
!                            ip , ";",  & !income
!                            ir , ";",  & !return
!                            id , ";",  & !discount
!                            m   !type
!                            enddo        
!                        enddo
!                    enddo
!                enddo
!            enddo
!        enddo
!    enddo
!
!close(234) 

!    write(666, '(A)') "Outcomes"
!    write(666, '(A)') "y;k/y;c/y;i/y;bigl;r;tauC;tauK;tauL;lambda;beq/y;gam_ss;average hours;r-g;replacement;"
!    write(666, '(F20.10,A)', advance='no') y_ss, ";"
!    write(666, '(F20.10,A)', advance='no') k_ss/y_ss, ";"
!    write(666, '(F20.10,A)', advance='no') consumption_ss_gross/(y_ss), ";"
!    write(666, '(F20.10,A)', advance='no') ((gam_ss+depr-1)*k_ss)/y_ss, ";"
!    write(666, '(F20.10,A)', advance='no') bigl_ss, ";"
!    write(666, '(F20.10,A)', advance='no') r_ss, ";"
!    write(666, '(F20.10,A)', advance='no') tc_ss, ";"
!    write(666, '(F20.10,A)', advance='no') tk_ss, ";"
!    write(666, '(F20.10,A)', advance='no') tl_ss, ";"
!    write(666, '(F20.10,A)', advance='no')lambda, ";"
!    write(666, '(F20.10,A)', advance='no') bequest_ss/y_ss, ";"
!    write(666, '(F20.10,A)', advance='no') gam_ss, ";"
!    write(666, '(F20.10,A)', advance='no') bigl_ss/sum(N_ss_j(1:jbar_ss-1)), ";"
!    write(666, '(F20.10,A)', advance='no') r_ss-gam_ss, ";"
!    write(666, '(F20.10,A)', advance='no') replacement_ss, ";"
!
!    write(666, '(A)') ""
!    write(666, '(A)') "Lifecycle"
!    write(666, '(A)') "yr;c;l;s;V;disc"
!    !do j = 1, bigJ
!    !    write(666, '(I2,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10)') j, ";", c_ss_j(j), ";", l_ss_j(j), ";", s_ss_j(j), ";", V_ss_j_vfi(j), ";", beta*delta**(j-1)*(pi_ss(j)/pi_ss(1))
!    !enddo
!CLOSE(666)
