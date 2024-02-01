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
# header used to organize simulation parameters
# HEADER="n,simid,rp,area_frac,events,cell,temp,vmag,ffrq"

## PARAMETER FILE LOCATION
# boolean that determines if the path to the directory that the 
# simulation parameters should be written to has been specified
declare -i PATH_BOOL=0
# default path to write file to is current directory
SIMPARAM_PATH="./"

## PARAMETER FILE NAME
# boolean used to determine if a file name was provided by the user
declare -i FILE_BOOL=0
# default file name used to write simulation parameters to
SIMPARAM_FILE="testH_param.csv"

## SIMULATION CELL SIZE
# boolean that determines if the simulation cell size has been specified
declare -i CELL_BOOL=0
# default cell size assigned if none is provided by the user
declare -i CELL=16

## EVENTS
# boolean that determines if the simulation number of events has been specified
declare -i EVENT_BOOL=0
# default number of events if none are specified by the user
declare -i EVENT=100000000

## SIMULATION AREA FRACTION
# boolean that determines if an integer corresponding to the simulation
# area fraction has been specified
declare -i AF_BOOL=0
# default area fraction if none is provided by the user
declare -i AF=20

## SIMULATION TEMPERATURE
# boolean determining if the temperature has been passed to the method
declare -i TEMP_BOOL=0

## SIMULATION FIELD STRENGTH
# boolean determing if simulation field strength was called
# indicating that TH simulations should be performed
declare -i FIELD_BOOL=0

## SIMULATION THERMAL TO FIELD STRENGTH (X)
# booleaning determing if ratio of thermal to magnetic energy was called
# indicating the TX simulations should be performed
declare -i X_BOOL=0

## INCREMENT
# amount to increment X or H by, which ever is called
declare -i INC_INT=10

## NUMBER OF REPLICATES
# boolean that determines if an integer corresponding to the 
# number of each unique set of simulation parameters should be repeated
declare -i REP_BOOL=0
# default number of replicates repeated by simulation
declare -i REPLICATES=3

## FUNCTIONS
# write script usage to command line
help () {

	# list the script's arguments
	echo -e "\nUSAGE :: ./testH_simparam.sh <<FLAGS>> \nScript for generating testH simulation parameters.\n"
	echo -e "-v           :: execute script verbosely."
	echo -e "\n || MADATORAY ARGUMENTS || "
	echo -e "-t << ARG >> :: (MADATORAY) simulation temperature as integer."
	echo -e "-h << ARG >> :: perform TH simulations (up to a maximum value of integer value passed to method)."
	echo -e "-x << ARG >> :: perform TX simulations (up to a maximum value of integer value passed to method)."
	echo -e "\n || SIMULATION OPTIONS || "
	echo -e "-i << ARG >> :: integer determining the amount to increment H or X by (default is ${INC_INT})."
	echo -e "-c << ARG >> :: simulation cell size (default value is ${CELL})"
	echo -e "-e << ARG >> :: simulation events (default value is ${EVENT})"
	echo -e "-a << ARG >> :: simulation area fraction as integer e2 (default value is ${AF})"
	echo -e "-r << ARG >> :: number of times unique simulations are repeated (default is ${REPLICATES})"
	echo -e "\n || SCRIPT OPTIONS || "
	echo -e "-p << ARG >> :: path to write simulation parameter files to (default is ${SIMPARAM_PATH})."
	echo -e "-f << ARG >> :: simulation parameter filename. default file name is ${SIMPARAM_FILE}"
}

# function that generates the simulation id based on the simulation parameters
get_simid () {

	## PARAMETERS
	# boolean that determines if an integer representing temperature
	# was passed to the method as an argument
	declare -i t_bool=0
	# boolean that determines if an integer representing x was passed
	# to the method as an argument
	declare -i x_bool=0
	# boolean that determines if an integer representing field strength
	# was passed to the method as an argument
	declare -i h_bool=0
	# boolean that determines if an integer representing replicate number
	# was passed to the method as an argument
	declare -i r_bool=0

	## ARGUMENTS 
	# none

	## OPTIONS
	# parse options
	while [ "$#" -gt 0 ]; do
	    case "$1" in
	    	-t)
				# flip the boolean
				declare -i t_bool=1
				# parse the integer passed to the argument
				declare -i t_int=$2
	        	shift 2
	        	;;
	    	-x)
				# flip the boolean
				declare -i x_bool=1
				# parse the integer passed to the argument
				declare -i x_int=$2
	        	shift 2
	        	;;
	        -h) 
				# flip the boolean
				declare -i h_bool=1
				# parse the integer passed to the argument
				declare -i h_int=$2
				shift 2
				;;
			-r)
				# flip the boolean
				declare	-i r_bool=1
				# parse the integer passed to the argument
				declare -i r_int=$2
				shift 2
				;;
	    	*)
	        	echo "Unknown option: $1"
	        	return 1
	        	;;
	    esac
  	done

	## SCRIPT
	# establish the simulation id
	simid=""

	if [[ $t_bool -eq 1 ]]; then
		t_string=$(printf '%03d' ${t_int})
		simid="${simid}t${t_string}"
	fi

	if [[ $h_bool -eq 1 ]]; then
		h_string=$(printf '%03d' ${h_int})
		simid="${simid}h${h_string}"
	fi

	if [[ $x_bool -eq 1 ]]; then
		x_string=$(printf '%03d' ${x_int})
		simid="${simid}x${x_string}"
	fi

	if [[ $r_bool -eq 1 ]]; then
		r_string=$(printf '%03d' ${r_int})
		simid="${simid}r${r_string}"
	fi

	# return to user
	echo $simid
}

# function that writes simulation parameters for simulations
# that varies with respect X (the ratio of magnetic to thermal 
# energy in the system) for a constant temperature
genTX () {

	## PARAMETERES
	# file that contains parameters for TX simulations
	TX_file=${SIMPARAM_PATH}${SIMPARAM_FILE}
	# header that is written to file
	TX_header='id,d,c,e,r,T,X'
	# formatted density as area fraction
	DEN=$(printf '%3.2f' $(awk "BEGIN { print $AF / 100 }"))
	## X parameters- ratio of magnetic to thermal energy
	# minimum x val
	declare -i minX_int=0
	# maximum x val
	declare -i maxX_int=$MAX_X_VAL
	# amount to increment x by
	declare -i incX_int=$INC_INT
	# string used to format the x int to a double val
	formX=''

	## ARGUMENTS
	# none

	## SCRIPT
	# # determine if the file exists
	# if ! [ -f $TX_file ]; then
	# 	# if the file does not exist, write the header to file
	# 	echo $TX_header > $TX_file
	# fi

	# loop through variables, write each combination to file
	declare -i N=0
	# first variable is x
	declare -i X=$minX_int
	while [[ $X -le $maxX_int ]]; do
		# second variable is replicates
		declare -i RP=0
		while [[ $RP -lt $REPLICATES ]]; do
			# establish the simulation id
			SIMID=$(get_simid -t $T -x $X -r $RP)
			# echo $(get_simid -t $T -x $X -r $rp)
			# get parameters as floating point numbers
			X_VAL=$(printf '%4.3f' $(awk "BEGIN { print $X / 100 }"))
			T_VAL=$(printf '%4.3f' $(awk "BEGIN { print $T / 100 }"))
			# establish comma seperated list of simulation parameters
			PARM="$SIMID,$DEN,$CELL,$EVENT,$RP,$T_VAL,$X_VAL"
			# write the values to file
			echo $PARM >> $TX_file
			# increment counter
			((N+=1))
			# increment replicates and repeat
			((RP+=1))
		done
		# increment x and repeat 
		((X+=$incX_int))
	done
}

# function that writes testH jobs with constant velocity magnitude
conT () {

	## PARAMETERS
	# path to file that is being written to
	SIMPARAM="${SIMPARAM_PATH}${SIMPARAM_FILE}"
	# minimum velocity magnitude
	declare -i VMAG_MIN=0
	# maximum velocity magnitude
	declare -i VMAG_MAX=150
	# amount to increment the velocity magnitude by
	declare -i VMAG_INC=2
	# minimum field frequency
	declare -i FFRQ_MIN=10
	# maximum field frequency
	declare -i FFRQ_MAX=600
	# amount to increment the field frequency by
	declare -i FFRQ_INC=5

	## ARGUMENTS
	# first argument: temperature set point for simulation
	declare -i TEMP=$1

	## SCRIPT
	# inform user
	if [[ VERB_BOOL -eq 1 ]]; then 
		echo "generating simulation parameters in ${SIMPARAM}."
	fi

	# if the file exists, delete it
	if test -f $SIMPARAM
	then 
		rm $SIMPARAM
	fi

	# write area fraction string
	AF_VAL=$(printf '%4.3f' $(awk "BEGIN { print ${AF} / 100 }"))

	# write temperature val, and formatted string
	TEMP_VAL=$(printf '%3.2f' $(awk "BEGIN { print ${TEMP} / 100 }"))
	TEMP_STRING=$(printf '%03d' $TEMP)
	TEMP_SIMID="t${TEMP_STRING}"


	# loop through variables, write to file
	declare -i COUNT=0
	# first variable is the velocity magnitude
	declare -i VMAG=$VMAG_MIN
	while [[ VMAG -le VMAG_MAX ]]; do

		# write formatted velocity magnitude strings 
		VMAG_VAL=$(printf '%3.2f' $(awk "BEGIN { print ${VMAG} / 100 }"))
		VMAG_STRING=$(printf '%03d' ${VMAG})
		VMAG_SIMID="v${VMAG_STRING}"

		# second variable is the field frequency
		declare -i FFRQ=$FFRQ_MIN
		while [[ FFRQ -le FFRQ_MAX ]]; do

			# write formatted field frequency strings
			FFRQ_VAL=$(printf '%03d' ${FFRQ})
			FFRQ_STRING=$(printf '%03d' ${FFRQ})
			FFRQ_SIMID="f${FFRQ_STRING}"

			# loop through replicates
			declare -i RP=1
			while [[ RP -le REPLICATES ]]; do

				SIMID="${TEMP_SIMID}${VMAG_SIMID}${FFRQ_SIMID}"

				# write the simulation parameters to the input file
				VAR="${COUNT},${SIMID},${RP},${AF_VAL},${EVENT},${CELL},${TEMP_VAL},${VMAG_VAL},${FFRQ_VAL}"
				echo $VAR >> $SIMPARAM
				((RP+=1))
				((COUNT+=1))
			done

			# increment the field frequency value
			((FFRQ+=FFRQ_INC))
		done

		# increment the velocity magnitude value
		((VMAG+=VMAG_INC))
	done

	# TODO :: ADD verbose statement with information about the parameters that were generated
}

## OPTIONS
while getopts "t:h:x:i:a:c:e:f:p:r:v" options; do 
	case $options in 
		t) # simulation temperature
			# boolean determining that the simulation temperature was specified
			declare -i TEMP_BOOL=1
			# parse the integer passed to the method
			declare -i T=${OPTARG}
			;;
		h) # simulation field strength
			# boolean determing that the simulation field strength was specified
			# incidating that TH simulations should be generated
			declare -i FIELD_BOOL=1
			# parse the integer passed to the method
			declare -i MAX_FIELD_VAL=${OPTARG}
			;;
		x) # simulation ratio of temperature to external field strength
			# boolean determining that the ration of magnetic to thermal energy was specified
			# indicating that TX simulations should be performed
			declare -i X_BOOL=1
			# parse the integer passed to the method
			declare -i MAX_X_VAL=${OPTARG}
			;;
		i) # amount to increment H or X integer by
			# parse the integer
			declare -i INC_INT=${OPTARG}
			;;
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
			SIMPARAM_FILE=${OPTARG}
			;;
		p) # path to write file to was provided by the user
			# boolean that determines if the path was provided by the user
			declare -i PATH_BOOL=1
			# parse the value, overwrite the old value
			SIMPARAM_PATH=${OPTARG}
			;;
		r) # number of times each unique set of parameters should be repeated
			# boolean that determines if a unique number of replicates was specified
			# by the user
			declare -i REP_BOOL=1
			# parse the value, overwrite default
			declare -i REPLICATES=${OPTARG}
			;;
		v) # execute the script verbosely
			# boolean that determines if the script should be executed verbosely
			declare -i VERB_BOOL=1 ;;
		\?) # default if incorrect options are specified
			# inform user of the correct options
			echo -e "\nIncorrect options specified (${options}).\n"
			help
			exit $NONZERO_EXITCODE ;;
    esac
done
shift $((OPTIND-1))

## ARGUMENTS
# none

## SCRIPT
# TODO check for illegal options
# TODO add option for clearing file that data will be written to
#		before writing to file

# if the script is executing verbosely, inform the user
if [[ $VERB_BOOL -eq 1 ]]; then
	echo "TODO :: implement verbose execution for testH_simparam.sh"
fi

# generate testing parameters for constant temperature and magnetic / thermal ration
genTX

