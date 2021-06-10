#!/bin/bash

if [[ "$OS" == "Ubuntu" ]]; then
  SERVICES='
      mongod
      activemq
      scot
      apache2
      flair
      scepd
  '
else
  SERVICES='
      mongod
      activemq
      scot
      httpd
      flair
      scepd
  '
fi

for service in $SERVICES; do
    service $service status
done
