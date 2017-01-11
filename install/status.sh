#!/bin/bash

SERVICES='
    mongod
    scot
    apache2
    httpd
    scfd
    scepd
'

for service in $SERVICES; do
    service $service status
done
