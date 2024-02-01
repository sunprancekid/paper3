# !/bin/bash
set -e

# Matthew Dorsey
# 2023-04-20
# program that takes save files from polsqu simulations
# and saves them to a seperate directory with a different name.

## PARAMETERS 
# current date and time 
CURRENTTIME=$(date '+%Y-%m-%d %H:%M:%S')
CURRENTTIME="postscript @ ${CURRENTTIME}"
# non-zero exit code for wrapper
declare -i NONZERO_EXITCODE=1
# exit code that idicates to CHTC scheduler that 
# the job should be put on hold
declare -i HOLD_EXITCODE=95
# array containing a list of SAVE files
SAVE=( "fposSAVE" "velSAVE" "chaiSAVE" "annealSAVE" "simSAVE" )
# temp file used to store information about saving and loading
# annealing simulations between pre- and post-processing scripts
TMP_FILE="./anneal/tmp/next_dir.txt"
# retry file contains the number of times that a job exits with 
# non-zero exit code in a row
RETRY_FILE="./anneal/tmp/retry.txt"
# boolean determining if initial simulation save data should be loaded
declare -i BOOL_SAVEINIT=0
# boolean used to determine if the script is handling an annealing simulation
declare -i BOOL_ANNEAL=0
# boolean used to determine if the script is handling a rerun of a previous
# iteration of the annealing simulation
declare -i BOOL_RERUN=0
# boolean determining if last save should be loaded
declare -i BOOL_LOADLAST=0
# boolean determining if simulation should be saved
declare -i BOOL_SAVE=0
# boolean that determines if the exit code was passed to the save script
declare -i HAS_EXITCODE=0


## OPTIONS
while getopts "ia:lsr:e:" option; do
    case $option in
    	i) # save initial simulation data

			# boolean determining if initial simulation save data should be loaded
			declare -i BOOL_SAVEINIT=1 ;;
		a) # save most recent iteration of annealing simulation
			
			# boolean determining if the script is handling an iteration
			# of the annealing loop
			declare -i BOOL_ANNEAL=1

			# the value passed with the flag is the minimum temperature 
			# that the simulation reaches before exiting the annealing loop
			ANNEAL_TEMP=${OPTARG};;
		r) # save a specific rerun of a previous iteration of an annealing simulation

			# boolean that determines if the the script is handling a previous
			# iteration of a previous version of the annealing simulation
			declare -i BOOL_RERUN=1

			# the value passed with the flag is the integer corresponding to the 
			# iteration of the annealing simulation that was rerun and 
			# that the script is handling
			declare -i RERUN_IT=${OPTARG};; 
		l) # load last save

			# boolean determining if last save should be loaded
			declare -i BOOL_LOADLAST=1;;
		e) # check the simulation exit code

			# boolean determining that the simulation exit code was passed to the method
			declare -i HAS_EXITCODE=1

			# parse the exit code from the flag
			declare -i EXITCODE=${OPTARG};;
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
# # third argument: exit code of the node being processed
# RETURN_VAL=$3
# third argument: number of times the node has iterated
RETRY_VAL=$3 # TODO :: CHANGE THIS NAME!!



## FUNCTIONS
# none


## SCRIPT

# determine the operation to perform
if [[ $BOOL_SAVEINIT -eq 1 ]]; then 
	# stdout file specific to initialization nodes
	INIT_STDOUT="./out/init_stdout.txt"
	# inform the user
	# echo "${CURRENTTIME}: initalization node completed (exit code ${RETURN_VAL})."
	echo "${CURRENTTIME}: initialization node completed successfully." >> $INIT_STDOUT

	# write the name of the directory that contains the save files
	# for the next annealing simulation
	echo "init" > $TMP_FILE

	exit 0
elif [[ $BOOL_ANNEAL -eq 1 ]]; then
	# stdout file specific to annealing node
	ANNEAL_STDOUT="./out/anneal_stdout.txt"

	# save the current files from the most recent simulation to the appropriate directory
	# get the directory that the files were loaded from
	NXT_DIR_INT=$( head -n 1 $TMP_FILE | tail -n 1 )
	if [[ "${NXT_DIR_INT}" == "init" ]]; then 
		# if the previous directory was the initial simulation
		# the simulation is the first iteration of the annealing loop
		declare -i NXT_DIR_INT=0
	else 
		# otherwise the directory is already stored as an integer
		declare -i NXT_DIR_INT=$NXT_DIR_INT # store value as integer
		((NXT_DIR_INT+=1)) # increment
	fi

	# inform the user
	echo "${CURRENTTIME}: anneal node ${NXT_DIR_INT} completed (total number of attempts is ${RETRY_VAL}). " >> $ANNEAL_STDOUT

	# check the simulation exit code
	if [[ $HAS_EXITCODE -eq 1 ]]; then 
		# if an exit code was passed to the method
		if [[ $EXITCODE -ne 0 ]]; then
			# if the exit code passed to the method was not zero
			# attempt to parse the retry value from the file
			if [[ -f $RETRY_FILE ]]; then 
				# parse the retry val from the retry file
				RETRY_INT=$( head -n 1 $RETRY_FILE | tail -n 1 )
				declare -i RETRY_INT=$RETRY_INT
			else 
				# if the file does not exist, the retry is zero
				declare -i RETRY_INT=0
			fi
			# increment if the value since the exit code was nonzero
			((RETRY_INT+=1))
		else
			# the exit code passed to the method is zero
			# restart the retry iteration
			declare	-i RETRY_INT=0
		fi
		# inform the user
		echo "${CURRENTTIME}: anneal node ${NXT_DIR_INT} exited with code ${EXITCODE} (number of failed retries is ${RETRY_INT})." >> $ANNEAL_STDOUT
	else
		# no exit code was passed to the method
		# restart the retry iteration
		declare	-i RETRY_INT=0
	fi
	# echo the retry int to the retry file, inform the user
	echo "${RETRY_INT}" > $RETRY_FILE

	# parse the current temperature from the save file
	SAVE_FILE="./anneal/tmp/${JOB}${SIMID}__simSAVE.dat"
	CURR_TEMP=$( head -n 3 $SAVE_FILE | tail -n 1 )

	if [[ $RETRY_INT -eq 0 ]]; then
		# if job exited successfully,
		# move the files into next directory

		# format the integer into a standard format
		NXT_DIR=$(printf '%03d' ${NXT_DIR_INT})
		# if the directory does not exist, make it
		if [[ ! -d "./anneal/${NXT_DIR}" ]]; then 
			mkdir -p "./anneal/${NXT_DIR}"
		fi
		# get list of files that match the naming convention
		SIM_FILES=(./anneal/tmp/${NEXT_DIR}/${JOB}${SIMID}*)
		for f in ${SIM_FILES[@]}; do
			# copy the file from the temporary directory to
			# the directory corresponding to the current annealing iteration
			cp "${f}" "./anneal/${NXT_DIR}/"
			# rm "${f}"
		done
		# remove the temporary directory corresponding to the annealing simulation
		# rm -r "./anneal/tmp/$NEXT_DIR"
	else
		# otherwise, the job did not exit successfully
		# delete the file in the temporary directory
		# the pre-script will reload the same inital files

		# get list of files that match the naming convention
		SIM_FILES=(./anneal/tmp/${JOB}${SIMID}*)
		for f in ${SIM_FILES[@]}; do
			rm "${f}"
		done

		# exit the post-script with a non-zero exit code
		# retry the annealing iteration
		exit $NONZERO_EXITCODE
	fi

	# determine if the temperature meets the criteria to exit the annealing loop
	declare -i BOOL_EXIT=$( ./comp_temp.py "${CURR_TEMP}" "${ANNEAL_TEMP}")
	if [[ $BOOL_EXIT -eq 1 ]]; then
		# if the current temperature of the simulation meets the critera to leave the loop
		echo "${CURRENTTIME}: Annealing simulation temperature is ${CURR_TEMP}, which is below the threshold ${ANNEAL_TEMP}." >> $ANNEAL_STDOUT
		# inform the user and exit with a 0 exit code
		exit 0
	else
		# otherwise, the annealing simulation should iterate again
		# inform the user
		echo "${CURRENTTIME}: Annealing simulation temperature is ${CURR_TEMP}, which is above the threshold ${ANNEAL_TEMP}." >> $ANNEAL_STDOUT
		# store the next integer in the temp directory file for the pre-wrapping script
		echo "${NXT_DIR_INT}" > $TMP_FILE
		# exit script with non-zero exit code
		exit $NONZERO_EXITCODE
	fi
elif [[ $BOOL_RERUN -eq 1 ]]; then 
	# establish the directory where the files from the simulation were stored
	RERUN_DIR=$(printf '%03d' ${RERUN_IT})
	# stdout file specific to rerun
	RERUN_STDOUT="./out/anneal${RERUN_DIR}_stdout.txt"

	# check that the job finished successfully
	# check the simulation exit code
	if [[ $HAS_EXITCODE -eq 1 ]]; then 
		# if an exit code was passed to the method
		if [[ $EXITCODE -ne 0 ]]; then
			# the job did not complete succesfully
			# delete the directory that contains the contents from the simulation
			rm -r "./anneal/tmp/${RERUN_DIR}"
			# inform the user
			echo "${CURRENTTIME}: rerun of annealing node ${RERUN_DIR} failed (retry number ${RETRY_VAL})." >> $RERUN_STDOUT
			# exit non-zero so that the job repeats
			exit $NONZERO_EXITCODE
		fi
	fi

	# once the simulation is finished, move the files from the temporary directory to the
	# annealing directory corresponding to the iteration
	SIM_FILES=(./anneal/tmp/${RERUN_DIR}/${JOB}${SIMID}*)
	for f in ${SIM_FILES[@]}; do
		# copy the file from the temporary directory to
		# the directory corresponding to the annealing directory
		cp "${f}" "./anneal/${RERUN_DIR}/"
		rm "${f}"
	done

	# delete the temporary directory corresponding to the annealing simulation rerun
	rm -r "./anneal/tmp/${RERUN_DIR}"

	# signal that the simulation was successfully completed by exiting with a 0 exit code
	echo "${CURRENTTIME}: Annealing rerun ${RERUN_IT} succesfully completed." >> $RERUN_STDOUT
	exit 0
fi

exit 0