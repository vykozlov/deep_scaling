#!/bin/bash
####
# Simple bash script to check all user deployments
# and delete them, if necessary
# vkozlov @19-Feb-2019
###

OrchentOutput=$(orchent depls -c me)
DeploymentList=($(echo "$OrchentOutput" |grep Deployment |\
                 awk '{print $2}' | cut -d '[' -f2 | cut -d ']' -f1))
CreationTime=($(echo "$OrchentOutput" |grep "creation time" | cut -d ':' -f2,3))

echo "Found ${#DeploymentList[@]} deployments"
echo -n "Do you want to delete all your deployments? (y/n) "
read REPLY
echo "" # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    for dep in ${Deployments[*]}
    do
        echo "Deleting $dep"
        orchent depdel $dep
    done
fi

echo -n "Do you want to delete them one-by-one? (y/n) "
read REPLY
echo "" # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    counter=0
    for dep in ${DeploymentList[*]}
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