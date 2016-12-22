#!/bin/bash

function ensure_elastic_entry {

    APT_ES_LIST="/etc/apt/sources.list.d/elasticsearch-2.x.list"
    ES_GPG="https://packages.elastic.co/GPG-KEY-elasticsearch"
    YUM_REPO="/etc/yum.repos.d/elasticsearch.repo"

    echo "-- ensuring elastic repo entries"

    if [[ $OS == "Ubuntu" ]]; then
        if [[ ! -e $APT_ES_LIST ]]; then
            wget -qO - $ES_GPG | sudo apt-key add -
            if [[ $? -gt 0 ]]; then
                wget --no-check-certificate -qO - $ES_GPG | sudo apt-key add -
                if [[ $? -gt 0 ]]; then
                    echo "!!!!"
                    echo "!!!! Failed to get ElasticSearch GPG key! "
                    echo "!!!! You will need to fix this to sucessfully install"
                    echo "!!!! SCOT."
                    echo "!!!!"
                    exit 2
                fi
            fi
            echo "-- grabbed ElasticSearch GPG key"
            echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee $APT_ES_LIST
        else
            echo "-- $APT_ES_LIST exists"
        fi
    else
        if grep --quiet elastic $YUM_REPO; then
            echo "-- $YUM_REPO exists"
        else
            echo "-- creating $YUM_REPO"
            cat <<-EOF > $YUM_REPO
[elasticsearch-2.x]
name=Elasticsearch repository for 2.x packages
baseurl=https://packages.elastic.co/elasticsearch/2.x/centos
gpgcheck=1
gpgkey=$ES_GPG
enabled=1
EOF
        fi
    fi
}

function create_se_init {
    ES_SYSD=/etc/systemd/system/elasticsearch.service
    ES_SYSD_SRC=$DEVDIR/src/systemd/elasticsearch.service
    ES_INIT=/etc/init.d/elasticsearch
    ES_INIT_SRC=$DEVDIR/src/elasticsearch/elasticsearch

    echo "-- installing init scripts"

    if [[ $OS == "Ubuntu" ]]; then
        if [[ $OSVERSION == "16" ]]; then
            if [[ ! -e $ES_SYSD ]]; then
                echo "-- installing $ES_SYD from $ES_SYSD_SRC"
                cp $ES_SYSD_SRC $ES_SYSD
            else
                echo "-- $ES_SYD aleady present"
            fi
        else
            if [[ ! -e $ES_INIT ]]; then
                echo "-- installing $ES_INIT_SRC to $ES_INIT"
                cp $ES_INIT_SRC $ES_INIT
            else 
                echo "-- $ES_INIT already present"
            fi
            echo "-- updating rc.d files"
            update-rc.d elasticsearch defaults
        fi
    else
        if [[ ! -e $ES_INIT ]]; then
            echo "-- installing $ES_INIT_SRC to $ES_INIT"
            cp $ES_INIT_SRC $ES_INIT
        else
            echo "-- $ES_INIT already present."
        fi
        echo "-- chkconfig adding elasticsearch"
        chkconfig --add elasticsearch
    fi
}

function install_elasticsearch {

    echo "---"
    echo "--- Installing ElasticSearch"
    echo "---"

#    echo "-- installing JDK"
#    if [[ $OS ==  "Ubuntu" ]]; then
#        apt-get install -y openjdk-7-jdk
#    else
#        yum install java-1.7.0-openjdk -y
#    fi

    ensure_elastic_entry

    if [[ $OS == "Ubuntu" ]]; then
        apt-get-update
        apt-get install -y elasticsearch
    else 
        yum -y install elasticsearch
    fi
    create_es_init

    if [[ $RESET_ES_DB == "yes" ]]; then
        . $DEVDIR/src/elasticsearch/mapping.sh
    fi


    if [[ $OS == "Ubuntu" ]]; then
        if [[ $OSVERSION == "16" ]]; then
            ES_SERVICE="/etc/systemd/system/elasticsearch.service"
            ES_SERVICE_SRC="$DEVDIR/../install/src/elasticsearch/elasticsearch.service"
            if [[ ! -e $ES_SERVICE ]]; then
                echo "- installing $ES_SERVICE"
                cp $ES_SERVICE_SRC $ES_SERVICE
            fi
            systemctl daemon-reload
            systemctl restart elasticsearch.service
        else
            echo "-- adding elasticsearch to rc.d"
            update-rc.d elasticsearch defaults
            echo "-- restarting elasticsearch"
            service elasticsearch restart
        fi
    else
        echo "-- adding elasticsearch to rc.d"
        chkconfig --add elasticsearch
        echo "-- restarting elasticsearch"
        sevice elasticsearch restart
    fi

}
