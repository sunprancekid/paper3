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
# boolean determining if the simulation should be checked
declare -i BOUND_BOOL=0
# boolean determine if the number of system iterations should be checked
declare -i COUNT_BOOL=0

## OPTIONS
# determine exit criteria
# flags are used for specifying exit criteria 
while getopts "ib:n:" option; do
    case $option in
    	i) # initial simulation
			
			# boolean determining if the script if performing operations
			# for the initial annealing node
			declare -i BOOL_INIT=1
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
RETURN_VAL=$3


## FUCNTIONS
# none


# SCRIPT
# establish the name used to write standard out and error from
# the pre and post processing scripts
OUTNAME="${JOB}${SIMID}_stdout.txt"

# determine the operation to perform
if [[ BOOL_INIT -eq 1 ]]; then 
	./savesave.sh -i $JOB $SIMID $RETURN_VAL >> "${OUTNAME}" 2>&1
fi

exit 0