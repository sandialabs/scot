#!/bin/bash
pidloc="/var/run/scot_backup.pid"
touch $pidloc
pid=`cat $pidloc`
if [ ! -e /proc/$pid ] || [ "$pid" == "" ]; then 
  echo $$ > $pidloc
  echo ""
  echo "Unpacking SCOT Backup Bundle for restore"
  echo ""
  rm -rf /opt/sandia/webapps/scot3/restore/tmp
  mkdir /opt/sandia/webapps/scot3/restore/tmp
  tar -C /opt/sandia/webapps/scot3/restore/tmp -xvzf /opt/sandia/webapps/scot3/restore/restore.tgz
  echo ""
  echo "Restoring REDIS"
  echo ""
  redis-cli --raw flushAll
  /etc/init.d/redis-server stop
  rm /var/lib/redis/dump.rdb
  mv /opt/sandia/webapps/scot3/restore/tmp/redis/dump.rdb /var/lib/redis/dump.rdb 
  echo -n "--"
  /etc/init.d/redis-server start  
  echo ""
  echo "Restoring MongoDB"
  echo ""
  mongo scotng-prod --eval "printjson(db.dropDatabase())"  
  mongorestore /opt/sandia/webapps/scot3/restore/tmp/mongo  
  echo ""
  echo "Restoring user uploaded files"
  echo ""
  rm -rf /opt/sandia/webapps/scot3/scotfiles
  mv /opt/sandia/webapps/scot3/restore/tmp/scotfiles /opt/sandia/webapps/scot3/
  echo ""
  echo "DONE"

fi
