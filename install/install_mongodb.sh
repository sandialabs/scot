#!/bin/bash

function ensure_mongo_repo {
    
    echo "-- ensuring correct mongodb repo"

    if [[ "$MONGO_KEYSRVR" == "" ]]; then
        MONGO_KEYSRVR="--keyserver hkp://keyserver.ubuntu.com:80"
    fi
    if [[ "$MONGO_KEY" == "" ]]; then
        MONGO_KEY="EA312927"
    fi
    if [[ "$MONGO_KEY_OPTS" == "" ]]; then
        MONGO_KEY_OPTS="--keyserver-options http-proxy=$PROXY"
    fi
    if [[ "$MONGO_SOURCE_LIST" == "" ]]; then
        MONGO_SOURCE_LIST="/etc/apt/sources.list.d/mongo-org-3.2.list"
    fi
    if [[ "$MONGO_YUM_REPO" == "" ]]; then
        MONGO_YUM_REPO="/etc/yum.repos.d/mongodb.repo"
    fi

    if [[ -z $PROXY ]]; then
        echo "-- proxy not detected"
        MONGO_KEY_OPTS=""
    else
        echo "-- using $PROXY to get key"
    fi

    if [[ $OS == "Ubuntu" ]]; then

        echo "-- requesting mongodb-org gpg key"
        apt-key adv $MONGO_KEY_OPTS $MONGO_KEYSRVR --recv $MONGO_KEY

        if [[ $OSVERSION == "16" ]]; then
            OS_REPO="xenial"
        else 
            OS_REPO="trusty"
        fi

        DEB="http://repo.mongodb.org/apt/ubuntu $OS_REPO/mongodb-org/3.2"
        echo "deb $DEB multiverse" | tee $MONGO_SOURCE_LIST
        apt-get update
    else 
        if grep --quiet mongo /etc/yum.repos.d/mongodb.repo; then
            echo "-- mongo yum repo already present"
        else
            echo "-- adding mongo yum repo stanza"
            cat <<- EOF > $MONGO_YUM_REPO
[mongodb-org-3.2]
name=MongoDB Repository
baseurl=http://repo.mongodb.org/yum/redhat/$OSVERSION/mongodb-org/3.2/x86_64/
gpgcheck=0
enabled=1
EOF
        fi
    fi
}

function add_failIndexKeyTooLong {

    MONGO_SRC_DIR=$DEVDIR/src/mongodb
    MONGO_SYSTEMD_INIT=/lib/systemd/system/mongod.service
    MONGO_INIT=/etc/init/mongod.conf
    MONGO_INIT_SRC=$MONGO_SRC_DIR/init-mongod.conf

    if [[ $OS == "Ubuntu" ]]; then

        if [[ $OSVERSION == "16" ]]; then
            echo "- ubuntu 16 locations"
            if grep --quiet failIndexKeyTooLong $MONGO_SYSTEMD_INIT; then
                echo "- failIndexKeyTooLong is present"
            else
                echo "- backing up $MONGO_SYSTEMD_INIT"
                backup_file $MONGO_SYSTEMD_INIT
                echo "- installing $MONGO_SRC_DIR/mongod.service"
                cp $MONGO_SRC_DIR/mongod.service $MONGO_SYSTEMD_INIT
            fi
        else
            echo "- ubuntu 14 locations"
            if grep --quiet failIndexKeyTooLong $MONGO_INIT; then
                echo "- failIndexKeyTooLong is present"
            else
                echo "- backing up $MONGO_INIT"
                backup_file $MONGO_INIT
                echo "- installing $MONGO_INIT_SRC"
                cp $MONGO_INIT_SRC $MONGO_INIT
            fi
        fi
    else
        echo "- cent locations"
        if grep --quiet failIndexKeyTooLong $MONGO_INIT;then
            echo "- failIndexKeyTooLong is present"
        else
            echo "- backing up $MONGO_INIT"
            backup_file $MONGO_INIT
            echo "- installing $MONGO_INIT_SRC"
            cp $MONGO_INIT_SRC $MONGO_INIT
        fi
    fi
}

function start_stop  {
    if [[ $OS == "Ubuntu" ]]; then
        if [[ $OSVERSION == "16" ]]; then
            systemctl $2 ${1}.service
        else
            service $1 $2
        fi
    else
        # cent 7 is systemd
        # service $1 $2
        systemctl $2 ${1}.service
    fi
}


function configure_for_scot {

    echo "--"
    echo "-- configuring MONGODB for SCOT"
    echo "--"

    echo "-- stopping mongodb if it is running"
    start_stop mongod stop

    echo "-- ensuring failIndexKeyTooLong is set"
    add_failIndexKeyTooLong 

    if [[ ! -d $DBDIR ]]; then
        echo "-- $DBDIR not present, creating..."
        mkdir -p $DBDIR
    else
        echo "-- $DBDIR present"
    fi

    echo "-- ensuring ownership"
    chown -R mongodb:mongodb $DBDIR

    MONGO_LOG="/var/log/mongodb/mongod.log"
    echo "-- clearing $MONGO_LOG"
    cat /dev/null > $MONGO_LOG

    initialize_database("reset")

    start_stop mongod start
}

function initialize_database {

    if [[ "$RESETDB" == "yes" ]] || [[ "$1" == "reset" ]]; then
        echo "-- initializing SCOT database"
        mongo scot-prod ./src/database/reset.js
    else
        echo "-- skipping SCOT DB initialization"
    fi

}

function install_mongodb {

    echo "---"
    echo "--- Installing Mongodb "
    echo "---"

    ensure_mongo_repo

    if [[ $OS == "Ubuntu" ]]; then
        apt-get-update
        apt-get install -y mongodb-org
    else
        yum install mongodb-org -y
    fi

    configure_for_scot
}
