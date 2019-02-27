#!/bin/bash

topology_file="deep-oc-mesos-webdav.yml"

USAGEMESSAGE="[Usage]: $0 [topology yaml file, default=$topology_file]"

if [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
    shopt -s xpg_echo
    echo $USAGEMESSAGE
    exit 1
elif [ $# -eq 1 ]; then
    topology_file=$1
fi

###
# GPU command versions:
# "run_command": "jupyterPORT=$PORT2 /run_jupyter.sh --allow-root",
# "run_command": "deepaas-run --listen-port=0.0.0.0 --listen-port=$PORT0",
###
# Jupyter possible config:
# "jupyter_pass": "s3cret",
# "jupyter_config_url": "deepnc:/Datasets/jupyter"
###
orchent depcreate $topology_file '{ "docker_image": "deephdc/deep-oc-dogs_breed_det:cpu",
                                    "mem_size": "8192 MB",
                                    "num_cpus": "1",
                                    "num_gpus": "0",
                                    "run_command": "deepaas-run --listen-ip=0.0.0.0",
                                    "rclone_conf": "/srv/.rclone/rclone.conf",
                                    "rclone_url": "https://nc.deep-hybrid-datacloud.eu/remote.php/webdav/",
                                    "rclone_user": "DEEP-IAM-XYXYXYXYXYXYXYXYXYXY",
                                    "rclone_pass": "jXXXX%XYXYXYXYXYXYXYXYXYXYXYXYXYXYX" }'

