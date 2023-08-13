!! Matthew A Dorsey
!! 2023.08.13
!! PURPOSE :: program for initializing conH annealing simulations

program conH_init
    use polarizedsquaremodule
    implicit none
    integer, parameter :: N_ARGS = 9 ! number of arguments accepted by simulation file
    integer :: a  ! number of arguments determined by program
    character(len=12), dimension(:), allocatable :: args
    ! arguments to parse from the command line
    ! first argument is the job title
    ! seconds argument is the annealing id
    real :: area_frac ! third argument is the simulation area fraction
    integer :: cell_size ! fourth argument is the simulation cell size
    real :: a_chai_frac ! fifth argument is the number fraction of a-chirality squares
    real :: field_strength ! sixth argument is the external field strength
    ! real :: init_temperature ! seventh argument is the initial temperature of the annealing simulation
    integer :: events ! eigth agument is the length of simulation
    ! real :: annealing_fraction ! ninth argument is the annealing fraction reduction

    ! parse the number of arguments passed to the program
    a = command_argument_count()
    if (a /= N_ARGS) then 
        write (*, *) 'Incorrect number of arguments passed to simulation executable.'
        write (*, 2) a, N_ARGS
        write (*, *) 'USAGE: ./polsqu_sim '
        2 format (I2," arguments passed to polsqu_sim when only ", I02," arguments are allowed.")
        call exit(NONZERO_EXITCODE)
    endif
    allocate(args(a))
    ! parse arguments
    do a = 1, N_ARGS 
        ! parse argument 
        call get_command_argument(a,args(a))
    enddo

    ! read argument values that are numeric (integers or real)
    read (args(3), '(f6.4)') area_frac ! area fraction is a real number between 0 and 1
    read (args(4), *) cell_size ! cell size is an integer
    read (args(5), '(f6.4)') a_chai_frac ! a-chairality fraction is a real number between 0 and 1
    read (args(6), '(f6.4)') field_strength ! field strength is a real number greater than 0
    read (args(7), *) events ! second argument is the number of simulation events

    ! initialize the simulation
    call initialize_simulation_settings(af = area_frac, e = events, nc = cell_size, ac = a_chai_frac)
    call set_sphere_movie (status = .false.)
    call set_square_movie (status = .true., freq = 1000.)
    call set_thermostat (status = .true., freq = 0.1)
    call set_external_field (status = .true., strength = field_strength)

    ! initialize system
    call initialize_system(job = trim(args(1)), sim = trim(args(2)))

    ! run the simulation until the system reaches the assigned number of steps
    do
        if (single_step()) exit
    enddo

end program conH_init