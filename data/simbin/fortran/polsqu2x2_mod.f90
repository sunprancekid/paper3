!*************************************************************
!** Programmer: Matthew A Dorsey 
!**				Dr. Carol Hall Research Laboratory
!**				Chemical and Biomolecular Engineering 
!**				North Carolina State University 
!**
!** 
!** Date: 05/11/2021
!** 
!**	Purpose: simulate a rigid, polarized square using four 
!**			 spheres. all spheres are bonded to one another, 
!**			 in order to maintain their formation. one side 
!**			 of the sphere is polarized, while the other 
!**			 maintains a neutral "charge". spheres which share 
!** 		 opposite charges interact via an attractive, square 
!**			 well potential. spheres which share different 
!**			 charges attract via a repuslive, square shoulder 
!**			 potential. the potential between two charged 
!**			 spheres consists of three discontinuities defined
!**			 by a well depth epsilon, where by the well depths
!**			 increase progressively as the pair get closer to
!**			 the hard sphere diameter.
!**
!*************************************************************

module polarizedsquaremodule
implicit none 
save 

! TO DO: create looping function which loops through an type(id) variable



!*************************************************************
!** GLOBAL CONSTANTS
!*************************************************************

! ** DMD constants *******************************************
integer, parameter :: dbl = selected_real_kind (32) ! integer which determines precision of real numbers
real(kind=dbl), parameter :: pi = 3.141592653589793238
real(kind=dbl), parameter :: twopi = 2. * pi
real(kind=dbl), parameter :: halfpi = pi / 2.
real(kind=dbl), parameter :: bigtime = 1e10 ! unreasonably large time
integer, parameter :: NONZERO_EXITCODE = 85
integer, parameter :: CHECKPOINT_EXITCODE = 0
! ** colors (rbg format) *************************************
character(len=12), parameter :: red = ' 1 0.15 0.15'
character(len=12), parameter :: blue = ' 0.1 1 0.3'
character(len=12), parameter :: green = ' 0 0 1'
character(len=12), parameter :: orange = ' 1 0 0.64'
character(len=12), parameter :: purple = ' 1 1 0'
character(len=15), parameter :: white = ' 0.75 0.75 0.75'


! ** ensemble ************************************************
integer, parameter :: ndim = 2 ! number of dimensions 
integer, parameter :: mer = 4 ! number of hardspheres which make one cube
real(kind=dbl), parameter :: excluded_area = 1. + ((3. / 4.) * pi) ! area occupied by one 2x2 square
real(kind=dbl), parameter :: tol = 0.001 ! amount by which to allow mistakes from numberical integration (i.e. overlap and bcs)
integer, parameter :: debug = 0 ! debugging status: 0 == off, 1 == on, 2 == extra on 


! ** SIMULATION SETTINGS *************************************
! boolean and default constants for values used to initia-
! lize the simulation

! ** PARAMETERS **
! DENSITY
! density as area fraction
real(kind=dbl), parameter :: default_areafraction = 0.6
real(kind=dbl), parameter :: max_areafraction = 0.83
real(kind=dbl), parameter :: min_areafraction = 0.01
real(kind=dbl) :: eta = default_areafraction
logical :: use_default_areafraction = .true.

! NUMBER OF PARTICLES
! number of lattice cells in each dimension for square 
! simulation box
integer, parameter :: default_cell = 8
!integer, parameter :: max_cell = 100
integer, parameter :: min_cell = 2
integer :: cell = default_cell ! number of lattice cells
logical :: use_default_cell = .true.

! NUMBER OF PARTICLES
! mol fraction of A-chirality squares in system
real(kind=dbl), parameter :: default_achairality = 1.0
real(kind=dbl), parameter :: max_achairality = 1.0
real(kind=dbl), parameter :: min_achirality = 0.0
real(kind=dbl) :: xa = default_achairality
logical :: use_default_achairality = .true.

! TEMPERATURE

! SIMULATION LENGTH
! length of simulation defined as the number of collision events
integer, parameter :: default_events = 1e8 ! default number of events
integer, parameter :: min_events = 0
integer :: total_events = default_events
logical :: use_default_events = .true.

! ANNEALING 
real(kind=dbl), parameter :: default_frac = 0.95 
! fractional amount by which to reduce the temperarture 
! of the annealing simulation
logical, parameter :: default_annealing_status = .false.
! default annealing status used for simulation
logical :: annealing_status = default_annealing_status
! boolean that determines if annealing is turned on
real(kind=dbl) :: anneal_frac = default_frac 
logical :: use_default_frac = .true.

! EQUILIBRIUM 
! simulation length until equilibrium has been established


! ** DEPENDENCIES **
integer :: cube ! number of cubes in the system
integer :: mols ! number of hard spheres 
integer :: na, nb ! number of a-chirality, b-chirality squares
real(kind=dbl) :: region ! length of simulation box in each dimension
real(kind=dbl) :: area ! area of simulation box 
real(kind=dbl) :: density ! number density of particles
integer :: event_equilibrium ! length of simulation after equilibriation
integer :: event_equilibriate ! length of simulation before equilibriation
integer :: event_reschedule ! events between complete event rescheduling
integer :: event_average ! events between property averaging
integer :: propfreq ! frequency of property calculations
integer :: milestonecheck_freq ! frequency to check milestoning properties



! ** SQUARE SETTINGS *****************************************
! ** defines physics used to model dynamics of square particles
real(kind=dbl), parameter :: tempfinal = 0.0025 ! final system temperature set point 
real(kind=dbl), parameter :: sigma1 = 1.0 ! distance from sphere center to first discontinuity (diameter of hardsphere)
real(kind=dbl), parameter :: sigma2 = 1.15 * sigma1 ! distance from sphere center to second discontinuity
real(kind=dbl), parameter :: sigma3 = 1.4 * sigma1 ! distance from sphere center to third discontinuity
real(kind=dbl), parameter :: epsilon1 = 1.0000 ! reduced energy parameter
real(kind=dbl), parameter :: epsilon2 = 0.8259 * epsilon1 ! depth of innermost well
real(kind=dbl), parameter :: epsilon3 = 0.3146 * epsilon1 ! depth of outermost well
real(kind=dbl), parameter :: delta = 0.015 ! half the bond length
real(kind=dbl), parameter :: exittemp = 0.01 ! final system temperature 
!*************************************************************
real(kind=dbl), parameter :: sg1sq = sigma1 ** 2
real(kind=dbl), parameter :: sg2sq = sigma2 ** 2
real(kind=dbl), parameter :: sg3sq = sigma3 ** 2
real(kind=dbl), parameter :: inbond = sigma1 - delta ! inner bond distance
real(kind=dbl), parameter :: onbond = sigma1 + delta ! outer bond distance
real(kind=dbl), parameter :: icbond = sqrt(2 * sigma1) - delta ! inner cross bond distance
real(kind=dbl), parameter :: ocbond = sqrt(2 * sigma1) + delta ! outer cross bond distance

! ** andersen thermostat *************************************
! assigned system temperature, used to initialize the velocity
! of simulation particles
real(kind=dbl), parameter :: default_temperature = 3.0
real(kind=dbl), parameter :: max_temperature = 10.
real(kind=dbl), parameter :: min_temperature = 0.001
logical :: use_default_temperature = .true.
logical :: thermostat = .false. ! anderson thermostat status: .false. == off, .true. == on
real(kind=dbl), parameter :: default_thermostat_freq = 0.2
! default frequency that particles should experience thermostat ghost collisions
real(kind=dbl) :: thermal_conductivity = 200.0 ! the thermal conductivity of the hardsphere system [THIS VALUE HAS NOT BEEN VERIFIED!!]
! TODO :: specify temperature when the thermostat is turned on
! TODO :: adjust thermostat frequency calculations to per particle
!   so that the frequency is constant across simulations of different sizes
! TODO :: add external field methods

! ** external field ******************************************
logical :: field = .false. ! boolean controlling stochastic external field
logical :: field_rotation = .false. ! boolean controlling field rotation, if field is on
logical :: field_toggel = .false. ! boolean controlling field toggeling, if field is on
real(kind=dbl), parameter :: default_field_stength = 0.5
! default external field strength, if field is turned on
real(kind=dbl), parameter :: default_field_angvel = 200.
! default external field rotational velocity, if the field / field rotation is turned on
! real(kind=dbl), parameter :: default_field_togfreq
! default external field switching frequency, if the field / field toggeling is turned on

! ** order parameters ****************************************
integer, parameter :: orderlength = 15
real(kind=dbl), parameter :: orderwidth = sigma3


! ** EFFICIENCY TECHNIQUES ***********************************
! ** cell + neighbor list

! PARAMETERS
! maximum number of particles accessible to list 
integer, parameter :: nbrListSizeMax = 100 

! calculated / target average number of neighbors in list
integer, parameter :: default_nbrListSize = 8
integer :: nbrListSize
logical :: use_default_nbrListSize = .true.

! integer used for determing the max displacement required for a neighborlist update
real(kind=dbl), parameter :: default_nbrRadiusMinInt = 3.0 
real(kind=dbl) :: nbrRadiusMinInt = default_nbrRadiusMinInt 
logical :: use_default_nbrRadiusMinInt = .true.

! DEPENDENCIES
real(kind=dbl) :: nbrRadiusMin ! minimum required radius
real(kind=dbl) :: nbrRadius ! radius of neighborlist
real(kind=dbl) :: nbrDispMax ! max particle displacement before a neighborlist update is required
integer :: nCells ! number of cells in one dimension, cell length cannot be shorter than the nerighbor radius
real(kind=dbl) :: lengthCell ! legnth of each cell in one dimension, must be greater than the square well length (sig2)


! ** FILE MANAGEMENT *****************************************
! parameters for file_io type
integer, parameter :: max_charlength = 50 ! maximum number of characters for any string
logical, parameter :: default_status = .true. ! default file writing status if none is provided
integer, parameter :: init_iounit = 10 ! first io unit used in creating files
integer :: curr_iounit = init_iounit ! iounit assign to next file that is created

type file_io
    logical :: iostatus
    integer :: iounit
    character(len=max_charlength) :: filename
end type file_io

type(file_io) :: fp_io ! file io for false position
type(file_io) :: vel_io ! file io for velocity
! type(file_io) :: c_i

! TODO :: initialize file names and units
character(len=10), parameter :: default_jobid = 'polsqu2x2' ! jobid if none is provided
character(len=max_charlength) :: jobid ! job id
character(len=10), parameter :: default_simid = 'test' ! simulation id if none is provided
character(len=max_charlength) :: simid ! simid
! files and files names
character(len=max_charlength) :: fp_savefile ! save file containing all false position vectors 
character(len=max_charlength) :: v_savefile ! save file containing all velocity vectors 
character(len=max_charlength) :: c_savefile ! save file containing chiraliry description of each grouping
character(len=max_charlength) :: sim_savefile ! save file containing all simulation state 
character(len=max_charlength) :: anneal_savefile ! save file containing the status of the annealing simulation
character(len=max_charlength) :: ms_savefile ! save file containing parameters for milestoning
integer :: saveiounit = 11 
integer :: simiounit = 12
integer :: coorsphiounit = 13
integer :: coorsquiounit = 14
integer :: reportiounit = 15
integer :: annealiounit = 16
integer :: opiounit = 17
integer :: mmiounit = 18


! ** animation settings *************************************
integer :: moviesph = 0 ! movie making status of simulation as spheres: 0 == off, 1 == on
integer :: moviesqu = 1 ! movie making status of simulation as squares: 0 == off, 1 == on
real(kind=dbl) :: squmovfreq = 200.0 ! frequency to take snapshots of movies [reduced seconds]
real(kind=dbl) :: sphmovfreq = 200.0 ! frequency to take snapshots of sphere movies
! TODO :: adjust movie making so that square and sphere movies can happen at different frequencies



!*************************************************************
!** GLOBAL TYPES: data constructions for OOP
!*************************************************************

type :: vec 
    real(kind=dbl), dimension(ndim) :: d ! dimension of the field
end type vec

type :: position 
    real(kind=dbl), dimension(ndim) :: r ! vector describing the position of one sphere
end type position 

type :: velocity
    real(kind=dbl), dimension(ndim) :: v ! vector describing the velocity of one sphere 
end type 

type :: id
    integer :: one, two 
end type

type :: event 
    real(kind=dbl) :: time 
    integer :: type
    type(id) :: partner 
end type event 

type :: percolation_parameters ! #percy
    logical :: visited ! logical value that determines if each particle has already been considered as a
    integer :: cluster ! the cluster that the particle belongs to (null if it has not yet been assigned a cluster)
    type(id) :: pnode ! node that is connected to the particle via an edge
    type(position) :: rvec ! vector that points from the cluster root node to the node in question
end type percolation_parameters

type :: particle
    type(position) :: fpos ! false location of sphere 
    type(velocity) :: vel ! velocity of sphere
    integer :: pol ! polarization of sphere (0 = neutral, -1 = negative, 1 = positive)
    type(event) :: schedule ! next event for sphere 
    type(id), dimension(nbrListSizeMax) :: upnab, dnnab ! uplist and downlist neightbors with nbrRadius distance used for event scheduling
    type(id), dimension(orderlength) :: orderlist ! list of oppositely charged pairs within orderwidth distance used for calculating order parameters 
    type(percolation_parameters) :: percy ! #percy
end type particle

type :: group
    type(particle), dimension(mer) :: circle ! each group is made of mer circles 
    integer :: chai ! integer describing the chiraliry of each square grouping 
    ! TO DO: add string describing each circle?
end type group

type :: property
    real(kind=dbl) :: value, sum, sum2, equilavg, equilstd
    integer :: count, equilibcount
end type property

type :: node 
    integer :: rnode, lnode, pnode
end type node 



!*************************************************************
!** GLOBAL VARIABLES
!*************************************************************

! simulation settings
! ** debugging status
! integer :: debug = default_debug_status
! ** simulation molecules ************************************ 
type(group), dimension(:), allocatable :: square ! square groupings plus ghost event
! ** simulation parameters ***********************************
real(kind=dbl) :: timenow ! current length of simulation 
real(kind=dbl) :: timeperiod ! current length of period 
real(kind=dbl) :: ghostrate ! frequency of ghost collision 
real(kind=dbl) :: tempset = default_temperature ! current system temperature set point 
integer :: n_events, n_col, n_ghost, n_thermostat, n_field, n_bond, n_hard, n_well ! event counting
integer :: ghost ! downlist, uplist, and ghost event participants
integer :: anneal ! number of times the simulation has reduced the temperature
! ** simulation properties ***********************************
type(property) :: te ! total energy 
type(property) :: ke ! kinetic energy 
type(property) :: pot ! potential energy 
type(property) :: temp ! temperature
type(property) :: pv ! accumulation
type(property) :: z ! compressibility factor
type(property), dimension(ndim) :: lm ! linear momentum in each dimension
type(property) :: poly1 ! polyermization with one molecule order parameter
type(property) :: poly1aa ! polymerization of a-chirality squares with different a-chirality squares
type(property) :: poly1abba ! polymerization of squares with oppsosite chirality squares
type(property) :: poly1bb ! polymerization of b-chirality squares with different b-chirality squares
type(property) :: h2ts ! head to tail - same order parameter 
type(property) :: h2to ! head to tail - opposite order parameter
type(property) :: anti ! anti-parallel order parameter
type(property) :: poly2 ! polymerization with two molecules order parameter
type(property) :: full ! fully-assembled order parameter
type(property) :: fulls ! fully assembled order parameter for same chiralities 
type(property) :: fullo ! fully assembled order parameter for same and opposite chiralities
type(property) :: percy ! percolation order parameter
type(property) :: nclust ! number of clusters identified by percolation algorithm 
type(property) :: nematic ! nematic order parameter between all squares
type(property) :: allign
! ** efficiency methods **************************************
real(kind=dbl) :: dispTotal ! displacement of fastest particle between neighborlist updates
logical :: nbrnow ! update neighbor list?
type(node), dimension(:), allocatable :: eventTree ! binary tree list used for scheduling collision events
integer :: rootnode ! pointer to first node of binary tree using for scheduling collision events
real(kind=dbl) :: tsl, tl ! used for false positioning method: time since last update and time of last update
! ** andersen thermostat *************************************
real(kind=dbl) :: thermostat_freq, thermostat_period
type(event) :: thermostat_event ! thermostat ghost collision event 
! ** stochastic external field *******************************
real(kind=dbl) :: external_field_strength = default_field_stength
real(kind=dbl) :: external_field_angvel = default_field_angvel
real(kind=dbl) :: field_impulse, field_freq, field_period
type(event) :: field_event ! external field ghost collision event 
type(vec) :: field_ori ! initial orientation of the field
! ** markovian milestoning ***********************************
logical :: milestone ! boolean that determintes whether milestoning procedure is on or off
integer :: boundary_index ! index assigned to state of milestone denoting the most recent boundary
! that the simulation has collided with (0 == no index, 1 == lower boundary, 2 == upper boundary)
real(kind=dbl) :: upper_nematic_boundary ! value of the upper nematic boundary
real(kind=dbl) :: lower_nematic_boundary ! value of the lower nematic boundary
integer :: n_ul ! number of times that the cell collides with the upper boundary 
! after having collided with the lower boundary 
integer :: n_uu ! number of times that the cell collides with the upper boundary
! after having collided with the upper boundary
integer :: n_ll ! number of times that the cell collides with the lower boundary
! after having collided with the lower boundary
integer :: n_lu ! number of times that the cell collides with the lower boundary
! after having collided with the upper boundary 
real(kind=dbl) :: t_u ! amount of time that the simulation is assigned to the upper boundary
real(kind=dbl) :: t_l ! amount of time that the simulation is assigned to the lower boudnary



!*************************************************************
!** GLOBAL METHODS
!*************************************************************

contains 

! loop through single simulation event
function single_step () result (stop)
    logical :: stop 
    integer :: i, m ! indexing parameters
    type (event) :: next_event ! length of step forward in time 
    type(id) :: a, b ! event partners
    integer :: movno = 0 ! used for movie making

    stop = .false.

    if (nbrnow) then 
        call build_neighborlist
    endif

    ! find next / soonest occuring event 
    ! integrate the system forward in time 
    call forward (next_event, a, b)

    ! process next event 
    if (a%one == (cube + 1)) then 
        ! thermostat ghost collision event 
        call thermostat_ghost_collision (tempset)
        thermostat_event = predict_ghost(thermostat_period) ! schedule next ghost collision
        call addbranch (eventTree, mols+1)
    else if (a%one == (cube + 2)) then 
        ! field ghost collision event
        call field_ghost_collision (field_impulse)
        field_event = predict_ghost(field_period)
        call addbranch (eventTree, mols+2)
    else ! collision event 
        call collide (a, b, next_event, pv%value)
        call collision_reschedule (a, b)
        call update_orderlist(a, b)
        ! ** Compressibility Factor **********************************
        call accumulate_properties (pv, 2)
    endif

    ! completely reschedule calander
    if (mod(n_events, event_reschedule) == 0) then 
        call complete_reschedule ()
        if (check_boundaries()) call restart ()
    end if 

    ! ! markovian milestoning check
    ! if (mod(n_events, milestonecheck_freq) == 0) then 
    !     ! determine if simulation has reach any of the cell boundaries
    !     if (check_milestoning_boundaries ()) then 

    !         ! apply the procedure for reversing a collision with a cell boundary
    !         call milestone_boundary_collision() 
    !         call close_files()
    !         call exit()
    !     endif

    !     ! if the simulation hasn't reached a bonudary
    !     ! save the state of the simulation and continue 
    !     call save()

    ! end if

    ! property calculations
    if (mod(n_events, propfreq) == 0) then 
        call calculate_poperties ()
    end if 

    ! report and reset properties to user information
    if ((mod(n_events, event_average) == 0) .and. (n_events /= 0)) then 
        call report_properties ()
        call save()
    end if 

    ! take snap shot for movie generation as spheres
    if (((moviesph == 1) .or. (moviesqu == 1)) .and. (real(movno) < (timenow / squmovfreq))) then 
        if (moviesph == 1) call record_position_circles ()
        if (moviesqu == 1) call record_position_squares ()
        movno = movno + 1
    end if

    ! TODO convert end of simulation calculation to mod function
    if (mod(n_events,total_events) == 0) then
        call close_files() 
        if (annealing_status) then 
            ! if the annealing status is turned on
            ! increment the annealing integer, which tracks how many times
            ! the system temperature as been decrimented    
            anneal = anneal + 1 
            ! decriment the sytstem temperature 
            call adjust_temperature (tempset) 
        endif
        call update_positions()
        ! TODO: if the milestone has not been reached, add time to the current index
        call save () ! save the final state of the simulation 
        call exit (CHECKPOINT_EXITCODE) ! if a boundary has not been reach, repeat the simulation
    end if 
end function single_step

! SIMULATION SETTINGS FUNCTIONS

! subroutine set_debug_status (status)
!     implicit none 
!     integer, intent(in), optional :: status 
!     ! integer determining the boolean that should be assigned
!     ! to the debuggin status
!     logical :: use_default = .true.

!     if (present(status)) then 
!         ! check that the integer passed to the method is within the valid range
!         if ((status < 0) .or. (status > 2)) then 
!             1 format (" set_debug_status :: value passed to method (", I3,") is outside valid range.")
!             write (*,1) status
!         else 
!             use_default = .false.
!             debug = status
!             2 format(" set_debug_status :: debugging status was set to (", I3,").")
!             write (*,2) debug
!         endif
!     endif

!     if (use_default) then 
!         ! assign the default debugging status
!         debug = default_debug_status
!         3 format(" set_debug_status :: default debugging status was assigned (debug = ", &
!             I4,").")
!         write (*,3) debug
!     endif

! end subroutine set_debug_status

subroutine initialize_simulation_settings (af, ac, e, nc)
    implicit none 
    real, intent(in), optional :: af ! area fraction
    real, intent(in), optional :: ac ! a-chirality
    integer, intent(in), optional :: e ! events 
    integer, intent(in), optional :: nc ! number of cells

    ! load any arguments that were passed to the method
    if (present(nc)) then 
        if (set_cells(nc)) then 
            use_default_cell = .false.
        endif
    endif
    write (*,"(' initialize_settings :: lattice cells set to ', I3)") cell

    if (present(af)) then 
        if (set_areafraction(af)) then 
            use_default_areafraction = .false.
        endif
    endif
    write (*,"(' initialize_settings :: area fraction set to ', F5.3)") eta

    if (present(ac)) then 
        if (set_achirality(ac)) then 
            use_default_achairality = .false.
        endif
        write (*,*) "initialize_settings :: a-chirality fraction of squares was specified."
    endif 
    write (*,"(' initialize_settings :: a-chirality fraction set to ', F5.3)") xa

    if (present(e)) then 
        if (set_events(e)) then 
            use_default_events = .false.
        endif 
    endif
    write (*,"(' initialize_settings :: simulation events set to ', F5.1, ' million')") (real(total_events) / 1e6)

    ! once settings have been loaded, initialize the relevant parameters
    ! parameters for initializing system
    cube = cell ** 2 ! number of cubes
    mols = cube*mer ! number of hardspheres
    na = cube * xa ! number of a chirality cubes 
    area = (excluded_area * cube) / eta ! area of simulation box
    region = sqrt (area) ! length of simulation box wall
    density = real(cube) / area ! number density of cubes

    ! parameters for running simulation
    event_equilibrium = 0.1 * total_events
    event_equilibriate = 0.9 * total_events 
    event_reschedule = 10000 
    event_average = 1000000
    propfreq = 1000000 
    milestonecheck_freq = 1000 

    ! turn on cell + neighbor list
    call initialize_cell_neighbor_list()
end subroutine initialize_simulation_settings

subroutine initialize_cell_neighbor_list() 
    implicit none 

    nbrRadiusMin = (nbrRadiusMinInt / (nbrRadiusMinInt - 1)) * (sigma3 - (sigma1 / nbrRadiusMinInt)) ! minimum required radius
    nbrRadius = max(sqrt((real(nbrListSize) / (real(mer) * density)) * (1.0 / pi)), nbrRadiusMin) ! radius of neighborlist
    nbrDispMax = (nbrRadius - sigma1) / nbrRadiusMinInt ! max particle displacement before a neighborlist update is required
    nCells = floor (region / nbrRadius) ! number of cells in one dimension, cell length cannot be shorter than the nerighbor radius
    lengthCell = region / real (nCells) ! legnth of each cell in one dimension, must be greater than the square well length (sig2)
end subroutine initialize_cell_neighbor_list

function set_areafraction(val) result (success)
    implicit none
    logical :: success ! used to determine if operation was successful
    real(kind=dbl), parameter :: t = tol 
    ! tolerance used for comparing real values
    real(kind=dbl), parameter :: max_val = max_areafraction
    ! maximum allowable value value that user can assign
    real(kind=dbl), parameter :: min_val = min_areafraction
    ! minimum allowable value that user can assign
    real(kind=dbl), parameter :: default_val = default_areafraction
    ! default value assigned by module
    real, intent(in) :: val ! area fraction passed by user

    ! check that value passed to method is within the range
    if ((val > (max_val + t)) .or. (val < (min_val - t))) then 
        ! if the value passed to the method is above the allowable limit
        ! inform the used and keep the default value
        150 format(" SET AREA FRACTION :: Value passed to method (", F5.3, ") is outside of range", &
            " (MIN = ", F5.3,", MAX = ", F5.3,"). Area fraction set to default value of ", F5.3, ".")
        write (*,150) val, min_val, max_val, default_val
        success = .false.
    endif
    eta = val
    success = .true.
end function set_areafraction

function set_cells(val) result (success)
    implicit none 
    logical :: success ! used to determine if operation was successful
    integer, parameter :: min_val = min_cell
    ! minimum allowable value that user can assign
    integer, parameter :: default_val = default_cell
    ! default value assigned by module
    integer, intent(in) :: val ! number of lattice cells assigned by user

    ! check that the value assigned by the user is within the allowable range
    if (val < min_val) then 
        ! the value is outside the allowable range
        ! inform the user, exit unsuccessful
        151 format (" SET LATTICE CELL :: value passed to method (", I4, ") is outside the allowable range ", &
            "(MIN = ", I4,"). Lattice cells set to default value (", I4,").")
        write (*,151) val, min_val, default_val
        success = .false.
    endif
    cell = val 
    success = .true.
end function set_cells

function set_achirality (val) result (success)
    implicit none 
    logical :: success ! used to determine if operation was successful
    real(kind=dbl), parameter :: t = tol 
    ! tolerance used for comparing real values
    real(kind=dbl), parameter :: max_val = max_achairality
    ! maximum allowable value that user can assign
    real(kind=dbl), parameter :: min_val = min_achirality
    ! minimum allowable value that user can assign
    real(kind=dbl), parameter :: default_val = default_achairality
    ! default value assigned by module
    real, intent(in) :: val ! a-chirality fraction assigned by user

    ! check that the value passed to the method is within the range
    if ((val > (max_val + t)) .or. (val < (min_val - t))) then 
        ! if the value passed to the method is outside the allowable range
        ! inform the user and keep the default value
        152 format(" SET A-CHIRALITY FRACTION :: Value passed to method (", F5.3, ") is outside of range", &
            " (MIN = ", F5.3,", MAX = ", F5.3,"). Area fraction set to default value of ", F5.3, ".")
        write (*,152) val, min_val, max_val, default_val
        success = .false.
    endif
    xa = val 
    success = .true.
end function set_achirality

function set_temperature (val) result (success)
    implicit none 
    logical :: success ! determines if operation was successful
    real(kind=dbl), parameter :: t = tol 
    ! maximum allowable value that user can assign
    real(kind=dbl), parameter :: min_val = min_temperature
    ! minimum allowable value that user can assign
    real(kind=dbl), parameter :: default_val = default_temperature
    ! default value assigned by module
    real, intent(in) :: val ! simulation temperature assigned by user

    ! check that the value passed to the method is within the range
    if (val < (min_val - t)) then 
        ! if the value passed to the method is outside the allowable range
        ! inform the user and keep the default value
        152 format(" SET TEMPERATURE :: Value passed to method (", F5.3, ") is outside of range", &
            " (MIN = ", F5.3,"). Temperature set to default value of ", F5.3, ".")
        write (*,152) val, min_val, default_val
        success = .false.
    endif
    tempset = val 
    success = .true.
end function set_temperature

function set_events(val) result (success)
    implicit none 
    logical :: success ! used to determine if operation was successful
    integer, parameter :: min_val = min_events
    ! minimum allowable value that user can assign
    integer, parameter :: default_val = default_events
    ! default value assigned by module
    integer, intent(in) :: val ! number of lattice cells assigned by user

    ! check that the value assigned by the user is within the allowable range
    if (val < min_val) then 
        ! the value is outside the allowable range
        ! inform the user, exit unsuccessful
        151 format (" SET EVENTS :: value passed to method (", F5.1, " million) is outside the allowable range ", &
            "(MIN = ", I4,"). Lattice cells set to default value (", F5.1," million).")
        write (*,151) (real(val) / 1e6), min_val, (real(default_val) / 1e6)
        success = .false.
    endif
    total_events = val 
    success = .true.
end function set_events

subroutine set_sphere_movie (status, freq)
    implicit none 
    logical, intent(in), optional :: status 
    ! boolean that determines if movie should be turned on or off
    real, intent(in), optional :: freq
    ! frequency of movie making in simulation seconds

    if (present(status)) then 
        if (status) then 
            ! if the status is .true.
            ! turn on the movie 
            moviesph = 1 
            write (*,*) "sphere_movie :: sphere movie making status was turned on."
        else
            ! turn off the movie
            moviesph = 0
            write (*,*) "sphere_movie :: sphere movie making status was turned off."
        endif 
    endif

    if (present(freq)) then 
        ! check that the value is greater than zero
        if (freq < 0) then 
            ! frequency value is less than zero
            1 format(" sphere_movie :: unable to assign sphere movie frequency. ", &
                "value (", F6.1,") passed to method is less than zero.")
            write (*,1) freq 
        else
            ! frequency value is greater than zero 
            sphmovfreq = freq
            2 format (" sphere_movie :: sphere movie making frequency set to ", &
                "every ", F6.1," simulations second(s).")
            write (*,2) sphmovfreq
        endif
    endif

    ! report to user status of movie making stauts
    if (moviesph == 1) then 
        ! movie making status is on
        3 format (" sphere_movie :: sphere movie making status is on and set to ", &
        "every ", F6.1, " simulation seconds." )
        write (*,3) sphmovfreq
    else
        ! movie making status is off
        write (*,*) "sphere_movie :: sphere movie making status is off."
    endif
end subroutine set_sphere_movie

subroutine set_square_movie (status, freq)
    implicit none 
    logical, intent(in), optional :: status 
    ! boolean that determines if movie should be turned on or off
    real, intent(in), optional :: freq
    ! frequency of movie making in simulation seconds

    if (present(status)) then 
        if (status) then 
            ! if the status is .true.
            ! turn on the movie 
            moviesqu = 1 
            write (*,*) "square_movie :: sphere movie making status was turned on."
        else
            ! turn off the movie
            moviesqu = 0
            write (*,*) "square_movie :: sphere movie making status was turned off."
        endif 
    endif

    if (present(freq)) then 
        ! check that the value is greater than zero
        if (freq < 0) then 
            ! frequency value is less than zero
            1 format(" square_movie :: unable to assign sphere movie frequency. ", &
                "value (", F6.1,") passed to method is less than zero.")
            write (*,1) freq 
        else
            ! frequency value is greater than zero 
            squmovfreq = freq
            2 format (" square_movie :: sphere movie making frequency set to ", &
                "every ", F6.1," simulations second(s).")
            write (*,2) squmovfreq
        endif
    endif

    ! report to user status of movie making stauts
    if (moviesqu == 1) then 
        ! movie making status is on
        3 format (" square_movie :: sphere movie making status is on and set to ", &
        "every ", F6.1, " simulation seconds." )
        write (*,3) squmovfreq
    else
        ! movie making status is off
        write (*,*) "square_movie :: sphere movie making status is off."
    endif
end subroutine set_square_movie

subroutine set_thermostat (status, freq) 
    implicit none 
    logical, intent(in), optional :: status 
    ! boolean that determines if thermostat should be turned on or off
    ! real, intent(in), optional :: temp 
    ! temperature set point of thermostat, strength of ghost collisions
    real, intent(in), optional :: freq
    ! frequency of thermostat ghost collisions per particle

    if (present(status)) then 
        if (status) then 
            ! turn on the thermostat
            thermostat = .true.
            write (*,*) "set_thermostat :: thermostat status was turned on."
        else
            ! turn off the thermostat
            thermostat = .false.
            write (*,*) "set_thermostat :: thermostat status was turned off."
        endif 
    endif

    ! if (present(temp)) then 
    !     ! check that the value is greater than zero
    !     if (set_temperature(temp)) then 
    !         use_default_temperature = .false.
    !         1 format(" set_temperature :: thermostat temperature was set to ", F6.3,".")
    !         write (*,1) tempset
    !     endif
    ! endif

    if (present(freq)) then 
        ! check that the value is greater than zero
        if (freq < 0) then 
            ! frequency value is less than zero
            2 format(" set_thermostat :: unable to assign thermostat ghost collision frequency. ", &
                "value passed to method (", F6.1,") is less than zero.")
            write (*,2) freq 
        else
            ! frequency value is greater than zero 
            3 format (" set_thermostat :: thermostat ghost collision frequency set to ", &
                "every ", F6.1," per particle.")
            write (*,3) freq
            thermostat_freq = (freq * cube)/ (density ** (1./2.))
        endif
    else
        ! if a frequency was not passed to the method
        ! assign the default frequency
        thermostat_freq = (default_thermostat_freq * cube) / (density ** (1./2.))
    endif

    ! initialize thermostat parameters
    thermostat_period = (1. / thermostat_freq)
    ! inevrse of frequency, simulation seconds until next thermostat event


    ! report the status of the thermostat to the user
    if (thermostat) then 
        ! thermostat is on
        4 format (" set_thermostat :: thermostat is on and thermostat ghost collision frequency is set to ", &
        F8.2, " per second." )
        write (*,4) thermostat_freq
    else
        ! thermostat is off
        write (*,*) "set_thermostat :: thermostat is off."
    endif
end subroutine set_thermostat

subroutine set_external_field (status, strength, rot_status, rot_freq, &
    freq, force, ori) 
    implicit none 
    logical, intent(in), optional :: status 
    ! boolean that determines if external field should be turned on or off
    real, intent(in), optional :: strength
    ! dimensionless strength of the external field
    real, intent(in), optional :: freq
    ! frequency that particles experience ghost collisions from the field
    real, intent(in), optional :: force 
    ! strength of impulsive force that charged particles experience during 
    ! an external field ghost collision
    type(vec), intent(in), optional :: ori ! field orientation
    logical :: check_ori ! used for determining if the orientation is correct
    real(kind=dbl) :: norm ! used to normalize the field orientation 
    integer :: q ! used for indexing

    ! formatting statements
    1 format (" set_external_field :: Field impulse has been set to value passed to method (", &
        F5.3, ").")
    2 format (" set_external_field :: Field impulse set to default value proportional ", & 
        "to the system temperature (", F5.3,").")
    3 format(" set_external_field :: unable to assign external field strength. ", &
        "value passed to method (", F5.3,") is less than zero.")
    4 format (" set_external_field :: external field strength set to ", F8.3,".")
    5 format (" set_external_field :: unable to assign the field frequency value ", &
        "passed to the method. value (", F8.3,") is less than zero.")
    6 format(" set_external_field :: external ghost collision field frequency set to ", &
        F8.3, " per simulation second.")
    7 format(" set_external_field :: unable to assign the field orientation passed to ", &
        "method. Both values (", F5.3,", ", F5.3,") equal to zero.")
    8 format(" set_external_field :: field orientation set to (", F5.3,", ", F5.3,").")
    9 format(" set_external_field :: field is set to (impulse = ", F5.3", freq = ", F8.3, &
        "), which corresponds to a strength of (", F8.3,"), in the direction (", F5.3, &
        ",", F5.3,").")

    if (present(status)) then 
        if (status) then 
            ! turn on the external field
            field = .true.
            write (*,*) "set_external_field :: external field status was turned on."
        else
            ! turn off the external field
            field = .false.
            write (*,*) "set_external_field :: external field status was turned off."
        endif 
    endif

    ! if the field is on
    if (status) then 

        ! assign the field impulse 
        if (present(force)) then 
            ! check that the value passed to the method is acceptable
            if (force > 0.) then 
                ! if force has been assigned and an allowable value
                ! set the field impulse to the value passed to the method
                field_impulse = force 
                ! inform the user
                write (*, 1) field_impulse
            else
                ! assign the default
                field_impulse = sqrt(2. * tempset)
                ! inform the user
                write (*, 2) field_impulse
            endif
        else
            ! force not assigned or value passed to method not allowable
            ! assign the default 
            field_impulse = sqrt(2. * tempset)
            write (*, 2) field_impulse
        endif 

        ! assign field strength or frequency
        ! cannot assign both
        if (present(strength) .and. (present(freq))) then 
            ! if both have been assigned, throw an error
            write (*,*) "set_external_field :: Error. Unable to assign both field strength ",&
                "and field frequency. Quitting program."
            call exit()

        else if (present(strength)) then 

            ! if only the field strength has been passed to the method
            ! check that the value is greater than zero
            if (strength < 0.) then 

                ! value is less than zero
                ! inform the user that the value cannot be assigned
                write (*,3) strength 

                ! assign defaults
                external_field_strength = default_field_stength
            else
                ! external field strength value is greater than zero 
                ! assign the value and inform the user
                external_field_strength = strength
            endif


            ! assign the field frequency according to the external field strength
            field_freq = (1. * external_field_strength / &
                (1. * field_impulse)) * real(cube)
            field_period = 1. / field_freq

            ! inform the user the values of the external field strength
            ! and the field frequency
            write (*,4) external_field_strength
            write (*,6) field_freq

        else if (present(freq)) then 
            ! if only the field frequency has been passed to the method

            ! check that the value is allowable
            if (freq > 0.) then 
                ! assign the value and report to the user
                field_freq = freq
                field_period = 1. / field_freq

                ! the external field strength is back calculated
                external_field_strength = field_freq * field_impulse * real(cube)
            else 
                ! inform the user that the value passed to the method
                ! cannot be assigned
                write (*,5) freq

                ! assign the default external field strength, field freq
                external_field_strength = default_field_stength
                field_freq = (1. * external_field_strength / &
                    (1. * field_impulse)) * real(cube)
                field_period = 1. / field_freq

            endif

            ! inform the user the value of the field frequency and strength
            write (*,6) field_freq
            write (*,4) external_field_strength
        else 
            ! if neither have been assigned, assign the defaults
            external_field_strength = default_field_stength
            field_freq = (1. * external_field_strength / &
                (1. * field_impulse)) * real(cube)
            field_period = 1. / field_freq
            ! inform the user the value of the field frequency and strength
            write (*,6) field_freq
            write (*,4) external_field_strength
        endif

        if (present(ori)) then 
            ! check that the values passed to the method are acceptable
            ! both values cannot be equal to zero
            if ((abs(ori%d(1)) < tol) .and. (abs(ori%d(2)) < tol)) then 
                ! inform the user that the values passed to the method
                ! do not meet the constrains
                write (*,7) ori%d(1), ori%d(2)

                ! assign the defaults
                field_ori%d(1) = 0.
                field_ori%d(2) = 1.
            else
                ! the orientation passed to the method is acceptable
                ! assign the normalized orientation
                norm = sqrt(ori%d(1) ** 2 + ori%d(2) ** 2)
                do q = 1, ndim
                    field_ori%d(q) = ori%d(q) / norm
                enddo
            endif 

            ! inform the user
            write (*,8) field_ori%d(1), field_ori%d(2)
        else
            ! assign defaults and inform user
            field_ori%d(1) = 0.
            field_ori%d(2) = 1.
            ! inform the user
            write (*,8) field_ori%d(1), field_ori%d(2)
        endif
    endif

    ! report the status of the external field to the user
    if (field) then 
        ! external field is on
        write (*,9) field_impulse, field_freq, external_field_strength, &
            field_ori%d(1), field_ori%d(2)
    else
        ! external field is off
        write (*,*) "set_external_field :: external field is off."
    endif
end subroutine set_external_field

subroutine set_field_rotation (rot_status, rot_freq) 
    implicit none
    logical, intent(in), optional :: rot_status
    ! boolean that determines if the external field is rotating
    real, intent(in), optional :: rot_freq
    ! positive real number that indicates the rate at which the external
    ! field rotates (in rads / sec), if field rotation has been turned on

end subroutine

! ** type(id) functions **************************************

type(id) function nullset()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************

    nullset%one = 0
    nullset%two = 0
end function nullset

integer function id2mol(i, m)
    implicit none
    ! ** calling variables ***********************************
    integer :: i, m
    ! ** local variables *************************************

    id2mol = (i-1)*mer + m
end function id2mol

type(id) function mol2id(i)
    implicit none
    ! ** calling variables ***********************************
    integer :: i
    ! ** local variables *************************************

    mol2id%one = ((i - 1) / mer) + 1
    mol2id%two = mod(i, mer)
	if (mol2id%two == 0) mol2id%two = mer
end function mol2id

logical function idequiv(id1, id2)
    implicit none
    ! ** calling variables ***********************************
    type(id), intent(in) :: id1, id2
    ! ** local variables *************************************

    idequiv = (id1%one == id2%one) .and. (id1%two == id2%two)
end function idequiv


! ** type(event) functions ***********************************

type(event) function reset_event () 
    implicit none 
    ! ** calling variables ***********************************
    ! ** local variables *************************************

    reset_event%time = bigtime
    reset_event%type = 0
    reset_event%partner = nullset ()
end function reset_event

logical function sooner (newevent, oldevent) 
    implicit none 
    ! ** calling variables ***********************************
    type(event), intent(in) :: newevent
    type(event), intent(in) :: oldevent
    ! ** local variables *************************************

    sooner = newevent%time < oldevent%time 
end function sooner


! ** initialization / restarting / saving / loading ***********

subroutine initialize_system (job, sim)
    implicit none 
    character(len=*), intent(in), optional :: job ! job id of simulation
    character(len=*), intent(in), optional :: sim ! sim id of simulation

    ! assign job and simulation id, if they are present
    if (present(job)) then
        ! check the length, assign
        if (len_trim(job) <= max_charlength) then 
            ! if the length is less than the max character length
            ! assign the job
            jobid = trim(job)
        else
            ! if the string is too long 
            ! inform the user and assign the default
            write (*,*) "initialize_system :: unable to assign jobid passed to method. Too many characters in string."
            jobid = trim(default_jobid)
        endif
    else
        ! assign default
        jobid = trim(default_jobid)
    endif
    1 format(" initialize_system :: simulation jobid set to ", A,'.')
    write (*,1) trim(jobid)

    if (present(sim)) then 
        ! check length, assign
        if (len_trim(sim) <= max_charlength) then 
            ! if the length of the string is less than the max length
            ! assign to simulation id
            simid = trim(sim)
        else
            ! the string is too long 
            ! inform the user and assign the default
            write (*,*) "initialize_system :: unable to assign simid passed to method. too many characters in string."
            simid = trim(default_simid)
        endif
    else
        ! assign default)
        simid = trim(default_simid)
    endif
    2 format(" initialize_system :: simulation simid set to ", A, ".")
    write (*,2) trim(simid)

    ! open simulation files
    call open_files ()
    call set_annealstatus ()
    if (tempset <= tempfinal) call exit() ! DONE: prevent the system from simulating below the maximum
    ! TODO :: write headers method
    ! TODO :: if annealing AND anneal status is met, quit simulation

    ! allocate arrays
    allocate(square(cube))
    allocate(eventTree(mols+2))
    ! events for all discs plus events for each stochastic 
    ! ghost event

    ! initialize groupings
    call reset_state ()
    call initial_state()
    call set_position ()
    call set_velocity ()
    call set_chairality ()
    call set_polarity ()
    call build_neighborlist ()
    call set_orderlist ()
    call set_milestones ()

    ! initialize system properties 
    call initialize_properties ()

    ! save
    call save()

    ! schedule events and record snapshot
    call complete_reschedule ()
    if (moviesph == 1) call record_position_circles ()
    if (moviesqu == 1) call record_position_squares ()

    write(simiounit,*) '*** START OF DISCONTINUOUS MOLECULAR DYNAMICS ***'
    write(simiounit,*) ' '
    write(simiounit,*) '    s   | evnt. (m) |   te   |   pe   |   ke   |  temp  |   lm   |   s   '
    write(simiounit,*) '============================================================================'
end subroutine initialize_system

subroutine restart()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************

    call reset_state()
    call set_position()
    call random_velocity(0., sqrt(tempset))
    call set_chairality()
    call set_polarity()
    call build_neighborlist()
    call set_orderlist()
    call complete_reschedule()
    call set_milestones ()
end subroutine restart

subroutine save()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************

    call save_annealstatus ()
    call save_state()
    call save_position()
    call save_velocity()
    call save_chairality()
    call save_milestones ()
end subroutine save

subroutine adjust_temperature(temp)
    implicit none
    ! ** calling variables ***********************************
    real(kind=dbl), intent(inout) :: temp
    ! ** local variables *************************************
    
    if (temp > tempfinal) then
        temp = temp * anneal_frac
    else 
        write (simiounit, *) 'adjust_temperature: temperature for simulation', &
            ' below the allowable amount. Annealing simulation has ended.'
        call exit ()
    end if 
    ! call random_velocity(0., sqrt(temp))
    call complete_reschedule()
end subroutine adjust_temperature

! // anneal status //

subroutine initialize_annealing (status, frac)
    implicit none 
    logical, intent(in), optional :: status 
    ! boolean that determines if annealing status should be turned on or off
    real, intent(in), optional :: frac
    ! real number between one and zero that determines the fraction by
    ! which the temperarture is reduced each iteration of the annealing simulation

    ! string formatting statements
    1 format (" set_annealing_status :: annealing fraction set to ", F8.3,".")
    2 format (" set_annealing_status :: unable to assign the annealing fraction value ", &
        "passed to the method. value (", F8.3,") is less than zero or greater than zero.")
    3 format (" set_annealing_status :: default annealing fraction assigned (", F8.3,")")

    ! assign the annealing status passed to the argument
    if (present(status)) then 
        if (status) then 
            annealing_status = .true. 
            write (*,*) "set_annealing_status :: the annealing status was turned on."
            ! if the annealing status is being turned on
            anneal = 0 ! initialize the annealing integer
        else
            annealing_status = .false.
            write (*,*) "set_annealing_status :: the annealing status was turned off."
        endif
    endif

    ! if annealing is turned on
    if (status) then 
        if (present(frac)) then 
            ! check that the value is acceptable, then assign the value
            if (frac > 0. .and. frac < 1.) then 
                anneal_frac = frac
                write (*,1) frac 
            else
                ! the value is outside the valid range
                write (*,2) frac 
                anneal_frac = default_frac
                write(*,3) anneal_frac
            endif
        else
            ! if the fraction is not present, assign the default
            anneal_frac = default_frac
            write (*,3) anneal_frac
        endif
    endif
end subroutine initialize_annealing

subroutine set_annealstatus()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer :: ierror 

    ! load the state of the annealing simulation
    open (unit = saveiounit, file = trim(anneal_savefile), status = 'OLD', action = 'READ', iostat = ierror)
    if (ierror == 0) then ! read the information in from the save file 
        read (saveiounit, *) annealing_status
        if (annealing_status) then 
            ! if the annealing status is turned on, continue reading the file
            read (saveiounit, *) anneal 
            read (saveiounit, *) anneal_frac
            ! read (saveiounit, *) tempset 
        endif
        close (unit = saveiounit, status = 'KEEP')
    else 
        ! if a file containing the annealing status does not exist
        ! assume that the annealing status is off
        annealing_status = .false.
    end if 
end subroutine set_annealstatus

subroutine save_annealstatus()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer :: ierror 

    ! save the status of the annealing simulation
    open (unit = saveiounit, file = trim(anneal_savefile), status = 'REPLACE', action = 'WRITE', iostat = ierror)
    if (ierror == 0) then 
        write (saveiounit, *) annealing_status
        write (saveiounit, *) anneal
        write (saveiounit, *) anneal_frac
        ! write (saveiounit, *) tempset 
    else
        write (simiounit, *) 'save_state: unable to open annealsavefile. failed to record annealing simulation status'
    end if
end subroutine save_annealstatus

! // state //

subroutine reset_state()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer :: ierror 

    ! load simulation state
    open (unit = saveiounit, file = trim(sim_savefile), status = 'OLD', action = 'READ', iostat = ierror)
    if (ierror == 0) then 
        read(saveiounit, *) timenow
        read(saveiounit, *) timeperiod
        read(saveiounit, *) tempset
        read(saveiounit, *) tl
        read(saveiounit, *) n_events
        read(saveiounit, *) n_col
        read(saveiounit, *) n_ghost
        read(saveiounit, *) n_thermostat
        read(saveiounit, *) n_field
        read(saveiounit, *) n_bond
        read(saveiounit, *) n_hard
        read(saveiounit, *) n_well
        close (unit = saveiounit, status = 'KEEP')
    else 
        ! if no save file exists, restart simulation from the beginning
        call initial_state()
    endif
end subroutine reset_state

subroutine initial_state()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer :: ierror ! used to record the status of i/o operations

    ! intialize simulation event and time tracking to zero
    timenow = 0.
    timeperiod = 0.
    tl = 0.
    n_events = 0
    n_col = 0
    n_ghost = 0
    n_thermostat = 0
    n_field = 0
    n_bond = 0
    n_hard = 0
    n_well = 0
end subroutine initial_state

subroutine save_state()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer :: ierror 

    ! save the state of the simulation 
    open (unit = saveiounit, file = trim(sim_savefile), status = 'REPLACE', action = 'WRITE', iostat = ierror)
    if (ierror == 0) then 
        write(saveiounit, *) timenow
        write(saveiounit, *) timeperiod
        write(saveiounit, *) tempset
        write(saveiounit, *) tl
        write(saveiounit, *) n_events
        write(saveiounit, *) n_col
        write(saveiounit, *) n_ghost
        write(saveiounit, *) n_thermostat
        write(saveiounit, *) n_field
        write(saveiounit, *) n_bond
        write(saveiounit, *) n_hard
        write(saveiounit, *) n_well
        close(unit = saveiounit, status = 'KEEP')
    else 
        write(simiounit, *) 'save_state: unable to open simsavefile. failed to record simulation state data'
    endif
end subroutine save_state

! // position //

subroutine set_position ()
    implicit none 
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer, parameter :: max_attempts = 1 ! maximum number of times to attempt a random configuration
    integer :: i, m, q ! indexing parameters for reading saved file data 
    integer :: success ! used to determine if random walk algorithm was successful 
    integer :: attempts ! used to count the number of times random walk algorithm has been attempted
    integer :: ierror ! used to record the status of i/o operations 

    ! if a file containing the simulation postion data exists, read it in
    open (unit = saveiounit, file = trim(fp_savefile), status = 'OLD', action = 'READ', iostat = ierror)
    if (ierror == 0) then ! read in the information from the save file 
        write(simiounit,*) 'set_position: postion vectors were read from saveio file'
        read (saveiounit, *) tsl
    	do q = 1 , ndim ! for each dimension 
    		do i = 1, cube ! for each square 
    			do m = 1, mer ! for each particle 
                    read (saveiounit, *) square(i)%circle(m)%fpos%r(q)
    			end do 
    		end do 
    	end do
        close (unit = saveiounit, status = 'KEEP')
    else if ((ierror /= 0) .or. (check_boundaries())) then ! if the file could not be loaded or the boundaries are overlapping
        ! generate random configuration
        attempts = 0
    	do
            attempts = attempts + 1
            success = 0
            call random_position (success)
    		if (success == 1) then 
                write(simiounit,*) 'set_position: position vectors were generated using random walk algorithm'
                exit
    		end if 
    		if ((success == 0) .and. (attempts >= max_attempts)) then
                write(simiounit,*) 'set_position: algorithm unable to generate squares with random positions at given density.'
                write(simiounit,*) 'set_position: squares were generated into a bcc lattice formation.'
                call lattice ()
                exit
    		end if
    	end do 
    end if
end subroutine set_position

subroutine random_position (success) 
    implicit none 
    ! ** calling variables ***********************************
    integer, intent(out) :: success 
    ! ** local variables *************************************
    integer, parameter :: limit = 100000 ! maxumimum number of attempts algorithm giving up
    integer :: count ! number of atempts made at random position generation
    real(kind=dbl) :: rij, theta ! distance between two particle, angle relative to origin
    real(kind=dbl) :: u, x, y ! variables for random position and orientation
    integer :: overlap ! if overlap, 1
    integer :: i, j, m, n, q, r ! indexing parameters

    ! Initialize parameteres
    count = 0 ! initial attempts are zero
    success = 0 ! initially unsuccessful until successful

    i = 1 ! first cube 
	do ! for every cube
        overlap = 0
		do m = 1, mer ! for every sphere making up a cube 
            ! assemble spheres in a cube 
			if (m == 1) then ! if the cube is the first in the assembly
                ! give the first sphere a random position and orientation
                call random_number (theta)
                theta = theta * 360
				do q = 1, ndim 
                    call random_number (square(i)%circle(m)%fpos%r(q))
                    square(i)%circle(m)%fpos%r(q) = square(i)%circle(m)%fpos%r(q) * region
				end do
			else 
                ! assign positions based on previous positions 
                ! spheres are generated in a counter clockwise fashion
                square(i)%circle(m)%fpos%r(1) = square(i)%circle(m - 1)%fpos%r(1) + sigma1 * cos(theta + (m - 1) * halfpi)
                square(i)%circle(m)%fpos%r(2) = square(i)%circle(m - 1)%fpos%r(2) + sigma1 * sin(theta + (m - 1) * halfpi)
                call apply_periodic_boundaries(square(i)%circle(m)%fpos)
			end if 

            ! check that the new sphere does not overlap with any previous squares
			if (i>1) then ! if the spheres do not belong to the first cube
				do j = 1, i-1 ! for all already placed squares
					do n = 1, mer ! for all spheres in each square
                        rij = distance(square(i)%circle(m), square(j)%circle(n))
						if (sqrt(rij) < sigma1) overlap = 1
					end do
				end do 
			end if 
		end do

		if (overlap == 0) then
			if (i == cube) then ! if all squares have been randomly places 
                success = 1 ! the algorithm has been successful
                tsl = 0. ! the time since the last update is reset
                tl = timenow ! the time of the last update is the current time
                return ! leave the subroutine
			end if
            i = i + 1
            count = 0
		else ! the one of the four spheres is overlapping
            ! assign the first sphere of cube i a new position and orientation
            count = count + 1
			if (count > limit) then ! if the maximum number of trials has been reached
                return ! leave subroutine
			end if 
		end if 
	end do
end subroutine random_position

subroutine lattice ()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    real(kind=dbl), parameter :: ori = (225. / 360.) * twopi ! orientation of the cube [radians]
    real(kind=dbl), parameter :: radius = sqrt(2.) / 2. ! distance from square center to sphere center
    real(kind=dbl) :: distance ! measurement of distance between two particles
    real :: rand ! random number
    integer :: randori ! random orientation created by the random number
    type(position) :: dr, center
    integer :: x, y, m  ! indexing parameters


    tsl = 0. ! the time since the last update is reset
    tl = timenow ! the time of the last update is the current time

	x_axis: do x = 1, cell 
        center%r(1) = (region / real(cell)) * (real(x) - 0.5)
		y_axis: do y = 1, cell 
            center%r(2) = (region / real(cell)) * (real(y) - 0.5)
            call random_number (rand)
            randori = floor (rand * 4.)
			group: do m = 1, mer 
                ! spheres are generated in a counter clockwise fashion
                square((x - 1) * cell + y)%circle(m)%fpos%r(1) = center%r(1) + radius * cos(ori + &
                    (real(randori) * halfpi) + (m - 1) * halfpi)
                square((x - 1) * cell + y)%circle(m)%fpos%r(2) = center%r(2) + radius * sin(ori + &
                    (real(randori) * halfpi) + (m - 1) * halfpi)
			end do group
		end do y_axis
	end do x_axis
end subroutine lattice

subroutine save_position()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer :: ierror ! used to determine read/write error status 
    integer :: i, m, q ! used for indexing 

    open (unit = saveiounit, file = fp_savefile, status = 'REPLACE', action = 'WRITE', iostat = ierror)
	if (ierror == 0) then 
        write (saveiounit, *) tsl
		do q = 1 , ndim ! for each dimension 
			do i = 1, cube ! for each square 
				do m = 1, mer ! for each particle 
                    write (saveiounit, *) square(i)%circle(m)%fpos%r(q)
                enddo
			enddo 
		enddo 
        close (unit = saveiounit, status = 'KEEP')
	else 
        write (simiounit,*) 'save_position: unable to open file. failed to record simulation position data'
	end if 
end subroutine save_position

! // velocity //

subroutine set_velocity () 
    implicit none 
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer :: i, m, q ! indexing parameters for reading saved file data 
    integer :: ierror ! used to record the status of i/o operations 

    ! if a file containing the simulation velocity data exists, read it in
    open (unit = saveiounit, file = trim(v_savefile), status = 'OLD', action = 'READ', iostat = ierror)
	if (ierror == 0) then ! read in the information from the save file 
        write(simiounit,*) 'set_velocity: velocity vectors were read from saveio file'
		do q = 1 , ndim ! for each dimension 
			do i = 1, cube ! for each square 
				do m = 1, mer ! for each particle in each grouping
                    read (saveiounit, *) square(i)%circle(m)%vel%v(q)
				end do 
			end do 
		end do
        close (unit = saveiounit, status = 'KEEP')
	else ! assign velocities 
        call random_velocity (0., sqrt(tempset))
	end if
end subroutine set_velocity

subroutine random_velocity (mu, sigma)
    implicit none
    ! ** calling variables ***********************************
    real, intent(in) :: mu ! mean of distribution
    real(kind=dbl), intent(in) :: sigma ! standard deviation of distribution
    ! ** local variables *************************************
    type(position), dimension(mols) :: rpos ! array storing the real position of every particle whose position is being update
    integer :: i, m, q ! indexing parameters
    real(kind=dbl) :: u_1, u_2 ! Box-Mueller algorithm parameters
    type(velocity) :: vsum

	do q = 1, ndim
        vsum%v(q) = 0.
	end do 

	do i = 1, cube ! for each group 
		do m = 1, mer ! for each particle
			do q = 1, ndim 
                ! store the real position of each particle
                rpos(id2mol(i,m))%r(q) = square(i)%circle(m)%fpos%r(q) + square(i)%circle(m)%vel%v(q) * tsl
                ! Generate a pseudo random vector components based on a Gaussian distribution along the Box-Mueller algorithm
                call random_number (u_1)
                call random_number (u_2)
                ! assign random velocity component to each sphere in cube
                square(i)%circle(m)%vel%v(q) = mu + sigma * sqrt( -2. * log(u_1)) * sin (twopi * u_2)
                vsum%v(q) = vsum%v(q) + square(i)%circle(m)%vel%v(q)
			end do
		end do 
	end do 

    ! calculate the linear momentum contributions per molecule in each direction
	do q = 1, ndim 
        vsum%v(q) = vsum%v(q) / mols
	end do 

    ! reduce the velocity sum / linear momentum to zero
	do i = 1, cube ! for each group 
		do m = 1, mer ! for each sphere 
			do q = 1, ndim 
                square(i)%circle(m)%vel%v(q) = square(i)%circle(m)%vel%v(q) - vsum%v(q)
			end do 
		end do
	end do

    do i = 1, cube
        do m = 1, mer 
            do q = 1, ndim 
                ! calculate the new false position of each particle
                square(i)%circle(m)%fpos%r(q) = rpos(id2mol(i,m))%r(q) - square(i)%circle(m)%vel%v(q) * tsl
            enddo
            ! apply periodic boundary conditions
            call apply_periodic_boundaries(square(i)%circle(m)%fpos)
        enddo
    enddo
end subroutine random_velocity

subroutine save_velocity()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer :: ierror ! used to determine read/write error status 
    integer :: i, m, q ! used for indexing 

    open (unit = saveiounit, file = v_savefile, status = 'REPLACE', action = 'WRITE', iostat = ierror)
	if (ierror == 0) then 
		do q = 1 , ndim ! for each dimension 
			do i = 1, cube ! for each square 
				do m = 1, mer ! for each particle in each grouping
                    write (saveiounit, *) square(i)%circle(m)%vel%v(q)
                enddo
			enddo 
		enddo 
        close (unit = saveiounit, status = 'KEEP')
	else 
        write (simiounit,*) 'save_velocity: unable to open file. failed to record simulation velocity data'
	end if 
end subroutine save_velocity

! // chirality & polaity //

subroutine set_chairality ()
    implicit none 
    ! ** calling variables ***********************************

    ! ** local variables *************************************
    integer :: i, m ! indexing parameters
    integer :: ierror ! used to record the status of i/o operations 
    real :: rand ! random number

    ! if a file containing the simulation chirality data exists
    OPEN (unit = saveiounit, file = trim(c_savefile), status = 'OLD', action = 'READ', iostat = ierror)
	if (ierror == 0) then ! read in the information from the save file 
		do i = 1, cube 
            read (saveiounit, *) square(i)%chai
		end do 
        close (unit = saveiounit, status = 'KEEP')
	else ! assign chiralities based on the specified mol fraction
        ! assign each cube a chirality based on its order
		do i = 1, cube 
            rand = real(i) / real(cube)
			if (rand > xa) then 
                square(i)%chai = 2
			else 
                square(i)%chai = 1
			end if 
		end do 
        ! randomly rearrange the chirality of all cubes
        do i = 1, cube 
            call random_number (rand)
            rand = rand * real(cube)
            m = square(i)%chai 
            square(i)%chai = square(ceiling(rand))%chai 
            square(ceiling(rand))%chai = m 
        enddo
	end if 
end subroutine set_chairality

subroutine save_chairality()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer :: ierror ! used to determine read/write error status 
    integer :: i, m ! used for indexing 

    open (unit = saveiounit, file = trim(c_savefile), status = 'REPLACE', action = 'WRITE', iostat = ierror)
	if (ierror == 0) then 
		do i = 1, cube ! for each square 
            write (saveiounit, *) square(i)%chai
		enddo 
        close (unit = saveiounit, status = 'KEEP')
	else 
        write (simiounit,*) 'save_chairality: unable to open file. failed to record simulation chairality data'
	end if 
end subroutine save_chairality

subroutine set_polarity ()
    implicit none 
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer :: i, m ! indexing parameters

	do i = 1, cube 
		do m = 1, mer 
			if (((square(i)%chai == 1) .and. (m == 1)) .or. ((square(i)%chai == 2) .and. (m == 2))) then 
                square(i)%circle(m)%pol = 1 ! positive charge
			else if (((square(i)%chai == 2) .and. (m == 1)) .or. ((square(i)%chai == 1) .and. (m == 2))) then  
                square(i)%circle(m)%pol = -1 ! negative charge 
			else 
                square(i)%circle(m)%pol = 0
			end if 
		end do 
	end do 
end subroutine set_polarity

! // markovian milestoning // 

subroutine set_milestones () 
    implicit none 
    real(kind=dbl), parameter :: initial_nematic_lower = 0.2
    real(kind=dbl), parameter :: initial_nematic_high = 0.3
    integer :: ierror ! used to record the status of i/o operations 

    !! attempt to load the milestoning file 
    !! if the file does not exist or contains a false boolean
    !! then milestoning is turned off

    open(unit = saveiounit, file = trim(ms_savefile), status = 'OLD', action = 'READ', iostat = ierror)
    if (ierror == 0) then ! the file exists and was successfully opened
        !!  read in information from the file 

        ! the first piece of information stored in the file determines whether milestoning is turned on
        read(saveiounit,*) milestone

        ! determine if milestoning is on
        if (milestone) then ! if milestoning is on 
            
            ! read the upper and lower boundaries of the simulation
            read (saveiounit, *) boundary_index
            read (saveiounit, *) upper_nematic_boundary
            read (saveiounit, *) lower_nematic_boundary
            read (saveiounit, *) n_ul 
            read (saveiounit, *) n_uu 
            read (saveiounit, *) n_lu 
            read (saveiounit, *) n_ll 
            read (saveiounit, *) t_u 
            read (saveiounit, *) t_l 

        endif 

        ! close the file 
        close (unit = saveiounit, status = 'KEEP')
    else ! if the file does not exist or could not be opened

        ! initalize the milestoning procedure
        milestone = .true.
        boundary_index = 0 ! boundary index is initially unassigned 
        upper_nematic_boundary = initial_nematic_high
        lower_nematic_boundary = initial_nematic_lower
        n_ul = 0
        n_uu = 0
        n_lu = 0
        n_ll = 0
        t_u = 0 
        t_l = 0

    endif
end subroutine set_milestones

subroutine save_milestones ()
    implicit none 
    integer :: ierror ! used to record the save the status of i/o operations

    !! if milestoning is on, save the nematic boundaries 
    !! else save the off status

    open(unit = saveiounit, file = trim(ms_savefile), status = 'REPLACE', action = 'WRITE', iostat = ierror)
    if (ierror == 0) then ! if the file was successfully opened

        ! write the boolean determining if milestoning is turned on or off
        write (saveiounit, *) milestone 

        if (milestone) then ! if milestoning is turned on

            ! write the state of the milestoning operation
            write (saveiounit, *) boundary_index
            write (saveiounit, *) upper_nematic_boundary
            write (saveiounit, *) lower_nematic_boundary
            write (saveiounit, *) n_ul 
            write (saveiounit, *) n_uu 
            write (saveiounit, *) n_lu 
            write (saveiounit, *) n_ll 
            write (saveiounit, *) t_u 
            write (saveiounit, *) t_l 

        endif 

        ! close the save file 
        close (unit = saveiounit, status = 'KEEP')
    else
        write (saveiounit, *) 'save_milestones: unable to write to save file. milestoning state not saved.'
    endif
end subroutine save_milestones

logical function check_milestoning_boundaries ()
    implicit none 
    real(kind=dbl) :: nematic
    logical :: lower_boundary, upper_boundary

    ! initialize checks 
    check_milestoning_boundaries = .false. 

    ! calculate the nematic order parameter 
    call determine_nematic (nematic)

    ! if the nematic order parameter is at or outside of the boundaries
    ! of the milestoning cell 
    lower_boundary = (nematic <= lower_nematic_boundary)
    upper_boundary = (nematic >= upper_nematic_boundary)
    if (lower_boundary .or. upper_boundary) then 

        ! the boundary of the milestone cell has been reach
        check_milestoning_boundaries = .true. 

        ! report to user
        write (simiounit,'("milestoning: milestone reached. nematic order parameter calculated to be ", F5.3)') nematic 

        ! increment the amount of time that simulation has been assigned to the boundary 
        ! and the number of times that the cell has collided with a boundary
        ! NOTE: overestimation of frequency since simulation has PAST the barrier
        ! rather than being at the barrier
        if (boundary_index == 1) then 
            t_l = t_l + timenow
            if (lower_boundary) then 
                n_ll = n_ll + 1 
            elseif (upper_boundary) then 
                n_lu = n_lu + 1 
            endif 
        elseif (boundary_index == 2) then 
            t_u = t_u + timenow 
            if (lower_boundary) then 
                n_ul = n_ul + 1 
            elseif (upper_boundary) then 
                n_uu = n_uu + 1 
            endif
        endif

        ! update the assigned boundary index 
        if (lower_boundary) then 
            boundary_index = 1 
        elseif (upper_boundary) then 
            boundary_index = 2
        endif

    endif
end function check_milestoning_boundaries

subroutine milestone_boundary_collision ()
    implicit none 
    integer :: i, m, q ! indexing parameters 

    ! load the simulation to a state before the milestone boundary collision
    call reset_state ()
    call set_position ()
    call set_velocity ()
    call set_chairality ()
    call set_polarity ()
    call build_neighborlist ()
    call set_orderlist ()

    ! integrate the system forward a half step to the next event
    ! so that when opposite velocities are applied, negative time
    ! calculations do not occur
    call half_forward()

    ! update velocities to real position (tsl = 0)
    call update_positions ()

    ! apply opposite velocities 
    do i = 1, cube 
        do m = 1, mer 
            do q = 1, ndim 
                square(i)%circle(m)%vel%v(q) = -square(i)%circle(m)%vel%v(q)
            enddo
        enddo
    enddo

    ! increment the "annealing" simulation
    anneal = anneal + 1

    ! save state of entire simulation
    call save()
end subroutine milestone_boundary_collision

! ** #physics *************************************************

subroutine apply_periodic_boundaries(ri)
    implicit none
    type(position), intent(inout) :: ri
    integer :: q 

    do q = 1, ndim 
    	if (ri%r(q) >= region) ri%r(q) = ri%r(q) - region 
    	if (ri%r(q) < 0.0) ri%r(q) = ri%r(q) + region
    end do 
end subroutine apply_periodic_boundaries

logical function check_boundaries()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer :: j1, n ! atomic pairs
    type(id) :: a, b ! group pairs 
    type(position) :: dr ! difference between two position vectors
    real(kind=dbl) :: d ! scalar distance between two particles
    logical :: check_overlap, check_bond, check_bc ! integers indicating whether the spheres are overlapping or within the boundary conditions

    ! initialize checks 
    check_boundaries = .false.
    check_overlap = .false.
    check_bond = .false.
    check_bc = .false.

	do j1 = 1, mols 
        a = mol2id(j1)
        ! check that the center of each atom is within the boundary conditions 
        !if (periodicbounderiesoverlap (square(a%one)%circle(a%two))) then 
            !check_bc = .true.
            !write (simiounit, 1) a%one, a%two, square(a%one)%circle(a%two)%fpos%r(1), square(a%one)%circle(a%two)%fpos%r(2)
            !1 format (" check_boundaries: circle ", I3, " of square ", I3, " is located outside of the boundaries (", F6.2,", ", F6.2,").")
        !end if 
        ! loop through all uplist neightbors
        n = 0
		compare: do 
            n = n + 1
            b = square(a%one)%circle(a%two)%upnab(n)
            if (b%one == 0) exit 
            d = distance (square(a%one)%circle(a%two), square(b%one)%circle(b%two))
			if ((a%one == b%one) .and. (b%two > a%two)) then ! if b is uplist of a and they are on the same group
                ! check that all grouped sphere are bonded correctly
				if (crossbonded (a%two, b%two) .and. crossbondoverlap (d)) then
                    check_bond = .true.
                    write (simiounit, 2) a%two, b%two, a%one, d 
					2 format (" check_boundaries: circles ", I3, " and ", I3, " of square ", I3 &
                        , " are cross-bonded and overlapping (", F6.4, ").")
				else if (neighborbonded (a%two, b%two) .and. neighborbondoverlap (d)) then 
                    check_bond = .true.
                    write (simiounit, 3) a%two, b%two, a%one, d 
					3 format (" check_boundaries: circles ", I3, " and ", I3, " of square ", I3 &
                        , " are neighbor-bonded and overlapping (", F6.2, ").")
				end if 
			else if (b%one > a%one) then ! if b is uplist of a and they not on the same group 
				if (hardsphereoverlap (d)) then ! if the spheres are less than the hard sphere distance apart 
                    check_overlap = .true.
                    write (simiounit, 4) a%two, a%one, b%two, b%one, d
					4 format (" check_boundaries: circle ", I3, " of square ", I3, " and circle ", I3, " of square ", &
                        I3, " are overlapping (", F6.4,").")
				end if 
			end if 
		enddo compare
	enddo

    ! determine if an overlap has occurred 
	if ((check_bond) .or. (check_overlap) .or. (check_bc)) then 
		if (check_bc) write (simiounit, *) 'check_boundaries: some particles are outside of the periodic boundaries'
		if (check_bond) write (simiounit, *) 'check_boundaries: some groupings have particles outside their bonds'
		if (check_overlap) write (simiounit, *) 'check_boundaries: some hardspheres are overlapping '
        write (simiounit, *) 'check_boundaries: the program will abort now '
        check_boundaries = .true.
	end if 
end function check_boundaries

real(kind=dbl) function distance (i, j) 
    implicit none 
    ! ** calling variables ***********************************
    type(particle), intent(in) :: i ! downlist particle
    type(particle), intent(in) :: j ! uplist particle
    ! ** local variables *************************************
    type(position) :: rij
    type(velocity) :: vij
    integer :: q ! indexing parameter 

    ! calculate the real distance between the particle pair
    distance = 0. 
	do q = 1, ndim 
        rij%r(q) = (i%fpos%r(q) - j%fpos%r(q))
        vij%v(q) = (i%vel%v(q) - j%vel%v(q))
        rij%r(q) = rij%r(q) + vij%v(q) * tsl
        ! apply the minimum image convention
		if (rij%r(q) >= (0.5 * region)) rij%r(q) = rij%r(q) - region 
		if (rij%r(q) < (-0.5 * region)) rij%r(q) = rij%r(q) + region
        distance = distance + (rij%r(q) ** 2)
	end do 
    distance = sqrt (distance)
end function distance

type(position) function distance_vector(i, j) ! #percy
    implicit none 
    ! ** calling variables ***********************************
    type(particle), intent(in) :: i ! downlist particle
    type(particle), intent(in) :: j ! uplist particle
    ! ** local variables *************************************
    type(position) :: rij
    type(velocity) :: vij
    integer :: q ! indexing parameter 

    ! calculate the relative distance between the pair in each dimension
    do q = 1, ndim 
        rij%r(q) = (i%fpos%r(q) - j%fpos%r(q))
        vij%v(q) = (i%vel%v(q) - j%vel%v(q))
        rij%r(q) = rij%r(q) + vij%v(q) * tsl
        ! apply the minimum image convention
        if (rij%r(q) >= (0.5 * region)) rij%r(q) = rij%r(q) - region 
        if (rij%r(q) < (-0.5 * region)) rij%r(q) = rij%r(q) + region
        distance_vector%r(q) = rij%r(q)
    end do 
end function distance_vector

logical function neighborbonded (i, j)
    implicit none 
    ! ** calling variables ***********************************
    integer, intent (in) :: i, j ! sphere identifiers
    ! ** local variables *************************************

    ! assume false 
    neighborbonded = .false.
	if (((j-i) == 1) .or. ((j-i) == 3)) then ! if the two spheres are next to one another
        neighborbonded = .true.
	end if 
end function neighborbonded

logical function crossbonded (i, j)
    implicit none 
    ! ** calling variables ***********************************
    integer, intent (in) :: i, j ! sphere identifiers
    ! ** local variables *************************************

    ! assume false 
    crossbonded = .false.
	if (((j-i) == 2) .and. (i == 1)) then ! if the two spheres are across from one another
        crossbonded = .true.
	end if 
end function crossbonded

logical function hardsphereoverlap (distance)
    implicit none 
    ! ** calling variables ***********************************
    real(kind=dbl), intent(in) :: distance
    ! ** local variables *************************************

    hardsphereoverlap = distance < (sigma1 - tol)
end function hardsphereoverlap

logical function crossbondoverlap (distance) 
    implicit none 
    ! ** calling variables ***********************************
    real(kind=dbl), intent(in) :: distance 
    ! ** local variables *************************************

    crossbondoverlap = (distance > (ocbond + tol)) .or. (distance < (icbond - tol))
end function crossbondoverlap

logical function neighborbondoverlap (distance) 
    implicit none 
    ! ** calling variables ***********************************
    real(kind=dbl), intent(in) :: distance 
    ! ** local variables *************************************

    neighborbondoverlap = (distance > (onbond + tol)) .or. (distance < (inbond - tol))
end function neighborbondoverlap

logical function periodicbounderiesoverlap (i)
    implicit none 
    ! ** calling variables ***********************************
    type(particle) :: i
    ! ** local variables *************************************
    type(position) :: rpos ! real position of particle
    integer :: q ! indexing

    periodicbounderiesoverlap = .false. ! false until true 
	do q = 1, ndim 
        rpos%r(q) = i%fpos%r(q) + i%vel%v(q) * tsl
		if ((rpos%r(q) > (region + tol)) .or. (rpos%r(q) < (-tol))) then
            periodicbounderiesoverlap = .true.
		end if 
	end do 
end function periodicbounderiesoverlap


! ** file i/o *************************************************

type(file_io) function set_file_io (status, unit, name)
    logical, intent(in), optional :: status 
    ! boolean that determines if the file should be written to
    integer, intent(in) :: unit 
    ! iounit assigned to writing for that file
    character(len=max_charlength), intent(in) :: name 
    ! name assigned to file for writing / reading
    
    ! use parameters passed to method to initialize the file_io object
    ! initialize iostatus
    if (present(status)) then 
        ! assign the value passed to the method
        set_file_io%iostatus = status 
    else
        ! if no status was passed to the method
        ! assume true 
        set_file_io%iostatus = .true. 
    endif

    ! initialize iounit 
    set_file_io%iounit = unit 

    ! initialize file name 
    set_file_io%filename = trim(name)
end function set_file_io

subroutine open_files ()
    implicit none 
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    character(len=10), parameter :: format = "(I0.3)"
    character(len=10) :: rp
    character(len=45) :: simfile, coorsphfile, coorsqufile, reportfile, &
        annealfile, opfile, mmfile
    integer :: ioerror

    ! initialize first iounit, use for counting
    curr_iounit = init_iounit

    ! name files, assign iounits
    ! save file names
    ! save file containing all false position vectors 
    fp_savefile = trim(jobid) // trim(simid) // '__fposSAVE.dat' 
    ! fp_io = set_file_io (status = .true., unit = curr_iounit, &
    !     name = trim(fp_savefile))
    ! curr_iounit = curr_iounit + 1
    ! ! save file containing all velocity vectors 
    v_savefile = trim(jobid) // trim(simid) // '__velSAVE.dat' 
    ! vel_io = set_file_io (status = .true., unit = curr_iounit, &
    !     name = trim(v_savefile))
    ! curr_iounit = curr_iounit + 1 

    ! TODO :: continue filename / initialization
    ! TODO :: decide on save file variable names
    ! TODO :: add reading / writing status to file_io (private variables),
    !   add methods for opening / closing file readers / writers

    c_savefile = trim(jobid) // trim(simid) // '__chaiSAVE.dat' 
    ! save file containing chiraliry description of each grouping
    sim_savefile = trim(jobid) // trim(simid) // '__simSAVE.dat' 
    ! save file containing all simulation state 
    anneal_savefile = trim(jobid) // trim(simid) // '__annealSAVE.dat' 
    ! save file containing the status of the annealing simulation
    ms_savefile = trim(jobid) // trim(simid) // '__milestoneSAVE.dat' 
    ! save file containing parameters for milestoning


    ! integer, parameter :: saveiounit = 11 
    ! integer, parameter :: simiounit = 12
    ! integer, parameter :: coorsphiounit = 13
    ! integer, parameter :: coorsquiounit = 14
    ! integer, parameter :: reportiounit = 15
    ! integer, parameter :: annealiounit = 16
    ! integer, parameter :: opiounit = 17
    ! integer, parameter :: mmiounit = 18

    write(rp,format) anneal

    simfile = trim(jobid) // trim(simid) // '.txt'
    open (unit = simiounit, file = trim(simfile), status = 'REPLACE')
    write(simiounit,*) ' '
    write(simiounit,*) '*** Canonical 2x2 Polarized Square Code ***'
    write(simiounit,*) ' '
    write(simiounit,"(' ',I4,' ',I3,'-mer cubes were generated.')") cube, mer
    write(simiounit,'(" Reduced Density of Squares: ", F6.2)') density
    write(simiounit,'(" Region Length: ",F7.3)') region
    write(simiounit,'(" Area Faction: ",F4.3)') eta
    write(simiounit,'(" Reduced Temperature: ", F6.2)') tempset / epsilon1
    write(simiounit,*) ' '
    write(simiounit,'("This simulation employs the cell subdivision efficiency technique")')
    write(simiounit,'("Actual Cell Length: ", F6.2)') lengthCell
    write(simiounit,'("Number of Cells: ", I4)') (nCells ** ndim) 
    write(simiounit,'("Average Number of circles per Cell", F6.2)') mer * density * (lengthCell ** ndim)
    write(simiounit,*) ' '
    write(simiounit,'("This simulation employs the cell neighbor list efficiency technique")')
    write(simiounit,'("Length of Neighbor Shell: ", F6.2)') nbrRadius
    write(simiounit,*) ' '


    coorsphfile = trim(jobid) // trim(simid) // '_' // 'sphmov.xyz' ! xyz file containing atomic coordinates for ovito animation
    if (moviesph == 1) open (unit = coorsphiounit, file = trim(coorsphfile), status = 'REPLACE')

    coorsqufile = trim(jobid) // trim(simid) // '_' // 'squmov.xyz' ! xyz file containing atomic coordinates for ovito animation
    if (moviesqu == 1) open (unit = coorsquiounit, file = trim(coorsqufile), status = 'REPLACE')

    annealfile = trim(jobid) // trim(simid) // '_anneal.csv' ! comma seperated list containing a summary of annealing simulations
    open (unit = annealiounit, file = trim(annealfile), status = 'REPLACE', iostat = ioerror)
    write(annealiounit,*) 'id,time,set,temp,te,te_fluc,pot,pot_fluc,ke,ke_fluc,poly2,poly2_fluc,',&
        'anti,anti_fluc,full,full_fluc,percy,percy_fluc,nematic,nem_fluc,allign,allign_fluc'

    reportfile = trim(jobid) // trim (simid) // '.csv' ! comma seperated list containing time progression of properties 
    open (unit = reportiounit, file = reportfile, status = 'REPLACE')

    ! report header 
    write(reportiounit, *) 'time,events,te,te_fluc,ke,ke_fluc,pot,pot_fluc,temp,',&
    'temp_fluc,lm,z,collision rate,n_ghost,n_thermostat,n_field,colrate,n_bonds,n_hards,n_wells'


    opfile = trim(jobid) // trim(simid) // '_op.csv' ! comma seperated list containing time progression of order parameters
    open(unit = opiounit, file = trim(opfile), status = 'REPLACE')
    write(opiounit, *) 'time, events, h2ts, h2ts_fluc, h2to, h2to_fluc, anti, anti_fluc,', &
        ' poly2, poly2_fluc, full, full_fluc, fulls, fulls_fluc, ,fullo, ', &
        'fullo_fluc, poly1aa, poly1aa_fluc, poly1abba, poly1abba_fluc,',&
        ' poly1bb, poly1bb_fluc, poly1, poly1_fluc, percolation, nclust,',&
        ' nclust_fluc, nematic, nematic_fluc, allign, allign_fluc'

    mmfile = trim(jobid) // trim(simid) // '_mm.csv'
    open (unit = mmiounit, file = trim(mmfile), status = 'REPLACE')
    write (mmiounit, *) 'boundary index, upper boundary, lower boundary, n_ul, n_uu, n_lu,', &
        ' n_ll, t_u, t_l'
end subroutine open_files

subroutine close_files ()
    implicit none 
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer :: m ! indexing parameter

    ! calculate equilibrium averages
    call accumulate_properties (pot, 5)
    call accumulate_properties (ke, 5)
    call accumulate_properties (te, 5)
    call accumulate_properties (temp, 5)
	do m = 1, ndim 
        call accumulate_properties (lm(m), 5)
	end do
    call accumulate_properties (z, 3)
    ! order parameters 
    call accumulate_properties (poly1, 5)
    call accumulate_properties (poly1aa, 5)
    call accumulate_properties (poly1abba, 5)
    call accumulate_properties (poly1bb, 5)
    call accumulate_properties (h2ts, 5)
    call accumulate_properties (h2to, 5)
    call accumulate_properties (anti, 5)
    call accumulate_properties (poly2, 5)
    call accumulate_properties (full, 5)
    call accumulate_properties (fulls, 5)
    call accumulate_properties (fullo, 5)
    call accumulate_properties (percy, 5)
    call accumulate_properties (nclust, 5)
    call accumulate_properties (nematic, 5)
    call accumulate_properties (allign, 5)

    ! report information and close files
    write(simiounit,*) '*** End of Molecular Simulation ***'
    write(simiounit,*) '*** Canonical 2x2 Polarized Square Code Results ***'
    write(simiounit,*) ' '
    write(simiounit,'("Simulation Length (reduced seconds): ", F8.2)') timenow
    write(simiounit,'("Number of Events: ", F5.1," million")') real(n_events)/1e6
    write(simiounit,'("Number of Collisions: ", F5.1," million ( ",F5.1," %)")') &
        real(n_col)/1e6, real(n_col)*100/real(n_events)
    write(simiounit,'("Number of Hard Sphere Collisions: ", F5.1," million ( ",F5.1," %)")') &
        real(n_hard)/1e6, real(n_hard)*100/real(n_events)
    write(simiounit,'("Number of Well Collisions: ", F5.1," million ( ",F5.1," %)")') &
        real(n_well)/1e6, real(n_well)*100/real(n_events)
    write(simiounit,'("Number of Bond Collisions: ", F5.1," million ( ",F5.1," %)")') &
        real(n_bond)/1e6, real(n_bond)*100/real(n_events)
    write(simiounit,'("Number of Ghost Collisions: ", F5.1," million ( ",F5.1," %)")') &
        real(n_ghost)/1e6, real(n_ghost)*100/real(n_events)
    write(simiounit,'("Number of Thermostat Ghost Collisions: ", F5.1," million ( ",F5.1," %)")') &
        real(n_thermostat)/1e6, real(n_thermostat)*100/real(n_events)
    write(simiounit,'("Number of Field Ghost Collisions: ", F5.1," million ( ",F5.1," %)")') &
        real(n_field)/1e6, real(n_field)*100/real(n_events)
    write(simiounit,'("Thermostat Ghost Collision Frequency (per second): ", F10.3)') &
        real(n_thermostat) / timenow
    write(simiounit,'("Field Ghost Collision Frequency (per second): ", F10.3)') &
        real(n_field) / timenow
    write(simiounit,*) ' ' 
    write(simiounit,'("Number of Cubes:", I7)') cube
    write(simiounit,'("Reduced Area: ", F8.2)') area
    write(simiounit,'("Area Faction: 0",F4.3)') eta
    write(simiounit,'("Reduced Temperature: ",F6.3)') temp%equilavg / epsilon1
    write(simiounit,'("Reduced Pressure: ",F6.3)') z%sum * temp%equilavg * density / epsilon1
    write(simiounit,'("Linear Momentum (x, y): (",F6.3,",",F6.3,").")') lm(1)%equilavg, lm(2)%equilavg
    write(simiounit,'(" ")') 
    write(simiounit,'("Total Energy (per cube): ", F6.3)') te%equilavg
    write(simiounit,'("Kinetic Energy (per cube): ", F6.3)') ke%equilavg
    write(simiounit,'("Potential Energy (per cube): ", F6.3)') pot%equilavg
    write(simiounit,'(" ")') 
    write(simiounit,'("Reduced Density of Squares: ", F6.3)') density
    write(simiounit,'("Beta Epsilon: ", F6.3)') epsilon1 / temp%equilavg
    write(simiounit,'("Compressability Factor: ", F6.3)') z%sum
    write(simiounit,'("Reduced Potential Energy (per cube): ", F6.3)') pot%equilavg / epsilon1

    close (unit = simiounit, status = 'KEEP')
    if (moviesph == 1) close (unit = coorsphiounit, status = 'KEEP')
    if (moviesqu == 1) close (unit = coorsquiounit, status = 'KEEP')
    write(reportiounit, *) ' '
    write(reportiounit, *) ' after '
    write(reportiounit, *) ' seconds , ', timenow
    write(reportiounit, *) ' events , ', n_events
    write(reportiounit, *) ' collisions ,  ', n_col 
    write(reportiounit, *) ' ghosts , ', n_ghost
    write(reportiounit, *) ' thermo ghosts , ', n_thermostat
    write(reportiounit, *) ' field ghosts , ', n_field
    write(reportiounit, *) ' bonds , ', n_bond
    write(reportiounit, *) ' hards , ', n_hard
    write(reportiounit, *) ' wells , ', n_well
    write(reportiounit, *) ' '
    write(reportiounit, *) ' red set point , ', tempfinal
    write(reportiounit, *) ' red temperature , ', temp%equilavg / epsilon1
    write(reportiounit, *) ' % error , ', 100 * (tempfinal - (temp%equilavg / epsilon1)) / tempfinal
    write(reportiounit, *) ' '
    write(reportiounit, *) ' thermo ghost per second , ', (real(n_thermostat)) / timenow
    write(reportiounit, *) ' field ghost per second , ', (real(n_field)) / timenow
    write(reportiounit, *) ' '
    write(reportiounit, *) ' red tote per cube , ', (te%equilavg / epsilon1)
    write(reportiounit, *) ' red kene per cube , ', (ke%equilavg / epsilon1)
    write(reportiounit, *) ' red pote per cube  , ', (pot%equilavg / epsilon1)
    close (unit = reportiounit, status = 'KEEP')
    close (unit = opiounit, status = 'KEEP')
    write(annealiounit, *) anneal,',',timenow,',',tempset,',',temp%equilavg,',',te%equilavg, & 
        ',',te%equilstd,',',pot%equilavg,',',pot%equilstd,',',ke%equilavg,',',ke%equilstd, &
        ',',poly2%equilavg,',',poly2%equilstd,',',anti%equilavg,',',anti%equilstd,',',&
        full%equilavg,',',full%equilstd,',',percy%equilavg,',',percy%equilstd,&
        ',',nematic%equilavg ,',',nematic%equilstd,',',allign%equilavg,',',allign%equilstd
    close (unit = annealiounit, status = 'KEEP')

    write(mmiounit, *) boundary_index, ',', upper_nematic_boundary, ',', lower_nematic_boundary, ',', &
        n_ul, ',', n_uu, ',', n_lu, ',', n_ll, ',', t_u, ',', t_l 
    close (unit = mmiounit, status = 'KEEP')
end subroutine close_files

subroutine record_position_circles ()
    implicit none 
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    type(position) :: ri
    character(len=15), parameter :: positive = blue
    character(len=15), parameter :: negative = red 
    character(len=15), parameter :: neutral = white 
    character(len=15), parameter :: A = green
    character(len=15), parameter :: B = orange
    integer :: i, m, q ! indexing parameters
    character(len=20) :: format, string, charge, type 

    format = "(2(' ', F7.3))"

    write(coorsphiounit,*) mols 
    write(coorsphiounit,*) ' x, y, polcolor (3), chiralcolor (3) ' ! comment line frame number starting from 1
    do i = 1, cube
        do m = 1, mer
            ! calculate the real position of the particle
            do q = 1, ndim
                ri%r(q) = square(i)%circle(m)%fpos%r(q) + square(i)%circle(m)%vel%v(q) * tsl
            enddo
            ! format the position
            write(string, format) ri%r(1), ri%r(2)
            ! determine the chairality of the sphere  
            ! determine the polarization of the sphere 
            select case (square(i)%circle(m)%pol)
            case (-1)
                charge = negative
                select case (square(i)%chai)
                case (1)
                    type = A 
                case (2) 
                    type = B
                case default
                    type = white
                end select 
            case (1) 
                charge = positive
                select case (square(i)%chai)
                case (1)
                    type = A 
                case (2) 
                    type = B
                case default
                    type = white
                end select 
            case default 
                charge = neutral
                type = white
            end select 
            ! write the description 
            write (coorsphiounit, *) trim(string), trim(charge), trim(type)
        end do 
    end do 
end subroutine record_position_circles

subroutine record_position_squares ()
    implicit none 
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    type(position), dimension(mer) :: rcircles ! position of the group of particles making up the square
    type(position) :: rsquare, dr ! position of the square
    real(kind=dbl) :: phi ! angle of the particle relative to the x-axis
    real(kind=dbl) :: x, y, z, w, t ! components of a quaternion
    real(kind=dbl), dimension(3,3) :: rotate ! rotation matrix
    character(len=15), parameter :: positive = blue
    character(len=15), parameter :: negative = red 
    character(len=15), parameter :: neutral = white 
    character(len=15), parameter :: A = green
    character(len=15), parameter :: B = orange
    integer :: i, m, q ! indexing parameters
    character(len=20) :: num, format, string, charge, typenum, typecol, qxy, qzw

    format = "(2(' ', F7.3))"

    write(coorsquiounit,*) cube
    write(coorsquiounit,*) ' position (xy), orientation (xyzw), particle type, chiralcolor (RBG) ' ! comment line frame number starting from 1
    do i = 1, cube
        ! calculate the real position of all circles
        do m = 1, mer
            do q = 1, ndim
                ! calculate the real position of the first circle
                rcircles(m)%r(q) = square(i)%circle(m)%fpos%r(q) + square(i)%circle(m)%vel%v(q) * tsl
            enddo
            call apply_periodic_boundaries (rcircles(m))
        enddo
        ! calculate the orientation of the particle relative to the x-axis by determining its quaternion
        ! calculate the angle of the particle relative to the x-axis
        phi = 0.
        do q = 1, ndim 
            dr%r(q) = rcircles(1)%r(q) - rcircles(2)%r(q)
            if (dr%r(q) >= 0.5*region) dr%r(q) = dr%r(q) - region 
            if (dr%r(q) < -0.5*region) dr%r(q) = dr%r(q) + region
            phi = phi + (dr%r(q) ** 2)
        enddo
        phi = sqrt(phi) 
        phi = (dr%r(1)) / phi 
        phi = acos(phi) ! bounds [-1, 1], range [0, pi] 
        if (dr%r(2) < 0) phi = -phi
        ! calculate the rotation matrix of the square using angle
        rotate(1,1) = cos(phi)
        rotate(1,2) = sin(phi)
        rotate(1,3) = 0.
        rotate(2,1) = -sin(phi)
        rotate(2,2) = cos(phi)
        rotate(2,3) = 0.
        rotate(3,1) = 0. 
        rotate(3,2) = 0.
        rotate(3,3) = 1.
        ! calculate the quaternion using the rotation matrix
        x = 0.
        y = 0.
        z = 0.
        w = 0. 
        if (rotate(3,3) < 0.) then 
            ! won't occur
        else
            if (rotate(1,1) < -rotate(2,2)) then 
                t = 1 - rotate(1,1) - rotate(2,2) + rotate(3,3)
                x = rotate(3,1) + rotate(1,3)
                y = rotate(2,3) + rotate(3,2)
                z = t
                w = rotate(1,2) - rotate(2,1)
            else
                t = 1 + rotate(1,1) + rotate(2,2) + rotate(3,3)
                x = rotate(2,3) - rotate(3,2)
                y = rotate(3,1) - rotate(1,3)
                z = rotate(1,2) - rotate(2,1)
                w = t
            endif
        endif
        t = 0.5 / sqrt(t)
        x = t * x 
        y = t * y 
        z = t * z 
        w = t * w 
        ! record the quaternion 
        write(qxy, format) x, y 
        write(qzw, format) z, w 

        ! determine the color of the square
        write (num, '(" ", I4)') i 
        write (typenum, '(" ", I4)') square(i)%chai
        select case (square(i)%chai)
        case (1)
            typecol = A 
        case (2)
            typecol = B 
        case default 
            typecol = white 
        end select 

        ! calculate the center of the square particle based on the position of the first particle
        rsquare%r(1) = rcircles(1)%r(1) + (sqrt(2.) / 2.) * cos((5. * pi / 4.) + phi)
        rsquare%r(2) = rcircles(1)%r(2) + (sqrt(2.) / 2.) * sin((5. * pi / 4.) + phi)
        ! apply preiodic boundary conditions
        call apply_periodic_boundaries (rsquare)
        write(string, format) rsquare%r(1), rsquare%r(2)

        ! report the description
        write(coorsquiounit, *) trim(num), trim(string), trim(qxy), trim(qzw), trim(typenum), trim(typecol)
    end do 
end subroutine record_position_squares

subroutine report_properties()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer :: q 

    ! average properties
	do q = 1, ndim
        call accumulate_properties (lm(q), 3) ! calculate the average linear momentum
	end do
    call accumulate_properties (te, 3) ! calculate the average total energy 
    call accumulate_properties (pot, 3) ! calculate the average potential energy
    call accumulate_properties (ke, 3) ! calculate the average kinetic energy 
    call accumulate_properties (temp, 3) ! calculate the average temperature 
    call accumulate_properties (h2ts, 3) ! calculate the average head-to-tail-same order parameter value 
    call accumulate_properties (poly1, 3)
    call accumulate_properties (poly1aa, 3) ! calculate the average aa polymerization
    call accumulate_properties (poly1abba, 3) ! calculate the average ab-ba polymerization
    call accumulate_properties (poly1bb, 3) ! calculate the average bb polymerization
    call accumulate_properties (h2ts, 3) ! calculate the average head-to-tail-same order parameter value
    call accumulate_properties (h2to, 3) ! calculate the average head-to-tail-opposite order parameter value
    call accumulate_properties (anti, 3) ! calculate the average antiparallel order parameter value 
    call accumulate_properties (poly2, 3) ! calculate the average polymerization order parameter value 
    call accumulate_properties (full, 3) ! calculate the average fully-assembled order parameter value
    call accumulate_properties (fulls, 3) ! calculate the average fully-assembled-same order parameter value
    call accumulate_properties (fullo, 3) ! calculate the average fully-assembled-oppo order parameter value
    call accumulate_properties (percy, 3) ! calculate the average percolation order parameter value
    call accumulate_properties (nclust, 3) ! calculate the average number of clusters
    call accumulate_properties (nematic, 3) ! calculate the average nematic order parameter 
    call accumulate_properties (allign, 3)
    z%value = (pv%sum / (2. * real(cube) * timeperiod * temp%sum)) + real(mer) ! calculate compressability factor, equation 8 in Erpenbeck et al.

    ! report values to the user 
    write(simiounit,"(' ',F9.2,' ',F7.1,' ',6('   ',F6.3))") timenow, real(n_events)/1e6, &
        te%sum, pot%sum, ke%sum, temp%sum, lm(1)%sum+lm(2)%sum, nematic%sum
    write(reportiounit, *) timenow, ',', n_events, ',', te%sum, ',', te%sum2, ',', ke%sum,',', &
        ke%sum2, ',', pot%sum, ',', pot%sum2, ',', temp%sum, ',', temp%sum2, ',', (lm(1)%sum+lm(2)%sum), &
        ',', z%value, ',', n_col, ',', n_ghost, ',', n_thermostat, ',',n_field,',',(n_col / timenow), ',', &
        n_bond, ',', n_hard, ',', n_well
    write(opiounit, *) timenow, ',', n_events, ',', h2ts%sum, ',', h2ts%sum2, ',', h2to%sum, ',', h2to%sum2, &
        ',', anti%sum,',', ',', anti%sum2, ',', poly2%sum, ',', poly2%sum2, ',', full%sum, ',', full%sum2, &
        ',', fulls%sum, ',', fulls%sum2, ',', fullo%sum, ',', fullo%sum2, ',', poly1aa%sum, ',', poly1aa%sum2, &
        ',', poly1abba%sum, ',', poly1abba%sum2, ',', poly1bb%sum, ',', poly1bb%sum2, ',', &
        poly1%sum,',', poly1%sum2, ',', percy%sum, ',', nclust%sum, ',', nclust%sum2, ',', nematic%sum, &
        ',', nematic%sum2, ',', allign%sum, ',', allign%sum2

    ! if the system has equilibraited, accumulate equilibrium sums
	if (n_events > event_equilibriate) then 
		do q = 1, ndim
            call accumulate_properties (lm(q), 4)
		end do 
        call accumulate_properties (te, 4)
        call accumulate_properties (pot, 4)
        call accumulate_properties (ke, 4)
        call accumulate_properties (temp, 4)
        call accumulate_properties (poly1, 4)
        call accumulate_properties (poly1aa, 4)
        call accumulate_properties (poly1abba, 4) 
        call accumulate_properties (poly1bb, 4)
        call accumulate_properties (h2ts, 4)
        call accumulate_properties (h2to, 4)
        call accumulate_properties (anti, 4)
        call accumulate_properties (poly2, 4)
        call accumulate_properties (full, 4)
        call accumulate_properties (fulls, 4)
        call accumulate_properties (fullo, 4)
        call accumulate_properties (percy, 4)
        call accumulate_properties (nclust, 4)
        call accumulate_properties (nematic, 4)
        call accumulate_properties (allign, 4)
        call accumulate_properties (z, 2)
	end if 

    ! reset property accumulation
	do q = 1, ndim
        call accumulate_properties (lm(q), 1)
	end do
    call accumulate_properties (te, 1)
    call accumulate_properties (pot, 1)
    call accumulate_properties (ke, 1)
    call accumulate_properties (temp, 1)
    call accumulate_properties (pv, 1)
    call accumulate_properties (poly1, 1)
    call accumulate_properties (poly1aa, 1)
    call accumulate_properties (poly1abba, 1)
    call accumulate_properties (poly1bb, 1)
    call accumulate_properties (h2ts, 1)
    call accumulate_properties (h2to, 1)
    call accumulate_properties (anti, 1)
    call accumulate_properties (poly2, 1)
    call accumulate_properties (full, 1)
    call accumulate_properties (fulls, 1)
    call accumulate_properties (fullo, 1)
    call accumulate_properties (percy, 1)
    call accumulate_properties (nclust, 1)
    call accumulate_properties (nematic, 1)
    call accumulate_properties (allign, 1)
    timeperiod = 0.
end subroutine report_properties


! ** propertty methods ****************************************

subroutine initialize_properties ()
    implicit none 
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer :: m

    call accumulate_properties (te, 0)
    call accumulate_properties (ke, 0)
    call accumulate_properties (pot, 0)
	do m = 1, ndim
        call accumulate_properties (lm(m), 0)
	end do
    call accumulate_properties (temp, 0)
    call accumulate_properties (pv, 0)
    call accumulate_properties (z, 0)
    call accumulate_properties (poly1, 0)
    call accumulate_properties (poly1aa, 0)
    call accumulate_properties (poly1abba, 0)
    call accumulate_properties (poly1bb, 0)
    call accumulate_properties (h2ts, 0)
    call accumulate_properties (h2to, 0)
    call accumulate_properties (anti, 0)
    call accumulate_properties (poly2, 0)
    call accumulate_properties (full, 0)
    call accumulate_properties (fulls, 0)
    call accumulate_properties (fullo, 0)
    call accumulate_properties (percy, 0)
    call accumulate_properties (nclust, 0)
    call accumulate_properties (nematic, 0)
    call accumulate_properties (allign, 0)
end subroutine initialize_properties

subroutine calculate_poperties()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    type(velocity) :: vsum 
    real(kind=dbl) :: vvsum 
    integer :: i, m, q 

    ! initialize parameters 
    vvsum = 0.
	do q = 1, ndim
        vsum%v(q) = 0.
	end do 

    ! sum velocities 
	do i = 1, cube 
		do m = 1, mer 
			do q = 1, ndim 
                vsum%v(q) = vsum%v(q) + square(i)%circle(m)%vel%v(q)
                vvsum = vvsum + (square(i)%circle(m)%vel%v(q) ** 2)
			enddo 
		enddo 
	enddo

    ! ** Linear Momentum *****************************************
	do q = 1, ndim
        lm(q)%value = (vsum%v(q)) / real(cube) ! linear momentum per cube 
        call accumulate_properties (lm(q), 2)
	end do
    ! ** Potential Energy ****************************************
    call accumulate_potential (pot%value)
    call accumulate_properties (pot, 2)
    ! ** Kinetic Energy ******************************************
    ke%value = (0.5 * vvsum / (real(cube) * real(mer)))
    call accumulate_properties (ke, 2)
    ! ** Total Energy ********************************************
    te%value = ke%value + pot%value 
    call accumulate_properties (te, 2)
    ! ** Temperature *********************************************
    temp%value = 2. * ke%value / (real(ndim))
    call accumulate_properties (temp, 2)
    ! ** Order Parameters ****************************************
    call determine_assembly (poly1%value, poly1aa%value, poly1abba%value, poly1bb%value, h2ts%value, &
        h2to%value, anti%value, poly2%value, full%value, fulls%value, fullo%value)
    call accumulate_properties (poly1, 2)
    call accumulate_properties (poly1aa, 2)
    call accumulate_properties (poly1abba, 2)
    call accumulate_properties (poly1bb, 2)
    call accumulate_properties (h2ts, 2)
    call accumulate_properties (h2to, 2)
    call accumulate_properties (anti, 2)
    call accumulate_properties (poly2, 2)
    call accumulate_properties (full, 2)
    call accumulate_properties (fulls, 2)
    call accumulate_properties (fullo, 2)
    ! ** percolation *********************************************
    if (determine_percolation(nclust%value)) then 
        percy%value = 1.
    else
        percy%value = 0.
    endif
    call accumulate_properties (percy, 2)
    call accumulate_properties (nclust, 2)
    ! ** nematic *************************************************
    call determine_nematic (nematic%value)
    call accumulate_properties (nematic, 2)
    ! ** allignment **********************************************
    call calculate_allignment (allign%value)
    call accumulate_properties (allign, 2)
end subroutine calculate_poperties

subroutine accumulate_potential (potential)
    implicit none 
    ! ** calling variables ***********************************
    real(kind=dbl), intent(out) :: potential ! potential accumulation
    ! ** local variables *************************************
    real(kind=dbl) :: rij
    integer :: i, j, m, n, q, o ! indexing parameters 
    
    ! initialize parameters 
    potential  = 0.

    ! loop through all squares 
	do i = 1, cube - 1
		do m = 1, mer 
            ! loop through all up list atoms 
            o = 0 
			uplist: do 
                o = o + 1
                j = square(i)%circle(m)%upnab(o)%one 
                if (j == 0) exit 
                if (i /= j) then 
                    n = square(i)%circle(m)%upnab(o)%two 
                    ! calculate the real distance between the pair
                    rij = distance(square(i)%circle(m), square(j)%circle(n))
					if (rij < sigma2) then ! if the pair is within the first, innermost well
						if ((square(i)%circle(m)%pol * square(j)%circle(n)%pol) == -1) then ! if the spheres are attracted to
                            potential = potential - epsilon2
						else if ((square(i)%circle(m)%pol * square(j)%circle(n)%pol) == 1) then ! if the spheres are repulsed from 
                            potential = potential + epsilon2
						end if 
					else if (rij < sigma3) then ! if the pair is within the second, middle well 
						if ((square(i)%circle(m)%pol * square(j)%circle(n)%pol) == -1) then ! if the spheres are attracted to
                            potential = potential - epsilon3
						else if ((square(i)%circle(m)%pol * square(j)%circle(n)%pol) == 1) then ! if the spheres are repulsed from
                            potential = potential + epsilon3
						end if
					end if
				endif
			enddo uplist
		enddo
	enddo 
    potential = potential / (real(cube) * real(mer)) ! potential energy per sphere
end subroutine accumulate_potential

subroutine accumulate_properties (prop, number)
    implicit none
    ! ** calling variables ***********************************
    type(property), intent(inout) :: prop
    integer, intent(in) :: number
    ! ** local variables *************************************

    if (number == 0) then
        prop%sum = 0.
        prop%sum2 = 0.
        prop%equilavg = 0.
        prop%count = 0
        prop%equilibcount = 0
    else if (number == 1) then 
        prop%sum = 0.
        prop%sum2 = 0.
        prop%count = 0
    else if (number == 2) then
        prop%count = prop%count + 1
        prop%sum = prop%sum + prop%value
        prop%sum2 = prop%sum2 + (prop%value ** 2)
    else if (number == 3) then
        prop%sum = prop%sum / prop%count
        prop%sum2 = sqrt(prop%sum2 / prop%count - (prop%sum ** 2))
    else if (number == 4) then
        prop%equilavg = prop%equilavg + prop%sum 
        prop%equilstd = prop%equilstd + (prop%sum ** 2)
        prop%equilibcount = prop%equilibcount + 1
    else if (number == 5) then 
        prop%equilavg = prop%equilavg / prop%equilibcount
        prop%equilstd = sqrt(prop%equilstd / prop%equilibcount - (prop%equilavg ** 2))
    else
        write(*,*) 'Error in execution of accumulate_properties subroutine'
    end if
end subroutine accumulate_properties

! // assembly order parameters //

subroutine set_orderlist()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    real(kind=dbl) :: rij
    integer :: i, m, j, q, o
    integer, dimension(mols) :: n
    type(id) :: a, b

    ! set all lists to zero 
    n = 1
    do i = 1, cube 
        do m = 1, mer 
            square(i)%circle(m)%orderlist = nullset()
        enddo
    enddo

    ! loop through all pairs using upnab 
    do i = 1, cube 
        do m = 1, mer 
            a%one = i 
            a%two = m 
            q = 0
            uplist: do 
                q = q + 1
                b = square(a%one)%circle(a%two)%upnab(q)
                if (b%one == 0) exit 
                ! if the particle pair not in the same group and oppositely charged 
                if ((b%one > a%one) .and. (square(a%one)%circle(a%two)%pol == -square(b%one)%circle(b%two)%pol)) then
                    ! determine the distance between the pair
                    rij = distance(square(a%one)%circle(a%two), square(b%one)%circle(b%two))
                    ! if the particle pair is less than the maximum distance of seperation 
                    if (rij < orderwidth) then ! record each pair 
                        o = id2mol(a%one, a%two)
                        if (n(o) < (orderlength + 1)) then 
                            square(a%one)%circle(a%two)%orderlist(n(o)) = b
                            n(o) = n(o) + 1
                        endif
                        j = id2mol(b%one, b%two)
                        if (n(j) < (orderlength + 1)) then 
                            square(b%one)%circle(b%two)%orderlist(n(j)) = a 
                            n(j) = n(j) + 1
                        endif
                    endif
                endif
            enddo uplist 
        enddo
    enddo
end subroutine set_orderlist

subroutine update_orderlist(a, b)
    implicit none
    ! ** calling variables ***********************************
    type(id), intent(in) :: a, b
    ! ** local variables *************************************
    real(kind=dbl) :: rij
    integer :: n

    ! if the pair are bound to each other, or not oppositely charged 
    if ((a%one == b%one) .or. (square(a%one)%circle(a%two)%pol * square(b%one)%circle(b%two)%pol /= -1)) return

    ! determine the distance between the pair 
    rij = distance(square(a%one)%circle(a%two), square(b%one)%circle(b%two))
    if (rij < orderwidth) then ! if the pair are within range after the event has occured 
        ! add the pair to each other's list, if they are not there already
        ! update order list of particle a 
        n = 0 
        add2a: do 
            n = n + 1
            if (idequiv(square(a%one)%circle(a%two)%orderlist(n), b)) exit
            if (idequiv(square(a%one)%circle(a%two)%orderlist(n), nullset())) then 
                square(a%one)%circle(a%two)%orderlist(n) = b 
                exit 
            endif
        enddo add2a
        ! update orderlist of particle b
        n = 0
        add2b: do 
            n = n + 1
            if (idequiv(square(b%one)%circle(b%two)%orderlist(n), a)) exit
            if (idequiv(square(b%one)%circle(b%two)%orderlist(n), nullset())) then 
                square(b%one)%circle(b%two)%orderlist(n) = a 
                exit 
            endif
        enddo add2b
    else ! if the pair are not within range 
        ! remove any occurances of the pair from and then update each other's lists
        do n = 1, orderlength
            ! delete the partner, if it is in the list 
            if (idequiv(square(a%one)%circle(a%two)%orderlist(n), b)) square(a%one)%circle(a%two)%orderlist(n) = nullset()
            if (idequiv(square(b%one)%circle(b%two)%orderlist(n), a)) square(b%one)%circle(b%two)%orderlist(n) = nullset()
            ! if the element is empty, shift the list forward 
            if (n /= orderlength) then 
                if (idequiv(square(a%one)%circle(a%two)%orderlist(n), nullset())) then 
                    square(a%one)%circle(a%two)%orderlist(n) = square(a%one)%circle(a%two)%orderlist(n + 1)
                    square(a%one)%circle(a%two)%orderlist(n + 1) = nullset()
                endif
                if (idequiv(square(b%one)%circle(b%two)%orderlist(n), nullset())) then 
                    square(b%one)%circle(b%two)%orderlist(n) = square(b%one)%circle(b%two)%orderlist(n + 1)
                    square(b%one)%circle(b%two)%orderlist(n + 1) = nullset()
	            endif
	        endif
	    enddo 
    endif
end subroutine update_orderlist

subroutine determine_assembly (poly1, aa, abba, bb, head2tailsame, head2tailoppo, antiparallel, poly2, &
    fullyassembeled, fullass_s, fullass_o)
    implicit none
    ! ** calling variables ***********************************
    real(kind=dbl), intent(out) :: poly1, aa, abba, bb, head2tailsame, head2tailoppo, antiparallel, poly2, &
    fullyassembeled, fullass_s, fullass_o
    ! ** local variables *************************************
    type(id), dimension(orderlength) :: ipartner, jpartner ! cube partners of polarized spheres 
    type(id) :: i, j
    integer :: n, m, iindex, jindex, o, p ! indexing 
    logical :: samesame, sameoppo, samepartner, diffpartner, diffpartner_oppochai, diffpartner_samechai  ! logical values for recording the order


    ! initialize values 
    poly1 = 0.
    aa = 0.
    abba = 0. 
    bb = 0.
    head2tailsame = 0.
    head2tailoppo = 0.
    antiparallel = 0.
    poly2 = 0.
    fullyassembeled = 0.
    fullass_s = 0.
    fullass_o = 0.

    eachcube: do n = 1, cube ! for each cube 
        i%one = n 
        i%two = 1 ! first polarized particle is the first sphere
        j%one = n 
        j%two = 2 ! HARD CODE: second polarized particle is the second sphere
        ipartner = nullset()
        jpartner = nullset()
        iindex = 0
        jindex = 0
        ! record cubic partners of i 
        ilist: do m = 1, orderlength 
            if (idequiv(square(i%one)%circle(i%two)%orderlist(m), nullset())) exit
            ! record that partner 
            iindex = iindex + 1
            ipartner(iindex) = square(i%one)%circle(i%two)%orderlist(m) ! partner to polarized particle i 
        enddo ilist 
        ! record cubic partners of j 
        jlist: do m = 1, orderlength
            if (idequiv(square(j%one)%circle(j%two)%orderlist(m), nullset())) exit 
            ! record that partner 
            jindex = jindex + 1
            jpartner(jindex) = square(j%one)%circle(j%two)%orderlist(m) ! partner to polarized particle j 
        enddo jlist 
        ! calculate the order of cube n 
        samesame = .false.
        sameoppo = .false.
        samepartner = .false.
        diffpartner = .false.
        diffpartner_samechai = .false.
        diffpartner_oppochai = .false.
        if ((iindex >= 1) .or. (jindex >= 1)) then ! if the square has at least one partner 
            if (iindex >= 1) then 
                do o = 1, iindex
                    if (square(n)%chai == square(ipartner(o)%one)%chai) then 
                        samesame = .true.
                    else
                        sameoppo = .true.
                    endif
                end do 
            endif
            if (jindex >= 1) then 
                do p = 1, jindex
                    if (square(n)%chai == square(jpartner(p)%one)%chai) then 
                        samesame = .true.
                    else
                        sameoppo = .true.
                    end if
                end do
            endif
        endif
        if ((iindex >= 1) .and. (jindex >= 1)) then ! if both polarized particles have cubic partners
	        do o = 1, iindex
	            do p = 1, jindex 
                    ! if either of the polarized particles share the same cubic partners
	                if (ipartner(o)%one == jpartner(p)%one) samepartner = .true. ! NOTE: this formation is only possible for same chirality squares
                    ! if either of the polarized particles have different cubic partners 
	                if (ipartner(o)%one /= jpartner(p)%one) then 
                        diffpartner = .true.
                        ! if the two different partners of the first and second polarized spheres share the same chiraility
                        if (square(ipartner(o)%one)%chai == square(jpartner(p)%one)%chai) then 
                            ! if the chairality of those partners is the same as the cube n
                            if (square(n)%chai == square(ipartner(o)%one)%chai) then 
                                diffpartner_samechai = .true.
                            else 
                                diffpartner_oppochai = .true.
                            endif
                        endif
                    endif
	            enddo
	        enddo
	    endif
        if (samesame .or. sameoppo) poly1 = poly1 + 1.
        if ((square(n)%chai == 1) .and. samesame) aa = aa + 1.
        if ((square(n)%chai == 2) .and. samesame) bb = bb + 1.
        if (sameoppo) abba = abba + 1.
        if (samepartner) antiparallel = antiparallel + 1.
        if (diffpartner) poly2 = poly2 + 1. 
        if (diffpartner_samechai) head2tailsame = head2tailsame + 1.
        if (diffpartner_oppochai) head2tailoppo = head2tailoppo + 1.
        if (iindex >= 2 .and. jindex >= 2) then 
            fullyassembeled = fullyassembeled + 1.
            if (diffpartner_oppochai .and. diffpartner_samechai) then 
                fullass_o = fullass_o + 1.
            else if (diffpartner_samechai .and. samepartner) then 
                fullass_s = fullass_s + 1.
            end if 
        end if
    enddo eachcube
    ! normalize order parameters by the number of cubes 
    if (na /= 0) then ! if the system is not entirely b-chirality squares
        aa = aa / real(na)
    end if 
    if (na /= cube) then ! if the system is not entirely a-chirality squares
        bb = bb / real (cube - na)
    end if
    abba = abba / real (cube)
    poly1 = poly1 / real(cube)
    head2tailsame = head2tailsame / real(cube)
    head2tailoppo = head2tailoppo / real(cube)
    antiparallel = antiparallel / real(cube)
    poly2 = poly2 / real(cube)
    fullyassembeled = fullyassembeled / real(cube)
    fullass_o = fullass_o / real(cube)
    fullass_s = fullass_s / real(cube)
end subroutine determine_assembly

! // percolation // 

logical function determine_percolation (n_clusters) ! #percy
    implicit none 
    ! ** calling variables ***********************************
    real(kind=dbl), intent(out) :: n_clusters ! number of clusters identified by the percolation algorithm 
    ! ** local variables *************************************
    logical, parameter :: perc_debug = ((debug >= 1) .and. .true.)
    logical, dimension(ndim) :: percolation 
    integer :: i, m, n
    type(id) :: a 

    ! intialize peroclation conditions
    call initialize_percolation ()
    determine_percolation = .false.
    ! loop through all atoms and begin cluster analysis if the particle has not yet been visited
    n = 0
    do i = 1, cube
        do m = 1, mer 
            if (.not. square(i)%circle(m)%percy%visited) then 
                n = n + 1
                if (perc_debug .and. (debug >= 2)) then 
                    write (*,*)
                    write (*,'("Cluster ", I4, " Analysis")') n
                    write (*,'("Root Node: ", 2I5)') i, m 
                    write (*,*)
                endif
                percolation(1) = .false.
                percolation(2) = .false.
                a%one = i 
                a%two = m
                call clusteranal (n, percolation, a)
                if (percolation(1) .and. percolation(2)) determine_percolation = .true.
            endif
        enddo
    enddo

    n_clusters = n
    if (perc_debug) then 
        if (determine_percolation) then 
            write (*,*) "determine_percolation: ", n," clusters were identified, at least one of which achieved a percolated state."
        else
            write (*,*) "determine_percolation: ", n," clusters were identified, none of which achieved a percolated state."
        endif
    endif
end function determine_percolation

subroutine initialize_percolation() ! #percy
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer :: i, m ! indexing parameters

    do i = 1, cube
        do m = 1, mer 
            square(i)%circle(m)%percy%visited = .false.
            square(i)%circle(m)%percy%cluster = 0
            square(i)%circle(m)%percy%pnode = nullset()
            square(i)%circle(m)%percy%rvec%r(1) = 0.
            square(i)%circle(m)%percy%rvec%r(2) = 0.
        enddo
    enddo
end subroutine initialize_percolation

recursive subroutine clusteranal(clust, perc, a) ! #percy
    implicit none
    ! ** calling variables ***********************************
    logical, parameter :: clusteranal_debug = ((debug >= 2) .and. .true.)
    real(kind=dbl), parameter :: cluster_dist = sigma3
    integer, intent(in) :: clust
    logical, dimension(ndim) :: perc
    type(id), intent (in) :: a
    ! ** local variables *************************************
    type(id) :: b 
    integer :: n, q
    real(kind=dbl) :: dist 
    type(position) :: dvec

    ! mark that the current node has been visited
    square(a%one)%circle(a%two)%percy%visited = .true.
    square(a%one)%circle(a%two)%percy%cluster = clust 

    ! loop through all partciles that are uplist or down list of a
    n = 0
    upnab: do 
        n = n + 1 
        b = square(a%one)%circle(a%two)%upnab(n)
        if (b%one == 0) exit
        dist = distance(square(a%one)%circle(a%two), square(b%one)%circle(b%two))
        ! if the pair are oppositely polarized and within the minimum distance 
        ! or the pair are in the same grouping
        if (clusteranal_debug) write (*,'("Compare ", 2I5, " to ", 2I5, " (", I2, F6.2,")")') a%one, &
            a%two, b%one, b%two, square(a%one)%circle(a%two)%pol * square(b%one)%circle(b%two)%pol, dist
        if (((dist <= cluster_dist) .and. (square(a%one)%circle(a%two)%pol * &
            square(b%one)%circle(b%two)%pol == -1)) .or. (a%one == b%one)) then 
            ! calculate the difference vector between the two
            dvec = distance_vector (square(a%one)%circle(a%two), square(b%one)%circle(b%two))
            if (square(b%one)%circle(b%two)%percy%visited) then ! has the other verticie already been visited?
                ! compare the current spanning vector the one that has been stored with 
                do q = 1, ndim 
                    dvec%r(q) = square(a%one)%circle(a%two)%percy%rvec%r(q) + dvec%r(q)
                    ! determine if percolation has occured in each dimensions
                    if (abs(square(b%one)%circle(b%two)%percy%rvec%r(q) - dvec%r(q)) >= (region - tol)) perc(q) = .true.
                enddo
            else 
                ! calculate and store the spanning vector
                do q = 1, ndim
                    square(b%one)%circle(b%two)%percy%rvec%r(q) = square(a%one)%circle(a%two)%percy%rvec%r(q) + dvec%r(q)
                enddo
                ! call the recursive subroutine
                square(b%one)%circle(b%two)%percy%pnode = a
                if (clusteranal_debug) write(*,'("Start Recursion: ", 2I5)') b%one, b%two
                call clusteranal (clust, perc, b)
                if (clusteranal_debug) write(*,'("End Recursion: ", 2I5)') b%one, b%two
            endif
        endif
    enddo upnab

    n = 0
    dnnab: do 
        n = n + 1 
        b = square(a%one)%circle(a%two)%dnnab(n)
        if (b%one == 0) exit
        dist = distance(square(a%one)%circle(a%two), square(b%one)%circle(b%two))
        ! if the pair are oppositely polarized and within the minimum distance 
        ! or the pair are in the same grouping
        if (clusteranal_debug) write (*,'("Compare ", 2I5, " to ", 2I5, " (", I2, F6.2,")")') a%one, &
            a%two, b%one, b%two, square(a%one)%circle(a%two)%pol * square(b%one)%circle(b%two)%pol, dist
        if (((dist <= cluster_dist) .and. (square(a%one)%circle(a%two)%pol * &
            square(b%one)%circle(b%two)%pol == -1)) .or. (a%one == b%one)) then 
            ! calculate the difference vector between the two
            dvec = distance_vector (square(a%one)%circle(a%two), square(b%one)%circle(b%two))
            if (square(b%one)%circle(b%two)%percy%visited) then ! has the other verticie already been visited?
                ! compare the current spanning vector the one that has been stored with 
                do q = 1, ndim 
                    dvec%r(q) = square(a%one)%circle(a%two)%percy%rvec%r(q) + dvec%r(q)
                    ! determine if percolation has occured in each dimensions
                    if (abs(square(b%one)%circle(b%two)%percy%rvec%r(q) - dvec%r(q)) >= (region - tol)) perc(q) = .true.
                enddo
            else 
                ! calculate and store the spanning vector
                do q = 1, ndim
                    square(b%one)%circle(b%two)%percy%rvec%r(q) = square(a%one)%circle(a%two)%percy%rvec%r(q) + dvec%r(q)
                enddo
                ! call the recursive subroutine
                square(b%one)%circle(b%two)%percy%pnode = a
                if (clusteranal_debug) write(*,'("Start Recursion: ", 2I5)') b%one, b%two
                call clusteranal (clust, perc, b)
                if (clusteranal_debug) write(*,'("End Recursion: ", 2I5)') b%one, b%two
            endif
        endif
    enddo dnnab
end subroutine clusteranal

! // nematic order parameter //

subroutine determine_nematic(nematic)
    implicit none
    ! ** calling variables ***********************************
    real(kind=dbl) :: nematic
    ! ** local variables *************************************
    real(kind=dbl), dimension(cube) :: phi
    type(position), dimension(mer) :: rcircles ! position of the group of particles making up the square
    type(position) :: dr
    integer :: i, j, m , q, nem_count ! indexing parameters

    ! intialize the order parameter
    phi = 0.
    nematic = 0. 
    nem_count = 0

    ! calculate and store the real angle of each cube relative to the x-axis
    do i = 1, cube
        ! calculate the real position of all circles
        do m = 1, mer
            do q = 1, ndim
                ! calculate the real position of the first circle
                rcircles(m)%r(q) = square(i)%circle(m)%fpos%r(q) + square(i)%circle(m)%vel%v(q) * tsl
            enddo
            call apply_periodic_boundaries (rcircles(m))
        enddo
        ! calculate the angle of the particle relative to the x-axis
        phi(i) = 0.
        do q = 1, ndim 
            dr%r(q) = rcircles(1)%r(q) - rcircles(2)%r(q)
            if (dr%r(q) >= 0.5*region) dr%r(q) = dr%r(q) - region 
            if (dr%r(q) < -0.5*region) dr%r(q) = dr%r(q) + region
            phi(i) = phi(i) + (dr%r(q) ** 2)
        enddo
        phi(i) = sqrt(phi(i)) 
        phi(i) = (dr%r(1)) / phi(i)
        phi(i) = acos(phi(i)) ! bounds [-1, 1], range [0, pi] 
        if (dr%r(2) < 0) phi(i) = -phi(i)
    end do

    ! calculate the difference in orientation between all cubic pairs 
    do i = 1, (cube - 1)
        do j = i + 1, cube 
            nematic = nematic + (cos(phi(i) - phi(j)) ** 2)
            nem_count = nem_count + 1
        enddo
    enddo
    nematic = nematic / real(nem_count) 
    nematic = (3. * nematic - 1.) / 2.
end subroutine determine_nematic

! // allignment order parameter //

subroutine calculate_allignment(op)
    implicit none 
    real(kind=dbl) :: op
    integer :: i, m, q ! indexing
    real(kind=dbl), dimension(cube) :: phi ! orientation of each colloid relative to the x-axis
    type(position), dimension(mer) :: rcircles ! position of all disks making the colloid
    type(position) :: dr ! used as intermediary for angle calculation

    !! TODO :: update allignment order parameter so that the allignment is measured
    !!         relative to the external field (right now, diredction is assumed to be y-axis)

    ! loop through particles, 
    ! measure angle relative to external field
    ! initialize variables
    phi = 0.
    op = 0.

    ! calculate and store the orientation of each particle relative to the x-axis
    do i = 1, cube 
        ! calculate the real position of all of the circles from the false position
        do m = 1, mer 
            do q = 1, ndim 
                rcircles(m)%r(q) = square(i)%circle(m)%fpos%r(q) + square(i)%circle(m)%vel%v(q) * tsl 
            enddo
            call apply_periodic_boundaries (rcircles(m))
        enddo

        ! calculate the angle of the colloid relative to the x-axis
        phi(i) = 0.
        do q = 1, ndim 
            dr%r(q) = rcircles(1)%r(q) - rcircles(mer)%r(q) ! orientation of rod from first to last disc
            if (dr%r(q) >= 0.5*region) dr%r(q) = dr%r(q) - region 
            if (dr%r(q) < -0.5*region) dr%r(q) = dr%r(q) + region
            phi(i) = phi(i) + (dr%r(q) ** 2)
        enddo
        phi(i) = sqrt(phi(i)) ! distance vector
        phi(i) = (dr%r(2)) / phi(i) ! normalized y-distance
        ! phi(i) = asin(phi(i)) ! bounds [-1, 1], range [-halfpi, halfpi] 
        ! if (dr%r(1) < 0.) phi(i) = -phi(i)
    end do

    ! calculate the angle of the particle relative to
    ! the direction of the field
    do i = 1, cube
        op = op + phi(i)
    enddo

    ! average and return
    op = op / real(cube)
end subroutine calculate_allignment

! ** event scheduling *****************************************

! subroutine that integrates the system forward halfway to the next event
subroutine half_forward () 
    implicit none
    real(kind=dbl), parameter :: half = 0.5
    type(event) :: next_event
    type(id) :: a, b ! uplist and downlist event pair 
    integer :: i, m, q
    integer :: check

    check = 0
    do
        ! find and save the next event 
        n_events = n_events + 1
        next_event = reset_event ()
        i = findnextevent(eventTree)
        if (i <= mols) then ! collision event
            a = mol2id(i)
            next_event = square(a%one)%circle(a%two)%schedule
            b = square(a%one)%circle(a%two)%schedule%partner
        elseif (i == mols+1) then ! ghost event
            next_event = thermostat_event
            a%one = cube + 1
            a%two = 0
            b = thermostat_event%partner
        elseif (i == mols + 2) then ! field event
            next_event = field_event
            a%one = cube + 2 
            a%two = 0
            b = field_event%partner
        endif

        ! notify user about next event
        if (debug >= 1) then
            if (a%one <= cube) then 
                write(simiounit,110) n_events, next_event%time, a%two, a%one, b%two, b%one, next_event%type
                110 format(' event ', I8, ' in ', F8.5, ' seconds: ', I3, ' of ', I5, ' will collide with ', &
                    I3,' of ', I5, ' (type ', I3,').')
            else if (a%one == (cube + 1)) then 
                write (simiounit, 120) n_events, next_event%time
                    120 format(' event ', I8, ' in ', F8.5, ' seconds: thermostat ghost collision event.')
            else if (a%one == (cube + 2)) then 
                write (simiounit, 130) n_events, next_event%time
                130 format (' event ', I8, ' in ', F8.5, ' seconds: field ghost collision event.')
            end if 
        endif

        ! if step length is less than zero 
        if (next_event%time < 0) then ! abort
            write(simiounit,*) 'forward: negative time calculated. reseting simulation from save files.'
            call restart ()
            check = check + 1
            if (check > 100) then 
                write (simiounit, *) 'forward: unable to restart system after negative time calculation'
                call exit (NONZERO_EXITCODE)
            endif
        else
            exit
        endif
    enddo

    ! integrate the system forward half way to the next event
    next_event%time = half * next_event%time

    ! subtract elapsed times from event calander
    ! TODO: store event times as occuring relative to the current position in time, which removes this step and possible O(N) calculation each step
    ! (or store events relative to the most recent false position update, and update the events times at each false position update)
    timenow = timenow + next_event%time
    timeperiod = timeperiod + next_event%time 
    tsl = tsl + next_event%time
    do i = 1, cube 
        do m = 1, mer 
            square(i)%circle(m)%schedule%time = square(i)%circle(m)%schedule%time - next_event%time 
        end do 
    end do 
    thermostat_event%time = thermostat_event%time - next_event%time
    field_event%time = field_event%time - next_event%time
    if (debug >= 1) then 
        if (check_boundaries()) then 
            write (*,*) 'forward: bounary overlap. program will abort now'
            call exit (NONZERO_EXITCODE)
        endif
    endif
end subroutine half_forward

subroutine forward (next_event, a, b)
    implicit none 
    ! ** calling variables ***********************************
    type(event) :: next_event
    type(id), intent(inout) :: a, b ! uplist and downlist event pair 
    ! ** local variables *************************************
    integer :: i, m, q
    integer :: check

    check = 0
    do
        ! find and save the next event 
        n_events = n_events + 1
        next_event = reset_event ()
        i = findnextevent(eventTree)
        if (i <= mols) then ! collision event
            a = mol2id(i)
            next_event = square(a%one)%circle(a%two)%schedule
            b = square(a%one)%circle(a%two)%schedule%partner
        elseif (i == mols+1) then ! ghost event
            next_event = thermostat_event
            a%one = cube + 1
            a%two = 0
            b = thermostat_event%partner
        elseif (i == mols + 2) then ! field event
            next_event = field_event
            a%one = cube + 2 
            a%two = 0
            b = field_event%partner
        endif

        ! notify user about next event
    	if (debug >= 1) then
    		if (a%one <= cube) then 
                write(simiounit,110) n_events, next_event%time, a%two, a%one, b%two, b%one, next_event%type
    			110 format(' event ', I8, ' in ', F8.5, ' seconds: ', I3, ' of ', I5, ' will collide with ', &
                    I3,' of ', I5, ' (type ', I3,').')
    		else if (a%one == (cube + 1)) then 
                write (simiounit, 120) n_events, next_event%time
                120 format(' event ', I8, ' in ', F8.5, ' seconds: thermostat ghost collision event.')
            else if (a%one == (cube + 2)) then 
                write (simiounit, 130) n_events, next_event%time
                130 format (' event ', I8, ' in ', F8.5, ' seconds: field ghost collision event.')
    		end if 
    	endif

        ! if step length is less than zero 
    	if (next_event%time < 0) then ! abort
            write(simiounit,*) 'forward: negative time calculated. reseting simulation from save files.'
            call restart ()
            check = check + 1
            if (check > 100) then 
                write (simiounit, *) 'forward: unable to restart system after negative time calculation'
                call exit (NONZERO_EXITCODE)
            endif
    	else
            exit
        endif
    enddo

    ! subtract elapsed times from event calander
    ! TODO: store event times as occuring relative to the current position in time, which removes this step and possible O(N) calculation each step
    ! (or store events relative to the most recent false position update, and update the events times at each false position update)
    timenow = timenow + next_event%time
    timeperiod = timeperiod + next_event%time 
    tsl = tsl + next_event%time
	do i = 1, cube 
		do m = 1, mer 
            square(i)%circle(m)%schedule%time = square(i)%circle(m)%schedule%time - next_event%time 
		end do 
	end do 
    thermostat_event%time = thermostat_event%time - next_event%time
    field_event%time = field_event%time - next_event%time
    if (debug >= 1) then 
        if (check_boundaries()) then 
            write (*,*) 'forward: bounary overlap. program will abort now'
            call exit (NONZERO_EXITCODE)
        endif
    endif
end subroutine forward

! // collision events //

subroutine predict(a, b)
    implicit none
    ! ** calling variables ***********************************
    type(id), intent(in) :: a, b ! pair 
    ! ** local variables *************************************
    type(position) :: rij
    type(velocity) :: vij 
    type(event) :: prediction
    integer :: j, n, q

    ! check that b is uplist of a 
    ! otherwise leave subroutine 
	if ((a%one > b%one) .or. ((a%two >= b%two) .and. (a%one == b%one))) return 

    ! calculate rij and vij 
	do q = 1, ndim 
        ! calculate the false position of the particle pair
        rij%r(q) = square(a%one)%circle(a%two)%fpos%r(q) - square(b%one)%circle(b%two)%fpos%r(q)
        vij%v(q) = square(a%one)%circle(a%two)%vel%v(q) - square(b%one)%circle(b%two)%vel%v(q)
        ! calculate the real position of the particle pair
        rij%r(q) = rij%r(q) + vij%v(q) * tsl
        ! apply minimum image convention
		if (rij%r(q) >= (0.5 * region)) rij%r(q) = rij%r(q) - region 
		if (rij%r(q) < (-0.5 * region)) rij%r(q) = rij%r(q) + region 
	end do 

    ! predict next event between pair 
    prediction = reset_event()
	if (a%one == b%one) then ! if the particle pair are part of the same group 
		if (neighborbonded (a%two, b%two)) then 
            prediction = neighborbond_event (rij, vij, b%one, b%two)
		else if (crossbonded (a%two, b%two)) then
            prediction = crossbond_event (rij, vij, b%one, b%two)
		else
            prediction = hardsphere_event (rij, vij, b%one, b%two)
		end if
	else if (b%one > a%one) then ! if b is an uplist group of a 
		if ((square(a%one)%circle(a%two)%pol * square(b%one)%circle(b%two)%pol) /= 0) then 
            prediction = polsphere_event (rij, vij, b%one, b%two)
		else 
            prediction = hardsphere_event (rij, vij, b%one, b%two)
		end if 
	end if 

    ! schedule event between pair, if sooner
	if (sooner(prediction, square(a%one)%circle(a%two)%schedule)) then 
            square(a%one)%circle(a%two)%schedule = prediction
	end if 
end subroutine predict

type(event) function neighborbond_event (rij, vij, j, n)
    implicit none  
    ! ** calling variables ***********************************
    type(position), intent(in) :: rij 
    type(velocity), intent(in) :: vij 
    integer, intent(in) :: j ! uplist group 
    integer, intent(in) :: n ! uplist particle of uplist group 
    ! ** local variables *************************************
    real(kind=dbl) :: aij, bij, icij, ocij ! quadratic equation constants wrt inner and outer neighbor bond 
    real(kind=dbl) :: idiscr, odiscr ! discrimenant wrt icij and ocij respectively

    ! determine the event partner
    neighborbond_event%partner%one = j
    neighborbond_event%partner%two = n 

    ! calculate quadratic parameters 
    aij = (vij%v(1) ** 2) + (vij%v(2) ** 2)
    bij = (rij%r(1) * vij%v(1)) + (rij%r(2) * vij%v(2))
    icij = (rij%r(1) ** 2) + (rij%r(2) ** 2) - (inbond ** 2)
    ocij = (rij%r(1) ** 2) + (rij%r(2) ** 2) - (onbond ** 2)
    idiscr = (bij ** 2) - (aij * icij)
    odiscr = (bij ** 2) - (aij * ocij)

    ! determine the event type and time 
	if (bij < 0.) then ! the centers are approaching
		if (idiscr > 0.) then ! the centers will collide 
            neighborbond_event%type = 8 ! an event will occur at the inner bond length
            neighborbond_event%time = (-bij - sqrt(idiscr)) / aij
		else ! the repulsive centers will miss each other 
            neighborbond_event%type = 9 ! an event will take place at the outer bond length
            neighborbond_event%time = (-bij + sqrt(odiscr)) / aij
		end if 
	else ! the centers are receding
        neighborbond_event%type = 9 ! an event will occur at the outer bond length 
        neighborbond_event%time = (-bij + sqrt(odiscr)) / aij
	end if 
end function neighborbond_event

type(event) function crossbond_event (rij, vij, j, n)
    implicit none  
    ! ** calling variables ***********************************
    type(position), intent(in) :: rij 
    type(velocity), intent(in) :: vij 
    integer, intent(in) :: j ! uplist group 
    integer, intent(in) :: n ! uplist particle of uplist group 
    ! ** local variables *************************************
    real(kind=dbl) :: aij, bij, icij, ocij ! quadratic equation constants wrt inner and outer neighbor bond 
    real(kind=dbl) :: idiscr, odiscr ! discrimenant wrt icij and ocij respectively

    ! determine the event partner
    crossbond_event%partner%one = j
    crossbond_event%partner%two = n

    ! calculate quadratic parameters 
    aij = (vij%v(1) ** 2) + (vij%v(2) ** 2)
    bij = (rij%r(1) * vij%v(1)) + (rij%r(2) * vij%v(2))
    icij = (rij%r(1) ** 2) + (rij%r(2) ** 2) - (icbond ** 2)
    ocij = (rij%r(1) ** 2) + (rij%r(2) ** 2) - (ocbond ** 2)
    idiscr = (bij ** 2) - (aij * icij)
    odiscr = (bij ** 2) - (aij * ocij)

    ! determine the event type and time 
	if (bij < 0.) then ! the centers are approaching
		if (idiscr > 0.) then ! the centers will collide 
            crossbond_event%type = 10 ! an event will occur at the inner bond length
            crossbond_event%time = (-bij - sqrt(idiscr)) / aij
		else ! the repulsive centers will miss each other 
            crossbond_event%type = 11 ! an event will take place at the outer bond length
            crossbond_event%time = (-bij + sqrt(odiscr)) / aij
		end if 
	else ! the centers are receding
        crossbond_event%type = 11 ! an event will occur at the outer bond length 
        crossbond_event%time = (-bij + sqrt(odiscr)) / aij
	end if 
end function crossbond_event

type(event) function hardsphere_event (rij, vij, j, n)
    implicit none 
    ! ** calling variables ***********************************
    type(position), intent(in) :: rij 
    type(velocity), intent(in) :: vij 
    integer, intent(in) :: j ! uplist group 
    integer, intent(in) :: n ! uplist particle of uplist group 
    ! ** local variables *************************************
    real(kind=dbl) :: aij, bij, cij, discr ! quadratic equation constants, discrimenant

    ! determine the event partner
    hardsphere_event%partner%one = j
    hardsphere_event%partner%two = n

    ! calculate quadratic parameters 
    aij = (vij%v(1) ** 2) + (vij%v(2) ** 2)
    bij = (rij%r(1) * vij%v(1)) + (rij%r(2) * vij%v(2))
    cij = (rij%r(1) ** 2) + (rij%r(2) ** 2) - sg1sq
    discr = (bij ** 2) - (aij * cij)

    ! predict if the hard spheres will collide
	if ((discr > 0.) .and. (bij < 0.)) then
        ! calculate the time until collision
        hardsphere_event%type = 1 ! an event will occur at sigma1
        hardsphere_event%time = (-bij - sqrt(discr)) / aij
	else 
        hardsphere_event%type = 0 ! no event will occue
        hardsphere_event%time = bigtime
	end if 
end function hardsphere_event

type(event) function polsphere_event (rij, vij, j, n)
    implicit none 
    ! ** calling variables ***********************************
    type(position), intent(in) :: rij 
    type(velocity), intent(in) :: vij 
    integer, intent(in) :: j ! uplist group 
    integer, intent(in) :: n ! uplist particle of uplist group 
    ! ** local variables *************************************
    real(kind=dbl) :: aij, bij, cij_1, cij_2, cij_3 ! quadratic equation constants wrt to discontinuities 1, 2, 3, and 4
    real(kind=dbl) :: discr1, discr2, discr3 ! discrimenant wrt cij_1, _2, _3, and _4

    ! determine the event partner
    polsphere_event%partner%one = j
    polsphere_event%partner%two = n

    ! calculate quadratic parameters 
    aij = (vij%v(1) ** 2) + (vij%v(2) ** 2)
    bij = (rij%r(1) * vij%v(1)) + (rij%r(2) * vij%v(2))
    cij_1 = (rij%r(1) ** 2) + (rij%r(2) ** 2) - sg1sq ! first discontinuity
    cij_2 = (rij%r(1) ** 2) + (rij%r(2) ** 2) - sg2sq ! second discontinuity
    cij_3 = (rij%r(1) ** 2) + (rij%r(2) ** 2) - sg3sq ! third discontinuity
    discr1 = (bij ** 2) - (aij * cij_1)
    discr2 = (bij ** 2) - (aij * cij_2)
    discr3 = (bij ** 2) - (aij * cij_3)

    ! predict the next event
	if (bij < 0.0) then ! the centers are approaching
		if (cij_2 < 0.0) then ! if rij is within the first well 
			if (discr1 > 0.0) then ! if the cores will collide
                polsphere_event%type = 1 ! an event will occur at sigma1
                polsphere_event%time = (-bij - sqrt(discr1)) / aij
			else ! the cores will miss
                polsphere_event%type = 2 ! an event will take place at sigma2-
                polsphere_event%time = (-bij + sqrt(discr2)) / aij
			end if 
		else if (cij_3 < 0.0) then ! if rij is within the second well
			if (discr2 > 0.0) then ! if the cores will collide
                polsphere_event%type = 3 ! an event will take place at sigma2+
                polsphere_event%time = (-bij - sqrt(discr2)) / aij
			else ! the cores will miss 
                polsphere_event%type = 4 ! an event will take place at sigma3-
                polsphere_event%time = (-bij + sqrt(discr3)) / aij
			end if 
		else ! if rij is outside the square wells
			if (discr3 > 0.0) then ! if the cores will collide
                polsphere_event%type = 5 ! an event will take place at sigma3+
                polsphere_event%time = (-bij - sqrt(discr3)) / aij
			else ! the outermost cores will miss
                polsphere_event%type = 0 ! no event will take place 
                polsphere_event%time = bigtime
			end if 
		end if 
	else ! the centers are receding
		if (cij_2 < 0.0) then ! if rij is within the first well
            polsphere_event%type = 2 ! an event will take place at sigma2-
            polsphere_event%time = (-bij + sqrt(discr2)) / aij
		else if (cij_3 < 0.0) then ! if rij is within the second well
            polsphere_event%type = 4 ! en event will take place at sigma 3-
            polsphere_event%time = (-bij + sqrt(discr3)) / aij
		else ! rij is outside the potential
            polsphere_event%type = 0 ! no event will take place
            polsphere_event%time = bigtime
		end if 
	end if 
end function polsphere_event

subroutine collide (a, b, this_event, w)
    implicit none
    ! ** calling variables ***********************************
    type(id), intent(in) :: a, b ! ids for participating particles 
    type(event), intent(in) :: this_event ! current event 
    real(kind=dbl), intent(out) :: w ! accumulation factor
    ! ** local variables *************************************
    real(kind=dbl), parameter :: smdistance = 5e-12 ! How small can this number be with out impacting my algorith??
    integer, parameter :: debug_collide = 0 ! debugging status of collide subroutine: 0 == off, 1 == on
    type(position) :: rij
    type(velocity) :: vij
    real(kind=dbl), dimension(ndim) :: impulse ! the transfer of energy between the two atoms 
    real(kind=dbl) :: bij, distance, bump, discr2, discr3, discr4, delep ! dot prroduct of moment and velocity vectors, distance between atoms
    real(kind=dbl) :: dispa, dispb ! displacement of a and b particles
    integer :: q ! indexing parameter 

    ! incriment the number of collisions by 1
    n_col = n_col + 1

    !initialize parameters 
    distance = 0.
    bij = 0.
    w = 0.
    dispa = 0.
    dispb = 0.
	do q = 1, ndim 
        ! calculate the false position of the particle pair
        rij%r(q) = square(a%one)%circle(a%two)%fpos%r(q) - square(b%one)%circle(b%two)%fpos%r(q)
        vij%v(q) = square(a%one)%circle(a%two)%vel%v(q) - square(b%one)%circle(b%two)%vel%v(q)
        ! calculate the real position of the particle pair
        rij%r(q) = rij%r(q) + vij%v(q) * tsl
        ! apply minimum image convention
		if (rij%r(q) >= 0.5*region) rij%r(q) = rij%r(q) - region 
		if (rij%r(q) < -0.5*region) rij%r(q) = rij%r(q) + region 
        distance = distance + (rij%r(q) ** 2)
        bij = bij + (rij%r(q) * vij%v(q))
        ! determine the displacement of either particle based on their pre-collision velocities
        dispa = dispa + (square(a%one)%circle(a%two)%vel%v(q) * tsl) ** 2
        dispb = dispb + (square(b%one)%circle(b%two)%vel%v(q) * tsl) ** 2
	end do 
    distance = sqrt(distance)
    ! determine if the pre-collision displacement of either particle is greater than
    ! the maximum displacement required for a neighborlist update
    if (dispa >= dispb) then
        dispa = sqrt(dispa)
        if (dispa >= nbrDispMax) nbrnow = .true.
    else
        dispb = sqrt(dispb)
        if (dispb >= nbrDispMax) nbrnow = .true.
    endif

    ! notify user about location of the particles at the time of the event 
	if ((debug_collide == 1) .and. (debug >= 1)) then 
        write(simiounit, 120) a%two, a%one, b%two, b%one, distance, this_event%type
		120 format ('SUBROUTINE collision: The distance between ', I3, ' of ',I5 &
            , ' and ', I3, ' of ', I5,' is ', F10.8,' (Type ',I2,').')
	end if 

    ! calculate collision dynamics based on event type 
	if (this_event%type == 1) then ! the event is at the repulsive core
		do q = 1, ndim 
            impulse(q) = -rij%r(q) * (bij / sg1sq)
		end do 
        bump = 0.0
        n_hard = n_hard + 1
	else if (this_event%type == 2) then ! the event is a collision at sigma2-
        delep = epsilon2 - epsilon3
		if ((square(a%one)%circle(a%two)%pol * square(b%one)%circle(b%two)%pol) == -1) then ! if the spheres are attracted to one another
            ! determine if the spheres have enough energy required to dissociate
            discr2 = (bij ** 2) - (4. * sg2sq * delep)
			if (discr2 >= 0) then ! if the pair meet the energy requirement
                ! the pair will dissociate
				do q = 1, ndim 
                    impulse(q) = - rij%r(q) * ((bij - sqrt(discr2)) / (2. * sg2sq))
				end do 
                bump = 1.0
			else ! the pair will remain associated ("bounce")
				do q = 1, ndim 
                    impulse(q) = - rij%r(q) * (bij / sg2sq)
				end do 
                bump = -1.0
			end if 
		else ! the spheres are repeled from one another
            ! the pair will dissociate
			do q = 1, ndim 
                impulse(q) = - rij%r(q) * ((bij - sqrt((bij ** 2) + (4. * sg2sq * delep)))/(2. * sg2sq)) ! CHECK THIS!
			end do 
            bump = 1.0
		end if
        n_well = n_well + 1
	else if (this_event%type == 3) then ! the event is a collision at sigma2+
        delep = epsilon2 - epsilon3
		if ((square(a%one)%circle(a%two)%pol * square(b%one)%circle(b%two)%pol) == -1) then ! if the spheres are attracted to one another
            ! the pair will associate 
			do q = 1, ndim 
                impulse(q) = - rij%r(q) * ((bij + sqrt((bij ** 2) + (4. * sg2sq * delep))) / (2. * (sg2sq)))
			end do 
            bump = -1.0
		else ! the spheres are repeled from one another 
            ! determine if the spheres have enough energy required to associate 
            discr2 = (bij ** 2) - (4. * sg2sq * delep)
			if (discr2 >= 0) then ! the the pair meet the energy requirement
                ! the pair will associate
				do q = 1, ndim 
                    impulse(q) = - rij%r(q) * ((bij + sqrt(discr2)) / (2. * sg2sq)) ! CHECK THIS
				end do 
                bump = -1.0
			else ! the pair do not meet the energy requirement
                ! the pair will remain dissociated ("bounce")
				do q = 1, ndim 
                    impulse(q) = - rij%r(q) * (bij / sg2sq) ! CHECK THIS
				end do 
                bump = 1.0
			end if 
		end if
        n_well = n_well + 1
	else if (this_event%type == 4) then ! the event is a collision at sigma 3-
        delep = epsilon3
		if ((square(a%one)%circle(a%two)%pol * square(b%one)%circle(b%two)%pol) == -1) then ! if the spheres are attracted to one another
            ! determine if the spheres have enough energy required to dissociate
            discr3 = bij ** 2 - (4. * sg3sq * delep)
			if (discr3 >= 0) then ! if the pair meet the energy requirement
                ! the pair will dissociate
				do q = 1, ndim 
                    impulse(q) = - rij%r(q) * ((bij - sqrt(discr3)) / (2. * sg3sq))
				end do 
                bump = 1.0
			else ! the pair will remain associated ("bounce")
				do q = 1, ndim 
                    impulse(q) = - rij%r(q) * (bij / sg3sq)
				end do 
                bump = -1.0
			end if 
		else ! the spheres are repeled from one another
            ! the pair will dissociate
			do q = 1, ndim 
                impulse(q) = - rij%r(q) * ((bij - sqrt((bij ** 2) + (4. * sg3sq * delep))) / (2. * sg3sq)) ! CHECK THIS!
			end do 
            bump = 1.0
		end if
        n_well = n_well + 1
	else if (this_event%type == 5) then ! the event is a collision at sigma 3+
        delep = epsilon3
		if ((square(a%one)%circle(a%two)%pol * square(b%one)%circle(b%two)%pol) == -1) then ! if the spheres are attracted to one another
            ! the pair will associate 
			do q = 1, ndim 
                impulse(q) = - rij%r(q) * ((bij + sqrt((bij ** 2) + (4. * sg3sq * delep))) / (2. * (sg3sq)))
			end do 
            bump = -1.0
		else ! the spheres are repeled from one another 
            ! determine if the spheres have enough energy required to associate 
            discr3 = bij ** 2 - (4. * sg3sq * delep)
			if (discr3 >= 0) then ! the the pair meet the energy requirement
                ! the pair will associate
				do q = 1, ndim 
                    impulse(q) = - rij%r(q) * ((bij + sqrt(discr3)) / (2. * sg3sq)) ! CHECK THIS
				end do 
                bump = -1.0
			else ! the pair do not meet the energy requirement
                ! the pair will remain dissociated ("bounce")
				do q = 1, ndim 
                    impulse(q) = - rij%r(q) * (bij / sg3sq) ! CHECK THIS
				end do 
                bump = 1.0
			end if 
		end if
        n_well = n_well + 1
	else if (this_event%type == 8) then ! the event is at the repulsive inner neighbor bond length
		do q = 1, ndim 
            impulse(q) = - rij%r(q) * (bij / inbond**2)
		end do 
        bump = 1.0
        n_bond = n_bond + 1
	else if (this_event%type == 9) then ! the event is at the repulsive outer neighbor bond length
		do q = 1, ndim 
            impulse(q) = - rij%r(q) * (bij / onbond**2)
		end do 
        bump = -1.0
        n_bond = n_bond + 1
	else if (this_event%type == 10) then ! the event is occuring at the repulsive inner cross bond length 
		do q = 1, ndim 
            impulse(q) = - rij%r(q) * (bij / icbond**2)
		end do 
        bump = 1.0
        n_bond = n_bond + 1
	else if (this_event%type == 11) then ! the event is occuring at the repulsive outer cross bond length
		do q = 1, ndim 
            impulse(q) = - rij%r(q) * (bij / ocbond**2)
		end do 
        bump = -1.0
        n_bond = n_bond + 1
	end if 

    dispa = 0.
    dispb = 0.
    ! adjust the velocity vector of each atom accordingly
	do q = 1, ndim 
        ! adjust the velocity of both colliding atoms 
        square(a%one)%circle(a%two)%vel%v(q) = square(a%one)%circle(a%two)%vel%v(q) + impulse(q)
        square(b%one)%circle(b%two)%vel%v(q) = square(b%one)%circle(b%two)%vel%v(q) - impulse(q)
        w = w + (rij%r(q) * impulse(q))
        ! move the particles a small distance away from the collision point
        square(a%one)%circle(a%two)%fpos%r(q) = square(a%one)%circle(a%two)%fpos%r(q) + &
            bump * smdistance * rij%r(q) * sigma2
        square(b%one)%circle(b%two)%fpos%r(q) = square(b%one)%circle(b%two)%fpos%r(q) - &
            bump * smdistance * rij%r(q) * sigma2
        ! calculate the new false position of each particle based on their new velocities
        square(a%one)%circle(a%two)%fpos%r(q) = square(a%one)%circle(a%two)%fpos%r(q) - impulse(q) * tsl
        square(b%one)%circle(b%two)%fpos%r(q) = square(b%one)%circle(b%two)%fpos%r(q) + impulse(q) * tsl
        ! calculate the dispalcement of either particle based on their post-collision velocities
        dispa = dispa + (square(a%one)%circle(a%two)%vel%v(q) * tsl) ** 2
        dispb = dispb + (square(b%one)%circle(b%two)%vel%v(q) * tsl) ** 2
	end do  
    ! apply periodic boundary conditions
    call apply_periodic_boundaries(square(a%one)%circle(a%two)%fpos)
    call apply_periodic_boundaries(square(b%one)%circle(b%two)%fpos)
    ! determine if the post-collision displacement of either particle is greater than
    ! the maximum displacement required for a neighborlist update
    if (dispa >= dispb) then
        dispa = sqrt(dispa)
        if (dispa >= nbrDispMax) nbrnow = .true.
    else
        dispb = sqrt(dispb)
        if (dispb >= nbrDispMax) nbrnow = .true.
    endif
end subroutine collide

! // ghost events //

subroutine thermostat_ghost_collision(temperature)
    implicit none
    real(kind=dbl), intent(in) :: temperature ! system temp 
    integer :: n ! number of partciles that experience a thermostat ghost collision
    type(id) :: a ! randomly selected particle that experiences a ghost collisions
    real(kind=dbl) :: sigma ! standard deviation of gaussian dist.
    real(kind=dbl) :: mu ! average of gaussian dist.
    real(kind=dbl) :: u1, u2 ! random numbers
    integer :: i, j, m, q ! indexing parameter 
    real(kind=dbl) :: disp ! used to measure particle displacement since tsl
    type(position), dimension(mer) :: rg ! stores the real position of each particle in ghost coliision

    ! determine how many ghost collisions could take place
    ! the number of particles that experience a ghost collisions
    ! is determined accoring to a random Poisson variate
    n = poissondist(real(1., dbl))
    n_ghost = n_ghost + n
    n_thermostat = n_thermostat + n
    if (debug >= 1) write (simiounit, 1) n
    1 format ('thermostat_ghost_event :: ', I3, ' thermal ghost collisions occur.')

    ! initialize parameters
    mu = 0. 
    sigma = sqrt(temperature)

    if (n > 0) then 
        ! if the number of particles experiencing ghost collisions is 1 or more
        do j = 1, n ! repeat process n times

            ! select a random particle
            a = random_cube()
            i = a%one
            if (debug >= 1) write (simiounit, 2) i
            2 format (' thermostat_ghost_event :: particle ', I5, ' experiences a thermal ghost collision ')

            ! reassign the particles velocity according to a maxwell-boltzmann dist
        	do m = 1, mer ! for every sphere in the square formation 
                disp = 0.
        		do q = 1, ndim
                    ! save the real position of each particle 
                    rg(mer)%r(q) = square(i)%circle(m)%fpos%r(q) + square(i)%circle(m)%vel%v(q) * tsl
                    ! Generate a pseudo random vector components based on a Gaussian distribution along the Box-Mueller algorithm
                    call random_number (u1)
                    call random_number (u2)
                    square(i)%circle(m)%vel%v(q) = mu + (sigma * sqrt( -2. * log(u1)) * sin (twopi * u2))
                    ! update the false position of the particle participating in the ghost event
                    square(i)%circle(m)%fpos%r(q) = rg(mer)%r(q) - square(i)%circle(m)%vel%v(q) * tsl
                    ! accumulate displacement
                    disp = disp + (square(i)%circle(m)%vel%v(q) ** 2)
        		end do 
                ! determine if maximum displacement was reached
                if (sqrt(disp) > nbrDispMax) nbrnow = .true.
                ! apply periodic boundary conditions
                call apply_periodic_boundaries(square(i)%circle(m)%fpos)
        	end do 

            ! reschedule the particle's collision events 
            call ghost_reschedule (i)
        enddo
    endif
end subroutine thermostat_ghost_collision

subroutine field_ghost_collision(impulse)
    implicit none 
    real(kind=dbl), intent(in) :: impulse 
    ! force that particles experience from external field
    type(vec) :: field_vec
    ! orientation of the external field
    integer :: n ! number of particles that experience field ghost events
    type(id) :: a ! particle experiencing event
    integer :: i, j, m, q ! indexing
    real(kind=dbl) :: disp ! displacement of the particles velocity
    type(position) :: rp ! real position of the particle


    ! determine the direction of the field vector
    if (field_rotation) then 
        ! the field is rotating
        ! field points constantly in the direction of the y-axis
        field_vec = get_field_vec(angvel = ..., time = timenow)
        ! scale the vector by the magnitude of the interaction
        field_vec%d = field_vec%d * impulse
        ! TODO :: implement field rotation
        ! write (*,*) 'TODO :: IMPLEMENT FIELD ROTATION'
    else
        ! the field is not rotating
        ! field points constantly in the direction of the y-axis
        field_vec = get_field_vec()
        ! scale the vector by the magnitude of the interaction
        field_vec%d = field_vec%d * impulse
    endif


    ! determine n particles
    n = poissondist(real(1.,dbl))
    ! increment counter
    n_ghost = n_ghost + n 
    n_field = n_field + n 
    ! report to user
    if (debug >= 1) write (simiounit, 1) n
    1 format (" field_ghost_collision :: ",I3," field ghost events.")

    ! if one or more particles have been selected
    if (n >= 1) then 
        ! for each particle
        do j = 1, n 
            ! determine the particle that should experience a collision
            a = random_cube()
            i = a%one
            ! report the particle
            if (debug >= 1) write (simiounit,2) i 
            2 format(" field_ghost_collision :: ", I3, " was selected.")

            ! do the interaction
            do m = 1, mer 
                ! for each disc
                if (square(i)%circle(m)%pol /= 0) then 
                    ! if the disc is charged
                    ! determine the overall displacement of the particles change in velocity
                    disp = 0.
                    ! apply in each dimension
                    do q = 1, ndim 
                        ! for each dimension
                        ! save the real position of the particle
                        rp%r(q) = square(i)%circle(m)%fpos%r(q) + &
                            square(i)%circle(m)%vel%v(q) * tsl

                        ! apply an external force to the charged particle
                        if (square(i)%circle(m)%pol == 1) then 
                            ! positive particles experience an impulse 
                            ! in the same direction as the field
                            square(i)%circle(m)%vel%v(q) = field_vec%d(q)
                        else
                            ! negative particles experience an impulse
                            ! in the opposite direction as the field
                            square(i)%circle(m)%vel%v(q) = - field_vec%d(q)
                        endif

                        ! update the false position of the particle
                        square(i)%circle(m)%fpos%r(q) = rp%r(q) - &
                            square(i)%circle(m)%vel%v(q) * tsl 

                        ! add to the over all displacement of the particle
                        disp = disp + (square(i)%circle(m)%vel%v(q) * tsl) ** 2

                    enddo
                    ! determine the overall displacement of the particle
                    ! update the total displacement if possible
                    if (sqrt(disp) > nbrDispMax) nbrnow = .true.

                    ! apply periodic boundary conditions
                    call apply_periodic_boundaries(square(i)%circle(m)%fpos)
                endif
            enddo
            ! reschedule the particles next collision
            call ghost_reschedule(i)
        enddo
    endif
end subroutine field_ghost_collision

type(vec) function get_field_vec (ori, angvel, time)
    implicit none 
    type(vec), intent(in), optional :: ori
    ! initial orientiation of the field
    real(kind=dbl), intent(in), optional :: angvel
    ! angular velocity of the field.
    real(kind=dbl), intent(in), optional :: time
    ! time since the simulation has started
    type(vec) :: field_ori

    if (present(ori)) then 
        ! if the orientation of the field was passed to the method
        ! assign that value as the initial orientation
        get_field_vec = ori
    else
        ! use the default orientation
        get_field_vec%d(1) = 0.0
        get_field_vec%d(2) = 1.0
    endif

    ! if the angular velocity and time were passed to the method
    if (present(angvel) .and. present(time)) then 
        get_field_vec%d(1) = cos((time / angvel) * twopi)
        get_field_vec%d(2) = sin((time / angvel) * twopi)
    endif 
end function get_field_vec

type(event) function predict_ghost(period)
    implicit none
    real(kind=dbl), intent(in) :: period 
    ! average time between collision events

    predict_ghost%time = period
    predict_ghost%partner = random_cube()
    predict_ghost%type = -1
end function predict_ghost

type(id) function random_cube()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    real(kind=dbl) :: dummy ! dummy variable 

    ! select a random cube 
    call random_number (dummy)
    random_cube%one = ceiling(dummy * real(cube))
    random_cube%two = 0
end function random_cube

integer function poissondist (lambda)
    implicit none
    ! ** purpose *********************************************
    ! This function generates a random integer based on a 
    ! Poisson distribution. The poisson variate is generated 
    ! using an algorithm that simulates a poisson distrubution
    ! directly.
    !
    ! SOURCE: https://hpaulkeeler.com/simulating-poisson-random-variables-direct-method/
    ! ********************************************************

    ! ** calling variables ***********************************
    real(kind=dbl), intent(in) :: lambda ! parameter used in poisson PDF
    ! average number of times and event occurs per unit time

    ! ** local variables *************************************
    real(kind=dbl) :: exp_lambda
    real(kind=dbl) :: randUni ! random uniform variable
    real(kind=dbl) :: prodUni ! product of random uniform variables
    real(kind=dbl) :: randPoisson ! random poisson variate returned by function

    ! initialize variables
    exp_lambda = exp(-lambda)
    randPoisson = -1
    prodUni = 1
    do 
        call random_number(randUni)
        prodUni = prodUni * randUni
        randPoisson = randPoisson + 1
        if (exp_lambda > prodUni) exit
    end do 
    poissondist = randPoisson
end function poissondist


! ** efficiency methods *****************************************

subroutine complete_reschedule()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer :: i, m, j, n 
    type(id) :: a, b 

    call initialize_binarytree(eventTree)
    do i = 1, mols 
        n = 0
        a = mol2id(i)
        square(a%one)%circle(a%two)%schedule = reset_event()
        do
            n = n + 1
            b = square(a%one)%circle(a%two)%upnab(n)
            if (b%one == 0) exit 
            call predict (a, b)
        enddo
        call addbranch (eventTree, i)
    enddo

    ! schedule thermostat ghost event
    thermostat_event = predict_ghost(thermostat_period)
    if (thermostat) call addbranch (eventTree, mols+1)

    ! schedule field ghost event
    field_event = predict_ghost(field_period)
    if (field) call addbranch (eventTree, mols+2)
end subroutine complete_reschedule

subroutine collision_reschedule(a, b)
    implicit none
    ! ** calling variables ***********************************
    type(id), intent(in) :: a, b
    ! ** local variables *************************************
    type(id) :: j1, j2 ! event partners 
    integer :: i, m, n  ! indexing parameters

    ! loop through all particles 
    do i = 1, cube 
        do m = 1, mer 
            ! if any particles just participated in an event or were scheduled to participate
            ! in an event with the event particles, reschedule their uplist partner 
            if (((i == a%one) .and. (m == a%two)) .or. ((square(i)%circle(m)%schedule%partner%one == a%one) .and.&
                (square(i)%circle(m)%schedule%partner%two == a%two)) .or. ((i == b%one) .and. (m == b%two)) .or.&
                ((square(i)%circle(m)%schedule%partner%one == b%one) .and. &
                (square(i)%circle(m)%schedule%partner%two == b%two))) then 
                j1%one = i
                j1%two = m
                ! reset its event and find next event 
                square(i)%circle(m)%schedule = reset_event()
                ! loop through their uplist neighbors to find next event partner
                n = 0
                uplist: do 
                    n = n + 1
                    j2 = square(i)%circle(m)%upnab(n)
                    if (j2%one == 0) exit 
                    call predict (j1, j2)
                enddo uplist
                call addbranch (eventTree, id2mol(j1%one, j1%two)) ! add the event to the event tree
            endif 
            ! if the particles are event partners 
            if (((i == a%one) .and. (m == a%two)) .or. ((i == b%one) .and. (m == b%two))) then 
                ! loop through downlist partners 
                j2%one = i 
                j2%two = m 
                n = 0
                downlist: do 
                    n = n + 1 
                    j1 = square(i)%circle(m)%dnnab(n)
                    if (j1%one == 0) exit 
                    call predict (j1, j2)
                    if (idequiv(square(j1%one)%circle(j1%two)%schedule%partner,j2)) then ! if j1 is scheduled for an event with j2
                        call addbranch (eventTree, id2mol(j1%one, j1%two))
                    endif
                enddo downlist
            endif 
        enddo
    enddo
end subroutine collision_reschedule

subroutine ghost_reschedule(ghost)
    implicit none
    ! ** calling variables ***********************************
    integer, intent(in) :: ghost
    ! ** local variables *************************************
    type(id) :: j1, j2 ! prediction event partners 
    integer :: i, m, n ! indexing parameters 

    ! loop through all particles 
    do i = 1, cube
        do m = 1, mer 
            ! if the partcle either participated in the ghost event, or was scheduled 
            ! to collide with a particle that participated in the ghost event 
            if ((i == ghost) .or. (square(i)%circle(m)%schedule%partner%one == ghost)) then 
                j1%one = i
                j1%two = m 
                ! reset and find its next event with an uplist particle
                square(j1%one)%circle(j1%two)%schedule = reset_event()
                n = 0 
                uplist: do 
                    n = n + 1
                    j2 = square(j1%one)%circle(j1%two)%upnab(n)
                    if (j2%one == 0) exit 
                    call predict (j1, j2)
                enddo uplist 
                call addbranch (eventTree, id2mol(j1%one, j1%two)) ! add the event to the event tree
            endif
            ! if the particle participated in the ghost event 
            if (i == ghost) then 
                j2%one = i 
                j2%two = m 
                ! find any downlist particles in its collision path 
                n = 0
                downlist: do 
                    n = n + 1
                    j1 = square(j2%one)%circle(j2%two)%dnnab(n)
                    if (j1%one == 0) exit
                    call predict (j1, j2)
                    if (idequiv(square(j1%one)%circle(j1%two)%schedule%partner,j2)) then ! if j1 is scheduled for an event with j2
                        call addbranch (eventTree, id2mol(j1%one, j1%two))
                    endif
                enddo downlist 
            endif 
        enddo
    enddo
end subroutine ghost_reschedule

 ! // cell + neighbor list //

subroutine build_linkedlist(list)
    implicit none
    ! ** calling variables ***********************************
    integer, dimension(mols + (nCells ** ndim)), intent(out) :: list
    ! ** local variables *************************************
    integer :: i, m, q ! indexing parameters 
    integer, dimension (ndim) :: c ! used to record the cell number of a particle in each dimenion 
    integer :: cellindex ! used to record the absolute cell number of each particle 

    ! reset each cell to -1
	do i = mols + 1, mols + (nCells ** ndim)
        list (i) = -1 
	end do 

    ! create a linked list based on the position of each atom 
	do i = 1, cube 
		do m = 1, mer 
			do q = 1, ndim 
                c(q) = floor (square(i)%circle(m)%fpos%r(q) / lengthCell)
			end do 
            cellindex = (c(2) * nCells) + c(1) + mols + 1
            list(id2mol(i, m)) = list(cellindex)
            list(cellindex) = id2mol(i,m)
		enddo
	enddo
end subroutine build_linkedlist

subroutine build_neighborlist()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    integer, dimension(mols + (nCells ** 2)) :: cellList
    integer :: m1x, m1y, m1cell ! integers used to determine the reference cell 
    integer :: delx, dely ! used to shift 
    integer :: m2x, m2y, m2cell ! integers used to determine the search cell 
    real(kind=dbl) :: rij
    integer :: j1, j2 ! particle pair 
    type(id) :: a, b
    integer :: i, j, m ! indexing parameters 
    integer, dimension (mols) :: nup, ndn ! down and uplist indexes 

    ! reset all neighbor lists to zero
	do i = 1, cube
		do m = 1, mer 
            square(i)%circle(m)%upnab = nullset()
            square(i)%circle(m)%dnnab = nullset()
		end do 
	end do 

    if (debug >= 1) write(simiounit,*) 'SUBROUTINE build_neighborlist: At event', n_events, ' the maximum displacement',&
         'was reached and the neighborlist was reset.'
    ! update the false positions of each particle
    call update_positions()
    ! create linked list to build the neighbor list 
    call build_linkedlist(cellList)
    ! intialize list index to the first position for all particles 
    nup = 1
    ndn = 1
	do m1y = 1, nCells 
		do m1x = 1, nCells
            ! determine the reference cell 
            m1cell = ((m1y - 1) * nCells) + m1x + mols
            ! establish reference atoms 
            j1 = cellList (m1cell)
			reference_cell: do ! loop through each atom in reference cell 
				if (j1 <= 0) exit ! until the end of the linked list (-1) is reached 
                ! calculate groupid from linked list index 
                a = mol2id(j1)
                ! loop through all neighboring cells 
				do dely = -1, 1 
                    ! determine m2y including wrap around effects 
                     m2y = m1y + dely 
					if (m2y > nCells) then 
                        m2y = 1
					else if (m2y < 1) then 
                        m2y = nCells 
					end if 
					do delx = -1, 1 
                        ! determine m2x including wrap around effects 
                        m2x = m1x + delx 
						if (m2x > nCells) then 
                            m2x = 1
						else if (m2x < 1) then 
                            m2x = nCells
						end if 
                        ! calculate the neighvoring cell to search through 
                        m2cell = ((m2y - 1) * nCells) + m2x + mols
                        ! establish atom in neighboring cell to compare to j1
                        j2 = cellList (m2cell)
						compare: do 
							if (j2 <= 0) exit 
							if (j2 > j1) then ! for all uplist atoms 
                                b = mol2id(j2)
                                rij = distance(square(a%one)%circle(a%two), square(b%one)%circle(b%two)) ! calculate the distance between pair i and j 
                                ! determine if the pair are neighbors
                                if (rij < nbrRadius) then ! if the distance between pair i and j is less than the max search radius
                                    if ((nup(j1) > nbrListSizeMax) .or. (ndn(j2) > nbrListSizeMax)) then 
                                        write (*,*) 'Too many neighbors in neighborlist. Increase size of list for this desnity.'
                                        call exit (NONZERO_EXITCODE)
                                    endif
                                    ! j is uplist of i 
                                    square(a%one)%circle(a%two)%upnab(nup(j1)) = b
                                    nup (j1) = nup (j1) + 1
                                    ! i is downlist of j 
                                    square(b%one)%circle(b%two)%dnnab(ndn(j2)) = a
                                    ndn (j2) = ndn (j2) + 1
                                endif
                            endif
                            j2 = cellList(j2)
                        enddo compare 
                    enddo
                enddo
                j1 = cellList(j1)
            enddo reference_cell
        enddo
    enddo
    nbrnow = .false.
    dispTotal = 0.
end subroutine build_neighborlist

! // bianry tree //

subroutine initialize_binarytree(tree)
    implicit none
    ! ** calling variables ***********************************
    type(node), dimension(mols+2), intent(out) :: tree
    ! ** local variables *************************************
    integer :: i ! indexing parameter
    type(id) :: a ! indexing parameter

    ! reset initial node of binary tree 
    rootnode = 0
    ! loop through each node and reset pointers to zero 
    do i = 1, mols+2
        tree(i)%lnode = 0
        tree(i)%rnode = 0
        tree(i)%pnode = 0
    end do 
end subroutine initialize_binarytree

integer function findnextevent(tree)
    implicit none
    ! ** calling variables ***********************************
    type(node), dimension(mols+2), intent(inout) :: tree ! binary tree
    ! ** local variables *************************************
    integer :: nextnode

    ! start the search for the minimum time with the root node 
    nextnode = rootnode
    do
        if (tree(nextnode)%lnode == 0) exit
        nextnode = tree(nextnode)%lnode
    enddo 
    findnextevent = nextnode
end function findnextevent

subroutine addbranch(tree, newnode)
    implicit none
    ! ** calling variables ***********************************
    type(node), dimension(mols+2), intent(inout) :: tree ! binary tree
    integer, intent(in) :: newnode ! node to be added to tree
    ! ** local variables *************************************
    type(id) :: a ! id of particle corresponding to node
    real(kind=dbl) :: tnew, tcomp ! collision time of new and compartison nodes
    integer :: ncomp ! current insertion node, which is being compared to the new node
    logical :: nfound ! true if insert position of new branch has been found, else false

    if (rootnode == 0) then ! if the tree is empty
        ! establish the root node 
        rootnode = newnode 
    else ! the tree has already begun 
        if ((tree(newnode)%pnode /= 0) .or. (newnode == rootnode)) then ! the node is already in the tree
            ! remove the node from the tree
            call delbranch (tree, newnode)
        endif
        ! save the time of the next event
        if (newnode <= mols) then 
            ! collision event
            a = mol2id(newnode)
            tnew = square(a%one)%circle(a%two)%schedule%time
        else if (newnode == mols + 1) then
            ! thermostat event
            tnew = thermostat_event%time
        else if (newnode == mols + 2) then 
            ! field event 
            tnew = field_event%time
        endif

        ! search through all branches to find the proper insert position
        ncomp = rootnode
        nfound = .false.
        do 
            if (nfound) exit
            ! calculate the time of comparison node's event
            if (ncomp <= mols) then 
                ! for collision events
                a = mol2id(ncomp)
                tcomp = square(a%one)%circle(a%two)%schedule%time
            else if (ncomp == mols + 1) then 
                ! thermostat event
                tcomp = thermostat_event%time
            else if (ncomp == mols + 2) then 
                ! field event 
                tcomp = field_event%time
            endif

            if (tnew <= tcomp) then ! if the new event is sooner than the current node event
                ! go to the left 
                if (tree(ncomp)%lnode /= 0) then ! if the current node has a left node 
                    ncomp = tree(ncomp)%lnode ! compare the new node to the left branch of the current node
                else ! connect the new node to the left of current node
                    tree(ncomp)%lnode = newnode
                    nfound = .true.
                    exit
                endif
            else ! the new event is later than the current node event
                ! go to the right 
                if (tree(ncomp)%rnode /= 0) then ! if the current node has a right node 
                    ncomp = tree(ncomp)%rnode ! compare the new node to the right branch of the current node
                else ! connect the new node to the right of current node
                    tree(ncomp)%rnode = newnode
                    nfound = .true.
                    exit
                end if
            endif
        enddo 
        ! link the new node to the previous node
        tree(newnode)%pnode = ncomp
    endif
end subroutine addbranch

subroutine delbranch(tree, nonode)
    implicit none
    ! ** calling variables ***********************************
    type(node), dimension(mols+2), intent(inout) :: tree ! binary tree
    integer, intent(in) :: nonode ! mold id of particle whose node is being deleted from tree
    ! ** local variables *************************************
    integer :: ns, np ! pointers used for relinking

    ! determine the relationship of the deleted node to other nodes in the tree structure
    ! adapted from Smith et al. MD for Polymeric Fluids
    if (tree(nonode)%rnode == 0) then
        ! CASE I: the deleted node is followed on the right branch by a null event
        ! SOL: pnode of nonode should be linked to lnode of nonode (note lnode of nonode can be
        ! either a null event or another branch)
        ns = tree(nonode)%lnode
        np = tree(nonode)%pnode
        if (ns /= 0) tree(ns)%pnode = np
        if (np /= 0) then 
            if (tree(np)%lnode == nonode) then 
                tree(np)%lnode = ns
            else
                tree(np)%rnode = ns 
            endif
        endif
    else if (tree(nonode)%lnode == 0) then ! 
        ! CASE II: the deleted node contains a null event on the left branch 
        ! and a non-null event on the right branch
        ! SOL: pnode of nonode should be linked to rnode of nonode
        ns = tree(nonode)%rnode
        np = tree(nonode)%pnode
        tree(ns)%pnode = np
        if (np /= 0) then 
            if (tree(np)%lnode == nonode) then 
                tree(np)%lnode = ns
            else
                tree(np)%rnode = ns 
            endif
        endif
    else if (tree(tree(nonode)%rnode)%lnode == 0) then
        ! CASE III: the deleted node contains non-null events on the left and right branches
        ! while the right branch contains a null left branch, which indicates that the right branch
        ! of the right branch is the smallest event time
        ! SOL: Since the event time on the right of nonode is larger than the event time on the left,
        ! rnode of nonode is designated as the successor. The null event of lnode of rnode of nonode
        ! is replaced with lnode of nonode      ! link pnode of nonode to rnode to nonode
        ns = tree(nonode)%rnode
        ! link the left branch of nonode to the left branch of the successor node (null event)
        np = tree(nonode)%lnode 
        tree(ns)%lnode = np 
        tree(np)%pnode = ns 
        ! link the successor node to the pointer node of nonode
        np = tree(nonode)%pnode
        tree(ns)%pnode = np
        if (np /= 0) then 
            if (tree(np)%lnode == nonode) then 
                tree(np)%lnode = ns
            else
                tree(np)%rnode = ns 
            endif
        endif
    else 
        ! CASE IV: last case, most generic solution required. The right branch of nonode has
        ! a non-null left branch
        ! SOL: search left branch of right branch of nonode for the minimum event 
        ! find the node whose event is closest to nonode
        ns = tree(tree(nonode)%rnode)%lnode
        do
            if (tree(ns)%lnode == 0) exit
            ns = tree(ns)%lnode
        enddo 
        ! replace the successor node with the successor node's right branch
        np = tree(ns)%pnode 
        tree(np)%lnode = tree(ns)%rnode 
        if (tree(ns)%rnode /= 0) tree(tree(ns)%rnode)%pnode = np 
        ! replace nonode with the successor node
        ! link the right branch of nonode to the right branch of the successor node
        np = tree(nonode)%rnode 
        tree(np)%pnode = ns 
        tree(ns)%rnode = np
        ! link the left branch of nonode to the left branch of the successor node (null event)
        np = tree(nonode)%lnode 
        tree(np)%pnode = ns 
        tree(ns)%lnode = np 
        ! link the successor node to nonode's predossesor node 
        np = tree(nonode)%pnode
        tree(ns)%pnode = np
        if (np /= 0) then 
            if (tree(np)%lnode == nonode) then 
                tree(np)%lnode = ns
            else
                tree(np)%rnode = ns 
            endif
        endif
    endif

    if (nonode == rootnode) then ! if nonode is the rootnode
        ! reset the rootnode as the successor node
        rootnode = ns 
    endif

    ! reset nonode
    tree(nonode)%pnode = 0
    tree(nonode)%rnode = 0
    tree(nonode)%lnode = 0 
end subroutine delbranch

! // false positioning method //

subroutine update_positions()
    implicit none
    ! ** calling variables ***********************************
    ! ** local variables *************************************
    type(position), dimension(mols) :: pos ! real position of each particle
    integer :: i, m, q ! indexing parameters 

    ! calculate the real position of each particle
    do i = 1, cube 
        do m = 1, mer 
            do q = 1, ndim 
                pos(id2mol(i,m))%r(q) = square(i)%circle(m)%fpos%r(q) + square(i)%circle(m)%vel%v(q) * tsl
            enddo
            call apply_periodic_boundaries (pos(id2mol(i,m)))
            square(i)%circle(m)%fpos = pos(id2mol(i,m))
        enddo
    enddo
    ! reset the update time
    tsl = 0.
    tl = timenow
end subroutine update_positions

end module polarizedsquaremodule

