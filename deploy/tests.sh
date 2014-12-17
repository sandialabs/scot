#!/bin/bash

/usr/bin/supervisord &
sleep 20
cd /opt/sandia/webapps/scot3/t/
perl /opt/sandia/webapps/scot3/t/all.t

if [ "\$?" == "0" ]; then 
  exit 0;
else
  exit 1;
fi
