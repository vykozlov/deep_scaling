# -*- coding: utf-8 -*-
#
# Copyright (c) 2017 - 2019 Karlsruhe Institute of Technology - Steinbuch Centre for Computing
# This code is distributed under the MIT License
# Please, see the LICENSE file
#
# Created on Thu Feb 28 09:18:17 2019
# @author: valentin.kozlov
#

# 1. (done) Set number of requests
# 2. (done) Read how many images are in the 'testdata' directory -> file_array
# 3. (done) Append file_array, such that the size of array > number of requests
# 4. (done) submit the number of requests, output is rerdirected in smthg 
#    DateNow-predict_multi-number.log
# 5. (ToDo) In a while loop open files, check content (size?) until all is done or timeout(?)
# 6. (ToDo) Report number of successful requests

### 1. Default parameters
NumRequests=3
RemoteURL="http://147.213.75.181:10017/"
Model="Dogs_Breed"
TestDir=$PWD/testdata

##### USAGEMESSAGE #####
USAGEMESSAGE="Usage: $0 <options> ; where <options> are: \n
	         --num_requests=number \t \t Number of requests to call \n
              --remote_url=url      \t \t http://WebAddress:Port, e.g. http://147.213.75.181:10017 \n
              --model=string        \t \t Name of the deployed user's Model \n
              --test_dir            \t \t \t Directory with test data (default 'testdata') \n"

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
elif [ $# -ge 1 ] && [ $# -le 4 ]; then
    for i in "${arr[@]}"; do
        [[ $i = *"--num_requests"* ]] && NumRequests=${i#*=}
        [[ $i = *"--remote_url"* ]] && RemoteURL=${i#*=}
        [[ $i = *"--model"* ]] && Model=${i#*=}
        [[ $i = *"--test_dir"* ]] && TestDir=${i#*=}
    done
else
    # Too many arguments were given (>1)
    echo "ERROR! Too many arguments provided!"
    shopt -s xpg_echo    
    echo $USAGEMESSAGE
    exit 2
fi

RemoteURL=${RemoteURL%/}


### 2. Check how many files in TestDir
#      looking for only .jpeg, .jpg
FileList=($(ls -1 $TestDir | egrep "(.jpeg|.jpg)"))

# Make new array of files
FileListLong=("${FileList[@]}") 

### 3. Append FileListLong until its size > NumRequests
while [ ${#FileListLong[@]} -lt $NumRequests ]
do
    FileListLong=( ${FileListLong[*]} ${FileList[*]})
done

echo ""
echo ${FileListLong[*]}
echo ${#FileListLong[@]}


### 4. Submit the number of requests (NumRequests)
DateNow=$(date +%y%m%d_%H%M%S)
counter=0

for j in $(seq 1 $NumRequests)
do
    test_file=${FileListLong[counter]}
    log_file="$DateNow-predict_multi-${counter}.log"
    echo "curl -X POST '${RemoteURL}/models/${Model}/predict' \
         -H 'accept: application/json' -H  'Content-Type: multipart/form-data' \
         -F 'data=@${test_file};type=image/jpeg'" > $log_file

    echo "" > $log_file

    curl -X POST "${RemoteURL}/models/${Model}/predict" \
         -H "accept: application/json" -H  "Content-Type: multipart/form-data" \
         -F "data=@${TestDir}/${test_file};type=image/jpeg" > $log_file &

    # waits for the upload of an image to finish, then goes to next call
    # without it first call is fine, others "Internal Server Error"
    wait 

    let counter=counter+1
done