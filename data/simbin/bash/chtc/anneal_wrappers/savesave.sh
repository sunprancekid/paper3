# !/bin/bash
set -e

# Matthew Dorsey
# 2023-04-20
# program that takes save files from polsqu simulations
# and saves them to a seperate directory with a different name.

## PARAMETERS 
# current date and time 
CURRENTTIME=$(date '+%Y-%m-%d %H:%M:%S')
# non-zero exit code for incorrect operations
declare -i NONZERO_EXITCODE=1
# array containing a list of SAVE files
SAVE=( "fposSAVE" "velSAVE" "chaiSAVE" "annSAVE" "simSAVE" )
# boolean determining if initial simulation save data should be loaded
declare -i BOOL_LOADINIT=0
# boolean determining if last save should be loaded
declare -i BOOL_LOADLAST=0
# boolean determining if simulation should be saved
declare -i BOOL_SAVE=0


## OPTIONS
while getopts "ils" option; do
    case $option in
    	i) # load initial simulation data

			# boolean determining if initial simulation save data should be loaded
			declare -i BOOL_LOADINIT=1 ;;
		l) # laod last save

			# boolean determining if last save should be loaded
			declare -i BOOL_LOADLAST=1;;
		s) # save simulation data
			
			# boolean determining if simulation should be saved
			declare -i BOOL_SAVE=1;;
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
# third argument: exit code of the node being processed
RETURN_VAL=$3


## FUNCTIONS
# none


## SCRIPT
# determine the operation to perform
if [[ BOOL_LOADINIT -eq 1 ]]; then 
	# right now, the post-processing script doesn't do anything
	# for the initial annealing node accept inform the user
	echo "${CURRENTTIME}: initalization node completed (exit code ${RETURN_VAL})."

	exit 0
fi

## stablish file names
# id associtated with simulation files
JOBID="${JOB}${SIMID}"

## determine what operation should be performed
if [[ BOOL_SAVE -eq 1 || BOOL_LOADLAST -eq 1 ]]; then
	# determinte the number of files that have been saved
	declare -i COUNT=$(find ./save -type f -name "${JOBID}_fposSAVEi*" | wc -l)
	if [[ BOOL_LOADLAST -eq 1 && COUNT -eq 1 ]]; then
		declare -i COUNT=0
	elif [[ BOOL_LOAD -eq 1 && COUNT -ne 1 ]]; then
		((COUNT=COUNT-1))
	fi
elif [[ BOOL_LOADINIT -eq 1 ]]; then 
	# reload the initial configuration
	declare -i COUNT=0
else 
	echo "${CURRENTTIME}: Operation not specified."
	exit $NONZERO_EXITCODE
fi
# created a string for file formatting
COUNT_STRING=$(printf '%03d' $COUNT)
echo $COUNT_STRING

## performed the operation
for s in ${SAVE[@]}; do

	# save file from most recently completed simulation
	SIMSAVE="./save/${JOBID}__${s}.dat"

	# stored save in order of simulations that have been completed
	INTSAVE="./save/${JOBID}_${s}i${COUNT_STRING}.dat"

	# resave the save files with new names
	if [[  BOOL_SAVE -eq 1 ]]; then
		# copy each save file to the same folder with a new name
		# corresponding to the number of times saves have been generated
		echo "${CURRENTTIME}: Saving ${SIMSAVE} as ${INTSAVE}."
		cp $SIMSAVE $INTSAVE
	elif [[ BOOL_LOADINIT -eq 1 || BOOL_LOADLAST -eq 1 ]]; then 
		# load previous save files for the simulation to use
		echo "${CURRENTTIME}: Loading ${INTSAVE}."
		cp $INTSAVE $SIMSAVE 
	else 
		echo "Operation not specified."
		exit $NONZERO_EXITCODE
	fi
done

exit 0