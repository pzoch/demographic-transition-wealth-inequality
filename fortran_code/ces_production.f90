!===============================================================================
! FILE: ces_production.f90
!
! DESCRIPTION:
!   Computes type-specific wages during transition path using CES production
!   function with imperfect substitution across education types. Allows for
!   skill-biased technological change and varying complementarity between
!   high-school and college labor.
!
! INCLUDED IN: transition.f90 via include statement
!
! PURPOSE:
!   Calculate wages w_bar(m,t) for each education type m at each time t,
!   given capital k(t) and type-specific labor supplies bigl_type(m,t).
!
! PRODUCTION FUNCTION:
!   Output: Y(t) = zbar * K(t)^alpha * L(t)^(1-alpha)
!   Where aggregate labor L(t) is CES aggregate of type-specific labor:
!     L(t) = [sum_m theta(m,t) * L_m(t)^rho]^(1/rho)
!
!   Parameters:
!     alpha = capital share (typically 0.33-0.36)
!     rho = rho_subst = substitution parameter
!       rho = 1: Perfect substitutes (all types identical)
!       rho = 0: Cobb-Douglas (unit elasticity of substitution)
!       rho < 0: Imperfect substitutes (typical case, e.g., rho = -0.5)
!     theta(m,t) = type_multiplier_t(m,t) = relative productivity of type m
!
! ELASTICITY OF SUBSTITUTION:
!   sigma = 1 / (1 - rho)
!   rho = 1 => sigma = infinity (perfect substitutes)
!   rho = 0 => sigma = 1 (Cobb-Douglas)
!   rho = -1 => sigma = 0.5 (low substitutability)
!
! WAGE FORMULAS:
!   Marginal product of type-m labor determines wage:
!     w_bar(m,t) = (partial Y / partial L_m) = FL(K,L) * (partial L / partial L_m)
!
!   CASE 1: rho_subst = 1 (perfect substitutes)
!     L(t) = sum_m theta(m,t) * L_m(t)
!     w_bar(m,t) = theta(m,t) * zbar*(1-alpha)*k(t)^alpha
!     All types paid their productivity-adjusted marginal product
!
!   CASE 2: rho_subst = 0 (Cobb-Douglas)
!     L(t) = product_m [L_m(t)^(theta(m,t)/sum theta)]
!     w_bar(m,t) = [theta(m,t)/sum(theta)] * [L(t)/L_m(t)] * zbar*(1-alpha)*k(t)^alpha
!     Wage depends on own labor supply (decreasing returns to scale by type)
!
!   CASE 3: Generic CES (rho != 0, 1)
!     L(t) = [sum_m theta(m,t) * L_m(t)^rho]^(1/rho)
!     multiplier_ces(t) = L(t)^(1-rho) = [sum_m theta*L_m^rho]^(1/rho - 1)
!     w_bar(m,t) = theta(m,t) * L_m(t)^(rho-1) * multiplier_ces(t) * zbar*(1-alpha)*k(t)^alpha
!     Wage depends on relative scarcity of type m
!
! SKILL PREMIUM:
!   College wage premium = w_bar(college,t) / w_bar(high_school,t)
!   Depends on:
!     1. Relative productivity: theta(college) / theta(high_school)
!     2. Relative supply: L_college(t) / L_hs(t) (if rho < 1)
!     3. Capital deepening: k(t)^alpha (neutral across types)
!
! TIME VARIATION:
!   - type_multiplier_t(m,t): Can change over time (skill-biased tech change)
!   - bigl_type(m,t): Type-specific labor supply evolves with demographics
!   - Capital k(t): Deepening increases all wages proportionally
!
! INPUTS (from transition iteration):
!   - k(t): Capital stock per effective labor (bigT vector)
!   - bigl_type(m,t): Type-specific labor supply (bigM × bigT matrix)
!   - type_multiplier_t(m,t): Type productivity (bigM × bigT matrix)
!   - alpha_t(t): Capital share (typically constant, bigT vector)
!   - rho_subst: Substitution elasticity parameter (scalar)
!   - zbar: TFP level (normalized to 1.0)
!
! OUTPUTS:
!   - w_bar(m,t): Type-specific wage per efficiency unit (bigM × bigT matrix)
!   - multiplier_ces(t): CES aggregator multiplier (bigT vector, generic case)
!
! ECONOMIC INTERPRETATION:
!   - If rho < 1 (imperfect substitutes): Increase in college graduates
!     reduces college wage premium (supply effect)
!   - If rho = 1 (perfect substitutes): College premium determined only
!     by productivity difference theta_college/theta_hs
!   - Typical calibration: rho ≈ 0.4-0.6 (sigma ≈ 1.67-2.5) to match
!     observed skill premium response to supply changes
!
! NOTES:
!   - Parallel to ces_production_ss.f90 for steady state
!   - Keep both files synchronized when modifying production structure
!   - Executed every iteration of transition path
!   - bigM typically 2 (high school, college) but can accommodate more types
!===============================================================================

    if (rho_subst == 1) then ! perfect substitutes 
    do m = 1,bigM,1
        w_bar(m,:) = type_multiplier_t(m,:) * zbar*(1 - alpha_t)*k(:)**alpha_t
    enddo
    
    
    elseif (rho_subst == 0) then! Cobb-Douglas 
    do m = 1,bigM,1  
        w_bar(m,:) = type_multiplier_t(m,:)/sum(type_multiplier_t) * (bigl(:) / bigl_type(m,:)) * zbar*(1 - alpha_t)*k(:)**alpha_t
    enddo
    

    else ! generic case
        
    do i = 1,bigT,1    
        multiplier_ces(i)  = sum ( type_multiplier_t(:,i) * bigl_type(:,i) ** rho_subst) ** (1.0d0/rho_subst - 1.0d0)
    enddo
    
    do m = 1,bigM,1
        w_bar(m,:) = type_multiplier_t(m,:) * bigl_type(m,:) ** (rho_subst - 1.0d0) * multiplier_ces * zbar*(1 - alpha)*k**alpha_t  
    enddo    
    endif

    