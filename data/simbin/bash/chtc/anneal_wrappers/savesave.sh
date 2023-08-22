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
# temp file used to store information about saving and loading
# annealing simulations between pre- and post-processing scripts
TMP_FILE="./anneal/tmp/next_dir.txt"
# boolean determining if initial simulation save data should be loaded
declare -i BOOL_SAVEINIT=0
# boolean used to determine if the script is handling an annealing simulation
declare -i BOOL_ANNEAL=0
# boolean determining if last save should be loaded
declare -i BOOL_LOADLAST=0
# boolean determining if simulation should be saved
declare -i BOOL_SAVE=0


## OPTIONS
while getopts "ials" option; do
    case $option in
    	i) # save initial simulation data

			# boolean determining if initial simulation save data should be loaded
			declare -i BOOL_SAVEINIT=1 ;;
		a) # save most recent iteration of annealing simulation
			
			# boolean determining if the script is handling an iteration
			# of the annealing loop
			declare -i BOOL_ANNEAL=1;;

			# the value passed with the flag is the minimum temperature 
			# that the simulation reaches before exiting the annealing loop
			ANNEAL_TEMP=${OPTARG};;
		l) # load last save

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
# fourth argument: number of times the node has iterated
RETRY_VAL=$4



## FUNCTIONS
# none


## SCRIPT
# determine the operation to perform
if [[ BOOL_SAVEINIT -eq 1 ]]; then 
	# inform the user
	echo "${CURRENTTIME}: initalization node completed (exit code ${RETURN_VAL})."

	# write the name of the directory that contains the save files
	# for the next annealing simulation
	echo "init" > $TMP_FILE

	exit 0
elif [[ BOOL_ANNEAL -eq 1 ]]; then
	# inform the user
	echo "${CURRENTTIME}: anneal node completed (exit code ${RETURN_VAL}, number of attempts ${RETRY_VAL})."

	# save the current files from the most recent simulation to the appropriate directory
	# get the directory that the files were loaded from
	NXT_DIR_INT=$( head -n 1 $TMP_FILE | tail -n 1 )
	if [[ NXT_DIR_INT == "init" ]]; then 
		# if the previous directory was the initial simulation
		# the simulation is the first iteration of the annealing loop
		declare -i NXT_DIR_INT=0
	else 
		# otherwise the directory is already stored as an integer
		declare -i NXT_DIR_INT=$NXT_DIR_INT # store value as integer
		$((NXT_DIR_INT+=1)) # increment
	fi
	# format the integer into a standard format
	NXT_DIR=$(printf '%03d' ${NXT_DIR_INT})
	# if the directory does not exist, make it
	if [[ ! -d "./anneal/${NXT_DIR}" ]]; then 
		mkdir -p "./anneal/${NXT_DIR}"
	fi
	# get list of files that match the naming stratagey
	SIM_FILES=("./anneal/tmp/${JOB}${SIMID}*")
	for f in ${SIM_FILES}; do
		# copy the file from the temporary directory to
		# the directory corresponding to the annealing directory
		cp "${f}" "./anneal/${NXT_DIR}/"
	done

	# parse the temperature from the save file
	SAVE_FILE="./anneal/temp/${JOB}${SIMID}__simSAVE.dat"
	CURR_TEMP=$( head -n 1 $SAVE_FILE | tail -n 1 )

	# determine if the temperature meets the criteria to exit the annealing loop
	declare -i BOOL_EXIT=$(python comp_temp.py "${CURR_TEMP}" "${ANNEAL_TEMP}")
	if [[ BOOL_EXIT -eq ]]; then
		# if the current temperature of the simulation meets the critera to leave the loop
		echo "${CURRENTTIME}: Annealing simulation temperature is ${CURR_TEMP}, which is below the threshold ${ANNEAL_TEMP}."
		# inform the user and exit with a 0 exit code
		exit 0
	else
		# otherwise, the annealing simulation should iterate again
		# inform the user
		echo "${CURRENTTIME}: Annealing simulation temperature is ${CURR_TEMP}, which is above the threshold ${ANNEAL_TEMP}."
		# store the next integer in the temp directory file for the pre-wrapping script
		echo "${NXT_DIR_INT}" > $TMP_FILE
		# exit script with non-zero exit code
		exit 0 # TODO :: change to nonzero exit code
	fi
fi

exit 0