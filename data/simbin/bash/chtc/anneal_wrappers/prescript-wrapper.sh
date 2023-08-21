#!/bin/bash 
set -e 

# Matthew Dorsey
# 2023-04-20
# wrapper for pre-scripts of DAGMAN annealing jobs. 
# used to write the status, standard out and error of DAGMAG jobs.
# loads files in preperation of annealing jobs, creates directories 
# that store and save the results from annealing simulations.

## PARAMETERS
# exit code for indicating to DAGMAN workflow that there is an error
declare -i NONZERO_EXITCODE=1
# boolean that determines if the last save should be loaded
declare -i BOOL_LOADLAST=0
# boolean that determines if the initial save should be loaded
declare -i BOOL_LOADINIT=0


## OPTIONS
# parse options
while getopts "il" option
do 
	case $option in 
		i) # load the initial state 
			
			# boolean that determines if the inital state should be loaded
			declare -i BOOL_LOADINIT=1;;
		l) # load the last save 

			# boolean that determines if the last state should be loaded
			declare -i BOOL_LOADLAST=1;;
		\?) # default
			echo "Invalid option declared." >> "${OUTNAME}" 2>&1;;
	esac
done
shift $((OPTIND-1))

# ARGUMENTS
# first argument: id associated with batch of annealing simulations
JOB=$1
# second argument: id associated with the annealing simulation
SIMID=$2


## FUCNTIONS
# none


# SCRIPT
# establish the name used to write standard out and error from
# the pre and post processing scripts
OUTNAME="${JOB}${SIMID}_stdout.txt"

# determine operation and execute
# redirect standard out and error
if [[ BOOL_LOADINIT -eq 1 ]]; then
	./loadsave.sh -i $JOB $SIMID >> "${OUTNAME}" 2>&1
elif [[ BOOL_LOADLAST -eq 1 ]]; then 
	./loadsave.sh -l $JOB $SIMID >> "${OUTNAME}" 2>&1
else 
	echo "Operation not specified." >> "${OUTNAME}" 2>&1
	exit $NONZERO_EXITCODE
fi

exit 0