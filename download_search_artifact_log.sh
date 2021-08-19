#!/bin/bash
#bash download_search_artifact_log.sh project_sha_list.csv 100

if [[ $1 == "" ]] || [[ $2 == "" ]]; then
    echo "arg1 - Path to CSV file with project, SHA"
    echo "arg2 - Number of workflow runs you want to download"
    exit
fi

PROJECT_SHA_LIST_FILE=$1
WORKFLOW="ci-unit-broker-broker-gp2_modified-pom"  #"workflow"
N_RUNS=$2

for line in $(cat ${PROJECT_SHA_LIST_FILE}); do

	# get the SLUG, name and SHA of the poject from the file
	SLUG=$(echo ${line} | cut -d',' -f1)
	PROJECT_NAME=$(echo ${line} | cut -d',' -f1 | rev | cut -d'/' -f1-1 | rev)
        SHA=$(echo ${line} | cut -d',' -f2)
        
        echo ${SHA}/${PROJECT_NAME}
        WORKFLOW_FILE=${WORKFLOW}_${SHA}.yaml

	cd ${SHA}/${PROJECT_NAME}

	echo $N_RUNS
	RUN_LIST=runs_list_${SHA}.csv

	gh run list --limit $N_RUNS -w ${WORKFLOW_FILE} | awk '{$1=$1}1' OFS="," | tee $RUN_LIST
	
	LOG_DIR="logs_dir/${WORKFLOW}"
	ARTIFACT_DIR="artifact_dir/${WORKFLOW}"
	mkdir -p ${LOG_DIR}
	mkdir -p ${ARTIFACT_DIR}
	
	for line in $(cat ${RUN_LIST}); do

    	    run_id=$(echo ${line} | rev | cut -d',' -f3 | rev)
    	    echo $run_id;
    	    status=$(echo ${line} | cut -d',' -f2)
    
    	    # downloading log of a specific run
    	    gh run view ${run_id} --log |& tee ${LOG_DIR}/log_${run_id}.log
    
    	    # downloading artifact of a specific run
    	    if [ $status  == "success" ]; then 
	 	mkdir -p "${ARTIFACT_DIR}/${run_id}/"
	 	gh run download ${run_id} -D ${ARTIFACT_DIR}/${run_id}
    	    fi
    	done   
    	# search into the log directory for test failures
    	RUNs_FAILURE_LOG=failure_${WORKFLOW}_${SHA}_n.log

	grep -a -n -r -A1 "<<< FAILURE!" ${LOG_DIR} | tee $RUNs_FAILURE_LOG
done

