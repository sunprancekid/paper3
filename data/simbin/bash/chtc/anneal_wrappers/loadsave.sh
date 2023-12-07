# !/bin/bash
set -e 

## Matthew Dorsey
## 2023.08.21
## script for annealing prescript-wrapper
## loads files for next annealing simulation
## writes informs user of the status of the annealing jobs
## with verbose execution

## PARAMETERS 
# current date and time 
CURRENTTIME=$(date '+%Y-%m-%d %H:%M:%S')
# non-zero exit code for incorrect operations
declare -i NONZERO_EXITCODE=1
# array containing a list of SAVE files
SAVE=( "fposSAVE" "velSAVE" "chaiSAVE" "annealSAVE" "simSAVE" )
# temp file used to store information about saving and loading
# annealing simulations between pre- and post-processing scripts
TMP_FILE="./anneal/tmp/next_dir.txt"
# retry file contains the number of times that a job exits with 
# non-zero exit code in a row
RETRY_FILE="./anneal/tmp/retry.txt"
# boolean determining if initial simulation save data should be loaded
declare -i BOOL_LOADINIT=0
# boolean determining if last save should be loaded
declare -i BOOL_LOADLAST=0
# boolean determining if simulation should be saved
declare -i BOOL_SAVE=0
# boolean used to determine if the script is handling a rerun of a previous
# iteration of the annealing simulation
declare -i BOOL_RERUN=0


## FUNCTIONS
# check number of annealing retries, decriments next directory integer if the
# number of failed attempts in a row is greater than the allowable amount
check_retries() {

	## PARAMETERS
	# maximum number of times an annealing node can fail in a row
	declare -i MAX_RETRIES=10

	## OPTIONS
	# none

	## ARGUMENTS
	# none

	## SCRIPT
	# get the number of retries from the retry file
	declare -i RETRY_INT=$( head -n 1 $RETRY_FILE | tail -n 1 )

	# determine if the number of retries is greater than the allowable amount
	if [[ $RETRY_INT -ge $MAX_RETRIES ]]; then 
		# inform the user
		echo "${CURRENTTIME}: the annealing job has failed ${RETRY_INT} times, which exceeds the maximum of ${MAX_RETRIES}."

		# if the number of failed attempts is too great, decriment
		# the integer stored in the next directory file
		NEXT_DIR_INT=$( head -n 1 $TMP_FILE | tail -n 1 )
		# if the directory to load from is not the initial directory
		if [[ "${NEXT_DIR_INT}" != "init" ]]; then
			# then the value stored in the file is an integer
			declare -i NEXT_DIR_INT=$NEXT_DIR_INT
			if [[ $NEXT_DIR_INT -eq 0 ]]; then 
				# if the current directory to load from is the zero-th
				# annealing iteration, then the previous directory to load from
				# is the initial directory
				NEXT_DIR_INT="init"
			else
				# otherwise decriment the integer
				((NEXT_DIR_INT-=1))
			if
		fi

		# store the next integer in the next directory file
		echo "${NEXT_DIR_INT}" > $TMP_FILE

		# restart the number of retries count 
		echo "0" > $RETRY_FILE
	fi
}


## OPTIONS
while getopts "ilsr:" option; do
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
		r) # save a specific rerun of a previous iteration of an annealing simulation

			# boolean that determines if the the script is handling a previous
			# iteration of a previous version of the annealing simulation
			declare -i BOOL_ANNEAL=1

			# the value passed with the flag is the integer corresponding to the 
			# iteration of the annealing simulation that was rerun and 
			# that the script is handling
			declare -i RERUN_IT=${OPTARG};; 
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


## SCRIPT

# determine the operation that should be performed
if [[ BOOL_LOADINIT -eq 1 ]]; then
	# if the loading the initial simulation
	# establish the initial directory that files will be saved to
	mkdir -p "./anneal/init"

	# in the case of the initial annealing simulation, 
	# no files are need as input

	# inform the user
	echo "${CURRENTTIME}: Generating save directories for initial node."

	exit 0
elif [[ BOOL_LOADLAST -eq 1 ]]; then
	# check the number of retries
	check_retries

	# if loading the previous state of an annealing simulation
	# get the directory that contains the previous state from the temporary file
	NXT_DIR_INT=$( head -n 1 $TMP_FILE | tail -n 1 )
	echo "${CURRENTTIME}: loading save files from annealing directory ${NXT_DIR_INT}." 

	if [[ "${NXT_DIR_INT}" == "init" ]]; then 
		# if the directory to load is the initial
		NXT_DIR=$NXT_DIR_INT
	else 
		# format the next directory to a standard integer
		NXT_DIR=$(printf '%03d' ${NXT_DIR_INT})
	fi

	# copy each save file from the save directory, to the tmp directory
	for s in ${SAVE[@]}; do
		cp "./anneal/${NXT_DIR}/${JOB}${SIMID}__${s}.dat" "./anneal/tmp/"
	done

	# inform the user
	echo "${CURRENTTIME}: Copying save files from ./anneal/${NXT_DIR} to ./anneal/tmp/."

	exit 0
elif [[ BOOL_RERUN -eq 1 ]]; then
	# if rerunning a previous iteration of the annealing simulation
	# the script simply creates the simulation save directory in the 
	# temporary annealing directory, where all of the simulation files 
	# will be saved to once the simulation completes for postscript processing
	RERUN_DIR=$(printf '%03d' ${RERUN_IT})
	mkdir -p "./anneal/tmp/${RERUN_DIR}/"
	# inform the user
	echo "${CURRENTTIME}: Initializing rerun directory for annealing node ${RERUN_DIR}."
fi

