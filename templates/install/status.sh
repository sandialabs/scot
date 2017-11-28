#!/bin/bash

if [[ "$OS" == "Ubuntu" ]]; then
  SERVICES='
      mongod
      activemq
      scot
      apache2
      scfd
      scepd
  '
else
  SERVICES='
      mongod
      activemq
      scot
      httpd
      scfd
      scepd
  '
fi

for service in $SERVICES; do
    service $service status
done
