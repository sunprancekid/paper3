# !/bin/bash
set -e

## Matthew Dorsey
## 2023.08.07
## script for generating conH jobs with polsqu2x2 module on CHTC linux systems


## PARAMETERS
# boolean that determines if the verbose flag was specified
declare -i VERB_BOOL=0
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
	echo -e " -j << ARG >> | specify job title (default is ${JOB})"
	echo -e " -c << ARG >> | specify simulation cell size (default is ${CELL})"
}


## OPTIONS
# none


## SCRIPT

# TODO :: establish DAGMAN files

# TODO :: establish directories
D0=${JOB}
D1=${SIM_MOD}_${CELL}

# TODO :: incorperate dipole into simulation parameters

# loop through simulation parameters
# first parameters is the achirality fraction of squares
declare -i ACHAI=$ACHAI_MIN
while [[  ACHAI -le ACHAI_MAX ]]; do

	# establish the achirality directory
	ACHAI_STRING=${printf '%03d' ${ACHAI}}
	D2="a${ACHAI_STRING}"

	# second simulation parameters is the external field strength
	declare -i FIELD=
done

