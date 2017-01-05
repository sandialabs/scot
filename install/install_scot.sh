#!/bin/bash

function add_scot_user {
    echo "- checking for existing scot user"
    if grep --quiet -c scot: /etc/password; then
        echo "- scot user exists"
    else
        useradd -c "SCOT User" -d $SCOTDIR -M -s /bin/bash scot
    fi
    
    if [[ $OS == "Ubuntu" ]]; then
        APACHE_GROUP="www-data"
    else
        APACHE_GROUP="apache"
    fi
    echo "- adding scot to $APACHE_GROUP group"
    usermod -a -G scot $APACHE_GROUP
}

function configure_logging {
    if [ ! -d $LOGDIR ]; then
        echo "- creating Log dir $LOGDIR"
        mkdir -p $LOGDIR
    fi

    echo "- ensuring proper log ownership/permissions of $LOGDIR"
    chown scot:scot $LOGDIR
    chmod g+w $LOGDIR

    if [ "$CLEARLOGS"  == "yes" ]; then
        for i in $LOGDIR/*; do
            echo "- clearing log $i"
            cat /dev/null > $i
        done
    fi

    echo "- creating $LOGDIR/scot.log"
    touch $LOGDIR/scot.log
    chown scot:scot $LOGDIR/scot.log

    if [ ! -e /etc/logrotate.d/scot ]; then
        echo "+ installing logrotate policy"
        cp $DEVDIR/src/logrotate/logrotate.scot /etc/logrotate.d/scot
    else 
        echo "= logrotate policy in place"
    fi
}

function get_config_files {
    echo "-- examining config files"
    CFGFILES='
        mongo
        logger
        imap
        activemq
        enrichments
        flair.app
        flair_logger
        stretch.app
        stretch_logger
        game.app
        elastic
        backup
    '
    for file in $CFGFILES; do
        CFGDEST="$SCOTDIR/etc/${file}.cfg"
        CFGSRC="$DEVDIR/src/scot/${file}.cfg"
        if [[ -e $CFGDEST ]]; then
            echo "- config file $file already exists"
        else
            echo "- copying $CFGSRC to $CFGDEST"
            cp $CFGSRC $CFGDEST
        fi
    done

    if [[ $AUTHMODE == "Remoteuser" ]]; then
        cp $DEVDIR/../install/src/scot/scot_env.remoteuser.cfg $SCOTDIR/etc/scot_env.cfg
    else
        cp $DEVDIR/../install/src/scot/scot_env.local.cfg $SCOTDIR/etc/scot_env.cfg
    fi

}

function copy_documentation {
    echo "--"
    echo "-- Installing documentation"
    echo "--"
    cp -r $DEVDIR/../docs/build/html/* $SCOTDIR/public/docs
    echo "-- Documentation now available at https://localhost/docs/index.html"
}

function configure_startup {
    echo "--"
    echo "-- configuring SCOT startup"
    echo "--"
    SCOTSERVICES='scot scfd scepd'
    SRCDIR="$DEVDIR/../install/src/scot"

    for service in $SCOTSERVICES; do
        if [[ $OS == "Ubuntu" ]]; then
            if [[ $OSVERSION == "16" ]]; then
                sysfile="${service}.service"
                target="/etc/systemd/system/$sysfile"
                if [[ "$REFRESH_INIT" == "yes" ]]; then
                    rm -f $target
                fi
                if [[ ! -e $target ]]; then
                    echo "-- installing $target"
                    cp $SRCDIR/$sysfile $target
                else
                    echo "-- $target exists, skipping..."
                fi
                systemctl daemon-reload
                systemctl enable $sysfile
            else
                if [[ "$REFRESH_INIT" == "yes" ]]; then
                    rm -f /etc/init.d/$service
                fi
                if [[ ! -e /etc/init.d/$service ]]; then
                    if [[ $service == "scot" ]]; then
                        echo "-- installing /etc/init.d/scot"
                        cp $SRCDIR/scot-init /etc/init.d/scot
                        chmod +x /etc/init.d/scot
                        sed -i 's=instdir='$SCOTDIR'=g' /etc/init.d/scot
                    else
                        echo "-- install /etc/init.d/$service"
                        /opt/scot/bin/${service}.pl > /etc/init.d/$service
                        chmod +x /etc/init.d/$service
                    fi
                fi
                echo "-- updating rc.d for $service"
                update-rc.d $service defaults
            fi
        else
            # echo "-- chkconfig adding $service"
            # chkconfig --add $service
            sysfile="${service}.service"
            target="/etc/systemd/system/$sysfile"
            if [[ "$REFRESH_INIT" == "yes" ]]; then
                rm -f $target
            fi
            if [[ ! -e $target ]]; then
                echo "-- installing $target"
                cp $SRCDIR/$sysfile $target
            else
                echo "-- $target exists, skipping..."
            fi
            systemctl daemon-reload
            systemctl enable $sysfile
        fi
    done
}

function install_scot {
    
    echo "---"
    echo "--- Installing SCOT software"
    echo "---"
    add_scot_user

    if [[ $DELDIR == "true" ]]; then
        echo "-- removing $SCOTDIR prior to install"
        rm -rf $SCOTDIR
    fi

    if [[ ! -d $SCOTDIR ]]; then
        echo "-- creating $SCOTDIR"
        mkdir -p $SCOTDIR
        chown scot:scot $SCOTDIR
        chmod 754 $SCOTDIR
    fi

    echo "-- copying SCOT to $SCOTDIR"
    #cp -r $DEVDIR/.. $SCOTDIR
    TAROPTS="--exclude=pubdev --exclude-vcs"
    echo "-       TAROPTS are $TAROPTS"
    (cd $DEVDIR/..; tar $TAROPTS -cf - .) | (cd $SCOTDIR; tar xvf -)

    echo "-- assigning owner/permissions on $SCOTDIR"
    chown -R scot:scot $SCOTDIR
    chmod -R 755 $SCOTDIR/bin

    get_config_files    
    configure_logging
    copy_documentation
    configure_startup
}
