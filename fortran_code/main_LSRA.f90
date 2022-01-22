! WHAT   : Consumption equivalent between base and second scenario 
! TAKE   : first and second steady and transition path from world without the reform, another second steady and transition path in world with reform
! DO     : calculate consumption equivalent -> utility effect ot the reform 
! RETURN : percent of consumption consumer after reform would need to give up to keep the same level of (x_j) calculated in lambda file, unif, sum_eq    

MODULE LSRA
use global_vars
use global_vars2
use get_data
use steady_state
use transition_DB

IMPLICIT NONE

CONTAINS

subroutine cons_eq(x_j, x_unif, sum_x, x_c_j, eq_unif, sum_eq, LS)
    real(dp), dimension(bigJ, bigT), intent(inout) :: x_j,  x_unif, sum_x, x_c_j, eq_unif, sum_eq
    real(dp) :: LS
    real(dp), dimension(bigJ, bigT) :: mult, c_p, c_f, l_p, l_f, u_j_f, u_j_p, x_j_old, V_j_vfi_p, V_j_vfi_f
    real(dp), dimension(bigT) :: u_p, u_f, u_g_p, u_g_f, r_p, r_f, tax_c_p, tax_c_f, disc, err_20, x_c, c, g_per_capita_p, g_per_capita_f
   real(dp), dimension(-bigJ:bigT) :: V_20_years_old_p, V_20_years_old_f
    real(dp), dimension(bigJ) :: u_i_p, u_i_f, pom, pom_x, sum_eq_ss, u_init_old_f, u_init_old_p, u_g_init_old_f, u_g_init_old_p, err_init
    real(dp) :: sum_disc, unif, unif_x, LS_x, lambda, lambda_l, lambda_h, S_C, welfare_f, welfare_p, x_t, delta_w

    write(*,*) ''
    write(*,*) '****************************************'

    write(*,*) closure,' - consumption equivalent subroutine'


    call clear_globals
    call globals
    
     !write(*,*) 'What theta do you want to use? '
     !read(*,*) theta 
     !switch_residual_t = 3
     !priv_share = 0.5d0
     
    write(*,*) 'What closure do you want to use? '
    write(*,*) '0 ups, 1 tc, 3 tk,  4 contr, 5 btax, 6 fC, 7fK'
    
    read(*,*)       switch_residual_t 
    !switch_residual_t = 3
    
    
    select case (switch_residual_t)  
    case(0)
        closure = 'upsil_'
        switch_residual_2 = 0 
    case(1)
        closure = 'taxC__' 
        switch_residual_2 = 1      
    case(2)
        closure = 'taxL__' 
        switch_residual_2 = 2         
    case(3)
        closure = 'taxK__' 
        switch_residual_2 = 3  
    case(4)
        closure = 'cont__' 
        switch_residual_2 = 4  
    case(5)
        closure = 'btax__' 
        switch_residual_2 = 5    
    case(6)
        closure = 'frlC__' 
        switch_residual_2 = 1  
     case(7)
        closure = 'frlk__' 
        switch_residual_2 = 3  

    end select
    

    if (switch_reduce_pension == 0) then 
        write(*,*) 'How much of contribitions does go to funded pillar? 0.0 - 0%, 0.5 - 50%'
        read(*,*)   priv_share
    else
        priv_share = 0.5d0
    endif
    
   
    

    switch_type_1 = 0
    switch_type_2 = 0
    t1_ss_new =  t1_ss_old
    t2_ss_new = t2_ss_old
    ! WORLD WITHOUT PENSION SYSTEM REFORM 
    write(*,*) closure,' - steady old payg'
    sum_eq_ss = 0
    switch_ref_run_now = 0
    switch_run_1 = 1 ! otherwise we would not write value at period 1 in vf tables for second, third ans so on closure
    call steady(switch_residual_1, switch_param_1, switch_type_1, rho_1, k_ss_1, r_ss_1, r_bar_ss_1, w_bar_ss_1, &
                l_ss_j_1, w_ss_j_1, s_ss_j_1, c_ss_j_1, b_ss_j_1,  upsilon_r_ss_1, t1_ss_1, g_per_capita_ss_1, &
                b1_ss_j_1, b2_ss_j_1,  pillar1_ss_j_1, pillar2_ss_j_1)

    write(*,*) closure,' - steady new payg'
    sum_eq_ss = 0
    switch_run_1 = 0 ! otherwise we would rewrite value at period 1 in vf tables 
    call steady(switch_residual_2, switch_param_2, switch_type_1, rho_2, k_ss_2, r_ss_2, r_bar_ss_2, w_bar_ss_2, &
               l_ss_j_2, w_ss_j_2, s_ss_j_2, c_ss_j_2, b_ss_j_2, upsilon_r_ss_2, t1_ss_2, g_per_capita_ss_2,&
               b1_ss_j_2, b2_ss_j_2, pillar1_ss_j_2, pillar2_ss_j_2)

    write(*,*) closure,' - transition payg'
    call transition_path_DB(switch_residual_t, switch_param_2,  l_p, c_p, tax_c_p, r_p,  V_20_years_old_p, g_per_capita_p)
    V_j_vfi_p  = V_j_vfi
    
    
    ! WORLD WITH pension system reform
    
    write(*,*) '****************************************'
    if (switch_reduce_pension == 0) then 
        write(*,*) closure,' - steady new DC '
        switch_ref_run_now = 1
        !define policy shape
        version = 'ref__'
        switch_type_2 = 1
        t1_ss_new = (1d0-priv_share )*t1_ss_old
        t1_ss_contrib = t1_ss_new
        t2_ss_new = priv_share*t1_ss_old
        switch_pension = abs(switch_type_1 - switch_type_2) 
    else 
        write(*,*) closure,' - steady new reduced pension system  '
        switch_ref_run_now = 1
        !define policy shape
        version = 'ref__'
        switch_type_2 = 0
        t1_ss_new = (1d0-priv_share )*t1_ss_old
        t2_ss_new = 0
        rho_2 =  rho_1*(1d0-priv_share)
        switch_pension = abs(switch_type_1 - switch_type_2) 
    endif 
    
        sum_eq_ss = 0

        k_ss_2 = 0
        r_ss_2 = 0
        r_bar_ss_2 = 0 
        w_bar_ss_2 = 0
        l_ss_j_2 = 0
        w_ss_j_2 = 0
        s_ss_j_2 = 0
        c_ss_j_2 = 0
        b_ss_j_2 = 0
        upsilon_r_ss_2 = 0


        switch_run_1 = 0 ! otherwise we would rewrite value at period 1 in vf tables 

            
       call steady(switch_residual_2, switch_param_2, switch_type_2, rho_2, k_ss_2, r_ss_2, r_bar_ss_2, w_bar_ss_2, &
                   l_ss_j_2, w_ss_j_2, s_ss_j_2, c_ss_j_2, b_ss_j_2, upsilon_r_ss_2, t1_ss_2, g_per_capita_ss_2, &
                   b1_ss_j_2, b2_ss_j_2, pillar1_ss_j_2, pillar2_ss_j_2)

        sum_eq = 0
        
        write(*,*) closure,' - transition payg'
       call transition_path_DB(switch_residual_t, switch_param_2,  l_f, c_f, tax_c_f, r_f,  V_20_years_old_f, g_per_capita_f)
        V_j_vfi_f =V_j_vfi
        include 'lambda.f90'


    OPEN (unit=1, FILE = closure//"lambda_20.txt")
    OPEN (unit=2, FILE = closure//"lambda_init.txt")
    do i = 1,n_p+2,1
        write(1, '(F20.10)') x_j(1,i)
    enddo
    do j = 2,bigJ,1
        write(2, '(F20.10)') x_j(j,1)
    enddo
    CLOSE(1)
    CLOSE(2)


    ! CONSUMPTION EQUIVALENT BETWEEN SCENARIOS 
    !!!!!!!!! TO BE COMPLETED !!!!!!!!!!!
    do i = 2,n_p+2,1
        do j = 1,bigJ,1
            if (j == 1) then 
                x_c_j(j,i) = x_j(j,i)*c_f(j,i)
            else
                x_j(j,i) = x_j(j-1,i-1)
                x_c_j(j,i) = x_j(j,i)*c_f(j,i)
            endif
        enddo
    enddo

    do i = n_p+3,bigT,1
        do j = 1,bigJ,1
            x_j(j,i) = x_j(j,i-1)
            x_c_j(j,i) = x_j(j,i)*c_p(j,i)
        enddo
    enddo
     
     x_c = sum(x_c_j*Nn_, dim=1)
     c = sum(c_f*Nn_, dim=1)
                  
    LS = x_c(1)
    S_C = c(1)
    disc(1) = 1
    ! 20-year olds
    do i = 2,n_p+1,1
        disc(i) = gam_cum(i)/gam_cum(1)/product(r_f((2):(i))) ! OPIS 
        LS  = LS + disc(i)*x_c(i)
        S_C = S_C + disc(i)*c(i)            
    enddo

    disc(n_p+2) = gam_cum(n_p+1)/product(r_f((1):(n_p+1)))
    LS = LS + x_c(n_p+2)*(gam_cum(n_p+2)/gam_cum(1)/product(r_f((2):(n_p+2))))*(r_f(n_p+2)/(r_f(n_p+2)  - Nn_(1,n_p+2)/Nn_(1,n_p+1)*gam_t(n_p+2))) !the last part is the sum of infinite sequence
    S_C = S_C  + c(n_p+2)*(gam_cum(n_p+2)/gam_cum(1)/product(r_f((2):(n_p+2))))*(r_f(n_p+2)/(r_f(n_p+2) - Nn_(1,n_p+2)/Nn_(1,n_p+1)* gam_t(n_p+2))) !the last part is the sum of infinite sequence
     ! - Nn_(1,n_p+2)/Nn_(1,n_p+1)*
    
    unif = LS/S_C  ! if we have something left, then you can lower lump-sums by this amount, hence the minus sign
    sum_eq = (x_j - unif)*c_p
    sum_eq_ss(:) = sum_eq(:, bigT)

    OPEN (unit=3, FILE = closure//"x_j.csv")
    OPEN (unit=4, FILE = closure//"sum_eq.csv")
            do j = 1,bigJ,1
                do i = 1,bigT-1,1
                    write(3, '(F20.10)', advance='no') x_j(j,i)
                    write(3, '(A)', advance='no')";"
                    write(4, '(F20.10)', advance='no') sum_eq(j,i)
                    write(4, '(A)', advance='no')";"

                enddo
                write(3, '(F20.10)') x_j(j,bigT)
                write(4, '(F20.10)') sum_eq(j,bigT)
            enddo
    CLOSE(3)
    CLOSE(4)
    
    OPEN (unit=3, FILE = closure//"x_c_j.csv")
        do j = 1,bigJ,1
            do i = 1,bigT-1,1
                write(3, '(F20.10)', advance='no') x_c_j(j,i)
                write(3, '(A)', advance='no')";"
            enddo
            write(3, '(F20.10)') x_c_j(j,bigT)
        enddo
    CLOSE(3)

    do i = 1, bigT, 1
    do  j = 1,bigJ, 1
        if (x_j(j,i)>0.0_dp) then
        better_j(j,i) = Nn_(j,i)
        endif 
    enddo
    better(i)= sum(better_j(1:bigJ,i))/sum(Nn_(1:bigJ,i))
    enddo 

    OPEN (unit=1, FILE = "better.txt")
    OPEN (unit=2, FILE = "c_LSRA.txt")
    OPEN (unit=3, FILE = "x_c_LSRA.txt")
        do i = 1, bigT, 1
            write(1, '(F20.10)') better(i)
            write(2, '(F20.10)') c(i)
            write(3, '(F20.10)') x_c(i)
        enddo
    CLOSE(1)
    CLOSE(2)
    CLOSE(3)

    if (unif > 0) then
        write(*,*) closure,'  unif = ', unif, '> 0, i.e. the new policy is Pareto improving'
    else 
        write(*,*) closure,'  unif = ', unif , '< 0, i.e. the new policy is Pareto deteriorating'
    endif  
    
    write(*,*) '****************************************'

    OPEN (unit=1, FILE = "unif.txt")
    write(1, '(F20.10)') unif
    CLOSE(1)


end subroutine cons_eq

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

end module LSRA