#!/bin/bash
set -m

mongodb_cmd="mongod --setParameter failIndexKeyTooLong=false --dbpath=/var/lib/mongodb/"
cmd="$mongodb_cmd"

if [ "$AUTH" == "yes" ]; then
    cmd="$cmd --auth"
fi

$cmd &


if [ ! -f /var/lib/mongodb/.mongodb_password_set ]; then
    /set_mongodb_config.sh 
fi

fg
