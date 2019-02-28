#!/usr/bin/env bash
#
# Copyright (c) 2017 - 2019 Karlsruhe Institute of Technology - Steinbuch Centre for Computing
# This code is distributed under the MIT License
# Please, see the LICENSE file
#
####
# Simple bash script to submit deployments,
# check their status, record a simple log
# and delete them, if necessary
#
# Arguments (optional):
#  --num_jobs=number       The amount of deployments to submit
#  --submit_cmd            Script used to submit a single job
#  --search_string=string  String to search within curl response
#
# vkozlov @27-Feb-2019
###

NumJobs=20
submit_cmd=./submit_orchent.sh
CurlSearchString="Author\":"

SleepSubmitTime="3s"
SleepLogTime="20s"


##### USAGEMESSAGE #####
USAGEMESSAGE="Usage: $0 <options> ; where <options> are: \n
	         --num_jobs=number       \t \t The amount of deployments to submit \n
              --submit_cmd=command    \t \t Script used to submit a single job \n
              --search_string=string  \t String to search within curl response \n"

##### PARSE SCRIPT FLAGS #####
arr=("$@")
if [ $# -eq 0 ]; then 
# use default config (0)
    break 
elif [ $1 == "-h" ] || [ $1 == "--help" ]; then 
# print usagemessage
    shopt -s xpg_echo
    echo $USAGEMESSAGE
    exit 1
elif [ $# -ge 1 ] && [ $# -le 3 ]; then
    for i in "${arr[@]}"; do
        [[ $i = *"--num_jobs"* ]] && NumJobs=${i#*=}
        [[ $i = *"--submit_cmd"* ]] && submit_cmd=${i#*=}
        [[ $i = *"--search_string"* ]] && CurlSearchString=${i#*=}
    done
else
    # Too many arguments were given (>1)
    echo "ERROR! Too many arguments provided!"
    shopt -s xpg_echo    
    echo $USAGEMESSAGE
    exit 2
fi

DateNow=$(date +%y%m%d_%H%M%S)
LogFile="$DateNow-multi_submission_$NumJobs.csv"


# write initial time and number of jobs to submit in the log file
echo "$DateNow,NumJobs,$NumJobs" > $LogFile

DeploymentsBefore=($(orchent depls -c me |grep Deployment |\
                 awk '{print $2}' | cut -d '[' -f2 | cut -d ']' -f1))

StatusAllBefore=($(orchent depls -c me |grep status | awk '{print $2}'))
StatusINPROGRESSBefore=($(orchent depls -c me |grep CREATE_IN_PROGRESS | awk '{print $2}'))
StatusCOMPLETEBefore=($(orchent depls -c me |grep CREATE_COMPLETE | awk '{print $2}'))

NumDeploymentsBefore=${#DeploymentsBefore[@]}
NumINPROGRESSBefore=${#StatusINPROGRESSBefore[@]}
NumCOMPLETEBefore=${#StatusCOMPLETEBefore[@]}

DateNow=$(date +%y%m%d_%H%M%S)
echo "Date,NumDeployments,NumINPROGRESS,NumCOMPLETE," >> $LogFile
echo "$DateNow,$NumDeploymentsBefore,$NumINPROGRESSBefore,$NumCOMPLETEBefore," >> $LogFile

echo ""
echo "+-----------------------------------------------+"
echo "|  Checking if there are previous deployments   |"
echo "+-----------------------------------------------+"
echo "Date NumDeployments NumINPROGRESS NumCOMPLETE"
echo "$DateNow $NumDeploymentsBefore $NumINPROGRESSBefore $NumCOMPLETEBefore"
echo ""

echo "$(date +%y%m%d_%H%M%S), [INFO] Submitting $NumJobs Jobs," >> $LogFile
sub_counter=0
for j in $(seq 1 $NumJobs)
do 
    let sub_counter=sub_counter+1
    echo "Deploying #$sub_counter from $NumJobs"
    $submit_cmd
    sleep $SleepSubmitTime
done

# Wait until all deployments are in CREATE_COMPLETE
job_success=0
while [ $job_success -lt $NumJobs ]
do
    DateNow=$(date +%y%m%d_%H%M%S)
    OrchentOutput=$(orchent depls -c me)
    Deployments=($(echo "$OrchentOutput" |grep Deployment |\
                 awk '{print $2}' | cut -d '[' -f2 | cut -d ']' -f1))
    StatusAll=($(echo "$OrchentOutput"  |grep status | awk '{print $2}'))
    StatusINPROGRESS=($(echo "$OrchentOutput"  |grep CREATE_IN_PROGRESS | awk '{print $2}'))
    StatusCOMPLETE=($(echo "$OrchentOutput" |grep CREATE_COMPLETE | awk '{print $2}'))

    job_success=${#StatusCOMPLETE[@]}
    echo "$DateNow ${#Deployments[@]} ${#StatusINPROGRESS[@]} $job_success "
    echo "$DateNow,${#Deployments[@]},${#StatusINPROGRESS[@]},$job_success," >> $LogFile

    sleep $SleepLogTime
done

# List deployments once again
OrchentOutput=$(orchent depls -c me)
Deployments=($(echo "$OrchentOutput" |grep Deployment |\
             awk '{print $2}' | cut -d '[' -f2 | cut -d ']' -f1))

CreationTime=($(echo "$OrchentOutput" |grep "creation time" | cut -d ':' -f2,3))

curl_success=0
echo "" >> $LogFile
# Try to access all deployments via curl call, deepaas_endpoint is expected!
for dep in ${Deployments[*]}
do
    echo "Checking $dep"
    DateNow=$(date +%y%m%d_%H%M%S)
    WebLink=$(orchent depshow $dep | grep deepaas_endpoint | \
              awk '{print $2}' | cut -d'"' -f2)

    CurlResponse=$(curl -X GET "http://$WebLink/models/" -H  "accept: application/json")
    if [[ $CurlResponse == *"$CurlSearchString"* ]]; then
       let curl_success=curl_success+1
    fi

    CreationTime=${CreationTime[icounter]}
    echo "$DateNow,$dep,$CreationTime,$WebLink,$CurlResponse" >> $LogFile
    echo "" >> $LogFile 
done

DateNow=$(date +%y%m%d_%H%M%S)
echo "$DateNow, Deployments accessed, $curl_success," >> $LogFile
echo "$DateNow, Deployments deployed, ${#Deployments[@]}," >> $LogFile
echo ",[INFO] Finished checking," >> $LogFile

if [ $curl_success -eq ${#Deployments[@]} ]; then
    echo "+------------------------------------------------+"
    echo "| Looks like all deployments respond correctly!  |"
    echo "+------------------------------------------------+"
else
    echo "+------------------------------------------------+"
    echo "|    Hmmm... some deployments do not respond?    |"
    echo "+------------------------------------------------+"
fi

# You may immediately delete all deployments
# either all at the same time ...
echo -n "Do you want to delete them all? (y/n) "
read REPLY
echo "" # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    for dep in ${Deployments[*]}
    do
        echo "Deleting $dep"
        orchent depdel $dep
    done
    DateNow=$(date +%y%m%d_%H%M%S)
    echo "$DateNow,[INFO] Triggered deletion of all deployments," >> $LogFile
fi

# ... or one-by-one
echo -n "Do you want to delete them one-by-one? (y/n) "
read REPLY
echo "" # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    counter=0
    for dep in ${Deployments[*]}
    do
        echo "Deployment $dep"
        echo "Created: ${CreationTime[counter]}"
        echo -n "Delete? (y/n) "
        read REPLY
        if [[ $REPLY =~ ^[Yy]$ ]]; then
           orchent depdel $dep
           echo ""
        fi
        let counter=counter+1
    done
fi
