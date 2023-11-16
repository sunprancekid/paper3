#!/bin/bash
set -e

# Matthew Dorsey
# 10-25-2022
# script that downloads and updates simulation directories using rsync
# call from sim directory

## PARAMETERS 
# login address to access hpc login nodes
LOGIN="mad@ap21.uc.osg-htc.org"
# LOGIN="matthew.dorsey@ap1.facility.path-cc.io"
# LOGIN="mad@login05.osgconnect.net"
# location of simulation directory
LOC="~/paper3/data/"
# command and flags for remote synchronization
RSYNC="rsync -Pavz"
# non-zero exit code if error occurs or no flag is specified
declare -i NONZERO_EXITCODE=1
# boolean that determines if everything in the specified location (LOC) 
# should be synced with the local directory
declare -i ALL_BOOL=0
# boolean that determines if simbin should be uploaded to the execture node
declare -i BIN_BOOL=0
# boolean that determines if a specific job should be downloaded from the execute node
declare -i JOB_BOOL=0
# boolean that determines if only the save fules should be uploaded to the execute node
declare -i SAVE_BOOL=0


## OPTIONS
# parse options
while getopts ":abj:s:" option; do
    case $option in 
        a) # sync everything in the specified location (LOC) with the local directory (LOGIN)

            # boolean determining if the directories should be synced
            declare -i ALL_BOOL=1
            ;;
        b) # upload the simbin to the execute node

            # boolean determining if simbin should be uploaded
            declare -i BIN_BOOL=1
            ;;
        j) # sync simulation files corresponding to a specific job on the execute node
            # with files simulation files located on the main diretory

            # TODO this piece of code doesnt work the way I would like it to
            if [ $# -eq 0 ]; then
                echo ""
                echo "Usage : ./update.sh -j [JOB ID]"
                echo ""
                exit $NONZERO_EXITCODE
            fi

            # job id corresponding to the directory that should be downloaded from the
            # execute node
            JOB="${OPTARG}"

            # boolean determining if the job specified by the job id should be downloaded
            # the execute node
            declare -i JOB_BOOL=1
            ;;
        s) # upload save files corresponding to a particular job to the execute node

            # TODO this piece of code doesnt work the way I would like it to
            if [ $# -eq 0 ]; then
                echo ""
                echo "Usage : ./update.sh -s [JOB ID]"
                echo ""
                exit $NONZERO_EXITCODE
            fi
            
            # job id corresponding to the save files that should be uploaded to the
            # execute nodes
            JOB="${OPTARG}"

            # boolean determining if the save files corresponding the job id should be 
            # uploaded to the execute node
            declare -i SAVE_BOOL=1
            ;;
        \?) # default if no flags are specified
            ;;
    esac
done
shift $((OPTIND-1))

## ARGUMENTS
# none


## FUNCTIONS
# none


## SCRIPT

# determine the operation that should be performed
if [[ ALL_BOOL -eq 1 ]]; then 
    # sync everything in the specified location (LOC) with the local directory (LOGIN)

    rsync -Pavz $LOGIN:$LOC ../

elif [[ BIN_BOOL -eq 1 ]]; then 

    # upload the simbin to the execute node (LOGIN) to the specified location (LOC)
    scp -r simbin $LOGIN:$LOC

elif [[ JOB_BOOL -eq 1 ]]; then 

    # sync the simulation files corresponding to the specified job id (JOB) 
    # located in the specified location (LOC) on the specified execute node (LOGIN)
    # with the local simulations corresponding to the job id (JOB)
    rsync -Pavz "${LOGIN}:${LOC}${JOB}/" "./${JOB}/"

    # echo "TODO upload simupdate program"         
    # ./simbin/java/SimUpdate.sh ${JOB} true

elif [[ SAVE_BOOL -eq 1 ]]; then 
    # upload local save files corresponding to the specified job id (JOB) to the location (LOC)
    # on the execute directory (LOGIN)

    # create a list of directories that match the job description
    # right now the job associated with the save files is hard coded
    SAVEDIR=(./${JOB}/*/h*/e*/)
    #printf '%s\n' "${SAVEDIR[@]}"

    # upload the files in each directory to the cloud directory
    # with the same naming hirearchy
    for dir in ${SAVEDIR[@]}
    do
        echo "uploading save files in ${dir}"
        rsync -Pavz "${dir}save" $LOGIN:$LOC$dir
    done
else
            
    # inform user of the options
    echo ""
    echo "update: invalid or no flag specified."
    echo "-a : download entire directory from hpc execute point"
    echo "-b : upload simbin to hpc exectue point"
    echo "-j [JOB ID] : only update sub directories that contain simulation file located on hpcs"
    echo "-s [JOB ID] : upload save files to cloud server"
    echo "NOTE: only one option should be specified"
    echo ""

    # exit with non-zero code
    exit $NONZERO_EXITCODE 

fi

exit 0
