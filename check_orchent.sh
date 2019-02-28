#!/usr/bin/env bash
#
# Copyright (c) 2017 - 2019 Karlsruhe Institute of Technology - Steinbuch Centre for Computing
# This code is distributed under the MIT License
# Please, see the LICENSE file
#
####
# Simple bash script to check response of deployments
#
# Arguments (optional):
#  --search_string=string  String to search within curl response
#
# vkozlov @27-Feb-2019
###

CurlSearchString="Author\":"

##### USAGEMESSAGE #####
USAGEMESSAGE="Usage: $0 <options> ; where <options> are: \n
              --search_string=string  \t String to search within curl response \n"

##### PARSE SCRIPT FLAGS #####
arr=("$@")
if [ $# -eq 0 ]; then 
# use default config (0)
    echo "Taking default values ..."
    echo "--search_string=$CurlSearchString"
elif [ $1 == "-h" ] || [ $1 == "--help" ]; then 
# print usagemessage
    shopt -s xpg_echo
    echo $USAGEMESSAGE
    exit 1
elif [ $# -eq 1 ]; then
    for i in "${arr[@]}"; do
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
LogFile="$DateNow-check_orchent.csv"

# List deployments
OrchentOutput=$(orchent depls -c me)
Deployments=($(echo "$OrchentOutput" |grep Deployment |\
             awk '{print $2}' | cut -d '[' -f2 | cut -d ']' -f1))

CreationTime=($(echo "$OrchentOutput" |grep "creation time" | cut -d ':' -f2,3))

curl_success=0
echo "" >> $LogFile
# Try to access all deployments via curl call, deepaas_endpoint is expected!
icounter=0
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
    let icounter=icounter+1
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
