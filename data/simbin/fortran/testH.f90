!! Matthew A. Dorsey 
!! North Carolina State University 
!! 2023-07-21

!! PURPOSE :: runs simulation for polarized squares with external field on
!             to test the external field parameters

program testH
    use polarizedsquaremodule
    implicit none
    integer, parameter :: N_ARGS = 1 ! number of arguments accepted by simulation file
    integer :: a  ! number of arguments determined by program
    character(len=12), dimension(:), allocatable :: args
    real :: tset, vmag, ffrq

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
    read (args(1), '(f6.4)') tset
    read (args(2), '(f6.4)') vmag
    read (args(3), '(f6.0)') ffrq

    ! initialize simulation
    call initialize_simulation_settings(af = 0.2, e = 10000000, nc = 16, ac = 0.8)
    call set_sphere_movie (status = .false.)
    call set_square_movie (status = .true., freq = 1.)
    call set_thermostat (status = .true., temp = tset, freq = 0.1)
    call set_external_field (status = .true., freq = ffrq, force = vmag)

    ! initialize system
    call initialize_system()

    ! run the simulation if the parameters are met
    if (trim(args(1)) == '1') then
        do
            if (single_step()) exit
        enddo
    endif 
end program testH


