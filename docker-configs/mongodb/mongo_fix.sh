echo "`/bin/sh ./set_mongodb_config.sh`"

mongo scot-prod --eval "db.user.deleteMany({username:'admin'})"
