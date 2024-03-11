!! Matthew A. Dorsey 
!! North Carolina State University 
!! 2023-07-21

!! PURPOSE :: runs simulation for polarized squares with external field on
!             to test the external field parameters

program testH
    use polarizedsquaremodule
    implicit none
    integer, parameter :: N_ARGS = 6 ! number of arguments accepted by simulation file
    integer :: a  ! number of arguments determined by program
    character(len=12), dimension(:), allocatable :: args
    real :: area_frac ! simulation area fraction
    integer :: events ! length of simulation
    integer :: cell_size ! simulation cell size
    real :: tset, X, field_strength ! testH parameters

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

    ! read argument values
    read (args(1), '(f6.4)') area_frac ! first argument is the simulation area fraction
    read (args(2), *) events ! second argument is the number of simulation events
    read (args(3), *) cell_size ! third argument is the cell size of the simulation
    read (args(4), '(f6.4)') tset ! fourth argument is the temperature set point of the simulation
    read (args(5), '(f6.4)') field_strength ! fifth argument passed to the method is the ratio magnetic to thermal energy
    ! the sixth value passed to the method is simid for the testH job

    ! use the temperature set point and ratio of magnetic to thermal energy to
    ! calculate the external field strength
    ! field_strength = X * tset / 1.0
    ! for squares with standard dipoles, degree of charge seperation is one

    ! initialize simulation
    call initialize_simulation_settings(af = area_frac, e = events, nc = cell_size, ac = 1.0)
    call set_sphere_movie (status = .false.)
    call set_square_movie (status = .false., freq = 1000.)
    call set_thermostat (status = .true., temp = tset, freq = 0.2)
    call set_external_field (status = .true., strength = field_strength)

    ! turn on calculating the alignment distribution
    call alignment_distribution (status = .true., n_bins = 100)

    ! initialize system
    call initialize_system(job = "testH", sim = trim(args(6)))

    ! run the simulation if the parameters are met
    do
        if (single_step()) exit
    enddo
end program testH


