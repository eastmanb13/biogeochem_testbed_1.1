!====================================================================================================
!
! File:    corpse_variable.f90
!
! Purpose: defines/allocates variables for CORPSE model
!
!   MODULE corpsedimension
!   MODULE corpsevariable with subroutine alloc_corpsesvariable
!
! Contact: Melannie Hartman
!          melannie@ucar.edu
!
! History: 
!          12/28/2015 - Created 
!          01/04/2016 - Compiled
!====================================================================================================

MODULE corpsedimension

    implicit none

    !Carbon species: Labile (1), Recalcitrant (2), and Dead microbe C (3)
    integer,parameter::LABILE=1
    integer,parameter::RECALCTRNT=2
    integer,parameter::DEADMICRB=3
    integer,parameter::nspecies=3
    
    !Maximum number of soil layers
    integer,parameter::max_lev=2
    integer,parameter::num_lyr=1     !Number of soil layers
    
    real,parameter::DENS_H2O=1000.0
    real,parameter::layerThickness=0.15
    !!integer, parameter :: NHOURS = 24  ! Number of time steps per day when running hourly
    
END MODULE corpsedimension
!====================================================================================================

MODULE corpsevariable

    USE corpsedimension
    USE corpse_soil_carbon
    
    implicit none
    
    !Data container to store all the outputs while it runs
    !nlines = number of timesteps written to output file
    type outputvars
        real,allocatable :: litterC(:,:)          ! dimensions nspecies, nlines
        real,allocatable :: protectedC(:,:)       ! dimensions nspecies, nlines
        real,allocatable :: livingMicrobC(:)      ! dimension nlines
        real,allocatable :: CO2(:)                ! dimension nlines
        real,allocatable :: totalC(:)             ! dimension nlines
        real,allocatable :: Rtot(:,:)             ! dimensions nspecies, nlines
        real,allocatable :: protectedProd(:,:)    ! dimensions nspecies, nlines
        real,allocatable :: Ts(:)                 ! dimension nlines
        real,allocatable :: thetaLiq(:)           ! dimension nlines
        real,allocatable :: thetaFrzn(:)          ! dimension nlines
        real,allocatable :: fT(:)                 ! dimensions nlines (Placeholder, not currently written to output -mdh 11/27/2017) 
        real,allocatable :: fW(:)                 ! dimensions nlines  
        real,allocatable :: time(:)               ! dimension nlines
        real             :: cwd2co2(366)          ! dimension 1..days in a year (added 2/6/2017)
        integer :: linesWritten=0
        integer,allocatable::ncohorts(:)
        ! Annual means for the simulation (added 3/28/2016)
        ! These are updated in subroutine corpse_caccum.  
        integer :: nYear=0                        ! counter for current year being simulated
        real,allocatable :: litterCan(:,:)        ! dimensions nspecies, nlines
        real,allocatable :: protectedCan(:,:)     ! dimensions nspecies, nlines            
        real,allocatable :: livingMicrobCan(:)    ! dimensions nlines
        real,allocatable :: CO2an(:)              ! dimensions nlines
        real,allocatable :: totalCan(:)           ! dimensions nlines
        real,allocatable :: TsAn(:)               ! dimensions nlines
        real,allocatable :: thetaLiqAn(:)         ! dimensions nlines               
        real,allocatable :: thetaFrznAn(:)        ! dimensions nlines           
        real,allocatable :: fTAn(:)               ! dimensions nlines (Placeholder, not currently written to output -mdh 11/27/2017) 
        real,allocatable :: fWAn(:)               ! dimensions nlines      
        real,allocatable :: timeAn(:)             ! dimensions nlines               
    end type outputvars

    
    !Grid cell type to hold all grid-cell specific values
    type gridcell
        real,allocatable,dimension(:):: dz, z                    ! Soil layer thickness and depth (m) (dimension = # of soil layers, num_lyr)
        type(soil_carbon_pool),dimension(:),allocatable:: soil   ! CORPSE soil carbon pool array representing soil layers (dimension = # of soil layers, num_lyr)
        type(soil_carbon_pool):: litterlayer                     ! CORPSE soil carbon pool representing the litter layer
        type(outputvars),dimension(:),allocatable:: soil_outputs ! Container for output variables (dimension = # of soil layers, num_lyr)
        type(outputvars):: litterlayer_outputs                   ! Container for output variables
        ! Variables for storing diagnostic values generated by the update_pool subroutine
        real:: fast_C_loss_rate
        real:: slow_C_loss_rate
        real:: deadmic_C_loss_rate
        real:: CO2prod
        real:: deadmic_produced
        real,dimension(nspecies):: protected_produced
        real,dimension(nspecies):: protected_turnover_rate
        real,dimension(nspecies):: C_dissolved,deposited_C
    end type gridcell
    
    
    !Holds the netcdf variable identifiers
    type ncvars
        integer :: dimid_time,dimid_species,dimid_depth,dimid_lat,dimid_lon  ! NetCDF dimension ids
        integer :: lonid, latid              ! NetCDF variable ID for latitude and longitude
        integer :: timeid                    ! NetCDF variable ID for simulation time (years)
        integer :: dayid                     ! NetCDF variable ID for simulation day of year
        integer :: soilProtectedCid(nspecies)! NetCDF variable ID for protected soil carbon
        integer :: soilCid(nspecies)         ! NetCDF variable ID for unprotected soil carbon
        integer :: litterCid(nspecies)       ! NetCDF variable ID for unprotected litter layer carbon
        integer :: Tsid                      ! NetCDF variable ID for soil temperature
        integer :: thetaLiqid                ! NetCDF variable ID for liquid soil moisture
        integer :: thetaFrznid               ! NetCDF variable ID for frozen soil moisture
!       integer :: fTid                      ! NetCDF variable ID for liquid soil moisture
        integer :: fWid                      ! NetCDF variable ID for frozen soil moisture
        integer :: soil_livingMicrobeid      ! NetCDF variable ID for living soil microbe carbon
        integer :: litter_livingMicrobeid    ! NetCDF variable ID for living litter layer microbe carbon
        integer :: soil_CO2id                ! NetCDF variable ID for soil heterotrophic respiration C 
        integer :: litter_CO2id              ! NetCDF variable ID for litter layer heterotrophic respiration C
        integer :: ncohortsid                ! NetCDF variable ID for number of cohorts in the litter or soil pool
        integer :: litter_totalCid           ! NetCDF variable ID for total carbon in litter layer
        integer :: soil_totalCid             ! NetCDF variable ID for total carbon in soil layer
        integer :: depthid                   ! NetCDF variable ID for soil depth (meters)
        integer :: cellid                    ! NetCDF variable ID for for cellid(nlon,nlat)
        integer :: landareaid                ! NetCDF variable ID for land area
        integer :: maskid                    ! NetCDF variable ID for cellMissing(nlon,nlat)
        integer :: igbpid                    ! NetCDF variable ID for IGBP_PFT(nlon,nlat)

        !! Currently unused IDs
        integer :: Rtotid                    ! NetCDF variable ID for
        integer :: protectedProdid           ! NetCDF variable ID for
        integer :: leachingid                ! NetCDF variable ID for
        integer :: litterleachingid          ! NetCDF variable ID for
        integer :: leaching_divergenceid     ! NetCDF variable ID for
        integer :: flowid                    ! NetCDF variable ID for
        integer :: DOCid                     ! NetCDF variable ID for
        integer :: litterlayerDOCid          ! NetCDF variable ID for
    end type ncvars
    type(ncvars)::varids
    integer::ncid_corpse
    
    integer::namelistunit=123
    
    !Parameters for this test model run, in namelist file
    namelist /CORPSE_casa_nml/ initial_C, &
                               exudate_npp_frac, &
                               rhizosphere_frac, &
                               litter_option
    
    real:: initial_C(nspecies)             ! initial carbon pools for litter and soil layers
    !!real:: annual_exudate_input(nspecies)
    real:: exudate_npp_frac(nspecies)
    real:: rhizosphere_frac
    integer:: litter_option
    real::T           !soil temperature (K)
    
    integer::recordtime  !How often to record output data (# of timestep(hours))
    !!integer::maxSteps  !Maximum number of CORPSE time steps in the simulation.   
                         !This is now computed by CASA as total number of simulation years * 365 * #timesteps per day. 
                         !It is used only to dimension output variables
    integer::timestep    !What time step the model is on (# of timesteps)
    real:: dt            !timestep in years (1/(24*365) for hourly timestep, 1/365 for daily timestep)
    
    type(gridcell),dimension(:),allocatable:: pt

    integer:: verbose = 0

    real, parameter :: MISSING_VALUE = 1.e+36
    integer, parameter :: MISSING_INT = -9999

    character(len=100) :: filename_corpsenamelist !! file CORPSE namelist parameter file
    character(len=100) :: sPtFileNameCORPSE
    integer :: iptToSave_corpse

 
CONTAINS

!----------------------------------------------------------------------------------------------------
! Allocate memory for allocatable dimensions.
! These include the number of grid cells and the number of soil layers per grid cell.
!
SUBROUTINE alloc_corpsevariable(mp)
    USE corpsedimension
    implicit none
    integer, INTENT(IN) :: mp    ! number of grid points

    ! Local Variables
    integer::ipt, jj

    !Allocate memory for the grid of mp points
    allocate(pt(mp))

    do ipt = 1, mp
        ! Allocate memory for the number of soil layers.
        ! There is always only one litter layer per grid cell so that does not require allocation.
        allocate(pt(ipt)%z(num_lyr))
        allocate(pt(ipt)%dz(num_lyr))
        allocate(pt(ipt)%soil(num_lyr))
        allocate(pt(ipt)%soil_outputs(num_lyr))
    
        pt(ipt)%dz=layerThickness      !Soil layer thickness (constant in this case, but can vary between layers)
        pt(ipt)%z=0.0
        ! Calculate soil layer levels based on thickness of each layer
        if (num_lyr > 1) then
            print *, 'Uncomment the code for num_lyr > 1 alloc_corpsevariable'
            stop 
        !   do jj=2,num_lyr
        !       pt(ipt)%z(jj) = pt(ipt)%z(jj-1) + pt(ipt)%dz(jj-1)
        !   enddo
        endif
    enddo

END SUBROUTINE alloc_corpsevariable


END MODULE corpsevariable
!====================================================================================================