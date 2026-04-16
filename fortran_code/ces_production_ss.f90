!===============================================================================
! FILE: ces_production_ss.f90
!
! DESCRIPTION:
!   Computes type-specific wages w_bar_ss(m) in steady state using CES
!   production technology. Steady-state counterpart of ces_production.f90.
!
! INCLUDED IN: steady_state.f90 via include statement
!
! KEY OUTPUTS: w_bar_ss(m), multiplier_ces_ss
!===============================================================================
     
    
    if (rho_subst == 1) then ! perfect substitutes 
    do m = 1,bigM,1
        w_bar_ss(m) = type_multiplier_ss(m) * zbar*(1 - alpha)*k_ss**alpha
    enddo
    
    
    elseif (rho_subst == 0) then! Cobb-Douglas 
    do m = 1,bigM,1  
        w_bar_ss(m) = type_multiplier_ss(m)/sum(type_multiplier_ss) * (bigl_ss / bigl_type_ss(m)) * zbar*(1 - alpha)*k_ss**alpha
    enddo
    

    else ! generic case
    multiplier_ces_ss  = sum ( type_multiplier_ss * bigl_type_ss ** rho_subst) ** (1.0d0/rho_subst - 1.0d0)
    
    do m = 1,bigM,1
        w_bar_ss(m) = type_multiplier_ss(m) * bigl_type_ss(m) ** (rho_subst - 1.0d0) * multiplier_ces_ss * zbar*(1 - alpha)*k_ss**alpha  
    enddo    
    endif

    