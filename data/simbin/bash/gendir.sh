# !/bin/bash
set -e

# Matthew A. Dorsey
# 2023.07.25
# script for generating directories without over writing them

## PARAMETERS
# nonezero exit code for program
declare -i NONZERO_EXITCODE=120
# boolean that determines if the script should execute verbosely
declare -i VERB_BOOL=0
# boolean that determines if the directory has been specified
declare -i DIR_BOOL=0
# boolean that determines if the subdirectory has been specified
declare -i SUBDIR_BOOL=0


## FUNCTIONS
# lists script usage, arguments that must be specified
help() {

	echo -e "\nIncorrect options specified."
	echo -e "-v :: execute script verbosely."
	echo -e "-d << ARG >> :: MANDATORY: directory that already exists."
	echo -e "-s << ARG >> :: MANDATORY: subdirectory to generate inside directory that already exists."

}


## OPTIONS
while getopts "d:s:v" options; do 
	case $options in 
		v) # execute the script verbosely
			
			# boolean that determines if the script should
			# be executed verbosely
			declare -i VERB_BOOL=1 ;;
		d) # specify the directory that already exists

			# parse the directory from the arguments
			DIR_PATH="${OPTARG}"
			
			# boolean that determines if the directory has been specified
			declare -i DIR_BOOL=1
			
			;;
		s) # specify the subdirectories that should be generated
			
			# aprse the subdirectory from the arguments
			SUBDIR_PATH="${OPTARG}"

			# boolean that determines if the subdirectory has been specified
			declare -i SUBDIR_BOOL=1
			;;
		\?) # default if incorrect options are specified
			
			# inform user of the correct options
			help

			exit $NONZERO_EXITCODE ;;
    esac
done
shift $((OPTIND-1))


## ARGUMENTS
# none


## SCRIPT

# check that the correct information was specified


# inform the user
if [[ VERB_BOOL -eq 1 ]]; then 
	echo "generating /${subd} in ${D}."
fi

# check to see if the directory exists
directory="./${D}/${subd}"
if test -d $directory; then 
    # if the directory exists, check to see if it contains any files
    if [[ -n "$(ls -A $directory)" && ${EXEC_CODE} -eq 0 ]]; then 
    	# remove files in the directory only if the directory contains files
    	# and if the simulation is restarting completely
        rm ${directory}/*
    fi
else
    # make the directory
    mkdir -p $directory
fi