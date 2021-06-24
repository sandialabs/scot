#!/bin/bash

if [[ "$OS" == "Ubuntu" ]]; then
  SERVICES='
      mongod
      activemq
      scot
      apache2
      flair
      enricher
      scepd
  '
else
  SERVICES='
      mongod
      activemq
      scot
      httpd
      flair
      enricher
      scepd
  '
fi

for service in $SERVICES; do
    service $service status
done
