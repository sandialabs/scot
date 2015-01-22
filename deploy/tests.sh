#!/bin/bash

/usr/bin/supervisord &

COUNTER=0
grep -q 'waiting for connections on port' /var/log/mongodb/mongod.log
while [[ $? -ne 0 && $COUNTER -lt 100 ]] ; do
  sleep 1
  let COUNTER+=1
  echo "Waiting for mongo to initialize... ($COUNTER seconds so far)"
  grep -q 'waiting for connections on port' /var/log/mongodb/mongod.log
done

cd /opt/sandia/webapps/scot3/t/
perl /opt/sandia/webapps/scot3/t/all.t

if [ "\$?" == "0" ]; then
  exit 0;
else
  exit 1;
fi
