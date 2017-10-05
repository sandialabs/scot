#!/bin/bash

function install_activemq {

    if [[ "$SCOT_CONFIG_SRC" == "" ]];then
        SCOT_CONFIG_SRC="$DEVDIR/install/src"
    fi

    if [[ "$AMQDIR" == "" ]]; then
        AMQDIR="/opt/activemq"
    fi

    if [[ "$AMQTAR" == "" ]]; then
        AMQTAR="apache-activemq-5.13.2-bin.tar.gz"
    fi

    if [[ "$AMQURL" == "" ]]; then
        AMQURL="https://repository.apache.org/content/repositories/releases/org/apache/activemq/apache-activemq/5.13.2/$AMQTAR"
    fi

    if [[ "$AMQ_CONFIGS" == "" ]]; then
        AMQ_CONFIGS="$SCOT_CONFIG_SRC/ActiveMQ/amq"
    fi

    echo "---"
    echo "--- Installing ActiveMQ"
    echo "--- AMQDIR = $AMQDIR"
    echo "--- AMQTAR = $AMQTAR"
    echo "--- AMQURL = $AMQURL"
    echo "--- CONFIGS= $AMQ_CONFIGS"
    echo "---"

    echo "-- checking for activemq user and group"
    AMQ_GROUP=`grep -c activemq: /etc/group`
    if [[ $AMQ_GROUP != "1" ]]; then
        echo "-- adding activemq group"
        groupadd activemq
    fi

    AMQ_USER=`grep -c activemq: /etc/passwd`
    if [[ $AMQ_USER != "1" ]]; then
        echo "-- adding activemq user"
        useradd -M -c "ActiveMQ User" -d $AMQDIR -g activemq -s /bin/bash activemq
    else
        echo "-- activemq user exists"
    fi


    if [[ -e $AMQDIR/bin/activemq ]]; then
        echo "-- activemq appears to already be installed"
    else
        if [[ ! -e /tmp/$AMQTAR ]]; then
            echo "-- activemq tar file not present, attemping download"
            wget --no-check-certificate -P /tmp $AMQURL

            if [[ ! -e /tmp/$AMQTAR ]]; then
                echo "-- download may have failed! trying packaged tar"
                cp $DEVDIR/install/src/ActiveMQ/apache-activemq-5.14-20151229.032504-18-bin.tar.gz /tmp
            fi

            if [[ ! -d $AMQDIR ]]; then
                echo "-- $AMQDIR does not exist, creating..."
                mkdir -p $AMQDIR
                chown -R activemq.activemq $AMQDIR
            fi
        fi

        tar xf /tmp/$AMQTAR --directory /tmp
        mv /tmp/apache-activemq-5.13.2/* $AMQDIR
    fi

    if [[ ! -d /var/log/activemq ]]; then
        echo "-- creating /var/log/activemq for logging"
        mkdir -p /var/log/activemq
        touch /var/log/activemq/scot.amq.log
        chown -R activemq /var/log/activemq
        chgrp -R activemq /var/log/activemq
        chmod -R g+w /var/log/activemq
    else
        echo "-- logging directory /var/log/activemq exists"
    fi

    if [[ $REFRESH_AMQ_CONFIG == "yes" ]]; then
        echo "-- Command Line Flag set to remove existing AMQ SCOT config"
        rm -rf $AMQDIR/webapps/scot
        rm -rf $AMQDIR/webapps/scotaq
        rm -f $AMQDIR/conf/scotamq.xml
        rm -f $AMQDIR/conf/jetty.xml
    fi


    if [[ ! -d /$AMQDIR/webapps/scot ]]; then
        echo "-- installing scot webapp for activemq"
        cp -R $AMQ_CONFIGS/scotaq $AMQDIR/webapps
        mv $AMQDIR/webapps/scotaq $AMQDIR/webapps/scot
    else
        echo "-- webapp already present"
    fi

    if [[ ! -d /$AMQDIR/webapps/conf/scotamq.xml ]]; then
        echo "-- installing SCOT xml files into $AMQDIR/conf"
        cp $AMQ_CONFIGS/scotamq.xml $AMQDIR/conf
    else
        echo "-- scotamq.xml already present"
    fi

    if [[ ! -d /$AMQDIR/webapps/conf/jetty.xml ]]; then
        echo "-- installing SCOT jetty.xml files into $AMQDIR/conf"
        cp $AMQ_CONFIGS/jetty.xml $AMQDIR/conf
    else
        echo "-- jetty.xml already present"
    fi

    echo "-- installing /etc/init.d/activemq"
    cp $AMQ_CONFIGS/activemq-init /etc/init.d/activemq
    chmod +x /etc/init.d/activemq

    echo "-- ensuring proper ownership"
    chown -R activemq.activemq $AMQDIR

    if [[ $OS == "Ubuntu" ]]; then
        if [[ $OSVERSION == "16" ]]; then
            AMQ_SYSTEMD="/etc/systemd/system/activemq.service"
            AMQ_SYSTEMD_SRC="$SCOT_CONFIG_SRC/ActiveMQ/activemq.service"
            if [[ ! -e $AMQ_SYSTEMD ]]; then
                echo "-- installing $AMQ_SYSTEMD"
                cp $AMQ_SYSTEMD_SRC $AMQ_SYSTEMD
            else
                echo "-- $AMQ_SYSTEMD exists, skipping..."
            fi
            systemctl daemon-reload
            systemctl enable activemq.service
        else
            update-rc.d activemq defaults
        fi
    else
        # although this appears to work stil
        # chkconfig --add activemq
        # centos 7 appears to be systemd 
        AMQ_SYSTEMD="/etc/systemd/system/activmq.service"
        AMQ_SYSTEMD_SRC="$SCOT_CONFIG_SRC/ActiveMQ/activemq.service"
        if [[ ! -e $AMQ_SYSTEMD ]]; then
            echo "-- installing $AMQ_SYSTEMD"
            cp $AMQ_SYSTEMD_SRC $AMQ_SYSTEMD
        else
            echo "-- $AMQ_SYSTEMD exists, skipping..."
        fi
        systemctl daemon-reload
        systemctl enable activemq.service
    fi

    echo "-- installation of ActiveMQ complete, starting..."
    if [[ $OS == "Ubuntu" ]]; then
        if [[ $OSVERSION == "16" ]]; then
            systemctl start activemq.service
        else
            /etc/init.d/activemq start
        fi
    else
        systemctl start activemq.service
    fi

    echo "-- you will need to verify that process is running"
    echo "-- ps -ef | grep activemq"

}
