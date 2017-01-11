#!/bin/bash

function default_variables {
    PRIVATE_SCOT_MODULES="$DEVDIR/../Scot-Internal-Modules"
    FILESTORE="/opt/scotfiles"
    SCOTDIR="/opt/scot"
    SCOTROOT="/opt/scot"
    SCOTPORT=3000
    BACKUPDIR="/opt/scotbackup"
    LOGDIR="/var/log/scot"
    SCOT_CONFIG_SRC="$DEVDIR/install/src"
    SCOT_DOCS_SRC="$DEVDIR/docs/build/html"
    SCOT_RESTART_DAEMONS="no"

    AMQDIR="/opt/activemq"
    AMQTAR="apache-activemq-5.13.2-bin.tar.gz"
    AMQURL="https://repository.apache.org/content/repositories/releases/org/apache/activemq/apache-activemq/5.13.2/$AMQTAR"
    AMQ_CONFIGS="$DEVDIR/src/ActiveMQ/amq"

    ES_APT_LIST="/etc/apt/sources.list.d/elasticsearch-2.x.list"
    ES_GPG="https://packages.elastic.co/GPG-KEY-elasticsearch"
    ES_YUM_REPO="/etc/yum.repos.d/elasticsearch.repo"
    ES_RESET_DB="yes"

    MONGO_KEYSRVR="--keyserver hkp://keyserver.ubuntu.com:80"
    MONGO_KEY="EA312927"
    MONGO_KEY_OPTS="--keyserver-options http-proxy=$PROXY"
    MONGO_SOURCE_LIST="/etc/apt/sources.list.d/mongo-org-3.2.list"
    MONGO_YUM_REPO="/etc/yum.repos.d/mongodb.repo"
    MONGO_REFESH_CONF="yes"

    AUTHMODE="Local"
    INSTMODE="ALL"
    RESETDB="no"
    REFRESHREPOS="yes"
    DELDIR="no"

}


function process_commandline {
    options="A:M:Ddprsu"
    while getopts $options opt; do
        case $opt in
            A)
                AUTHMODE=$OPTARG
                ;;
            D) 
                DELDIR="yes"
                ;;
            d)
                SCOT_RESTART_DEAMONS="yes"
                ;;
            e)
                ES_RESET_DB="no"
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
                INSTMODE="SCOTONLY"
                RESETDB="no"
                REFRESHREPOS="no"
                MONGO_REFRESH_CONFIG="no"
                ;;
            s)
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

    Usage: $0 [-A mode] [-M path] [-dersu]

        -A mode     where mode = (default) "Local", "Ldap", or "Remoteuser" 
        -M path     where to locate installer for scot private modules
        -D          delete target install directory before beginning install
        -d          restart scot daemons (scepd and scfd)
        -e          reset the Elasticsearch DB
        -r          delete existing SCOT Database (DATA LOSS POTENTIAL)
        -s          Install SCOT only, skip prerequisites (upgrade SCOT)
        -u          same as -s
EOF
    exit 1
}
