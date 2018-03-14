#!/bin/bash

echo 'reset elastic db'
docker exec -it -u elasticsearch elastic /bin/bash /opt/scot/elastic/mapping.sh

echo 'reset mongodb'
docker exec -it mongodb /usr/bin/mongo scot-prod  /opt/scot/demo/reset.js

echo 'starting demo'
docker exec -it -u mongodb mongodb /opt/scot/demo/demo2.pl
