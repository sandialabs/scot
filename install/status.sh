#!/bin/bash

SERVICES='
    mongod
    activemq
    scot
    apache2
    httpd
    scfd
    scepd
'

for service in $SERVICES; do
    service $service status
done
