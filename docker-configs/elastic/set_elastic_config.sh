#!/bin/bash

echo $WAIT_FOR_ELASTIC

is_ready() {
    eval "$(curl --write-out %{http_code} --silent --output /dev/null http://elastic:9200/_cat/health?h=st) = 200"
}

i=0
while ! is_ready; do
    i=`expr $i + 1`
    if [ $i -ge 10 ]; then
        echo "$(date) - elastic still not ready, giving up"
        exit 1
    fi
    echo "$(date) - waiting to be ready"
    sleep 2 
done

/bin/bash /mapping.sh

# If everything went well, add a file as a flag so we know in the future to rerun mapping.sh
echo "ran mapping" > /var/lib/elasticsearch/.elastic_mapping_set

echo "Elastic configured successfully. You may now connect to http://elastic:9200."
