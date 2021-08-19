#!/bin/bash
#bash run_local_broker_gp1.sh project_sha_list.csv 1

if [[ $1 == "" ]] || [[ $2 == "" ]]; then
    echo "arg1 - Path to CSV file with project, SHA"
    echo "arg2 - Number of local runs"
    exit
fi

PROJECT_SHA_LIST_FILE=$1
START=22
END=$2
WORKFLOW=ci-unit-broker-gp1

for line in $(cat ${PROJECT_SHA_LIST_FILE}); do

	# get the SLUG, name and SHA of the poject from the file
	SLUG=$(echo ${line} | cut -d',' -f1)
	PROJECT_NAME=$(echo ${line} | cut -d',' -f1 | rev | cut -d'/' -f1-1 | rev)
        SHA=$(echo ${line} | cut -d',' -f2)
        
	mkdir -p ${SHA}/
	
	cd ${SHA}
	
	# clone the project if does not exist in local directory
	if [ -d "${PROJECT_NAME}" ]; then
	   echo "Project already in your local repository ${PROJECT_NAME}."
	else
	   gh repo clone ${SLUG}
	fi
	LOCAL_ARTIFACT_DIR=artifacts_local_${SHA}/${WORKFLOW}
	mkdir -p ${LOCAL_ARTIFACT_DIR}
	
	cd ${PROJECT_NAME}
	BRANCH_NAME=${PROJECT_NAME}_${SHA}
	
	
	# may2021 SHA: e1389db6727db2106805e473096609d719b572d3
	#git checkout -b ${BRANCH_NAME} ${SHA} # 12 June 2021 SHA: d81b5f8b8e6cb17f307ec830accaf9dd95d7643b
	LOCAL_LOG_DIR="logs_dir_local/${WORKFLOW}"
        mkdir -p ${LOCAL_LOG_DIR}
         
	# manually run the workflow N times without any push or pull event
	for ((i = $START ; i <= $END ; i++)); do
	  echo "Local run: $i"
	  
	  #building modules
	  mvn -B -ntp -q clean install -Pcore-modules,-main -DskipTests |& tee ${LOCAL_LOG_DIR}/local_run_log_${i}.log
	  
	  #run unit test BROKER_FLAKY
	  build/run_unit_group.sh BROKER_GROUP_1 |& tee ${LOCAL_LOG_DIR}/local_run_log_${i}.log
	  
	  #mvn -fn clean install test |& tee logs_dir_local/local_run_log_${i}.log 
	  mkdir -p artifacts_local_run_${i} 
	  find . -type d -name "*surefire-reports" -exec cp --parents -R {} artifacts_local_run_${i}/ \;
	  mv artifacts_local_run_${i}/ ../${LOCAL_ARTIFACT_DIR}
	done
	
done
