#!/bin/bash

# delete all admin accounts
mongo scot-prod --host mongodb --eval "db.user.deleteMany({username:'admin'})"

#set default password has (admin/admin)
HASH='{X-PBKDF2}HMACSHA2+512:AAAnEA:nCpmgiazs0SRt8Z53T9I:Z97YBqqp7H+uDl+oti+buLxayC9k+geSv3/zY63kctusQWqVJl5h+rx6t07LhhYM+hO9Fk8FpuzEhKx73v3zmw=='

# Wait for MongoDB to boot
RET=1
while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of MongoDB service startup..."
    sleep 5
    mongo admin --eval "help" >/dev/null 2>&1
    RET=$?
done

set='$set'

# If everything went well, add a file as a flag so we know in the future to not re-create the
# users if we're recreating the container (provided we're using some persistent storage)

if [ ! -f /var/lib/mongodb/mongodb_password_set ]; then
    mongo scot-prod --host mongodb /opt/scot/install/src/mongodb/reset.js
    mongo scot-prod --host mongodb /opt/scot/install/src/mongodb/admin_user.js
    mongo scot-prod --host mongodb --eval "db.user.update({username:'admin'}, {$set:{pwhash:'$HASH'}}, {multi:true})"
    echo "Mapping set for Mongo" > /var/lib/mongodb/mongodb_password_set
fi

sleep 3

echo "MongoDB configured successfully. You may now connect to the DB."

