!***************************************************************************************

! get distribution for every gridpoint and state for every age
! Steady state
    subroutine get_distribution_ss()

            implicit none

            integer :: j, ial, iar, iaimel, iaimer, ind
            real*8 :: dist, dist_aime, ia_initial(n_beq), p_initial(n_beq), const

            ! set distribution to zero
            prob_ss = 0d0

            const = 0d0
            
            if((switch_unequal_bequest==1))then
                !ia_initial(2) = bequest_ss_vfi / 
                !ia_initial(1) = 0d0
                do ind=1,n_beq,1 !normalizing constant
                    const = const + 1/ind**(zipf)
                enddo
                
                do ind=n_beq,1,-1
                    p_initial(ind) = 1d0/ind**(zipf)/const !zipf law p.d.f. 
                    ia_initial(ind) = 1d0/(2d0**(n_beq-ind+1))* bequest_ss_vfi/(p_initial(ind)*N_ss_j_vfi(1)) ! 1d0/(2d0**(n_beq-ind+1)) - number of people in one sub-cohort,  bequest_ss_vfi - sum of bequest, 
                    !(p_initial(ind)*edu_rate*N_ss_j_vfi(1)) -  part of bequest which agent from ind- subcohort inherit  
                    !p_initial(ind) = 0.0d0
                    !ia_initial(ind) = 0.0d0
                enddo
                    ia_initial(2) = 1d0/(2d0**(n_beq-2))* bequest_ss_vfi/(p_initial(2)*N_ss_j_vfi(1))
                    ia_initial(1) = 0d0
                    
                    const = sum(ia_initial)
                    const = sum(ia_initial * p_initial)
                    const = sum(p_initial)
                do ind=1,n_beq,1
                    call linear_int(ia_initial(ind), ial, iar, dist, sv, n_a, a_grow)
                    ial = min(ial, n_a)
                    iar = min(iar, n_a)
                    dist = min(dist, 1d0)

                    
                    prob_ss(1, ial, 0, :, :, :)  = prob_ss(1, ial, 0, :, :, :)  + p_initial(ind)*dist ! y-ss rename f_dens_ss ! poczatkowy rozk³ad
                    prob_ss(1, iar, 0, :,  :, :) = prob_ss(1, iar, 0, :, :, :) +  p_initial(ind)*(1d0 - dist)
                    
                    
                enddo
                  ! need to amend it to get initial dispersion
                const = 0.0d0
                 do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1 , n_sp, 1
                            do ir=1, n_sr, 1
                                do id=1,n_sd,1 
                                prob_ss(1, ia, i_aime, ip, ir, id) = prob_ss(1, ia, i_aime, ip, ir, id) * pi_ip_init(ip) * pi_id_init(id) * pi_ir_init(ir)
                                const = const + prob_ss(1, ia, i_aime, ip, ir, id)
                                enddo
                            enddo
                        enddo
                    enddo
              enddo
                
            else
            
            
            ! get initial distribution in age 1
            call linear_int(0d0, ial, iar, dist, sv, n_a, a_grow)
            ial = min(ial, n_a)
            iar = min(iar, n_a)
            dist = min(dist, 1d0)
            
            
            ! need to amend it to get initial dispersion
            
            prob_ss(1, ial, 0, :, :, :) = dist ! y-ss rename f_dens_ss ! poczatkowy rozk³ad
            prob_ss(1, iar, 0, :,  :, :) = 1d0 - dist
            
            
              do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1 , n_sp, 1
                            do ir=1, n_sr, 1
                                do id=1,n_sd,1 
                                prob_ss(1, ia, i_aime, ip, ir, id) = prob_ss(1, ia, i_aime, ip, ir, id) * pi_ip_init(ip) * pi_id_init(id) * pi_ir_init(ir)
                                enddo
                            enddo
                        enddo
                    enddo
              enddo

    
                        
            endif
            ! successively compute distribution over ages
            do j = 2, bigJ  
            ! iterate over yesterdays gridpoints
                do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1 , n_sp, 1
                            do ir=1, n_sr, 1
                                do id=1,n_sd,1 
                                    ! interpolate yesterday's savings decision
                                    call linear_int(svplus_ss(j-1, ia, i_aime, ip, ir, id), ial, iar, dist, sv, n_a, a_grow)
                                    call linear_int(aime_plus_ss(j-1, ia, i_aime, ip, ir, id), iaimel, iaimer, dist_aime, aime(:), n_aime, aime_grow)
                                    ! restrict values to grid just in case               
                                    dist = min(abs(dist), 1d0)

                                    ! redistribute households
                                    do ip_p = 1, n_sp,1
                                        do ir_r=1, n_sr, 1
                                            do id_d =1, n_sd, 1
                                                prob_ss(j, ial, iaimel, ip_p, ir_r, id_d) = prob_ss(j, ial, iaimel, ip_p, ir_r, id_d) &
                                                                                            + pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id, id_d)*dist       *dist_aime       *prob_ss(j-1, ia, i_aime, ip, ir, id)
                                                prob_ss(j, iar, iaimel, ip_p, ir_r, id_d) = prob_ss(j, iar, iaimel, ip_p, ir_r, id_d) &
                                                                                            + pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id, id_d)*(1d0-dist) *dist_aime       *prob_ss(j-1, ia, i_aime, ip, ir, id) 
                                                prob_ss(j, ial, iaimer, ip_p, ir_r, id_d) = prob_ss(j, ial, iaimer, ip_p, ir_r, id_d) &
                                                                                            + pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id, id_d)*dist       *(1d0-dist_aime) *prob_ss(j-1, ia, i_aime, ip, ir, id)
                                                prob_ss(j, iar, iaimer, ip_p, ir_r, id_d) = prob_ss(j, iar, iaimer, ip_p, ir_r, id_d) &
                                                                                            + pi_ip(ip, ip_p)*pi_ir(ir, ir_r)*pi_id(id, id_d)*(1d0-dist)  *(1d0-dist_aime)*prob_ss(j-1, ia, i_aime, ip, ir, id) 
                                            enddo
                                        enddo
                                    enddo
                                enddo
                            enddo
                        enddo
                    enddo
                enddo
            enddo 


        end subroutine
!***************************************************************************************

! get distribution for every gridpoint and state for every age
! for transition

    subroutine get_distribution_trans(i)



            implicit none
            integer, intent(in) :: i
            integer :: j, ial, iar, iaimel, iaimer, itm, year_birth, tp,ind
            real*8 :: dist, dist_aime, ia_initial(n_beq), p_initial(n_beq), const

            
            
            ! get yesterdays year
            itm = year(i, 2, 1) 
        
            ! set distribution to zero
            prob_trans(:,:,:,:,:,:,i) = 0d0 
            const = 0d0
            p_initial = 0d0
            ia_initial =0d0
            ! get initial distribution in age 1 
            if ((switch_unequal_bequest==1)) then
                !ia_initial(2) = bequest_ss_vfi / 
                !ia_initial(1) = 0d0
                
                
                
                !!!
                
                
                
                
                
                
                
                do ind=1,n_beq,1 !normalizing constant
                    const = const + 1/ind**(zipf)
                enddo
                
                do ind=n_beq,1,-1
                    p_initial(ind) = 1d0/ind**(zipf)/const !zipf law p.d.f. 
                    ia_initial(ind) = 1d0/(2d0**(n_beq-ind+1))* bequest_vfi(i)/(p_initial(ind)*N_t_j_vfi(1,i)) ! 1d0/(2d0**(n_beq-ind+1)) - number of people in one sub-cohort,  bequest_ss_vfi - sum of bequest, 

                enddo
                    ia_initial(2) = 1d0/(2d0**(n_beq-2))* bequest_vfi(i)/(p_initial(2)*N_t_j_vfi(1,i))
                    ia_initial(1) = 0d0
                do ind=1,n_beq,1
                    call linear_int(ia_initial(ind), ial, iar, dist, sv, n_a, a_grow)
                    ial = min(ial, n_a)
                    iar = min(iar, n_a)
                    dist = min(dist, 1d0)

                    prob_trans(1, ial, 0, :, :, :, i)  = prob_trans(1, ial, 0, n_sp_initial, n_sr_initial, n_sd_initial,i) +  p_initial(ind)*dist ! y-ss rename f_dens_ss ! poczatkowy rozk³ad
                    prob_trans(1, iar, 0, :, :, :, i) =  prob_trans(1, iar, 0,  n_sp_initial,  n_sr_initial, n_sd_initial,i) + p_initial(ind)*(1d0 - dist)
                enddo
                
                   do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1 , n_sp, 1
                            do ir=1, n_sr, 1
                                do id=1,n_sd,1 
                                prob_trans(1, ia, i_aime, ip, ir, id, i) = prob_trans(1, ia, i_aime, ip, ir, id, i) * pi_ip_init_trans(ip,i) * pi_id_init(id) * pi_ir_init(ir)
                                enddo
                            enddo
                        enddo
                    enddo
              enddo
                   
                
            else
            
                    
            call linear_int(0d0, ial, iar, dist, sv, n_a, a_grow)
                    ial = min(ial, n_a)
                    iar = min(iar, n_a)
                    dist = min(dist, 1d0)
            prob_trans(1, ial, 0, :, :, :, i) = dist ! y-ss rename f_dens_ss ! poczatkowy rozk³ad
            prob_trans(1, iar, 0, :, :, :, i) = 1d0 - dist
            
            
              do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1 , n_sp, 1
                            do ir=1, n_sr, 1
                                do id=1,n_sd,1 
                                prob_trans(1, ia, i_aime, ip, ir, id, i) = prob_trans(1, ia, i_aime, ip, ir, id, i) * pi_ip_init_trans(ip,i) * pi_id_init(id) * pi_ir_init(ir)
                                enddo
                            enddo
                        enddo
                    enddo
              enddo
              
           endif     
            
            ! successively compute distribution over ages
            do j = 2, bigJ
                
        
            year_birth = i - j + 1  ! get year of birth to assign correct sigma2_epsilon -- so this seems to be cohort specific


            tp = year_birth 

            if (tp < 1) then
                tp = 1
            elseif (tp > bigT) then
                tp = bigT
            endif
            
                ! iterate over yesterdays gridpoints
                do ia = 0, n_a, 1
                    do i_aime = 0, n_aime, 1
                        do ip = 1 , n_sp, 1
                            do ir=1, n_sr, 1
                                do id =1, n_sd, 1
                                    ! interpolate_trans yesterday's savings decision
                                    call linear_int(   svplus_trans(j-1, ia, i_aime, ip, ir, id, itm), ial, iar, dist, sv, n_a, a_grow)
                                    call linear_int(aime_plus_trans(j-1, ia, i_aime, ip, ir, id, itm), iaimel, iaimer, dist_aime, aime(:), n_aime, aime_grow)
                                    ! restrict values to grid just in case
                                    ial = min(ial, n_a)
                                    iar = min(iar, n_a)
                                    dist = min(abs(dist), 1d0)
                                    ! redistribute household_transs
                                    do ip_p = 1, n_sp,1
                                        do ir_r=1, n_sr, 1
                                            do id_d =1, n_sd, 1
                                                prob_trans(j, ial, iaimel, ip_p, ir_r, id_d, i) = prob_trans(j, ial, iaimel, ip_p, ir_r, id_d, i) + pi_ip_trans(ip, ip_p, tp)*pi_ir(ir, ir_r)*pi_id(id, id_d)*dist*dist_aime            *prob_trans(j-1, ia, i_aime, ip, ir, id, itm)
                                                prob_trans(j, iar, iaimel, ip_p, ir_r, id_d, i) = prob_trans(j, iar, iaimel, ip_p, ir_r, id_d, i) + pi_ip_trans(ip, ip_p, tp)*pi_ir(ir, ir_r)*pi_id(id, id_d)*(1d0-dist)*dist_aime      *prob_trans(j-1, ia, i_aime, ip, ir, id, itm)
                                                prob_trans(j, ial, iaimer, ip_p, ir_r, id_d, i) = prob_trans(j, ial, iaimer, ip_p, ir_r, id_d, i) + pi_ip_trans(ip, ip_p, tp)*pi_ir(ir, ir_r)*pi_id(id, id_d)*dist*(1d0-dist_aime)      *prob_trans(j-1, ia, i_aime, ip, ir, id, itm)
                                                prob_trans(j, iar, iaimer, ip_p, ir_r, id_d, i) = prob_trans(j, iar, iaimer, ip_p, ir_r, id_d, i) + pi_ip_trans(ip, ip_p, tp)*pi_ir(ir, ir_r)*pi_id(id, id_d)*(1d0-dist)*(1d0-dist_aime)*prob_trans(j-1, ia, i_aime, ip, ir, id, itm)
                                            enddo
                                        enddo
                                    enddo
                                enddo
                            enddo
                        enddo
                    enddo
                enddo
            enddo 
    end subroutine