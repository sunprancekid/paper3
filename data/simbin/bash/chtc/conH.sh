# !/bin/bash
set -e

## Matthew Dorsey
## 2023.08.07
## script for generating conH jobs with polsqu2x2 module on CHTC linux systems


## PARAMETERS
## system instructions
# non-zero exit code that specifies that if error has occured during script execution
declare -i NONZERO_EXITCODE=120
# boolean that determines if the verbose flag was specified
declare -i VERB_BOOL=0
# boolean that determines if the the script should overwrite directories
# containing existing simulation files that correspond to job
declare -i OVERWRITE_BOOL=0
# boolean that determines if the job should be submited to CHTC
declare -i SUBMIT_BOOL=0
# boolean that determines if annealing simulations which have
# already been performed should be rerun
declare -i RERUN_BOOL=0
## system instructions - generating simulation parameters
# boolean determining if simulation directories / parameters should be written
declare -i GEN_BOOL=0
# boolean for generating A-chirality fraction simulation space
declare -i GEN_X_BOOL=0
# integer value associated with controlled A-chirality fraction isosurface
declare -i GEN_X_VAL=0
# boolean for generating external field strength iso-surface
declare -i GEN_H_BOOL=0
# integer value associated with controlling external field strength isosurface
declare -i GEN_H_VAL=0
# boolean for generating density iso-surface
declare -i GEN_D_BOOL=0
# integer value assoicated with controlling density iso-surface
declare -i GEN_D_VAL=0

## simulation parameters
# default job title, unless overwritten
JOB="conH"
# simulation module title
SIM_MOD="squ2"
# default simulation cell size, unless overwritten
declare -i CELL=32
# starting temperature of annealing simulation
INIT_ANNEAL_TEMP="3.0"
# final annealing temperature of an annealing simulation
FINAL_ANNEAL_TEMP="0.01"
# number of replicates to perform per simulation
declare -i NUM_REPLICATES=3
# default number of simulation events, unless specified by user
declare -i EVENTS=250000000
# default fraction used to decrease simulation temperature
declare -i FRAC=96
# TODO :: replicates are not actually implemented


## FUNCTIONS
# function that lists script usage and options to the CLT
help () {

	# TODO :: write options so that if a variable is specified, its value is held constant
	# if the job already exists, the script skips, unless and overwrite flag is specified

	echo -e "\nScript for generating conH jobs on CHTC systems.\nUSAGE: ./conH.sh << FLAGS >>\n"
	echo -e " -h           | display script options, exit 0."
	echo -e " -v           | execute script verbosely."
	echo -e " -g           | boolean determing if simulation parameters / directories should be generated."
	echo -e " -s           | submit job to CHTC based on current status."
	echo -e " -o           | boolean determining if existing jobs should be overwritten."
	echo -e "\n"
	echo -e " ## JOB PARAMETERS ##"
	echo -e " -j << ARG >> | specify job title (default is ${JOB})"
	echo -e " -c << ARG >> | specify cell size (default is ${CELL})"
	echo -e " -e << ARG >> | specify events per (default is ${EVENTS})"
	echo -e " -f << ARG >> | specify annealing fraction (default is ${FRAC})"
	echo -e "\n"
	echo -e " ## SIMULATION PARAMETERS ##"
	echo -e " -r << ARG >> | integer representing the number of replicates to perform (default is 1)."
	echo -e "\n"
	echo -e " ## CHTC SUBMIT INSTRUCTIONS ##"
	echo -e " -t           | \"touch\" simulation directries, update files."
	echo -e " -r           | rerun anneal simulations that have already been performed."
}

# script for generating files for annealing simulations
gensimdir () {

	## PARAMETERS
	# list of sub directories to generate inside the main directory
	SUBDIR=( "anneal" "out" "sub" "sub/exec" "sub/fortran" "anal" "anneal/tmp" )
	# list of fortran files that should be copied to the simulation directory
	FORTRAN_FILES=( "conH.f90" "polsqu2x2_mod.f90" )
	# name of the executable file
	EXEC_NAME="sub/exec/conH.sh"
	# name of the executable
	EXEC_PATH="${D}${EXEC_NAME}"

	## PARAMETERS - SIMULATION VARIABLES
	# area fraction value
	local AF_VAL=$ETA_VAL
	# cell size value - related to the number of particles in the simulation
	local CELL_VAL=${CELL}
	# a-chirality square number fraction
	local ACHAI_VAL=$XA_VAL
	# external field value
	local FIELD_VAL=$H_VAL
	# inital temperature assigned to simulation
	local INIT_TEMP=$INIT_ANNEAL_TEMP
	# annealing fraction of simulation
	local ANNEAL_FRAC=$(printf '%3.2f' $(awk "BEGIN { print ${FRAC} / 100 }"))


	## ARGUMENTS
	# none


	## SCRIPT
	# inform user
	if [[ VERB_BOOL -eq 1 ]]; then 
		echo -e "\nGenerating annealing simulation (${ANNEALID}) in: ${D}"
	fi

	# establish the subdag path
	SUBDAG_PATH="${D}${SUBDAG}"
	if [[ -f "$SUBDAG_PATH" ]]; then 
		# if the file exists, remove it
		rm "$SUBDAG_PATH"
	fi

	# check if directory already exists
	declare -i GEN_DIR=0
	if [[ -f "${D}/${SUBDAG}" ]]; then 
		# if the subdag exists, then the directory has been initialized
		# check if the directory should be over written
		if [[ OVERWRITE_BOOL -eq 1 ]]; then 
			declare -i GEN_DIR=1
			rm -r ${D}/* # empty the directory and restart
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
		# otherwise, if the subdag has not been created
		# then the directory has not been initialized
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

		# establish the initialization node
		genCHTCinit

		# establish the annealing loop node
		genCHTCanneal 1
	else

		# if the directory already exists, determine how many
		# time the anneal simulation has already been performed
		local -a dirs=( ${D}anneal/[0-9][0-9][0-9] )
		# printf 'Matching Directory: %s\n' "${dirs[@]}"
		declare -i N_ANNEAL=${#dirs[@]}
		((N_ANNEAL=N_ANNEAL-2))

		# determine the nodes to intialize based on the number of annealing
		# simulations that have been performed
		if [[ N_ANNEAL -le 0 ]];
		then
			# if no annealing simulations have been performed
			# establish the initial annealing
			echo "No annealing simulations have been performed"

			# perform the same routine, as if initializing the simulation
			# establish the initialization node
			genCHTCinit

			# establish the annealing loop node
			genCHTCanneal 1
		else
			# inform the user of the annealing simulations that
			# have been performed already
			echo "${N_ANNEAL} annealing simulations have already been performed."

			# if some annealing simulations have been performed
			# rerun all of the previous annealing simulations
			if [[ RERUN_BOOL -eq 1 ]]; then
				echo "Rerunning previous annealing nodes."
				for (( i=0; i<$N_ANNEAL; i++ ))
				do
					genCHTCanneal_rerun i
				done
			fi

			# establish the annealing loop
			genCHTCanneal 0

			# write the directory of the most recently run annealing
			# simulation to the tmp directory, for the annealing loop
			echo ${N_ANNEAL} > "${D}anneal/tmp/next_dir.txt"

			# exit 0

		fi
	fi

	## add / write files to the directory
	# copy fortran files to the directory
	for ff in ${FORTRAN_FILES[@]}; do
		# copy each fortran file from the fortran bin to the simulation directory fortan repo
		cp "./simbin/fortran/${ff}" "${D}sub/fortran/"
	done
	# copy pre / post - script wrappers for annealing simulations
	cp ./simbin/bash/chtc/anneal_wrappers/* "${D}"
	chmod u+x "${D}comp_temp.py" # add execution status to python script

	# write the executable to the simulation directory
	echo "# !/bin/bash" > $EXEC_PATH # shebang!!
	echo "set -e" >> $EXEC_PATH  # catch errors! 
	# compile module and program
	echo "gfortran -O -c polsqu2x2_mod.f90 conH.f90" >> $EXEC_PATH 
	# link module and program
	echo "gfortran -o conH.ex conH.o polsqu2x2_mod.o" >> $EXEC_PATH 
	# execute with arguments, first argument is the execute code
	echo "./conH.ex \$1 ${JOBID} ${ANNEALID} ${AF_VAL} ${CELL_VAL} ${ACHAI_VAL} ${FIELD_VAL} ${INIT_TEMP} ${EVENTS} ${ANNEAL_FRAC}"  >> $EXEC_PATH 
	# add execution capabilities to script
	chmod u+x $EXEC_PATH
}

# script for generation the initialization conH node
# the initialization node accepts the simulation parameters
# as inputs, and establishes the save files which the annealing
# simulation will iterate
genCHTCinit() {

	## PARAMETERS
	# name of file containing submission instructions
	local SUB_NAME="sub/init.sub"
	# path to file containing submission instructions
	local SUB_PATH="${D}${SUB_NAME}"
	# id for the simulation that the initialization node is being generated for
	local SIM_ID="${JOBID}${ANNEALID}"

	## PARAMETERS - FILES
	# movie file
	local SIM_MOV="${SIM_ID}_squmov.xyz"
	# text file
	local SIM_TXT="${SIM_ID}.txt"
	# anneal file
	local SIM_ANN="${SIM_ID}_anneal.csv"
	# annealing save file
	local SIM_ANN_SAVE="${SIM_ID}__annealSAVE.dat"
	# chirality save file
	local SIM_CHAI_SAVE="${SIM_ID}__chaiSAVE.dat"
	# false position save file
	local SIM_FPOS_SAVE="${SIM_ID}__fposSAVE.dat"
	# velocity save file
	local SIM_VEL_SAVE="${SIM_ID}__velSAVE.dat"
	# simulation setting sim file
	local SIM_SIM_SAVE="${SIM_ID}__simSAVE.dat"

	## PARAMETERS - SUBMISSION INTRUCTIONS
	# memory to request
	local REQUEST_MEMORY="500MB"
	# disk space to request
	local REQUEST_DISK="1GB"
	# directory that output files are remapped to
	local REMAP="anneal/init/"
	# list of files with remapping instructions
	local RMP_SIM_MOV="${SIM_MOV}=${REMAP}${SIM_MOV}"
	local RMP_SIM_TXT="${SIM_TXT}=${REMAP}${SIM_TXT}"
	local RMP_SIM_ANN="${SIM_ANN}=${REMAP}${SIM_ANN}"
	local RMP_SIM_ANN_SAVE="${SIM_ANN_SAVE}=${REMAP}${SIM_ANN_SAVE}"
	local RMP_SIM_CHAI_SAVE="${SIM_CHAI_SAVE}=${REMAP}${SIM_CHAI_SAVE}"
	local RMP_SIM_FPOS_SAVE="${SIM_FPOS_SAVE}=${REMAP}${SIM_FPOS_SAVE}"
	local RMP_SIM_VEL_SAVE="${SIM_VEL_SAVE}=${REMAP}${SIM_VEL_SAVE}"
	local RMP_SIM_SIM_SAVE="${SIM_SIM_SAVE}=${REMAP}${SIM_SIM_SAVE}"
	# list of files that should be transfered to the execute node
	local TRANSFER_INPUT_FILES="sub/fortran/conH.f90, sub/fortran/polsqu2x2_mod.f90"
	# list of files that should be transfered from the execute node
	local TRANSFER_OUTPUT_FILES="${SIM_MOV}, ${SIM_ANN_SAVE}, ${SIM_CHAI_SAVE}, ${SIM_FPOS_SAVE}, ${SIM_VEL_SAVE}, ${SIM_SIM_SAVE}"
	# list of remap instructions for each output file
	local TRANSFER_OUTPUT_REMAPS="${RMP_SIM_MOV}; ${RMP_SIM_ANN_SAVE}; ${RMP_SIM_CHAI_SAVE}; ${RMP_SIM_FPOS_SAVE}; ${RMP_SIM_VEL_SAVE}; ${RMP_SIM_SIM_SAVE}"

	## PARAMETERS - EXECUTION INSTRUCTIONS
	# none


	## ARGUMENTS
	# none


	## SCRIPT
	# if verbose, inform the user
	if [[ VERB_BOOL -eq 1 ]]; then 
		echo "Establishing initialization node for annealing simulation (${ANNEALID})."
	fi

	# write submission script
	echo "executable = ${EXEC_NAME}" > $SUB_PATH
	echo "arguments = 0" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "+SingularityImage = \"/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-ubuntu-20.04:latest\"" >> $SUB_PATH
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
	echo "request_disk = ${REQUEST_DISK}" >> $SUB_PATH
	echo "request_memory = ${REQUEST_MEMORY}" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "on_exit_hold = (ExitCode != 0)" >> $SUB_PATH
	echo "requirements = (HAS_GCC == true) && (Mips > 30000)" >> $SUB_PATH
	# echo "requirements = HasSingularity" >> $SUB_PATH
	echo "+ProjectName=\"NCSU_Hall\"" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "queue" >> $SUB_PATH

	# add node, pre- and post-script wrapper
	echo "JOB ${ANNEALID}_init ${SUB_NAME}" >> $SUBDAG_PATH
	echo "SCRIPT PRE ${ANNEALID}_init prescript-wrapper.sh -i ${JOBID} ${ANNEALID}" >> $SUBDAG_PATH
	echo "SCRIPT POST ${ANNEALID}_init postscript-wrapper.sh -i ${JOBID} ${ANNEALID} \$RETURN \$RETRY" >> $SUBDAG_PATH
}

# script for generating annealing nodes
# the annealing node accepts the save files from the previous
# annealing simulation, and uses them to continue the annealing 
# simulation from the place the it stopped according to the save files
genCHTCanneal() {

	## PARAMETERS
	# boolean used to determine if the annealing node should have a 
	# parent child relationship with the initialization node
	declare -i INIT_BOOL=$1
	# name of file containing submission instructions
	local SUB_NAME="sub/anneal.sub"
	# path to file containing submission instructions
	local SUB_PATH="${D}${SUB_NAME}"
	# name of the executable file
	local EXEC_NAME="sub/exec/conH.sh"
	# name of the executable
	local EXEC_PATH="${D}${EXEC_NAME}"
	# id for the simulation that the initialization node is being generated for
	local SIM_ID="${JOBID}${ANNEALID}"

	## PARAMETERS - FILES
	# movie file
	local SIM_MOV="${SIM_ID}_squmov.xyz"
	# text file
	local SIM_TXT="${SIM_ID}.txt"
	# anneal file
	local SIM_ANN="${SIM_ID}_anneal.csv"
	# annealing save file
	local SIM_ANN_SAVE="${SIM_ID}__annealSAVE.dat"
	# chirality save file
	local SIM_CHAI_SAVE="${SIM_ID}__chaiSAVE.dat"
	# false position save file
	local SIM_FPOS_SAVE="${SIM_ID}__fposSAVE.dat"
	# velocity save file
	local SIM_VEL_SAVE="${SIM_ID}__velSAVE.dat"
	# simulation setting sim file
	local SIM_SIM_SAVE="${SIM_ID}__simSAVE.dat"

	## PARAMETERS - MAPPING TO INPUT FILES
	# memory to request
	local REQUEST_MEMORY="500MB"
	# disk space to request
	local REQUEST_DISK="1GB"
	# directory that output files are remapped to
	local REMAP="anneal/tmp/"
	# list of files with path to the input directory
	local INPT_SIM_ANN_SAVE="${REMAP}${SIM_ANN_SAVE}"
	local INPT_SIM_CHAI_SAVE="${REMAP}${SIM_CHAI_SAVE}"
	local INPT_SIM_FPOS_SAVE="${REMAP}${SIM_FPOS_SAVE}"
	local INPT_SIM_VEL_SAVE="${REMAP}${SIM_VEL_SAVE}"
	local INPT_SIM_SIM_SAVE="${REMAP}${SIM_SIM_SAVE}"
	# list of files with remapping instructions
	local RMP_SIM_MOV="${SIM_MOV}=${REMAP}${SIM_MOV}"
	local RMP_SIM_TXT="${SIM_TXT}=${REMAP}${SIM_TXT}"
	local RMP_SIM_ANN="${SIM_ANN}=${REMAP}${SIM_ANN}"
	local RMP_SIM_ANN_SAVE="${SIM_ANN_SAVE}=${REMAP}${SIM_ANN_SAVE}"
	local RMP_SIM_CHAI_SAVE="${SIM_CHAI_SAVE}=${REMAP}${SIM_CHAI_SAVE}"
	local RMP_SIM_FPOS_SAVE="${SIM_FPOS_SAVE}=${REMAP}${SIM_FPOS_SAVE}"
	local RMP_SIM_VEL_SAVE="${SIM_VEL_SAVE}=${REMAP}${SIM_VEL_SAVE}"
	local RMP_SIM_SIM_SAVE="${SIM_SIM_SAVE}=${REMAP}${SIM_SIM_SAVE}"
	# list of files that should be transfered to the execute node
	local TRANSFER_INPUT_FILES="sub/fortran/conH.f90, sub/fortran/polsqu2x2_mod.f90, ${INPT_SIM_ANN_SAVE}, ${INPT_SIM_SIM_SAVE}, ${INPT_SIM_VEL_SAVE}, ${INPT_SIM_CHAI_SAVE}, ${INPT_SIM_FPOS_SAVE}"
	# list of files that should be transfered from the execute node
	local TRANSFER_OUTPUT_FILES="${SIM_MOV}, ${SIM_ANN}, ${SIM_TXT}, ${SIM_ANN_SAVE}, ${SIM_CHAI_SAVE}, ${SIM_FPOS_SAVE}, ${SIM_VEL_SAVE}, ${SIM_SIM_SAVE}"
	# list of remap instructions for each output file
	local TRANSFER_OUTPUT_REMAPS="${RMP_SIM_MOV}; ${RMP_SIM_ANN}; ${RMP_SIM_TXT}; ${RMP_SIM_ANN_SAVE}; ${RMP_SIM_CHAI_SAVE}; ${RMP_SIM_FPOS_SAVE}; ${RMP_SIM_VEL_SAVE}; ${RMP_SIM_SIM_SAVE}"


	## OPTIONS
	# none


	## ARGUMENTS
	# none

	## SCRIPT
	# if verbose, inform the user
	if [[ VERB_BOOL -eq 1 ]]; then 
		echo "Establishing looping anneal node for annealing simulation (${ANNEALID})."
	fi

	# write submission script
	echo "executable = ${EXEC_NAME}" > $SUB_PATH
	echo "arguments = 1" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "+SingularityImage = \"/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-ubuntu-20.04:latest\"" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "should_transfer_files = YES" >> $SUB_PATH
	echo "transfer_input_files = ${TRANSFER_INPUT_FILES}" >> $SUB_PATH
	echo "transfer_output_files = ${TRANSFER_OUTPUT_FILES}" >> $SUB_PATH
	echo "transfer_output_remaps = \"${TRANSFER_OUTPUT_REMAPS}\"" >> $SUB_PATH
	echo "when_to_transfer_output = ON_SUCCESS" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "log = out/anneal.log" >> $SUB_PATH
	echo "error = out/anneal.err" >> $SUB_PATH
	echo "output = out/anneal.out" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "request_cpus = 1" >> $SUB_PATH
	echo "request_disk = ${REQUEST_DISK}" >> $SUB_PATH
	echo "request_memory = ${REQUEST_MEMORY}" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "on_exit_hold = (ExitCode != 0)" >> $SUB_PATH
	# echo "max_retries = 5" >> $SUB_PATH
	# echo "requirements = HasSingularity" >> $SUB_PATH
	echo "requirements = (HAS_GCC == true) && (Mips > 30000)" >> $SUB_PATH
	echo "+ProjectName=\"NCSU_Hall\"" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "queue" >> $SUB_PATH

	# add node, pre- and post-script wrapper
	echo "JOB ${ANNEALID}_anneal ${SUB_NAME}" >> $SUBDAG_PATH
	echo "RETRY ${ANNEALID}_anneal 1000" >> $SUBDAG_PATH
	if [[ INIT_BOOL -eq 1 ]]; then 
		echo "PARENT ${ANNEALID}_init CHILD ${ANNEALID}_anneal" >> $SUBDAG_PATH
	fi
	echo "SCRIPT PRE ${ANNEALID}_anneal prescript-wrapper.sh -a ${JOBID} ${ANNEALID}" >> $SUBDAG_PATH
	echo "SCRIPT POST ${ANNEALID}_anneal postscript-wrapper.sh -a ${FINAL_ANNEAL_TEMP} ${JOBID} ${ANNEALID} \$RETURN \$RETRY" >> $SUBDAG_PATH
}

# script for generating annealing nodes that should be rerun
# the rerun node loads the save files from the previous simulation,
# and continues running the simulation from the save point of those 
# files. Once the simulations are finished running, the files are 
# are save to the temporary directory with an integer corresponding
# for the integer of the annealing simulation, and the postscript-
# wrapper moves them to appropraite anneal directory once the node
# has completely finished running
genCHTCanneal_rerun () {

	## ARGUMENTS
	# integer corresponding to the iteration of the annealing simulation that
	# is being rerun
	declare -i RERUN_IT=$1

	## PARAMETERS
	# directory corresponding to the current iteration of the annealing simulation
	CURR_DIR=$(printf '%03d' ${RERUN_IT})
	CURR_DIR="${CURR_DIR}"
	# directory corresponding to the previous simulations that should be
	# loaded for the current iteration of the annealing simulation
	if [[ RERUN_IT -eq 0 ]]; then
		# if the first iteraction of the annealing simulation is 
		# being rerun, then the save files in the initial directory
		# should be rerun
		PREV_DIR="init"
	else
		# otherwise, the directory to load the save files from is the directory
		# whose integer is one less than the current directory
		declare -i PREV_INT=0
		((PREV_INT=RERUN_IT-1))
		PREV_DIR=$(printf '%03d' ${PREV_INT})
		PREV_DIR="${PREV_DIR}"
	fi
	# name of file containing submission instructions
	local SUB_NAME="sub/anneal${CURR_DIR}.sub"
	# path to file containing submission instructions
	local SUB_PATH="${D}${SUB_NAME}"
	# name of the executable file
	local EXEC_NAME="sub/exec/conH.sh"
	# name of the executable
	local EXEC_PATH="${D}${EXEC_NAME}"
	# id for the simulation that the initialization node is being generated for
	local SIM_ID="${JOBID}${ANNEALID}"

	## PARAMETERS - FILES
	# movie file
	local SIM_MOV="${SIM_ID}_squmov.xyz"
	# text file
	local SIM_TXT="${SIM_ID}.txt"
	# anneal file
	local SIM_ANN="${SIM_ID}_anneal.csv"
	# order parameter file
	# TODO :: add remaping for order parameters calculated during simulation
	# annealing save file
	local SIM_ANN_SAVE="${SIM_ID}__annealSAVE.dat"
	# chirality save file
	local SIM_CHAI_SAVE="${SIM_ID}__chaiSAVE.dat"
	# false position save file
	local SIM_FPOS_SAVE="${SIM_ID}__fposSAVE.dat"
	# velocity save file
	local SIM_VEL_SAVE="${SIM_ID}__velSAVE.dat"
	# simulation setting sim file
	local SIM_SIM_SAVE="${SIM_ID}__simSAVE.dat"

	## PARAMETERS - MAPPING TO INPUT FILES
	# memory to request
	local REQUEST_MEMORY="500MB"
	# disk space to request
	local REQUEST_DISK="1GB"
	# directory that input files are loaded from
	local REMAP_INPUT="anneal/${PREV_DIR}/"
	# directory that the output files are saved to for postscript processing
	local REMAP_OUTPUT="temp/${CURR_DIR}/"
	# list of files with path to the input directory
	local INPT_SIM_ANN_SAVE="${REMAP_INPUT}${SIM_ANN_SAVE}"
	local INPT_SIM_CHAI_SAVE="${REMAP_INPUT}${SIM_CHAI_SAVE}"
	local INPT_SIM_FPOS_SAVE="${REMAP_INPUT}${SIM_FPOS_SAVE}"
	local INPT_SIM_VEL_SAVE="${REMAP_INPUT}${SIM_VEL_SAVE}"
	local INPT_SIM_SIM_SAVE="${REMAP_INPUT}${SIM_SIM_SAVE}"
	# list of files with remapping instructions
	local RMP_SIM_MOV="${SIM_MOV}=${REMAP_OUTPUT}${SIM_MOV}"
	local RMP_SIM_TXT="${SIM_TXT}=${REMAP_OUTPUT}${SIM_TXT}"
	local RMP_SIM_ANN="${SIM_ANN}=${REMAP_OUTPUT}${SIM_ANN}"
	local RMP_SIM_ANN_SAVE="${SIM_ANN_SAVE}=${REMAP_OUTPUT}${SIM_ANN_SAVE}"
	local RMP_SIM_CHAI_SAVE="${SIM_CHAI_SAVE}=${REMAP_OUTPUT}${SIM_CHAI_SAVE}"
	local RMP_SIM_FPOS_SAVE="${SIM_FPOS_SAVE}=${REMAP_OUTPUT}${SIM_FPOS_SAVE}"
	local RMP_SIM_VEL_SAVE="${SIM_VEL_SAVE}=${REMAP_OUTPUT}${SIM_VEL_SAVE}"
	local RMP_SIM_SIM_SAVE="${SIM_SIM_SAVE}=${REMAP_OUTPUT}${SIM_SIM_SAVE}"
	# list of files that should be transfered to the execute node
	local TRANSFER_INPUT_FILES="sub/fortran/conH.f90, sub/fortran/polsqu2x2_mod.f90, ${INPT_SIM_ANN_SAVE}, ${INPT_SIM_SIM_SAVE}, ${INPT_SIM_VEL_SAVE}, ${INPT_SIM_CHAI_SAVE}, ${INPT_SIM_FPOS_SAVE}"
	# list of files that should be transfered from the execute node
	local TRANSFER_OUTPUT_FILES="${SIM_MOV}, ${SIM_ANN}, ${SIM_TXT}, ${SIM_ANN_SAVE}, ${SIM_CHAI_SAVE}, ${SIM_FPOS_SAVE}, ${SIM_VEL_SAVE}, ${SIM_SIM_SAVE}"
	# list of remap instructions for each output file
	local TRANSFER_OUTPUT_REMAPS="${RMP_SIM_MOV}; ${RMP_SIM_ANN}; ${RMP_SIM_TXT}; ${RMP_SIM_ANN_SAVE}; ${RMP_SIM_CHAI_SAVE}; ${RMP_SIM_FPOS_SAVE}; ${RMP_SIM_VEL_SAVE}; ${RMP_SIM_SIM_SAVE}"


	## OPTIONS
	# none

	echo "The CURRENT DIRECTORY is (${CURR_DIR}) and the PREVIOUS DIRECTORY is (${PREV_DIR})."
	return

	## SCRIPT
	# if verbose, inform the user
	if [[ VERB_BOOL -eq 1 ]]; then 
		echo "Establishing looping anneal node for annealing simulation (${ANNEALID})."
	fi

	# write submission script
	echo "executable = ${EXEC_NAME}" > $SUB_PATH
	echo "arguments = 1" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "+SingularityImage = \"/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-ubuntu-20.04:latest\"" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "should_transfer_files = YES" >> $SUB_PATH
	echo "transfer_input_files = ${TRANSFER_INPUT_FILES}" >> $SUB_PATH
	echo "transfer_output_files = ${TRANSFER_OUTPUT_FILES}" >> $SUB_PATH
	echo "transfer_output_remaps = \"${TRANSFER_OUTPUT_REMAPS}\"" >> $SUB_PATH
	echo "when_to_transfer_output = ON_SUCCESS" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "log = out/anneal.log" >> $SUB_PATH
	echo "error = out/anneal.err" >> $SUB_PATH
	echo "output = out/anneal.out" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "request_cpus = 1" >> $SUB_PATH
	echo "request_disk = ${REQUEST_DISK}" >> $SUB_PATH
	echo "request_memory = ${REQUEST_MEMORY}" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "on_exit_hold = (ExitCode != 0)" >> $SUB_PATH
	# echo "requirements = HasSingularity" >> $SUB_PATH
	echo "requirements = (HAS_GCC == true) && (Mips > 30000)" >> $SUB_PATH
	echo "+ProjectName=\"NCSU_Hall\"" >> $SUB_PATH
	echo "" >> $SUB_PATH
	echo "queue" >> $SUB_PATH

	# add node, pre- and post-script wrapper
	echo "JOB ${ANNEALID}_anneal${CURR_DIR} ${SUB_NAME}" >> $SUBDAG_PATH
	echo "RETRY ${ANNEALID}_anneal${CURR_DIR} 2" >> $SUBDAG_PATH
	echo "SCRIPT PRE ${ANNEALID}_anneal prescript-wrapper.sh -r ${RERUN_IT} ${JOBID} ${ANNEALID}" >> $SUBDAG_PATH
	echo "SCRIPT POST ${ANNEALID}_anneal postscript-wrapper.sh -r ${RERUN_IT} ${JOBID} ${ANNEALID} \$RETURN \$RETRY" >> $SUBDAG_PATH
}

## OPTIONS
# parse options
while getopts "hvosrj:c:e:f:gx:h:p:" option; do 
	case $option in
		v) # execute script verbosely
			
			# boolean that determines if the script should execute verbosely
			declare -i VERB_BOOL=1
			;;
		o) # overwrite existing simulation directories
			
			# boolean that determines if the script should
			# overwrite existing simulation data corresponding to job
			declare -i OVERWRITE_BOOL=0
			# declare -i OVERWRITE_BOOL=1
			;;
		g) # generate simulation directories / parameters 
			
			# boolean for generating simulation directories / parameters
			declare -i GEN_BOOL=1
			;;
		s) # submit job to CHTC 

			# boolean that determines if the script should submit the job to CHTC
			declare -i SUBMIT_BOOL=1
			;;
		r) # rerun annealing simulations that have already been completed

			# boolean that determines if annealing simulations that have 
			# already been performed should be rerun
			declare -i RERUN_BOOL=1
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
		h) # inform user of script flag options
			help
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
# establish initial directories, file names
SIMID=${SIM_MOD}_c${CELL}
D0=${JOB}/${SIMID}
JOBID=${JOB}_${SIMID}
# name of file containing simulation parameters
SIMPARAM_FILE=${D0}/${JOBID}.csv
# establish DAGMAN files
DAG="${JOBID}.dag"
if [[ -f "${DAG}" ]]; then
	# if the file exists, remove it
	rm $DAG
fi


## generate data, if specified
if [[ GEN_BOOL -eq 1 ]]; then

	# TODO :: incorperate dipole into simulation parameters
	if [[ VERB_BOOL -eq 1 ]]; then 
		echo -e "\nconH :: Generating simulation parameters."
	fi
	# generate specified simulation parameters
	./simbin/bash/chtc/conH_simparam.sh -x 50 -r $NUM_REPLICATES $JOB $SIMID
	./simbin/bash/chtc/conH_simparam.sh -x 75 -r $NUM_REPLICATES $JOB $SIMID
	./simbin/bash/chtc/conH_simparam.sh -x 100 -r $NUM_REPLICATES $JOB $SIMID
fi 

# write parameters to file. if the directories already exist,
# then they should already by in the file

## start / restart simulations
if [[ VERB_BOOL -eq 1 ]]; then
	echo -e "\nconH :: Parsing simulation parameters."
fi
# load data from csv
# get the number of lines in the sim parameter directory
declare -i N_LINES=$(./simbin/bash/util/parse_csv.sh -l -f ${SIMPARAM_FILE})
# loop through each line in file
# parse simulation parameters
declare -i LINE=2 # first line is the header
while [[ LINE -le N_LINES ]]
do

	# parse the simulation data
	# simulation parameters
	SIMPARM="$( head -n ${LINE} ${SIMPARAM_FILE} | tail -n 1 )"

	# parse the simulation parameters from the line
	D="$(echo ${SIMPARM} | cut -d , -f 7 )/" # path to the simulation directory
	ANNEALID="$(echo ${SIMPARM} | cut -d , -f 2 )"
	XA_VAL="$(echo ${SIMPARM} | cut -d , -f 3 )"
	H_VAL="$(echo ${SIMPARM} | cut -d , -f 4 )"
	ETA_VAL="$(echo ${SIMPARM} | cut -d , -f 5 )"

	# establish annealing simulation id
	SUBDAG="${ANNEALID}.spl"

	# generate simulation directory and files
	gensimdir

	# add annealing simulation instructions to the subdag
	echo "SPLICE ${ANNEALID} ${SUBDAG} DIR ${D}" >> $DAG

	# increment the line number and repeat
	((LINE+=1))

	# TODO :: establish analysis nodes
done

exit 0

# submit job to CHTC
if [[ SUBMIT_BOOL -eq 1 ]]; then
	condor_submit_dag -batch-name "${JOBID}" ${DAG} > ${JOBID}_dagsub.out
	sleep 10
	condor_watch_q
fi
