# !/bin/bash
set -e 

## Matthew A. Dorsey
## 2023.11.14
## program for generating parameters for conH annealing simulations

## PARAMETERS
# header for simulation parameter file
HEADER="jobid,simid,H,ETA,XA,path"
# default number of replicates
declare -i REPLICATES=1
## FIELD STRENGTH PARAMETERS
# minimum field strength
declare -i FIELD_MIN=0
# maximum field strength
declare -i FIELD_MAX=20
# amount the external field strength is incremented by
declare -i FIELD_INC=1
## DENSITY PARAMETERS
# minimum density
declare -i ETA_MIN=5
# maximum density
declare -i ETA_MAX=60
# amount the system density is incremented by
declare -i ETA_INC=5
## A-CHIRALITY FRACTION PARAMETERS
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
# none


## ARGUMENTS
# none


## SCRIPT
# none