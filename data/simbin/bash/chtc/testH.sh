# !/bin/bash
set -e

# Matthew Dorsey
# 2023-07-25
# script that generates testH job for polarized squares


## EXECUTION PARAMETERS
# none zero exit code
declare -i NONZERO_EXITCODE=1
# boolean that determines if script should execute verbosely
declare -i VERB_BOOL=0
# boolean that determines if the script should generate simlations
# for execution on chtc node
declare -i GEN_BOOL=0
# boolean that determines if the script should analyze results 
# from generated from simulations
declare -i ANAL_BOOL=0
# integer that specifies how the simulations should be generated
# for execution on chtc nodes
declare -i EXEC_CODE=0

## SIMULATION PARAMETERS
# default job name
JOB="testH"
# default model used for simulations
MODEL="squ2"
# default cell size of simulation
declare -i CELL=16
# default simulation area fraction
declare -i AREA_FRACTION=5
# default area fraction of simulation
declare -i ETA=20
# default number of simulation events
declare -i EVENTS=200000000
# minimum temperature set point for simulations
declare -i TEMP_MIN=025
# maximum temperature set point
declare -i TEMP_MAX=150
# amount to INCREMENT the temperature set point by
declare -i TEMP_INC=1
# minimum velocity magnitude
declare -i VMAG_MIN=025
# maximum velocity magnitude
declare -i VMAG_MAX=030
# amount to INCREMENT the velcoity magnitude by
declare -i VMAG_INC=10
# minimum field frequency
declare -i FFRQ_MIN=10
# maximum field frequency
declare -i FFRQ_MAX=600
# amount to DECREMENT the field frequency by
declare -i FFRQ_INC=5
# number of times to replicate each experiment
declare -i REPLICATE=5
# file containing simulation parameters
SIMPARAM="${JOB}.csv"


## OPTIONS
while getopts "ae:gv" options; do 
	case $options in 
		a) # analyze results from simulations
			

			# boolean that determines if the script should analyze results 
			# from generated from simulations
			declare -i ANAL_BOOL=1

			;;
		e) # specify integer that determines how the script should execute
			
			# parse the integer
			declare -i EXEC_CODE=${OPTARG}

			# check that the value passed to the program is within the bounds
			if [[ $EXEC_CODE -lt 0 || $EXEC_CODE -gt 2 ]]; then
				echo -e "Incorrect execution code passed to script (${EXEC_CODE})."
				exit $NONZERO_EXITCODE
			fi
			;;
		g) # generate simulations on CHTC node
			
			# boolean that determines if the script should generate simlations
			# for execution on chtc node
			declare -i GEN_BOOL=1

			;;
		v) # execute the script verbosely
			
			# boolean that determines if the script should
			# be executed verbosely
			declare -i VERB_BOOL=1 ;;
		\?) # default if incorrect options are specified
			
			# inform user of the correct options
			echo -e "\nIncorrect options specified."
			echo -e "-e :: specify integer that determines script execution."
			echo -e "-v :: execute script verbosely.\n"

			exit $NONZERO_EXITCODE ;;
    esac
done
shift $((OPTIND-1))


## ARGUMENTS
# none


## FUNCTIONS
# function that generates directories for CHTC simulations
gendirs () {

	## PARAMETERS
	# none


	## OPTIONS
	# none


	## ARGUMENTS
	# none


	## SCRIPT

	# inform user
	if [[ VERB_BOOL -eq 1 ]] ; then
		echo "generating directories in ${D}"
	fi

	# generate directories
	./simbin/bash/gendir.sh -d ${D} -s /out -v -o # contains output files from CHTC execute node
	./simbin/bash/gendir.sh -d ${D} -s /txt -v -o # contains text files from simulation
	./simbin/bash/gendir.sh -d ${D} -s /anneal -v -o # contains anneal files from simulation
	./simbin/bash/gendir.sh -d ${D} -s /fortran -v -o # contains fortran files for simulations
}

# function that generates simulation programs
gensim () {

	# TODO :: compile program with make and copy to main dir

	## PARAMETERS
	# path to main fortran directory
	FORTRAN_DIR="./simbin/fortran/"
	# list of fortran files to copy from the simbin
	FORTRAN_FILES=( "testH.f90" "polsqu2x2_mod.f90" )
	# path to simulation directory
	SIM_FORT_DIR="${D}/fortran/"
	# name of executable for CHTC execute node
	EXECUTE="${D}/${JOB}.sh"
	# gfortran compiler execution
	GFORT="gfortran"
	# flags for gfortran compiler
	GFORT_FLAG="-O"
	# ifort compiler execution + flags
	IFORT="ifort -no-wrap-margin -O3 -fp-model=precise"


	# OPTIONS
	# none


	## ARGUMENTS 
	# none


	# SCRIPT

	# add each file to the fortran directory
	for F in ${FORTRAN_FILES[@]}; do

		# inform user
		if [[ VERB_BOOL -eq 1 ]]; then 
			echo "copying ${F} from ${FORTRAN_DIR} to ${SIM_FORT_DIR}."
		fi

		# copy file
		cp ${FORTRAN_DIR}${F} ${SIM_FORT_DIR}
	done

	# write CHTC executable to the simulation directory
	echo "#!/bin/bash" > $EXECUTE # shebang!!
	echo "set -e" >> $EXECUTE # catch errors!!
	echo "${GFORT} ${GFORT_FLAG} -c polsqu2x2_mod.f90 testH.f90" >> $EXECUTE
	echo "${GFORT} -o testH.ex testH.o polsqu2x2_mod.o" >> $EXECUTE
	echo "./testH.ex \$1 \$2 \$3 \$4 \$5 \$6" >> $EXECUTE
	chmod u+x ${EXECUTE}
}

# function that generates submit script for CHTC workflow
genCHTCsub () {

	## PARAMETERS
	# name of simulation files generated with default polsqu module
	simname="testH\$(simid)"
	# list of files that are transfered to the execute node
	local transin="fortran/polsqu2x2_mod.f90, fortran/testH.f90"
	# list of files that are transfered from the execute node
	local transout="${simname}.txt, ${simname}_anneal.csv"
	# list of remap instructions for files transfered from execute node
	local transoutremap="${simname}.txt=txt/\$(simid).txt; ${simname}_anneal.csv=anneal/\$(simid)_anneal.csv"
	# name of the CHTC submission file
	# local sub="${D}/${JOB}.sub"

	## OPTIONS
	# none

	## ARGUMENTS
	# first argument: name of file containing CHTC submission instructions
	local sub="${D}/${1}.sub"

	## SCRIPT
	# inform user
	if [[ VERB_BOOL -eq 1 ]]; then 
		echo "generation submision script ${sub}."
	fi

	# write submission instructions to submit file
	echo "executable = ${JOB}.sh" > $sub
	echo "arguments = \$(area_frac) \$(events) \$(cell) \$(T) \$(X) \$(simid)" >> $sub 
	echo "" >> $sub 
	echo "should_transfer_files = YES" >> $sub
	echo "transfer_input_files = ${transin}" >> $sub
	echo "transfer_output_files = ${transout}" >> $sub
	echo "transfer_output_remaps = \"${transoutremap}\"" >> $sub
	echo "when_to_transfer_output = ON_SUCCESS" >> $sub 
	echo "" >> $sub
	echo "max_idle = 10000" >> $sub
	echo "on_exit_hold = (ExitBySignal == True) || (ExitCode != 0)" >> $sub 
	#echo "max_retries = 5" >> $sub
	echo "" >> $sub
	echo "log = out/${JOB}.log" >> $sub 
	echo "output = out/\$(simid).out" >> $sub
	echo "error = out/\$(simid).err" >> $sub
	#echo "stream_error = True" >> $sub # FOR DEBUGGING
	#echo "stream_output = True" >> $sub # FOR DUBUGGING 
	echo "" >> $sub
	echo "request_cpus = 1" >> $sub
	echo "request_disk = 1GB" >> $sub
	echo "request_memory = 500MB" >> $sub
	echo "" >> $sub
	echo "requirements = (HAS_GCC == true) && (Mips > 30000)" >> $sub
	echo "+ProjectName=\"NCSU_Hall\"" >> $sub
	echo "" >> $sub
	echo "queue simid,area_frac,cell,events,rp,T,X from ${SIMPARAM}" >> $sub
}

# function that generates simulation parameters for CHTC simulations
gensimparam () {

	## PARAMETERS
	# path to script that generates scripts
	local SIMP="./simbin/bash/chtc/testH_simparam.sh"

	## OPTIONS
	# none

	## ARGUMENTS
	# none

	## SCRIPT
	# compile flags for script execution
	local flags=""
	# execture verbosely
	if [[ $VERB_BOOL -eq 1 ]]; then
		flags="${flags} -v"
	fi
	# path to file and file name
	flags="${flags} -p ${D}/ -f ${JOB}.csv"
	# simulation parameters
	flags="${flags} -c ${CELL} -e ${EVENTS} -a ${AREA_FRACTION}"
	# testH parameters
	flags="${flags} -x 500 -i 5 -r ${REPLICATE}"

	# loop through each temperature
	declare -i T=25
	while [[ $T -le 100 ]]; do
		# call script with flags
		$SIMP $flags -t $T
		# increment temperature and repeat
		((T+=5))
	done
}

## SCRIPT
## TODO add parameter for job type
## generate directories
# zeroth and first directories that store simulation files
D0="${JOB}"
D1="${MODEL}c${CELL}"
D2="e$(printf '%02d' ${AREA_FRACTION})"
# generate directories for testH simulations
D="${D0}/${D1}/${D2}/TX" # directory containing simulation files

# job id is job name plus model and size of simulation system
JOBID="${JOB}_${D1}${D2}_TX"


# generate DAG file
DAG="${JOBID}.dag"
# if test -f $DAG; then 
# 	# if the dag file already exists, remove it
# 	#rm $DAG
# fi

if [[ $GEN_BOOL -eq 1 ]]
# if the simulation should be generated on the chtc node
then
	# generate directories
	gendirs $D

	# generate simulation programs
	gensim

	# generate simulation parameters and store in file
	gensimparam

	# generate submit file for testH simulations
	# SUB="${D}/${JOBID}.sub"
	genCHTCsub ${JOBID}
	# exit 0

	# submit simulations to chtc condor
	MAIN=$PWD
	cd $D
	condor_submit -batch-name "${JOBID}" ${JOBID}.sub > ${JOBID}_sub.out
	cd $MAIN
	sleep 10
	condor_watch_q
fi

if [[ ANAL_BOOL -eq 1 ]]
# the script should analyze data generated by simulations
then 

	echo "TODO :: configure testH analysis programs with polsqu simulation code."
fi