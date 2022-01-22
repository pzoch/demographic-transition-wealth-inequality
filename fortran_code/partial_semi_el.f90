!!Semi elasticity of capital:
!!For fixed prices and transfers - so GE - we calculate semi elasticity of capital, 
!!which means we are interested in % change of net interest rate and simple changes of capital. 
!!
!!We keep macro variables as in the first steady-state. 
!!Then we solve the agent's problem for the transition population structure.  
!!In the second step, we adjust the net interest rate and resolve the agent's problem.
!!
!!In the DC scenario, we also adjust pension system benefits. 
!!Thus we neede to recalculate implicit tax in the second step.
!!
!!In the third step, we can calculate semi elasticities = Delta K/% Delta r
!   
!! 1st step base for elasticities 
!    ! implicit tax base on 1st ss values 
!    ! tax rate increase by 1 % tk = 1.01*tk, thus 
!    switch_partial_semi = 1
!        r = 1d0 + (1-tk(1))*r_bar(1)
!        include 'partial_semi_do.f90'
!        
!    ! calculate total capital   
!    
!      K_semi_elasticity_base   =sum(N_t_j*sv_j_el, dim=1)+sum(N_t_j*pillarII_j, dim=1)
!      r_semi_elasticity_base  = r
!! 2nd step r net change 
!    ! implicit tax base on 1st ss values 
!    ! assign macro variables
!        r = 1.01d0 *(1d0 + (1-tk(1))*r_bar(1))
!        include 'partial_semi_do.f90'
!    ! calculate total capital 
!    
!   K_semi_elasticity_reform =sum(N_t_j*sv_j_el, dim=1) + sum(N_t_j*pillarII_j, dim=1)
!   r_semi_elasticity_reform = r
!      
!! 3rd elasticities 
!    
!    delta_K =  K_semi_elasticity_reform - K_semi_elasticity_base
!        
!! we need to take into account increase of # number 
!    do i = 1, bigT, 1
!        delta_K(i) = delta_K(i)/(N_t_j(1,i)/N_t_j(1,1))
!    enddo 
!    delta_proc_r = (r_semi_elasticity_reform - r_semi_elasticity_base)/r_semi_elasticity_base  
!    semi_elasticity = delta_K/delta_proc_r
!    
!
!    OPEN (unit=7,   FILE = version//closure//"K_base.txt")
!    OPEN (unit=8,   FILE = version//closure//"r_base.txt")
!    OPEN (unit=9,   FILE = version//closure//"K_reform.txt")
!    OPEN (unit=10,  FILE = version//closure//"r_reform.txt")
!    OPEN (unit=11,  FILE = version//closure//"semi_elasticity.txt")
!            write(7,   '(F20.10)') K_semi_elasticity_base/K_semi_elasticity_base(1)*k(1)
!            write(8,   '(F20.10)') r_semi_elasticity_base
!            write(9,   '(F20.10)') K_semi_elasticity_reform/K_semi_elasticity_base(1)*k(1)
!            write(10,  '(F20.10)') r_semi_elasticity_reform
!            write(11,  '(F20.10)') semi_elasticity/K_semi_elasticity_base(1)
!    close(7)
!    close(8)
!    close(9)
!    close(10)
!    close(11)
!    
!    switch_partial_semi = 0
