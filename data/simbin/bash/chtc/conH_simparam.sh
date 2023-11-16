# !/bin/bash
set -e 

## Matthew A. Dorsey
## 2023.11.14
## program for generating parameters for conH annealing simulations

## PARAMETERS
# header for simulation parameter file
HEADER="jobid,simid,XA,H,ETA,RP,path"
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
declare -i FIELD_INC=2

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

# method of generate a simulation directory according to the simulation parameters
# this method is used to control the generating of simulation directories, and is
# called by all other methods in the script
get_simpath () {

	## PARAMETERS
	# none

	## OPTIONS
	# none

	## ARGUMENTS
	# first parameter :: integer representing the a-chirality fraction of the system
	declare -i XA=$1
	# second parameter :: integer representing the external field strength of the simulation
	declare -i H=$2
	# third parameter :: integer representing the system density
	declare -i ETA=$3
	# fourth parameter :: integer representing the number of replicates performed
	declare -i REP=$4

	## SCRIPT
	# translate the integers to a formatted string
	# first directory corresponds to the a-chirality fraction
	D1=$(printf '%03d' ${XA})
	D1="a${D1}"
	# second directory correspond to the external field strength
	D2=$(printf '%02d' ${H})
	D2="h${D2}"
	# third directory correspond to the a-chirality fraction
	D3=$(printf '%02d' ${ETA})
	D3="e${D3}"
	# fourth directory is the number of replicates
	D4=$(printf '%02d' ${REP})
	D4="r${D4}"

	# generate the directory and return to user
	local DIR=${D0}/${D1}/${D2}/${D3}/${D4}
	echo $DIR
}

# generates simulation parameters for a constant field strength
gen_conH () {

	## PARAMETERS
	# none

	## OPTIONS
	# none

	# TODO :: add options to specify an a-chirality fraction value
	# TODO :: add options to specify a density

	## ARGUMENTS 
	# first argument :: integer corresponding to the constant field strength value
	declare -i H_INT=$1

	## SCRIPT 
	# establish the constant field strength value as a floating point value
	H_STRING=$(printf '%02d' ${H_INT})
	H_VALUE=$(printf '%3.2f' $(awk "BEGIN { print ${H_INT} / 100 }"))
	# establish the directory that contains the simulation parameters for constant field strength
	H_FILE=${D0}/summary/H
	if [[ ! -d ${H_FILE} ]]; then
		# make the directory if it does not exist
		mkdir $H_FILE
	fi
	# establish the file that contains the simulation parameters for the constant field strength value
	H_FILE=${D0}/summary/H/${JOB}_h${H_STRING}.csv
	if [[ ! -f $H_FILE ]]; then
		# if the file does not exist, write the header to the file
		echo $HEADER > $H_FILE
	fi
	# inform the user
	echo -e "\nconH_simparam :: Generating simulations for constant field strength of ${H_VALUE} (${REPLICATES} replicates)."

	# loop through all densities and a-chirality fraction values, write to file
	# start with the a-chirality fraction
	declare -i XA_INT=$XA_MIN 
	while [[  XA_INT -le XA_MAX ]]; do

		# establish the achirality value
		XA_VALUE=$(printf '%3.2f' $(awk "BEGIN { print ${XA_INT} / 100 }"))

		# then loop through all densities
		declare -i ETA_INT=$ETA_MIN
		while [[ ETA_INT -le ETA_MAX ]]; do

			# establish the density value
			ETA_VALUE=$(printf '%3.2f' $(awk "BEGIN { print ${ETA_INT} / 100 }"))

			# loop through replicates
			declare -i R=0
			while [[ $R -lt $REPLICATES ]]; do 

				# determine the directory path based on the simulation parameters / replicates
				SIMDIR=$(get_simpath $XA_INT $H_INT $ETA_INT $R) 
				# establish the simulation parameter string
				SIMPARAM_STRING="${JOBID},${SIMID},${XA_VALUE},${H_VALUE},${ETA_VALUE},${R},${SIMDIR}"


				# check if the directory exists
				if [[ ! -d $SIMDIR ]]; then
					if [[ VERB_BOOL -eq 1 ]]; then
						echo "conH_simparam :: Establishing $SIMDIR .."
					fi
					# if it does not, initialize the path to the directory
					# mkdir -p $SIMDIR # directories are generated in the conH submission / analysis script
					# write the parameters to the main simulation parameter file
					echo $SIMPARAM_STRING >> $SIMPARAM_FILE
					# write the simulation parameters to the conH file
					echo $SIMPARAM_STRING >> $H_FILE
				else
					# if the directory does exist, the parameter should already be stored in the main sim param file
					if [[ VERB_BOOL -eq 1 ]]; then
						echo "conH_simparam :: $SIMDIR has already been established .."
					fi
				fi

				((R+=1))
			done
			((ETA_INT+=ETA_INC))
		done
		((XA_INT+=XA_INC))
	done
}

# generates simulation parameters for a constant density
gen_conXA () {

	## PARAMETERS
	# none

	## OPTIONS
	# none

	## ARGUMENTS 
	# first argument :: integer corresponding to the constant a-chirality fraction value
	declare -i XA_INT=$1

	## SCRIPT 
	# establish the constant field strength value as a floating point value
	XA_STRING=$(printf '%03d' ${XA_INT})
	XA_VALUE=$(printf '%3.2f' $(awk "BEGIN { print ${XA_INT} / 100 }"))
	# establish the directory that contains the simulation parameters for constant field strength
	XA_FILE=${D0}/summary/XA
	if [[ ! -d ${XA_FILE} ]]; then
		# make the directory if it does not exist
		mkdir $XA_FILE
	fi
	# establish the file that contains the simulation parameters for the constant field strength value
	XA_FILE=${D0}/summary/XA/${JOB}_a${XA_STRING}.csv
	if [[ ! -f $XA_FILE ]]; then
		# if the file does not exist, write the header to the file
		echo $HEADER > $XA_FILE
	fi
	# inform the user
	echo -e "\nconH_simparam :: Generating simulations for a-chirality fraction value of ${XA_VALUE} (${REPLICATES} replicates)."

	# loop through all external field strengths and density values, write to file
	# start with the external field strength
	declare -i H_INT=$FIELD_MIN 
	while [[  H_INT -le FIELD_MAX ]]; do

		# establish the field strength value
		H_VALUE=$(printf '%3.2f' $(awk "BEGIN { print ${H_INT} / 100 }"))

		# then loop through all densities
		declare -i ETA_INT=$ETA_MIN
		while [[ ETA_INT -le ETA_MAX ]]; do

			# establish the density value
			ETA_VALUE=$(printf '%3.2f' $(awk "BEGIN { print ${ETA_INT} / 100 }"))

			# loop through replicates
			declare -i R=0
			while [[ $R -lt $REPLICATES ]]; do 

				# determine the directory path based on the simulation parameters / replicates
				SIMDIR=$(get_simpath $XA_INT $H_INT $ETA_INT $R) 
				# establish the simulation parameter string
				SIMPARAM_STRING="${JOBID},${SIMID},${XA_VALUE},${H_VALUE},${ETA_VALUE},${R},${SIMDIR}"

				# check if the directory exists
				if [[ ! -d $SIMDIR ]]; then
					if [[ VERB_BOOL -eq 1 ]]; then
						echo "conH_simparam :: Establishing $SIMDIR .."
					fi
					# if it does not, initialize the path to the directory
					# mkdir -p $SIMDIR # directories are generated in the conH submission / analysis script
					# write the parameters to the main simulation parameter file
					echo $SIMPARAM_STRING >> $SIMPARAM_FILE
					# write the simulation parameters to the conH file
					echo $SIMPARAM_STRING >> $XA_FILE
				else
					# if the directory does exist, the parameter should already be stored in the main sim param file
					if [[ VERB_BOOL -eq 1 ]]; then
						echo "conH_simparam :: $SIMDIR has already been established .."
					fi
				fi

				((R+=1))
			done
			((ETA_INT+=ETA_INC))
		done
		((H_INT+=FIELD_INC))
	done
}

# # generates simulation parameters for a constant density value
gen_conETA () {

	## PARAMETERS
	# none

	## OPTIONS
	# none

	# TODO :: add options to specify an a-chirality fraction value
	# TODO :: add options to specify an external field strength

	## ARGUMENTS 
	# first argument :: integer corresponding to the constant density value
	declare -i ETA_INT=$1

	## SCRIPT 
	# establish the constant field strength value as a floating point value
	ETA_STRING=$(printf '%02d' ${ETA_INT})
	ETA_VALUE=$(printf '%3.2f' $(awk "BEGIN { print ${ETA_INT} / 100 }"))
	# establish the directory that contains the simulation parameters for constant field strength
	ETA_FILE=${D0}/summary/ETA
	if [[ ! -d ${ETA_FILE} ]]; then
		# make the directory if it does not exist
		mkdir $ETA_FILE
	fi
	# establish the file that contains the simulation parameters for the constant field strength value
	ETA_FILE=${D0}/summary/ETA/${JOB}_e${ETA_STRING}.csv
	if [[ ! -f $ETA_FILE ]]; then
		# if the file does not exist, write the header to the file
		echo $HEADER > $ETA_FILE
	fi
	# inform the user
	echo -e "\nconH_simparam :: Generating simulations for constant density of ${ETA_VALUE} (${REPLICATES} replicates)."

	# loop through all densities and a-chirality fraction values, write to file
	# start with the a-chirality fraction
	declare -i XA_INT=$XA_MIN 
	while [[  XA_INT -le XA_MAX ]]; do

		# establish the achirality value
		XA_VALUE=$(printf '%3.2f' $(awk "BEGIN { print ${XA_INT} / 100 }"))

		# then loop through all densities
		declare -i H_INT=$FIELD_MIN
		while [[ H_INT -le FIELD_MAX ]]; do

			# establish the density value
			H_VALUE=$(printf '%3.2f' $(awk "BEGIN { print ${H_INT} / 100 }"))

			# loop through replicates
			declare -i R=0
			while [[ $R -lt $REPLICATES ]]; do 

				# determine the directory path based on the simulation parameters / replicates
				SIMDIR=$(get_simpath $XA_INT $H_INT $ETA_INT $R) 
				# establish the simulation parameter string
				SIMPARAM_STRING="${JOBID},${SIMID},${XA_VALUE},${H_VALUE},${ETA_VALUE},${R},${SIMDIR}"


				# check if the directory exists
				if [[ ! -d $SIMDIR ]]; then
					if [[ VERB_BOOL -eq 1 ]]; then
						echo "conH_simparam :: Establishing $SIMDIR .."
					fi
					# if it does not, initialize the path to the directory
					# mkdir -p $SIMDIR # directories are generated in the conH submission / analysis script
					# write the parameters to the main simulation parameter file
					echo $SIMPARAM_STRING >> $SIMPARAM_FILE
					# write the simulation parameters to the conH file
					echo $SIMPARAM_STRING >> $ETA_FILE
				else
					# if the directory does exist, the parameter should already be stored in the main sim param file
					if [[ VERB_BOOL -eq 1 ]]; then
						echo "conH_simparam :: $SIMDIR has already been established .."
					fi
				fi

				((R+=1))
			done
			((H_INT+=FIELD_INC))
		done
		((XA_INT+=XA_INC))
	done
}



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
# first argument :: job id
JOBID=$1
# second argument :: simulation id
SIMID=$2


## SCRIPT
## check that the simulation directories and files exist
#  check that the main simulation directory exists
D0=${JOBID}/${SIMID}
if [[ ! -d $D0 ]]; then 
	mkdir -p $D0
fi
# check that the summary directory exists
if [[ ! -d "${D0}/summary" ]]; then
	mkdir ${D0}/summary
fi
# establish the file name that contains simulation parameters for all jobs
JOB=${JOBID}_${SIMID}
SIMPARAM_FILE=${D0}/${JOB}.csv
if [[ ! -f $SIMPARAM_FILE ]]; then 
	# if the file does not exists, inform the user and write the header to the file
	echo -e "conH_simparam :: Initializing simulation parameter file for $JOB."
	echo $HEADER > $SIMPARAM_FILE
fi

## according to the options that were called, generate simulation parameteres
# constant field simulations
if [[ FIELD_BOOL -eq 1 ]]; then 
	# generate constant field surface corresponding to integer passed to the script
	gen_conH $FIELD
fi 

# constant density simulations
if [[ ETA_BOOL -eq 1 ]]; then
	# generate constant density surface corresponding to the integer passed to the script
	gen_conETA $ETA
fi

# constant a-chirality fraction simulations
if [[ XA_BOOL -eq 1 ]]; then 
	# generate constant a-chirality fraction surface corresponding to the integer passed to the script
	gen_conXA $XA
fi
