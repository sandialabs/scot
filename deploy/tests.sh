#!bin/bash

/usr/bin/supervisord
sleep 30
cd /opt/sandia/webapps/scot3/t/
perl /opt/sandia/webapps/scot3/t/all.t
