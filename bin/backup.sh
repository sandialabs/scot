#!/bin/bash
pidloc="/var/run/scot_backup.pid"
touch $pidloc
pid=`cat $pidloc`
if [ ! -e /proc/$pid ] || [ "$pid" == "" ]; then 
  echo $$ > $pidloc
  rm -rf /opt/sandia/webapps/scot3/backups/tmp
  mkdir -p /opt/sandia/webapps/scot3/backups/tmp/redis
  lastRedisSave=`redis-cli --raw lastsave`
  echo ""
  echo "Backing Up REDIS"
  echo ""
  echo -n "--"
  redis-cli bgsave
  until [ `redis-cli --raw lastsave` -gt $lastRedisSave ]; do
    echo -n "."
    sleep 1s
  cp /var/lib/redis/dump.rdb /opt/sandia/webapps/scot3/backups/tmp/redis
  done
  echo ""
  echo "Backing up MongoDB"
  echo ""
  (cd /opt/sandia/webapps/scot3/backups/tmp && mongodump --db scotng-prod -o mongo)
  now=$(date +'%Y%m%d%H%M');
  base="/opt/sandia/webapps/scot3/backups/$now";
  file=$base".zgt"
  final=$base".tgz"
  echo ""
  echo "Backing up user uploaded files"
  echo ""
  echo "Compressing backup to $file"
  echo ""
  tar czfv $file -C /opt/sandia/webapps/scot3/backups/tmp . /opt/scotfiles/
  mv $file $final
fi
