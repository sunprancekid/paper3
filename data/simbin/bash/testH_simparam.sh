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
# boolean that determines if the path to the directory that the 
# simulation parameters should be written to has been specified
declare -i PATH_BOOL=0
# default path to write file to is current directory
PATH="."
# boolean used to determine if a file name was provided by the user
declare -i FILE_BOOL=0
# default file name used to write simulation parameters to
FILE="testH_param.csv"
# boolean that determines if the simulation cell size has been specified
declare -i CELL_BOOL=0
# default cell size assigned if none is provided by the user
declare -i CELL=16
# boolean that determines if the simulation number of events has been specified
declare -i EVENT_BOOL=0
# default number of events if none are specified by the user
declare -i EVENT=100000000
# boolean that determines if an integer corresponding to the simulation
# area fraction has been specified
declare -i AF_BOOL=0
# default area fraction if none is provided by the user
declare -i AF=20
# header used to organize simulation parameters
HEADER="n,simid,rp,area_frac,events,cell,temp,vmag,ffrq"

## FUNCTIONS
# write script usage to command line
help () {

	# list the script's arguments
	echo -e "\n./testH_simparam.sh <<FLAGS>> \nScript for generating testH simulation parameters.\n"
	echo -e "-v :: execute script verbosely."
	echo -e "-p << ARG >> :: path to write simulation parameter files to (default is ${PATH})."
	echo -e "-f << ARG >> :: simulation parameter filename. default file name is ${FILE}"
	echo -e "-a << ARG >> :: simulation area fraction as integer e2 (default value is ${AF})"
	echo -e "-c << ARG >> :: simulation cell size (default value is ${CELL})"
	echo -e "-e << ARG >> :: simulation events (default value is ${EVENT})"
}

# function that writes testH jobs with constant velocity magnitude
conV () {

	## PARAMETERS
	# 
}

## OPTIONS
while getopts "a:c:e:f:p:v" options; do 
	case $options in 
		a) # simulation area fraction specified by user

			# boolean that determines if the area fraction was specified by the user
			declare -i AF_BOOL=1

			# parse the value from the user, overwrite the old value
			declare -i AF=${OPTARG}

			;;
		c) # simulation cell size specified by user

			# boolean that determines if the cell size was specified by the user
			declare -i CELL_BOOL=1

			# parse the value from the user, overwrite the old value
			declare -i CELL=${OPTARG}

			;;
		e) # simulation events specified by user

			# boolean the determines if the simulation events was specified by the user
			declare -i EVENT_BOOL=1

			# parse the value from the user, overwrite the old value
			declare -i EVENT=${OPTARG}

			;;
		f) # simulation parameter file name specified by user

			# boolean that determines if the filename was specified by the user
			declare -i FILE_BOOL=1

			# parse the value from the user, overwrite the old value
			FILE=${OPTARG}

			;;
		p) # path to write file to was provided by the user
			
			# boolean that determines if the path was provided by the user
			declare -i PATH_BOOL=1

			# parse the value, overwrite the old value
			PATH=${OPTARG}

			;;
		v) # execute the script verbosely
			
			# boolean that determines if the script should be executed verbosely
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

# determine the type of parameters to generate

# write the values to the file specified by the user

