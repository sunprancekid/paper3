# !/bin/bash
set -e

## Matthew Dorsey
## 2023.08.07
## script for generating conH jobs with polsqu2x2 module on CHTC linux systems


## PARAMETERS
# non-zero exit code that specifies that if error has occured during script execution
declare -i NONZERO_EXITCODE=120
# boolean that determines if the verbose flag was specified
declare -i VERB_BOOL=0
# boolean that determines if the the script should overwrite directories
# containing existing simulation files that correspond to job
declare -i OVERWRITE_BOOL=0
# default job title, unless overwritten
JOB="conH"
# simulation module title
SIM_MOD="polsqu2x2"
# default simulation cell size, unless overwritten
declare -i CELL=12
# minimum field strength used for simulations
declare -i FIELD_MIN=0
# maximum field strength used for simulations
declare -i FIELD_MAX=20
# integer used to increment the field by between maximum and minimum
declare -i FIELD_INC=2
# minimum value used for density
declare -i ETA_MIN=5
# maximum value used for density
declare -i ETA_MAX=60
# integer amount to increment density by between maximum and minimum
declare -i ETA_INC=5
# minimum fraction of a-chirality squares used in simulations
declare -i ACHAI_MIN=50
# maximum fraction of a-chirality squares used in simulations
declare -i ACHAI_MAX=100
# integer amount to increment fraction of a-chirality squares by
# between the maxmimum and the minimum
declare -i ACHAI_INC=25
# number of times that each simulation is repeated
declare -i NUM_REPLICATES=3


## FUNCTIONS
# function that lists script usage and options to the CLT
help () {

	# TODO :: write options so that if a variable is specified, its value is held constant
	# if the job already exists, the script skips, unless and overwrite flag is specified

	echo -e "\nScript for generating conH jobs on CHTC systems.\nUSAGE: ./conH.sh << FLAGS >>\n"
	echo -e " -v           | execute script verbosely"
	echo -e " -o           | overwrite existing simulation files and directories corresponding to job"
	echo -e " -j << ARG >> | specify job title (default is ${JOB})"
	echo -e " -c << ARG >> | specify simulation cell size (default is ${CELL})"
}

# script for generating files for annealing simulations
gensim () {

	# TODO :: implement script for generating annealing simulations

}

## OPTIONS
# parse options
while getopts "voj:c:" option; do 
	case $option in
		v) # execute script verbosely
			
			# boolean that determines if the script should execute verbosely
			declare -i VERB_BOOL=1
			;;
		o) # overwrite existing simulation directories
			
			# boolean that determines if the script should
			# overwrite existing simulation data corresponding to job
			declare -i OVERWRITE_BOOL=1
			;;
		j) # specify the name of the job
			
			# parse the job name from the flag
			JOB="${OPTARG}"
			;;
		c) # specify the cell size 

			# parse the cell size from the flag
			declare -i CELL="${OPTARG}"
			;;
		\?) # default if illegal argument specified
			
			echo -e "\nIllegal argument ${option} specified.\n"
			help()
			exit $NONZERO_EXITCODE
	esac
done
shift $((OPTIND-1))


## ARGUMENTS
# none


## SCRIPT
# establish initial directories
D0=${JOB}
D1=${SIM_MOD}_${CELL}

# establish DAGMAN files
JOBID="${JOB}_${SIM_MOD}"
DAG="${JOBID}.dag"

# TODO :: incorperate dipole into simulation parameters

# loop through simulation parameters
# first parameters is the achirality fraction of squares
declare -i ACHAI=$ACHAI_MIN
while [[  ACHAI -le ACHAI_MAX ]]; do

	# establish the achirality directory
	ACHAI_STRING=${printf '%03d' ${ACHAI}}
	D2="a${ACHAI_STRING}"

	# second simulation parameters is the external field strength
	declare -i FIELD=$FIELD_MIN
	while [[ FIELD -le FIELD_MIN ]]; do

		# establish the field directory
		FIELD_STRING=${printf '%02d' ${FIELD}}
		D3="h${FIELD_STRING}"

		# third simulation parameter is the system density
		declare -i ETA=$ETA_MIN
		while [[ ETA -le ETA_MIN ]]; do 

			# establish the density directory
			ETA_STRING=${printf '%02d' ${ETA}}
			D4="e${ETA_STRING}"

			# establish directory path
			D="./${D0}/${D1}/${D2}/${D3}/${D4}/"

			# establish annealing simulation id
			ANNEALID="${D2}${D3}${D4}"
			SUBDAG="${ANNEALID}.spl"

			# generate simulation files
			gensim()

			# add annealing simulation to subdag
			echo "SPLICE ${ANNEALID} ${SUBDAG} DIR ${D}" >> $DAG

			# increment density
			((ETA+=ETA_INC))
		done

	# increment field string
	((FIELD+=FIELD_INC))
	done

# increment chirality
((ACHAI+=ACHAI_INC))
done
