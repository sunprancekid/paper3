!! Matthew A Dorsey
!! 2023.08.13
!! PURPOSE :: program for initializing conH annealing simulations

program conH
    use polarizedsquaremodule
    implicit none
    integer, parameter :: N_ARGS = 11 ! number of arguments accepted by simulation file
    integer :: a  ! number of arguments determined by program
    character(len=20), dimension(:), allocatable :: args
    ! arguments to parse from the command line
    ! first argument is a boolean integer that indicates whether to iterate the simulation
    !   forward in time
    ! second argument is the job title
    ! third argument is the annealing id
    real :: area_frac ! fourth argument is the simulation area fraction
    integer :: cell_size ! fifth argument is the simulation cell size
    real :: a_chai_frac ! sixth argument is the number fraction of a-chirality squares
    real :: field_strength ! seventh argument is the external field strength
    real :: field_rotation_freq ! eighth argument is the frequency of external field rotation
    real :: init_temperature ! ninth argument is the initial temperature of the annealing simulation
    integer :: events ! tenth agument is the length of simulation
    real :: annealing_fraction ! eleventh argument is the annealing fraction reduction

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
    read (args(4), '(f6.4)') area_frac ! area fraction is a real number between 0 and 1
    read (args(5), *) cell_size ! cell size is an integer
    read (args(6), '(f6.4)') a_chai_frac ! a-chairality fraction is a real number between 0 and 1
    read (args(7), '(f6.4)') field_strength ! field strength is a real number greater than 0
    read (args(8), '(f7.4)') field_rotation_freq ! rotational frequency of the field in rad / sec
    read (args(9), '(f6.4)') init_temperature ! temperature is a real number greater than 0
    read (args(10), *) events ! second argument is the number of simulation events
    read (args(11), '(f6.4)') annealing_fraction ! annealing fraction is a real number between 0 and 1

    ! initialize the simulation
    call initialize_simulation_settings(af = area_frac, e = events, nc = cell_size, ac = a_chai_frac)

    ! initialize system
    call initialize_system(job = trim(args(2)), sim = trim(args(3)))
    call initialize_annealing(status = .true., frac = annealing_fraction)

    ! set simulation parameters
    call set_sphere_movie (status = .false.)
    call set_square_movie (status = .true., freq = 0.5)
    ! call set_thermostat (status = .true., freq = 0.1)
    call set_external_field (status = .true., strength = field_strength)
    call set_external_field_rotation (rot_status = .true., rot_freq = field_rotation_freq)

    ! save the status of the simulation after initialization
    call save()

    ! if the execute code is passed to the method,
    ! run the simulation until the system reaches the assigned number of steps
    if (trim(args(1)) == '1') then
        do
            if (single_step()) exit
        enddo
    endif 

end program conH