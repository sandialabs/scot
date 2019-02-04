#!/bin/bash

echo 'reset elastic db'
docker exec -u elasticsearch elastic /bin/bash /opt/scot/elastic/mapping.sh

echo 'reset mongodb'
docker exec mongodb /usr/bin/mongo scot-prod  /opt/scot/demo/reset.js

echo 'starting demo'
docker exec -u mongodb mongodb /opt/scot/demo/demo2.pl
