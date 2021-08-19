#!/bin/bash
#bash run_workflow.sh project_sha_list.csv ci_unit_test_cli 100

if [[ $1 == "" ]] || [[ $2 == "" ]] || [[ $3 == "" ]]; then
    echo "arg1 - Path to CSV file with project, SHA"
    echo "arg2 - Name of the workflow file to trigger run"
    echo "arg3 - Number of workflow runs"
    exit
fi

PROJECT_SHA_LIST_FILE=$1
WORKFLOW=$2
START=1
END=$3

for line in $(cat ${PROJECT_SHA_LIST_FILE}); do

	# get the SLUG, name and SHA of the poject from the file
	SLUG=$(echo ${line} | cut -d',' -f1)
	PROJECT_NAME=$(echo ${line} | cut -d',' -f1 | rev | cut -d'/' -f1-1 | rev)
        SHA=$(echo ${line} | cut -d',' -f2)
        
        WORKFLOW_FILE=${WORKFLOW}.yml 
	mkdir -p ${SHA}/
	cp ${WORKFLOW_FILE} ${SHA}/
	cd ${SHA}
	
	# clone the project if does not exist in local directory
	if [ -d "$PROJECT_NAME" ]; then
	   echo "Project already in your local repository ${PROJECT_NAME}."
	else
	   gh repo clone ${SLUG}
	fi
	
	# rename and save a copy of the workflow file to the workflows directory of new branch
	NEW_WORKFLOW_FILE=${WORKFLOW}_${SHA}.yml
	mv ${WORKFLOW_FILE} ${NEW_WORKFLOW_FILE}
	mv ${NEW_WORKFLOW_FILE} ${PROJECT_NAME}/.github/workflows/
	
	cd ${PROJECT_NAME}
	BRANCH_NAME=${PROJECT_NAME}_${SHA}
	
	git add .github/workflows/${NEW_WORKFLOW_FILE}
	
	git commit -m "adding workflow file"
	
	# may2021 SHA: e1389db6727db2106805e473096609d719b572d3
	git checkout -b ${BRANCH_NAME} ${SHA} # 12 June 2021 SHA: d81b5f8b8e6cb17f307ec830accaf9dd95d7643b
	git rev-parse HEAD
	git branch
	#git push -f origin master
	git push -u origin ${BRANCH_NAME}
	
	# manually run the workflow N times without any push or pull event
	for ((i = $START ; i <= $END ; i++)); do
	  echo "Workflow run: $i"
	  gh workflow run ${NEW_WORKFLOW_FILE} --ref ${BRANCH_NAME}
	done
done
