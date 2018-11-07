#!/bin/bash

function configure_geoip {
    
    GEO_SRC_DIR="$DEVDIR/install/src/geoip"
    GEO_DB_DIR="/usr/local/share/GeoIP"
    GEO_LITE="$GEO_DB_DIR/GeoLiteCity.dat"
    if [[ -e "$GEO_LITE" ]]; then
        if [[ "$GEO_DB_OVERWRITE" == "yes" ]]; then
            echo "-- overwriting existing $GEO_LITE"
            backup_file $GEO_LITE
            cp $GEO_SRC_DIR/GeoLiteCity.dat $GEO_LITE
        else
            echo "-- not overwriting existing $GEO_LITE"
        fi
    else
        echo "-- creating $GEO_LITE"
        cp $GEO_SRC_DIR/GeoLiteCity.dat $GEO_LITE
        chmod +r $GEO_LITE
    fi
}

function install_geoip {

    echo "--- installing geoip from maxmind"

    if [[ $OS == "Ubuntu" ]];then
        MAXMINDURL="http://ppa.launchpad.net/maxmind/ppa/ubuntu"
        U_DEB_REPO="deb $MAXMINDURL"
        U_DEB_SRC_REPO="deb-src $MAXMINDURL"

        if [[ $OSVERSION == "18" ]];then
            code_name="bionic"
        if [[ $OSVERSION == "16" ]];then
            code_name="xenial"
        else
            code_name="trusty"
        fi

        MMREPO="$U_DEB_REPO $codename main"
        MMREPOS="$U_DEB_SRC_REPO $codename main"

        add-apt-repository "$MMREPO"
        add-apt-repository "$MMREPOS"
        apt-get update
        apt-get install -y libgeoip-dev libmaxminddb0 libmaxminddb-dev mmdb-bin
    else 
        yum install -y GeoIP
    fi

    configure_geoip
}

