#!/bin/bash
#bash search_into_log.sh

#if [[ $1 == "" ]]; then
#    echo "arg1 - Number of workflow runs you want to download"
#    exit
#fi

RUNs_FAILURE_LOG=all_runs_failure_log.log

grep -r "<<< FAILURE!" pulsar/logs_dir | tee $RUNs_FAILURE_LOG



