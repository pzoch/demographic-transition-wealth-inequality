!===============================================================================
! FILE: Print_DB.f90
!
! DESCRIPTION:
!   Writes transition path results to disk: aggregate time series (*_trans.txt)
!   and cohort-level life-cycle profiles (*_j_trans.csv). Controlled by
!   switch_print_macro and switch_small_write.
!
! INCLUDED IN: main_base_transition.f90
!
! KEY OUTPUTS: *_trans.txt (aggregates), *_j_trans.csv (age profiles)
!===============================================================================
  ! save in files

! Macro time series output - only written if switch_print_macro == 1 (baseline scenario)
if (switch_print_macro == 1) then
    OPEN (unit=1,  FILE ="u_init_old_trans.txt")
    OPEN (unit=2,  FILE ="u_all_trans.txt")
    OPEN (unit=3,  FILE ="u20_trans.txt")
    OPEN (unit=4,  FILE ="y_trans.txt")
    OPEN (unit=5,  FILE ="capital_trans.txt")
    OPEN (unit=6,  FILE ="rate_trans.txt") 
    OPEN (unit=8,  FILE ="subsidy_share_trans.txt")
    OPEN (unit=9,  FILE ="benefits_trans.txt")
    
    OPEN (unit=10, FILE ="bigl_trans.txt")
    OPEN (unit=11, FILE ="replacement_trans.txt")
    OPEN (unit=13, FILE ="tC_trans.txt")
    OPEN (unit=14, FILE ="tL_trans.txt")
    OPEN (unit=15, FILE ="tK_trans.txt")
    OPEN (unit=16, FILE ="contrib_to_gdp_trans.txt")
    OPEN (unit=17, FILE ="debt_share_trans.txt")
    OPEN (unit=18, FILE ="debt_cost_share_trans.txt")
    
    OPEN (unit=21, FILE ="replacement2_trans.txt") ! first pension to last wage ratio
    OPEN (unit=22, FILE ="bigL_trans.txt")
    OPEN (unit=23, FILE ="Nt_trans.txt")
    OPEN (unit=24, FILE ="g_share_trans.txt")
    OPEN (unit=25, FILE ="rbar_trans.txt")
    
    OPEN (unit=26, FILE ="tC_tax_revenue_trans.txt")
    OPEN (unit=27, FILE ="tL_tax_revenue_trans.txt")
    OPEN (unit=28, FILE ="tK_tax_revenue_trans.txt")
    
    
    OPEN (unit=64, FILE ="gamma_trans.txt")
    
    OPEN (unit=65, FILE ="cy_ratio_trans.txt")
    OPEN (unit=66, FILE ="ky_ratio_trans.txt")
    
    OPEN (unit=67, FILE ="bigK_trans.txt")
    OPEN (unit=68, FILE ="bigY_trans.txt")
    OPEN (unit=69, FILE ="lambda_trans.txt")
    OPEN (unit=70, FILE ="lifeexp_trans.txt")
    OPEN (unit=71, FILE ="nu_trans.txt")
    OPEN (unit=72, FILE ="depend_ratio_trans.txt")
    
    OPEN (unit=73,  FILE ="r_pretax_trans_1y.txt")
    OPEN (unit=74,  FILE ="r_afterax_trans_1y.txt")
    OPEN (unit=75,  FILE ="r_trans.txt")
    OPEN (unit=76,  FILE ="sum_b_weight_trans.txt")
    OPEN (unit=77,  FILE ="zet_trans.txt")
    OPEN (unit=78,  FILE ="gdp_trans.txt")
    OPEN (unit=79,  FILE ="ky_ratio_trans_1y.txt")
    OPEN (unit=80,  FILE ="irr_trans_1y.txt")
    OPEN (unit=81,  FILE ="iy_ratio_trans.txt")
    OPEN (unit=82,  FILE ="gdp_pc_trans.txt")
    OPEN (unit=83,  FILE ="star_tinc_trans.txt")
    OPEN (unit=84,  FILE ="star_linc_trans.txt")
    OPEN (unit=85,  FILE ="star_pop_trans.txt")
    OPEN (unit=86,  FILE ="beq_gdp_trans.txt")
    OPEN (unit=87,  FILE ="avg_hours_trans.txt")
    if (any(rate_adj /= 0.0d0)) then
    OPEN (unit=88,  FILE ="r_low_trans.txt")
    OPEN (unit=89,  FILE ="r_type_trans.csv")
    write(89, '(A)', advance='no') "year;r_low"
    do m = 1,bigM,1
        write(89, '(A,I0)', advance='no') ";r_type_", m
    enddo
    write(89, '(A)') ""
    endif
    do i = 2,bigJ-1,1
        write(1, '(F20.10)')  u_init_old(i) 
    enddo

    do i = 1,bigJ+n_p,1
        write(2, '(F20.10)')  u_all(i) 
    enddo

    do i = 1,n_p+2,1 
        write(3,  '(F20.10)') u(i) 
        write(4,  '(F20.10)') y(i) 
        write(5,  '(F20.10)') k(i) 
        write(6,  '(F20.10)') r_bar(i)  
        write(8,  '(F20.10)') subsidy(i)/y(i)
        write(9, '(F20.10)')  sum_b(i)/y(i)
        write(10, '(F20.10)') bigl_aux(i)/1000000 
        write(11, '(F20.10)') replacement(i)
        write(13, '(F20.10)') tC(i)
        write(14, '(F20.10)') tL(i)
        write(15, '(F20.10)') tK(i)
        write(16, '(F20.10)') contribution(i)/y(i)
        write(17, '(F20.10)') debt_share(i)
        write(18, '(F20.10)') ((1 + r_bar(i))*debt(max(i-1,1))/(nu(i)*gam_t(i)) - debt(i))/y(i)
        write(21, '(F20.10)') replacement2(i)         
        write(22, '(F20.10)') bigl(i)
        write(23, '(F20.10)') N_t(i)
        write(24, '(F20.10)') g(i)/y(i)
        write(25, '(F20.10)') (1d0 + r_bar(i))**(1d0/real(zbar)) - 1d0
        write(26, '(F20.10)') tc(i)*consumption_gross(i)/y(i)
        
        write(27, '(F20.10)') labor_tax_revenue(i)/bigl(i)/y(i)
         if (switch_tauK_gross == 0) then 
            write(28, '(F20.10)') tk(i)*r_bar(i)*k(i) /y(i)
         else
            write(28, '(F20.10)') tk(i)*(r_bar(i)+depr)*k(i) / y(i)
         endif
         
        write(64,  '(F20.10)') gam_t(i) 
        write(65,  '(F20.10)') consumption_gross(i)/y(i) 
        write(66,  '(F20.10)') k(i)/y(i)
        write(67,  '(F20.10)') bigK(i)
        write(68,  '(F20.10)') bigY(i)
        write(69,  '(F20.10)') lambda_trans(i)
        write(70,  '(F20.10)') life_exp(1,i)
        write(71,  '(F20.10)') nu(i)
        write(72,  '(F20.10)') sum(N_t_j(jbar_t_vfi(i):bigJ,i))/bigl(i)
        
        write(73,  '(F20.10)') 100*((1 + r_bar(i))**0.2_dp -1d0)
        write(74,  '(F20.10)') 100*(r(i)**0.2_dp -1d0)
        
        write(75,  '(F20.10)') r(i)  
        write(76,  '(F20.10)') sum_b_weight_trans(i)
        write(77,  '(F20.10)') zet(i) 
        write(78,  '(F20.10)') zet(i) * bigY(i)
        write(79,  '(F20.10)') k(i)/y(i) * real(zbar)
        write(80,  '(F20.10)') 100*((1 + r_bar(i))**0.2_dp -1d0)
        write(81,  '(F20.10)') (y(i)-consumption_gross(i)-g(i))/y(i) 
        write(82,  '(F20.10)') zet(i) * bigY(i) / N_t(i) 
        write(83,  '(F20.10)') superstar_totinc_share_trans(i)
        write(84,  '(F20.10)') superstar_labinc_share_trans(i)
        write(85,  '(F20.10)') superstar_pop_share_trans(i)
        write(86,  '(F20.10)') bequest_trans(i) / y(i)
        write(87,  '(F20.10)') average_lab(i)
        if (any(rate_adj /= 0.0d0)) then
        write(88,  '(F20.10)') r_low(i)
        write(89,  '(I5,A,F20.10)', advance='no') i, ";", r_low(i)
        do m = 1,bigM,1
            write(89, '(A,F20.10)', advance='no') ";", r_low(i)+rate_adj(m)
        enddo
        write(89, '(A)') ""
        endif
    enddo

    CLOSE(1)
    CLOSE(2)
    CLOSE(3)
    CLOSE(4)
    CLOSE(5)
    CLOSE(6)
    CLOSE(8)
    CLOSE(9)
    CLOSE(10)
    CLOSE(11)
    CLOSE(13)
    CLOSE(14)
    CLOSE(15)
    CLOSE(16)
    CLOSE(17)
    CLOSE(21)
    CLOSE(22)
    CLOSE(23)
    CLOSE(24)
    CLOSE(25)
    CLOSE(26)
    CLOSE(27)
    CLOSE(28)
    CLOSE(64)
    CLOSE(65)
    CLOSE(66)
    CLOSE(67)
    CLOSE(68)
    CLOSE(69)
    CLOSE(70)
    CLOSE(71)
    CLOSE(72)
    CLOSE(73)
    CLOSE(74)
    CLOSE(75)
     CLOSE(76)
     CLOSE(77)
     CLOSE(78)
     CLOSE(79)
     CLOSE(80)
     CLOSE(81)
     CLOSE(82)
     CLOSE(83)
     CLOSE(84)
     CLOSE(85)
     CLOSE(86)
     CLOSE(87)
     if (any(rate_adj /= 0.0d0)) then
     CLOSE(88)
     CLOSE(89)
     endif

! pension system closure
    OPEN (unit=1, FILE ="b_scale_factor.txt")
    OPEN (unit=2, FILE ="t1_additional_contrib.txt")
        do i = 1,n_p+1,1
            write(1, '(F20.10)')  b_scale_factor(i) 
            write(2, '(F20.10)')  t1(1,i) - t1_contrib(1,i)
    enddo

    CLOSE(1)
    CLOSE(2)
    CLOSE(3)
    

    OPEN (unit=202,  FILE ="savings_trans.txt")
    OPEN (unit=203,  FILE ="debt_trans.txt")
    write(202,  '(F20.10)') (savings(1))/(nu(1)*gam_t(1))
    write(203,  '(F20.10)') (debt(1))/(nu(1)*gam_t(1))
    do i = 2,n_p+1,1 
        write(202,  '(F20.10)') (savings(i-1))/(nu(i)*gam_t(i))
        write(203,  '(F20.10)') (debt(i-1))/(nu(i)*gam_t(i))
    enddo
    write(202,  '(F20.10)') (savings(n_p+1))/(nu(n_p+1)*gam_t(n_p+1))
    write(203,  '(F20.10)') (debt(n_p+1))/(nu(n_p+1)*gam_t(n_p+1))
    CLOSE(202)
    CLOSE(203)

    OPEN (unit=1, FILE ="gini_weight_trans.txt")
        do i = 1, bigT, 1
            do j = 1, bigJ, 1
                do ia = 0, n_a, 1
                    write(1,*) gini_weight_trans(j,ia,i)
                enddo
            enddo
        enddo
    close(1)

    open(unit = 106, FILE ="gini_weight_trans.csv")
    write(106, '(A)') "weight;year;age;assets"
        do i = 1, bigT, 1
            do j = 1, bigJ, 1
                do ia = 0, n_a, 1
        write(106, '(F20.10,A,I5,A,I5,A,F20.10)') &
                    gini_weight_trans(j,ia,i), ";", & ! weight
                    i, ";", & !year
                    j , ";",  & !age
                    sv(ia)  !assets
                enddo
            enddo
        enddo
    close(106)

endif  ! end of switch_print_macro block


! prob_trans.csv - only written if switch_full_csv_write == 1
if (switch_full_csv_write == 1) then
open(unit = 107, FILE ="prob_trans.csv")
write(107, '(A)') "prob;year;age;asset;aime;inc_shock;ret_shock;disc_shock"
    do i = 1, bigT, 1
        do j = 1, bigJ, 1
            do ia = 0, n_a, 1
                do i_aime = 0, n_aime, 1
                    do ip = 1, n_sp, 1
                        do ir = 1, n_sr, 1
                            do id = 1, n_sd, 1
                            write(107, '(F20.10,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5)') &
                            prob_trans(j, ia, i_aime, ip, ir, id,i), ";", & ! probability
                            i, ";", & !year
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


close(107)
endif
! mass_trans CSV - behavior depends on both switch_full_csv_write and switch_small_write
if (switch_full_csv_write == 1) then
    ! Full CSV write mode (base_all_govt__ scenario)
    if (switch_small_write == 0) then
        open(unit = 108, FILE ="mass_trans.csv")
        write(108, '(A)') "mass;cons;hours;labinc;labinc_pretax;totinc_pretax;wealth;sav;year;age;asset;aime;inc_shock;ret_shock;disc_shock;type"
        do i = 1, bigT, 1
            do j = 1, bigJ, 1
                do m = 1, bigM, 1
                do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1, n_sp, 1
                            do ir = 1, n_sr, 1
                                do id = 1, n_sd, 1
                                write(108, '(F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5)') &
                                prob_trans_big(j, ia, i_aime, ip, ir, id,m,i)*N_big_t_j(j,m,i)/sum(N_big_t_j(:,:,i)), ";", & ! mass
                                c_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !consumption
                                l_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !hours
                                lab_income_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !lab income
                                lab_income_pretax_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !lab income
                                tot_income_pretax_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !pretax income
                                sv(ia) + bequest_j_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !sav
                                svplus_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !sav
                                i, ";", & !year
                                j , ";",  & !age
                                ia , ";",  & !asset
                                i_aime , ";",  & !aime
                                ip , ";",  & !income
                                ir , ";",  & !return
                                id , ";",  & !discount
                                m   !type
                                enddo
                            enddo
                        enddo
                    enddo
                    enddo
                enddo
            enddo
        enddo
        close(108)
    else
        open(unit = 108, FILE ="mass_trans_small.csv")
        write(108, '(A)') "mass;labinc_pretax;sav;year;age;asset;aime;inc_shock;ret_shock;disc_shock;type"
        do i = 1, bigT, 1
            do j = 1, bigJ, 1
                do m = 1, bigM, 1
                do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1, n_sp, 1
                            do ir = 1, n_sr, 1
                                do id = 1, n_sd, 1
                                write(108, '(F20.10,A,F20.10,A,F20.10,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5)') &
                                prob_trans_big(j, ia, i_aime, ip, ir, id,m,i)*N_big_t_j(j,m,i)/sum(N_big_t_j(:,:,i)), ";", & ! mass
                                lab_income_pretax_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !lab income
                                svplus_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !sav
                                i, ";", & !year
                                j , ";",  & !age
                                ia , ";",  & !asset
                                i_aime , ";",  & !aime
                                ip , ";",  & !income
                                ir , ";",  & !return
                                id , ";",  & !discount
                                m   !type
                                enddo
                            enddo
                        enddo
                    enddo
                    enddo
                enddo
            enddo
        enddo
        close(108)
    endif
elseif (switch_full_csv_write == 2) then
    ! Compact CSV write mode (optional, use switch_full_csv_write=2 to enable)
    if (switch_small_write == 0) then
        ! Medium CSV: svplus, prob, and all index variables
        open(unit = 108, FILE ="mass_trans_medium.csv")
        write(108, '(A)') "svplus;prob;year;age;asset;aime;inc_shock;ret_shock;disc_shock;type"
        do i = 1, bigT, 1
            do j = 1, bigJ, 1
                do m = 1, bigM, 1
                do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1, n_sp, 1
                            do ir = 1, n_sr, 1
                                do id = 1, n_sd, 1
                                write(108, '(F20.10,A,F20.10,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5)') &
                                svplus_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !sav
                                prob_trans_big(j, ia, i_aime, ip, ir, id,m,i)*N_big_t_j(j,m,i)/sum(N_big_t_j(:,:,i)), ";", & ! prob
                                i, ";", & !year
                                j , ";",  & !age
                                ia , ";",  & !asset
                                i_aime , ";",  & !aime
                                ip , ";",  & !income
                                ir , ";",  & !return
                                id , ";",  & !discount
                                m   !type
                                enddo
                            enddo
                        enddo
                    enddo
                    enddo
                enddo
            enddo
        enddo
        close(108)
    else
        ! Minimal CSV: only svplus, prob, and year index
        open(unit = 108, FILE ="mass_trans_minimal.csv")
        write(108, '(A)') "svplus;prob;year"
        do i = 1, bigT, 1
            do j = 1, bigJ, 1
                do m = 1, bigM, 1
                do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1, n_sp, 1
                            do ir = 1, n_sr, 1
                                do id = 1, n_sd, 1
                                write(108, '(F20.10,A,F20.10,A,I5)') &
                                svplus_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !sav
                                prob_trans_big(j, ia, i_aime, ip, ir, id,m,i)*N_big_t_j(j,m,i)/sum(N_big_t_j(:,:,i)), ";", & ! prob
                                i  !year
                                enddo
                            enddo
                        enddo
                    enddo
                    enddo
                enddo
            enddo
        enddo
        close(108)
    endif
endif
    
    ! mass_trans_beq.csv - only written if switch_full_csv_write == 1
    if (switch_full_csv_write == 1 .and. switch_unequal_bequest == 2) then
    open(unit = 109, FILE ="mass_trans_beq.csv")
write(109, '(A)') "mass;cons;hours;labinc;labinc_pretax;totinc_pretax;wealth;sav;year;beq;asset;aime;inc_shock;ret_shock;disc_shock;type"
    
    do i = 1, bigT, 1
        do j = 1, n_beq, 1
            do m = 1, bigM, 1
            do ia = 0, n_a, 1
                do i_aime = 0, n_aime, 1
                    do ip = 1, n_sp, 1
                        do ir = 1, n_sr, 1
                            do id = 1, n_sd, 1
                            write(109, '(F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,F20.10,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5,A,I5)') &
                            prob_trans_big(beq_age, ia, i_aime, ip, ir, id,m,i)*N_big_t_j(beq_age,m,i)/sum(N_big_t_j(beq_age,:,i))*p_beq_trans(j,i), ";", & ! mass
                            c_beq_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !consumption
                            l_beq_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !hours
                            lab_income_beq_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !lab income
                            lab_income_pretax_beq_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !lab income
                            tot_income_pretax_beq_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !pretax income
                            sv(ia) + beq_zipf_trans_big(j,m,i), ";", & !sav
                            svplus_beq_trans_big(j, ia, i_aime, ip, ir, id,m,i), ";", & !sav
                            i, ";", & !year
                            j , ";",  & !age
                            ia , ";",  & !asset
                            i_aime , ";",  & !aime
                            ip , ";",  & !income
                            ir , ";",  & !return
                            id , ";",  & !discount
                            m   !type
                            enddo        
                        enddo
                    enddo
                enddo
                enddo
            enddo
        enddo
    enddo
close(109)
endif

! Write Gini coefficient of savings by year
open(unit = 120, FILE = "gini_trans.csv")
write(120, '(A)') "year;gini_sav"
do i = 1, bigT, 1
    write(120, '(I5,A,F20.10)') i, ";", gini_sav_trans(i)
enddo
close(120)
