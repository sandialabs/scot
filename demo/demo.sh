#!/bin/bash
SHELL=/bin/sh PATH=/bin:/sbin:/usr/bin:/usr/sbin 

echo 'reset elastic db'
curl -X DELETE 'http://localhost:9200/scot'
/opt/scot/install/src/elasticsearch/mapping.sh

echo 'reset mongodb'
mongo scot-prod < /usr/lib/scotdemo/reset.js
/usr/lib/scotdemo/demogenerator.pl
