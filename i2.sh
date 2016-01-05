#!/bin/bash
#
# scot installer
#

# color output formatting
blue='\e[0;34m'
green='\e[0;32m'
yellow='\e[0;33m'
red='\e[0;31m'
NC='\e[-m'

echo "${blue}########"
echo "######## SCOT 3 Installer"
echo "######## Support at: scot-dev@sandia.gov"
echo "########${NC}"

DEVDIR="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $DEVDIR/etc/install/locations.sh

echo "${yellow}Reading Commandline Args...${NC}"

while getopts "digsrflm" opt; do
    case $opt in
        d)
            echo "${red}--- will delete installation directory $INSTDIR${NC}"
            DEL_INST_DIR="true"
            ;;
        i)
            echo "${red}--- will overwrite existing /etc/init.d/scot file${NC}"
            NEWINIT="yes"
            ;;
        g)
            echo "${red}--- overwrite existing GeoCity DB ${NC}"
            OVERGEO="yes"
            ;;
        m)
            echo "${red}--- overwrite mongodb config and restart"
            MDBREFRESH="yes"
            ;;
        s) 
            echo "${green}--- will install only SCOT software (no prereqs)${NC}"
            INSTMODE="SCOTONLY"
            ;;
        r)
            echo "${red}--- will reset SCOT DB (warning: DATA LOSS!)"
            RESETDB=1
            ;;
        f)
            echo "${red}--- will delete SCOT filestore directory $FILESTORE (warning: DATA LOSS)"
            SFILESDEL=1
            ;;
        l)
            echo "${red}--- will zero existing log files (warning potential data loss)"
            CLEARLOGS=1
            ;;
        \?)
            echo "!!! Invalid -$OPTARG"
            echo ""
            echo "Usage: $0 [-f][-s][-r][-d]"
            echo ""
            echo "    -f    delete $FILESTORE filestore directory and its contents"
            echo "    -s    only install the SCOT software, skip prerequisite or 3rd party software"
            echo "    -r    delete the SCOT database and install initial template"
            echo "    -d    delete $INSTDIR intallation directory prior to install"
            echo "    -i    overwrite existing /etc/init.d/scot "
            echo "    -g    overwrite existing GeoCity db file"
            exit 1
            ;;
    esac
done

echo "${NC}"
echo "${yellow}Determining OS..."
echo "${NC}"

DISTRO=`$DEVDIR/etc/install/determine_os.sh | cut -d ' ' -f 2`
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

    echo "${yellow}+ installing prerequisite packages{$NC}"

    if [[ $OS == "RedHatEnterpriseServer" ]]; then
        if grep --quiet mongo /etc/yum.repos.d/mongodb.repo; then
            echo "= mongo yum stanza present"
        else
            echo "+ adding mongo to yum repos"
            cat <<- EOF > /etc/yum.repos.d/mongodb.repo
[mongodb]
name=MongoDB Repository
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64/
gpgcheck=0
enabled=1
EOF
        fi


        for pkg in `cat $DEVDIR/etc/install/rpms_list`; do
            echo "+ package = $pkg";
            yum install $pkg -y
        done

        curl -L http://cpanmin.us | perl - --sudo App::cpanminus

    fi

    if [[ $OS == "Ubuntu" ]]; then
        if grep --quiet mongo /etc/apt/sources.list; then
            echo "= mongo source present"
        else 
            echo "+ Adding Mongo 10Gen repo and updating apt-get caches"
            echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" >> /etc/apt/sources.list
            apt-key add $DEVDIR/etc/mongo_10gen.key
            apt-get update
            
        fi
        for pkg in `cat $DEVDIR/etc/install/ubuntu_debs_list`; do
            echo "+ package $pkg"
            apt-get -qq install $pkg
        done
    fi

###
### ActiveMQ install
###
    echo "${yellow}+ installing ActiveMQ${NC}"

    if [ -e "$ACTIVEMQDIR/bin/activemq" ]; then
        echo "= activemq already installed"
    else
        echo "= downloading..."
        curl -o /tmp/apache-activemq.tar.gz -SL '$AMQTAR'

        AMQ_USER=`grep -c activemq: /etc/passwd`
        if [ $AMQ_USER -ne 1 ]; then
            userad -c "ActiveMQ User" -d $ACTIVEMQDIR -M -s /bin/bash activemq
        fi

        mkdir -p /var/log/activemq
        touch /var/log/activemq/scot.amq.log
        chown -R activemq /var/log/activemq

        tar xf /tmp/apache-activemq.tar.gz --directory /tmp
        mv /tmp/apache-activemq-5.14-SNAPSHOT/* $ACTIVEMQDIR

        cp $DEVDIR/etc/scotamq.xml $ACTIVEMQDIR/conf
        cp $DEVDIR/etc/jetty.xml   $ACTIVEMQDIR/conf
        cp -R $DEVDIR/etc/scotaq   $ACTIVEMQDIR/webapps
        mv $ACTIVEMQDIR/webapps/scotaq     $ACITVEMQDIR/webapps/scot
        cp $DEVDIR/etc/activemq-init /etc/init.d/activemq
        chmow +x /etc/init.d/activemq
        chown -R activemq.activemq $ACTIVEMQDIR
        service activemq start
    fi

###
### Perl Module installation
###

    echo "${yellow}+ installing Perl Modules${NC}"

    for mod in `cat $DEVDIR/etc/install/perl_modules_list`; do
        DOCRES=`perldoc -l $mod 2>/dev/null
        if [[ -z "$DOCRES" ]]; then
            echo "+ Installing perl module $mod"
            if [ "$mod" = "MongoDB" ]; then
                cpanm $mod --force
            else
                cpanm $mod
            fi
        fi
    done

###
### Apache Web server configuration
###

    echo "${yellow}= Configuring Apache"

    MYHOSTNAME=`hostname`

    if [[ $OS == "RedHatEnterpriseServer" ]]; then

        if [ ! -e /etc/httpd/conf.d/scot.conf ]; then
            echo "${yellow}+ adding scot configuration${NC}"
            REVPROXY=$DEVDIR/etc/scot-revproxy-$MYHOSTNAME
            if [ ! -e $REVPROXY ]; then
                echo "${red}= custom apache config for $MYHOSTNAME not present, using defaults${NC}"
                if [[ $OSVERSION == "7" ]]; then
                    REVPROXY=$DEVDIR/etc/scot-revproxy-local.conf
                else
                    REVPROXY=$DEVDIR/etc/scot-revproxy-local-rh.conf
                fi
            fi
            cp $REVPROXY /etc/httpd/conf.d/scot.conf
        fi

        SSLDIR="/etc/apache2/ssl"

        if [[ ! -f $SSLDIR/scot.key ]]; then
            mkdir -p $SSLDIR/ssl/
            openssl genrsa 2048 > $SSLDIR/scot.key
            openssl req -new -key $SSLDIR/scot.key -out /tmp/scot.csr -subj '/CN=localhost/O=SCOT Default Cert/C=US'
            openssl x509 -req -days 36530 -in /tmp/scot.csr -signkey $SSLDIR/scot.key -out $SSLDIR/scot.crt
        fi
    fi

    if [[ $OS == "Ubuntu" ]]; then

        MODSENABLED="/etc/apache2/sites-enabled"
        MODSAVAILABLE="/etc/apache2/sites-available"

        # default config blocks 80->443 redirect
        if [ -e $MODSENABLED/000-default.conf ]; then
            mv $MODSENABLED/000-default.conf $MODSAVAILABLE/000-default.conf
        fi

        a2enmod -q proxy
        a2enmod -q proxy_http
        a2enmod -q ssl
        a2enmod -q headers
        a2enmod -q rewrite
        a2enmod -q authnz_ldap

        if [ ! -e /etc/apache2/sites-enabled/scot.conf ]; then
            echo "${yellow}+ adding scot configuration${NC}"
            REVPROXY=$DEVDIR/etc/scot-revproxy-$MYHOSTNAME
            if [ ! -e $REVPROXY ]; then
                echo "${red}= custom apache config for $MYHOSTNAME not present, using defaults${NC}"
                if [[ $OSVERSION == "7" ]]; then
                    REVPROXY=$DEVDIR/etc/scot-revproxy-local.conf
                else
                    REVPROXY=$DEVDIR/etc/scot-revproxy-local-rh.conf
                fi
            fi
            cp $REVPROXY /etc/apache2/sites-enabled/scot.conf
        fi

        SSLDIR="/etc/apache2/ssl"

        if [[ ! -f $SSLDIR/scot.key ]]; then
            mkdir -p $SSLDIR/ssl/
            openssl genrsa 2048 > $SSLDIR/scot.key
            openssl req -new -key $SSLDIR/scot.key -out /tmp/scot.csr -subj '/CN=localhost/O=SCOT Default Cert/C=US'
            openssl x509 -req -days 36530 -in /tmp/scot.csr -signkey $SSLDIR/scot.key -out $SSLDIR/scot.crt
        fi
    fi

###
### Geo IP database set up
###
    if [ -e $GEODIR/GeoLiteCity.dat ]; then
        if [ "$OVERGEO" == "yes" ]; then
            echo "${red}- overwriting existing GeoLiteCity.dat file"
            cp $DEVDIR/etc/GeoLiteCity.dat $GEODIR/GeoLiteCity.dat
            chmod +r $GEODIR/GeoLiteCity.dat
        fi
    else 
        echo "+ copying GeoLiteCity.dat file"
        cp $DEVDIR/etc/GeoLiteCity.dat $GEODIR/GeoLiteCity.dat
        chmod +r $GEODIR/GeoLiteCity.dat
    fi

###
### we are done with the prerequisite software installation
##

fi

###
### account creation
###

echo "${yellow} Checking SCOT accounts${NC}"

scot_user=`grep -c scot: /etc/password`
if [ $scot_user -ne 1 ]; then
    echo "+ adding user: scot"
    useradd scot
fi

###
### set up init.d script
###
echo "${yellow} Checking for init.d script${NC}"

if [ -e /etc/init.d/scot ]; then
    echo "= init script exists, stopping existing scot..."
    service scot stop
fi

if [ "$NEWINIT" == "yes" ]; then
    if [ $OS == "RedHatEnterpriseServer" ]; then
        cp $INSTDIR/etc/scot-centos-init /etc/init.d/scot
    fi
    if [ $OS == "Ubuntu" ]; then
        cp $INSTDIR/etc/scot-init /etc/init.d/scot
    fi
    chmod +x /etc/init.d/scot
    sed -i 's=/instdir='$INSTDIR'=g' /etc/init.d/scot
fi
    
###
### Set up Filestore directory
###
echo "${yellow} Checking SCOT filestore $FILESTORE"

if [ "$SFILESDEL" == "1" ]; then
    echo "${red}- removing existing filestore${NC}"
    rm -rf  $FILESTORE
fi

echo "+ creating new filestore directory"
mkdir -p $FILESTORE
chown scot $FILESTORE
chgrp scot $FILESTORE
chmod g+w $FILESTORE

###
### set up the backup directory
###
echo "${yellow} setting up backup directory $BACKDIR"
mkdir -p $BACKUPDIR
chown scot:scot $BACKUPDIR

###
### install the scot
###

echo "${yellow} installing SCOT files"

if [ $DELDIR = "true" ]; then
    echo "${red}- removing target installation directory $INSTDIR ${NC}"
    rm -rf $INSTDIR
fi

if [ ! -d $INSTDIR ]; then
    echo "+ creating $INSTDIR";
    mkdir -p $INSTDIR
    chown scot:scot $INSTDIR
    cp -r $DEVDIR/* $INSTDIR/
fi

###
### Logging file set up
###
echo "${yellow} setting up Log dir $LOGDIR"
if [ "$CLEARLOGS"  == "1" ]; then
    echo "${red}- clearing any existing scot logs"
    for i in $LOGDIR/*; do
        cat /dev/null > $i
    done
fi

touch $LOGDIR/scot.log
chown scot:scot $LOGDIR/scot.log
cp $DEVDIR/etc/logrotate.scot /etc/logrotate.d/scot

###
### Mongo Configuration
###

if [ "$MDBREFRESH" == "yes" ]; then
    echo "= stopping mongod"
    service mongod stop

    cp $DEVDIR/etc/mongod.conf /etc/mongod.conf
    mkdir -p $DBDIR
    chown -R mongodb:mongodb $DBDIR
    cat /dev/null > /var/log/mongodb/mongod.log
fi

MONGOSTATUS=`service mongod status`

if [ "$MONGOSTATUS" == "mongod stop/waiting" ];then
    service mongod start
fi

COUNTER=0
grep -q 'waiting for connections on port' /var/log/mongodb/mongod.log
while [[ $? -ne 0 && $COUNTER -lt 100 ]]; do
    sleep 1
    let COUNTER+=1
    echo "~ waiting for mongo to initialize ( $COUNTER seconds)"
    grep -q 'waiting for connections on port' /var/log/mongodb/mongod.log
done

if [ "$RESETDB" == "1" ];then
    echo "${red}- Dropping mongodb scot database!${NC}"
    mongo scot-prod $DEVDIR/bin/reset_db.js
fi

MONGOADMIN=$(mongo scot-prod --eval "printjson(db.users.count({username:'admin'}))" --quiet)

if [ "$MONGOADMIN" == "0" || "$RESETDB" == "1" ]; then
    PASSWORD=$(dialog --stdout --nocancel --title "Set SCOT Admin Password" --backtitle "SCOT Installer" --inputbox "Choose a SCOT ADmin login password" 10 70)
    set='$set'
    HASH=`$DEVDIR/bin/passwd.pl $PASSWORD`

    mongo scot-prod $DEVDIR/etc/admin_user.js
    mongo scot-prod --eval "db.users.update({username:'admin'}, {$set:{hash:'$HASH'}})"

fi

echo "= restarting scot"
/etc/init.d/scot restart

echo "----"
echo "----"
echo "---- Install completed"
echo "----"
echo "----"
