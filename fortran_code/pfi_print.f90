!===============================================================================
! FILE: pfi_print.f90
!
! DESCRIPTION:
!   Output routines for policy function iteration results. Writes value/policy
!   functions and distributions to CSV files for post-processing and visualization.
!
! SUBROUTINES:
!   - output: Main output routine (currently commented out)
!             Writes c_vfi, s_vfi, l_vfi, prob_trans to CSV files
!
! OUTPUT FILES (when active):
!   - c_vfi.csv: Consumption policy by (j, time) - semicolon delimited
!   - s_vfi.csv: Savings policy by (j, time)
!   - l_vfi.csv: Labor supply policy by (j, time)
!   - prob_trans_*.csv: Distribution snapshots at different time periods
!
! FORMAT:
!   CSV with semicolon separators. Rows = age j, Columns = time periods.
!   Last column written without separator (advance='no' then final value).
!
! CURRENT STATUS:
!   Most output code commented out (lines 4-72). Likely disabled for performance
!   during production runs. Uncomment selectively for debugging/diagnostics.
!
! TYPICAL USAGE PATTERN:
!   do j = 1, bigJ
!     do i = 1, bigT-1
!       write(unit, '(F20.10)', advance='no') variable(j,i)
!       write(unit, '(A)', advance='no') ";"
!     enddo
!     write(unit, '(F20.10)') variable(j,bigT)  ! Last column, newline
!   enddo
!
! NOTES:
!   Unit numbers 103, 111 used. Ensure proper CLOSE to avoid file locks.
!   Distributions prob_trans summed over state dimensions before writing.
!   Enable selectively - full output can generate GB of data for large grids.
!===============================================================================
!***************************************************************************************
    subroutine output()
    implicit none
!    open(unit = 103, file= "c_vfi.csv")
!
!         do j = 1, bigJ,1  
!            do i = 1,bigT-1,1
!                write(103, '(F20.10)', advance='no') c_j_vfi(j,i)
!                write(103, '(A)', advance='no') ";"
!            enddo
!             write(103, '(F20.10)') c_j_vfi(j,bigT)
!   
!         enddo       
!            close(103)
!              open(unit = 103, file= "s_vfi.csv")
!         do j = 1, bigJ,1  
!            do i = 1,bigT-1,1
!                write(103, '(F20.10)', advance='no') s_pom_j_vfi(j,i)
!                write(103, '(A)', advance='no') ";"
!            enddo
!             write(103, '(F20.10)') s_pom_j_vfi(j,bigT)
!   
!         enddo       
!            close(103)
!             open(unit = 111, file= "l_vfi.csv")
!         do j = 1, bigJ,1  
!            do i = 1,bigT-1,1
!                write(111, '(F20.10)', advance='no') l_j_vfi(j,i)
!                write(111, '(A)', advance='no') ";"
!            enddo
!             write(111, '(F20.10)') l_j_vfi(j,bigT)
!   
!         enddo       
!            close(111)
!
!   open(unit = 111, file= "prob_trans_1.csv")
!         do j = 1, bigJ,1  
!            do i = 1,n_a-1,1
!                write(111, '(F20.10)', advance='no') sum(prob_trans(j, i, :,  :, 5,1,1))
!                write(111, '(A)', advance='no') ";"
!            enddo
!            write(111, '(F20.10)') sum(prob_trans(j, n_a, :, :, 1, 1, 1))
!         enddo       
!close(111)
!
!open(unit = 111, file= "prob_trans_n.csv")
!         do j = 1, bigJ,1  
!            do i = 1,n_a-1,1
!                write(111, '(F20.10)', advance='no') sum(prob_trans(j, i, :,  :, 5, 1, 50))
!                write(111, '(A)', advance='no') ";"
!            enddo
!             write(111, '(F20.10)') sum(prob_trans(j, n_a, :, :, 5, 1, 50))
!         enddo       
!close(111)
!          
!    open(unit = 104, file= "euler_trans.csv")
!        do j = 1, bigJ,1  
!            do i = 2,bigT,1
!                write(104, '(F20.10)', advance='no') check_euler_trans(j, i)
!                write(104, '(A)', advance='no') ";"
!            enddo
!             write(104, '(F20.10)') check_euler_trans(j, bigT)
!        enddo      
!    close(104)
!!
!     open(unit = 104, file= "svs.csv")     
!            do i = 0,n_a,1
!                write(104, '(F20.10)', advance='no') sv(i)
!                write(104, '(A)', advance='no') ";"
!            enddo
!    close(104)
    end subroutine 