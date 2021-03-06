!!****m* DoNOF/m_rdmd
!! NAME
!! basic NOFT variables
!!
!! FUNCTION
!! This module contains definitions of common variables used by NOFT module.
!!
!! COPYRIGHT
!! This file is distributed under the terms of the
!! GNU General Public License, see http://www.gnu.org/copyleft/gpl.txt .
!!
!! NOTES
!!
!! SOURCE

module m_rdmd 

 use m_nofoutput
 use m_definitions

 implicit none

!!****t* m_rdmd/rdm_t
!! NAME
!! rdm_t
!!
!! FUNCTION
!! Datatype storing noft quantities and arrays needed
!!
!! SOURCE

 type,public :: rdm_t

  logical::GAMMAs_nread=.true.   ! Are GAMMAS read from previous calc.?
  integer::INOF=7                ! Functional to use (5-> PNOF5, 7-> PNOF7)
  integer::Ista=1                ! Use PNOF7s version
  integer::Nfrozen               ! Number of frozen orbitals in the NOFT calc.
  integer::Nbeta_elect           ! Number of orbitals containing beta electrons
  integer::Nalpha_elect          ! Number of orbitals containing alpha electrons
  integer::Nsingleocc=0          ! Number of singly occ orbitals
  integer::NBF_tot               ! Number of total orbitals
  integer::NBF_occ               ! Number of frozen plus active orbitals
  integer::NBF_ldiag             ! Size of the arrays that contain J, K, and L integrals
  integer::Ncoupled              ! Number of 'virtual' coupled orbital per 'occupied' orbital  
  integer::Npairs                ! Number of electron pairs
  integer::Npairs_p_sing         ! Number of electron pairs plus number of singly occ orbitals
  integer::Ngammas               ! Number of gammas (independet variables used in occ optimization procedure)
  real(dp)::Lpower=0.53d0        ! Power functional exponent
! arrays 
  real(dp),allocatable,dimension(:)::occ,chempot_orb
  real(dp),allocatable,dimension(:)::GAMMAs_old
  real(dp),allocatable,dimension(:)::DM2_J,DM2_K,DM2_L,DM2_iiii
  real(dp),allocatable,dimension(:)::Docc_gamma,Dfni_ni
  real(dp),allocatable,dimension(:)::DDM2_gamma_J,DDM2_gamma_K,DDM2_gamma_L

 contains 
   procedure :: free => rdm_free
   ! Destructor.

   procedure :: print_dmn => print_rdm
   ! Print the 1,2-RDMs into unformated files.

   procedure :: print_swdmn => print_swrdm
   ! Print the spin-with 1,2-RDMs into formated files.

   procedure :: print_orbs => print_orb_coefs
   ! Print orbital coefs to a formated file.

   procedure :: print_orbs_bin => print_orb_coefs_bin
   ! Print orbital coefs to an unformated file.

   procedure :: print_gammas => print_gammas_old
   ! Print GAMMAs_old indep./unconstrained variables.

 end type rdm_t

 public :: rdm_init     ! Main creation method.
!!***

CONTAINS  !==============================================================================

!!***
!!****f* DoNOF/rdm_init
!! NAME
!! rdm_init
!!
!! FUNCTION
!!  Initialize the data type rdm_t 
!!
!! INPUTS
!! INOF=PNOFi functional to use
!! Ista=Use PNOF7 (Ista=0) or PNOF7s (Ista=1)
!! NBF_tot=Number of total orbitals
!! NBF_occ=Number of orbitals that are occupied
!! Nfrozen=Number of frozen orbitals that remain with occ=2.0 
!! Npairs=Number of electron pairs
!! Ncoupled=Number of coupled orbitals per electron pair (it is then used as Ncoupled-1 inside this module, as the number
!!             of coupled 'virtual' orbitals to a 'initially occupied' (HF) orbital)
!! Nbeta_elect=Number of beta electrons (N/2 for spin compensated systems)
!! Nalpha_elect=Number of beta electrons (N/2 for spin compensated systems)
!!
!! OUTPUT
!!
!! PARENTS
!!  
!! CHILDREN
!!
!! SOURCE

subroutine rdm_init(RDMd,INOF,Ista,NBF_tot,NBF_occ,Nfrozen,Npairs,&
&  Ncoupled,Nbeta_elect,Nalpha_elect,Lpower)
!Arguments ------------------------------------
!scalars
 integer,intent(in)::INOF,Ista
 integer,intent(in)::NBF_tot,NBF_occ,Nfrozen,Npairs,Ncoupled
 integer,intent(in)::Nbeta_elect,Nalpha_elect
 real(dp),optional,intent(in)::Lpower
 type(rdm_t),intent(inout)::RDMd
!Local variables ------------------------------
!scalars
 real(dp)::totMEM
!arrays
 character(len=200)::msg
!************************************************************************

 RDMd%INOF=INOF
 if(RDMd%INOF==-2) then
  if(present(Lpower)) then
   RDMd%Lpower=Lpower
  endif
 endif
 RDMd%Ista=Ista
 RDMd%Nfrozen=Nfrozen
 RDMd%Nbeta_elect=Nbeta_elect
 RDMd%Nalpha_elect=Nalpha_elect
 RDMd%NBF_occ=NBF_occ
 RDMd%NBF_tot=NBF_tot
 RDMd%Ncoupled=Ncoupled
 RDMd%Npairs=Npairs
 RDMd%Nsingleocc=Nalpha_elect-Nbeta_elect
 RDMd%Npairs_p_sing=RDMd%Npairs+RDMd%Nsingleocc 
 RDMd%NBF_ldiag=RDMd%NBF_occ*(RDMd%NBF_occ+1)/2
 RDMd%Ngammas=RDMd%Ncoupled*RDMd%Npairs
 ! Calculate memory needed
 totMEM=3*RDMd%NBF_occ*RDMd%NBF_occ+RDMd%NBF_occ*RDMd%Ngammas+3*RDMd%NBF_occ*RDMd%NBF_occ*RDMd%Ngammas
 totMEM=totMEM+RDMd%Ngammas+4*RDMd%NBF_occ
 totMEM=8*totMEM       ! Bytes
 totMEM=totMEM*tol6    ! Bytes to Mb  
 if(totMEM>thousand) then  ! Mb to Gb
  write(msg,'(a,f10.3,a)') 'Mem. required for storing RDMd object   ',totMEM*tol3,' Gb'
 elseif(totMEM<one) then   ! Mb to Kb
  write(msg,'(a,f10.3,a)') 'Mem. required for storing RDMd object   ',totMEM*thousand,' Kb'
 else                      ! Mb
  write(msg,'(a,f10.3,a)') 'Mem. required for storing RDMd object   ',totMEM,' Mb'
 endif 
 call write_output(msg)
 ! Allocate arrays
 allocate(RDMd%DM2_J(RDMd%NBF_occ*RDMd%NBF_occ))
 allocate(RDMd%DM2_K(RDMd%NBF_occ*RDMd%NBF_occ))
 allocate(RDMd%DM2_L(RDMd%NBF_occ*RDMd%NBF_occ))
 allocate(RDMd%Docc_gamma(RDMd%NBF_occ*RDMd%Ngammas)) 
 allocate(RDMd%DDM2_gamma_J(RDMd%NBF_occ*RDMd%NBF_occ*RDMd%Ngammas))
 allocate(RDMd%DDM2_gamma_K(RDMd%NBF_occ*RDMd%NBF_occ*RDMd%Ngammas)) 
 allocate(RDMd%DDM2_gamma_L(RDMd%NBF_occ*RDMd%NBF_occ*RDMd%Ngammas)) 
 allocate(RDMd%GAMMAs_old(RDMd%Ngammas))
 allocate(RDMd%DM2_iiii(RDMd%NBF_occ),RDMd%Dfni_ni(RDMd%NBF_occ)) 
 allocate(RDMd%occ(RDMd%NBF_occ),RDMd%chempot_orb(RDMd%NBF_occ))

end subroutine rdm_init
!!***

!!***
!!****f* DoNOF/rdm_free
!! NAME
!! rdm_free
!!
!! FUNCTION
!!  Free allocated arrays of the data type rdm_t 
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!  
!! CHILDREN
!!
!! SOURCE

subroutine rdm_free(RDMd)
!Arguments ------------------------------------
!scalars
 class(rdm_t),intent(inout)::RDMd
!Local variables ------------------------------
!scalars
!arrays
!************************************************************************

 deallocate(RDMd%GAMMAs_old)
 deallocate(RDMd%occ,RDMd%chempot_orb)
 deallocate(RDMd%DM2_iiii)
 deallocate(RDMd%DM2_J,RDMd%DM2_K,RDMd%DM2_L) 
 deallocate(RDMd%Docc_gamma,RDMd%Dfni_ni) 
 deallocate(RDMd%DDM2_gamma_J)
 deallocate(RDMd%DDM2_gamma_K)
 deallocate(RDMd%DDM2_gamma_L)

end subroutine rdm_free
!!***

!!***
!!****f* DoNOF/print_rdm
!! NAME
!! print_rdm
!!
!! FUNCTION
!!  Print the 2-RDM matrix allocated in rdm_t to the binary file DM2 
!!  Print the 1-RDM matrix allocated in rdm_t to the binary file DM1
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!  
!! CHILDREN
!!
!! SOURCE

subroutine print_rdm(RDMd,DM2_J,DM2_K,DM2_L)
!Arguments ------------------------------------
!scalars
 class(rdm_t),intent(inout)::RDMd
!arrays
 real(dp),dimension(RDMd%NBF_occ,RDMd%NBF_occ),intent(in)::DM2_J,DM2_K,DM2_L
!Local variables ------------------------------
!scalars
 integer::iorb,iorb1,iunit=312
!arrays

!************************************************************************

 ! Print the 2-RDM
 ! TODO: Missing terms for Nsingleocc>0 !
 open(unit=iunit,form='unformatted',file='DM2')
 do iorb=1,RDMd%NBF_occ
  if(dabs(RDMd%DM2_iiii(iorb))>tol8) write(iunit) iorb,iorb,iorb,iorb,RDMd%DM2_iiii(iorb) 
  do iorb1=1,iorb-1
   if(dabs(DM2_J(iorb,iorb1))>tol8) then
     write(iunit) iorb,iorb1,iorb,iorb1,DM2_J(iorb,iorb1)  
     write(iunit) iorb1,iorb,iorb1,iorb,DM2_J(iorb,iorb1)  
   endif
   if(dabs(DM2_K(iorb,iorb1))>tol8) then
    write(iunit) iorb,iorb1,iorb1,iorb,DM2_K(iorb,iorb1)
    write(iunit) iorb1,iorb,iorb,iorb1,DM2_K(iorb,iorb1)
   endif
   if(dabs(DM2_L(iorb,iorb1))>tol8) then
    write(iunit) iorb,iorb,iorb1,iorb1,DM2_L(iorb,iorb1)
    write(iunit) iorb1,iorb1,iorb,iorb,DM2_L(iorb,iorb1)
   endif
  enddo
 enddo
 write(iunit) 0,0,0,0,zero
 write(iunit) 0,0,0,0,zero
 close(iunit)

 ! Print the 1-RDM
 open(unit=iunit,form='unformatted',file='DM1')
 do iorb=1,RDMd%NBF_occ
  write(iunit) iorb,iorb,two*RDMd%occ(iorb)
 enddo
 write(iunit) 0,0,zero
 close(iunit)

 ! Print the FORM_occ file
 open(unit=iunit,form='formatted',file='FORM_occ')
 do iorb=1,RDMd%NBF_occ
  write(iunit,'(i5,f17.10)') iorb,two*RDMd%occ(iorb)
 enddo
 write(iunit,'(i5,f17.10)') 0,zero
 close(iunit)

end subroutine print_rdm
!!***

!!***
!!****f* DoNOF/print_swrdm
!! NAME
!! print_swrdm
!!
!! FUNCTION
!!  Print the spin-with 2-RDM matrix allocated in rdm_t to the binary file DM2 
!!  Print the spin-with 1-RDM matrix allocated in rdm_t to the binary file DM1
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!  
!! CHILDREN
!!
!! SOURCE

subroutine print_swrdm(RDMd)
!Arguments ------------------------------------
!scalars
 class(rdm_t),intent(inout)::RDMd
!arrays
!Local variables ------------------------------
!scalars
 integer::iorb,iorb1,iorb2,iorb3,iorb4,iorb5,iorb6,iorb7
 integer::iorbmin,iorbmax,NsdORBs,NBF2,NsdVIRT,iunit=312
 real(dp)::Delem
!arrays
 integer,allocatable,dimension(:)::coup
 real(dp),allocatable,dimension(:)::occ
!************************************************************************

 NBF2=2*RDMd%NBF_occ
 NsdORBs=RDMd%Nfrozen+RDMd%Npairs
 NsdVIRT=RDMd%NBF_occ-NsdORBs
 allocate(coup(NBF2),occ(NBF2))
 occ=zero

 ! Print the sw 1-RDM
 open(unit=iunit,file='swDM1')
 do iorb=1,RDMd%NBF_occ
  Delem=RDMd%occ(iorb)
  if(dabs(Delem)>tol8) then
   occ(2*iorb-1)=Delem
   occ(2*iorb)  =occ(2*iorb-1)
   write(iunit,'(f15.8,2i4)') occ(2*iorb-1),2*iorb-1,2*iorb-1
   write(iunit,'(f15.8,2i4)') occ(2*iorb),2*iorb,2*iorb
  endif
 enddo
 write(iunit,'(f15.8,2i4)') zero,0,0
 close(iunit)

 ! Print the sw 2-RDM
 ! TODO: Missing terms for Nsingleocc>0 !
 coup=-1
 do iorb=1,NsdORBs
  iorbmin=NsdORBs+RDMd%Ncoupled*(NsdORBs-iorb)+1
  iorbmax=NsdORBs+RDMd%Ncoupled*(NsdORBs-iorb)+RDMd%Ncoupled
  do iorb1=1,NsdVIRT
   iorb2=iorb1+NsdORBs
   if((iorbmin<=iorb2.and.iorb2<=iorbmax).and.(iorbmax<=RDMd%NBF_occ)) then
    coup(2*iorb-1) =iorb
    coup(2*iorb)   =iorb
    coup(2*iorb2-1)=iorb
    coup(2*iorb2)  =iorb
   endif
  enddo
 enddo
 open(unit=iunit,file='swDM2')
 do iorb=1,NBF2
  do iorb1=1,NBF2
   do iorb2=1,NBF2
    do iorb3=1,NBF2
     if((mod(iorb,2)==mod(iorb2,2)).and.(mod(iorb1,2)==mod(iorb3,2))) then
      !! Check for spinless indeces (used for PI_ii,kk)
      if(mod(iorb,2)==0) then
       iorb4=iorb/2
       iorb6=iorb2/2
      else
       iorb4=(iorb+1)/2
       iorb6=(iorb2+1)/2
      endif
      if(mod(iorb1,2)==0) then
       iorb5=iorb1/2
       iorb7=iorb3/2
      else
       iorb5=(iorb1+1)/2
       iorb7=(iorb3+1)/2
      endif
      Delem=ZERO
      !! SD
      ! Hartree
      if((iorb==iorb2).and.(iorb1==iorb3)) then
       Delem=half*occ(iorb)*occ(iorb1)
      endif
      ! Exchange
      if((iorb==iorb3).and.(iorb1==iorb2)) then
       Delem=Delem-half*occ(iorb)*occ(iorb1)
      endif
      !! PNOFi
      ! Hartree
      if((iorb==iorb2).and.(iorb1==iorb3).and.coup(iorb)==coup(iorb1)) then
       if(coup(iorb)/=-1) Delem=Delem-half*occ(iorb)*occ(iorb1)
      endif
      ! Exchange
      if((iorb==iorb3).and.(iorb1==iorb2).and.coup(iorb)==coup(iorb1)) then
       if(coup(iorb)/=-1) Delem=Delem+half*occ(iorb)*occ(iorb1)
      endif
      ! Time-inversion
      if((iorb4==iorb5).and.(iorb6==iorb7).and.(iorb/=iorb1.and.iorb2/=iorb3)) then
       if(coup(iorb)==coup(iorb2).and.coup(iorb)/=-1) then
        if(iorb4<=NsdORBs .or. iorb6<=NsdORBs) then
         if(iorb4==iorb6) Delem=Delem+half*occ(iorb)
         if(iorb4/=iorb6) Delem=Delem-half*dsqrt(occ(iorb)*occ(iorb2))
        else
         if(iorb4==iorb6) Delem=Delem+half*occ(iorb)
         if(iorb4/=iorb6) Delem=Delem+half*dsqrt(occ(iorb)*occ(iorb2))
        endif
       else
        if(RDMD%INOF==7) then
         if(RDMD%Ista==1) then
          Delem=Delem-two*((one-occ(iorb))*occ(iorb)*(one-occ(iorb2))*occ(iorb2))
         else
          Delem=Delem-half*dsqrt((one-occ(iorb))*occ(iorb)*(one-occ(iorb2))*occ(iorb2))
         endif
        endif
       endif
      endif
      ! Print the ^2D_ij,kl element
      if(abs(Delem)>tol8) then
       write(iunit,'(f15.8,4i4)') Delem,iorb,iorb1,iorb2,iorb3
      endif
      ! Done iorb,iorb1,iorb2,iorb3
     endif 
    enddo
   enddo
  enddo
 enddo
 write(iunit,'(f15.8,4i4)') zero,0,0,0,0
 close(iunit)
 
 deallocate(coup,occ) 

end subroutine print_swrdm
!!***

!!***
!!****f* DoNOF/print_orb_coefs
!! NAME
!! print_orb_coefs
!!
!! FUNCTION
!!  Print the orbital coefficients to a given file
!!
!! INPUTS
!!  COEF=Orbital coefs.
!!  name_file=Name of the file where the orb. coefs. are printed
!!
!! OUTPUT
!!
!! PARENTS
!!  
!! CHILDREN
!!
!! SOURCE

subroutine print_orb_coefs(RDMd,name_file,COEF,COEF_cmplx)
!Arguments ------------------------------------
!scalars
 class(rdm_t),intent(in)::RDMd
!arrays
 character(len=10)::name_file 
 real(dp),optional,dimension(RDMd%NBF_tot,RDMd%NBF_tot),intent(in)::COEF
 complex(dp),optional,dimension(RDMd%NBF_tot,RDMd%NBF_tot),intent(in)::COEF_cmplx
!Local variables ------------------------------
!scalars
 logical::cpx_mos=.false.
 integer::iorb,iorb1,iunit=312
!arrays

!************************************************************************

 if(present(COEF_cmplx)) cpx_mos=.true.
 ! Print the orb. coefs
 open(unit=iunit,form='formatted',file=name_file)
 do iorb=1,RDMd%NBF_tot
  do iorb1=1,(RDMd%NBF_tot/10)*10,10
   if(cpx_mos) then
    write(iunit,'(f14.8,9f13.8)') real(COEF_cmplx(iorb1:iorb1+9,iorb))
    write(iunit,'(f14.8,9f13.8)') aimag(COEF_cmplx(iorb1:iorb1+9,iorb))
   else
    write(iunit,'(f14.8,9f13.8)') COEF(iorb1:iorb1+9,iorb)
   endif
  enddo
  iorb1=(RDMd%NBF_tot/10)*10+1
  if(cpx_mos) then
    write(iunit,'(f14.8,*(f13.8))') real(COEF_cmplx(iorb1:,iorb))
    write(iunit,'(f14.8,*(f13.8))') aimag(COEF_cmplx(iorb1:,iorb))
  else
   write(iunit,'(f14.8,*(f13.8))') COEF(iorb1:,iorb)
  endif
 enddo
 close(iunit)

end subroutine print_orb_coefs
!!***

!!***
!!****f* DoNOF/print_orb_coefs_bin
!! NAME
!! print_orb_coefs_bin
!!
!! FUNCTION
!!  Print the orbital coefficients to the unformatted NO_COEF_BIN file
!!
!! INPUTS
!!  COEF=Orbital coefs.
!!
!! OUTPUT
!!
!! PARENTS
!!  
!! CHILDREN
!!
!! SOURCE

subroutine print_orb_coefs_bin(RDMd,COEF,COEF_cmplx)
!Arguments ------------------------------------
!scalars
 class(rdm_t),intent(in)::RDMd
!arrays
 real(dp),optional,dimension(RDMd%NBF_tot,RDMd%NBF_tot),intent(in)::COEF
 complex(dp),optional,dimension(RDMd%NBF_tot,RDMd%NBF_tot),intent(in)::COEF_cmplx
!Local variables ------------------------------
!scalars
 logical::cpx_mos=.false.
 integer::iorb,iorb1,iunit=312
!arrays

!************************************************************************
 
 if(present(COEF_cmplx)) cpx_mos=.true.
 ! Print the orb. coefs
 open(unit=iunit,form='unformatted',file='NO_COEF_BIN')
 do iorb=1,RDMd%NBF_tot
  do iorb1=1,RDMd%NBF_tot
   if(cpx_mos) then
    write(iunit) iorb,iorb1,COEF_cmplx(iorb,iorb1)
   else
    write(iunit) iorb,iorb1,COEF(iorb,iorb1)
   endif
  enddo
 enddo
 if(cpx_mos) then
  write(iunit) 0,0,zero
 else
  write(iunit) 0,0,complex_zero
 endif
 close(iunit)

end subroutine print_orb_coefs_bin
!!***

!!***
!!****f* DoNOF/print_gammas_old
!! NAME
!! print_gammas_old
!!
!! FUNCTION
!!  Print the GAMMAs_old vector allocated in rdm_t to the binary file GAMMAS
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!  
!! CHILDREN
!!
!! SOURCE

subroutine print_gammas_old(RDMd)
!Arguments ------------------------------------
!scalars
 class(rdm_t),intent(inout)::RDMd
!arrays
!Local variables ------------------------------
!scalars
integer::igamma,iunit=312
!arrays

!************************************************************************

 ! Print the GAMMAS_old
 open(unit=iunit,form='unformatted',file='GAMMAS')
 do igamma=1,RDMd%Ngammas
  write(iunit) igamma,RDMd%GAMMAs_old(igamma)
 enddo
 write(iunit) 0,zero
 close(iunit)

end subroutine print_gammas_old
!!***

end module m_rdmd
!!***
