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
SAVE=( "fposSAVE" "velSAVE" "chaiSAVE" "annSAVE" "simSAVE" )
# boolean determining if initial simulation save data should be loaded
declare -i BOOL_LOADINIT=0
# boolean determining if last save should be loaded
declare -i BOOL_LOADLAST=0
# boolean determining if simulation should be saved
declare -i BOOL_SAVE=0


## FUNCTIONS
# none


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
fi
