#!/bin/bash

function ensure_mongo_repo {
    
    echo "-- ensuring correct mongodb repo"

    MONGO_KEYSRVR="hkp://keyserver.ubuntu.com:80"
    MONGO_KEY="EA312927"
    KEY_OPTS="--keyserver-options http-proxy=$PROXY"
    MONGO_SOURCE_LIST="/etc/apt/sources.list.d/mongo-org-3.2.list"
    YUM_REPO="/etc/yum.repos.d/mongodb.repo"

    if [[ -z $PROXY ]]; then
        echo "-- proxy not detected"
        KEY_OPTS=""
    else
        echo "-- using $PROXY to get key"
    fi

    if [[ $OS == "Ubuntu" ]]; then

        echo "-- requesting mongodb-org gpg key"
        apt-key adv $KEY_OPTS $MONGO_KEYSRVR --recv-keys $MONGO_KEY

        if [[ $OSVERSION == "16" ]]; then
            OS_REPO="xenial"
        else 
            OS_REPO="trusty"
        fi

        DEB="http://repo.mongodb.org/apt/ubuntu $OS_REPO/mongodb-org/3.2"
        echo "deb $DEB multiverse" | tee $MONGO_SOURCE_LIST
    else 
        if grep --quiet mongo /etc/yum.repos.d/mongodb.repo; then
            echo "-- mongo yum repo already present"
        else
            echo "-- adding mongo yum repo stanza"
            cat <<- EOF > $YUM_REPO
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
        service $1 $2
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
    chown -r mongodb:mongodb $DBDIR

    MONGO_LOG="/var/log/mongodb/mongod.log"
    echo "-- clearing $MONGO_LOG"
    cat /dev/null > $MONGO_LOG

    # not sure this is needed
#    echo "-- configuring startup"
#    if [[ $OS == "Ubuntu" ]]; then
#        if [[ $OSVERSION == "16" ]]; then
#            MDB_SYSTEMD="/etc/systemd/system/mongod.service"
#            MDB_SYSTEMD_SRC="$DEVDIR/../install/src/mongodb/mongod.service"
#            if [[ ! -e $MDB_SYSTEMD ]]; then
#                echo "-- installing $MDB_SYSTEMD"
#                cp $MDB_SYSTEMD_SRC $MDB_SYSTEMD
#            else
#                echo "-- $MDB_SYSTEMD already present"
#            fi
#            systemctl daemon-reload
#            systemctl enable mongod.service
#        else
#            # echo "-- enabling mongod in defaults rc.d"
#            # not needed
#            echo ""
#        fi
#    else
#        echo "-- adding ckconfig mongod "
#        chkconfig --add mongod
#    fi

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
