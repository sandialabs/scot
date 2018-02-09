#!/bin/bash
set -m


#set index parameter
mongodb_cmd="mongod --setParameter failIndexKeyTooLong=false --dbpath=/var/lib/mongodb/ --logpath /var/log/mongodb/mongod.log"
cmd="$mongodb_cmd"


$cmd &

#check to see if file exists (meaning an admin user exists) and if it doesnt, create one
if [ ! -f /var/lib/mongodb/mongodb_password_set ]; then
    /set_mongodb_config.sh 
fi

fg
