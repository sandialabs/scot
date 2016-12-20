#!/bin/bash

function proceed () {
    if [[ $INTERACTIVE == 'yes' ]]; then
        read -p 'continue? [ctr-c to quit] ' FOO
        if [[ $FOO == "Y" ]]; then
            INTERACTIVE="no"
        fi
    fi
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

function process_command_line () {
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

function configure_accounts {

    echo -e "${blue}= Checking for activemq user ${nc}"
    AMQ_USER=`grep -c activemq: /etc/passwd`
    if [ $AMQ_USER -ne 1 ]; then
        echo -e "${green}+ adding activemq user ${nc}"
        useradd -c "ActiveMQ User" -d $AMQDIR -M -s /bin/bash activemq
    else
        echo -e "${green}= activemq exists ${nc}"
    fi

    echo -e "${blue}= Checking for scot user ${nc}"
    SCOT_USER=`grep -c scot: /etc/passwd`
    if [ $SCOT_USER -ne 1 ]; then
        echo -e "${green}+ adding scot user ${nc}"
        useradd -c "SCOT User" -d $SCOTDIR -M -s /bin/bash scot
        if [[ $OS == "Ubuntu" ]]; then
            usermod -a -G scot www-data
        else
            usermod -a -G scot apache
        fi
    fi

}

function apt-get-update {
    apt-get update 2>&1 > /dev/null
}

function install_packages {
    echo -e "${yellow}+ Installing Packages${nc}"
    if [[ $OS == "Ubuntu" ]]
    then
        if [[ $REFRESHAPT == "yes" ]]
        then
            echo -e "${green}+ Refreshing APT DB Repo ${nc}"
            apt-get-update
            if [ $? != 0 ];
            then
                echo -e "${red}! Error refreshing the Apt db repository!"
                exit 2;
            fi
        fi
        echo -e "${green}+ installing apt packages"
        for pkg in `cat $DEVDIR/packages/ubuntu_debs_list`
        do
            apt-get -y install $pkg
        done
    else
        # so later perl packages can compile
        yum -y install openssl-devel
        echo "+ adding line to allow unverifyed ssl in yum"
        echo "sslverify=false" >> /etc/yum.conf

        echo "+ installing rpms..."
        for pkg in `cat $DEVDIR/packages/rpms_list`; do
            echo "+ package = $pkg";
            yum install $pkg -y
        done
    fi
}

function install_perl_modules {
    echo -e "${blue}++++++++++ PERL module Installation +++++++++++${nc}"
    echo -e "${blue}= installing pre-compiled package perl libs${nc}"
    if [[ $OS == "Ubuntu" ]]; then
        PREPACKFILES=$DEDVIR/packages/perl_debs_list
    else
        PREPACKFILES=$DEVDIR/packages/perl_yum_list
    fi

    for $prepack in `cat $PREPACKFILES`
    do
        echo -e "${green}+ adding $prepack ${nc}"
        if [[ $OS == "Ubuntu" ]]; then
           apt-get install $prepack -y
        else
            yum -y install $prepack
        fi
    done

    echo -e "${green} Updating CPANMinus ${nc}"

    echo -e "${red} removing old cpanm ${nc}"
    if [[ $OS == "Ubuntu" ]]; then
        apt-get remove cpanminus -y
    else
        yum -y remove perl-App-cpanminus
    fi


    CPANM="/usr/local/bin/cpanm"

    if [[ ! -e $CPANM ]]; 
    then
        echo -e "${green} installing latest cpanminus ${nc}"
        curl -L http://cpanmin.us | perl - --sudo App::cpanminus

        if [[ ! -e $CPANM ]]; 
        then
            echo -e "${red}!!!! $CPANM not found!  SCOT will not install properly without $CPANM"
            echo    "!!!! As root try: curl -L http://cpanmin.us | perl - --sudo App::cpanminus "
            echo -e "!!!! again. Once sucessfully installed restart scot install {$nc} "
            exit 3
        fi
    fi

    for modules in `cat $DEVDIR/packages/perl_modules_list`
    do
        echo -e "${green} 1st Attempt to install $module"
        $CPANM $module
        if [ $? == 1]; then
            echo -e "${red} 1st attemp to install $module failed will retry once more ${nc}"
            RETRY="$RETRY $module"
        fi
        echo ""
    done

    for module in $RETRY
    do
        echo -e "${green} 2nd Attempt to install $module"
        $CPANM $module
        if [ $? == 1]; then
            echo -e "${red} 2nd attempt to install $module failed.  You are likely to "
            echo -e " encouter problems with SCOT until this is fixed. ${nc}"
            FAILED="$FAILED $module"
        fi
        echo ""
    done

    echo -e "${red} ============ FAILED PERL MODULES ================== ";
    for module in $FAILED
    do
        echo "     $module"
    done
    echo -e "${nc} "
}

function install_nodejs {
    if [[ $OS == "Ubuntu" ]]
    then
        if [ $SKIPNODE == "no" ]; then
            echo "+ installing nodejs"
            curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
            apt-get install -y nodejs
        fi
    else
        if [ $SKIPNODE == "no" ]; then
            echo "+ installing nodejs"
            curl --silent --location https://rpm.nodesource.com/setup_4.x | bash -
            yum -y install nodejs
        fi
    fi
}

function ensure_mongo_apt_entry {
    echo -e "${blue} - ensuring mongo 10gen apt entry ${nc}"
    KEYSERVERURL="hkp://keyserver.ubuntu.com:80"
    KEYNUMBER="EA312927"
    if grep --quiet mongo /etc/apt/sources.list; then
        echo "= mongo entry in /etc/apt/sources.list already present"
    else
        if grep --quiet 10gen /etc/apt/sources.list
        then
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

        echo -e "${blue} grabbing mongo key ${nc}"
        apt-key adv $KEYOPTS $KEYSERVERURL -recv-keys $KEYNUMBER

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

function install_geoip {
    echo -e "${blue} Installing Geoip from Maxmind ${nc}"

    if [[ $OS == "Ubuntu" ]]; then
        if [[ $OSVERSION == "14" ]]; then
            if [[ ! -e /etc/apt/sources.list.d/maxmind-ppa-trusty.list ]]; then
                add-apt-repository 'deb http://ppa.launchpad.net/maxmind/ppa ubuntu trusty main' 
                add-apt-repository 'deb-src http://ppa.launchpad.net/maxmind/ppa ubuntu trusty main' 
            fi
        else 
            add-apt-repository 'deb http://ppa.launchpad.net/maxmind/ppa ubuntu xenial main' 
            add-apt-repository 'deb-src http://ppa.launchpad.net/maxmind/ppa ubuntu xenial main' 
        fi
       apt-get-update
       apt-get install -y libmaxminddb0 libmaxminddb-dev mmdb-bin
    else
        yum install -y GeoIP
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
        local AMQSRC=$DEVDIR/src/ActiveMQ
        cp $AMQSRC/amq/scotamq.xml     $AMQDIR/conf
        cp $AMQSRC/amq/jetty.xml       $AMQDIR/conf

        echo "+ copying $AMQSRC/amq/scotaq to $AMQDIR/webapps"
        cp -R $AMQSRC/amq/scotaq       $AMQDIR/webapps

        echo "+ renaming $AMQDIR/webapps/scotaq to $AMQDIR/webapps/scot"
        mv $AMQDIR/webapps/scotaq      $AMQDIR/webapps/scot
        cp $AMQSRC/amq//activemq-init   /etc/init.d/activemq
        chmod +x /etc/init.d/activemq
        chown -R activemq.activemq $AMQDIR
    fi
}

function get-ubuntu-rev-proxy-config {
    local SDIR=$DEVDIR/src/apache2
    REVPROXY=$SDIR/scot-revproxy-$MYHOSTNAME
    local SASRC="scot-revproxy-ubuntu-remoteuser.conf"
    if [[ ! -e $REVPROXY ]]
    then
        echo -e "${red}- custom scot configuration for $MYHOSTNAME not found, using default ${nc}"
        if [[ $AUTHMODE == "RemoteUser" ]];
        then
            if [[ -e $PRIVATE_SCOT_MODULE/etc/$SASRC ]]
            then
                REVPROXY=$PRIVATE_SCOT_MODULE/etc/$SASRC
            else 
                REVPROXY=$SDIR/$SASRC
            fi
        else
            SASRC="scot-revproxy-ubuntu-aux.conf"
            if [[ -e $PRIVATE_SCOT_MODULE/etc/$SASRC ]]
            then
                REVPROXY=$PRIVATE_SCOT_MODULE/etc/$SASRC
            else 
                REVPROXY=$SDIR/$SASRC
            fi
        fi
    fi
    echo "= REVPROXY set to $REVPROXY"
}

function get-cent-7-proxy-config {
    local SARC="scot-revproxy-rh-7-remoteuser.conf"
    local SDIR=$DEVDIR/src/apache2
    if [[ $AUTHMODE == "RemoteUser" ]];
    then
        if [[ -e $PRIVATE_SCOT_MODULES/etc/$SARC ]]
        then
            REVPROXY=$PRIVATE_SCOT_MODULES/etc/$SARC
        else 
            REVPROXY=$SDIR/scot-revproxy-rh-7-remoteuser.conf
        fi
    else
        if [[ -e $PRIVATE_SCOT_MODULES/etc/apache2/scot-revproxy-rh-7-aux.conf ]];
        then
            REVPROXY=$PRIVATE_SCOT_MODULES/etc/apache2/scot-revproxy-rh-7-aux.conf
        else
            REVPROXY=$SDIR2/scot-revproxy-rh-7-aux.conf
        fi
    fi
    echo "= REVPROXY set to $REVPROXY"
}

function get-cent-6-proxy-config {
    local SARC="scot-revproxy-rh-remoteuser.conf"
    local SDIR=$DEVDIR/src/apache2
    if [[ $AUTHMODE == "RemoteUser" ]];
    then
        if [[ -e $PRIVATE_SCOT_MODULES/etc/$SARC ]]
        then
            REVPROXY=$PRIVATE_SCOT_MODULES/etc/$SARC
        else 
            REVPROXY=$SDIR/scot-revproxy-rh-remoteuser.conf
        fi
    else
        if [[ -e $PRIVATE_SCOT_MODULES/etc/apache2/scot-revproxy-rh-aux.conf ]];
        then
            REVPROXY=$PRIVATE_SCOT_MODULES/etc/apache2/scot-revproxy-rh-aux.conf
        else
            REVPROXY=$SDIR2/scot-revproxy-rh-aux.conf
        fi
    fi
    echo "= REVPROXY set to $REVPROXY"
}

function get-cent-rev-proxy-config {
    REVPROXY=$DEVDIR/src/apache2/scot-revproxy-$MYHOSTNAME
    if [[ ! -e $REVPROXY ]];
    then
        echo -e "${red}- custom scot config for $MYHOSTNAME not found using default ${nc}"
        if [[ $OSVERSION == "7" ]];
        then
            get-cent-7-proxy-config
        else
            get-cent-6-proxy-config
        fi
    fi
}

function generate_ssl {
    echo -e "${green}+ creating SSL certificates (CHANGE these ASAP)"
    SSLDIR="/etc/apache2/ssl"
    if [[ ! -f $SSLDIR/scot.key ]]; then
        mkdir -p $SSLDIR/ssl/
        openssl genrsa 2048 > $SSLDIR/scot.key
        openssl req -new -key $SSLDIR/scot.key \
                    -out /tmp/scot.csr \
                    -subj '/CN=localhost/O=SCOT Default Cert/C=US'
        openssl x509 -req -days 36530 \
                     -in /tmp/scot.csr
                     -signkey $SSLDIR/scot.key \
                     -out $SSLDIR/scot.crt
    fi
}

function update_scot_apache_conf {
    local CONFDIR=$CENT_HTTP_CONF_DIR
    if [[ $OS == "Ubuntu" ]];
    then
        CONFDIR=$SITESAVAILABLE
    fi
    echo -e "${yellow}~ modifying scot.conf to local defaults ${nc}"
    sed -i 's=/scot/document/root='$SCOTROOT'/public=g' $CONFDIR/scot.conf
    sed -i 's=localport='$SCOTPORT'=g' $CONFDIR/scot.conf
    sed -i 's=scot\.server\.tld='$MYHOSTNAME'=g' $CONFDIR/scot.conf
}

function ubuntu-apache-configure {
    ACD="/etc/apache2"
    SITESENABLED="$ACD/sites-enabled"
    SITESAVAILABLE="$ACD/sites-available"

    if [[ $REFRESHAPACHECONF == "yes" ]]
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
        get-ubuntu-rev-proxy-config
    fi
    cp $REVPROXY $SITESAVAILABLE/scot.conf
    ln -sf $SITESAVAILABLE/scot.conf $SITESENABLED/scot.conf

    update_scot_apache_conf
    generate_ssl
}

function cent-apache-configure {
    echo "+ Enabling apache to do network connections"
    setsebool -P httpd_can_network_connect 1

    CENT_HTTP_CONF_DIR=/etc/httpd/conf.d

    echo "- Renaming existing conf file in $CENT_HTTP_CONF_DIR"

    for FILE in $CENT_HTTP_CONF_DIR/*.conf
    do
        if [[ $FILE != "$CENT_HTTP_CONF_DIR/scot.conf" ]];
        then
            mv $FILE $FILE.bak
        else
            if [[ $REFRESHAPACHECONF == "YES" ]];
            then
                mv $FILE $FILE.bak
            fi
        fi
    done
    get-cent-rev-proxy-config
    echo -e "${green}+ copying scot.conf to apache ${nc}"
    cp $REVPROXY $CENT_HTTP_CONF_DIR/scot.conf
    
    update_scot_apache_conf
    generate_ssl
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

function copy_documentation {
    echo "+ installing SCOT docmentation at https://localhost/docs/index.html"
    cp -r $DEVDIR/docs/build/html/* $SCOTDIR/public/docs
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

function configure_ubuntu_startup {
    local SDIR=$DEVDIR/src/systemd
    if [[ $OSVERSION == "16" ]]; then
        SYSDSERVICES='
            elasticsearch.service 
            scot.service 
            scfd.service 
            scepd.service 
            mongod.service
        '
        for service in $SYSDSERVICES
        do
            if [[ ! -e /etc/systemd/system/$service ]];
            then
                if [[ -e $SDIR/$service ]]; then
                    cp $SDIR/$service /etc/systemd/system/$service
                else
                    echo "- warning: $SDIR/$service not present"
                fi
            fi
            systemctl enable $service
            # systemctl restart $service do this in start services
        done
    else
        update-rc.d elasticsearch defaults
        update-rc.d scot defaults
        update-rc.d activemq defaults
        update-rc.d scepd defaults
        update-rc.d scfd defaults
    fi
}

function configure_cent_startup {
    echo "+ adding startup scripts"
    chkconfig --add elasticsearch
    chkconfig --add scot
    chkconfig --add activemq
    chkconfig --add mongod
    chkconfig --add scepd
    chkconfig --add scfd

    echo "+ Allowing Firewalld to pass web traffic"
    firewall-cmd --permanent --add-port=80/tcp
    firewall-cmd --permanent --add-port=443/tcp
    firewall-cmd --reload
}

function configure_startup {
    local SDIR=$DEVDIR/src
    if [[ ! -e /etc/init.d/scot ]]; then
        echo -e "${yellow} adding /etc/init.d/scot ${nc}"
        cp $SDIR/scot/scot-init /etc/init.d/scot
        chmod +x /etc/init.d/scot
        sed -i 's=/instdir='$SCOTDIR'=g' /etc/init.d/scot
    fi

    if [ ! -e /etc/init.d/scfd ]; then
        echo -e "${red} Missing INIT for SCot Flair Daemon ${NC}"
        echo -e "${yellow}+ adding /etc/init.d/scfd...${NC}"
        /opt/scot/bin/scfd.pl get_init_file > /etc/init.d/scfd
        chmod +x /etc/init.d/scfd
    fi

    if [ ! -e /etc/init.d/scepd ]; then
        echo -e "${red} Missing INIT for SCot ES Push Daemon ${NC}"
        echo -e "${yellow}+ adding /etc/init.d/scepd...${NC}"
        /opt/scot/bin/scepd.pl get_init_file > /etc/init.d/scepd
        chmod +x /etc/init.d/scepd
    fi

    if [[ $OS == "Ubuntu" ]]; then
        configure_ubuntu_startup
    else 
        configure_cent_startup
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

function configure_scot {
    local SDIR=$DEVDIR/src/scot
    if [[ $AUTHMODE == "Remoteuser" ]]; then
        cp $SDIR/scot_env.remoteuser.cfg $SCOTDIR/etc/scot_env.cfg
    else 
        if [[ ! -e $SCOTDIR/etc/scot_env.cfg ]]; then
            echo "+ copying scot_env.cfg into $SCOTDIR/etc"
            cp $SDIR/scot_env.local.cfg $SCOTDIR/etc/scot_env.cfg
        else
            echo "= scot_env.cfg already present, skipping..."
        fi
    fi

    CFGFILES='mongo logger imap activemq enrichments flair.app 
             flair_logger stretch.app stretch_logger game.app elastic
             backup'

    for file in $CFGFILES
    do
        CFGDEST="$SCOTDIR/etc/$file.cfg"
        if [[ -e $CFGDEST ]]; then
            echo "= $CFGDEST already present, skipping..."
        else
            CFGSRC="$SDIR/$file.cfg"
            echo "+ copying $CFGSRC to $CFGDEST"
            cp $CFGSRC $CFGDEST
        fi
    done
}

function install_private {
    if [ -d "$PRIVATE_SCOT_MODULES" ]; then
        echo "Private SCOT modules and config directory exist.  Installing..."
        . $PRIVATE_SCOT_MODULES/install.sh
    fi
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

function add_failIndexKeyTooLong {

    echo "= checking failIndexKeyTooLong Mongod parameter"

    local SDIR=$DEVDIR/src/mongodb
    if [[ $OSVERSION == "16" ]]; then
        FIKTL=`grep failIndexKeyTooLong /lib/systemd/system/mongod.service`
        if [ "$FIKTL" == "" ]; then
            echo "- SCOT will fail unless failIndexKeyTooLong=false in /lib/systemd/system/mongod.service"
            echo "+ backing orig, and copying new into place. "
            ext=`date +%s`
            cp /lib/systemd/system/mongod.service /tmp/mongod.service.backup.$ext
            cp $SDIR/systemd-mongod.conf /lib/systemd/system/mongod.service
            cp $MDCDIR/mongod.conf $MDCDIR/mongod.conf.$ext
            cp $SDIR/mongod.conf $MDCDIR/mongod.conf
        else 
            echo "~ appears that failIndexKeyTooLong is in /lib/systemd/system/mongod.service"
        fi
    else 
        FIKTL=`grep failIndexKeyTooLong /etc/init/mongod.conf`
        if [ "$FIKTL" == "" ]; then
            echo "- SCOT will fail unless failIndexKeyTooLong=false in /etc/init/mongod.conf"
            echo "+ backing orig, and copying new into place. "
            MDCDIR="/etc/init/"
            cp $MDCDIR/mongod.conf $MDCDIR/mongod.conf.bak
            cp $SDIR/init-mongod.conf $MDCDIR/mongod.conf
        else
            echo "~ appears the parameter is set in mongod config"
        fi
    fi
}

function configure_mongodb {
    echo "= Configuring MongoDB"
    echo "= Stopping MongoDB"
    local SDIR=$DEVDIR/src/mongodb

    if [[ $OSVERSION == "16" ]]; then
        systemctl stop mongod.service
    else
        service mongod stop
    fi

    local COPYFILE=$SDIR/init-mongod.conf

    if [[ $OS == "Ubuntu" ]]; then
        if [[ $OSVERSION == "16" ]]; then
            MDCDIR="/etc"
            COPYFILE=$SDIR/mongod.conf
        else 
            MDCDIR="/etc/init"
            COPYFILE=$SDIR/init-mongod.conf
        fi
    else
        MDCDIR="/etc/init"
        COPYFILE=$SDIR/init-mongod.conf
    fi

    if [[ $MDBREFRESH == "yes" ]]; then
        echo "+ backup up mongod.conf"
        cp $MDCDIR/mongod.conf $MDCDIR/mongod.conf.$$
        echo "+ coping $COPYFILE to $MCDIR"
        cp $COPYFILE $MCDIR
        add_failIndexKeyTooLong
    fi

    if [[ ! -d $DBDIR ]]; then
        echo "+ creating db dir $DBDIR"
        mkdir -p $DBDIR
    fi

    echo "+ ensuring proper ownership of $DBDIR"
    chown -R mongodb:mongodb $DBDIR

    echo "- clearing /var/log/mongod/monod.log"
    cat /dev/null > /var/log/mongodb/mongod.log

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
        /etc/init.d/scot restart
        service apache2 restart
        service scfd restart
        service scepd restart
    fi
}
