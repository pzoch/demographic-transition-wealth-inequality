    
    if ( switch_run_1 == 1) then 
    no_steady = 'ss1_'    
    else
    no_steady = 'ss2_'
    endif
    
    
    
    
    ! write on the screen
        write(*,*) '******* STEADY STATE PAYG *******'
        write(*,*)
        write(*,*) '*********************************'
        write(*,*) 'Calibration:'
        write(*,*)
        
        
        ! most of it has to be removed, we do not care about these... 
        if  (bigJ == 16)  then ! US
            write(*,'(A25,F10.7,A)') ' 100*sum_b/y =  ', 100*sum_b_ss/y_ss, '  |  Should be 5.2%'
            error_pen_sys = 100*sum_b_ss/y_ss - 5.20d0
        else
            write(*,'(A25,F10.7,A)') ' 100*sum_b/y = ', 100*sum_b_ss/y_ss, '  |  Should be 5%'
        endif
        write(*,'(A25,F10.7,A)') ' 100*subsidy/y =', 100*subsidy_ss/y_ss, '  |  Should be 0.0%'
        if (bigJ == 16)  then
            if (switch_vf > 0) then 
            write(*,'(A25,F10.7,A)') ' average hours =  ', 100*sum(N_ss_j(1:jbar_ss-1)*lab_ss_j_vfi(1:jbar_ss-1))/sum(N_ss_j(1:jbar_ss-1)), '  |  Should be 33%' 
             error_labor = 100*sum(N_ss_j(1:jbar_ss-1)*lab_ss_j_vfi(1:jbar_ss-1))/sum(N_ss_j(1:jbar_ss-1))

            else 
            write(*,'(A25,F10.7,A)') ' average hours = ', bigl_ss/sum(N_ss_j(1:jbar_ss-1)), '  |  Should be 33%'    
            endif
        else
            write(*,'(A25,F10.7,A)') ' average hours = ', bigl_ss/sum(N_ss_j(1:jbar_ss-1)), '  |  Should be 56.8%' 
        endif
            if (bigJ == 4) then
                write(*,'(A20,F10.7,A)') ' 1 + r_bar_ss = ', (1 + r_bar_ss)**0.05_dp, '  |  Should be 7.8%'
                write(*,'(A20,F10.7,A)') ' r_ss = ', r_ss**0.05_dp
            elseif (bigJ == 20)  then   
                write(*,'(A20,F10.7,A)') ' 1 + r_bar_ss = ', (1 + r_bar_ss)**0.25_dp, '  |  Should be 7.8%'
                write(*,'(A20,F10.7,A)') ' r_ss = ', r_ss**0.25_dp
           elseif (bigJ == 16)  then   ! US
                write(*,'(A25,F10.7,A)') ' 1 + r_bar_ss = ', 100*((1 + r_bar_ss)**0.2_dp -1d0), '  |  Should be 5.5%'
                write(*,'(A25,F10.7,A)') ' r_ss = ', r_ss**0.2_dp
                write(*,'(A25,F10.7,A)') ' investment rate =  ', 100*(y_ss - consumption_ss_gross - g_ss)/y_ss, ' %  |  Should be 21%'

            else
                write(*,'(A20,F10.7,A)') ' 1 + r_bar_ss = ', 1 + r_bar_ss, '  |  Should be 7.8%'
                write(*,'(A20,F10.7,A)') ' r_ss = ', r_ss
                
                write(*,'(A20,F10.7,A)') ' investment rate = ', (y_ss - consumption_ss_gross - g_ss)/y_ss, '  |  Should be 21%'
                write(*,'(A20,F10.7,A)') ' investment rate = ', ((gam_ss+depr-1)*k_ss)/y_ss
  
            endif       
        write(*,'(A20,F10.7,A)') 'Tax_C/y_ss = ',  100*tc_ss*consumption_ss_gross/y_ss, '  |  Should be 2.8%'
        error_tc = 100*tc_ss*consumption_ss_gross/y_ss
        write(*,'(A20,F10.7,A)') 'Tax_K/y_ss = ',  100*tk_ss*r_bar_ss*sum_priv_sv_ss/(gam_ss*nu_ss)/y_ss, '  |  Should be 5.4%'
        error_tk = 100*tk_ss*r_bar_ss*sum_priv_sv_ss/gam_ss/y_ss
       ! write(*,'(A20,F10.7,A)') 'Tax_Lw/y_ss = 9.2 +', 100*tL_ss*(1 - t1_ss)*w_bar_ss/y_ss-9.2d0, '  |  Should be 9.2%'
        write(*,'(A20,F10.7,A)') 'Tax_Lw/y_ss =', 100*sum(N_ss_j*labor_tax_ss_j_vfi(1:bigJ))/bigl_ss/y_ss, '  |  Should be 9.2%' 
        error_tl = 100*sum(N_ss_j*labor_tax_ss_j_vfi(1:bigJ))/bigl_ss/y_ss 
        write(*,'(A20,F10.7,A)') 'r*debt/y = ', ((1 + r_bar_ss)*debt_ss/(gam_ss*nu_ss) - debt_ss)/y_ss
        write(*,'(A20,F10.7,A)') 'g/y = ',   g_ss/y_ss
        write(*,'(A20,F10.7,A)') 'subsidy/y = ',   subsidy_ss/y_ss
        write(*,'(A20,F10.7,A)') 'gam_ss*nu_ss = ',   gam_ss*nu_ss
        write(*,'(A20,F10.7,A)') 'r= ',   1 + r_bar_ss
        
        
        write(*,*) '*********************************'
        write(*,*)
        write(*,'(A30,F10.7,A)') ' err_ss = ', err_ss
        write(*,'(A30,F10.7,A)') ' k_ss = ', k_ss
        write(*,'(A30,F10.7,A)') ' y_ss = ', y_ss
        write(*,'(A30,F10.7,A)') ' K_ss = ', k_ss*bigl_ss/N_ss_j(1)
        write(*,'(A30,F10.7,A)') ' L_ss = ', bigl_ss/N_ss_j(1)
        write(*,'(A30,F10.7,A)') ' w_bar_ss = ', w_bar_ss
        write(*,'(A30,F10.7,A)') ' capital output ratio = ', k_ss/(y_ss/zbar)
        error_delta = 10*(k_ss/(y_ss/zbar) - K_Y_target)

        write(*,'(A30,F10.7,A)') ' capital labour ratio = ', k_ss/bigl_ss
        write(*,'(A30,F10.7,A)') ' labour share = ', w_bar_ss/y_ss
        write(*,'(A30,F10.7,A)') ' capital share = ', ((r_bar_ss + depr)*k_ss/y_ss)
        write(*,'(A30,F10.7,A)') ' l_ss_pen_j(jbar-1) = ', l_ss_pen_j(jbar_ss-1)
        write(*,'(A30,F10.7,A)') ' l_ss_j(jbar-1) = ', l_ss_j(jbar_ss-1)
        write(*,*) ' u_ss = ', V_ss_j_vfi(1)
        write(*,*) ' mult = ', mult_ss
        write(*,*)
        write(*,'(A30,F16.7,A)') ' N_ss = ', N_ss
        write(*,'(A30,F16.7,A)') ' bigl_ss = ', bigl_ss
        write(*,'(A30,F16.7,A)') ' bequest_ss = ', bequest_ss
        write(*,*)
        write(*,'(A40,F10.7,A)') ' 100*(upsilon_ss*N_ss/bigl_ss)/y_ss = ', 100*(upsilon_ss*N_ss/bigl_ss)/y_ss
        write(*,*)
        write(*,'(A30,F16.7,A)') ' g_ss = ', g_ss
        write(*,'(A30,F16.7,A)') ' g_per_capia = ', g_per_capita_ss
        write(*,'(A30,F16.7,A)') ' upsilon_ss = ', upsilon_ss
        write(*,'(A30,F16.7,A)') ' savings_top_ten = ',  savings_top_ten(10)/sum(N_ss_j*asset_pom_ss_j)
        write(*,'(A30,F16.7,A)') ' savings_top_100 = ',  savings_top_100(100)/sum(N_ss_j*asset_pom_ss_j)
        write(*,'(A30,F16.7,A)') 'private_wealth/y_ss ratio =', sum(N_ss_j*asset_pom_ss_j)/y_ss
        write(*,'(A30,F16.7,A)') 'share negative assets =', share_neg
        write(*,'(A30,F16.7,A)') 'share nonpositive assets =', share_nonpos
        write(*,'(A30,F16.7,A)') 'borrowing limit to LabIncAVG_ss_vfi', sv(0) / LabIncAVG_ss_vfi
        write(*,'(A30,F16.7,A)') ' top_ten = ',  top_ten(10)
        write(*,'(A30,F16.7,A)') ' tc = ',  tc_ss
        write(*,'(A30,F16.7,A)') ' tk = ',  tk_ss
        write(*,'(A30,F16.7,A)') ' tl = ',  tl_ss
        write(*,'(A30,F10.7,A)') ' rho = ', rho
        write(*,'(A30,F16.7,A)') ' phi = ',  phi
        write(*,'(A30,F10.7,A)') ' delta = ', delta
        write(*,'(A30,F10.7,A)') ' b_scale_factor_ss = ', b_scale_factor_ss
        write(*,'(A30,F16.7,A)') ' t1 = ',  t1_ss
        write(*,'(A30,F16.7,A)') ' t1_contrib = ',  t1_ss_contrib
        write(*,'(A30,F16.7,A)') ' lambda = ',  lambda
        write(*,'(A30,F16.7,A)') ' LabIncAVG_ss_vfi = ',  LabIncAVG_ss_vfi
        write(*,'(A30,F16.7,A)') ' replacement = ',  replacement_ss
        write(*,'(A30,F16.7,A)') ' feasibility = ', abs((y_ss - consumption_ss_gross - g_ss)/y_ss - ((nu_ss*gam_ss+depr-1)*k_ss)/y_ss) 
        write(*,*) '********************************************'

    OPEN (unit=666, FILE = version//experiment//closure//no_steady//"aggregates.csv")

 
    write(666, '(A)') "Outcomes"
    write(666, '(A)') "y;k/y;c/y;i/y;bigl;r;tauC;tauK;tauL;lambda;beq/y;gam_ss;average hours;r-g;replacement;"
    write(666, '(F20.10,A)', advance='no') y_ss, ";"
    write(666, '(F20.10,A)', advance='no') k_ss/y_ss, ";"
    write(666, '(F20.10,A)', advance='no') consumption_ss_gross/(y_ss), ";"
    write(666, '(F20.10,A)', advance='no') ((gam_ss+depr-1)*k_ss)/y_ss, ";"
    write(666, '(F20.10,A)', advance='no') bigl_ss, ";"
    write(666, '(F20.10,A)', advance='no') r_ss, ";"
    write(666, '(F20.10,A)', advance='no') tc_ss, ";"
    write(666, '(F20.10,A)', advance='no') tk_ss, ";"
    write(666, '(F20.10,A)', advance='no') tl_ss, ";"
    write(666, '(F20.10,A)', advance='no')lambda, ";"
    write(666, '(F20.10,A)', advance='no') bequest_ss/y_ss, ";"
    write(666, '(F20.10,A)', advance='no') gam_ss, ";"
    write(666, '(F20.10,A)', advance='no') bigl_ss/sum(N_ss_j(1:jbar_ss-1)), ";"
    write(666, '(F20.10,A)', advance='no') r_ss-gam_ss, ";"
    write(666, '(F20.10,A)', advance='no') replacement_ss, ";"

    write(666, '(A)') ""
    write(666, '(A)') "Lifecycle"
    write(666, '(A)') "yr;c;l;s;V;disc"
    do j = 1, bigJ
        write(666, '(I2,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10)') j, ";", c_ss_j(j), ";", l_ss_j(j), ";", s_ss_j(j), ";", V_ss_j_vfi(j), ";", beta*delta**(j-1)*(pi_ss(j)/pi_ss(1))
    enddo
CLOSE(666)

    
if (switch_ss_write == 1) then
    open(unit = 106, FILE = version//experiment//closure//no_steady//"gini_weight.csv")
    write(106, '(A)') "weight;age;assets"

            do j = 1, bigJ, 1
                do ia = 0, n_a, 1
        write(106, '(F20.10,A,I5,A,F20.10)') &
                    gini_weight_sv(j,ia), ";", & ! weight
                    j , ";",  & !age
                    sv(ia)  !assets
                enddo        
            enddo

    close(106)


    open(unit = 107, FILE = version//experiment//closure//no_steady//"prob.csv")
    write(107, '(A)') "prob;age;asset;aime;inc_shock;ret_shock;disc_shock"
   
            do j = 1, bigJ, 1
                do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1, n_sp, 1
                            do ir = 1, n_sr, 1
                                do id = 1, n_sd, 1
                                write(107, '(F20.10,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5)') &
                                prob_ss(j, ia, i_aime, ip, ir, id), ";", & ! probability
                                j , ";",  & !age
                                ia , ";",  & !asset
                                i_aime , ";",  & !aime
                                ip , ";",  & !income
                                ir , ";",  & !return
                                id  !discount
                                enddo        
                            enddo
                        enddo
                    enddo
                enddo
            enddo


    close(107)

    open(unit = 108, FILE = version//experiment//closure//no_steady//"mass.csv")
    write(108, '(A)') "mass;cons;hours;labinc;labinc_pretax;age;asset;aime;inc_shock;ret_shock;disc_shock"
        do i = 1, bigT, 1
            do j = 1, bigJ, 1
                do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1, n_sp, 1
                            do ir = 1, n_sr, 1
                                do id = 1, n_sd, 1
                                write(108, '(F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5)') &
                                prob_ss(j, ia, i_aime, ip, ir, id)*n_ss_j(j)/sum(n_ss_j(:)), ";", & ! mass
                                c_ss(j, ia, i_aime, ip, ir, id), ";", & !consumption
                                l_ss(j, ia, i_aime, ip, ir, id), ";", & !hours
                                lab_income_ss(j, ia, i_aime, ip, ir, id), ";", & !lab income
                                lab_income_pretax_ss(j, ia, i_aime, ip, ir, id), ";", & !lab income
                    
                                j , ";",  & !age
                                ia , ";",  & !asset
                                i_aime , ";",  & !aime
                                ip , ";",  & !income
                                ir , ";",  & !return
                                id  !discount
                                enddo        
                            enddo
                        enddo
                    enddo
                enddo
            enddo
        enddo
    
    endif
    