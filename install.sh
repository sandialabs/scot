#!/bin/bash
#
# SCOT installer
#

# color output formatting
blue='\e[0;34m'
green='\e[0;32m'
yellow='\e[0;33m'
red='\e[0;31m'
NC='\033[0m'

echo -e "${blue}########"
echo           "######## SCOT 3 Installer"
echo           "######## Support at: scot-dev@sandia.gov"
echo -e        "########${NC}"

if [[ $EUID -ne 0 ]]; then
    echo -e "${red}This script must be run as root or using sudo!${NC}"
    exit 1
fi

##
## Locations
##

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
CPANM="/usr/local/bin/cpanm" 
LOGDIR="/var/log/scot";
AMQDIR="/opt/activemq"
AMQTAR="apache-activemq-5.13.2-bin.tar.gz"
AMQURL="https://repository.apache.org/content/repositories/releases/org/apache/activemq/apache-activemq/5.13.2/$AMQTAR"

t_proxy=$(printenv http_proxy)
t_s_proxy=$(printenv https_proxy)

echo "= http proxy $http_proxy"
echo "= https proxy $https_proxy"

if [[ ! -z $http_proxy ]]; then
    echo "+ http_proxy environment variable detected"
    PROXY="$http_proxy/" 
    echo "+ PROXY is now $PROXY"
else 
    echo "- http_proxy NOT SET!  if you are behind a proxy, this install will not work until you set this environment variable"
fi

if [[ ! -z $https_proxy ]]; then
    echo "+ https_proxy environment variable detected"
    SPROXY="$https_proxy/"
    echo "+ Secure PROXY is now $SPROXY"
else 
    echo "- https_proxy NOT SET!  if you are behind a proxy, this install may not work until you set this environment variable"
fi


##
## defaults
##
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


echo -e "${yellow}Reading Commandline Args... ${NC}"

while getopts "adigmsrflqA:F:J:wNb:" opt; do
    case $opt in
        a)  
            echo -e "${red} --- do not refresh apt repositories ${NC}"
            REFRESHAPT="no"
            ;;
        b)
            BACKUPDIR=$OPTARG
            echo -e "${yellow} --- Setting Backup directory to $BACKUPDIR ${NC}"
            ;;
        d)
            echo -e "${red} --- do not delete installation directory $SCOTDIR";
            echo -e "${NC}"
            DELDIR="no"
            ;;
        i) 
            echo -e "${red} --- do not overwrite $SCOTINIT ${NC}"
            NEWINIT="no"
            ;;
        g)
            echo -e "${red} --- overwrite existing GeoCity DB ${NC}"
            OVERGEO="yes"
            ;;
        m)
            echo -e "${red} --- do not overwrite mongodb config and restart ${NC}"
            MDBREFRESH="no"
            ;;
        s)
            echo -e "${green} --- INSTALL only SCOT software ${NC}"
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
            echo -e "${red} --- delete SCOT filestore $FILESTORE (DATA LOSS!) ${NC}"
            SFILESDEL="yes"
            ;;
        l)
            echo -e "${red} --- zero existing log files (DATA LOSS!) ${NC}"
            CLEARLOGS="yes"
            ;;
        q)
            echo -e "${red} --- refresh ActiveMQ config and init files ${NC}"
            REFRESH_AMQ_CONFIG="yes"
            ;;
        A)
            AUTHMODE=$OPTARG
            echo -e "${green} --- AUTHMODE set to ${AUTHMODE} ${NC}"
            ;;
        F)
            DEFAULTFILE=$OPTARG
            echo -e "${green} --- Loading Defaults from $DEFAULTFILE ${NC}"
            . $DEFALTFILE
            ;;
        #J)
        #    DBCONFIGJS=$OPTARG
        #    echo -e "${green} --- Loading Config into DB from $DBCONFIGJS ${NC}"
        #    ;;
        w)
            REFRESHAPACHECONF="yes"
            echo -e "${red} --- overwriting exist SCOT apache config ${NC}"
            ;;
        N)
            SKIPNODE="yes"
            echo -e "${yellow} --- skipping NODE/NPM/Grunt instal/build ${NC}"
            ;;
        \?)
            echo -e "${yellow} !!!! INVALID option -$OPTARG ${NC}";
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

echo -e "${NC}"
echo -e "${yellow}Determining OS..."
echo -e "${NC}"

DISTRO=`$DEVDIR/etcsrc/install/determine_os.sh | cut -d ' ' -f 2`
echo "Looks like a $DISTRO based system"

if [[ $DISTRO == "RedHat" ]]; then
    if ! hash lsb_release 2>/dev/null; then
        # ubuntu should have this, but surprisingly
        # redhat/centos/fedora? might not have this installed!
        yum install redhat-lsb
    fi
fi

OS=`lsb_release -i | cut -s -f 2`
OSVERSION=`lsb_release -r | cut -s -f2 | cut -d. -f 1`

echo "Your system looks like a $OS : $OSVERSION"

if [[ $INSTMODE != "SCOTONLY" ]]; then

    ###
    ### Prerequisite Package software installation
    ###

    echo -e "${yellow}+ installing prerequisite packages ${NC}"

    if [ $OS == "RedHatEnterpriseServer" ] || [ $OS == "CentOS" ]; then

        # so later perl packages can compile
        yum -y install openssl-devel
        #
        # install mongo
        #
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

        echo "+ adding line to allow unverifyed ssl in yum"
        echo "sslverify=false" >> /etc/yum.conf

        echo "+ installing rpms..."
        for pkg in `cat $DEVDIR/etcsrc/install/rpms_list`; do
            echo "+ package = $pkg";
            yum install $pkg -y
        done

        #
        # get cpanm going for later use
        # 
	    echo "+ ensuring cpanm is installed"
        curl -L http://cpanmin.us | perl - --sudo App::cpanminus

        # 
        # get NodeJS setup for package install
        # 
        if [ $SKIPNODE == "no" ]; then
            curl --silent --location https://rpm.nodesource.com/setup_4.x | bash -
            yum -y install nodejs
        fi

    fi

    if [[ $OS == "Ubuntu" ]]; then
        apt-get update
        apt-get install curl make -y
	    echo "+ ensuring cpanm is installed"
        curl -L http://cpanmin.us | perl - --sudo App::cpanminus
        if [[ ! -e /usr/local/bin/cpanm ]];
        then
            echo "install can not work without /usr/local/bin/cpanm"
            exit 1
        fi
        if grep --quiet mongo /etc/apt/sources.list; then
            echo "= mongo source present"
        else 
            if grep -q 10gen /etc/apt/sources.list
            then
                echo "= mongo 10Gen repo already present"
            else 
                echo "+ Adding Mongo 10Gen repo and updating apt-get caches"
                # apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927 --keyserver-options http-proxy=$PROXY
                if [[ ! -z $PROXY ]]; then
                    echo " - using $PROXY to add Mongo 10Gen key"
                    apt-key adv --keyserver-options http-proxy=$PROXY --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EA312927
                else 
                    echo " - Not using proxy to add Mongo 10Gen key"
                    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EA312927
                fi
                if [ $OSVERSION == "16" ]; then
                    echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list
                else 
                    echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list
                fi
            fi
        fi

        if [[ ! -e /etc/apt/sources.list.d/maxmind-ppa-trusty.list ]]; then
            add-apt-repository -y ppa:maxmind/ppa
        fi

        apt-get update && apt-get install -y mongodb-org

        if [ $OSVERSION == "16" ]; then 
            if [ ! -e /var/log/mongodb/mongod.log ]; then
                touch /var/log/mongodb/mongod.log
            fi
            chown mongodb.mongodb /var/log/mongodb/mongod.log
            systemctl enable mongod.service
            systemctl daemon-reload mongod.service
            systemctl restart mongod.service
        fi

        if [[ ! -e /etc/apt/sources.list.d/elasticsearch-2.x.list ]]; then
            wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
            if [ $? -gt 0 ]; then
                echo "~ failed to grap elastic GPC-KEY, could be SSL problem"
                wget --no-check-certificate -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
            fi

            echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
        fi

        if [ "$REFRESHAPT" == "yes" ]; then
            echo "= updating apt repository"
            apt-get update 2>&1 > /dev/null
        fi

        apt-get install -y elasticsearch

        if [ $OSVERSION == "16" ]; then
            echo "+ elastic post install for 16.04"
            sed -i 's/#START_DAEMON/START_DAEMON/' /etc/default/elasticsearch
            systemctl enable elasticsearch.service
            systemctl restart elasticsearch.service
        fi

        if [ $SKIPNODE == "no" ]; then
            echo "+ setting up nodejs apt repos"
            curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
            apt-get install -y nodejs
        fi

        echo -e "${yellow}+ installing apt packages ${NC}"

        for pkg in `cat $DEVDIR/etcsrc/install/ubuntu_debs_list`; do
            # echo "+ package $pkg"
            pkgs="$pkgs $pkg"
            apt-get -y install $pkg
        done
    fi


    ##
    ## ActiveMQ install 
    ## 
    echo    "--- Installing ActiveMQ"
    echo    ""
    echo -e "${yellow}+ installing ActiveMQ${NC}"

    if [ -e "$AMQDIR/bin/activemq" ]; then
        echo "= activemq already installed"
        # service activemq restart
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

    echo -e "${yellow}= Checking for activemq user ${NC}"

    AMQ_USER=`grep -c activemq: /etc/passwd`

    if [ $AMQ_USER -ne 1 ]; then
        echo -e "${green}+ adding activemq user ${NC}"
        useradd -c "ActiveMQ User" -d $AMQDIR -M -s /bin/bash activemq
    fi

    echo -e "${yellow}= checking activemq logging directories ${NC}"
    if [ ! -d /var/log/activemq ]; then
        echo "${green}+ creating /var/log/activemq ${NC}"
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

    if [ ! -e "/etc/init.d/activemq" ]; then
        echo "+ copying activemq init file to /etc/init.d"
        cp $DEVDIR/etcsrc/init/activemq-init   /etc/init.d/activemq
    fi
    if [ ! -e "$AMQDIR/conf/scotamq.xml" ]; then
        echo "+ ensuring scotamq.xml is present"
        cp $DEVDIR/etcsrc/scotamq.xml     $AMQDIR/conf
    fi

    service activemq restart

    ###
    ### Perl Module installation
    ###

    echo -e "${yellow}+ installing Perl Modules${NC}"

    for mod in `cat $DEVDIR/etcsrc/install/perl_modules_list`; do
        DOCRES=`perldoc -l $mod 2>/dev/null`
        if [[ -z "$DOCRES" ]]; then
            echo "+ Installing perl module $mod"
            if [ "$mod" = "MongoDB" ]; then
                $CPANM -v $mod --force
            else
                $CPANM -v $mod
            fi
        fi
    done

    ###
    ### Apache Web server configuration
    ###

    echo -e "${yellow}= Configuring Apache ${NC}"

    MYHOSTNAME=`hostname`

    if [ $OS == "RedHatEnterpriseServer" ] || [ $OS == "CentOS" ]; then

        # allow rev proxy to work with selinux
        echo "+ enabling apache to do network connections"
        setsebool -P httpd_can_network_connect 1

        HTTPCONFDIR=/etc/httpd/conf.d

        echo "- Renaming existing conf files in $HTTPCONFDIR"
        for FILE in $HTTPCONFDIR/*.conf
        do
            if [ $FILE != "$HTTPCONFDIR/scot.conf" ]; then
                mv $FILE $FILE.bak
            else
                if [ $REFRESHAPACHECONF == "YES" ]; then
                    mv $FILE $FILE.bak
                fi
            fi
        done

        if [ ! -e /etc/httpd/conf.d/scot.conf ] || [ $REFRESHAPACHECONF == "yes"]; then
            echo -e "${yellow}+ adding scot configuration${NC}"
            REVPROXY=$DEVDIR/etcsrc/apache2/scot-revproxy-$MYHOSTNAME
            if [ ! -e $REVPROXY ]||[$REFRESHAPACHECONF == "yes"]; then

                echo -e "${red}= custom apache config for hostname=$MYHOSTNAME not present, using defaults${NC}"

                if [[ $OSVERSION == "7" ]]; then
                    if [[ $AUTHMODE == "Remoteuser" ]]; then
                        if [ -e $PRIVATE_SCOT_MODULES/etc/apache2/scot-revproxy-rh-7-remoteuser.conf ]; then
                            REVPROXY=$PRIVATE_SCOT_MODULES/etc/apache2/scot-revproxy-rh-7-remoteuser.conf
                        else 
                            REVPROXY=$DEVDIR/etcsrc/apache2/scot-revproxy-rh-7-remoteuser.conf
                        fi
                    else
                        if [ -e $PRIVATE_SCOT_MODULES/etc/apache2/scot-revproxy-rh-7-aux.conf ];then
                            REVPROXY=$PRIVATE_SCOT_MODULES/etc/apache2/scot-revproxy-rh-7-aux.conf
                        else 
                            REVPROXY=$DEVDIR/etcsrc/apache2/scot-revproxy-rh-7-aux.conf
                        fi
                    fi
                else
                    if [[ $AUTHMODE == "Remoteuser" ]]; then
                        if [ -e $PRIVATE_SCOT_MODULES/etc/apache2/scot-revproxy-rh-remoteuser.conf ];then
                            REVPROXY=$PRIVATE_SCOT_MODULES/etc/apache2/scot-revproxy-rh-remoteuser.conf
                        else
                            REVPROXY=$DEVDIR/etcsrc/apache2/scot-revproxy-rh-remoteuser.conf
                        fi
                    else
                        if [ -e $PRIVATE_SCOT_MODULES/etc/apache2/scot-revproxy-rh-aux.conf ];then
                            REVPROXY=$PRIVATE_SCOT_MODULES/etc/apache2/scot-revproxy-rh-aux.conf
                        else
                            REVPROXY=$DEVDIR/etcsrc/apache2/scot-revproxy-rh-aux.conf
                        fi
                    fi
                fi
            fi

            echo -e "${green} --- copying scot.conf apache configuration"
            cp $REVPROXY $HTTPCONFDIR/scot.conf
            echo -e "${yellow} --- sed-ing scot.conf ${NC}"
            sed -i 's=/scot/document/root='$SCOTROOT'/public=g' $HTTPCONFDIR/scot.conf
            sed -i 's=localport='$SCOTPORT'=g' $HTTPCONFDIR/scot.conf
            sed -i 's=scot\.server\.tld='$MYHOSTNAME'=g' $HTTPCONFDIR/scot.conf
        fi

        SSLDIR="/etc/apache2/ssl"

        if [[ ! -f $SSLDIR/scot.key ]]; then
            mkdir -p $SSLDIR/ssl/
            openssl genrsa 2048 > $SSLDIR/scot.key
            openssl req -new -key $SSLDIR/scot.key \
                        -out /tmp/scot.csr \
                        -subj '/CN=localhost/O=SCOT Default Cert/C=US'
            openssl x509 -req -days 36530 \
                         -in /tmp/scot.csr \
                         -signkey $SSLDIR/scot.key \
                         -out $SSLDIR/scot.crt
        fi
    fi

    if [[ $OS == "Ubuntu" ]]; then

        SITESENABLED="/etc/apache2/sites-enabled"
        SITESAVAILABLE="/etc/apache2/sites-available"

        if [ $REFRESHAPACHECONF == "yes" ]; then
            rm -f $SITESENABLED/scot.conf
            rm -f $SITESAVAILABLE/scot.conf
        fi

        # default config blocks 80->443 redirect
        if [ -e $SITESENABLED/000-default.conf ]; then
            rm -f $SITESENABLED/000-default.conf    # exists as symbolic link
        fi

        a2enmod -q proxy
        a2enmod -q proxy_http
        a2enmod -q ssl
        a2enmod -q headers
        a2enmod -q rewrite
        a2enmod -q authnz_ldap

        if [ ! -e $SITESAVAILABLE/scot.conf ] || [ $REFRESHAPACHECONF == "yes" ]; then

            echo -e "${yellow}+ adding scot configuration${NC}"
            REVPROXY=$DEVDIR/etcsrc/scot-revproxy-$MYHOSTNAME

            if [ ! -e $REVPROXY ]; then
                echo -e "${red}= custom apache config for $MYHOSTNAME not present, using defaults${NC}"
                if [[ $AUTHMODE == "Remoteuser" ]]; then
                    if [ -e $PRIVATE_SCOT_MODULES/etc/scot-revproxy-ubuntu-remoteuser.conf ]; then
                        REVPROXY=$PRIVATE_SCOT_MODULES/etc/scot-revproxy-ubuntu-remoteuser.conf
                    else
                        REVPROXY=$DEVDIR/etcsrc/apache2/scot-revproxy-ubuntu-remoteuser.conf
                    fi
                else 
                    if [ -e $PRIVATE_SCOT_MODULES/etc/scot-revproxy-ubuntu-aux.conf ]; then
                        REVPROXY=$PRIVATE_SCOT_MODULES/etc/scot-revproxy-ubuntu-aux.conf
                    else
                        REVPROXY=$DEVDIR/etcsrc/apache2/scot-revproxy-ubuntu-aux.conf
                    fi
                fi
            fi

            echo -e "${green} copying $REVPROXY to $SITESAVAILABLE ${NC}"
            cp $REVPROXY $SITESAVAILABLE/scot.conf
            echo -e "${yellow} sed-ing files ${NC}"
            sed -i 's=/scot/document/root='$SCOTROOT'/public=g' $SITESAVAILABLE/scot.conf
            sed -i 's=localport='$SCOTPORT'=g' $SITESAVAILABLE/scot.conf
            sed -i 's=scot\.server\.tld='$MYHOSTNAME'=g' $SITESAVAILABLE/scot.conf
            ln -sf /etc/apache2/sites-available/scot.conf \
                  /etc/apache2/sites-enabled/scot.conf
        fi

        SSLDIR="/etc/apache2/ssl"

        if [[ ! -f $SSLDIR/scot.key ]]; then
            echo "+ creating temporary SSL certs, ${RED} REPLACE WITH REAL CERTS ASAP! ${NC}"
            mkdir -p $SSLDIR/ssl/
            openssl genrsa 2048 > $SSLDIR/scot.key
            openssl req -new -key $SSLDIR/scot.key \
                        -out /tmp/scot.csr \
                        -subj '/CN=localhost/O=SCOT Default Cert/C=US'
            openssl x509 -req -days 36530 \
                         -in /tmp/scot.csr \
                         -signkey $SSLDIR/scot.key \
                         -out $SSLDIR/scot.crt
        fi
    fi

    ###
    ### Geo IP database set up
    ###
    if [ -e $GEODIR/GeoLiteCity.dat ]; then
        if [ "$OVERGEO" == "yes" ]; then
            echo -e "${red}- overwriting existing GeoLiteCity.dat file"
            cp $DEVDIR/etcsrc/GeoLiteCity.dat $GEODIR/GeoLiteCity.dat
            chmod +r $GEODIR/GeoLiteCity.dat
        fi
    else 
        echo "+ copying GeoLiteCity.dat file"
        cp $DEVDIR/etcsrc/GeoLiteCity.dat $GEODIR/GeoLiteCity.dat
        chmod +r $GEODIR/GeoLiteCity.dat
    fi

    ###
    ### we are done with the prerequisite software installation
    ###
fi

###
### account creation
###

echo -e "${yellow} Checking SCOT accounts${NC}"

scot_user=`grep -c scot: /etc/passwd`
if [ "$scot_user" -ne 1 ]; then
    echo -e "${green}+ adding user: scot ${NC}"
    useradd scot
fi

###
### set up init.d script
###
echo -e "${yellow} Checking for init.d script ${NC}"

if [ -e /etc/init.d/scot ]; then
    echo "= init script exists, stopping existing scot..."
    service scot stop
fi

if [ "$NEWINIT" == "yes" ] || [ ! -e /etc/init.d/scot ]; then
    echo -e "${yellow} refreshing or instaling the scot init script ${NC}"
    #if [ $OS == "RedHatEnterpriseServer" ] || [ $OS == "CentOS" ]; then
    #    cp $DEVDIR/etc/init/scot-centos-init /etc/init.d/scot
    #fi
    #if [ $OS == "Ubuntu" ]; then
        cp $DEVDIR/etcsrc/init/scot-init /etc/init.d/scot
    #fi
    chmod +x /etc/init.d/scot
    sed -i 's=/instdir='$SCOTDIR'=g' /etc/init.d/scot
fi
    
###
### Set up Filestore directory
###
echo -e "${yellow} Checking SCOT filestore $FILESTORE ${NC}"

if [ "$SFILESDEL" == "yes" ]; then
    echo -e "${red}- removing existing filestore${NC}"
    if [ "$FILESTORE" != "/" ]; then
        # try to prevent major catastrophe!
        rm -rf  $FILESTORE
    else
        echo -e "${RED} Someone set filestore to /, so deletion skipped.${NC}"
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

###
### set up the backup directory
###
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

###
### install the scot
###
#echo -e "${yellow} running grunt on reactjs files...${NC}"
#CURDIR=`pwd`

#if [ $SKIPNODE == "no" ];then
#    cd $DEVDIR/pubdev 
#    npm install
#    cd $CURDIR
#fi


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

if [ "$OS"  == "Ubuntu" ];
then
    echo "+ adding user scot to the www-data group"
    usermod -a -G scot www-data
else 
    echo "+ adding user scot to the apache group"
    usermod -a -G scot apache
fi

echo -e "${yellow} installing SCOT files ${NC}"
cp -r $DEVDIR/* $SCOTDIR/

# default scot_env
if [[ $AUTHMODE == "Remoteuser" ]]; then
    cp $DEVDIR/etcsrc/scot_env.remoteuser.cfg $SCOTDIR/etc/scot_env.cfg
else 
    if [[ ! -e $SCOTDIR/etc/scot_env.cfg ]]; then
        echo "+ copying scot_env.cfg into $SCOTDIR/etc"
        cp $DEVDIR/etcsrc/scot_env.local.cfg $SCOTDIR/etc/scot_env.cfg
    else
        echo "= scot_env.cfg already present, skipping..."
    fi
fi

CFGFILES='mongo logger imap activemq enrichments flair.app flair_logger stretch.app stretch_logger game.app elastic scot_server'

for file in $CFGFILES
do
    CFGDEST="$SCOTDIR/etc/$file.cfg"
    if [[ -e $CFGDEST ]]; then
        echo "= $CFGDEST already present, skipping..."
    else
        CFGSRC="$DEVDIR/etcsrc/$file.cfg"
        echo "+ copying $CFGSRC to $CFGDEST"
        cp $CFGSRC $CFGDEST
    fi
done

# private configs to overwrite default configs

if [ -d "$PRIVATE_SCOT_MODULES" ]; then
    echo "Private SCOT modules and config directory exist.  Installing..."
    . $PRIVATE_SCOT_MODULES/install.sh
fi

chown -R scot.scot $SCOTDIR
chmod -R 755 $SCOTDIR/bin

###
### Logging file set up
###
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
    cp $DEVDIR/etcsrc/logrotate.scot /etc/logrotate.d/scot
else 
    echo "= logrotate policy in place"
fi

###
### Mongo Configuration
###
echo "+ Configuring MongoDB"

if [ "$MDBREFRESH" == "yes" ]; then
    echo "+ Refresh of Mongo Config requested"
    echo "= stopping mongod"
    service mongod stop

    echo "+ copying new mongod.conf"
    if [ $OS == "RedHatEnterpriseServer" ] || [ $OS == "CentOS" ]; then
        cp $DEVDIR/etcsrc/init/mongod-cent-init /etc/init.d/mongod
        cp $DEVDIR/etcsrc/mongod-cent-conf /etc/mongod.conf
        # I really wish that mongo would get it's sh*t together and 
        # install everything in the same place regardless of distro
        DBDIR=/var/log/mongo 
    fi

    if [ $OS == "Ubuntu" ]; then
        if [ $OSVERSION == "16" ]; then
            MDCDIR="/etc/"
            cp $MDCDIR/mongod.conf $MDCDIR/mongod.conf.bak
            cp $DEVDIR/etcsrc/mongod.conf $MDCDIR/mongod.conf
            FIKTL=`grep failIndexKeyTooLong /lib/systemd/system/mongod.service`
            if [ "$FIKTL" == "" ]; then
                echo "- SCOT will fail unless failIndexKeyTooLong=false in /lib/systemd/system/mongod.service"
                echo "+ backing orig, and copying new into place. "
                ext=`date +%s`
                cp /lib/systemd/system/mongod.service /tmp/mongod.service.backup.$ext
                cp $DEVDIR/etcsrc/systemd-mongod.conf /lib/systemd/system/mongod.service
                cp $MDCDIR/mongod.conf $MDCDIR/mongod.conf.$ext
                cp $DEVDIR/etcsrc/mongod.conf $MDCDIR/mongod.conf
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
                cp $DEVDIR/etcsrc/init-mongod.conf $MDCDIR/mongod.conf
            fi
        fi
    fi

    if [ ! -d $DBDIR ]; then
        echo "+ creating database dir $DBDIR"
        mkdir -p $DBDIR
    fi
    echo "+ ensuring proper ownership of $DBDIR"
    chown -R mongodb:mongodb $DBDIR

    echo "- clearing /var/log/mondob/mongod.log"
    cat /dev/null > /var/log/mongodb/mongod.log
else
    echo "- skipping configuration of mongodb at user request"
fi

if [ $OSVERSION == "16" ]; then
    systemctl daemon-reload
fi

MONGOSTATUS=`service mongod status`

if [ $OS == "RedHatEnterpriseServer" ] || [ $OS == "CentOS" ]; then
    echo $MONGOSTATUS | grep inactive
    MSTAT=$?
    if [ "$MSTAT" == "0" ]; then
        service mongod start
    fi
else 
    if [ $OSVERSION == "16" ]; then
        echo $MONGOSTATUS | grep inactive
        MSTAT=$?
        if [ "$MSTAT" == "0" ]; then
            service mongod start
        fi
    else
        if [ "$MONGOSTATUS" == "mongod stop/waiting" ];then
            service mongod start
        fi
    fi
fi

COUNTER=0
grep -q 'waiting for connections on port' /var/log/mongodb/mongod.log
while [[ $? -ne 0 && $COUNTER -lt 50 ]]; do
    sleep 1
    let COUNTER+=1
    echo "~ waiting for mongo to initialize ( $COUNTER seconds)"
    grep -q 'waiting for connections on port' /var/log/mongodb/mongod.log
done

if [ "$RESETDB" == "yes" ];then
    echo -e "${red}- Dropping mongodb scot database!${NC}"
    (cd $DEVDIR/etcsrc; mongo scot-prod $DEVDIR/etcsrc/database/reset.js)
    # mongo scot-prod $DBCONFIGJS
else 
    INEXIST=$(mongo scot-prod --eval "printjson(db.alertgroup.getIndexes());" --quiet)
    if [ "$INEXIST" == "[ ]" ]; then
        (cd $DEVDIR/etcsrc; mongo scot-prod $DEVDIR/etcsrc/database/reset.js)
    fi
fi

MONGOADMIN=$(mongo scot-prod --eval "printjson(db.user.count({username:'admin'}))" --quiet)

if [ "$MONGOADMIN" == "0" ] || [ "$RESETDB" == "yes" ]; then
    # PASSWORD=$(dialog --stdout --nocancel --title "Set SCOT Admin Password" --backtitle "SCOT Installer" --inputbox "Choose a SCOT Admin login password" 10 70)
    echo ""
    echo "${red} USER INPUT NEEDED ${NC}"
    echo ""
    echo "Choose a SCOT Admin login Password (characters will not be echoed)"
    echo ""
    set='$set'
    HASH=`$DEVDIR/bin/passwd.pl`

    mongo scot-prod $DEVDIR/etcsrc/admin_user.js
    mongo scot-prod --eval "db.user.update({username:'admin'}, {$set:{pwhash:'$HASH'}})"

fi

if [[ $INSTMODE != "SCOTONLY" ]]; then
    $CPANM -f MooseX::Role::MongoDB # to get arround deprecation warnings, remove this once upstream pull request is accepted
    $CPANM -f Meerkat
    echo "+ installing current Courriel"
    $CPANM Courriel
    $CPANM -f AnyEvent::ForkManager
fi

if [ $OSVERSION == "16" ]; then 
    echo "+ retrying elasticsearch start"
    systemctl restart elasticsearch.service
fi

echo "+ copying documentation to public dir"
cp -r $DEVDIR/docs/build/html/* $SCOTDIR/public/docs/

if [ $OSVERSION == "16" ]; then 
    cp $DEVDIR/etcsrc/scot /etc/systemd/system/scot.service
    systemctl enable scot.service
    systemctl start scot.service
else 
    if [ ! -e /etc/init.d/scot ]; then
        echo -e "${yellow}+ missing /etc/init.d/scot, installing...${NC}"
        cp $DEVDIR/etcsrc/init/scot-init /etc/init.d/scot
        chmod +x /etc/init.d/scot
        sed -i 's=/instdir='$SCOTDIR'=g' /etc/init.d/scot
        if [ $OS == "RedHatEnterpriseServer" ] || [ $OS == "CentOS" ]; then
            chkconfig --add scot
        else 
            update-rc.d scot defaults
        fi
    fi
fi

if [ $OSVERSION == "16" ]; then 
    echo "+ setting up systemd service for scot flairing daemon"
    cp $DEVDIR/etcsrc/scfd.unit /etc/systemd/system/scfd.service
    systemctl enable scfd.service
    systemctl start scfd.service
else 
    if [ ! -e /etc/init.d/scfd ]; then
        echo -e "${red} Missing INIT for SCot Flair Daemon ${NC}"
        echo -e "${yellow}+ adding /etc/init.d/scfd...${NC}"
        /opt/scot/bin/scfd.pl get_init_file > /etc/init.d/scfd
        chmod +x /etc/init.d/scfd
        if [ $OS == "RedHatEnterpriseServer" ] || [ $OS == "CentOS" ]; then
            chkconfig --add scfd
            /etc/init.d/scfd start
        else 
            update-rc.d scfd defaults
            service scfd start
        fi
    fi
fi

if [ $OSVERSION == "16" ]; then 
    echo "+ setting up systemd service for scot elasticsearch push daemon"
    cp $DEVDIR/etcsrc/scepd.unit /etc/systemd/system/scepd.service
    systemctl enable scepd.service
    systemctl start scepd.service
else 
    if [ ! -e /etc/init.d/scepd ]; then
        echo -e "${red} Missing INIT for SCot ES Push Daemon ${NC}"
        echo -e "${yellow}+ adding /etc/init.d/scepd...${NC}"
        /opt/scot/bin/scepd.pl get_init_file > /etc/init.d/scepd
        chmod +x /etc/init.d/scepd
        if [ $OS == "RedHatEnterpriseServer" ] || [ $OS == "CentOS" ]; then
            chkconfig --add scepd
            /etc/init.d/scepd start
        else 
            if [ $OSVERSION == "14" ]; then
                update-rc.d scepd defaults
                service scepd start
            fi
        fi
    fi
fi

echo "= restarting apache2"
if [ $OSVERSION == "16" ]; then
    systemctl restart apache2
else 
    /etc/init.d/apache2 restart
fi

echo "= restarting scot"
if [ $OSVERSION == "16" ]; then
    systemctl restart scot
else 
    /etc/init.d/scot restart
fi

    
#
# add elastic search to startup
# TODO: add other (activemq?) to start here 
if [ $OS == "RedHatEnterpriseServer" ] || [ $OS == "CentOS" ]; then
    chkconfig --add elasticsearch
    chkconfig --add scot
    chkconfig --add activemq
    chkconfig --add mongod

    echo "+ Allowing Firewalld to pass web traffic"
    firewall-cmd --permanent --add-port=80/tcp
    firewall-cmd --permanent --add-port=443/tcp
    firewall-cmd --reload
else 
    if [ $OSVERSION == "14" ]; then 
        update-rc.d elasticsearch defaults
        update-rc.d scot defaults
        update-rc.d activemq defaults
    fi
fi

echo "+ starting activemq"
/opt/activemq/bin/activemq start

if [ $AUTHMODE == "Local"  ];then
    echo "!!!!"
    echo "!!!! AUTHMODE is set to LOCAL.  Use the admin username and password"
    echo "!!!! to initially access SCOT.  Please see only documentation for "
    echo "!!!! direction on how to create users/password or to switch "
    echo "!!!! authentication options."
    echo "!!!!"
fi


echo ""
echo "@@"
echo "@@ SCOT online documentaton is available at "
echo "@@  https://localhost/docs/index.html"
echo "@@"
echo ""

echo "----"
echo "----"
echo "---- Install completed"
echo "----"
echo "----"
