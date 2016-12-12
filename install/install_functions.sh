#!/bin/bash

function set_defaults () {
    DEVDIR="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd )"
    PRIVATE_SCOT_MODULES="$DEVDIR/../Scot-Internal-Modules"
    FILESTORE="/opt/scotfiles";
    SCOTDIR="/opt/scot"
    SCOTROOT="/opt/scot"
    SCOTINIT="/etc/init.d/scot"
    SCOTPORT=3000
    FILESTORE="/opt/scotfiles"
    INSTALL_LOG="/tmp/scot.install.log"
    TESTURL="http://getscot.sandia.gov"
    BACKUPDIR="/sdb/scotbackup"        
    GEOIPDIR="/usr/local/share/GeoIP"
    DBDIR="/var/lib/mongodb"
    CPANM="/usr/local/bin/cpanm --mirror-only --mirror https://stratopan.com/toddbruner/Scot-deps/master"
    LOGDIR="/var/log/scot";
    AMQDIR="/opt/activemq"
    AMQTAR="apache-activemq-5.13.2-bin.tar.gz"
    AMQURL="https://repository.apache.org/content/repositories/releases/org/apache/activemq/apache-activemq/5.13.2/$AMQTAR"
    REFRESHAPT="yes"            # turn off with -a or -s
    DELDIR="yes"                # delete the $SCOTDIR prior to installation
    NEWINIT="yes"               # install a new $SCOTINIT
    OVERGEO="no"                # overwrite the GeoIP database
    MDBREFRESH="yes"            # install new Mongod.conf and restart
#MDBREFRESH="no"             # overwrite an existing mongod config
    INSTMODE="all"              # install everything or just SCOTONLY 
    RESETDB="no"                # delete existing scot db
    SFILESDEL="no"              # delete existing filestore directory and contents
    CLEARLOGS="no"              # clear the logs in $LOGDIR
    REFRESH_AMQ_CONFIG="no"     # install new config for activemq and restart
    AUTHMODE="Local"            # authentication type to use
    DEFAULFILE=""               # override file for all the above
# DBCONFIGJS="./config.custom.js"   # initial config data you entered for DB
    REFRESHAPACHECONF="no"      # refresh the apache config for SCOT
    SKIPNODE="no"               # skip the node/npm/grunt stuff
}

sub process_command_line () {
    echo -e "${yellow}~~~~~ Reading Command Line Args ~~~~~~~${nc}"
    while getopts "adigmsrflqA:F:J:wNb:" opt; do
        case $opt in
            a)  
                echo -e "${red} --- do not refresh apt repositories ${nc}"
                REFRESHAPT="no"
                ;;
            b)
                BACKUPDIR=$OPTARG
                echo -e "${yellow} --- Setting Backup directory to $BACKUPDIR ${nc}"
                ;;
            d)
                echo -e "${red} --- do not delete installation directory $SCOTDIR";
                echo -e "${nc}"
                DELDIR="no"
                ;;
            i) 
                echo -e "${red} --- do not overwrite $SCOTINIT ${nc}"
                NEWINIT="no"
                ;;
            g)
                echo -e "${red} --- overwrite existing GeoCity DB ${nc}"
                OVERGEO="yes"
                ;;
            m)
                echo -e "${red} --- do not overwrite mongodb config and restart ${nc}"
                MDBREFRESH="no"
                ;;
            s)
                echo -e "${green} --- INSTALL only SCOT software ${nc}"
                MDBREFRESH="no"
                INSTMODE="SCOTONLY"
                REFRESHAPT="no"
                NEWINIT="no"
                RESETDB="no"
                SFILESDEL="no"
                ;;
            r)
                echo -e "${red} --- will reset SCOTDB (DATA LOSS!)"
                RESETDB="yes"
                ;;
            f) 
                echo -e "${red} --- delete SCOT filestore $FILESTORE (DATA LOSS!) ${nc}"
                SFILESDEL="yes"
                ;;
            l)
                echo -e "${red} --- zero existing log files (DATA LOSS!) ${nc}"
                CLEARLOGS="yes"
                ;;
            q)
                echo -e "${red} --- refresh ActiveMQ config and init files ${nc}"
                REFRESH_AMQ_CONFIG="yes"
                ;;
            A)
                AUTHMODE=$OPTARG
                echo -e "${green} --- AUTHMODE set to ${AUTHMODE} ${nc}"
                ;;
            F)
                DEFAULTFILE=$OPTARG
                echo -e "${green} --- Loading Defaults from $DEFAULTFILE ${nc}"
                . $DEFALTFILE
                ;;
            #J)
            #    DBCONFIGJS=$OPTARG
            #    echo -e "${green} --- Loading Config into DB from $DBCONFIGJS ${nc}"
            #    ;;
            w)
                REFRESHAPACHECONF="yes"
                echo -e "${red} --- overwriting exist SCOT apache config ${nc}"
                ;;
            N)
                SKIPNODE="yes"
                echo -e "${yellow} --- skipping NODE/NPM/Grunt instal/build ${nc}"
                ;;
            \?)
                echo -e "${yellow} !!!! INVALID option -$OPTARG ${nc}";
                cat << EOF

    Usage: $0 [-abigmsrflq] [-A mode] 

        -a      do not attempt to perform an "apt-get update"
        -d      do not delete $SCOTDIR before installation
        -i      do not overwrite an existing $SCOTINIT file
        -g      Overwrite existing GeoCitiy DB
        -m      Overwrite mongodb config and restart mongo service
        -s      SAFE SCOT. Only instal SCOT software, do not refresh apt, do not
                    overwrite $SCOTINIT, do not reset db, and 
                    do not delete $FILESTORE
        -r      delete SCOT database (will result in data loss!)
        -f      delete $FILESTORE directory and contents ( again, data loss!)
        -l      truncate logs in $LOGDIR (potential data loss)
        -q      install new activemq config, apps, initfiles and restart service
        -w      overwrite existing SCOT apache config files
        
        -A mode     mode = Local | Ldap | Remoteuser
                    default is Remoteuser (see docs for details)
EOF
                exit 1;
                ;;
        esac
    done
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
    PROXY=$(printenv https_proxy)
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
    # output is of format:
    # ${OS} ${DIST} ${REV} (${PSUEDONAME} ${KERNEL} ${MACH})
    DISTRO=`echo $output | cut -d ' ' -f 2`
}

function ensure_lsb_installed {
    if [[ -z $DISTRO ]]; then
        determine_distro
    fi
    if [[ $DISTRO == "RedHat" ]]; then
        if ! hash lsb_release 2>/dev/null
        then
            yum install redhat-lsb
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
    blue='\e[0;34m'
    green='\e[0;32m'
    yellow='\e[0;33m'
    red='\e[0;31m'
    nc='\033[0m'
}

function root_check {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${red} This script must be run as root!${nc}"
        exit 1;
    fi
    return 0;
}

function configure_accounts {

    echo -e "${yellow}= Checking for activemq user ${nc}"
    AMQ_USER=`grep -c activemq: /etc/passwd`
    if [ $AMQ_USER -ne 1 ]; then
        echo -e "${green}+ adding activemq user ${nc}"
        useradd -c "ActiveMQ User" -d $AMQDIR -M -s /bin/bash activemq
    else
        echo -e "${green}= activemq exists ${nc}"
    fi

    echo -e "${yellow}= Checking for scot user ${nc}"
    SCOT_USER=`grep -c scot: /etc/passwd`
    if [ $SCOT_USER -ne 1 ]; then
        echo -e "${green}+ adding scot user ${nc}"
        useradd -c "SCOT User" -d $SCOTDIR -M -s /bin/bash scot
    fi

}

function apt-get-update {
    apt-get update 2>&1 > /dev/null
}

function install_packages {
    echo "${yellow}+ Installing Packages${nc}"
    if [[ $OS == "Ubuntu" ]]
    then
        if [[ $REFRESHAPT == "yes" ]]
        then
            echo "${green}+ Refreshing APT DB Repo"
            apt-get-update
            if [ $? != 0 ];
                echo "${red}! Error refreshing the Apt db repository!"
                exit 2;
            fi
        fi
        echo "${green}+ installing apt packages"
        for pkg in `cat $DEVDIR/install/ubuntu_debs_list`
        do
            apt-get -y install $pkg
        done
    else
        # so later perl packages can compile
        yum -y install openssl-devel
        echo "+ adding line to allow unverifyed ssl in yum"
        echo "sslverify=false" >> /etc/yum.conf

        echo "+ installing rpms..."
        for pkg in `cat $DEVDIR/install/rpms_list`; do
            echo "+ package = $pkg";
            yum install $pkg -y
        done
    fi
}

function install_perl_modules {

}

function install_nodejs {

}

function ensure_mongo_apt_entry {
    KEYSERVERURL="hkp://keyserver.ubuntu.com:80"
    KEYNUMBER="EA312927"
    if grep --quiet mongo /etc/apt/sources.list; then
        echo "= mongo entry in /etc/apt/sources.list already present"
    else
        if grep --quiet 10gen /etc/apt/sources.list
            echo "= 10gen mongo repo already present in /etc/apt/sources.list"
        else
            echo "+ adding Mongo 10Gen repo to /etc/apt/sources.list"
        fi
        if [[ -z $PROXY ]]
        then
            echo "- not using proxy to add Mondo 10Gen key"
            KEYOPTS=""
        else
            KEYOPTS="--keyserver-options http-proxy=$PROXY"
        fi
        if [[ $OSVERSION == "16" ]]
        then
            userepo="xenial"
        else 
            userepo="trusty"
        fi
        echo "deb http://repo.mongodb.org/apt/ubuntu $userepo/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list
    fi
}

function ensure_mongo_yum_entry {
    if grep --quiet mongo /etc/yum.repos.d/mongodb.repo; then
        echo "= mongo yum stanza present"
    else
        echo "+ adding mongo to yum repos"
        cat <<- EOF > /etc/yum.repos.d/mongodb.repo
[mongodb-org-3.2]
name=MongoDB Repository
baseurl=http://repo.mongodb.org/yum/redhat/$OSVERSION/mongodb-org/3.2/x86_64/
gpgcheck=0
enabled=1
EOF
    fi
}


function install_mongodb {
    echo "+ installing mongodb-org"
    if [[ $OS == "Ubuntu" ]] 
    then
        ensure_mongo_apt_entry
        apt-get-update
        apt-get -y install mongodb-org
    else 
        ensure_mongo_yum_entry
        yum -y insall mongodb-org
    fi
}

function ensure_eleastic_apt_entry {
    EAE="/etc/apt/sources.list.d/elasticsearch-2.x.list"
    if [[ ! -e $EAE ]]
    then
        wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
        if [ $? -gt 0 ]; then
            echo "~ failed to grap elastic GPC-KEY, could be SSL problem"
            wget --no-check-certificate -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
            if [ $? -gt 0 ]; then
                echo "${red}!!! Elasticsearch totally failed install.  "
                echo "!!! Reason: failure to key GPG key.  You will have to manually "
                echo "!!! fix this condition for Search to work in SCOT"
            fi
        fi
        echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a $EAE
    fi
}

function ensure_elastic_yum_entry {
    if grep --quiet eleastic /etc/yum.repos.d/elasticsearch.repo; then
        echo "= elastic search stanza present"
    else 
        echo "+ adding elastic search to yum repos"
        cat <<- EOF > /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-2.x]
name=Elasticsearch repository for 2.x packages
baseurl=https://packages.elastic.co/elasticsearch/2.x/centos
gpgcheck=1
gpgkey=https://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1
EOF
    fi
}

function install_elasticsearch {
    echo "+ installing elasticsearch"
    if [[ $OS == "Ubuntu" ]]
    then
        ensure_elastic_apt_entry
        apt-get-update
        apt-get -y install elasticsearch
    else
        ensure_elastic_yum_entry
        yum -y install elasticsearch
    fi
}

function install_activemq {
    echo -e "${yellow}+ installing ActiveMQ${nc}"

    if [ -e "$AMQDIR/bin/activemq" ]; then
        echo "= activemq already installed"
    else
        if [ ! -e /tmp/$AMQTAR ]; then
            echo "= downloading $AMQURL"
            # curl -o /tmp/apache-activemq.tar.gz $AMQTAR
            wget -P /tmp $AMQURL 
        fi
        if [ ! -d $AMQDIR ];then
            mkdir -p $AMQDIR
            chown -R activemq.activemq $AMQDIR
        fi
        tar xf /tmp/$AMQTAR --directory /tmp
        mv /tmp/apache-activemq-5.13.2/* $AMQDIR
    fi


    echo -e "${yellow}= checking activemq logging directories ${nc}"
    if [ ! -d /var/log/activemq ]; then
        echo "${green}+ creating /var/log/activemq ${nc}"
        mkdir -p /var/log/activemq
        touch /var/log/activemq/scot.amq.log
        chown -R activemq.activemq /var/log/activemq
        chmod -R g+w /var/log/activemq
    fi

    if [ $REFRESH_AMQ_CONFIG == "yes" ] || ! [ -d $AMQDIR/webapps/scot ] ; then
        echo "+ adding/refreshing scot activemq config"
        echo "- removing $AMQDIR/webapps/scot"
        rm -rf $AMQDIR/webapps/scot

        echo "- removing $AMQDIR/webapps/scotaq"
        rm -rf $AMQDIR/webapps/scotaq

        echo "+ copying scot xml files into $AMQDIR/conf"
        cp $DEVDIR/etcsrc/scotamq.xml     $AMQDIR/conf
        cp $DEVDIR/etcsrc/jetty.xml       $AMQDIR/conf

        echo "+ copying $DEVDIR/etcsrc/scotaq to $AMQDIR/webapps"
        cp -R $DEVDIR/etcsrc/scotaq       $AMQDIR/webapps

        echo "+ renaming $AMQDIR/webapps/scotaq to $AMQDIR/webapps/scot"
        mv $AMQDIR/webapps/scotaq      $AMQDIR/webapps/scot
        cp $DEVDIR/etc/init/activemq-init   /etc/init.d/activemq
        chmod +x /etc/init.d/activemq
        chown -R activemq.activemq $AMQDIR
    fi
}

function get-rev-proxy-config {
    REVPROXY=$DEVDIR/etcsrc/scot-revproxy-$MYHOSTNAME
    local SASRC="scot-revproxy-ubuntu-remoteuser.conf"
    if [[ ! -e $REVPROXY ]]
    then
        echo -e "${red}- custom scot configuration for $MYHOSTNAME not found, using default"
        if [[ $AUTHMODE == "RemoteUser" ]];
        then
            if [[ -e $PRIVATE_SCOT_MODULE/etc/$SASRC ]]
            then
                REVPROXY=$PRIVATE_SCOT_MODULE/etc/$SASRC
            else 
                REVPROXY=$DEVDIR/etcsrc/apache2/$SASRC
            fi
        else
            SASRC="scot-revproxy-ubuntu-aux.conf"
            if [[ -e $PRIVATE_SCOT_MODULE/etc/$SASRC ]]
            then
                REVPROXY=$PRIVATE_SCOT_MODULE/etc/$SASRC
            else 
                REVPROXY=$DEVDIR/etcsrc/apache2/$SASRC
            fi
        fi
    fi
}

function ubuntu-apache-configure {
    ACD="/etc/apache2"
    SITESENABLED="$ACD/sites-enabled"
    SITESAVAILABLE="$ACD/sites-available"

    if [[ $REFRESHAPACHECONF == "yes"]]
    then
        rm -f $SITESENABLED/scot.conf
        rm -f $SITESAVAILABLE/scot.conf
    fi

    if [[ -e $SITESENABLED/000-default.conf ]]
    then
        rm -f $SITESENABLED/000-default.conf
    fi

    MYMODS="proxy proxy_http ssl headers rewrite authnz_ldap"
    for m in $MYMODS
    do
        echo "+ enabling $m"
        a2enmod -q $m
    done

    if [[ ! -e $SITESAVAILABLE/scot.conf ]] 
    then
        echo -e "${yellow}+ adding scot apache configuration ${nc}"
        get-rev-proxy-config

}

function cent-apache-configure {

}

function configure_apache {
    echo -e "${yellow}= Configuring Apache ${nc}"
    MYHOSTNAME=`hostname`

    if [[ $OS == "Ubuntu" ]]
    then
        ubuntu-apache-configure
    else
        cent-apache-configure
    fi
}

function configure_geoip {

}


function configure_startup {

}

function configure_filestore {

}

function configure_backup {

}

function install_scot {

}

function configure_scot {

}

function install_private {

}

funtion configure_logging {

}

function configure_mongodb {

}

function start_services {

}
