!! Matthew A. Dorsey 
!! North Carolina State University 
!! 2023-04-15

!! PURPOSE :: runs simulation for polarized squares

program polarizedsquare_simulation
    use polarizedsquaremodule
    implicit none
    integer, parameter :: N_ARGS = 1 ! number of arguments accepted by simulation file
    integer :: a  ! number of arguments determined by program
    character(len=12), dimension(:), allocatable :: args

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

    ! TODO :: adjust debugging status so that it can be adjusted from the main program method

    ! pass settings to module
    ! load settings
    ! TO THINK :: better to pass values to function, or set each
    ! parameter individually (probably the second one -> actually maybe the first? for cleanliness)
    call initialize_simulation_settings(af = 0.2, e = 50000, nc = 12)
    call set_sphere_movie (status = .false.)
    call set_square_movie (status = .true., freq = 1.)
    call set_thermostat (status = .true., temp = 0.3, freq = 0.1)
    call set_external_field (status = .false., strength = 0.1)
    ! TODO :: add methods for turning property calculation on and off
    ! TODO :: add methods for renaming the simulation

    ! TODO :: make sure that milestoning is off! 

    ! load system
    ! system will be initialized if save files are not present
    call initialize_system()

    ! run the simulation if the parameters are met
    if (trim(args(1)) == '1') then
        do
            if (single_step()) exit
        enddo
    endif 

    ! anneal
    ! save
    ! deallocate (do not need to do that)
end program polarizedsquare_simulation


