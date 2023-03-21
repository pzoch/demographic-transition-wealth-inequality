

!##############################################################################
!##############################################################################
! MODULE sorting
! Required for Gini calculation
!##############################################################################
!############################################################################## 
module sorting

implicit none

! declare everything as private by default
private
! should the random tbox_seed be set
logical, private :: tbox_seed = .true.

! Level of tolerance for all routines
real*8,  private  :: tbox_gftol = 1d-8

! Maximum number of iterations
integer, private  :: tbox_itermax_min = 200

! Maximum number of iterations for brent_pow
integer, parameter, private  :: tbox_tbox_itermax_pow_b = 150

! Level of tolerance for all routines
real*8,  private  :: tbox_gftol_root = 1d-8

! sorting
public :: sort

interface sort

    module procedure sort_r, sort_r2, sort_i, sort_i2

end interface 

contains
    
    !##############################################################################
    ! SUBROUTINE sort_r
    !
    ! Sorts an array of type real*8 in ascending order.
    !
    ! PARTS OF THIS PROCEDURE WERE COPIED AND ADAPTED FROM:
    !     The Wikibook "Algorithm Implementation" available at
    !     https://en.wikibooks.org/wiki/Algorithm_Implementation/Sorting/Quicksort#FORTRAN_90.2F95
    !
    !     and follows closely the Qsort implementation found in 
    !     "A FORTRAN 90 Numerical Library" (AFNL), which is available at
    !     https://sourceforge.net/projects/afnl/
    !
    !     REFERENCE: Ramos, A. (2006). A FORTRAN 90 numerical library.
    !##############################################################################
    subroutine sort_r(x)

        implicit none
        
        
        !##### INPUT/OUTPUT VARIABLES #############################################

        ! the array that should be sorted
        real*8, intent(inout) :: x(:)


        !##### OTHER VARIABLES ####################################################

        ! from which list size should insertion sort be used
        integer, parameter :: Isw = 10

        ! type for the left and right bounds
        type Limits
           integer :: Ileft, Iright
        end type Limits

        ! other variables        
        integer :: Ipvn, Ileft, Iright, ISpos, ISmax
        type(Limits), allocatable :: Stack(:)
        

        !##### ROUTINE CODE #######################################################

        allocate(Stack(Size(X)*2)) 
    
        Stack(:)%Ileft = 0
        
        ! Iniitialize the stack
        Ispos = 1
        Ismax = 1
        Stack(ISpos)%Ileft  = 1
        Stack(ISpos)%Iright = size(X)
        
        do while (Stack(ISpos)%Ileft /= 0)
 
           Ileft = Stack(ISPos)%Ileft
           Iright = Stack(ISPos)%Iright

           ! choose between inseration and quick sort
           if (Iright-Ileft <= Isw) then
              call InsrtLC(X, Ileft, Iright)
              ISpos = ISPos + 1
           else
              Ipvn = ChoosePiv(X, Ileft, Iright)
              Ipvn = Partition(X, Ileft, Iright, Ipvn)
              
              Stack(ISmax+1)%Ileft = Ileft
              Stack(ISmax+1) %Iright = Ipvn-1
              Stack(ISmax+2)%Ileft = Ipvn + 1
              Stack(ISmax+2)%Iright = Iright
              ISpos = ISpos + 1
              ISmax = ISmax + 2
           endif
        enddo

        ! deallocate all arrays
        deallocate(Stack)
        
    
    !##### SUBROUTINES AND FUNCTIONS ##########################################

    contains

            
        !##########################################################################
        ! FUNCTION ChoosePiv
        !
        ! Determines the pivotal element for the quicksort algorithm.
        !##########################################################################
        function ChoosePiv(XX, IIleft, IIright) result (IIpv)


            !##### INPUT/OUTPUT VARIABLES #############################################          

            ! the array to work on
            real*8, intent(in) :: XX(:)

            ! the left and right definition of the sub-array
            integer, intent(in) :: IIleft, IIright
   
            ! the pivotal element that is returned
            integer :: IIpv
            

            !##### OTHER VARIABLES ####################################################
            
            real*8 :: XXcp(3)
            integer :: IIpt(3), IImd


            !##### ROUTINE CODE #######################################################
            
            IImd = Int((IIleft+IIright)/2)
            IIpv = IImd
            XXcp(1) = XX(IIleft)
            XXcp(2) = XX(IImd)
            XXcp(3) = XX(IIright)
            IIpt = (/1,2,3/)
            
            call InsrtLC(XXcp, 1, 3, IIpt)
            
            select case (IIpt(2))
            case (1)
                IIpv = IIleft
            case (2)
                IIpv = IImd
            case (3)
                IIpv = IIright
            End Select
   
        end function

            
        !##########################################################################
        ! SUBROUTINE InsrtLC
        !
        ! Perform an insertion sort of the list XX(:) between index 
        !     values IIl and IIr.
        !##########################################################################
        subroutine InsrtLC(XX, IIl, IIr, IIpt)
       
        
            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            real*8, intent(inout) :: XX(:)

            ! the left and right definition of the sub-array
            integer, intent(in) :: IIl, IIr

            ! the permutations
            integer, intent(inout), optional :: IIpt(:)

            
            !##### OTHER VARIABLES ####################################################
            
            real*8 :: RRtmp
            integer :: II, JJ
            

            !##### ROUTINE CODE #######################################################
      
            do II = IIl+1, IIr
                RRtmp = XX(II)
                do JJ = II-1, 1, -1
                    if (RRtmp < XX(JJ)) then
                        XX(JJ+1) = XX(JJ)
                        if(present(IIpt))call Swap_IN(IIpt, JJ, JJ+1)
                    else
                        Exit
                    endif
                enddo
                XX(JJ+1) = RRtmp
            enddo
           
        end subroutine InsrtLC

        
        !##########################################################################
        ! FUNCTION Partition
        !
        ! Arranges the array X between the index values Ileft and Iright
        !     positioning elements smallers than X(Ipv) at the left and the others 
        !     at the right.
        !##########################################################################
        function Partition(X, Ileft, Iright, Ipv) result(Ipvfn)
        
            
            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            real*8, intent(inout) :: X(:)

            ! the left and right definition of the sub-array and pivotal element
            integer, intent(in) :: Ileft, Iright, Ipv

            ! return value
            integer :: Ipvfn

            
            !##### OTHER VARIABLES ####################################################
            
            real*8 :: Rpv
            integer :: I
            

            !##### ROUTINE CODE #######################################################
        
            Rpv = X(Ipv)
            call Swap(X, Ipv, Iright)
            Ipvfn = Ileft
        
            do I = Ileft, Iright-1
                if (X(I) <= Rpv) then
                    call Swap(X, I, Ipvfn)
                    Ipvfn = Ipvfn + 1
                endif
            enddo
        
            call Swap(X, Ipvfn, Iright)
        
        end function Partition
        

        !##########################################################################
        ! SUBROUTINE Swap
        !
        ! Swaps elements i and j of array x
        !##########################################################################
        subroutine Swap(X, I, J)


            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            real*8, intent(inout) :: X(:)

            ! the left and right definition of the sub-array and pivotal element
            integer, intent(in) :: I, J
            
            
            !##### OTHER VARIABLES ####################################################
            
            real*8 :: Xtmp
            

            !##### ROUTINE CODE #######################################################        
        
            Xtmp = X(I)
            X(I) = X(J)
            X(J) = Xtmp
        
        end subroutine Swap


        !##########################################################################
        ! SUBROUTINE Swap_IN
        !
        ! Swaps elements i and j of an integer array
        !##########################################################################
        subroutine Swap_IN(X, I, J)


            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            integer, intent(inout) :: X(:)

            ! the left and right definition of the sub-array and pivotal element
            integer, intent(in) :: I, J
            
            
            !##### OTHER VARIABLES ####################################################
            
            integer :: Xtmp
            

            !##### ROUTINE CODE #######################################################        
        
            Xtmp = X(I)
            X(I) = X(J)
            X(J) = Xtmp
        
        end subroutine Swap_IN
   
     end subroutine sort_r



    !##############################################################################
    ! SUBROUTINE sort_r2
    !
    ! Sorts an array of type real*8 in ascending order and returns new ordering.
    !
    ! PARTS OF THIS PROCEDURE WERE COPIED AND ADAPTED FROM:
    !     The Wikibook "Algorithm Implementation" available at
    !     https://en.wikibooks.org/wiki/Algorithm_Implementation/Sorting/Quicksort#FORTRAN_90.2F95
    !
    !     and follows closely the Qsort implementation found in 
    !     "A FORTRAN 90 Numerical Library" (AFNL), which is available at
    !     https://sourceforge.net/projects/afnl/
    !
    !     REFERENCE: Ramos, A. (2006). A FORTRAN 90 numerical library.
    !##############################################################################
    subroutine sort_r2(x, iorder)

        implicit none
        
        
        !##### INPUT/OUTPUT VARIABLES #############################################

        ! the array that should be sorted
        real*8, intent(inout) :: x(:)

        ! an array that will contain the new sorting order
        integer, intent(out) :: iorder(size(x, 1))


        !##### OTHER VARIABLES ####################################################

        ! from which list size should insertion sort be used
        integer, parameter :: Isw = 10

        ! type for the left and right bounds
        type Limits
           integer :: Ileft, Iright
        end type Limits

        ! other variables        
        integer :: Ipvn, Ileft, Iright, ISpos, ISmax, ii
        type(Limits), allocatable :: Stack(:)
        

        !##### ROUTINE CODE #######################################################

        ! initialize the sorting order array
        iorder = (/(ii, ii = 1, size(x, 1))/)

        allocate(Stack(Size(X)*2)) 
    
        Stack(:)%Ileft = 0
        
        ! Iniitialize the stack
        Ispos = 1
        Ismax = 1
        Stack(ISpos)%Ileft  = 1
        Stack(ISpos)%Iright = size(X)
        
        do while (Stack(ISpos)%Ileft /= 0)
 
           Ileft = Stack(ISPos)%Ileft
           Iright = Stack(ISPos)%Iright

           ! choose between inseration and quick sort
           if (Iright-Ileft <= Isw) then
              call InsrtLC(X, iorder, Ileft, Iright)
              ISpos = ISPos + 1
           else
              Ipvn = ChoosePiv(X, Ileft, Iright)
              Ipvn = Partition(X, iorder, Ileft, Iright, Ipvn)
              
              Stack(ISmax+1)%Ileft = Ileft
              Stack(ISmax+1) %Iright = Ipvn-1
              Stack(ISmax+2)%Ileft = Ipvn + 1
              Stack(ISmax+2)%Iright = Iright
              ISpos = ISpos + 1
              ISmax = ISmax + 2
           endif
        enddo

        ! deallocate all arrays
        deallocate(Stack)
        
    
    !##### SUBROUTINES AND FUNCTIONS ##########################################

    contains

            
        !##########################################################################
        ! FUNCTION ChoosePiv
        !
        ! Determines the pivotal element for the quicksort algorithm.
        !##########################################################################
        function ChoosePiv(XX, IIleft, IIright) result (IIpv)


            !##### INPUT/OUTPUT VARIABLES #############################################          

            ! the array to work on
            real*8, intent(in) :: XX(:)

            ! the left and right definition of the sub-array
            integer, intent(in) :: IIleft, IIright
   
            ! the pivotal element that is returned
            integer :: IIpv
            

            !##### OTHER VARIABLES ####################################################
            
            real*8 :: XXcp(3)
            integer :: IIpt(3), IImd


            !##### ROUTINE CODE #######################################################
            
            IImd = Int((IIleft+IIright)/2)
            IIpv = IImd
            XXcp(1) = XX(IIleft)
            XXcp(2) = XX(IImd)
            XXcp(3) = XX(IIright)
            IIpt = (/1,2,3/)
            
            call InsrtLC_help(XXcp, 1, 3, IIpt)
            
            select case (IIpt(2))
            case (1)
                IIpv = IIleft
            case (2)
                IIpv = IImd
            case (3)
                IIpv = IIright
            End Select
   
        end function

        !##########################################################################
        ! SUBROUTINE InsrtLC_help
        !
        ! Just a helping routine. Same as below but without iorder.
        !##########################################################################
        subroutine InsrtLC_help(XX, IIl, IIr, IIpt)
       
        
            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            real*8, intent(inout) :: XX(:)

            ! the left and right definition of the sub-array
            integer, intent(in) :: IIl, IIr

            ! the permutations
            integer, intent(inout) :: IIpt(:)

            
            !##### OTHER VARIABLES ####################################################
            
            real*8 :: RRtmp
            integer :: II, JJ
            

            !##### ROUTINE CODE #######################################################
      
            do II = IIl+1, IIr
                RRtmp = XX(II)
                do JJ = II-1, 1, -1
                    if (RRtmp < XX(JJ)) then
                        XX(JJ+1) = XX(JJ)
                        call Swap_IN(IIpt, JJ, JJ+1)
                    else
                        Exit
                    endif
                enddo
                XX(JJ+1) = RRtmp
            enddo
           
        end subroutine InsrtLC_help

            
        !##########################################################################
        ! SUBROUTINE InsrtLC
        !
        ! Perform an insertion sort of the list XX(:) between index 
        !     values IIl and IIr.
        !##########################################################################
        subroutine InsrtLC(XX, iorder, IIl, IIr)
       
        
            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            real*8, intent(inout) :: XX(:)

            ! an array that will contain the new sorting order
            integer, intent(inout) :: iorder(size(XX, 1))

            ! the left and right definition of the sub-array
            integer, intent(in) :: IIl, IIr

            
            !##### OTHER VARIABLES ####################################################
            
            real*8 :: RRtmp
            integer :: IItmp
            integer :: II, JJ
            

            !##### ROUTINE CODE #######################################################
      
            do II = IIl+1, IIr
                RRtmp = XX(II)
                IItmp = iorder(II)
                do JJ = II-1, 1, -1
                    if (RRtmp < XX(JJ)) then
                        XX(JJ+1) = XX(JJ)
                        iorder(JJ+1) = iorder(JJ)
                    else
                        Exit
                    endif
                enddo
                XX(JJ+1) = RRtmp
                iorder(JJ+1) = IItmp
            enddo
           
        end subroutine InsrtLC

        
        !##########################################################################
        ! FUNCTION Partition
        !
        ! Arranges the array X between the index values Ileft and Iright
        !     positioning elements smallers than X(Ipv) at the left and the others 
        !     at the right.
        !##########################################################################
        function Partition(X, iorder, Ileft, Iright, Ipv) result(Ipvfn)
        
            
            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            real*8, intent(inout) :: X(:)

            ! an array that will contain the new sorting order
            integer, intent(inout) :: iorder(size(X, 1))

            ! the left and right definition of the sub-array and pivotal element
            integer, intent(in) :: Ileft, Iright, Ipv

            ! return value
            integer :: Ipvfn

            
            !##### OTHER VARIABLES ####################################################
            
            real*8 :: Rpv
            integer :: I
            

            !##### ROUTINE CODE #######################################################
        
            Rpv = X(Ipv)
            call Swap(X, Ipv, Iright)
            call Swap_IN(iorder, Ipv, Iright)
            Ipvfn = Ileft
        
            do I = Ileft, Iright-1
                if (X(I) <= Rpv) then
                    call Swap(X, I, Ipvfn)
                    call Swap_IN(iorder, I, Ipvfn)
                    Ipvfn = Ipvfn + 1
                endif
            enddo
        
            call Swap(X, Ipvfn, Iright)
            call Swap_IN(iorder, Ipvfn, Iright)
        
        end function Partition
        

        !##########################################################################
        ! SUBROUTINE Swap
        !
        ! Swaps elements i and j of array x
        !##########################################################################
        subroutine Swap(X, I, J)


            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            real*8, intent(inout) :: X(:)

            ! the left and right definition of the sub-array and pivotal element
            integer, intent(in) :: I, J
            
            
            !##### OTHER VARIABLES ####################################################
            
            real*8 :: Xtmp
            

            !##### ROUTINE CODE #######################################################        
        
            Xtmp = X(I)
            X(I) = X(J)
            X(J) = Xtmp
        
        end subroutine Swap


        !##########################################################################
        ! SUBROUTINE Swap_IN
        !
        ! Swaps elements i and j of an integer array
        !##########################################################################
        subroutine Swap_IN(X, I, J)


            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            integer, intent(inout) :: X(:)

            ! the left and right definition of the sub-array and pivotal element
            integer, intent(in) :: I, J
            
            
            !##### OTHER VARIABLES ####################################################
            
            integer :: Xtmp
            

            !##### ROUTINE CODE #######################################################        
        
            Xtmp = X(I)
            X(I) = X(J)
            X(J) = Xtmp
        
        end subroutine Swap_IN
   
    end subroutine sort_r2




    !##############################################################################
    ! SUBROUTINE sort_i
    !
    ! Sorts an array of type integer in ascending order.
    !
    ! PARTS OF THIS PROCEDURE WERE COPIED AND ADAPTED FROM:
    !     The Wikibook "Algorithm Implementation" available at
    !     https://en.wikibooks.org/wiki/Algorithm_Implementation/Sorting/Quicksort#FORTRAN_90.2F95
    !
    !     and follows closely the Qsort implementation found in 
    !     "A FORTRAN 90 Numerical Library" (AFNL), which is available at
    !     https://sourceforge.net/projects/afnl/
    !
    !     REFERENCE: Ramos, A. (2006). A FORTRAN 90 numerical library.
    !##############################################################################
    subroutine sort_i(x)

        implicit none
        
        
        !##### INPUT/OUTPUT VARIABLES #############################################

        ! the array that should be sorted
        integer, intent(inout) :: x(:)


        !##### OTHER VARIABLES ####################################################

        ! from which list size should insertion sort be used
        integer, parameter :: Isw = 10

        ! type for the left and right bounds
        type Limits
           integer :: Ileft, Iright
        end type Limits

        ! other variables        
        integer :: Ipvn, Ileft, Iright, ISpos, ISmax
        type(Limits), allocatable :: Stack(:)
        

        !##### ROUTINE CODE #######################################################
        
        allocate(Stack(Size(X)*2))
    
        Stack(:)%Ileft = 0
        
        ! Iniitialize the stack
        Ispos = 1
        Ismax = 1
        Stack(ISpos)%Ileft  = 1
        Stack(ISpos)%Iright = size(X)
        
        do while (Stack(ISpos)%Ileft /= 0)
 
           Ileft = Stack(ISPos)%Ileft
           Iright = Stack(ISPos)%Iright

           ! choose between inseration and quick sort
           if (Iright-Ileft <= Isw) then
              call InsrtLC(X, Ileft, Iright)
              ISpos = ISPos + 1
           else
              Ipvn = ChoosePiv(X, Ileft, Iright)
              Ipvn = Partition(X, Ileft, Iright, Ipvn)
              
              Stack(ISmax+1)%Ileft = Ileft
              Stack(ISmax+1) %Iright = Ipvn-1
              Stack(ISmax+2)%Ileft = Ipvn + 1
              Stack(ISmax+2)%Iright = Iright
              ISpos = ISpos + 1
              ISmax = ISmax + 2
           endif
        enddo

        ! deallocate all arrays
        deallocate(Stack)
        
    
    !##### SUBROUTINES AND FUNCTIONS ##########################################

    contains

            
        !##########################################################################
        ! FUNCTION ChoosePiv
        !
        ! Determines the pivotal element for the quicksort algorithm.
        !##########################################################################
        function ChoosePiv(XX, IIleft, IIright) result (IIpv)


            !##### INPUT/OUTPUT VARIABLES #############################################          

            ! the array to work on
            integer, intent(in) :: XX(:)

            ! the left and right definition of the sub-array
            integer, intent(in) :: IIleft, IIright
   
            ! the pivotal element that is returned
            integer :: IIpv
            

            !##### OTHER VARIABLES ####################################################
            
            integer :: XXcp(3)
            integer :: IIpt(3), IImd


            !##### ROUTINE CODE #######################################################
            
            IImd = Int((IIleft+IIright)/2)
            IIpv = IImd
            XXcp(1) = XX(IIleft)
            XXcp(2) = XX(IImd)
            XXcp(3) = XX(IIright)
            IIpt = (/1,2,3/)
            
            call InsrtLC(XXcp, 1, 3, IIpt)
            
            select case (IIpt(2))
            case (1)
                IIpv = IIleft
            case (2)
                IIpv = IImd
            case (3)
                IIpv = IIright
            End Select
   
        end function

            
        !##########################################################################
        ! SUBROUTINE InsrtLC
        !
        ! Perform an insertion sort of the list XX(:) between index 
        !     values IIl and IIr.
        !##########################################################################
        subroutine InsrtLC(XX, IIl, IIr, IIpt)
       
        
            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            integer, intent(inout) :: XX(:)

            ! the left and right definition of the sub-array
            integer, intent(in) :: IIl, IIr

            ! the permutations
            integer, intent(inout), optional :: IIpt(:)

            
            !##### OTHER VARIABLES ####################################################
            
            integer :: RRtmp
            integer :: II, JJ
            

            !##### ROUTINE CODE #######################################################
      
            do II = IIl+1, IIr
                RRtmp = XX(II)
                do JJ = II-1, 1, -1
                    if (RRtmp < XX(JJ)) then
                        XX(JJ+1) = XX(JJ)
                        if(present(IIpt))call Swap_IN(IIpt, JJ, JJ+1)
                    else
                        Exit
                    endif
                enddo
                XX(JJ+1) = RRtmp
            enddo
           
        end subroutine InsrtLC

        
        !##########################################################################
        ! FUNCTION Partition
        !
        ! Arranges the array X between the index values Ileft and Iright
        !     positioning elements smallers than X(Ipv) at the left and the others 
        !     at the right.
        !##########################################################################
        function Partition(X, Ileft, Iright, Ipv) result(Ipvfn)
        
            
            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            integer, intent(inout) :: X(:)

            ! the left and right definition of the sub-array and pivotal element
            integer, intent(in) :: Ileft, Iright, Ipv

            ! return value
            integer :: Ipvfn

            
            !##### OTHER VARIABLES ####################################################
            
            real*8 :: Rpv
            integer :: I
            

            !##### ROUTINE CODE #######################################################
        
            Rpv = X(Ipv)
            call Swap(X, Ipv, Iright)
            Ipvfn = Ileft
        
            do I = Ileft, Iright-1
                if (X(I) <= Rpv) then
                    call Swap(X, I, Ipvfn)
                    Ipvfn = Ipvfn + 1
                endif
            enddo
        
            call Swap(X, Ipvfn, Iright)
        
        end function Partition
        

        !##########################################################################
        ! SUBROUTINE Swap
        !
        ! Swaps elements i and j of array x
        !##########################################################################
        subroutine Swap(X, I, J)


            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            integer, intent(inout) :: X(:)

            ! the left and right definition of the sub-array and pivotal element
            integer, intent(in) :: I, J
            
            
            !##### OTHER VARIABLES ####################################################
            
            integer :: Xtmp
            

            !##### ROUTINE CODE #######################################################        
        
            Xtmp = X(I)
            X(I) = X(J)
            X(J) = Xtmp
        
        end subroutine Swap


        !##########################################################################
        ! SUBROUTINE Swap_IN
        !
        ! Swaps elements i and j of an integer array
        !##########################################################################
        subroutine Swap_IN(X, I, J)


            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            integer, intent(inout) :: X(:)

            ! the left and right definition of the sub-array and pivotal element
            integer, intent(in) :: I, J
            
            
            !##### OTHER VARIABLES ####################################################
            
            integer :: Xtmp
            

            !##### ROUTINE CODE #######################################################        
        
            Xtmp = X(I)
            X(I) = X(J)
            X(J) = Xtmp
        
        end subroutine Swap_IN
   
     end subroutine sort_i



    !##############################################################################
    ! SUBROUTINE sort_i2
    !
    ! Sorts an array of type integer in ascending order and returns new ordering.
    !
    ! PARTS OF THIS PROCEDURE WERE COPIED AND ADAPTED FROM:
    !     The Wikibook "Algorithm Implementation" available at
    !     https://en.wikibooks.org/wiki/Algorithm_Implementation/Sorting/Quicksort#FORTRAN_90.2F95
    !
    !     and follows closely the Qsort implementation found in 
    !     "A FORTRAN 90 Numerical Library" (AFNL), which is available at
    !     https://sourceforge.net/projects/afnl/
    !
    !     REFERENCE: Ramos, A. (2006). A FORTRAN 90 numerical library.
    !##############################################################################
    subroutine sort_i2(x, iorder)

        implicit none
        
        
        !##### INPUT/OUTPUT VARIABLES #############################################

        ! the array that should be sorted
        integer, intent(inout) :: x(:)

        ! an array that will contain the new sorting order
        integer, intent(out) :: iorder(size(x, 1))


        !##### OTHER VARIABLES ####################################################

        ! from which list size should insertion sort be used
        integer, parameter :: Isw = 10

        ! type for the left and right bounds
        type Limits
           integer :: Ileft, Iright
        end type Limits

        ! other variables        
        integer :: Ipvn, Ileft, Iright, ISpos, ISmax, ii
        type(Limits), allocatable :: Stack(:)
        

        !##### ROUTINE CODE #######################################################

        ! initialize the sorting order array
        iorder = (/(ii, ii = 1, size(x, 1))/)

        allocate(Stack(Size(X)*2)) 
    
        Stack(:)%Ileft = 0
        
        ! Iniitialize the stack
        Ispos = 1
        Ismax = 1
        Stack(ISpos)%Ileft  = 1
        Stack(ISpos)%Iright = size(X)
        
        do while (Stack(ISpos)%Ileft /= 0)
 
           Ileft = Stack(ISPos)%Ileft
           Iright = Stack(ISPos)%Iright

           ! choose between inseration and quick sort
           if (Iright-Ileft <= Isw) then
              call InsrtLC(X, iorder, Ileft, Iright)
              ISpos = ISPos + 1
           else
              Ipvn = ChoosePiv(X, Ileft, Iright)
              Ipvn = Partition(X, iorder, Ileft, Iright, Ipvn)
              
              Stack(ISmax+1)%Ileft = Ileft
              Stack(ISmax+1) %Iright = Ipvn-1
              Stack(ISmax+2)%Ileft = Ipvn + 1
              Stack(ISmax+2)%Iright = Iright
              ISpos = ISpos + 1
              ISmax = ISmax + 2
           endif
        enddo

        ! deallocate all arrays
        deallocate(Stack)
        
    
    !##### SUBROUTINES AND FUNCTIONS ##########################################

    contains

            
        !##########################################################################
        ! FUNCTION ChoosePiv
        !
        ! Determines the pivotal element for the quicksort algorithm.
        !##########################################################################
        function ChoosePiv(XX, IIleft, IIright) result (IIpv)


            !##### INPUT/OUTPUT VARIABLES #############################################          

            ! the array to work on
            integer, intent(in) :: XX(:)

            ! the left and right definition of the sub-array
            integer, intent(in) :: IIleft, IIright
   
            ! the pivotal element that is returned
            integer :: IIpv
            

            !##### OTHER VARIABLES ####################################################
            
            integer :: XXcp(3)
            integer :: IIpt(3), IImd


            !##### ROUTINE CODE #######################################################
            
            IImd = Int((IIleft+IIright)/2)
            IIpv = IImd
            XXcp(1) = XX(IIleft)
            XXcp(2) = XX(IImd)
            XXcp(3) = XX(IIright)
            IIpt = (/1,2,3/)
            
            call InsrtLC_help(XXcp, 1, 3, IIpt)
            
            select case (IIpt(2))
            case (1)
                IIpv = IIleft
            case (2)
                IIpv = IImd
            case (3)
                IIpv = IIright
            End Select
   
        end function

        !##########################################################################
        ! SUBROUTINE InsrtLC_help
        !
        ! Just a helping routine. Same as below but without iorder.
        !##########################################################################
        subroutine InsrtLC_help(XX, IIl, IIr, IIpt)
       
        
            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            integer, intent(inout) :: XX(:)

            ! the left and right definition of the sub-array
            integer, intent(in) :: IIl, IIr

            ! the permutations
            integer, intent(inout) :: IIpt(:)

            
            !##### OTHER VARIABLES ####################################################
            
            integer :: RRtmp
            integer :: II, JJ
            

            !##### ROUTINE CODE #######################################################
      
            do II = IIl+1, IIr
                RRtmp = XX(II)
                do JJ = II-1, 1, -1
                    if (RRtmp < XX(JJ)) then
                        XX(JJ+1) = XX(JJ)
                        call Swap_IN(IIpt, JJ, JJ+1)
                    else
                        Exit
                    endif
                enddo
                XX(JJ+1) = RRtmp
            enddo
           
        end subroutine InsrtLC_help

            
        !##########################################################################
        ! SUBROUTINE InsrtLC
        !
        ! Perform an insertion sort of the list XX(:) between index 
        !     values IIl and IIr.
        !##########################################################################
        subroutine InsrtLC(XX, iorder, IIl, IIr)
       
        
            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            integer, intent(inout) :: XX(:)

            ! an array that will contain the new sorting order
            integer, intent(inout) :: iorder(size(XX, 1))

            ! the left and right definition of the sub-array
            integer, intent(in) :: IIl, IIr

            
            !##### OTHER VARIABLES ####################################################
            
            integer :: RRtmp
            integer :: IItmp
            integer :: II, JJ
            

            !##### ROUTINE CODE #######################################################
      
            do II = IIl+1, IIr
                RRtmp = XX(II)
                IItmp = iorder(II)
                do JJ = II-1, 1, -1
                    if (RRtmp < XX(JJ)) then
                        XX(JJ+1) = XX(JJ)
                        iorder(JJ+1) = iorder(JJ)
                    else
                        Exit
                    endif
                enddo
                XX(JJ+1) = RRtmp
                iorder(JJ+1) = IItmp
            enddo
           
        end subroutine InsrtLC

        
        !##########################################################################
        ! FUNCTION Partition
        !
        ! Arranges the array X between the index values Ileft and Iright
        !     positioning elements smallers than X(Ipv) at the left and the others 
        !     at the right.
        !##########################################################################
        function Partition(X, iorder, Ileft, Iright, Ipv) result(Ipvfn)
        
            
            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            integer, intent(inout) :: X(:)

            ! an array that will contain the new sorting order
            integer, intent(inout) :: iorder(size(X, 1))

            ! the left and right definition of the sub-array and pivotal element
            integer, intent(in) :: Ileft, Iright, Ipv

            ! return value
            integer :: Ipvfn

            
            !##### OTHER VARIABLES ####################################################
            
            integer :: Rpv
            integer :: I
            

            !##### ROUTINE CODE #######################################################
        
            Rpv = X(Ipv)
            call Swap(X, Ipv, Iright)
            call Swap_IN(iorder, Ipv, Iright)
            Ipvfn = Ileft
        
            do I = Ileft, Iright-1
                if (X(I) <= Rpv) then
                    call Swap(X, I, Ipvfn)
                    call Swap_IN(iorder, I, Ipvfn)
                    Ipvfn = Ipvfn + 1
                endif
            enddo
        
            call Swap(X, Ipvfn, Iright)
            call Swap_IN(iorder, Ipvfn, Iright)
        
        end function Partition
        

        !##########################################################################
        ! SUBROUTINE Swap
        !
        ! Swaps elements i and j of array x
        !##########################################################################
        subroutine Swap(X, I, J)


            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            integer, intent(inout) :: X(:)

            ! the left and right definition of the sub-array and pivotal element
            integer, intent(in) :: I, J
            
            
            !##### OTHER VARIABLES ####################################################
            
            integer :: Xtmp
            

            !##### ROUTINE CODE #######################################################        
        
            Xtmp = X(I)
            X(I) = X(J)
            X(J) = Xtmp
        
        end subroutine Swap


        !##########################################################################
        ! SUBROUTINE Swap_IN
        !
        ! Swaps elements i and j of an integer array
        !##########################################################################
        subroutine Swap_IN(X, I, J)


            !##### INPUT/OUTPUT VARIABLES #############################################

            ! the array to work on
            integer, intent(inout) :: X(:)

            ! the left and right definition of the sub-array and pivotal element
            integer, intent(in) :: I, J
            
            
            !##### OTHER VARIABLES ####################################################
            
            integer :: Xtmp
            

            !##### ROUTINE CODE #######################################################        
        
            Xtmp = X(I)
            X(I) = X(J)
            X(J) = Xtmp
        
        end subroutine Swap_IN
   
    end subroutine sort_i2

end module
