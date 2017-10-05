#!/bin/bash
SHELL=/bin/sh PATH=/bin:/sbin:/usr/bin:/usr/sbin 

echo 'reset elastic db'
/opt/scot/install/src/elasticsearch/mapping.sh

echo 'reset mongodb'
mongo scot-prod < /opt/scot/demo/reset.js

echo 'starting demo'
/opt/scot/demo/demo2.pl
