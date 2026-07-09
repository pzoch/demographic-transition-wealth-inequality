!===============================================================================
! FILE: pfi_print.f90
!
! DESCRIPTION:
!   Diagnostic CSV output for policy functions and distributions.
!   Currently mostly commented out; uncomment selectively for debugging.
!
! KEY OUTPUTS: c_vfi.csv, s_vfi.csv, l_vfi.csv, prob_trans_*.csv
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