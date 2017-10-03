#!/bin/bash

#admin User
MONGODB_ADMIN_USER=${MONGODB_ADMIN_USER:-"admin"}
MONGODB_ADMIN_PASS=${MONGODB_ADMIN_PASS:-"admin"}

# Application Database User
MONGODB_APPLICATION_DATABASE=${MONGODB_APPLICATION_DATABASE:-"scot-prod"}
MONGODB_APPLICATION_USER=${MONGODB_APPLICATION_USER:-"admin"}
MONGODB_APPLICATION_PASS=${MONGODB_APPLICATION_PASS:-"admin"}

#HASH='{:X-PBKDF2}HMACSHA2+512:AAAnEA:sFAw7jFy0WoaZViC9H7P:7uJJ0HmGwzl6s/s79UNcyHpIbBvAIEF6jXeVuDzP+F5CYwQcxPCZM7z/XqC+4oZFLCNJLqCL0R2meU9bF8YiYg=='
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
mongo scot-prod /opt/scot/install/src/mongodb/admin_user.js
mongo scot-prod --eval "db.user.update({username:'admin'}, {$set:{pwhash:'$HASH'}})"

sleep 3

# If we've defined the MONGODB_APPLICATION_DATABASE environment variable and it's a different database
# than admin, then create the user for that database.
# First it authenticates to Mongo using the admin user it created above.
# Then it switches to the REST API database and runs the createUser command 
# to actually create the user and assign it to the database.


# If everything went well, add a file as a flag so we know in the future to not re-create the
# users if we're recreating the container (provided we're using some persistent storage)
touch /data/db/.mongodb_password_set

echo "MongoDB configured successfully. You may now connect to the DB."
