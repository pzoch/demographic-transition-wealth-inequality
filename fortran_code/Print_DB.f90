  ! save in files

    OPEN (unit=1,  FILE = version//experiment//closure//"u_init_old_trans.txt")
    OPEN (unit=2,  FILE = version//experiment//closure//"u_all_trans.txt")
    OPEN (unit=3,  FILE = version//experiment//closure//"u20_trans.txt")
    OPEN (unit=4,  FILE = version//experiment//closure//"y_trans.txt")
    OPEN (unit=5,  FILE = version//experiment//closure//"capital_trans.txt")
    OPEN (unit=6,  FILE = version//experiment//closure//"rate_trans.txt") 
    OPEN (unit=8,  FILE = version//experiment//closure//"subsidy_share_trans.txt")
    OPEN (unit=9,  FILE = version//experiment//closure//"benefits_trans.txt")
    
    OPEN (unit=10, FILE = version//experiment//closure//"bigl_trans.txt")
    OPEN (unit=11, FILE = version//experiment//closure//"replacement_trans.txt")
    OPEN (unit=12, FILE = version//experiment//closure//"upsilon_trans.txt")
    OPEN (unit=13, FILE = version//experiment//closure//"tC_trans.txt")
    OPEN (unit=14, FILE = version//experiment//closure//"tL_trans.txt")
    OPEN (unit=15, FILE = version//experiment//closure//"tK_trans.txt")
    OPEN (unit=16, FILE = version//experiment//closure//"contrib_to_gdp_trans.txt")
    OPEN (unit=17, FILE = version//experiment//closure//"debt_share_trans.txt")
    OPEN (unit=18, FILE = version//experiment//closure//"debt_cost_share_trans.txt")
    
    OPEN (unit=20, FILE = version//experiment//closure//"upsilon_share_trans.txt")
    OPEN (unit=21, FILE = version//experiment//closure//"replacement2_trans.txt") !rozumiane jako pierwsza emerytura do ostatniej placy
    OPEN (unit=22, FILE = version//experiment//closure//"bigL_trans.txt")
    OPEN (unit=23, FILE = version//experiment//closure//"Nt_trans.txt")
    OPEN (unit=24, FILE = version//experiment//closure//"g_share_trans.txt")
    OPEN (unit=25, FILE = version//experiment//closure//"rbar_trans.txt")
    
    OPEN (unit=26, FILE = version//experiment//closure//"tC_tax_revenue_trans.txt")
    OPEN (unit=27, FILE = version//experiment//closure//"tL_tax_revenue_trans.txt")
    OPEN (unit=28, FILE = version//experiment//closure//"tK_tax_revenue_trans.txt")
    
    
    OPEN (unit=22, FILE = version//experiment//closure//"u_j_trans.csv")
    OPEN (unit=60, FILE = version//experiment//closure//"l_j_trans.csv")
    OPEN (unit=61, FILE = version//experiment//closure//"c_j_trans.csv")
    OPEN (unit=62, FILE = version//experiment//closure//"b_j_trans.csv")
    OPEN (unit=63, FILE = version//experiment//closure//"sv_j_trans.csv")

    OPEN (unit=64, FILE = version//experiment//closure//"gamma_trans.txt")
    
    OPEN (unit=65, FILE = version//experiment//closure//"cy_ratio_trans.txt")
    OPEN (unit=66, FILE = version//experiment//closure//"ky_ratio_trans.txt")
    
    OPEN (unit=67, FILE = version//experiment//closure//"bigK_trans.txt")
    OPEN (unit=68, FILE = version//experiment//closure//"bigY_trans.txt")
    OPEN (unit=69, FILE = version//experiment//closure//"lambda_trans.txt")
    OPEN (unit=70, FILE = version//experiment//closure//"lifeexp_trans.txt")
    OPEN (unit=71, FILE = version//experiment//closure//"nu_trans.txt")
    OPEN (unit=72, FILE = version//experiment//closure//"depend_ratio_trans.txt")
    
    OPEN (unit=73,  FILE = version//experiment//closure//"r_pretax_trans_1y.txt")
    OPEN (unit=74,  FILE = version//experiment//closure//"r_afterax_trans_1y.txt")
    OPEN (unit=75,  FILE = version//experiment//closure//"r_trans.txt")
    OPEN (unit=76,  FILE = version//experiment//closure//"sum_b_weight_trans.txt")
    OPEN (unit=77,  FILE = version//experiment//closure//"zet_trans.txt")
    OPEN (unit=78,  FILE = version//experiment//closure//"gdp_trans.txt")
    OPEN (unit=79,  FILE = version//experiment//closure//"ky_ratio_trans_1y.txt")
    OPEN (unit=80,  FILE = version//experiment//closure//"irr_trans_1y.txt")
    OPEN (unit=81,  FILE = version//experiment//closure//"iy_ratio_trans.txt")
    OPEN (unit=82,  FILE = version//experiment//closure//"gdp_pc_trans.txt")
    OPEN (unit=83,  FILE = version//experiment//closure//"star_tinc_trans.txt")
    OPEN (unit=84,  FILE = version//experiment//closure//"star_linc_trans.txt")
    OPEN (unit=85,  FILE = version//experiment//closure//"star_pop_trans.txt")
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
        write(9, '(F20.10)')  sum_b(i)/y(i) !units?
        write(10, '(F20.10)') bigl_aux(i)/1000000 
        write(11, '(F20.10)') replacement(i)
        write(12, '(F20.10)') upsilon(i)
        write(13, '(F20.10)') tC(i)
        write(14, '(F20.10)') tL(i)
        write(15, '(F20.10)') tK(i)
        write(16, '(F20.10)') contribution(i)/y(i)
        write(17, '(F20.10)') debt_share(i)
        write(18, '(F20.10)') ((1 + r_bar(i))*debt(max(i-1,1))/(nu(i)*gam_t(i)) - debt(i))/y(i)
        write(20, '(F20.10)') upsilon(i)/(bigl(i)/N_t(i))/y(i) 
        write(21, '(F20.10)') replacement2(i)         
        write(22, '(F20.10)') bigl(i)
        write(23, '(F20.10)') N_t(i)
        write(24, '(F20.10)') g(i)/y(i)
        write(25, '(F20.10)') (1d0 + r_bar(i))**(1d0/real(zbar)) - 1d0
        write(26, '(F20.10)') tc(i)*consumption_gross(i)/y(i)
        
        write(27, '(F20.10)') labor_tax_revenue(i)/bigl(i)/y(i)
         if (switch_tauK_gross == 0) then 
            write(28, '(F20.10)') tk(i)*r_bar(i)*k(i) /y(i) !! i am not sure if this is calculated correctly - need to check also in closure.f90
         else
            write(28, '(F20.10)') tk(i)*(r_bar(i)+depr)*k(i) / y(i)
         endif
         
        write(30,  '(F20.16)') t1(2,i)
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
        write(83,  '(F20.10)') superstar_totinc_share_trans
        write(84,  '(F20.10)') superstar_labinc_share_trans
        write(85,  '(F20.10)') superstar_pop_share_trans
    enddo
    
    

    !do j = 1,bigJ,1
    !    do i = 1,bigT-1,1
    !        write(22, '(F20.10)', advance='no') u_j(j,i)
    !        write(22, '(A)', advance='no')";"
    !        write(60, '(F20.10)', advance='no') l_j(j,i)
    !        write(60, '(A)', advance='no')";"
    !        write(61, '(F20.10)', advance='no') c_j(j,i)
    !        write(61, '(A)', advance='no')";"
    !        write(62, '(F20.10)', advance='no') b_j(j,i)
    !        write(62, '(A)', advance='no')";"
    !        write(63, '(F20.10)', advance='no') sv_j(j,i)
    !        write(63, '(A)', advance='no')";"
    !    enddo
    !    write(22, '(F20.10)') u_j(j,bigT)
    !    write(60, '(F20.10)') l_j(j,bigT)
    !    write(61, '(F20.10)') c_j(j,bigT)
    !    write(62, '(F20.10)') b_j(j,bigT)
    !    write(63, '(F20.10)') sv_j(j,bigT)
    !enddo

    CLOSE(1)
    CLOSE(2)
    CLOSE(3)
    CLOSE(4)
    CLOSE(5)
    CLOSE(6)
    CLOSE(7)
    CLOSE(8)
    CLOSE(9)
    CLOSE(10)
    CLOSE(11)
    CLOSE(12)
    CLOSE(13)
    CLOSE(14)
    CLOSE(15)
    CLOSE(16)
    CLOSE(17)
    CLOSE(20)
    CLOSE(21)
    CLOSE(22)
    CLOSE(23)
    CLOSE(24)
    CLOSE(25)
    CLOSE(26)
    CLOSE(27)
    CLOSE(28)
    CLOSE(60)
    CLOSE(61)
    CLOSE(62)
    CLOSE(63)
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
     
! pension system closure
    OPEN (unit=1, FILE = version//experiment//closure//"b_scale_factor.txt")
    OPEN (unit=2, FILE = version//experiment//closure//"t1_additional_contrib.txt")
    OPEN (unit=3, FILE = version//experiment//closure//"upsilon.txt")
        do i = 1,n_p+1,1
            write(1, '(F20.10)')  b_scale_factor(i) 
            write(2, '(F20.10)')  t1(1,i) - t1_contrib(1,i)
            write(3, '(F20.10)')  upsilon(i) 
    enddo

    CLOSE(1)
    CLOSE(2)
    CLOSE(3)
    

    OPEN (unit=202,  FILE = version//experiment//closure//"savings_trans.txt")
    OPEN (unit=203,  FILE = version//experiment//closure//"debt_trans.txt")
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



OPEN (unit=1, FILE = version//experiment//closure//"gini_weight_trans.txt")
    do i = 1, bigT, 1
        do j = 1, bigJ, 1
            do ia = 0, n_a, 1
                write(1,*) gini_weight_trans(j,ia,i)
            enddo        
        enddo
    enddo
close(1)


open(unit = 106, FILE = version//experiment//closure//"gini_weight_trans.csv")
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


open(unit = 107, FILE = version//experiment//closure//"prob_trans.csv")
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
if (switch_small_write == 0) then
open(unit = 108, FILE = version//experiment//closure//"mass_trans.csv")
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
open(unit = 108, FILE = version//experiment//closure//"mass_trans_small.csv")
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
        
        
    endif
    
    open(unit = 109, FILE = version//experiment//closure//"mass_trans_beq.csv")
    
    if (switch_unequal_bequest == 2) then
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
                            j , ";",  & !beq point
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
    


