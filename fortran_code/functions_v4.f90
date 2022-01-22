!-------------------------------------------------------------------------------------------!
!
! May 2020
! Hubmer, Krusell, Smith: "Sources of U.S. Wealth Inequality: Past, Present, and Future"
! Model Code
!
! auxiliary file
!
!-------------------------------------------------------------------------------------------!

module functions_v4
  use nrtypeDP
  use shared_v4
  use NRfunctionsDP
  implicit none

  real(DP), private :: CoH_mod,r0_mod,earn_mod
  integer, private :: h_mod

contains

  subroutine assign_K_CoH_vars(CoH_loc,r0_loc,earn_loc,h_loc)
    real(DP), intent(in) :: CoH_loc,r0_loc,earn_loc
    integer, intent(in) :: h_loc
    CoH_mod = CoH_loc
    r0_mod = r0_loc
    earn_mod = earn_loc
    h_mod = h_loc
  end subroutine assign_K_CoH_vars

  function K_CoH_Fun(x)
    real(DP), intent(in) :: x ! begin-of-period assets (Kgrid)
    real(DP) :: K_CoH_Fun ! difference CoH(Kgrid) - CoH(EGP)
    real(DP) :: yk_ord,yk_cg,y_ord,net_y_ord,net_y
    call RCap(x,h_mod,r0_mod,yk_ord,yk_cg)
    y_ord = yk_ord + earn_mod
    net_y_ord = ynet(y_ord)
    net_y = net_y_ord + (1.0-tau_cg)*yk_cg
    K_CoH_Fun = x + net_y - CoH_mod
  end function K_CoH_Fun

  function Kcdf_inv(x) ! inverse CDF of wealth
    real(DP), intent(in) :: x ! probability
    real(DP) :: Kcdf_inv
    Kcdf_inv = lin_interp(Kcdf,Kfi,x)
  end function Kcdf_inv

  function Kbo_fun(x) ! integral of asset holdings [0,x]
    real(DP), intent(in) :: x ! asset level
    real(DP) :: Kbo_fun
    Kbo_fun = lin_interp(Kfi,Kbo,x)
  end function Kbo_fun

  function lin_interp(xa,ya,x) ! classic linear interpolation in 1 dim
    USE nrutilDP, ONLY : assert_eq
    real(DP), dimension(:), intent(in) :: xa,ya
    real(DP), intent(in) :: x
    integer :: size_xa,n_loc
    real(DP) :: int_coef, lin_interp
    size_xa=assert_eq(size(xa),size(ya),'lin_interp')
    n_loc = max(1,min(size_xa-1,locate(xa,x)))
    int_coef = (x-xa(n_loc))/(xa(n_loc+1)-xa(n_loc))
    lin_interp = int_coef*ya(n_loc+1)+(1.0-int_coef)*ya(n_loc)
  end function lin_interp

  function lin_interp1(xa,ya,x,dx) ! linear int 1-D, in addition 1st derivative
    USE nrutilDP, ONLY : assert_eq
    real(DP), dimension(:), intent(in) :: xa,ya
    real(DP), intent(in) :: x
    real(DP), intent(out) :: dx
    real(DP) :: lin_interp1
    integer :: size_xa,n_loc
    size_xa=assert_eq(size(xa),size(ya),'lin_interp')
    n_loc = max(1,min(size_xa-1,locate(xa,x)))
    dx = (ya(n_loc+1)-ya(n_loc))/(xa(n_loc+1)-xa(n_loc))
    lin_interp1 = ya(n_loc) + (x-xa(n_loc))*dx
  end function lin_interp1

  function lin_interp_d1(xa,ya,x) ! linear int 1-D, only 1st derivative
    USE nrutilDP, ONLY : assert_eq
    real(DP), dimension(:), intent(in) :: xa,ya
    real(DP), intent(in) :: x
    real(DP) :: lin_interp_d1
    integer :: size_xa,n_loc
    size_xa=assert_eq(size(xa),size(ya),'lin_interp')
    n_loc = max(1,min(size_xa-1,locate(xa,x)))
    lin_interp_d1 = (ya(n_loc+1)-ya(n_loc))/(xa(n_loc+1)-xa(n_loc))
  end function lin_interp_d1

  function mean_xx(xx)
    real(DP), dimension(:), intent(in):: xx
    real(DP) :: mean_xx
    integer :: nx
    nx = size(xx)
    mean_xx = sum(xx)/real(nx)
  end function mean_xx

  subroutine compute_vary_r()
    real(DP), dimension(nRp+1) :: K_fract
    real(DP), dimension(nRp) :: Krp,K_rdif_upd,r_ex_upd,diff_k,diff_r
    real(DP), dimension(nRp,nAssets) :: Krp_asset,r_ex_asset
    real(DP), dimension(nAssets) :: r_ex_norm,r_ex_agg2
    real(DP), parameter :: damp_rp = 0.75
    integer :: ia

    ! compute quantiles of asset cdf at r_fract and r_fract2
    K_fract(1) = Kfi(1)
    K_fract(nRp+1) = Kfi(nKf)
    do ia = 2,nRp
      K_fract(ia) = Kcdf_inv(r_fract(ia))
    end do
    do ia = 1,nRp
      K_rdif_upd(ia) = Kcdf_inv(r_fract2(ia))
    end do

    ! compute wealth shares by quantile (and asset type)
    Krp(1) = Kbo_fun(K_fract(2))
    Krp_asset(1,:) = Krp(1) * pf_w(1,:)
    do ia=2,nRp
      Krp(ia) = Kbo_fun(K_fract(ia+1)) - Kbo_fun(K_fract(ia))
      Krp_asset(ia,:) = Krp(ia) * pf_w(ia,:)
    end do
    Krp = Krp / sum(Krp)
    do ia=1,nAssets
      Krp_asset(:,ia) = Krp_asset(:,ia) / sum(Krp_asset(:,ia))
    end do

    ! normalize excess return by asset
    do ia=1,nAssets
      r_ex_norm(ia) = sum(Krp_asset(:,ia)*r_dif_mean(:,ia))
    end do
    r_ex_agg2 = r_ex_agg - r_ex_norm
    do ia=1,nAssets
      r_ex_asset(:,ia) = r_ex_agg2(ia) + r_dif_mean(:,ia)
    end do
    r_ex_upd = sum(pf_w * r_ex_asset , 2)
    r_ex_upd = r_ex_upd - r_ex_upd(1)
    ! finally have excess return and sd by quantile (one asset in model only)

    ! update
    diff_k = (K_rdif_upd - K_rdif)/max(abs(K_rdif),0.1)
    diff_r = (r_ex_upd - r_ex)/max(abs(r_ex),0.1)
    K_rdif = damp_rp*K_rdif + (1.0-damp_rp)*K_rdif_upd
    r_ex = damp_rp*r_ex + (1.0-damp_rp)*r_ex_upd
    if (test_no_ex) then
      r_ex = 0.0_dp
    end if

    ! fit spline to excess return
    call spline(K_rdif,r_ex,0.0_dp,0.0_dp,r_ex_d2)
    call spline(K_rdif,r_sd,0.0_dp,0.0_dp,r_sd_d2)

    if (print_model_details) then
      write(*,"(A30,F12.4,A10,F12.4,A10,F12.4)") 'Diff K_rdif mean:',mean_xx(diff_k),&
        'mean abs:',mean_xx(abs(diff_k)),'max abs:',maxval(abs(diff_k))
      write(*,"(A30,F12.4,A10,F12.4,A10,F12.4)") 'Diff r_ex mean:',mean_xx(diff_r),&
          'mean abs:',mean_xx(abs(diff_r)),'max abs:',maxval(abs(diff_r))
      write(*,"(A14,13ES10.3)") 'K_rdif',K_rdif
      write(*,"(A14,13ES10.3)") 'r_ex',r_ex
      write(*,"(A14,13ES10.3)") 'r_sd',r_sd
      write(*,"(A40,3F12.4)") 'Weighted Return Diff.',r_ex_norm
      write(*,"(A40,3F12.4)") 'Excess Return Re-Norm.',r_ex_agg2
      call test_r_ex_sd(1.0_dp)
    end if

  end subroutine compute_vary_r

  function r_ex_fun(x)
    real(DP), intent(in) :: x
    real(DP) :: r_ex_fun
    if (x <= K_rdif(1)) then
      r_ex_fun = r_ex(1)
    elseif (x >= K_rdif(nRp)) then
      r_ex_fun = r_ex(nRp)
    else
      if (rex_lip) then
        r_ex_fun = lin_interp(K_rdif,r_ex,x)
      else
        r_ex_fun = splint(K_rdif,r_ex,r_ex_d2,x)
      end if
    end if
  end function r_ex_fun

  function r_ex_fun_d1(x)
    real(DP), intent(in) :: x
    real(DP) :: r_ex_fun_d1
    if (x <= K_rdif(1)) then
      r_ex_fun_d1 = 0.0_dp
    elseif (x >= K_rdif(nRp)) then
      r_ex_fun_d1 = 0.0_dp
    else
      if (rex_lip) then
        r_ex_fun_d1 = lin_interp_d1(K_rdif,r_ex,x)
      else
        r_ex_fun_d1 = splint1(K_rdif,r_ex,r_ex_d2,x)
      end if
    end if
  end function r_ex_fun_d1

  function r_sd_fun(x)
    real(DP), intent(in) :: x
    real(DP) :: r_sd_fun
    if (x <= K_rdif(1)) then
      r_sd_fun = r_sd(1)
    elseif (x >= K_rdif(nRp)) then
      r_sd_fun = r_sd(nRp)
    else
      if (rex_lip) then
        r_sd_fun = lin_interp(K_rdif,r_sd,x)
      else
        r_sd_fun = splint(K_rdif,r_sd,r_sd_d2,x)
      end if
    end if
  end function r_sd_fun

  function r_sd_fun_d1(x)
    real(DP), intent(in) :: x
    real(DP) :: r_sd_fun_d1
    if (x <= K_rdif(1)) then
      r_sd_fun_d1 = 0.0_dp
    elseif (x >= K_rdif(nRp)) then
      r_sd_fun_d1 = 0.0_dp
    else
      if (rex_lip) then
        r_sd_fun_d1 = lin_interp_d1(K_rdif,r_sd,x)
      else
        r_sd_fun_d1 = splint1(K_rdif,r_sd,r_sd_d2,x)
      end if
    end if
  end function r_sd_fun_d1

  subroutine test_r_ex_sd(x)
    real(DP), intent(in) :: x
    write(*,"(A40,F12.3)") 'Testing r_ex and r_sd at x=',x
    write(*,"(A15,F15.8,A15,F15.8)") 'r_ex =',r_ex_fun(x),'d r_ex / d a =',r_ex_fun_d1(x)
    write(*,"(A15,F15.8,A15,F15.8)") 'r_sd =',r_sd_fun(x),'d r_sd / d a =',r_sd_fun_d1(x)
  end subroutine test_r_ex_sd

  subroutine RCap(cap,h2,r0_loc,Rcap_ord,Rcap_cg)
    real(DP), intent(in) :: cap, r0_loc
    real(DP), intent(out) :: Rcap_ord,Rcap_cg
    real(DP) :: r_ex_loc,r_sd_loc,Rcap_eps
    integer, intent(in) :: h2

    r_ex_loc = r_ex_fun(cap)
    r_sd_loc = r_sd_fun(cap)

    Rcap_ord = (r0_loc + r_ex_loc)*cap

    Rcap_eps = r_sd_loc*Agrid(h2)*cap
    if (cg_tax == 0) then
      Rcap_ord = Rcap_ord + Rcap_eps
      Rcap_cg = 0.0
    else
      Rcap_cg = Rcap_eps
    end if
  end subroutine Rcap

  subroutine RCap1(cap,h2,r0_loc,Rcap_ord,Rcap_cg,dRcap_ord,dRcap_cg)
    real(DP), intent(in) :: cap, r0_loc
    real(DP), intent(out) :: Rcap_ord,Rcap_cg,dRcap_ord,dRcap_cg
    real(DP) :: r_ex_loc,dr_ex_loc,r_sd_loc,dr_sd_loc,Rcap_eps,dRcap_eps
    integer, intent(in) :: h2

    r_ex_loc = r_ex_fun(cap)
    dr_ex_loc = r_ex_fun_d1(cap)
    r_sd_loc = r_sd_fun(cap)
    dr_sd_loc = r_sd_fun_d1(cap)

    Rcap_ord = (r0_loc + r_ex_loc)*cap
    dRcap_ord = (r0_loc + r_ex_loc) + dr_ex_loc*cap

    Rcap_eps = r_sd_loc*Agrid(h2)*cap
    dRcap_eps = r_sd_loc*Agrid(h2) + dr_sd_loc*Agrid(h2)*cap
    if (cg_tax == 0) then
      Rcap_ord = Rcap_ord + Rcap_eps
      dRcap_ord = dRcap_ord + dRcap_eps
      Rcap_cg = 0.0
      dRcap_cg = 0.0
    else
      Rcap_cg = Rcap_eps
      dRcap_cg = dRcap_eps
    end if

  end subroutine Rcap1

  function norminv(quantile,mu,sigma)
    ! transforms quantile \in (0,1) into normal (sigma,mu)
    real(DP), intent(in) :: quantile, mu, sigma
    real(DP) :: norminv
    norminv = mu + sigma*r8_normal_01_cdf_inverse(quantile)
  end function norminv

  function Ztrans(z,cdfz)
    ! transforms normal z shock into a variable scaling wage
    real(DP), intent(in) :: z,cdfz
    real(DP) :: Ztrans
    if (cdfz < qtop) then
      Ztrans = exp(z)
    else
      Ztrans = Qpareto((cdfz-qtop)/(1.0-qtop),ebar,eta)
    end if
  end function Ztrans

  function normpdf(mu,sigma,x)
    real(DP), intent(in) :: mu,sigma,x
    real(DP) :: normpdf
    normpdf = exp(-((x-mu)**2)/(2.0*sigma**2))/(sigma*sqrt(TWOPI_D))
  end function normpdf

  function normcdf(mu,sigma,x)
    real(DP), intent(in) :: mu,sigma,x
    real(DP) :: normcdf
    normcdf = (1.0+erf((x-mu)/(sigma*sqrt(2.0))))/2.0
  end function normcdf

  function qPareto(quant,xmin,parcoef)
    real(DP), intent(in) :: xmin,parcoef,quant
    real(DP) :: qPareto
    qPareto = xmin*(1.0-quant)**(-1.0/parcoef)
  end function qPareto

  subroutine intWeightsN(mu,sigma,zzgrid,eegrid,ngrid,wx)
    ! for a normally distributed (mu,sigma) random variable z on grid 'zzgrid'
    ! of length ngrid, computes integration weights wx s.t.
    ! sum_j wx_j h(grid(j)) =approx integral h(z) f(z) dz
    ! given that h(z) is interpolated linearly off the grid in the actual productivity space
    ! with grid 'eegrid' (check that linear interpolation works better in that space)
    real(DP), intent(in) :: mu,sigma
    integer, intent(in) :: ngrid
    real(DP), dimension(ngrid), intent(in) :: zzgrid,eegrid
    real(DP), dimension(ngrid) :: wx
    integer, parameter :: ipts=100000
    real(DP), parameter :: extrap=0.1
    real(DP), dimension(ipts) :: intgridZ
    integer :: ii,n
    real(DP) :: pdfval,theta,xlo,xhi,eval
    xlo = (1.0+extrap)*minval(zzgrid) - extrap*maxval(zzgrid)
    xhi = (1.0+extrap)*maxval(zzgrid) - extrap*minval(zzgrid)
    intgridZ = linspace(xlo,xhi,ipts)
    wx = 0.0
    do ii =1,ipts
      eval = Ztrans(intgridZ(ii),normcdf(mu,sigma,intgridZ(ii)))
      n = max(1,min(ngrid-1,locate(eegrid,eval)))
      theta = (eval-eegrid(n))/(eegrid(n+1)-eegrid(n))
      pdfval = normpdf(mu,sigma,intgridZ(ii))
      wx(n)  = wx(n)  +(1.0-theta)*pdfval
      wx(n+1)= wx(n+1)+     theta *pdfval
    end do
    wx = wx/sum(wx)
  end subroutine intWeightsN

  subroutine LoopIndex(wx,ngrid,loop)
    ! normalizes integration matrix wx such that rows sum to one
    ! and creates index loop indicating non-negligible summation weights
    integer, intent(in) :: ngrid
    integer :: n,n2,n3
    real(DP), dimension(ngrid,ngrid) :: wx
    integer, dimension(ngrid,ngrid+1), intent(out) :: Loop
    real(DP), parameter :: trunc=1e-06
    do n=1,ngrid
      wx(n,:) = wx(n,:)/sum(wx(n,:))
      n3 = 0
      do n2=1,ngrid
        if (wx(n,n2)>trunc) then
          n3 = n3 + 1
          loop(n,n3) = n2
        else
          wx(n,n2) = 0.0
        end if
      end do
      wx(n,:) = wx(n,:)/sum(wx(n,:))
      loop(n,ngrid+1) = n3
    end do
  end subroutine LoopIndex

  subroutine get_tax_RK(taxesPaid,sumProb,sumInc,aggCapInc)
    real(DP), intent(out) :: taxesPaid,sumProb,sumInc,aggCapInc
    real(DP) :: taxes,y_ord,y_total,Rcap_ord,Rcap_cg,yk_total
    integer :: i,j,k,h,q
    taxesPaid = 0.0
    aggCapInc = 0.0
    sumProb = 0.0
    sumInc = 0.0
    do j=1,nE
      do k=1,nB
        do h=1,nA
          do q=1,nGQ
            call RCap(Kfi(1),h,r0,Rcap_ord,Rcap_cg)
            y_ord = earn(j,q) + Rcap_ord
            y_total = y_ord + Rcap_cg
            yk_total = Rcap_ord + Rcap_cg
            taxes = y_ord - yNet(y_ord) + tau_cg*Rcap_cg
            sumProb = sumProb     + wGQ(q)*fA(h)*fJ(j,k)*(1.0-G(1,j,k))
            taxesPaid = taxesPaid + wGQ(q)*fA(h)*fJ(j,k)*(1.0-G(1,j,k))*taxes
            aggCapInc = aggCapInc + wGQ(q)*fA(h)*fJ(j,k)*(1.0-G(1,j,k))*yk_total
            sumInc = sumInc       + wGQ(q)*fA(h)*fJ(j,k)*(1.0-G(1,j,k))*y_total
            do i=2,nKf
              call RCap((Kfi(i-1)+Kfi(i))/2.0,h,r0,Rcap_ord,Rcap_cg)
              y_ord = earn(j,q) + Rcap_ord
              y_total = y_ord + Rcap_cg
              yk_total = Rcap_ord + Rcap_cg
              taxes = y_ord - yNet(y_ord) + tau_cg*Rcap_cg
              sumProb = sumProb + wGQ(q)*fA(h)*fJ(j,k)*(G(i-1,j,k)-G(i,j,k))
              taxesPaid = taxesPaid + wGQ(q)*fA(h)*fJ(j,k)*(G(i-1,j,k)-G(i,j,k))*taxes
              aggCapInc = aggCapInc + wGQ(q)*fA(h)*fJ(j,k)*(G(i-1,j,k)-G(i,j,k))*yk_total
              sumInc = sumInc       + wGQ(q)*fA(h)*fJ(j,k)*(G(i-1,j,k)-G(i,j,k))*y_total
            end do
          end do
        end do
      end do
    end do
  end subroutine get_tax_RK

  subroutine Ginis(gYLpre,gYpre,gYpost)
    ! computes Gini coefficient for labor income, as well as for total income
    real(DP), intent(out) ::  gYLpre,gYpre,gYpost
    real(DP), dimension(nE*nGQ) :: YLpre,ProbYL
    real(DP), dimension(nE*nGQ+1) :: SYLpre
    real(DP), dimension(:,:,:,:,:), allocatable :: Ypre,Ypost,ProbY
    real(DP), dimension(:), allocatable :: vecYpre,vecYpost,vecProbYpre,vecProbYpost,SYpre,SYpost
    real(DP) :: Rcap_ord,Rcap_cg,y_ord
    integer :: i,j,k,h,q,jj,nS

    ! labor income Gini (pre-tax and transfer)
    do j=1,nE
      do q=1,nGQ
        YLpre((j-1)*nGQ+q) = earn(j,q)
        ProbYL((j-1)*nGQ+q) = fE(j)*wGQ(q)
      end do
    end do
    call sort2(YLpre,ProbYL)
    SYLpre(1)=0.0
    jj = nE*nGQ+1
    do i=2,jj
      SYLpre(i)=SYLpre(i-1)+ProbYL(i-1)*YLpre(i-1)
    end do
    gYLpre = 1.0-(sum(ProbYL*(SYLpre(1:jj-1)+SYLpre(2:jj))))/SYLpre(jj)

    ! total income Gini, pre- and post- tax and transfer
    allocate(Ypre(nKf,nE,nB,nA,nGQ),Ypost(nKf,nE,nB,nA,nGQ),ProbY(nKf,nE,nB,nA,nGQ))
    do j=1,nE
      do k=1,nB
        do h=1,nA
          do q=1,nGQ
            call RCap(Kfi(1),h,r0,Rcap_ord,Rcap_cg)
            y_ord = earn(j,q) + Rcap_ord
            Ypre(1,j,k,h,q) = y_ord + Rcap_cg
            Ypost(1,j,k,h,q) = yNet(y_ord) + (1.0-tau_cg)*Rcap_cg + lumpsum
            ProbY(1,j,k,h,q) = wGQ(q)*fA(h)*fJ(j,k)*(1.0-G(1,j,k))
            do i=2,nKf
              call RCap((Kfi(i-1)+Kfi(i))/2.0,h,r0,Rcap_ord,Rcap_cg)
              y_ord = earn(j,q) + Rcap_ord
              Ypre(i,j,k,h,q) = y_ord + Rcap_cg
              Ypost(i,j,k,h,q) = yNet(y_ord) + (1.0-tau_cg)*Rcap_cg + lumpsum
              ProbY(i,j,k,h,q) = wGQ(q)*fA(h)*fJ(j,k)*(G(i-1,j,k)-G(i,j,k))
            end do
          end do
        end do
      end do
    end do
    nS = nKf*nE*nB*nA*nGQ
    allocate(vecYpre(nS))
    vecYpre = RESHAPE(Ypre, (/nS/))
    deallocate(Ypre)
    allocate(vecYpost(nS))
    vecYpost = RESHAPE(Ypost, (/nS/))
    deallocate(Ypost)
    allocate(vecProbYpre(nS))
    vecProbYpre = RESHAPE(ProbY, (/nS/))
    deallocate(ProbY)
    allocate(vecProbYpost(nS))
    vecProbYpost = vecProbYpre
    call sort2(vecYpre,vecProbYpre)
    call sort2(vecYpost,vecProbYpost)
    allocate(SYpre(nS+1),SYpost(nS+1))
    SYpre(1) = 0.0
    SYpost(1) = 0.0
    do i=2,(nS+1)
      SYpre(i) = SYpre(i-1) + vecProbYpre(i-1)*vecYpre(i-1)
      SYpost(i) = SYpost(i-1) + vecProbYpost(i-1)*vecYpost(i-1)
    end do
    deallocate(vecYpre,vecYpost)

    gYpre = 1.0 - (sum(vecProbYpre*(SYpre(1:nS)+SYpre(2:nS+1))))/SYpre(nS+1)
    gYpost = 1.0 - (sum(vecProbYpost*(SYpost(1:nS)+SYpost(2:nS+1))))/SYpost(nS+1)
    deallocate(vecProbYpre,vecProbYpost,SYpre,SYpost)
  end subroutine Ginis


  function capgrid(a,b,n)
    real(DP) :: a,b,c,d
    real(DP), dimension(n) :: capgrid
    integer :: i,n
    c = 0.0
    d = log(b-a+1.0)
    do i=1,n
      capgrid(i)= exp(c + (d-c)*(i-1.0)/(n-1.0))+a-1.0
    end do
  end function capgrid

  function linspace(xlo,xhi,N)
    USE nrutilDP, ONLY : nrerror
    real(DP), intent(in) :: xlo,xhi
    integer, intent(in) :: N
    real(DP), dimension(N) :: linspace
    integer :: m
    if (N < 2) call nrerror('linspace vector must be at least of length 2')
    linspace(1) = xlo
    linspace(N) = xhi
    if (N > 2) then
      do m=2,N-1
        linspace(m) = xlo + (xhi-xlo)*real(m-1)/real(N-1)
      end do
    end if
  end function linspace

  function F(KK) ! production function
    real(DP) :: F,KK,epsLocal
    if (CESdummy) then
      epsLocal = (sigmaCES-1.0)/sigmaCES
      F =  TFP * ACES*(alphaCES*KK**epsLocal + (1.0-alphaCES)*LL**epsLocal)**(1.0/epsLocal)
    else
      F = TFP * KK**alpha*LL**(1-alpha)
    end if
  end function F

  function Fnet(KK) ! net production function
    real(DP) :: Fnet,KK
    Fnet = F(KK) - delta*KK
  end function Fnet

  function MPL(KK) ! marginal product of labor
    real(DP) :: MPL,KK,epsLocal
    if (CESdummy) then
      epsLocal = (sigmaCES-1.0)/sigmaCES
      MPL = TFP * (1.0-alphaCES)*ACES*LL**(-1.0/sigmaCES)*(alphaCES*KK**epsLocal &
      + (1.0-alphaCES)*LL**epsLocal)**(1.0/(sigmaCES-1.0))
    else
      MPL = TFP * (1-alpha)*(KK/LL)**alpha
    end if
  end function MPL

  function MPC(KK) ! marginal product of capital
    real(DP) :: MPC,KK,epsLocal
    if (CESdummy) then
      epsLocal = (sigmaCES-1.0)/sigmaCES
      MPC = TFP * alphaCES*ACES*KK**(-1.0/sigmaCES)*(alphaCES*KK**epsLocal &
      + (1.0-alphaCES)*LL**epsLocal)**(1.0/(sigmaCES-1.0))
    else
      MPC = TFP * alpha*(LL/KK)**(1-alpha)
    end if
  end function MPC

  function u(cons) ! utility function
    real(DP) :: u,cons
    if (cons>0.0) then
      if (sig > 1.00001 .or. sig < 0.99999) then
        u = (cons**(1.0-sig))/(1.0-sig)
      else
        u = log(cons)
      end if
    else
      u = - (10.0**16)
    end if
  end function u

  function du(cons) ! first derivative of utility function
    real(DP) :: du,cons
    if (cons>0.0) then
      du = cons**(-sig)
    else
      du = 0.0
    end if
  end function du

  function duInv(x) ! inverse of first derivative of utility function
    real(DP) :: duInv,x
    duInv = x**(-1.0/sig)
  end function duInv

  function utr(x) ! TRansform grid in Utility scale
    real(DP), intent(in) :: x
    real(DP) :: utr
    utr = log(x-CoH(1)+1.0)
  end function utr

  function dutr(x) ! TRansform grid in Utility scale, derivative
    real(DP), intent(in) :: x
    real(DP) :: dutr
    dutr = 1.0/(x-CoH(1)+1.0)
  end function dutr

  function yNet(y)
    real(DP), intent(in) :: y
    real(DP) :: yNet
    integer :: m
    if (y<0.0_dp) then
      yNet = y
    else
      m = min(locate(tauG,y),nTau-1)
      if (m==0) then
        yNet = (1.0_dp-tauM(1))*y
      else
        yNet = y - tax(m)-(y-tauG(m))*tauM(m+1)
      end if
    end if
  end function yNet

  subroutine yNet1(y,netY,DnetY)
    real(DP), intent(in) :: y
    real(DP) :: netY,dnetY
    integer :: m
    if (y<0.0_dp) then
      netY = y
      dnetY = 1.0_dp
    else
      m = min(locate(tauG,y),nTau-1)
      if (m==0) then
        netY = (1.0_dp-tauM(1))*y
        dnetY = (1.0_dp-tauM(1))
      else
        netY = y - tax(m)-(y-tauG(m))*tauM(m+1)
        dnetY = (1.0_dp-tauM(m+1))
      end if
    end if
  end subroutine yNet1

  function Veval(x,i,j,k)
    real(DP), intent(in) :: x
    real(DP) :: Veval ! intent(out)
    real(DP) :: temp,Rcap_ord,Rcap_cg,CoHnext
    integer :: jj,j2,kk,k2,h2,q2,i,j,k
    temp = 0.0
    do h2=1,nA
      call RCap(x,h2,r0,Rcap_ord,Rcap_cg)
      do jj=1,LoopE(j,nE+1)
        j2 = LoopE(j,jj)
        do q2=1,nGQ
          CoHnext = utr(x + yNet(Rcap_ord+earn(j2,q2)) + (1.0-tau_cg)*Rcap_cg + lumpsum)
          do kk = 1,LoopB(k,nB+1)
            k2 = LoopB(k,kk)
            temp = temp + Pj(j,j2,k,k2,h2,q2)*splint(CoHutr,V(:,j2,k2),D2V(:,j2,k2),CoHnext)
          end do
        end do
      end do
    end do
    Veval = u(CoH(i)-Gr*x) + betaEff(k)*temp
  end function Veval

  function is_V_concave()
    integer :: is_V_concave,i,j,k
    is_V_concave = 0
    do k=1,nB
      do j=1,nE
        do i=2,nK
          if (CoH2(i,j,k)<CoH2(i-1,j,k)) then ! Houston we have a problem
            print *,'value function non-concave at i,j,k',i,j,k
            print *,'savings choices at i-1 and i',CoH2(i-1,j,k),CoH2(i,j,k)
            is_V_concave = is_V_concave + 1
          end if
        end do
      end do
    end do
    if (is_V_concave==0) then
      print *, 'conditional expectation of value function concave everywhere'
    else
      print *, 'WARNING: conditional expectation of value function not concave everywhere'
      print *, 'number of problematic points is',is_V_concave,'out of',(nK-1)*nE*nB
      write(*,"(A50,F15.4)") 'so in % that is',real(is_V_concave) / real((nK-1)*nE*nB)
    end if
  end function is_V_concave

  subroutine EGP()
    ! endogenous grid point method
    real(DP), dimension(:,:,:,:,:), allocatable :: DVcont
    real(DP) :: temp
    integer :: i,j,k,h,q,j2,k2,h2,q2

    ! compute first derivative of value function tomorrow
    allocate(DVcont(nK,nE,nB,nGQ,nA))
    !$OMP PARALLEL DO private(h,q,k,j,i) shared(CoHutr,V,D2V,resTr,dCoHdK) collapse(3)
    do h=1,nA
      do q=1,nGQ
        do k=1,nB
          do j=1,nE
            do i=1,nK
              DVcont(i,j,k,q,h) = splint1(CoHutr,V(:,j,k),D2V(:,j,k),resTr(i,j,h,q))*dCoHdK(i,j,h,q)

              if (isnan(DVcont(i,j,k,q,h))) then
                print *,'stop program, DVcont = NaN for i',i,'j',j,'k',k,'q',q,'h',h
                print *,'Kgrid(i),h,r0',Kgrid(i),h,r0
                print *,'earn(j,q)',earn(j,q)
                print *,'tau_cg',tau_cg
                print *,'lumpsum',lumpsum
                print *,'r_ex_fun(Kgrid(i))',r_ex_fun(Kgrid(i))
                print *,'r_ex',r_ex
                print *,'K_rdif',K_rdif
                print *,'r_ex_d2',r_ex_d2
                stop
              end if

            end do
          end do
        end do
      end do
    end do
    !$OMP END PARALLEL DO

    ! take expectation and compute CoH2 today such that savings Kgrid(i) is optimal
    !$OMP PARALLEL DO private(j,k,i,j2,k2,q2,h2,temp) shared(Pj,DVcont,CoH2,Kgrid,betaEff) collapse(2)
    do k=1,nB
      do j=1,nE
        do i=1,nK
          temp = 0.0
          do h2=1,nA
            do q2=1,nGQ
              do k2=1,nB
                do j2=1,nE
                  temp = temp + Pj(j,j2,k,k2,h2,q2)*DVcont(i,j2,k2,q2,h2)
                end do
              end do
            end do
          end do
          CoH2(i,j,k) = duInv(betaEff(k)*temp)+Gr*Kgrid(i)
        end do
      end do
    end do
    !$OMP END PARALLEL DO
    deallocate(DVcont)

  end subroutine EGP

end module functions_v4
