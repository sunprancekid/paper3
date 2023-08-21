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
# starting temperature of annealing simulation
ANNEAL_TEMP="3.0"
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
# default number of simulation events, unless specified by user
declare -i EVENTS=100000000
# default fraction used to decrease simulation temperature
declare -i FRAC=95
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
	echo -e " -e << ARG >> | specify simulation events (default is ${EVENTS})"
	echo -e " -f << ARG >> | specify annealing fraction (default is ${FRAC})"
}

# script for generating files for annealing simulations
gensimdir () {

	## PARAMETERS
	# list of sub directories to generate inside the main directory
	SUBDIR=( "anneal" "out" "sub" "sub/exec" "sub/fortran" "anal" "anneal/tmp" "anneal/save" "anneal/mov" "anneal/prop" "anneal/txt" )
	# list of fortran files that should be copied to the simulation directory
	FORTRAN_FILES=( "conH_init.f90" "conH_anneal.f90" "polsqu2x2_mod.f90" )


	## ARGUMENTS
	# none


	## SCRIPT
	# inform user
	if [[ VERB_BOOL -eq 1 ]]; then 
		echo -e "\nGenerating annealing simulation (${ANNEALID}) in: ${D}"
	fi

	# check if directory already exists
	declare -i GEN_DIR=0
	if [[ -d "${D}" ]]; then 
		# if the directory exists
		# check if the directory should be over written
		if [[ OVERWRITE_BOOL -eq 1 ]]; then 
			declare -i GEN_DIR=1
			rm -r "${D}"
			# inform user 
			if [[ VERB_BOOL -eq 1 ]]; then
				echo "Directory already exists. Overwriting .."
			fi
		else
			# inform the user
			if [[ VERB_BOOL -eq 1 ]]; then
				echo "Directory already exists."
			fi
		fi
	else
		# if the directory does not exist
		declare	-i GEN_DIR=1
		# inform the user
		if [[ VERB_BOOL -eq 1 ]]; then 
			echo "Generating directory .."
		fi
	fi
	# if it does not, generate subdirectories
	# or, if overwrite is true, delete the directory
	# re-generate everything
	if [[ GEN_DIR -eq 1 ]]; then
		mkdir -p $D

		# generate subdirectories
		for sd in "${SUBDIR[@]}"; do 
			mkdir -p "${D}${sd}/"
		done
	fi

	# add / write files to the directory
	# write the subdag to the directory

	# write files to directory
	# fortran files
	for ff in ${FORTRAN_FILES[@]}; do
		# copy each fortran file from the fortran bin to the simulation directory fortan repo
		cp "./simbin/fortran/${ff}" "${D}sub/fortran/"
	done
	# pre / post - script wrappers for annealing simulations
	cp ./simbin/bash/chtc/anneal_wrappers/* "${D}"
	# TODO :: add execution status to each script
	# initialize the subdag
	SUBDAG="${D}${SUBDAG}"
	if [[ -f "$SUBDAG" ]]; then 
		# if the file exists, remove it
		rm "$SUBDAG"
	fi
}

# script for generation the initialization conH node
# the initialization node accepts the simulation parameters
# as inputs, and establishes the save files which the annealing
# simulation will iterate
genCHTCinit() {

	## PARAMETERS
	# path to submission instructions
	SUB_PATH="${D}sub/init.sub"
	# name of the executable file
	EXEC_NAME="sub/exec/conH_init.sh"
	# name of the executable
	EXEC_PATH="${D}${EXEC_NAME}"
	# id for the simulation that the initialization node is being generated for
	SIM_ID="${JOBID}${ANNEALID}"

	## PARAMETERS - SIMULATION VARIABLES
	# area fraction value
	AF_VAL=$(printf '%3.2f' $(awk "BEGIN { print ${ETA} / 100 }"))
	# cell size value - related to the number of particles in the simulation
	CELL_VAL=${CELL}
	# a-chirality square number fraction
	ACHAI_VAL=$(printf '%3.2f' $(awk "BEGIN { print ${ACHAI} / 100 }"))
	# external field value
	FIELD_VAL=$(printf '%3.2f' $(awk "BEGIN { print ${FIELD} / 100 }"))
	# inital temperature assigned to simulation
	INIT_TEMP=$ANNEAL_TEMP
	# annealing fraction of simulation
	ANNEAL_FRAC=$(printf '%3.2f' $(awk "BEGIN { print ${FRAC} / 100 }"))

	## PARAMETERS - FILES
	# movie file
	SIM_MOV="${SIM_ID}_squmov.xyz"
	# text file
	SIM_TXT="${SIM_ID}.txt"
	# anneal file
	SIM_ANN="${SIM_ID}_anneal.csv"
	# annealing save file
	SIM_ANN_SAVE="${SIM_ID}__annealSAVE.dat"
	# chirality save file
	SIM_CHAI_SAVE="${SIM_ID}__chaiSAVE.dat"
	# false position save file
	SIM_FPOS_SAVE="${SIM_ID}__fposSAVE.dat"
	# velocity save file
	SIM_VEL_SAVE="${SIM_ID}__velSAVE.dat"
	# simulation setting sim file
	SIM_SIM_SAVE="${SIM_ID}__simSAVE.dat"

	## PARAMETERS - SUBMISSION INTRUCTIONS
	# memory to request
	REQUEST_MEMORY="500MB"
	# disk space to request
	REQUEST_DISK="1GB"
	# directory that output files are remapped to
	REMAP="anneal/init/"
	# list of files with remapping instructions
	RMP_SIM_MOV="${SIM_MOV}=${REMAP}${SIM_MOV}"
	RMP_SIM_TXT="${SIM_TXT}=${REMAP}${SIM_TXT}"
	RMP_SIM_ANN="${SIM_ANN}=${REMAP}${SIM_ANN}"
	RMP_SIM_ANN_SAVE="${SIM_ANN_SAVE}=${REMAP}${SIM_ANN_SAVE}"
	RMP_SIM_CHAI_SAVE="${SIM_CHAI_SAVE}=${REMAP}${SIM_CHAI_SAVE}"
	RMP_SIM_FPOS_SAVE="${SIM_FPOS_SAVE}=${REMAP}${SIM_FPOS_SAVE}"
	RMP_SIM_VEL_SAVE="${SIM_VEL_SAVE}=${REMAP}${SIM_VEL_SAVE}"
	RMP_SIM_SIM_SAVE="${SIM_ANN_SAVE}=${REMAP}${SIM_ANN_SAVE}"
	# list of files that should be transfered to the execute node
	TRANSFER_INPUT_FILES="sub/fortran/conH_init.f90, sub/fortran/polsqu2x2_mod.f90"
	# list of files that should be transfered from the execute node
	TRANSFER_OUTPUT_FILES="${SIM_MOV}, ${SIM_ANN_SAVE}, ${SIM_CHAI_SAVE}, ${SIM_FPOS_SAVE}, ${SIM_VEL_SAVE}, ${SIM_SIM_SAVE}"
	# list of remap instructions for each output file
	TRANSFER_OUTPUT_REMAPS="${RMP_SIM_MOV}; ${RMP_SIM_ANN_SAVE}; ${RMP_SIM_CHAI_SAVE}; ${RMP_SIM_FPOS_SAVE}; ${RMP_SIM_VEL_SAVE}; ${RMP_SIM_SIM_SAVE}"

	## PARAMETERS - EXECUTION INSTRUCTIONS
	# 


	## ARGUMENTS
	# none


	## SCRIPT
	# write submission script
	echo "executable = ${EXEC_NAME}" > $SUB_PATH
	echo "" >> $SUB_PATH
	echo "should_transfer_files = YES" >> $SUB_PATH
	echo "transfer_input_files = ${TRANSFER_INPUT_FILES}" >> $SUB_PATH
	echo "transfer_output_files = ${TRANSFER_OUTPUT_FILES}" >> $SUB_PATH
	echo "transfer_output_remaps = \"${TRANSFER_OUTPUT_REMAPS}\"" >> $SUB_PATH
	echo "when_to_transfer_output = ON_SUCCESS" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "log = out/init.log" >> $SUB_PATH
	echo "error = out/init.err" >> $SUB_PATH
	echo "output = out/init.out" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "request_cpus = 1" >> $SUB_PATH
	echo "request_disk = ${REQUEST_MEMORY}" >> $SUB_PATH
	echo "request_memory = ${REQUEST_MEMORY}" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "requirements = (HAS_GCC == true) && (Mips > 30000)" >> $SUB_PATH
	echo "+ProjectName=\"NCSU_Hall\"" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "queue" >> $SUB_PATH

	# write the execution scipt
	echo "# !/bin/bash" > $EXEC_PATH # shebang!!
	echo "set -e" >> $EXEC_PATH  # catch errors! 
	# compile module and program
	echo "gfortran -O -c polsqu2x2_mod.f90 conH_init.f90" >> $EXEC_PATH 
	# link module and program
	echo "gfortran -o conH_init.ex conH_init.o polsqu2x2_mod.o" >> $EXEC_PATH 
	# execute with arguments
	echo "./conH_init.ex ${JOBID} ${ANNEALID} ${AF_VAL} ${CELL_VAL} ${ACHAI_VAL} ${FIELD_VAL} ${INIT_TEMP} ${EVENTS} ${ANNEAL_FRAC}"  >> $EXEC_PATH 
	# add execution capabilities to script
	chmod u+x $EXEC_PATH

	# add node, pre- and post-script wrapper
	echo "SCRIPT PRE ${ANNEALID}_init prescript_wrapper.sh -i ${JOBID} ${ANNEALID}" >> $SUBDAG
	echo "JOB ${ANNEALID}_init ${SUB_PATH}" >> $SUBDAG
	echo "SCRIPT POST ${ANNEALID}_init postscript_wrapper.sh -i ${JOBID} ${ANNEALID} \$RETURN" >> $SUBDAG
}

## OPTIONS
# parse options
while getopts "voj:c:e:f:" option; do 
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

			# parse the cell size from the flag arguments
			declare -i CELL="${OPTARG}"
			;;
		e) # specify simulation events
			
			# parse the value from the flag arguments
			declare -i EVENTS="${OPTARG}"
			;;
		f) # specify annealing fraction
			
			# parse the value from the flag arguments
			declare -i FRAC="${OPTARG}"
			;;
		\?) # default if illegal argument specified
			
			echo -e "\nIllegal argument ${option} specified.\n"
			help
			exit $NONZERO_EXITCODE
	esac
done
shift $((OPTIND-1))


## ARGUMENTS
# none


## SCRIPT
# establish initial directories
D0=${JOB}
D1=${SIM_MOD}_c${CELL}

# establish DAGMAN files
JOBID="${JOB}_${SIM_MOD}"
DAG="${JOBID}.dag"
if [[ -f DAG ]]; then
	# if the file exists, remove it
	rm $DAG
fi

# TODO :: incorperate dipole into simulation parameters

# loop through simulation parameters
# first parameters is the achirality fraction of squares
declare -i ACHAI=$ACHAI_MIN
while [[  ACHAI -le ACHAI_MAX ]]; do

	# establish the achirality directory
	ACHAI_STRING=$(printf '%03d' ${ACHAI})
	D2="a${ACHAI_STRING}"

	# second simulation parameters is the external field strength
	declare -i FIELD=$FIELD_MIN
	while [[ FIELD -le FIELD_MAX ]]; do

		# establish the field directory
		FIELD_STRING=$(printf '%02d' ${FIELD})
		D3="h${FIELD_STRING}"

		# third simulation parameter is the system density
		declare -i ETA=$ETA_MIN
		while [[ ETA -le ETA_MAX ]]; do 

			# establish the density directory
			ETA_STRING=$(printf '%02d' ${ETA})
			D4="e${ETA_STRING}"

			# establish directory path
			D="./${D0}/${D1}/${D2}/${D3}/${D4}/"

			# establish annealing simulation id
			ANNEALID="${D2}${D3}${D4}"
			SUBDAG="${ANNEALID}.spl"

			# generate simulation directory and files
			gensimdir

			# establish initialization node
			genCHTCinit

			# establish rerun nodes
			# genCHTCrerun # add name of repeated function?

			# establish the final anneal node
			# genCHTCanneal

			# TODO :: establish analysis nodes

			# add annealing simulation instructions to the subdag
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

# submit job to CHTC
condor_submit_dag -maxidle 1000 -batch-name "${JOBID}" ${DAG} > ${JOBID}_dagsub.out
sleep 10
condor_watch_q
