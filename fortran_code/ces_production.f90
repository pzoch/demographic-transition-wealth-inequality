
    
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

    