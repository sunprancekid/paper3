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
# none


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
	# if loading the previous state of an annealing simulation
	# get the directory that contains the previous state from the temporary file
	NXT_DIR_INT=$( head -n 1 $TMP_FILE | tail -n 1 )
	if [[ "${NXT_DIR_INT}" == "init" ]]; then 
		# if the directory to load is the initial
		NXT_DIR=$NXT_DIR_INT
	else 
		# otherwise the directory is stored as an integer
		declare -i NXT_DIR_INT=$NXT_DIR_INT
		# format the next directory
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
fi

