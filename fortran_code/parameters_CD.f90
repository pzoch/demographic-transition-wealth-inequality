! WHAT   : Consumer problem -> parametrization for CD utility function 
! TAKE   : unchanged in routine:   switch_two_rates - 0 = one interest rate, 1 = two interest rates; switch_bequest -  0 = bequests collected and spreaded uniformly; 1 = bequests remain in respective cohort  
!          changed   in routine:   time-consistent (exponential) preferences [[beta]], capital depreciation [[depr]], the standard discount factor [[delta]], replacement ratio in old  [[rho_1]] and new [[rho_2]] PAYG pension system
!          changed   in routine:   contribution to 1st pillar [[t1_ss]], the inverse of Frisch elasticity of labor [[ksi]], the disutility of labor [[psi]], preference for leisure [[phi]]
! DO     : called in globals subroutine to clean parameters
! RETURN : calibration of the model


!           case 0 - omega = 1 and beta = 1            
            beta = 1.0d0



            ! k/y =2.75, alpha = 0.33
            depr = (1.0_dp + 0.050_dp)**zbar - 1.0_dp 
            delta =  (0.99_dp)**zbar ! 0.9726968 !1.0476838584 !1.0447238439d0 !1.0150d0**(zbar)   !(0.9862_dp)
            phi = 0.30d0 ! 0.3920313 !0.359375_dp
            rho_1 = 0.7d0 !0.225_dp!*0.0d0
            rho_2 = 0.7d0 !0.225_dp!*0.0d0
            t1_ss_old =  0.1_dp!*0.5d0 0d0 !
            t1_ss_new =  0.1_dp
            t2_ss_old = 0d0 !0.077_dp*0.5d0 !
            t2_ss_new = 0.0d0 !39d0
            
            !! k/y =2.65, alpha = 0.33
            !depr = (1.0_dp + 0.047_dp)**zbar - 1.0_dp 
            !delta =  0.9845369d0 ! 0.9726968 !1.0476838584 !1.0447238439d0 !1.0150d0**(zbar)   !(0.9862_dp)
            !phi = 0.37125d0 ! 0.3920313 !0.359375_dp
            !rho_1 = 1.0140625d0 !0d0! 0.9484375d0 !1.1562500d0 ! 0.6d0 !0.225_dp!*0.0d0
            !rho_2 = 1.0140625d0 !0d0! 0.9484375d0 !1.1562500d0 !0.6d0 !0.225_dp!*0.0d0
            !t1_ss_old =  0.052d0/(1d0-alpha)! 0.0745_dp!*0.5d0 0d0 !
            !t1_ss_new =  0.052d0/(1d0-alpha) !0.0745d0
            


              
       if (switch_cohort_ps == 1) then
            rho_1 = 0.5d0 !0.225_dp!*0.0d0
            rho_2 = 0.5d0 !0.225_dp!*0.0d0    
        endif

         
