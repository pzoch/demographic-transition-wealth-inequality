! module that contains useful functions and subroutines from various sources

module NRfunctionsDP
  use nrtypeDP
  implicit none

contains


  function r8_normal_01_cdf_inverse ( p )

    !*****************************************************************************80
    !
    !! R8_NORMAL_01_CDF_INVERSE inverts the standard normal CDF.
    !
    !  Discussion:
    !
    !    The result is accurate to about 1 part in 10**16.
    !
    !  Licensing:
    !
    !    This code is distributed under the GNU LGPL license.
    !
    !  Modified:
    !
    !    27 December 2004
    !
    !  Author:
    !
    !    Original FORTRAN77 version by Michael Wichura.
    !    FORTRAN90 version by John Burkardt.
    !
    !  Reference:
    !
    !    Michael Wichura,
    !    The Percentage Points of the Normal Distribution,
    !    Algorithm AS 241,
    !    Applied Statistics,
    !    Volume 37, Number 3, pages 477-484, 1988.
    !
    !  Parameters:
    !
    !    Input, real ( kind = 8 ) P, the value of the cumulative probability
    !    densitity function.  0 < P < 1.  If P is outside this range,
    !    an "infinite" value will be returned.
    !
    !    Output, real ( kind = 8 ) D_NORMAL_01_CDF_INVERSE, the normal deviate
    !    value with the property that the probability of a standard normal
    !    deviate being less than or equal to the value is P.
    !
    implicit none

    real ( kind = 8 ), parameter, dimension ( 8 ) :: a = (/ &
    3.3871328727963666080D+00, &
    1.3314166789178437745D+02, &
    1.9715909503065514427D+03, &
    1.3731693765509461125D+04, &
    4.5921953931549871457D+04, &
    6.7265770927008700853D+04, &
    3.3430575583588128105D+04, &
    2.5090809287301226727D+03 /)
    real ( kind = 8 ), parameter, dimension ( 8 ) :: b = (/ &
    1.0D+00, &
    4.2313330701600911252D+01, &
    6.8718700749205790830D+02, &
    5.3941960214247511077D+03, &
    2.1213794301586595867D+04, &
    3.9307895800092710610D+04, &
    2.8729085735721942674D+04, &
    5.2264952788528545610D+03 /)
    real   ( kind = 8 ), parameter, dimension ( 8 ) :: c = (/ &
    1.42343711074968357734D+00, &
    4.63033784615654529590D+00, &
    5.76949722146069140550D+00, &
    3.64784832476320460504D+00, &
    1.27045825245236838258D+00, &
    2.41780725177450611770D-01, &
    2.27238449892691845833D-02, &
    7.74545014278341407640D-04 /)
    real ( kind = 8 ), parameter :: const1 = 0.180625D+00
    real ( kind = 8 ), parameter :: const2 = 1.6D+00
    real ( kind = 8 ), parameter, dimension ( 8 ) :: d = (/ &
    1.0D+00, &
    2.05319162663775882187D+00, &
    1.67638483018380384940D+00, &
    6.89767334985100004550D-01, &
    1.48103976427480074590D-01, &
    1.51986665636164571966D-02, &
    5.47593808499534494600D-04, &
    1.05075007164441684324D-09 /)
    real ( kind = 8 ), parameter, dimension ( 8 ) :: e = (/ &
    6.65790464350110377720D+00, &
    5.46378491116411436990D+00, &
    1.78482653991729133580D+00, &
    2.96560571828504891230D-01, &
    2.65321895265761230930D-02, &
    1.24266094738807843860D-03, &
    2.71155556874348757815D-05, &
    2.01033439929228813265D-07 /)
    real ( kind = 8 ), parameter, dimension ( 8 ) :: f = (/ &
    1.0D+00, &
    5.99832206555887937690D-01, &
    1.36929880922735805310D-01, &
    1.48753612908506148525D-02, &
    7.86869131145613259100D-04, &
    1.84631831751005468180D-05, &
    1.42151175831644588870D-07, &
    2.04426310338993978564D-15 /)
    real ( kind = 8 ) p
    real ( kind = 8 ) q
    real ( kind = 8 ) r
    real ( kind = 8 ) r8_normal_01_cdf_inverse
    !  real ( kind = 8 ) r8poly_value
    real ( kind = 8 ), parameter :: split1 = 0.425D+00
    real ( kind = 8 ), parameter :: split2 = 5.0D+00

    if ( p <= 0.0D+00 ) then
      r8_normal_01_cdf_inverse = - huge ( p )
      return
    end if

    if ( 1.0D+00 <= p ) then
      r8_normal_01_cdf_inverse = huge ( p )
      return
    end if

    q = p - 0.5D+00

    if ( abs ( q ) <= split1 ) then

      r = const1 - q * q
      r8_normal_01_cdf_inverse = q * r8poly_value ( 8, a, r ) &
      / r8poly_value ( 8, b, r )

    else

      if ( q < 0.0D+00 ) then
        r = p
      else
        r = 1.0D+00 - p
      end if

      if ( r <= 0.0D+00 ) then
        r8_normal_01_cdf_inverse = - 1.0D+00
        stop
      end if

      r = sqrt ( -log ( r ) )

      if ( r <= split2 ) then

        r = r - const2
        r8_normal_01_cdf_inverse = r8poly_value ( 8, c, r ) &
        / r8poly_value ( 8, d, r )

      else

        r = r - split2
        r8_normal_01_cdf_inverse = r8poly_value ( 8, e, r ) &
        / r8poly_value ( 8, f, r )

      end if

      if ( q < 0.0D+00 ) then
        r8_normal_01_cdf_inverse = - r8_normal_01_cdf_inverse
      end if

    end if

    return
  end function r8_normal_01_cdf_inverse

  function r8poly_value ( n, a, x )

    !*****************************************************************************80
    !
    !! R8POLY_VALUE evaluates an R8POLY
    !
    !  Discussion:
    !
    !    For sanity's sake, the value of N indicates the NUMBER of
    !    coefficients, or more precisely, the ORDER of the polynomial,
    !    rather than the DEGREE of the polynomial.  The two quantities
    !    differ by 1, but cause a great deal of confusion.
    !
    !    Given N and A, the form of the polynomial is:
    !
    !      p(x) = a(1) + a(2) * x + ... + a(n-1) * x^(n-2) + a(n) * x^(n-1)
    !
    !  Licensing:
    !
    !    This code is distributed under the GNU LGPL license.
    !
    !  Modified:
    !
    !    13 August 2004
    !
    !  Author:
    !
    !    John Burkardt
    !
    !  Parameters:
    !
    !    Input, integer ( kind = 4 ) N, the order of the polynomial.
    !
    !    Input, real ( kind = 8 ) A(N), the coefficients of the polynomial.
    !    A(1) is the constant term.
    !
    !    Input, real ( kind = 8 ) X, the point at which the polynomial is
    !    to be evaluated.
    !
    !    Output, real ( kind = 8 ) R8POLY_VALUE, the value of the polynomial at X.
    !
    implicit none

    integer ( kind = 4 ) n

    real ( kind = 8 ) a(n)
    integer ( kind = 4 ) i
    real ( kind = 8 ) r8poly_value
    real ( kind = 8 ) x

    r8poly_value = 0.0D+00
    do i = n, 1, -1
      r8poly_value = r8poly_value * x + a(i)
    end do

    return
  end function r8poly_value





  SUBROUTINE sort2(arr,slave)
    USE nrtypeDP
    USE nrutilDP, ONLY : assert_eq
    IMPLICIT NONE
    real(DPP), DIMENSION(:), INTENT(INOUT) :: arr,slave
    INTEGER(I4B) :: ndum
    INTEGER(I4B), DIMENSION(size(arr)) :: index
    ndum=assert_eq(size(arr),size(slave),'sort2')
    call indexx(arr,index)
    arr=arr(index)
    slave=slave(index)
  END SUBROUTINE sort2

  SUBROUTINE sort3(arr,slave1,slave2)
    USE nrtypeDP
    USE nrutilDP, ONLY : assert_eq
    IMPLICIT NONE
    real(DPP), DIMENSION(:), INTENT(INOUT) :: arr,slave1,slave2
    INTEGER(I4B) :: ndum
    INTEGER(I4B), DIMENSION(size(arr)) :: index
    ndum=assert_eq(size(arr),size(slave1),size(slave2),'sort3')
    call indexx(arr,index)
    arr=arr(index)
    slave1=slave1(index)
    slave2=slave2(index)
  END SUBROUTINE sort3

  SUBROUTINE indexx(arr,index)
    USE nrtypeDP
    USE nrutilDP, ONLY : arth,assert_eq,nrerror,swap
    IMPLICIT NONE
    real(DPP), DIMENSION(:), INTENT(IN) :: arr
    INTEGER(I4B), DIMENSION(:), INTENT(OUT) :: index
    INTEGER(I4B), PARAMETER :: NN=15, NSTACK=50
    real(DPP) :: a
    INTEGER(I4B) :: n,k,i,j,indext,jstack,l,r
    INTEGER(I4B), DIMENSION(NSTACK) :: istack
    n=assert_eq(size(index),size(arr),'indexx')
    index=arth(1,1,n)
    jstack=0
    l=1
    r=n
    do
      if (r-l < NN) then
        do j=l+1,r
          indext=index(j)
          a=arr(indext)
          do i=j-1,l,-1
            if (arr(index(i)) <= a) exit
            index(i+1)=index(i)
          end do
          index(i+1)=indext
        end do
        if (jstack == 0) RETURN
        r=istack(jstack)
        l=istack(jstack-1)
        jstack=jstack-2
      else
        k=(l+r)/2
        call swap(index(k),index(l+1))
        call icomp_xchg(index(l),index(r))
        call icomp_xchg(index(l+1),index(r))
        call icomp_xchg(index(l),index(l+1))
        i=l+1
        j=r
        indext=index(l+1)
        a=arr(indext)
        do
          do
            i=i+1
            if (arr(index(i)) >= a) exit
          end do
          do
            j=j-1
            if (arr(index(j)) <= a) exit
          end do
          if (j < i) exit
          call swap(index(i),index(j))
        end do
        index(l+1)=index(j)
        index(j)=indext
        jstack=jstack+2
        if (jstack > NSTACK) call nrerror('indexx: NSTACK too small')
        if (r-i+1 >= j-l) then
          istack(jstack)=r
          istack(jstack-1)=i
          r=j-1
        else
          istack(jstack)=j-1
          istack(jstack-1)=l
          l=i
        end if
      end if
    end do
  CONTAINS
    !BL
    SUBROUTINE icomp_xchg(i,j)
      INTEGER(I4B), INTENT(INOUT) :: i,j
      INTEGER(I4B) :: swp
      if (arr(j) < arr(i)) then
        swp=i
        i=j
        j=swp
      end if
    END SUBROUTINE icomp_xchg
  END SUBROUTINE indexx

  SUBROUTINE indexx_i4b(iarr,index)
    USE nrtypeDP
    USE nrutilDP, ONLY : arth,assert_eq,nrerror,swap
    IMPLICIT NONE
    INTEGER(I4B), DIMENSION(:), INTENT(IN) :: iarr
    INTEGER(I4B), DIMENSION(:), INTENT(OUT) :: index
    INTEGER(I4B), PARAMETER :: NN=15, NSTACK=50
    INTEGER(I4B) :: a
    INTEGER(I4B) :: n,k,i,j,indext,jstack,l,r
    INTEGER(I4B), DIMENSION(NSTACK) :: istack
    n=assert_eq(size(index),size(iarr),'indexx')
    index=arth(1,1,n)
    jstack=0
    l=1
    r=n
    do
      if (r-l < NN) then
        do j=l+1,r
          indext=index(j)
          a=iarr(indext)
          do i=j-1,l,-1
            if (iarr(index(i)) <= a) exit
            index(i+1)=index(i)
          end do
          index(i+1)=indext
        end do
        if (jstack == 0) RETURN
        r=istack(jstack)
        l=istack(jstack-1)
        jstack=jstack-2
      else
        k=(l+r)/2
        call swap(index(k),index(l+1))
        call icomp_xchg(index(l),index(r))
        call icomp_xchg(index(l+1),index(r))
        call icomp_xchg(index(l),index(l+1))
        i=l+1
        j=r
        indext=index(l+1)
        a=iarr(indext)
        do
          do
            i=i+1
            if (iarr(index(i)) >= a) exit
          end do
          do
            j=j-1
            if (iarr(index(j)) <= a) exit
          end do
          if (j < i) exit
          call swap(index(i),index(j))
        end do
        index(l+1)=index(j)
        index(j)=indext
        jstack=jstack+2
        if (jstack > NSTACK) call nrerror('indexx: NSTACK too small')
        if (r-i+1 >= j-l) then
          istack(jstack)=r
          istack(jstack-1)=i
          r=j-1
        else
          istack(jstack)=j-1
          istack(jstack-1)=l
          l=i
        end if
      end if
    end do
  CONTAINS
    !BL
    SUBROUTINE icomp_xchg(i,j)
      INTEGER(I4B), INTENT(INOUT) :: i,j
      INTEGER(I4B) :: swp
      if (iarr(j) < iarr(i)) then
        swp=i
        i=j
        j=swp
      end if
    END SUBROUTINE icomp_xchg
  END SUBROUTINE indexx_i4b

  SUBROUTINE sort(arr)
    USE nrutilDP, ONLY : swap,nrerror
    IMPLICIT NONE
    real(DPP), DIMENSION(:), INTENT(INOUT) :: arr
    INTEGER(I4B), PARAMETER :: NN=15, NSTACK=50
    real(DPP) :: a
    INTEGER(I4B) :: n,k,i,j,jstack,l,r
    INTEGER(I4B), DIMENSION(NSTACK) :: istack
    n=size(arr)
    jstack=0
    l=1
    r=n
    do
      if (r-l < NN) then
        do j=l+1,r
          a=arr(j)
          do i=j-1,l,-1
            if (arr(i) <= a) exit
            arr(i+1)=arr(i)
          end do
          arr(i+1)=a
        end do
        if (jstack == 0) RETURN
        r=istack(jstack)
        l=istack(jstack-1)
        jstack=jstack-2
      else
        k=(l+r)/2
        call swap(arr(k),arr(l+1))
        call swap(arr(l),arr(r),arr(l)>arr(r))
        call swap(arr(l+1),arr(r),arr(l+1)>arr(r))
        call swap(arr(l),arr(l+1),arr(l)>arr(l+1))
        i=l+1
        j=r
        a=arr(l+1)
        do
          do
            i=i+1
            if (arr(i) >= a) exit
          end do
          do
            j=j-1
            if (arr(j) <= a) exit
          end do
          if (j < i) exit
          call swap(arr(i),arr(j))
        end do
        arr(l+1)=arr(j)
        arr(j)=a
        jstack=jstack+2
        if (jstack > NSTACK) call nrerror('sort: NSTACK too small')
        if (r-i+1 >= j-l) then
          istack(jstack)=r
          istack(jstack-1)=i
          r=j-1
        else
          istack(jstack)=j-1
          istack(jstack-1)=l
          l=i
        end if
      end if
    end do
  END SUBROUTINE sort


  SUBROUTINE select_heap(arr,heap)
    USE nrutilDP, ONLY : nrerror,swap
    IMPLICIT NONE
    real(DPP), DIMENSION(:), INTENT(IN) :: arr
    real(DPP), DIMENSION(:), INTENT(OUT) :: heap
    INTEGER(I4B) :: i,j,k,m,n
    m=size(heap)
    n=size(arr)
    if (m > n/2 .or. m < 1) call nrerror('probable misuse of select_heap')
    heap=arr(1:m)
    call sort(heap)
    do i=m+1,n
      if (arr(i) > heap(1)) then
        heap(1)=arr(i)
        j=1
        do
          k=2*j
          if (k > m) exit
          if (k /= m) then
            if (heap(k) > heap(k+1)) k=k+1
          end if
          if (heap(j) <= heap(k)) exit
          call swap(heap(k),heap(j))
          j=k
        end do
      end if
    end do
  END SUBROUTINE select_heap

  SUBROUTINE polint(xa,ya,x,y,dy)
    USE nrtypeDP; USE nrutilDP, ONLY : assert_eq,iminloc,nrerror
    IMPLICIT NONE
    real(DPP), DIMENSION(:), INTENT(IN) :: xa,ya
    real(DPP), INTENT(IN) :: x
    real(DPP), INTENT(OUT) :: y,dy
    INTEGER(I4B) :: m,n,ns
    real(DPP), DIMENSION(size(xa)) :: c,d,den,ho
    n=assert_eq(size(xa),size(ya),'polint')
    c=ya
    d=ya
    ho=xa-x
    ns=iminloc(abs(x-xa))
    y=ya(ns)
    ns=ns-1
    do m=1,n-1
      den(1:n-m)=ho(1:n-m)-ho(1+m:n)
      if (any(den(1:n-m) == 0.0)) &
      call nrerror('polint: calculation failure')
      den(1:n-m)=(c(2:n-m+1)-d(1:n-m))/den(1:n-m)
      d(1:n-m)=ho(1+m:n)*den(1:n-m)
      c(1:n-m)=ho(1:n-m)*den(1:n-m)
      if (2*ns < n-m) then
        dy=c(ns+1)
      else
        dy=d(ns)
        ns=ns-1
      end if
      y=y+dy
    end do
  END SUBROUTINE polint

  SUBROUTINE hunt(xx,x,jlo)
    USE nrtypeDP
    IMPLICIT NONE
    INTEGER(I4B), INTENT(INOUT) :: jlo
    real(DPP), INTENT(IN) :: x
    real(DPP), DIMENSION(:), INTENT(IN) :: xx
    INTEGER(I4B) :: n,inc,jhi,jm
    LOGICAL :: ascnd
    n=size(xx)
    ascnd = (xx(n) >= xx(1))
    if (jlo <= 0 .or. jlo > n) then
      jlo=0
      jhi=n+1
    else
      inc=1
      if (x >= xx(jlo) .eqv. ascnd) then
        do
          jhi=jlo+inc
          if (jhi > n) then
            jhi=n+1
            exit
          else
            if (x < xx(jhi) .eqv. ascnd) exit
            jlo=jhi
            inc=inc+inc
          end if
        end do
      else
        jhi=jlo
        do
          jlo=jhi-inc
          if (jlo < 1) then
            jlo=0
            exit
          else
            if (x >= xx(jlo) .eqv. ascnd) exit
            jhi=jlo
            inc=inc+inc
          end if
        end do
      end if
    end if
    do
      if (jhi-jlo <= 1) then
        if (x == xx(n)) jlo=n-1
        if (x == xx(1)) jlo=1
        exit
      else
        jm=(jhi+jlo)/2
        if (x >= xx(jm) .eqv. ascnd) then
          jlo=jm
        else
          jhi=jm
        end if
      end if
    end do
  END SUBROUTINE hunt


  SUBROUTINE spline(x,y,yp1,ypn,y2)
    USE nrtypeDP; USE nrutilDP, ONLY : assert_eq
    !USE nr, ONLY : tridag
    IMPLICIT NONE
    real(DPP), DIMENSION(:), INTENT(IN) :: x,y
    real(DPP), INTENT(IN) :: yp1,ypn
    real(DPP), DIMENSION(:), INTENT(OUT) :: y2
    INTEGER(I4B) :: n
    real(DPP), DIMENSION(size(x)) :: a,b,c,r
    n=assert_eq(size(x),size(y),size(y2),'spline')
    c(1:n-1)=x(2:n)-x(1:n-1)
    r(1:n-1)=6.0*((y(2:n)-y(1:n-1))/c(1:n-1))
    r(2:n-1)=r(2:n-1)-r(1:n-2)
    a(2:n-1)=c(1:n-2)
    b(2:n-1)=2.0*(c(2:n-1)+a(2:n-1))
    b(1)=1.0
    b(n)=1.0
    if (yp1 > 0.99e30) then
      r(1)=0.0
      c(1)=0.0
    else
      r(1)=(3.0/(x(2)-x(1)))*((y(2)-y(1))/(x(2)-x(1))-yp1)
      c(1)=0.5
    end if
    if (ypn > 0.99e30) then
      r(n)=0.0
      a(n)=0.0
    else
      r(n)=(-3.0/(x(n)-x(n-1)))*((y(n)-y(n-1))/(x(n)-x(n-1))-ypn)
      a(n)=0.5
    end if

    call tridag_par(a(2:n),b(1:n),c(1:n-1),r(1:n),y2(1:n))
  END SUBROUTINE spline

  SUBROUTINE splineTEST(x,y,yp1,ypn,y2)
    USE nrtypeDP; USE nrutilDP, ONLY : assert_eq
    !USE nr, ONLY : tridag
    IMPLICIT NONE
    real(DPP), DIMENSION(:), INTENT(IN) :: x,y
    real(DPP), INTENT(IN) :: yp1,ypn
    real(DPP), DIMENSION(:), INTENT(OUT) :: y2
    INTEGER(I4B) :: n
    real(DPP), DIMENSION(size(x)) :: a,b,c,r
    n=assert_eq(size(x),size(y),size(y2),'spline')
    c(1:n-1)=x(2:n)-x(1:n-1)
    r(1:n-1)=6.0*((y(2:n)-y(1:n-1))/c(1:n-1))
    r(2:n-1)=r(2:n-1)-r(1:n-2)
    a(2:n-1)=c(1:n-2)
    b(2:n-1)=2.0*(c(2:n-1)+a(2:n-1))
    b(1)=1.0
    b(n)=1.0
    if (yp1 > 0.99e30) then
      r(1)=0.0
      c(1)=0.0
    else
      r(1)=(3.0/(x(2)-x(1)))*((y(2)-y(1))/(x(2)-x(1))-yp1)
      c(1)=0.5
    end if
    if (ypn > 0.99e30) then
      r(n)=0.0
      a(n)=0.0
    else
      r(n)=(-3.0/(x(n)-x(n-1)))*((y(n)-y(n-1))/(x(n)-x(n-1))-ypn)
      a(n)=0.5
    end if
    print *,'sizes',size(a(2:n)),size(b(1:n)),size(c(1:n-1)),size(r(1:n)),size(y2(1:n))
    call tridag_par(a(2:n),b(1:n),c(1:n-1),r(1:n),y2(1:n))
  END SUBROUTINE splineTEST

  FUNCTION splint(xa,ya,y2a,x)
    USE nrtypeDP; USE nrutilDP, ONLY : assert_eq,nrerror
    !USE nr, ONLY: locate
    IMPLICIT NONE
    real(DPP), DIMENSION(:), INTENT(IN) :: xa,ya,y2a
    real(DPP), INTENT(IN) :: x
    real(DPP) :: splint
    INTEGER(I4B) :: khi,klo,n
    real(DPP) :: a,b,h
    n=assert_eq(size(xa),size(ya),size(y2a),'splint')
    klo=max(min(locate(xa,x),n-1),1)
    khi=klo+1
    h=xa(khi)-xa(klo)
    if (h == 0.0) call nrerror('bad xa input in splint')
    a=(xa(khi)-x)/h
    b=(x-xa(klo))/h
    splint=a*ya(klo)+b*ya(khi)+((a**3-a)*y2a(klo)+(b**3-b)*y2a(khi))*(h**2)/6.0
  END FUNCTION splint

  FUNCTION splint1(xa,ya,y2a,x)
    USE nrtypeDP; USE nrutilDP, ONLY : assert_eq,nrerror
    ! yields first derivative
    !USE nr, ONLY: locate
    IMPLICIT NONE
    real(DPP), DIMENSION(:), INTENT(IN) :: xa,ya,y2a
    real(DPP), INTENT(IN) :: x
    real(DPP) :: splint1
    INTEGER(I4B) :: khi,klo,n
    real(DPP) :: a,b,h
    n=assert_eq(size(xa),size(ya),size(y2a),'splint')
    klo=max(min(locate(xa,x),n-1),1)
    khi=klo+1
    h=xa(khi)-xa(klo)
    if (h == 0.0) call nrerror('bad xa input in splint1')
    a=(xa(khi)-x)/h
    b=(x-xa(klo))/h
    splint1=h*((b**2*y2a(khi)-a**2*y2a(klo))/2+(y2a(klo)-y2a(khi))/6)+(ya(khi)-ya(klo))/h
  END FUNCTION splint1

  FUNCTION splint2(xa,y2a,x)
    USE nrtypeDP; USE nrutilDP, ONLY : assert_eq,nrerror
    ! yields second derivative
    !USE nr, ONLY: locate
    IMPLICIT NONE
    real(DPP), DIMENSION(:), INTENT(IN) :: xa,y2a
    real(DPP), INTENT(IN) :: x
    real(DPP) :: splint2
    INTEGER(I4B) :: khi,klo,n
    real(DPP) :: a,b,h
    n=assert_eq(size(xa),size(y2a),'splint')
    klo=max(min(locate(xa,x),n-1),1)
    khi=klo+1
    h=xa(khi)-xa(klo)
    if (h == 0.0) call nrerror('bad xa input in splint2')
    a=(xa(khi)-x)/h
    b=(x-xa(klo))/h
    splint2=a*y2a(klo)+b*y2a(khi)
  END FUNCTION splint2

  FUNCTION locate(xx,x)
    USE nrtypeDP
    IMPLICIT NONE
    real(DPP), DIMENSION(:), INTENT(IN) :: xx
    real(DPP), INTENT(IN) :: x
    INTEGER(I4B) :: locate
    INTEGER(I4B) :: n,jl,jm,ju
    LOGICAL :: ascnd
    n=size(xx)
    ascnd = (xx(n) >= xx(1))
    jl=0
    ju=n+1
    do
      if (ju-jl <= 1) exit
      jm=(ju+jl)/2
      if (ascnd .eqv. (x >= xx(jm))) then
        jl=jm
      else
        ju=jm
      end if
    end do
    if (x == xx(1)) then
      locate=1
    else if (x == xx(n)) then
      locate=n-1
    else
      locate=jl
    end if
  END FUNCTION locate

  SUBROUTINE tridag_ser(a,b,c,r,u)
    USE nrtypeDP; USE nrutilDP, ONLY : assert_eq,nrerror
    IMPLICIT NONE
    real(DPP), DIMENSION(:), INTENT(IN) :: a,b,c,r
    real(DPP), DIMENSION(:), INTENT(OUT) :: u
    real(DPP), DIMENSION(size(b)) :: gam
    INTEGER(I4B) :: n,j
    real(DPP) :: bet
    n=assert_eq((/size(a)+1,size(b),size(c)+1,size(r),size(u)/),'tridag_ser')
    bet=b(1)
    if (bet == 0.0) call nrerror('tridag_ser: Error at code stage 1')
    u(1)=r(1)/bet
    do j=2,n
      gam(j)=c(j-1)/bet
      bet=b(j)-a(j-1)*gam(j)
      if (bet == 0.0) &
      call nrerror('tridag_ser: Error at code stage 2')
      u(j)=(r(j)-a(j-1)*u(j-1))/bet
    end do
    do j=n-1,1,-1
      u(j)=u(j)-gam(j+1)*u(j+1)
    end do
  END SUBROUTINE tridag_ser

  RECURSIVE SUBROUTINE tridag_par(a,b,c,r,u)
    USE nrtypeDP; USE nrutilDP, ONLY : assert_eq,nrerror
    !USE nr, ONLY : tridag_ser
    IMPLICIT NONE
    real(DPP), DIMENSION(:), INTENT(IN) :: a,b,c,r
    real(DPP), DIMENSION(:), INTENT(OUT) :: u
    INTEGER(I4B), PARAMETER :: NPAR_TRIDAG=4
    INTEGER(I4B) :: n,n2,nm,nx
    real(DPP), DIMENSION(size(b)/2) :: y,q,piva
    real(DPP), DIMENSION(size(b)/2-1) :: x,z
    real(DPP), DIMENSION(size(a)/2) :: pivc
    n=assert_eq((/size(a)+1,size(b),size(c)+1,size(r),size(u)/),'tridag_par')
    if (n < NPAR_TRIDAG) then
      call tridag_ser(a,b,c,r,u)
    else
      if (maxval(abs(b(1:n))) == 0.0) &
      call nrerror('tridag_par: possible singular matrix')
      n2=size(y)
      nm=size(pivc)
      nx=size(x)
      piva = a(1:n-1:2)/b(1:n-1:2)
      pivc = c(2:n-1:2)/b(3:n:2)
      y(1:nm) = b(2:n-1:2)-piva(1:nm)*c(1:n-2:2)-pivc*a(2:n-1:2)
      q(1:nm) = r(2:n-1:2)-piva(1:nm)*r(1:n-2:2)-pivc*r(3:n:2)
      if (nm < n2) then
        y(n2) = b(n)-piva(n2)*c(n-1)
        q(n2) = r(n)-piva(n2)*r(n-1)
      end if
      x = -piva(2:n2)*a(2:n-2:2)
      z = -pivc(1:nx)*c(3:n-1:2)
      call tridag_par(x,y,z,q,u(2:n:2))
      u(1) = (r(1)-c(1)*u(2))/b(1)
      u(3:n-1:2) = (r(3:n-1:2)-a(2:n-2:2)*u(2:n-2:2) &
      -c(3:n-1:2)*u(4:n:2))/b(3:n-1:2)
      if (nm == n2) u(n)=(r(n)-a(n-1)*u(n-1))/b(n)
    end if
  END SUBROUTINE tridag_par

  FUNCTION brent(ax,bx,cx,func,tol,xmin)
    USE nrtypeDP; USE nrutilDP, ONLY : nrerror
    IMPLICIT NONE
    real(DPP), INTENT(IN) :: ax,bx,cx,tol
    real(DPP), INTENT(OUT) :: xmin
    real(DPP) :: brent
    INTERFACE
      FUNCTION func(x)
        USE nrtypeDP
        IMPLICIT NONE
        real(DPP), INTENT(IN) :: x
        real(DPP) :: func
      END FUNCTION func
    END INTERFACE
    INTEGER(I4B), PARAMETER :: ITMAX=1000
    real(DPP), PARAMETER :: CGOLD=0.3819660,ZEPS=1.0e-3*epsilon(ax)
    INTEGER(I4B) :: iter
    real(DPP) :: a,b,d,e,etemp,fu,fv,fw,fx,p,q,r,tol1,tol2,u,v,w,x,xm
    a=min(ax,cx)
    b=max(ax,cx)
    v=bx
    w=v
    x=v
    e=0.0
    fx=func(x)
    fv=fx
    fw=fx
    do iter=1,ITMAX
      xm=0.5*(a+b)
      tol1=tol*abs(x)+ZEPS
      tol2=2.0*tol1
      if (abs(x-xm) <= (tol2-0.5*(b-a))) then
        xmin=x
        brent=fx
        RETURN
      end if
      if (abs(e) > tol1) then
        r=(x-w)*(fx-fv)
        q=(x-v)*(fx-fw)
        p=(x-v)*q-(x-w)*r
        q=2.0*(q-r)
        if (q > 0.0) p=-p
        q=abs(q)
        etemp=e
        e=d
        if (abs(p) >= abs(0.5*q*etemp) .or. &
        p <= q*(a-x) .or. p >= q*(b-x)) then
        e=merge(a-x,b-x, x >= xm )
        d=CGOLD*e
      else
        d=p/q
        u=x+d
        if (u-a < tol2 .or. b-u < tol2) d=sign(tol1,xm-x)
      end if
    else
      e=merge(a-x,b-x, x >= xm )
      d=CGOLD*e
    end if
    u=merge(x+d,x+sign(tol1,d), abs(d) >= tol1 )
    fu=func(u)
    if (fu <= fx) then
      if (u >= x) then
        a=x
      else
        b=x
      end if
      call shft(v,w,x,u)
      call shft(fv,fw,fx,fu)
    else
      if (u < x) then
        a=u
      else
        b=u
      end if
      if (fu <= fw .or. w == x) then
        v=w
        fv=fw
        w=u
        fw=fu
      else if (fu <= fv .or. v == x .or. v == w) then
        v=u
        fv=fu
      end if
    end if
  end do
  call nrerror('brent: exceed maximum iterations')
END FUNCTION brent

SUBROUTINE zbrac(func,x1,x2,succes)
	USE nrtypeDP; USE nrutilDP, ONLY : nrerror
	IMPLICIT NONE
	REAL(DPP), INTENT(INOUT) :: x1,x2
	LOGICAL(LGT), INTENT(OUT) :: succes
	INTERFACE
		FUNCTION func(x)
		USE nrtypeDP
		IMPLICIT NONE
		REAL(DPP), INTENT(IN) :: x
		REAL(DPP) :: func
		END FUNCTION func
	END INTERFACE
	INTEGER(I4B), PARAMETER :: NTRY=50
	REAL(DPP), PARAMETER :: FACTOR=1.6_dpp
	INTEGER(I4B) :: j
	REAL(DPP) :: f1,f2
	if (x1 == x2) call nrerror('zbrac: you have to guess an initial range')
	f1=func(x1)
	f2=func(x2)
	succes=.true.
	do j=1,NTRY
		if ((f1 > 0.0 .and. f2 < 0.0) .or. &
			(f1 < 0.0 .and. f2 > 0.0)) RETURN
		if (abs(f1) < abs(f2)) then
			x1=x1+FACTOR*(x1-x2)
			f1=func(x1)
		else
			x2=x2+FACTOR*(x2-x1)
			f2=func(x2)
		end if
	end do
	succes=.false.
	END SUBROUTINE zbrac

SUBROUTINE mnbrak(ax,bx,cx,fa,fb,fc,func)
  USE nrtypeDP
  USE nrutilDP, ONLY : swap
  IMPLICIT NONE
  real(DPP), INTENT(INOUT) :: ax,bx
  real(DPP), INTENT(OUT) :: cx,fa,fb,fc
  INTERFACE
    FUNCTION func(x)
      USE nrtypeDP
      IMPLICIT NONE
      real(DPP), INTENT(IN) :: x
      real(DPP) :: func
    END FUNCTION func
  END INTERFACE
  real(DPP), PARAMETER :: GOLD=1.618034,GLIMIT=100.0,TINY=1.0e-20
  real(DPP) :: fu,q,r,u,ulim
  fa=func(ax)
  fb=func(bx)
  if (fb > fa) then
    call swap(ax,bx)
    call swap(fa,fb)
  end if
  cx=bx+GOLD*(bx-ax)
  fc=func(cx)
  do
    if (fb < fc) RETURN
    r=(bx-ax)*(fb-fc)
    q=(bx-cx)*(fb-fa)
    u=bx-((bx-cx)*q-(bx-ax)*r)/(2.0*sign(max(abs(q-r),TINY),q-r))
    ulim=bx+GLIMIT*(cx-bx)
    if ((bx-u)*(u-cx) > 0.0) then
      fu=func(u)
      if (fu < fc) then
        ax=bx
        fa=fb
        bx=u
        fb=fu
        RETURN
      else if (fu > fb) then
        cx=u
        fc=fu
        RETURN
      end if
      u=cx+GOLD*(cx-bx)
      fu=func(u)
    else if ((cx-u)*(u-ulim) > 0.0) then
      fu=func(u)
      if (fu < fc) then
        bx=cx
        cx=u
        u=cx+GOLD*(cx-bx)
        call shft(fb,fc,fu,func(u))
      end if
    else if ((u-ulim)*(ulim-cx) >= 0.0) then
      u=ulim
      fu=func(u)
    else
      u=cx+GOLD*(cx-bx)
      fu=func(u)
    end if
    call shft(ax,bx,cx,u)
    call shft(fa,fb,fc,fu)
  end do

END SUBROUTINE mnbrak

SUBROUTINE shft(a,b,c,d)
  use nrtypeDP
  real(DPP), INTENT(OUT) :: a
  real(DPP), INTENT(INOUT) :: b,c
  real(DPP), INTENT(IN) :: d
  a=b
  b=c
  c=d
END SUBROUTINE shft

FUNCTION zbrent(func,x1,x2,tol)
  USE nrtypeDP; USE nrutilDP, ONLY : nrerror
  IMPLICIT NONE
  real(DPP), INTENT(IN) :: x1,x2,tol
  real(DPP) :: zbrent
  INTERFACE
    FUNCTION func(x)
      USE nrtypeDP
      IMPLICIT NONE
      real(DPP), INTENT(IN) :: x
      real(DPP) :: func
    END FUNCTION func
  END INTERFACE
  INTEGER(I4B), PARAMETER :: ITMAX=100
  real(DPP), PARAMETER :: EPS=epsilon(x1)
  INTEGER(I4B) :: iter
  real(DPP) :: a,b,c,d,e,fa,fb,fc,p,q,r,s,tol1,xm
  a=x1
  b=x2
  fa=func(a)
  fb=func(b)
  if ((fa > 0.0 .and. fb > 0.0) .or. (fa < 0.0 .and. fb < 0.0)) &
  call nrerror('root must be bracketed for zbrent')
  c=b
  fc=fb
  do iter=1,ITMAX
    if ((fb > 0.0 .and. fc > 0.0) .or. (fb < 0.0 .and. fc < 0.0)) then
      c=a
      fc=fa
      d=b-a
      e=d
    end if
    if (abs(fc) < abs(fb)) then
      a=b
      b=c
      c=a
      fa=fb
      fb=fc
      fc=fa
    end if
    tol1=2.0*EPS*abs(b)+0.5*tol
    xm=0.5*(c-b)
    if (abs(xm) <= tol1 .or. fb == 0.0) then
      zbrent=b
      RETURN
    end if
    if (abs(e) >= tol1 .and. abs(fa) > abs(fb)) then
      s=fb/fa
      if (a == c) then
        p=2.0*xm*s
        q=1.0-s
      else
        q=fa/fc
        r=fb/fc
        p=s*(2.0*xm*q*(q-r)-(b-a)*(r-1.0))
        q=(q-1.0)*(r-1.0)*(s-1.0)
      end if
      if (p > 0.0) q=-q
      p=abs(p)
      if (2.0*p  <  min(3.0*xm*q-abs(tol1*q),abs(e*q))) then
        e=d
        d=p/q
      else
        d=xm
        e=d
      end if
    else
      d=xm
      e=d
    end if
    a=b
    fa=fb
    b=b+merge(d,sign(tol1,xm), abs(d) > tol1 )
    fb=func(b)
  end do
  call nrerror('zbrent: exceeded maximum iterations')
  zbrent=b
END FUNCTION zbrent

FUNCTION zbrentJ(func,x1,x2,tol,tolF)
  ! stop in addition if abs(func) < tolF
  USE nrtypeDP; USE nrutilDP, ONLY : nrerror
  IMPLICIT NONE
  real(DPP), INTENT(IN) :: x1,x2,tol,tolF
  real(DPP) :: zbrentJ
  INTERFACE
    FUNCTION func(x)
      USE nrtypeDP
      IMPLICIT NONE
      real(DPP), INTENT(IN) :: x
      real(DPP) :: func
    END FUNCTION func
  END INTERFACE
  INTEGER(I4B), PARAMETER :: ITMAX=100
  real(DPP), PARAMETER :: EPS=epsilon(x1)
  INTEGER(I4B) :: iter
  real(DPP) :: a,b,c,d,e,fa,fb,fc,p,q,r,s,tol1,xm
  a=x1
  b=x2
  fa=func(a)
  fb=func(b)
  if ((fa > 0.0 .and. fb > 0.0) .or. (fa < 0.0 .and. fb < 0.0)) &
  call nrerror('root must be bracketed for zbrent')
  c=b
  fc=fb
  do iter=1,ITMAX
    if ((fb > 0.0 .and. fc > 0.0) .or. (fb < 0.0 .and. fc < 0.0)) then
      c=a
      fc=fa
      d=b-a
      e=d
    end if
    if (abs(fc) < abs(fb)) then
      a=b
      b=c
      c=a
      fa=fb
      fb=fc
      fc=fa
    end if
    tol1=2.0*EPS*abs(b)+0.5*tol
    xm=0.5*(c-b)
    if (abs(xm) <= tol1 .or. abs(fb) < tolF) then
      zbrentJ=b
      RETURN
    end if
    if (abs(e) >= tol1 .and. abs(fa) > abs(fb)) then
      s=fb/fa
      if (a == c) then
        p=2.0*xm*s
        q=1.0-s
      else
        q=fa/fc
        r=fb/fc
        p=s*(2.0*xm*q*(q-r)-(b-a)*(r-1.0))
        q=(q-1.0)*(r-1.0)*(s-1.0)
      end if
      if (p > 0.0) q=-q
      p=abs(p)
      if (2.0*p  <  min(3.0*xm*q-abs(tol1*q),abs(e*q))) then
        e=d
        d=p/q
      else
        d=xm
        e=d
      end if
    else
      d=xm
      e=d
    end if
    a=b
    fa=fb
    b=b+merge(d,sign(tol1,xm), abs(d) > tol1 )
    fb=func(b)
  end do
  call nrerror('zbrent: exceeded maximum iterations')
  zbrentJ=b
END FUNCTION zbrentJ

FUNCTION zbrentJp(func,x1,x2,fx1,fx2,tol,tolF)
  ! stop in addition if abs(func) < tolF
  ! bracketing function values also passed here
  USE nrtypeDP; USE nrutilDP, ONLY : nrerror
  IMPLICIT NONE
  real(DPP), INTENT(IN) :: x1,x2,fx1,fx2,tol,tolF
  real(DPP) :: zbrentJp
  INTERFACE
    FUNCTION func(x)
      USE nrtypeDP
      IMPLICIT NONE
      real(DPP), INTENT(IN) :: x
      real(DPP) :: func
    END FUNCTION func
  END INTERFACE
  INTEGER(I4B), PARAMETER :: ITMAX=100
  real(DPP), PARAMETER :: EPS=epsilon(x1)
  INTEGER(I4B) :: iter
  real(DPP) :: a,b,c,d,e,fa,fb,fc,p,q,r,s,tol1,xm
  a=x1
  b=x2
  fa=fx1
  fb=fx2
  if ((fa > 0.0 .and. fb > 0.0) .or. (fa < 0.0 .and. fb < 0.0)) &
  call nrerror('root must be bracketed for zbrent')
  c=b
  fc=fb
  do iter=1,ITMAX
    if ((fb > 0.0 .and. fc > 0.0) .or. (fb < 0.0 .and. fc < 0.0)) then
      c=a
      fc=fa
      d=b-a
      e=d
    end if
    if (abs(fc) < abs(fb)) then
      a=b
      b=c
      c=a
      fa=fb
      fb=fc
      fc=fa
    end if
    tol1=2.0*EPS*abs(b)+0.5*tol
    xm=0.5*(c-b)
    if (abs(xm) <= tol1 .or. abs(fb) < tolF) then
      zbrentJp=b
      RETURN
    end if
    if (abs(e) >= tol1 .and. abs(fa) > abs(fb)) then
      s=fb/fa
      if (a == c) then
        p=2.0*xm*s
        q=1.0-s
      else
        q=fa/fc
        r=fb/fc
        p=s*(2.0*xm*q*(q-r)-(b-a)*(r-1.0))
        q=(q-1.0)*(r-1.0)*(s-1.0)
      end if
      if (p > 0.0) q=-q
      p=abs(p)
      if (2.0*p  <  min(3.0*xm*q-abs(tol1*q),abs(e*q))) then
        e=d
        d=p/q
      else
        d=xm
        e=d
      end if
    else
      d=xm
      e=d
    end if
    a=b
    fa=fb
    b=b+merge(d,sign(tol1,xm), abs(d) > tol1 )
    fb=func(b)
  end do
  call nrerror('zbrent: exceeded maximum iterations')
  zbrentJp=b
END FUNCTION zbrentJp


SUBROUTINE gauher(x,w)
  USE nrtypeDP; USE nrutilDP, ONLY : arth,assert_eq,nrerror
  IMPLICIT NONE
  real(DPP), DIMENSION(:), INTENT(OUT) :: x,w
  real(DPP), PARAMETER :: EPS=3.0e-13,PIM4=0.7511255444649425
  INTEGER(I4B) :: its,j,m,n
  INTEGER(I4B), PARAMETER :: MAXIT=10
  real(DPP) :: anu
  real(DPP), PARAMETER :: C1=9.084064e-01,C2=5.214976e-02,&
  C3=2.579930e-03,C4=3.986126e-03
  real(DPP), DIMENSION((size(x)+1)/2) :: rhs,r2,r3,theta
  real(DPP), DIMENSION((size(x)+1)/2) :: p1,p2,p3,pp,z,z1
  LOGICAL(LGT), DIMENSION((size(x)+1)/2) :: unfinished
  n=assert_eq(size(x),size(w),'gauher')
  m=(n+1)/2
  anu=2.0*n+1.0
  rhs=arth(3,4,m)*PIE/anu
  r3=rhs**(1.0/3.0)
  r2=r3**2
  theta=r3*(C1+r2*(C2+r2*(C3+r2*C4)))
  z=sqrt(anu)*cos(theta)
  unfinished=.true.
  do its=1,MAXIT
    where (unfinished)
      p1=PIM4
      p2=0.0
    end where
    do j=1,n
      where (unfinished)
        p3=p2
        p2=p1
        p1=z*sqrt(2.0/j)*p2-sqrt(real(j-1,DPP)/real(j,DPP))*p3
      end where
    end do
    where (unfinished)
      pp=sqrt(2.0*n)*p2
      z1=z
      z=z1-p1/pp
      unfinished=(abs(z-z1) > EPS)
    end where
    if (.not. any(unfinished)) exit
  end do
  if (its == MAXIT+1) call nrerror('too many iterations in gauher')
  x(1:m)=z
  x(n:n-m+1:-1)=-z
  w(1:m)=2.0/pp**2
  w(n:n-m+1:-1)=w(1:m)
END SUBROUTINE gauher


SUBROUTINE splie2(x1a,x2a,ya,y2a)
  USE nrtypeDP; USE nrutilDP, ONLY : assert_eq
  !USE nr, ONLY : spline
  IMPLICIT NONE
  real(DPP), DIMENSION(:), INTENT(IN) :: x1a,x2a
  real(DPP), DIMENSION(:,:), INTENT(IN) :: ya
  real(DPP), DIMENSION(:,:), INTENT(OUT) :: y2a
  INTEGER(I4B) :: j,m,ndum
  m=assert_eq(size(x1a),size(ya,1),size(y2a,1),'splie2: m')
  ndum=assert_eq(size(x2a),size(ya,2),size(y2a,2),'splie2: ndum')
  do j=1,m
    call spline(x2a,ya(j,:),1.0e30_dpp,1.0e30_dpp,y2a(j,:))
  end do
END SUBROUTINE splie2

FUNCTION splin2(x1a,x2a,ya,y2a,x1,x2)
  USE nrtypeDP; USE nrutilDP, ONLY : assert_eq
  !USE nr, ONLY : spline,splint
  IMPLICIT NONE
  real(DPP), DIMENSION(:), INTENT(IN) :: x1a,x2a
  real(DPP), DIMENSION(:,:), INTENT(IN) :: ya,y2a
  real(DPP), INTENT(IN) :: x1,x2
  real(DPP) :: splin2
  INTEGER(I4B) :: j,m,ndum
  real(DPP), DIMENSION(size(x1a)) :: yytmp,y2tmp2
  m=assert_eq(size(x1a),size(ya,1),size(y2a,1),'splin2: m')
  ndum=assert_eq(size(x2a),size(ya,2),size(y2a,2),'splin2: ndum')
  do j=1,m
    yytmp(j)=splint(x2a,ya(j,:),y2a(j,:),x2)
  end do
  call spline(x1a,yytmp,1.0e30_dpp,1.0e30_dpp,y2tmp2)
  splin2=splint(x1a,yytmp,y2tmp2,x1)
END FUNCTION splin2

end module NRfunctionsDP
