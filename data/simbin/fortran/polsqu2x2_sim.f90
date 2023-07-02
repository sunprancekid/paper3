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

    ! load system
    ! system will be initialized if save files are not present
    call initialize_system()

    ! run the simulation if the parameters are met
    if (trim(args(1)) == '1') then
        do
            if (single_step()) exit
        enddo
    endif 
end program polarizedsquare_simulation


