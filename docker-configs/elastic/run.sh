#!/bin/bash

set -m
elastic_cmd="/bin/bash bin/es-docker"

nohup /bin/bash bin/es-docker & 
status=$?
if [ $status -ne 0 ]; then
    echo "Failed to start my_first_process: $status"
    exit $status
fi


#check to see if file exists (meaning mapping has been run) and if it doesnt, create one
if [ ! -f /var/lib/elasticsearch/elastic_mapping_set ]; then
    /opt/scot/elastic/set_elastic_config.sh 
fi

fg
