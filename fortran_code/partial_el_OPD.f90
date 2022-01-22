!We analyze capital elasticity with respect to the tax rate. We are not interested in the general equilibrium effect here.
!Thus, we assume a direct tax rate increases and compare saving decision from partial equilibrium scenario.
!
!Since the increase in taxes changes the interest rate, saving decisions would be different. 
!For the baseline scenario, interest rate adjustment is the only channel which affects a saving decision. 
!
!In the reform scenario, we need to recalculate implicit tax, cause 
!the present value of pension benefit would be different for a different interest rate. 
    
! pritnt files 
OPEN (unit=4,  FILE = version//closure//"sv_cum_trans_ff.txt")
OPEN (unit=7,  FILE = version//closure//"sv_cum_price_ff.txt")   
        write(4,  '(F20.16)') sum(N_t_j*savings_j, dim=1)/bigL
        write(7,  '(F20.16)') r
close(4)
close(7)
 
elasticity = 0d0
savings_base = sum(N_t_j*savings_j, dim=1)


write(*,*) w_pom_trans_implicit_vfi(1,10)
write(*,*) l_j_vfi(1,10)  
     

do time_iter = 10, 10, 10
! tax rate increase by 1 % tk = 1.01*tk, thus 
    r = (1d0 + (1-tk)*r_bar)
   ! r(time_iter) = 1.01d0 *(1d0 + (1-tk(time_iter))*r_bar(time_iter))
    r_vfi = r - 1d0
    
include 'partial_el_OPD_do.f90'
    
! recalculate cappital stock
savings_el(time_iter) = sum(N_t_j(:,time_iter)*sv_j_el(:,time_iter), dim=1)+sum(N_t_j(:,time_iter)*pillarII_j(:,time_iter), dim=1)
savings_rel_dif(time_iter) = (savings_el(time_iter)-savings_base(time_iter))/savings_base(time_iter)
r_rel_diff(time_iter) = (r(time_iter)-(1+(1 - tk(time_iter))*r_bar(time_iter)))/(1+(1 - tk(time_iter))*r_bar(time_iter))
elasticity(time_iter) = savings_rel_dif(time_iter)/r_rel_diff(time_iter)  ! %Delat S / %Delta r


enddo
    


    OPEN (unit=5,  FILE = version//closure//"OPD_elas_sv_cum_trans_ff.txt")
    OPEN (unit=6,  FILE = version//closure//"OPD_elas_sv_cum_price_ff.txt") 
    OPEN (unit=7,  FILE = version//closure//"OPD_elasticity.txt") 
    OPEN (unit=8,  FILE = version//closure//"OPD_savings_rel_dif.txt") 
    OPEN (unit=9,  FILE = version//closure//"OPD_r_rel_diff.txt") 
            write(5,  '(F20.16)') savings_el/bigL
            write(6,  '(F20.16)') r_vfi
            write(7,  '(F20.16)') elasticity
            write(8,  '(F20.16)') savings_rel_dif
            write(9,  '(F20.16)') r_rel_diff
    close(5)
    close(6)
    close(7)
    close(8)
    close(9)
