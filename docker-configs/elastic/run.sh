#!/bin/bash

set -m
elastic_cmd="/bin/bash bin/es-docker"
cmd="$elastic_cmd"

$cmd &

#check to see if file exists (meaning mapping has been run) and if it doesnt, create one
if [ ! -f /var/lib/elasticsearch/.elastic_mapping_set ]; then
    /set_elastic_config.sh 
fi

fg
