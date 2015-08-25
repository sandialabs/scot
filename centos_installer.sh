#!/bin/bash

###
### Unified Installer for SCOT
### 
### installs scot for the following OS/types
### CentOS 6.7
###

set -o pipefail

readonly DEVDIR="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly WEBAPPS="/opt/sandia/webapps"
readonly INSTDIR="/opt/sandia/webapps/scot3"
readonly FILESTORE="/opt/scotfiles"
readonly CONF="$INSTDIR/etc/scot.json"
readonly INSTLOG="/tmp/scot.install.log"
readonly TESTURL="http://getscot.sandia.gov"
readonly BACKUPDIR="$INSTDIR/backups"
readonly GEODIR="/usr/local/share/GeoIP"
readonly AMQPKG="$DEVDIR/pkgs/apache-activemq-5.9-20130708.151752-73-bin.tar.gz"
readonly DBDIR="/data/db"
readonly CPANM="/usr/local/bin/cpanm"

DELDIR='false'
RESETDB=0

if [ -z "$DOCKERINSTALL" ]; then
    DOCKERINSTALL="false"
fi

# color output formatting
blue='\e[0;34m'
green='\e[0;32m'
yellow='\e[0;33m'
red='\e[0;31m'
NC='\e[-m'

echo "########"
echo "######## SCOT 3 Installer"
echo "######## Email: scot-dev@sandia.gov"
echo "########"

echo "=== Checking for required internet connection"
# I think this magic allows SELinux to connect
SELINUX=`sestatus`
#if [ $SELINUX -ne "SELinux status:                 disabled" ]; then
    /usr/sbin/setsebool httpd_can_network_connect 1
    /usr/sbin/setsebool -P httpd_can_network_connect 1
#fi

if [[ $DOCKERINSTALL != "true" ]]; then
    if hash wget 2>/dev/null; then
        wget -qO- $TESTURL &>/dev/null
    else
        curl $TESTURL &>/dev/null
    fi
else 
    curl $TESTURL &>/dev/null
fi

if [ "$?" != 0 ]; then
    echo "!!!"
    echo "!!! Unable to reach $TESTURL."
    echo "!!! This implies that your internet connection may be down "
    echo "!!!  (or $TESTURL is not responding)."
    echo "!!! Verify that your proxy setting are correct if you have a proxy"
    echo "!!! and retry."
    echo "!!!"
    exit 3
fi

yum install redhat-lsb

OS=`lsb_release -i | cut -s -f2`
OSVERSION=`lsb_release -r | cut -s -f2 | cut -d. -f 1`

echo "=== Attempting Install on: "
echo "=== $OS : $OSVERSION"
echo "=== processing command line options..."

INSTMODE=''
MODE='production'

while getopts "dsfrm:" opt; do
    case $opt in
        d)
            echo "--- will delete installation directory $INSTDIR"
            DELDIR="true"
            ;;
        s)
            echo "--- will only install SCOT code"
            INSTMODE='SCOTONLY'
            ;;
        r)
            echo "--- will reset SCOT DB (existing data will be lost!)"
            RESETDB=1
            ;;
        m)
            echo "--- will set MODE to $OPTARG"
            MODE=$OPTARG
            ;;
        f)
            echo "--- will delete files in $FILESTORE (warning data will be lost!)"
            SFILESDEL=1
            ;;
        :)
            echo "!!! Option -$OPTARG requires an argument !!!"
            exit 1
            ;;
        \?)
            echo "!!! Invalid -$OPTARG"
            echo ""
            echo "Useage $0 [-f] [-s] [-m mode] [-r] [-d]"
            echo ""
            echo "      -f        deletes filestore directory and contents"
            echo "      -s        only install SCOT, skip 3rd party software"
            echo "      -m mode   mode is dev or prod"
            echo "      -r        will reset mongo databases (data loss!)"
            echo "      -d        delete existing scot install"
            exit 1
            ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    echo "!!!"
    echo "!!! This script must be run as ROOT or using SUDO !!!"
    echo "!!!"
    exit 2
fi


if [[ $DOCKERINSTALL != "true" ]]; then

    if [[ $INSTMODE != "SCOTONLY" ]]; then

        echo "=== CentOS installation"
        # create the yum stanza for mongodb
        echo "=== creating yum stanza for mongodb"
        cat <<- EOF > /etc/yum.repos.d/mongodb.repo
[mongodb]
name=MongoDB Repository
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64/
gpgcheck=0
enabled=1
EOF

        echo "=== Installing yum packages"
        # yum update
        yum install wget git -y
        yum groupinstall "Development Tools" -y
        yum install file-devel

        export ISEPEL=`yum repolist 2>/dev/null | grep -i epel`
        if [ "$ISEPEL" == "" ]; then
            # see https://troubleshootguru.wordpress.com/2014/11/19/how-to-install-redis-on-a-centos-6-5-centos-7-0-server-2/
            wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
            rpm -Uvh epel-release-6*.rpm
        fi

        if hash perl 2>/dev/null; then
            echo "=== perl is installed"
        else 
            yum install perl perl-Net-SSLeay
        fi

        if hash cpanm 2>/dev/null; then
            echo "=== cpanm is installed"
        else
            echo "=== install perl cpan and cpanm"
            yum install perl-devel
            yum install perl-CPAN
            curl -L http://cpanmin.us | perl - --sudo App::cpanminus
        fi

        yum install httpd dialog mongodb-org redis GeoIP perl-Geo-IP perl-Curses java-1.7.0-openjdk krb5-libs krb5-devel mod_ssl openssl -y

        echo "=== starting redis"
        service redis start 
        chkconfig redis on

        export RPMFILEDEVEL=`rpm -qa file-devel`
        if [ "$RPMFILEDEVEL" == "" ]; then
            wget http://mirror.centos.org/centos/$OSVERSION/os/x86_64/Packages/file-devel-5.11-21.el7.x86_64.rpm
            rpm -i file-devel-5.11-21.el7.x86_64.rpm
            rm -f file-devel-5.11-21.el7.x86_64.rpm
        fi
    fi 
fi

    for PACKAGE in "PSGI" "Plack" "CGI::PSGI" "CGI::PSGI" "CGI::Emulate::PSGI" "CGI::Compile" "HTTP::Server::Simple::PSGI" "Starman" "Starlet" "JSON" "Curses::UI" "Number::Bytes::Human" "Sys::RunAlone" "Parallel::ForkManager" "DBI" "Encode" "FileHandle" "File::Slurp" "File::Temp" "File::Type" "Geo::IP" "HTML::Entities" "HTML::Scrubber" "HTML::Strip" "HTML::StripTags" "JSON" "Log::Log4perl" "Mail::IMAPClient" "Mail::IMAPClient::BodyStructure" "MongoDB" "MongoDB::GridFS" "MongoDB::GridFS::File" "MongoDB::OID" "Moose" "Moose::Role" "Moose::Util::TypeConstraints" "Net::Jabber::Bot" "Net::LDAP" "Net::SMTP::TLS" "Readonly" "Time::HiRes" "Mojo" "MojoX::Log::Log4perl" "MooseX::MetaDescription::Meta::Attribute" "DateTime::Format::Natural" "Net::STOMP::Client" "IPC::Run" "XML::Smart" "Config::Auto" "Data::GUID" "Redis" "File::LibMagic" "Courriel" "List::Uniq" "Domain::PublicSuffix" "Crypt::PBKDF2" "Config::Crontab" "HTML::TreeBuilder" "HTML::FromText" "DateTime::Cron::Simple" "DateTime::Format::Strptime" "HTML::FromText" "IO::Prompt" "Proc::PID::File" "Test::Mojo" "Log::Log4perl" "File::Slurp"
    do
        DOCRES=`perldoc -l $PACKAGE 2>/dev/null`
        if [[ -z "$DOCRES" ]]; then
            echo "Installing perl module $PACKAGE"
            if [ "$PACKAGE" = "MongoDB" ]; then
                cpanm $PACKAGE --force
            else
                cpanm $PACKAGE
            fi
        fi
    done

echo "=== Configuring Apache"

# NOT SURE THIS IS NEEDED.  HELP NEEDED HERE OPEN SOURCE FRIENDS
#    echo "!!! WARNING: Apache Configuration on CentOS is funky !!!"
#    echo "!!! The install script will disable the existing "
#    echo "!!! /etc/httpd/conf.d/*.conf scripts by appending a .noscot to them"
#    echo "!!! if you need to renable them, just rename them by removeing the .noscot"
    for file in /etc/httpd/conf.d/*.conf
    do
        if [[ $file != "/etc/httpd/conf.d/scot.conf"  && $file != "/etc/httpd/conf.d/ssl.conf"]]; then
            mv $file $file.noscot
        fi
    done

MYHOSTNAME=`hostname`
#Only install apache conf if it doen't already exist

    if [ ! -e /etc/httpd/conf.d/scot.conf ]; then
        REVPROXY=$DEVDIR/etc/scot-revproxy-$MYHOSTNAME
        echo "=== Copying SCOT reverse proxy config"

        if [ ! -e $REVPROXY ]; then
            REVPROXY=$DEVDIR/etc/scot-revproxy-local-rh.conf
        fi

        cp $REVPROXY /etc/httpd/conf.d/scot.conf
    fi

SSLDIR="/etc/apache2/ssl"

if [[ ! -f $SSLDIR/scot.key ]]; then
    mkdir -p $SSLDIR/ssl/
    openssl genrsa 2048 > $SSLDIR/scot.key
    openssl req -new -key $SSLDIR/scot.key  -out /tmp/scot.csr -subj '/CN=localhost/O=SCOT Default Cert/C=US'
    openssl x509 -req -days 36530 -in /tmp/scot.csr -signkey $SSLDIR/scot.key -out $SSLDIR/scot.crt
fi

echo "=== checking scot account"
scot_user=`grep -c scot: /etc/passwd`
if [ $scot_user -ne 1 ]; then
    echo "--- Creating SCOT user account";
    useradd scot
    usermod -a -G redis scot
    usermod -a -G scot redis
    echo "scot ALL=(ALL) NOPASSWD:/usr/sbin/service redis-server restart">>/etc/sudoers
fi

echo "=== checking scot service status"
if [ -e /etc/init.d/scot3 ]; then
    echo "--- Stopping SCOT3"
    service scot3 stop
fi

if [ "$SFILESDEL" == "1" ]; then
    echo "--- Deleting SCOT Filestore $FILESTORE"
    rm -rf $FILESTORE
fi

echo "=== Creating SCOT Filestore $FILESTORE"
mkdir -p "$FILESTORE"
chown scot "$FILESTORE"
chgrp scot "$FILESTORE"
chmod g+w "$FILESTORE"

echo "=== Creating Backup Directory"
mkdir -p "$BACKUPDIR"
chown scot:scot "$BACKUPDIR"

echo "=== Installing SCOT3 service into init.d"
cp $DEVDIR/etc/scot-init /etc/init.d/scot3
chmod +x /etc/init.d/scot3
sed -i 's=/opt/sandia/webapps/scot3='$INSTDIR'=g' /etc/init.d/scot3

echo "=== installing scotPlungins daemon into init.d"
cp $DEVDIR/etc/scotPlugins /etc/init.d/scotPlugins
chmod +x /etc/init.d/scotPlugins
sed -i 's=/opt/sandia/webapps/scot3='$INSTDIR'=g' /etc/init.d/scotPlugins

echo "=== copying GeoLiteCity DB"
mkdir -p $GEODIR
cp $DEVDIR/etc/GeoLiteCity.dat $GEODIR/GeoLiteCity.dat
chmod +r $GEODIR/GeoLiteCity.dat

if [ $DELDIR = "true" ]; then
    echo "--- Removing target installation directory"
    for i in bin docs etc jabber lib log pkgs public scot.json script t templates scot.pid
    do
        rm -rf $INSTDIR/$i
    done
fi

echo "=== Copying SCOT files..."
mkdir -p $INSTDIR
cp -r $DEVDIR/* $INSTDIR
mkdir -p $INSTDIR/log

if [[ "x$MODE" = "xdev" ]]; then
    echo "--- Clearing dev logs"
    for i in $INSTDIR/log/*
    do
        cat /dev/null > $i
    done
fi

touch /var/log/scot.dev.log
chown scot:scot /var/log/scot.dev.log

touch /var/log/scot.prod.log
chown scot:scot /var/log/scot.prod.log

echo "=== installing log rotate policy"
cp $DEVDIR/etc/logrotate.scot /etc/logrotate.d/scot

if [ -e $INSTDIR/scot.conf ]; then
    echo "=== scot.conf already exists in $INSTDIR/scot.conf"
    echo "===    not overwriting.  try $0 -h for info"
else 
    $INSTDIR/bin/update_conf.pl $INSTDIR $MODE
fi

echo "=== checking $INSDIR permissions"
chown -R scot:scot $INSTDIR

if [ "x$INSTDIR" = "x" ];then
    echo "=== Installing ActiveMQ"
    ACTIVEMQ_USER=`grep -c activemq: /etc/passwd`
    if [ $ACTIVEMQ_USER -ne 1]; then
        useradd -c "ActiveMQ User" -d $WEBAPPS/activemq -M -s /bin/bash activemq
    fi
    mkdir -p /var/log
    touch /var/log/activemq.scot.log
    chown activemq /var/log/activemq.scot.log

    rm -rf $WEBAPPS/activemq
    if [ -f $AMQPKG ]; then
        tar xzf $AMQPKG --directory $WEBAPPS
    else 
        echo "--- $AMQPKG not found... Downloading"
        curl -o /tmp/apache-activemq.tar.gz -SL 'http://www.gtlib.gatech.edu/pub/apache/activemq/5.9.1/apache-activemq-5.9.1-bin.tar.gz'
        tar xzf /tmp/apache-activemq.tar.gz --directory=$WEBAPPS
        rm /tmp/apache-activemq.tar.gz
    fi
    mv $WEBAPPS/apache-activemq-5.9-SNAPSHOT $WEBAPPS/activemq
    cp $DEVDIR/etc/scotamq.xml $WEBAPPS/activemq/conf
    cp $DEVDIR/etc/jetty.xml $WEBAPPS/activemq/conf
    cp -R $DEVDIR/etc/scotaq $WEBAPPS/activemq/webapps
    mv $WEBAPPS/activemq/webapps/scotaq $WEBAPPS/activemq/webapps/scot
    cp $DEVDIR/etc/activemq-init /etc/init.d/activemq
    chmod +x /etc/init.d/activemq
    chown -R activemq.activemq $WEBAPPS/activemq
    service activemq start
fi
        
echo "=== Starting Scot"


MYIP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
echo "=== Restarting apache..."
    service httpd restart

echo "=== installing start scripts"
    chkconfig scot3 on
    chkconfig scotPlugins on
    chkconfig activemq on

echo "=== Starting MongoDB"
mkdir -p $DBDIR
cat /dev/null > /var/log/mongodb/mongod.log
chown mongod:mongod /var/log/mongodb/mongod*log /data/db

if [[ $DOCKERINSTALL == "true" ]]; then
    /usr/bin/mongod --quiet --logpath /var/log/mongodb/mongod.log --logappend&
else
    service mongod stop
    service mongod start
fi

COUNTER=0
grep -q 'waiting for connections on port' /var/log/mongodb/mongod.log

while [[ $? != 0 && $COUNTER -lt 100 ]]; do
    sleep 1
    let COUNTER+=1
    echo "... waiting for mongodb to init... ($COUNTER seconds)"
    grep -q 'waiting for connections on port' /var/log/mongodb/mongod.log
done


MONGOADMIN=$(mongo scotng-prod --eval "printjson(db.users.count({username:'admin'}))" --quiet)

if [ "$MONGOADMIN" == "0" ] || [ "$RESETDB" == "1" ] ; then

        PASSWORD=$(dialog --stdout --nocancel --title "Set SCOT Admin Password" --backtitle "SCOT Installer" --inputbox "Choose a SCOT Admin login password" 10 70)
        set='$set'
        HASH=`$DEVDIR/bin/passwd.pl $PASSWORD`

        if [[ $RESETDB == "1" ]]; then
            mongo scotng-prod $DEVDIR/bin/reset_db.js
        fi

        #Create SCOT admin account for initial setup
        mongo scotng-prod $DEVDIR/etc/admin_user.js
        mongo scotng-prod --eval "db.users.update({username:'admin'}, {$set:{hash:'$HASH'}})"
        dialog --title "Install Completed" --msgbox "\n Browse to https://$MYIP to finish SCOT configuration\n    Username=admin\n    Password=$PASSWORD" 10 70

        if [[ $RESETDB == "1" ]]; then
            $DEVDIR/bin/init_db.pl $PASSWORD
        fi
fi

echo "========================"
echo "==  Install Finished  =="
echo "========================"




