#!/bin/bash

function default_variables {
    # location of private Scot modules
    PRIVATE_SCOT_MODULES="$DEVDIR/../Scot-Internal-Modules"
    # location where to store uploaded files
    FILESTORE="/opt/scotfiles"
    # location where to install SCOT
    SCOTDIR="/opt/scot"
    # SCOT's root
    SCOTROOT="/opt/scot"
    # Port for the hypnotoad scot server
    SCOTPORT=3000
    # location where to build and store SCOT backups
    BACKUPDIR="/opt/scotbackup"
    # location for the log files
    LOGDIR="/var/log/scot"
    # where to find config files used in install
    SCOT_CONFIG_SRC="$DEVDIR/install/src"
    #  where to get the html docs built from the markdown sources
    SCOT_DOCS_SRC="$DEVDIR/docs/build/html"
    # restart SCOT daemons scfd and scep whe installing/upgrading
    SCOT_RESTART_DAEMONS="no"
    # overwrite config files
    SCOT_ENV_OVERWRITE="no"

    # where to install activemq
    AMQDIR="/opt/activemq"
    # the activemq tar package to use
    AMQTAR="apache-activemq-5.13.2-bin.tar.gz"
    # where to get it
    AMQURL="https://repository.apache.org/content/repositories/releases/org/apache/activemq/apache-activemq/5.13.2/$AMQTAR"
    # install time location of the configs
    AMQ_CONFIGS="$SCOT_CONFIG_SRC/ActiveMQ/amq"

    # apt repor for elasticsearch
    ES_APT_LIST="/etc/apt/sources.list.d/elasticsearch-2.x.list"
    # apt key
    ES_GPG="https://packages.elastic.co/GPG-KEY-elasticsearch"
    # the repo
    ES_YUM_REPO="/etc/yum.repos.d/elasticsearch.repo"
    # reset the DB at install
    ES_RESET_DB="no"

    # mongo package keyserver
    MONGO_KEYSRVR="--keyserver hkp://keyserver.ubuntu.com:80"
    # the key
    MONGO_KEY="EA312927"
    # options to use the proxy
    MONGO_KEY_OPTS="--keyserver-options http-proxy=$PROXY"
    # the repo list
    MONGO_SOURCE_LIST="/etc/apt/sources.list.d/mongo-org-3.2.list"
    # and for cent/rh
    MONGO_YUM_REPO="/etc/yum.repos.d/mongodb.repo"
    # refresh the config?
    MONGO_REFESH_CONF="yes"
    # where to install the database data files
    MONGO_DB_DIR="/var/lib/mongodb"

    # mode Local/Remoteuser/Ldap
    AUTHMODE="Local"
    # install all prerequisites or just the scot code "SCOTONLY"
    INSTMODE="ALL"
    # wipe out existing SCOT data in monog db
    RESETDB="no"
    # do yum update or apt-get update
    REFRESHREPOS="yes"
    # wipe the $SCOT_ROOT prior to install
    DELDIR="no"
    # refresh the mongo config file            
    MONGO_REFRESH_CONFIG="no"
    # refresh the apache configs, allow Scot-Internal-Modules to overwrite
    APACHE_REFRESH_CONFIG="no"
    # refresh the scot configs, allow Scot-Internal-Modules to overwrite
    SCOT_REFRESH_CONFIG="no"
}


function process_commandline {
    options="A:M:CDEdprsu"
    while getopts $options opt; do
        case $opt in
            A)
                AUTHMODE=$OPTARG
                ;;
            C)
                SCOT_ENV_OVERWRITE="yes"
                ;;
            D) 
                DELDIR="yes"
                ;;
            E)
                ES_RESET_DB="yes"
                ;;
            d)
                SCOT_RESTART_DEAMONS="yes"
                ;;
            M)
                SCOT_PRIVATE_MODULES=$OPTARG
                ;;
            p)
                REFRESHREPOS="no"
                ;;
            r)
                RESETDB="yes"
                ;;
            u)
                INSTMODE="UPGRADE"
                RESETDB="no"
                REFRESHREPOS="yes"
                MONGO_REFRESH_CONFIG="yes"
                APACHE_REFRESH_CONFIG="yes"
                SCOT_REFRESH_CONFIG="yes"
                ;;
            s)
                echo "SCOT only Install"
                INSTMODE="SCOTONLY"
                RESETDB="no"
                REFRESHREPOS="no"
                MONGO_REFRESH_CONFIG="no"
                ;;
            \?)
                usage
                ;;
            *)
                echo "!!! Invalid command line option: $opt"
                usage
                ;;
        esac
    done
}

function show_variables {
    echo "Install Mode            = INSTMODE             => $INSTMODE"
    echo "Authentication Mode     = AUTHMODE             => $AUTHMODE"
    echo "Delete existing Scot DB = RESETDB              => $RESETDB"
    echo "Delete installation dir = DELDIR               => $DELDIR"
    echo "Refresh Apt/Yum Repos   = REFRESHREPOS         => $REFRESHREPOS"
    echo "Scot Private Modules Loc= SCOT_PRIVATE_MODULES => $SCOT_PRIVATE_MODULES"
    echo "Reset Elasticsearch DB  = ES_RESET_DB          => $ES_RESET_DB"
}

function usage {
    cat << EOF

    Usage: $0 [-A mode] [-M path] [-dDErsu]

        -A mode     where mode = (default) "Local", "Ldap", or "Remoteuser" 
        -M path     where to locate installer for scot private modules
        -D          delete target install directory before beginning install
        -d          restart scot daemons (scepd and scfd)
        -E          reset the Elasticsearch DB
        -r          delete existing SCOT Database (DATA LOSS POTENTIAL)
        -s          Install SCOT only, skip prerequisites (upgrade SCOT)
        -u          same as -s
EOF
    exit 1
}
