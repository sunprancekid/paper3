#!/bin/bash 
set -e 

# Matthew Dorsey
# 2023-04-20
# wrapper for post-scripts of DAGMAN annealing jobs. 
# used to write status of DAGMAN jobs, standard out and error of chtc scripts.
# script moves files to their proper storage directory if certain criteria are met.

## PARAMETERS
# exit code for indicating to DAGMAN workflow that there is an error
declare -i NONZERO_EXITCODE=1
# boolean determining if the script performing operations for the initial annealing node
declare -i BOOL_INIT=0
# boolean determining if the simulation is handling an iteration of the annealing simulation
declare -i BOOL_ANNEAL=0
# boolean determining if the script is handling a rerun of a previous iteration
# of the annealing simulation
declare -i BOOL_RERUN=0
# boolean determining if the simulation should be checked
declare -i BOUND_BOOL=0
# boolean determine if the number of system iterations should be checked
declare -i COUNT_BOOL=0

## OPTIONS
# determine exit criteria
# flags are used for specifying exit criteria 
while getopts "ia:r:" option; do
    case $option in
    	i) # flag for how the script should handle the initial simulation
			
			# boolean determining if the script if performing operations
			# for the initial annealing node
			declare -i BOOL_INIT=1 ;;
		a) # flag for how the script should handle an iteration of the annealing simulation

			# boolean determining if the simulation is handling an
			# iteration of the annealing simulation
			declare -i BOOL_ANNEAL=1

			# the annealing flag accepts the temperature at which
			# the annealing loop should break
			ANNEAL_TEMP=${OPTARG}
			;;
		r) # flag for how the script should handle reruns of an iteration of an annealing simulation
			
			# boolean determining if the script is handling a rerun
			# of a previous iteration of the annealing simulation
			declare BOOL_RERUN=1 

			# the rerun flag accepts integer corresponding to the iteration
			# of the annealing simulation that the script is handling
			declare -i RERUN_IT=${OPTARG}
			;;
		\?) # default
			echo "must declare arguments" ;;
   esac
done
shift $((OPTIND-1))


## ARGUMENTS
# first argument: id associated with batch of annealing simulations
JOB=$1
# second argument: id associated with the annealing simulation
SIMID=$2
# third argument: exit code of the script
EXIT_VAL=$3
# fourth argument: number of node retries
RETRY_VAL=$4


## FUCNTIONS
# none


# SCRIPT
# establish the name used to write standard out and error from
# the pre and post processing scripts
OUTNAME="${JOB}${SIMID}_stdout.txt"

# determine the operation to perform
if [[ $BOOL_INIT -eq 1 ]]; then 
	./savesave.sh -i -e $EXIT_VAL $JOB $SIMID $RETRY_VAL >> "${OUTNAME}" 2>&1
elif [[ $BOOL_ANNEAL -eq 1 ]]; then 
	./savesave.sh -a "${ANNEAL_TEMP}" -e $EXIT_VAL $JOB $SIMID $RETRY_VAL >> "${OUTNAME}" 2>&1
elif [[ $BOOL_RERUN -eq 1 ]]; then
	./savesave.sh -r ${RERUN_IT} -e $EXIT_VAL $JOB $SIMID $RETRY_VAL >> "${OUTNAME}" 2>&1
fi

exit 0
