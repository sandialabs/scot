#!/bin/bash

function ensure_elastic_entry {

    if [[ "$SCOT_CONFIG_SRC" == "" ]];then
        SCOT_CONFIG_SRC="$DEVDIR/install/src"
    fi

    if [[ "$ES_APT_LIST" == "" ]]; then
        ES_APT_LIST="/etc/apt/sources.list.d/elasticsearch-2.x.list"
    fi

    if [[ "$ES_GPG" == "" ]]; then
        # ES_GPG="https://packages.elastic.co/GPG-KEY-elasticsearch"
        ES_GPG="https://artifacts.elastic.co/GPG-KEY-elasticsearch"
    fi

    if [[ "$ES_YUM_REPO" == "" ]]; then
        ES_YUM_REPO="/etc/yum.repos.d/elasticsearch.repo"
    fi

    echo "-- ensuring elastic repo entries"

    if [[ $OS == "Ubuntu" ]]; then
        if [[ ! -e $ES_APT_LIST ]]; then
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
            echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee $ES_APT_LIST
        else
            echo "-- $ES_APT_LIST exists"
        fi
    else
        echo "-importing signing key"
        rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
        if grep --quiet elastic $ES_YUM_REPO; then
            echo "-- $ES_YUM_REPO exists"
        else
            echo "-- creating $ES_YUM_REPO"
# 2.x series
#            cat <<-EOF > $ES_YUM_REPO
#[elasticsearch-2.x]
#name=Elasticsearch repository for 2.x packages
#baseurl=https://packages.elastic.co/elasticsearch/2.x/centos
#gpgcheck=1
#gpgkey=$ES_GPG
#enabled=1
#EOF
            cat <<-EOF > $ES_YUM_REPO
[elasticsearch-5.x]
name=Elasticsearch repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
        fi
    fi
}

function create_se_init {
    ES_SYSD=/etc/systemd/system/elasticsearch.service
    ES_SYSD_SRC=$SCOT_CONFIG_SRC/systemd/elasticsearch.service
    ES_INIT=/etc/init.d/elasticsearch
    ES_INIT_SRC=$SCOT_CONFIG_SRC/elasticsearch/elasticsearch

    echo "-- installing init scripts"

    if [[ $OS == "Ubuntu" ]]; then
        if [[ $OSVERSION == "18" ]] || [[ $OSVERSION == "20" ]]; then
            if [[ ! -e $ES_SYSD ]]; then
                echo "-- installing $ES_SYD from $ES_SYSD_SRC"
                cp $ES_SYSD_SRC $ES_SYSD
            else
                echo "-- $ES_SYD aleady present"
            fi
        elif [[ $OSVERSION == "16" ]]; then
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

    ensure_elastic_entry

    if [[ $OS == "Ubuntu" ]]; then
        apt-get-update
        apt-get install -y apt-transport-https
        apt-get install -y elasticsearch
    else 
        yum -y install elasticsearch
    fi


    if [[ $OS == "Ubuntu" ]]; then
        if [[ $OSVERSION == "18" ]] || [[ $OSVERSION == "20" ]]; then
            systemctl daemon-reload
            systemctl enable elasticsearch.service
            systemctl --no-pager restart elasticsearch.service
        elif [[ $OSVERSION == "16" ]]; then
            # looks like this happens from the installer
            # ES_SERVICE="/etc/systemd/system/elasticsearch.service"
            # ES_SERVICE_SRC="$SCOT_CONFIG_SRC/elasticsearch/elasticsearch.service"
            # if [[ ! -e $ES_SERVICE ]]; then
            #     echo "- installing $ES_SERVICE"
            #     cp $ES_SERVICE_SRC $ES_SERVICE
            # fi
            systemctl daemon-reload
            systemctl enable elasticsearch.service
            systemctl --no-pager restart elasticsearch.service
        else
            echo "-- adding elasticsearch to rc.d"
            update-rc.d elasticsearch defaults
            echo "-- restarting elasticsearch"
            service elasticsearch restart
        fi
    else
        systemctl daemon-reload
        systemctl enable elasticsearch.service
        systemctl --no-pager start elasticsearch.service
    fi

    echo "~~~ pausing for a few seconds to allow ES to spin up"
    sleep 5


    echo "~~~ attempting to query localhost:9200 for scot index"
    if curl -i -f -XHEAD http://localhost:9200/scot | grep -q 404; then
        echo "-- need to init elastic search DB"
        ES_RESET_DB="yes"
    else
        echo "-- index for scot already works"
    fi

    if [[ $ES_RESET_DB == "yes" ]]; then
        echo "-- creating elasticsearch mappings..."
        . $SCOT_CONFIG_SRC/elasticsearch/mapping.sh
    fi

}


