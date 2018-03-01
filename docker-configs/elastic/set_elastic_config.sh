#!/bin/bash

echo $WAIT_FOR_ELASTIC

is_ready() {

    [ $(curl --write-out %{http_code} --silent --output /dev/null http://elastic:9200/_cat/health?h=st) = 200 ]
}


i=0

while ! is_ready; do
    i=`expr $i + 1`
    if [ $i -ge 100 ]; then
        echo "$(date) - elastic still not ready, giving up"
        exit 1
    fi
    echo "$(date) - waiting to be ready"
    sleep 10 
done
echo "Elastic configured successfully. You may now connect to http://elastic:9200."
if [ ! -f /var/lib/mongodb/mongodb_password_set ]; then
    /bin/bash /opt/scot/elastic/mapping.sh
    echo 'Mapping set' >/var/lib/elasticsearch/elastic_mapping_set
fi
