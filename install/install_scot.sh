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
        echo "+ creating Log dir $LOGDIR"
        mkdir -p $LOGDIR
    fi

    echo "= ensuring proper log ownership/permissions"
    chown scot.scot $LOGDIR
    chmod g+w $LOGDIR

    if [ "$CLEARLOGS"  == "yes" ]; then
        echo -e "${red}- clearing any existing scot logs${NC}"
        for i in $LOGDIR/*; do
            cat /dev/null > $i
        done
    fi

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
}

function install_scot {
    
    echo "---"
    echo "--- Installing SCOT software"
    echo "---"

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
    cp -r $DEVDIR/../* $SCOTDIR

    echo "-- assigning owner/permissions on $SCOTDIR"
    chown -R scot:scot $SCOTDIR
    chmod -R 755 $SCOTDIR/bin

    get_config_files    
    configure_logging
    
}
