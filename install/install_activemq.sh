#!/bin/bash

function install_activemq {

    echo "---"
    echo "--- Installing ActiveMQ"
    echo "---"

    echo "-- checking for activemq user and group"
    AMQ_USER=`grep -c activemq: /etc/passwd`
    if [[ $AMQ_USER != "1" ]]; then
        echo "-- adding activemq user"
        useradd -c "ActiveMQ User" -d $AMQDIR -M -s /bin/bash activemq
    else
        echo "-- activemq user exists"
    fi

    AMQ_GROUP=`grep -c activemq: /etc/group`
    if [[ $AMQ_GROUP != "1" ]]; then
        echo "-- adding activemq group"
        groupadd activemq
    fi

    if [[ -e $AMQDIR/bin/activemq ]]; then
        echo "-- activemq appears to already be installed"
    else
        if [[ ! -e /tmp/$AMQTAR ]]; then
            echo "-- activemq tar file not present, attemping download"
            wget -P /tmp $AMQURL

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
        mv /tmp/apche-activemq-5.13.2/* $AMQDIR
    fi

    if [[ ! -d /var/log/activemq ]]; then
        echo "-- creating /var/log/activemq for logging"
        mkdir -p /var/log/activemq
        touch /var/log/activemq/scot.amq.log
        chown -R activemq.activemq /var/log/activemq
        chmod -R g+w /var/log/activmq
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

    AMQ_CONFIGS=$DEVDIR/src/ActiveMQ/amq

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
    cp $AMQ_CONFIGS/activemq-init /etc/init.d/activmq
    chmod +x /etc/init.d/activemq

    echo "-- ensuring proper ownership"
    chown -R activemq.activemq $AMQDIR

    echo "-- installation of ActiveMQ complete, starting..."
    /etc/init.d/activemq start

    echo "-- you will need to verify that process is running"
    echo "-- ps -ef | grep activemq"

}
