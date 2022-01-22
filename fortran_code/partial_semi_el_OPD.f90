!Semi elasticity of capital:
!For fixed prices and transfers - so GE - we calculate semi elasticity of capital, 
!which means we are interested in % change of net interest rate and simple changes of capital. 
!
!We keep macro variables as in the first steady-state. 
!Then we solve the agent's problem for the transition population structure.  
!In the second step, we adjust the net interest rate and resolve the agent's problem.
!
!In the DC scenario, we also adjust pension system benefits. 
!Thus we neede to recalculate implicit tax in the second step.
!
!In the third step, we can calculate semi elasticities = Delta K/% Delta r
   
! 1st step base for elasticities 
    ! implicit tax base on 1st ss values 
    ! tax rate increase by 1 % tk = 1.01*tk, thus 
    switch_partial_semi = 1
        r = 1d0 + (1-tk(1))*r_bar(1)
        include 'partial_semi_do.f90'
        
    ! calculate total capital   
    
      K_semi_elasticity_base   =sum(N_t_j*sv_j_el, dim=1)+sum(N_t_j*pillarII_j, dim=1)
      r_semi_elasticity_base  = r
      tk_base = tk(1)
      
K_semi_elasticity_reform = K_semi_elasticity_base 
r_semi_elasticity_reform  = r_semi_elasticity_base
tk_reform = tk_base
! 2nd step r net change 
    ! implicit tax base on 1st ss values 
    ! assign macro variables
     
      do time_iter  = 10, 50, 10
        ! one period deviation 
        r = 1d0 + (1-tk(1))*r_bar(1)
        r(time_iter) = (1d0 + (1d0-tk(1)-0.01d0)*r_bar(1))
        include 'partial_semi_do.f90'
        ! calculate total capital 
        K_semi_elasticity_reform(time_iter) =sum(N_t_j(:,time_iter)*sv_j_el(:,time_iter), dim=1) &
                                            + sum(N_t_j(:,time_iter)*pillarII_j(:,time_iter), dim=1)
        r_semi_elasticity_reform(time_iter) = r(time_iter)
        tk_reform(time_iter) = tk(1)+0.01d0
    enddo 
      
! 3rd elasticities 
    
    delta_K =  K_semi_elasticity_reform - K_semi_elasticity_base
        
    do i = 1, bigT, 1
        delta_K(i) = delta_K(i)/K_semi_elasticity_base(i) !(N_t_j(1,i)/N_t_j(1,1))
    enddo 
    delta_proc_r = (r_semi_elasticity_reform - r_semi_elasticity_base) !/r_semi_elasticity_base  
    semi_elasticity = delta_K/delta_proc_r
    

    OPEN (unit=6,   FILE = version//closure//"OPD_K_base.txt")
    OPEN (unit=7,   FILE = version//closure//"OPD_r_base.txt")
    OPEN (unit=8,   FILE = version//closure//"OPD_tk_base.txt")
    OPEN (unit=9,   FILE = version//closure//"OPD_K_reform.txt")
    OPEN (unit=10,  FILE = version//closure//"OPD_r_reform.txt")
    OPEN (unit=11,  FILE = version//closure//"OPD_tk_reform.txt")
    OPEN (unit=12,  FILE = version//closure//"OPD_semi_elasticity_with_respect_to_r.txt")
    OPEN (unit=12,  FILE = version//closure//"OPD_semi_elasticity_with_respect_to_tk.txt")
            write(6,   '(F20.10)') K_semi_elasticity_base
            write(7,   '(F20.10)') r_semi_elasticity_base
            write(8,   '(F20.10)') tk_base
            write(9,   '(F20.10)') K_semi_elasticity_reform
            write(10,  '(F20.10)') r_semi_elasticity_reform
            write(11,  '(F20.10)') tk_reform
            write(12,  '(F20.10)') semi_elasticity
            write(13,  '(F20.10)') delta_K/0.01d0
    close(6)
    close(7)
    close(8)
    close(9)
    close(10)
    close(11)
    close(12)
    close(13)
    
    switch_partial_semi = 0
