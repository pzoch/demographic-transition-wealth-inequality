!===============================================================================
! FILE: ces_production_ss.f90
!
! DESCRIPTION:
!   Calculates type-specific wages in steady state using CES production function
!   with imperfect substitution across labor types. Steady-state variant.
!
! SCRIPT (included code fragment)
!   Executed within steady state solver to compute w_bar_ss(m).
!
! PRODUCTION FUNCTION:
!   Y = zbar * K^α * L^(1-α), where L = [∑_m θ_m * L_m^ρ]^(1/ρ)
!   ρ = rho_subst: Elasticity parameter (ρ=1 ⇒ perfect substitutes, ρ=0 ⇒ Cobb-Douglas)
!   θ_m = type_multiplier_ss(m): Type-specific productivity (steady state)
!
! CASES:
!   - rho_subst = 1: Perfect substitutes
!     w_bar_ss(m) = θ_m * zbar*(1-α)*k_ss^α
!   - rho_subst = 0: Cobb-Douglas
!     w_bar_ss(m) = θ_m/∑θ_m * (bigl_ss/bigl_type_ss(m)) * zbar*(1-α)*k_ss^α
!   - Generic CES:
!     w_bar_ss(m) = θ_m * bigl_type_ss(m)^(ρ-1) * [∑θ_m*bigl_type_ss^ρ]^(1/ρ-1) * zbar*(1-α)*k_ss^α
!
! INPUTS (from global_vars):
!   - k_ss: Steady-state capital
!   - bigl_type_ss(m): Type-specific labor supply
!   - type_multiplier_ss(m): Type productivity
!   - alpha: Capital share (steady state)
!
! OUTPUTS:
!   - w_bar_ss(m): Type-specific steady-state wage rates
!   - multiplier_ces_ss: CES aggregator (generic case)
!
! NOTES:
!   Included in steady_state.f90 solver. Parallel to ces_production.f90 for
!   transition path. Keep both synchronized when modifying production structure.
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

    