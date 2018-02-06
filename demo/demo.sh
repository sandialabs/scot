#!/bin/bash

echo 'reset elastic db'
sudo docker exec -it -u elasticsearch elastic /bin/bash /opt/scot/elastic/mapping.sh

echo 'reset mongodb'
sudo docker exec -it mongodb /usr/bin/mongo scot-prod  /opt/scot/demo/reset.js

echo 'starting demo'
sudo docker exec -it -u mongodb mongodb /opt/scot/demo/demo2.pl
