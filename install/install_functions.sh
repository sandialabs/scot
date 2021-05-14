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
        read -p "Ctrl-C to quit, enter to continue..." proxyfoo
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
        read -p "Ctrl-C to quit, enter to continue..." proxyfoo
    fi
    SPROXY=$(printenv https_proxy)
}

function check_no_proxy {
    if [[ "$PROXY" != "" ]] || [[ "$SPROXY" != "" ]]; then
        no_proxy_setting=$(printenv no_proxy)
        if [[ -z $no_proxy_setting ]]; then
            echo "!!! You have a proxy environment variable set, but have "
            echo "!!! not set your \"no_proxy\" environment variable"
            echo "!!! recommend adding the following to your environment "
            echo "!!!    export no_proxy=localhost,127.0.0.1"
            echo "!!!"
            export no_proxy=localhost,127.0.0.1
        fi
    fi
}

function get_script_src_dir () {
    SRCDIR="${BASH_SOURCE%/*}"
    if [[ ! -d "$DIR" ]]; then
        SRCDIR="$PWD"
    fi
}

function determine_distro {
    get_script_src_dir
    local cmd=$SRCDIR/install/determine_distro.sh
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

function wait_for_mongo {
    COUNTER=0
    grep -q 'waiting for connections on port' /var/log/mongodb/mongod.log
    while [[ $? -ne 0 && $COUNTER -lt 50 ]]; do
        sleep 1
        let COUNTER+=1
        echo "~ waiting for mongo to initialize ($COUNTER seconds have passed)"
        grep -q 'waiting for connections on port' /var/log/mongodb/mongod.log
    done

    if [[ $? -ne 0 ]]; then
        echo "!!!! Mongod failed to start. Please fix and restart mongod "
        echo "!!!! Unless mongod is running, you will get an error attempting"
        echo "!!!! to access SCOT!"
    fi
}


function start_services {
    AMQSTATUS=`ps -ef | grep -v grep | grep activemq`
    if [[ $? != 0 ]]; then
        $AMQDIR/bin/activemq start
    fi

    if [[ $OS == "Ubuntu" ]]; then
        if [[ $OSVERSION == "18" ]]; then
            systemctl daemon-reload
            systemctl restart mongod.service
            wait_for_mongo
            systemctl --no-pager restart scot.service
            systemctl --no-pager restart apache2.service
            systemctl --no-pager restart scf2d.service
            systemctl --no-pager restart scrfd.service
            systemctl --no-pager restart scepd.service
            systemctl --no-pager restart recfpd.service
        elif [[ $OSVERSION == "16" ]]; then
            systemctl daemon-reload
            systemctl restart mongod.service
            wait_for_mongo
            systemctl --no-pager restart scot.service
            systemctl --no-pager restart apache2.service
            systemctl --no-pager restart scf2d.service
            systemctl --no-pager restart scrfd.service
            systemctl --no-pager restart scepd.service
            systemctl --no-pager restart recfpd.service
        else 
            service mongod restart
            wait_for_mongo
            service scot restart
            service apache2 restart
            service scf2d restart
            service scrfd restart
            service scepd restart
            service restart recfpd.service
        fi
    else
        # it appears that centos 7.3 is systemd 
        systemctl daemon-reload
        systemctl --no-pager restart mongod.service
        wait_for_mongo
        systemctl --no-pager restart scot.service
        systemctl --no-pager restart httpd.service
        systemctl --no-pager restart scfd.service
        systemctl --no-pager restart scrfd.service
        systemctl --no-pager restart scepd.service
        systemctl --no-pager restart recfpd.service
    fi
}
