# !/bin/bash
set -e

# Matthew Dorsey
# 2023.07.26
# script that generates simulation parameters for testH simulations

## PARAMETERS
# exit code for improper usage of script
declare -i NONZERO_EXITCODE=120
# boolean that determines if the script should execute verbosely
declare -i VERB_BOOL=0
# boolean that determines if the simulation cell size has been specified
declare -i CELL_BOOL=0
# boolean that determines if the simulation number of events has been specified
declare -i EVENT_BOOL=0
# boolean that determines if an integer corresponding to the simulation
# area fraction has been specified
declare -i AF_BOOL=0

## FUNCTIONS
help () {

	# list the script's arguments
}

## OPTIONS
while getopts "a:c:e:" options; do 
	case $options in 
		a) # analyze results from simulations

			;;
		c) # specify integer that determines how the script should execute

			;;
		e) # generate simulations on CHTC node

			;;
		v) # execute the script verbosely
			
			# boolean that determines if the script should
			# be executed verbosely
			declare -i VERB_BOOL=1 ;;
		\?) # default if incorrect options are specified
			
			# inform user of the correct options
			echo -e "\nIncorrect options specified.\n"
			help

			exit $NONZERO_EXITCODE ;;
    esac
done
shift $((OPTIND-1))

## ARGUMENTS
# none

## SCRIPT
# none

