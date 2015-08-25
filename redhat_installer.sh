#!/bin/bash

## 
## Redhat SCOT installer
##
###	Redhat Enterprise Server 6
###	Redhat Enterprise Server 7

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

echo "=== Checking for required internet connection"
# I think this magic allows SELinux to connect
SELINUX=`sestatus`
#if [ $SELINUX -ne "SELinux status:                 disabled" ]; then
    /usr/sbin/setsebool httpd_can_network_connect 1
    /usr/sbin/setsebool -P httpd_can_network_connect 1
#fi

curl $TESTURL &>/dev/null

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

    if [[ $INSTMODE != "SCOTONLY" ]]; then

        if [[ $OS == "RedHatEnterpriseServer" ]];then
            echo "=== RedHat installation"
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
                if [ $OSVERSION == "7" ]; then

                    wget -r --no-parent -A 'epel-release-*.rpm' http://dl.fedoraproject.org/pub/epel/$OSVERSION/x86_64/e/
                    rpm -Uvh dl.fedoraproject.org/pub/epel/$OSVERSION/x86_64/e/epel-release-*.rpm
                    rm -rf dl.fedoraproject.org
                else 
# see https://troubleshootguru.wordpress.com/2014/11/19/how-to-install-redis-on-a-centos-6-5-centos-7-0-server-2/
                    wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
                    rpm -Uvh epel-release-6*.rpm
                fi
            fi

            if hash perl 2>/dev/null; then
                echo "=== perl is installed"
            else 
                yum install perl
            fi

            if hash cpanm 2>/dev/null; then
                echo "=== cpanm is installed"
            else
                yum install perl-devel
                yum install perl-CPAN
                curl -L http://cpanmin.us | perl - --sudo App::cpanminus
            fi

            yum install httpd dialog mongodb-org redis GeoIP perl-Geo-IP perl-Curses java-1.7.0-openjdk krb5-libs krb5-devel mod_ssl openssl redhat-lsb -y

            echo "=== starting redis"
            service redis start 
            chkconfig redis on

            export RPMFILEDEVEL=`rpm -qa file-devel`
            if [ "$RPMFILEDEVEL" == "" ]; then
                wget http://mirror.centos.org/centos/$OSVERSION/os/x86_64/Packages/file-devel-5.11-21.el7.x86_64.rpm
                rpm -i file-devel-5.11-21.el7.x86_64.rpm
                rm -f file-devel-5.11-21.el7.x86_64.rpm
                ### turns out this is too ancient to help instal Task::Plack
                # aaaaarg!
                # more hacks, got to hate, I mean love, redhat
                #rpm -q perl-Twiggy
                #if [[ $? == 1 ]]; then
                #    wget wget ftp://fr2.rpmfind.net/linux/dag/redhat/el6/en/x86_64/extras/RPMS/perl-Twiggy-0.1010-2.el6.rfx.noarch.rpm
                #    rpm -i --nodeps perl-Twiggy-0.1010-2.el6.rfx.noarch.rpm
                #    rm -f perl-Twiggy-0.1010-2.el6.rfx.noarch.rpm
                #fi
            fi
        else 
            echo "=== Ubuntu installation"
            if grep --quiet mongo /etc/apt/sources.list; then
                echo  ""
            else
                echo "=== Adding Mongo 10Gen repo and updating apt-get caches"
                echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" >> /etc/apt/sources.list
                apt-key add $DEVDIR/etc/mongo_10gen.key
                apt-get update
            fi

            echo "=== Installing apt packages"
            apt-get -qq install libapache2-mod-authnz-external dialog libcurses-perl libmagic-dev make libxml-perl libyaml-perl perlmagick perltidy perl-doc groff libwww-mechanize-perl libjson-perl librose-db-perl libtree-simple-perl libtask-weaken-perl libtree-simple-visitorfactory-perl libalgorithm-c3-perl libapparmor-perl libarchive-zip-perl libauthen-krb5-simple-perl libauthen-sasl-perl libb-hooks-endofscope-perl libb-keywords-perl libbit-vector-perl libcache-perl libcairo-perl libcarp-assert-more-perl libcarp-assert-perl libcarp-clan-perl libcgi-simple-perl libclass-accessor-perl libclass-c3-adopt-next-perl libclass-c3-perl libclass-c3-xs-perl libclass-data-inheritable-perl libclass-errorhandler-perl libclass-factory-util-perl libclass-inspector-perl  libclass-singleton-perl libclone-perl libclone-pp-perl libcompress-bzip2-perl libconfig-tiny-perl libdata-dump-perl libdata-optlist-perl libdate-manip-perl libdatetime-format-builder-perl libdatetime-format-mysql-perl libdatetime-format-pg-perl libdatetime-format-strptime-perl libdatetime-locale-perl libdatetime-perl libdatetime-timezone-perl libdbd-mysql-perl libdbd-pg-perl libdbi-perl libdevel-globaldestruction-perl libdevel-stacktrace-perl libdevel-symdump-perl  liberror-perl libexception-class-perl libextutils-autoinstall-perl  libfcgi-perl libfile-copy-recursive-perl libfile-homedir-perl libfile-modified-perl libfile-nfslock-perl libfile-remove-perl libfile-searchpath-perl libfile-slurp-perl libfile-spec-perl libfile-which-perl libfont-afm-perl libfreezethaw-perl libglib-perl libgnome2-canvas-perl libgnome2-perl libgnome2-vfs-perl libgtk2-perl libheap-perl libhtml-clean-perl libhtml-format-perl libhtml-parser-perl libhtml-tagset-perl libhtml-template-perl libhtml-tree-perl libhttp-body-perl libhttp-request-ascgi-perl libhttp-response-encoding-perl libhttp-server-simple-perl libio-socket-ssl-perl libio-string-perl libio-stringy-perl libjson-perl libjson-xs-perl liblingua-stem-snowball-perl liblist-moreutils-perl liblocale-gettext-perl liblwp-authen-wsse-perl libmailtools-perl libmime-types-perl libmldbm-perl libmodule-corelist-perl libmodule-install-perl libmodule-scandeps-perl libmoose-perl libmoosex-emulate-class-accessor-fast-perl libmoosex-methodattributes-perl libmoosex-types-perl libmro-compat-perl libnamespace-autoclean-perl libnamespace-clean-perl libnet-daemon-perl libnet-dbus-perl libnet-jabber-perl libnet-libidn-perl libnet-ssleay-perl libnet-xmpp-perl libpango-perl libpar-dist-perl libparams-util-perl libparams-validate-perl libparse-cpan-meta-perl libparse-debianchangelog-perl libpath-class-perl libperl-critic-perl libplrpc-perl libpod-coverage-perl libpod-spell-perl libppi-perl libreadonly-perl libreadonly-xs-perl librose-datetime-perl librose-db-object-perl librose-db-perl librose-object-perl librpc-xml-perl libscope-guard-perl libscope-upper-perl libsphinx-search-perl libsql-reservedwords-perl libstring-format-perl libstring-rewriteprefix-perl libsub-exporter-perl libsub-install-perl libsub-name-perl libsub-uplevel-perl libtask-weaken-perl libterm-readkey-perl libtest-exception-perl libtest-longstring-perl libtest-mockobject-perl libtest-perl-critic-perl libtest-pod-coverage-perl libtest-pod-perl libtest-www-mechanize-perl libtext-charwidth-perl libtext-iconv-perl libtext-simpletable-perl libtext-wrapi18n-perl libtie-ixhash-perl libtime-clock-perl libtimedate-perl libtree-simple-perl libtree-simple-visitorfactory-perl libuniversal-can-perl libuniversal-isa-perl liburi-fetch-perl liburi-perl libuuid-perl libvariable-magic-perl libwww-mechanize-perl libwww-perl libxml-atom-perl libxml-dom-perl libxml-libxml-perl libxml-libxslt-perl libxml-namespacesupport-perl libxml-parser-perl libxml-perl libxml-regexp-perl libxml-sax-expat-perl libxml-sax-perl libxml-stream-perl libxml-twig-perl libxml-xpath-perl libxml-xslt-perl libyaml-perl libyaml-syck-perl libyaml-tiny-perl perl perl-base perl-doc perl-modules perlmagick perltidy libgssapi-krb5-2 libkrb5support0 libkrb5-3 krb5-doc gcc lynx curl mongodb-org git-core java-common apache2 libapache2-mod-proxy-html libapache2-mod-rpaf libimlib2-dev libimlib2 redis-server starman libgeoip-dev default-jre libplack-perl cpanminus libfile-libmagic-perl libmoosex-types-common-perl liblog-log4perl-perl
        fi

        echo  "=== Installing Perl Modules"
        for PACKAGE in  "Try::Tiny" "Curses::UI" "Number::Bytes::Human" "Sys::RunAlone" "Parallel::ForkManager" "DBI" "Encode" "FileHandle" "File::Slurp" "File::Temp" "File::Type" "Geo::IP" "HTML::Entities" "HTML::Scrubber" "HTML::Strip" "HTML::StripTags" "JSON" "Log::Log4perl" "Mail::IMAPClient" "Mail::IMAPClient::BodyStructure" "MongoDB" "MongoDB::GridFS" "MongoDB::GridFS::File" "MongoDB::OID" "Moose" "Moose::Role" "Moose::Util::TypeConstraints" "Net::LDAP" "Net::SMTP::TLS" "Readonly" "Time::HiRes" "Mojo" "MojoX::Log::Log4perl" "MooseX::MetaDescription::Meta::Attribute" "DateTime::Format::Natural" "Net::STOMP::Client" "IPC::Run" "XML::Smart" "Config::Auto" "Data::GUID" "Redis" "File::LibMagic" "Courriel" "List::Uniq" "Domain::PublicSuffix" "Crypt::PBKDF2" "Config::Crontab" "HTML::TreeBuilder" "DateTime::Cron::Simple" "HTML::FromText" "IO::Prompt" "Proc::PID::File" "DateTime::Format::Strptime" "HTTP::Server::Simple::PSGI" "EV" "Test::Mojo" 
        do
            DOCRES=`perldoc -l $PACKAGE 2>/dev/null`
            if [[ -z "$DOCRES" ]]; then
                echo "Installing perl module $PACKAGE"
                if [ "$PACKAGE" = "MongoDB" ]; then
                    $CPANM $PACKAGE --force
                else
                    $CPANM $PACKAGE
                fi
            fi
        done
    fi

    for PACKAGE in "PSGI" "Plack" "CGI::PSGI" "CGI::PSGI" "CGI::Emulate::PSGI" "CGI::Compile" "HTTP::Server::Simple::PSGI" "Starman" "Starlet" 
    do
        $CPANM $PACKAGE
    done

echo "=== Configuring Apache"


# NOT SURE THIS IS NEEDED.  HELP NEEDED HERE OPEN SOURCE FRIENDS
#    echo "!!! WARNING: Apache Configuration on Redhat is funky !!!"
#    echo "!!! The install script will disable the existing "
#    echo "!!! /etc/httpd/conf.d/*.conf scripts by appending a .noscot to them"
#    echo "!!! if you need to renable them, just rename them by removeing the .noscot"
    for file in /etc/httpd/conf.d/*.conf
    do
        if [[ $file != "/etc/httpd/conf.d/scot.conf" && $file != "/etc/httpd/conf.d/ssl.conf" ]]; then
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

echo "+++ setting startup script to run at boot"
    chkconfig scot3 on
    chkconfig scotPlugins on
    chkconfig activemq on

echo "=== Starting MongoDB"
mkdir -p $DBDIR
cat /dev/null > /var/log/mongodb/mongod.log
chown mongod:mongod /var/log/mongodb/mongod*log /data/db

    service mongod stop
    service mongod start

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

    if [ $DOCKERINSTALL == "True" ] || [ $MODE == "test" ]; then

        echo -e "${green}Installing with docker${NC}"
        # Create SCOT admin account for initial setup
        echo "Add default admin/admin account to mongoDB..."
        set='$set'
        HASH=`$DEVDIR/bin/passwd.pl admin`
        mongo scotng-prod $DEVDIR/etc/admin_user.js
        mongo scotng-prod --eval "printjson(db.users.findOne())"
        mongo scotng-prod --eval "db.users.update({username:'admin'}, {$set:{hash:'$HASH'}})"
        mongo scotng-prod --eval "printjson(db.users.findOne())"
        chown -R mongod /var/log/mongodb/mongod.log /data/db
        ls -al /var/log/mongodb/mongod.log /data/db

        MONGOADMIN=$(mongo scotng-prod --eval "printjson(db.users.count({username:'admin'}))" --quiet)
        if [[ $MONGOADMIN == 1 ]]; then
            echo -e "${blue}admin/admin account successfuly added.${NC}"
        fi

    else

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
fi

echo "========================"
echo "==  Install Finished  =="
echo "========================"




