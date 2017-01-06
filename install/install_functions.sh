#!/bin/bash

function proceed () {
    if [[ $INTERACTIVE == 'yes' ]]; then
        read -p 'continue? [ctr-c to quit] ' FOO
        if [[ $FOO == "Y" ]]; then
            INTERACTIVE="no"
        fi
    fi
}

function backup_file {
    local ext=`date +%s`
    cp $1 $1.$ext
}

function perl_version_check {
    local PVER=`perl -e 'print $];'`
    local PTAR="5.018"
    local COMP=`echo $PVER'>'$PTAR | bc -l`
    if [[ $COMP == 1 ]];then
        echo -e "${green} Yea! A modern perl! ${nc}"
    else 
        echo -e "${red} Your Perl is out of date.  Upgrade to 5.18 or better ${nc}"
        echo "== See installation docs in docs/source/install.rst for instructions on how to install new perl"
        exit 1
    fi
}


function get_http_proxy () {
    echo "~~~~~ Determining http Proxy settings"
    http_proxy_setting=$(printenv http_proxy)
    echo "http_proxy  = $http_proxy_setting"
    if [[ -z $http_proxy_setting ]];then
        echo "!!! http_proxy not set! if you are behind a proxy, install will "
        echo "!!! likely fail.  If you are using \"sudo\" to install use the "
        echo "!!! \"-E\" option to preserve your environment variables"
        exit 1;
    fi
    PROXY=$(printenv http_proxy)
}

function get_https_proxy () {
    https_proxy_setting=$(printenv https_proxy)
    echo "https_proxy = $https_proxy_setting"
    if [[ -z $https_proxy_setting ]];then
        echo "!!! https_proxy not set! if you are behind a proxy, install may "
        echo "!!! encounter problems.  If you are using \"sudo\" to install "
        echo "!!! use the \"-E\" option to preserve your environment variables"
        exit 1;
    fi
    SPROXY=$(printenv https_proxy)
}

function get_script_src_dir () {
    SRCDIR="${BASH_SOURCE%/*}"
    if [[ ! -d "$DIR" ]]; then
        SRCDIR="$PWD"
    fi
}

function determine_distro {
    get_script_src_dir
    local cmd=$SRCDIR/determine_distro.sh
    echo "running $cmd"
    local output=`$cmd`
    echo -e "${blue} DISTRO: $output ${nc}"
    # output is of format:
    # ${OS} ${DIST} ${REV} (${PSUEDONAME} ${KERNEL} ${MACH})
    DISTRO=`echo $output | cut -d ' ' -f 2`
}

function ensure_lsb_installed {
    if [[ -z $DISTRO ]]; then
        determine_distro
    fi
    if [[ $DISTRO == "RedHat" ]]; then
        yum update -y
        if ! hash lsb_release 2>/dev/null
        then
            echo "!!! lsb_release not found, installing Redhat/Cent lsb"
            yum install -y redhat-lsb 
        fi
    fi
}

function get_os_name {
    ensure_lsb_installed
    OS=`lsb_release -i | cut -s -f 2`
}

function get_os_version {
    ensure_lsb_installed
    OSVERSION=`lsb_release -r | cut -s -f2 | cut -d. -f 1`
}

function set_ascii_colors {
    echo "+ Setting ascii color codes"
    blue='\e[0;34m'
    echo -e "${blue} Information"
    green='\e[0;32m'
    echo -e "${green} Sucess message"
    yellow='\e[0;33m'
    echo -e "${yellow} warning message"
    red='\e[0;31m'
    echo -e "${red} error message"
    nc='\033[0m'
    echo -e "${nc}"
}

function root_check {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${red} This script must be run as root!${nc}"
        exit 1;
    fi
    return 0;
}

function apt-get-update {
    apt-get update 2>&1 > /dev/null
}


function install_geoip {
    echo -e "${blue} Installing Geoip from Maxmind ${nc}"

    if [[ $OS == "Ubuntu" ]]; then
        if [[ $OSVERSION == "14" ]]; then
            if [[ ! -e /etc/apt/sources.list.d/maxmind-ppa-trusty.list ]]; then
                add-apt-repository 'deb http://ppa.launchpad.net/maxmind/ppa/ubuntu trusty main' 
                add-apt-repository 'deb-src http://ppa.launchpad.net/maxmind/ppa/ubuntu trusty main' 
            fi
        else 
            add-apt-repository 'deb http://ppa.launchpad.net/maxmind/ppa/ubuntu xenial main' 
            add-apt-repository 'deb-src http://ppa.launchpad.net/maxmind/ppa/ubuntu xenial main' 
        fi
       apt-get-update
       apt-get install -y libgeoip-dev libmaxminddb0 libmaxminddb-dev mmdb-bin
    else
        yum install -y GeoIP
    fi
}

function configure_geoip {
    local SDIR=$DEVDIR/src/geoip
    if [[ -e $GEODIR/GeoLiteCity.dat ]]; then 
        if [[ $OVERGEO == "yes" ]]; then
            local BCKUP=GeoLiteCity.dat.$$
            echo -e "${red}- overwriting existing GeoLiteCity.dat file (original backed to $BCKUP ${nc}"
            cp $GEODIR/GeoLiteCity.dat $GEODIR/$BCKUP
            cp $SDIR/GeoLiteCity.dat $GEODIR/GeoLiteCity.dat
        fi
    else 
        echo -e "${green}+ copying GeoLiteCity.dat file ${nc}"
        cp $SDIR/GeoLiteCity.dat $GEODIR/GeoLiteCity.dat
        chmod +r $GEODIR/GeoLiteCity.dat
    fi
}

function configure_filestore {
    echo -e "${yellow} Checking SCOT filestore $FILESTORE ${nc}"

    if [ "$SFILESDEL" == "yes" ]; then
        echo -e "${red}- removing existing filestore${nc}"
        if [ "$FILESTORE" != "/" ] && [ "$FILESTORE" != "/usr" ]
        then
            # try to prevent major catastrophe!
            echo " WARNING: You are about to delete $FILESTORE.  ARE YOU SURE? "
            read -n 1 -p "Enter y to proceed" NUKEIT
            if [[ $NUKEIT == "y" ]];
            then
                rm -rf  $FILESTORE
            else
                echo -e "${green} $FILESTORE deletion aborted.${nc}"
            fi
        else
            echo -e "${RED} Someone set filestore to /, so deletion skipped.${nc}"
        fi
    fi

    if [ -d $FILESTORE ]; then
        echo "= filestore directory exists";
    else
        echo "+ creating new filestore directory"
        mkdir -p $FILESTORE
    fi

    echo "= ensuring proper ownership and permissions of $FILESTORE"
    chown scot $FILESTORE
    chgrp scot $FILESTORE
    chmod g+w $FILESTORE
}

function configure_backup {
    if [ -d $BACKDIR ]; then
        echo "= backup directory $BACKDIR exists"
    else 
        echo "+ creating backup directory $BACKDIR "
        mkdir -p $BACKUPDIR
        mkdir -p $BACKUPDIR/mongo
        mkdir -p $BACKUPDIR/elastic
        chown -R scot:scot $BACKUPDIR
        chown -R elasticsearch:elasticsearch $BACKUPDIR/elastic
    fi
}

function install_scot {
    if [ "$DELDIR" == "true" ]; then
        echo -e "${red}- removing target installation directory $SCOTDIR ${NC}"
        rm -rf $SCOTDIR
    fi

    if [ ! -d $SCOTDIR ]; then
        echo -e "+ creating $SCOTDIR";
        mkdir -p $SCOTDIR
        chown scot:scot $SCOTDIR
        chmod 754 $SCOTDIR
    fi

    chown -R scot.scot $SCOTDIR
    chmod -R 755 $SCOTDIR/bin

}

function install_private {
    if [ -d "$PRIVATE_SCOT_MODULES" ]; then
        echo "Private SCOT modules and config directory exist.  Installing..."
        . $PRIVATE_SCOT_MODULES/install.sh
    fi
}


function start_mongo {
    if [[ $OS == "Ubuntu" ]]; then
        if [[ $OSVERSION == "16" ]]; then
            systemctl restart mongod.service
        else
            service mongod restart
        fi
    else
        service mongod start
    fi
}

function wait_for_mongo {
    COUNTER=0
    grep -q 'waiting for connections on port' /var/log/mongod.log
    while [[ $? -ne 0 && $COUNTER -lt 50 ]]; do
        sleep 1
        let COUNTER+=1
        echo "~ waiting for mongo to initialize ($COUNTER seconds have passed)"
        grep -q 'waiting for connections on port' /var/log/mongod.log
    done
}


function start_services {
    AMQSTATUS=`ps -ef | grep -v grep | grep activemq`
    if [[ $? != 0 ]]; then
        $AMQDIR/bin/activemq start
    fi

    if [[ $OS == "Ubuntu" ]]; then
        if [[ $OSVERSION == "16" ]]; then
            systemctl daemon-reload
            start_mongo
            wait_for_mongo
            systemctl restart scot.service
            systemctl restart apache2.service
            systemctl restart scfd.service
            systemctl restart scepd.service
        else 
            /etc/init.d/scot restart
            service apache2 restart
            service scfd restart
            service scepd restart
        fi
    else
        # it appears that centos 7.3 is systemd 
        systemctl daemon-reload
        start_mongo
        wait_for_mongo
        systemctl restart scot.service
        systemctl restart apache2.service
        systemctl restart scfd.service
        systemctl restart scepd.service
    fi
}
