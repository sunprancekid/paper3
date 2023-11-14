# !/bin/bash
set -e 

## Matthew A. Dorsey
## 2023.11.14
## program for generating parameters for conH annealing simulations

## PARAMETERS
# header for simulation parameter file
HEADER="jobid,simid,H,ETA,XA,path"
# boolean that determines if the script should be executed verbosely
declare -i VERB_BOOL=0
# default number of replicates
declare -i REPLICATES=1

## FIELD STRENGTH PARAMETERS
# boolean indicating that a constant field strength value was specified
declare -i FIELD_BOOL=0
# minimum field strength
declare -i FIELD_MIN=0
# maximum field strength
declare -i FIELD_MAX=20
# amount the external field strength is incremented by
declare -i FIELD_INC=1

## DENSITY PARAMETERS
# boolean indicating that a constant density value was specified
declare -i ETA_BOOL=0
# minimum density
declare -i ETA_MIN=5
# maximum density
declare -i ETA_MAX=60
# amount the system density is incremented by
declare -i ETA_INC=5

## A-CHIRALITY FRACTION PARAMETERS
# boolean indicating that a constant a-chirality fraction value was specified
declare -i XA_BOOL=0
# minimum allowable a-chirality fraction
declare -i XA_MIN=50
# maximum allowable a-chirality fraction
declare -i XA_MAX=100
# amount the achirality parameter is incremented by
declare -i XA_INC=5



## FUNCTIONS
# prints instructions for using the script
help () {

	# list the script's arguments
	echo -e "\nUSAGE :: ./testH_simparam.sh <<FLAGS>> \nScript for generating conH simulation parameters.\n"
	echo -e "-v           :: execute script verbosely."
	echo -e "-d << ARG >> :: simulation density as area fraction (as integer * e^2 - default value is ${ETA})."
	echo -e "-h << ARG >> :: simulation external field strength (as integer * e^2 - default value is ${FIELD}). "
	echo -e "-x << ARG >> :: simulation a-chirality fraction (as integer * e^2 - default value is ${XA})."
	echo -e "-r << ARG >> :: number of times unique simulations are repeated (default is ${REPLICATES})"
}

# generates simulation parameters for a constant field strength


# generates simulation parameters for a constant density


# generates simulation parameters for a constant A-chirality fraction


## OPTIONS
# parse options
while getopts "d:h:x:r:v" options; do 
	case $options in 
		d) # simulation area fraction specified by user

			# boolean indicating that a constant density value was specified
			declare -i ETA_BOOL=1

			# parse the value from the user
			declare -i ETA=${OPTARG}

			# check that the value passed to the method is within the specified bounds
			if [[ ETA -lt ETA_MIN || ETA -gt ETA_MAX ]]; then
				if [[ ETA -lt ETA_MIN ]]; then 
					echo "conH_simparam :: density value passed to script (${ETA}) is below the minimum allowable value (${ETA_MIN})."
				else
					echo "conH_simparam :: density value passed to script (${ETA}) is greater than the maximum allowable value (${ETA_MAX})."
				fi
				exit $NONZERO_EXITCODE
			fi

			;;
		h) # simulation external field strength

			# boolean indicating that a constant field strength value was specified
			declare -i FIELD_BOOL=1

			# parse the value from the user
			declare -i FIELD=${OPTARG}

			# check that the value is within the bounds
			if [[ FIELD -lt FIELD_MIN || FIELD -gt FIELD_MAX ]]; then
				if [[ FIELD -lt FIELD_MIN ]]; then 
					echo "conH_simparam :: field value passed to script (${FIELD}) is below the minimum allowable value (${FIELD_MIN})."
				else
					echo "conH_simparam :: field value passed to script (${FIELD}) is greater than the maximum allowable value (${FIELD_MAX})."
				fi
				exit $NONZERO_EXITCODE
			fi

			;;
		x) # simulation a-chirality fraction

			# boolean indicating that a constant a-chirality fraction value was specified
			declare -i XA_BOOL=1

			# parse the value from the user, overwrite the old value
			declare -i XA=${OPTARG}

			# check that the value is within the bounds
			if [[ XA -lt XA_MIN || XA -gt XA_MAX ]]; then
				if [[ XA -lt XA_MIN ]]; then 
					echo "conH_simparam :: field value passed to script (${XA}) is below the minimum allowable value (${XA_MIN})."
				else
					echo "conH_simparam :: field value passed to script (${XA}) is greater than the maximum allowable value (${XA_MAX})."
				fi
				exit $NONZERO_EXITCODE
			fi

			;;
		r) # number of times each unique set of parameters should be repeated

			# parse the value, overwrite default
			REPLICATES=${OPTARG}

			# check the value passed to the script is not less than 1
			if [[ REPLICATES -lt 1 ]]; then
				echo "conH_simparam :: replicate value passed to script ($REPLICATES) less than the allowable minimum (1)."
				exit $NONZERO_EXITCODE
			fi
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
# none