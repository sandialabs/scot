#!/bin/bash

#TODO: Quote EVEryThING!!!

#Stop at an undefined variable
# set -u #KEEP THIS COMMENTED OUT!!!!
# If a pipe fails, make sure to stop, all of these are to prevent
# mucking up the system if there is an issue with the install script
set -o pipefail

readonly DEVDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly WEBAPPS='/opt/sandia/webapps'
readonly INSTDIR='/opt/sandia/webapps/scot3'
readonly FILESTORE='/opt/scotfiles'
readonly CONF="$INSTDIR/etc/scot.json"
readonly INSTLOG='/tmp/scot.install.log'
DELDIR='false'
RESETDB=0
if [ -z "$DOCKERINSTALL" ]; then
  DOCKERINSTALL="False"
fi

# Used for output formatting
blue='\e[0;34m'
green='\e[0;32m'
yellow='\e[0;33m'
red='\e[0;31m'
NC='\e[0m' # No Color

echo "################################"
echo "======  SCOT3 Installer  ======="
echo "Email:  scot-dev@sandia.gov"
echo "################################"


OS=`lsb_release -i | cut -s -f2`
if [[ "$OS" == "Ubuntu " ]]; then
    echo "This installer only works on Ubuntu.  If you want a really easy install experience, try the SCOT Virtual Machine from our website."
    exit 1
fi

OSVERSION=`lsb_release -r | cut -s -f2 | cut -d. -f 1`
if [[ $(($OSVERSION+0)) -lt 12 ]]; then
    echo "This installer only works on Ubuntu 12.04LTS and above"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or using sudo!"
    exit 1
fi

# The Docker installer only has curl installed and Ubuntu only has wget installed by default
if [[ $DOCKERINSTALL != "True" ]]; then
   wget -qO- http://getscot.sandia.gov &>/dev/null
else
  curl http://getscot.sandia.gov &>/dev/null
fi

if [ "$?" != 0 ]; then
  echo "Couldn't reach the internet, and SCOT needs an internet connection to install.  Do you use a proxy?.  If so, remember to add the proxy to /etc/apt/apt.conf since APT doesn't respect HTTP_PROXY env variables"
  echo "Exiting..."
  exit;
fi


INSTMODE=''
MODE='production'
while getopts "dsfrm:" opt; do
    case $opt in
        d)
            echo "Deleting installation directory..."
            DELDIR="true"
            ;;
        s)
            echo "Installing only SCOT code"
            INSTMODE="SCOTONLY"
            ;;
        m)
            echo "MODE: $OPTARG"
            MODE=$OPTARG
            ;;
        r)
            echo "Will Reset DB"
            RESETDB=1
            ;;
        f)
            echo "Will Delete $FILESTORE directory and contents"
            SFILESDEL=1
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            exit 1
            ;;
        \?)
            echo "Invalid -$OPTARG";
            echo ""
            echo "Usage: $0 [-f] [-s] [-m mode] [-r] [-d]"
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


#if [[ "x$MODE" = "x" ]];
#then
#    MODE="production"
#fi

#Check to see if mongo repo is in sources
if [[ $DOCKERINSTALL != "True" ]]; then
  if grep --quiet mongo /etc/apt/sources.list; then
    echo  ""
  else
    echo "Adding Mongo 10Gen repo and updating apt-get caches"
    echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" >> /etc/apt/sources.list
    apt-key add $DEVDIR/etc/mongo_10gen.key
    apt-get update
  fi

  echo "Installing apt packages"
  apt-get -qq install libapache2-mod-authnz-external dialog libcurses-perl libmagic-dev make libxml-perl libyaml-perl perlmagick perltidy perl-doc groff libwww-mechanize-perl libjson-perl librose-db-perl libtree-simple-perl libtask-weaken-perl libtree-simple-visitorfactory-perl libalgorithm-c3-perl libapparmor-perl libarchive-zip-perl libauthen-krb5-simple-perl libauthen-sasl-perl libb-hooks-endofscope-perl libb-keywords-perl libbit-vector-perl libcache-perl libcairo-perl libcarp-assert-more-perl libcarp-assert-perl libcarp-clan-perl libcgi-simple-perl libclass-accessor-perl libclass-c3-adopt-next-perl libclass-c3-perl libclass-c3-xs-perl libclass-data-inheritable-perl libclass-errorhandler-perl libclass-factory-util-perl libclass-inspector-perl  libclass-singleton-perl libclone-perl libclone-pp-perl libcompress-bzip2-perl libconfig-tiny-perl libdata-dump-perl libdata-optlist-perl libdate-manip-perl libdatetime-format-builder-perl libdatetime-format-mysql-perl libdatetime-format-pg-perl libdatetime-format-strptime-perl libdatetime-locale-perl libdatetime-perl libdatetime-timezone-perl libdbd-mysql-perl libdbd-pg-perl libdbi-perl libdevel-globaldestruction-perl libdevel-stacktrace-perl libdevel-symdump-perl  liberror-perl libexception-class-perl libextutils-autoinstall-perl  libfcgi-perl libfile-copy-recursive-perl libfile-homedir-perl libfile-modified-perl libfile-nfslock-perl libfile-remove-perl libfile-searchpath-perl libfile-slurp-perl libfile-spec-perl libfile-which-perl libfont-afm-perl libfreezethaw-perl libglib-perl libgnome2-canvas-perl libgnome2-perl libgnome2-vfs-perl libgtk2-perl libheap-perl libhtml-clean-perl libhtml-format-perl libhtml-parser-perl libhtml-tagset-perl libhtml-template-perl libhtml-tree-perl libhttp-body-perl libhttp-request-ascgi-perl libhttp-response-encoding-perl libhttp-server-simple-perl libio-socket-ssl-perl libio-string-perl libio-stringy-perl libjson-perl libjson-xs-perl liblingua-stem-snowball-perl liblist-moreutils-perl liblocale-gettext-perl liblwp-authen-wsse-perl libmailtools-perl libmime-types-perl libmldbm-perl libmodule-corelist-perl libmodule-install-perl libmodule-scandeps-perl libmoose-perl libmoosex-emulate-class-accessor-fast-perl libmoosex-methodattributes-perl libmoosex-types-perl libmro-compat-perl libnamespace-autoclean-perl libnamespace-clean-perl libnet-daemon-perl libnet-dbus-perl libnet-jabber-perl libnet-libidn-perl libnet-ssleay-perl libnet-xmpp-perl libpango-perl libpar-dist-perl libparams-util-perl libparams-validate-perl libparse-cpan-meta-perl libparse-debianchangelog-perl libpath-class-perl libperl-critic-perl libplrpc-perl libpod-coverage-perl libpod-spell-perl libppi-perl libreadonly-perl libreadonly-xs-perl librose-datetime-perl librose-db-object-perl librose-db-perl librose-object-perl librpc-xml-perl libscope-guard-perl libscope-upper-perl libsphinx-search-perl libsql-reservedwords-perl libstring-format-perl libstring-rewriteprefix-perl libsub-exporter-perl libsub-install-perl libsub-name-perl libsub-uplevel-perl libtask-weaken-perl libterm-readkey-perl libtest-exception-perl libtest-longstring-perl libtest-mockobject-perl libtest-perl-critic-perl libtest-pod-coverage-perl libtest-pod-perl libtest-www-mechanize-perl libtext-charwidth-perl libtext-iconv-perl libtext-simpletable-perl libtext-wrapi18n-perl libtie-ixhash-perl libtime-clock-perl libtimedate-perl libtree-simple-perl libtree-simple-visitorfactory-perl libuniversal-can-perl libuniversal-isa-perl liburi-fetch-perl liburi-perl libuuid-perl libvariable-magic-perl libwww-mechanize-perl libwww-perl libxml-atom-perl libxml-dom-perl libxml-libxml-perl libxml-libxslt-perl libxml-namespacesupport-perl libxml-parser-perl libxml-perl libxml-regexp-perl libxml-sax-expat-perl libxml-sax-perl libxml-stream-perl libxml-twig-perl libxml-xpath-perl libxml-xslt-perl libyaml-perl libyaml-syck-perl libyaml-tiny-perl perl perl-base perl-doc perl-modules perlmagick perltidy libgssapi-krb5-2 libkrb5support0 libkrb5-3 krb5-doc gcc lynx curl mongodb-org git-core java-common apache2 libapache2-mod-proxy-html libapache2-mod-rpaf libimlib2-dev libimlib2 redis-server starman libgeoip-dev default-jre libplack-perl cpanminus libfile-libmagic-perl libmoosex-types-common-perl


  echo  "Installing Perl Modules"
  for PACKAGE in  "Curses::UI" "Number::Bytes::Human" "Sys::RunAlone" "Parallel::ForkManager" "DBI" "Encode" "FileHandle" "File::Slurp" "File::Temp" "File::Type" "Geo::IP" "HTML::Entities" "HTML::Scrubber" "HTML::Strip" "HTML::StripTags" "JSON" "Log::Log4perl" "Mail::IMAPClient" "Mail::IMAPClient::BodyStructure" "MongoDB" "MongoDB::GridFS" "MongoDB::GridFS::File" "MongoDB::OID" "Moose" "Moose::Role" "Moose::Util::TypeConstraints" "Net::Jabber::Bot" "Net::LDAP" "Net::SMTP::TLS" "Readonly" "Time::HiRes" "Mojo" "MojoX::Log::Log4perl" "MooseX::MetaDescription::Meta::Attribute" "DateTime::Format::Natural" "Net::STOMP::Client" "IPC::Run" "XML::Smart" "Config::Auto" "Data::GUID" "Redis" "File::LibMagic" "Courriel" "List::Uniq" "Domain::PublicSuffix" "Crypt::PBKDF2" "Config::Crontab" "HTML::TreeBuilder HTML::FromText" "DateTime::Cron::Simple" "HTML::FromText" "IO::Prompt" "Proc::PID::File"

  do
      DOCRES=`perldoc -l $PACKAGE 2>/dev/null`
      if [[ -z "$DOCRES" ]]
      then
         echo "Installing perl module $PACKAGE"
         if [ "$PACKAGE" = "MongoDB" ]
         then
            cpanm $PACKAGE --force
         else
            cpanm $PACKAGE
        fi
      fi
  done
fi

#remove the default apache webpage which blocks our 80->443 redirect
if [ -e /etc/apache2/sites-enabled/000-default.conf ]; then
  rm -f /etc/apache2/sites-enabled/000-default.conf
fi


echo -e "${yellow}Configuring Apache${NC}"
a2enmod -q proxy
a2enmod -q proxy_http
a2enmod -q ssl
a2enmod -q headers
a2enmod -q rewrite
a2enmod -q authnz_ldap
if [[ ! -f /etc/apache2/ssl/scot.key ]]
then
  mkdir -p /etc/apache2/ssl/
  openssl genrsa 2048 > /etc/apache2/ssl/scot.key
  openssl req -new -key /etc/apache2/ssl/scot.key  -out /tmp/scot.csr -subj '/CN=localhost/O=SCOT Default Cert/C=US'
  openssl x509 -req -days 36530 -in /tmp/scot.csr -signkey /etc/apache2/ssl/scot.key -out /etc/apache2/ssl/scot.crt

fi


#If the SCOT user isn't added, do so (we run the website as this reduced user)
scot_user=`grep -c scot: /etc/passwd`
if [ $scot_user -ne 1 ]
then
    echo "Creating SCOT user account one...";
    useradd scot
    usermod -a -G redis scot
    usermod -a -G scot redis
    echo "scot ALL=(ALL) NOPASSWD:/usr/sbin/service redis-server restart" >> /etc/sudoers
fi


#Only stop scot3 service if it already exists
if [ -e /etc/init.d/scot3 ]
then
  echo "Stopping SCOT3 service"
  service scot3 stop
fi

if [ "$SFILESDEL" == "1" ]; then
    echo "Deleting Filestore..."
    rm -rf $FILESTORE
fi

echo ""
echo "Creating Filestore directory $FILESTORE"
mkdir -p "$FILESTORE"
chown scot "$FILESTORE"
chgrp scot "$FILESTORE"
chmod g+w "$FILESTORE"


echo "Creating backups directory"
mkdir -p "$INSTDIR/backups"
chown scot "$INSTDIR/backups"

#Installing scot3 service into init.d
cp $DEVDIR/etc/scot-init /etc/init.d/scot3
chmod +x /etc/init.d/scot3
#Update install dir in daemon
sed -i 's=/opt/sandia/webapps/scot3='$INSTDIR'=g' /etc/init.d/scot3

#Installing scotPlugins daemon into init.d
cp $DEVDIR/etc/scotPlugins /etc/init.d/scotPlugins
chmod +x /etc/init.d/scotPlugins
#Update install dir in daemon
sed -i 's=/opt/sandia/webapps/scot3='$INSTDIR'=g' /etc/init.d/scot3

#Copying free GeoLiteCity DB
mkdir -p /usr/local/share/GeoIP/
cp $DEVDIR/etc/GeoLiteCity.dat /usr/local/share/GeoIP/GeoLiteCity.dat
chmod +r /usr/local/share/GeoIP/GeoLiteCity.dat
chown scot /usr/local/share/GeoIP/GeoLiteCity.dat

#echo "Removing SCOT3 webapps directory"
if [ $DELDIR = "true" ]
then
    for i in bin docs etc jabber lib log pkgs public scot.json script t templates scot.pid
        do
            rm -rf $INSTDIR/$i
        done
fi

echo "Copying files ..."
mkdir -p $INSTDIR

cp -r $DEVDIR/* $INSTDIR
mkdir -p $INSTDIR/log

#Only clear the logs if we are in dev mode
#losing production logs sucks
if [[ "x$MODE" = "xdev" ]];
then
   echo "Clearing dev logs"
   for i in $INSTDIR/log/*
   do
       cat /dev/null > $i
   done
fi

touch /var/log/scot.dev.log
touch /var/log/scot.prod.log
chown scot /var/log/scot.prod.log
chgrp scot /var/log/scot.prod.log
chown scot /var/log/scot.dev.log
chgrp scot /var/log/scot.dev.log

cp $DEVDIR/etc/logrotate.scot /etc/logrotate.d/scot

if [ -e $INSTDIR/scot.conf ]; then
  echo "Scot.conf already exists in $INSTDIR/scot.conf, not over-writing, try $0 -h for info"
else
  $INSTDIR/bin/update_conf.pl $INSTDIR $MODE
fi

chown -R scot.scot $INSTDIR
#mkdir -p $INSTDIR/jabber
#chgrp scotjabber $INSTDIR/jabber

if [ "x$INSTMODE" = "x" ];
then

echo -e "${yellow}Installing ActiveMQ${NC}"
#TODO: Check if user exists, and add if doesn't
ACTIVEMQ_USER=`grep -c activemq: /etc/passwd`
if [ $ACTIVEMQ_USER -ne 1 ]; then
   useradd -c "ActiveMQ User" -d /opt/sandia/webapps/activemq -M -s /bin/bash activemq
fi
mkdir -p /var/log/
touch /var/log/activemq.scot.log
chown activemq /var/log/activemq.scot.log
#TODO: Check for user changes before just blapping over this
    rm -rf $WEBAPPS/activemq
    if [ -f $DEVDIR/pkgs/apache-activemq-5.9-20130708.151752-73-bin.tar.gz ];then
       tar xzf $DEVDIR/pkgs/apache-activemq-5.9-20130708.151752-73-bin.tar.gz --directory=$WEBAPPS
    else
       echo -e "${yellow}apache-activemq-5.9.. not found, downloading file now.${NC}"
       curl -o /tmp/apache-activemq.tar.gz -SL 'http://www.gtlib.gatech.edu/pub/apache/activemq/5.9.1/apache-activemq-5.9.1-bin.tar.gz'
        tar xzf /tmp/apache-activemq.tar.gz --directory=$WEBAPPS
        rm /tmp/apache-activemq.tar.gz
    fi
    mv $WEBAPPS/apache-activemq-5.9-SNAPSHOT $WEBAPPS/activemq
#TODO: Make sure no hard coded paths
    cp $DEVDIR/etc/scotamq.xml $WEBAPPS/activemq/conf
    cp $DEVDIR/etc/jetty.xml $WEBAPPS/activemq/conf
    cp -R $DEVDIR/etc/scotaq $WEBAPPS/activemq/webapps
    mv $WEBAPPS/activemq/webapps/scotaq $WEBAPPS/activemq/webapps/scot
#TODO: Adjust for INSTDIR
    cp $DEVDIR/etc/activemq-init /etc/init.d/activemq
    chmod +x /etc/init.d/activemq
    chown -R activemq.activemq $WEBAPPS/activemq
    service activemq start
#TODO: Verify stat worked

fi


touch /var/log/scot.dev.log
touch /var/log/scot.prod.log
chgrp scot /var/log/scot*
chmod g+w /var/log/scot*

echo -e "${yellow}Starting SCOT app server${NC}"
service scot3 start
#TODO: Verify SCOT started

MYHOSTNAME=`hostname`
#Only install apache conf if it doen't already exist
if [ ! -e /etc/apache2/sites-enabled/scot.conf ]; then
   REVPROXY=$DEVDIR/etc/scot-revproxy-$MYHOSTNAME
   echo "Copying SCOT reverse proxy config"
   if [ ! -e $REVPROXY ]; then
       REVPROXY=$DEVDIR/etc/scot-revproxy-local.conf
   fi
   cp $REVPROXY /etc/apache2/sites-enabled/scot.conf
fi


MYIP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
echo -e "${yellow}Restarting apache...${NC}"
service apache2 restart
update-rc.d scot3 defaults
update-rc.d scotPlugins defaults
update-rc.d activemq defaults



echo -e "${yellow}Starting mongod...${NC}"
# Initialize a mongo data folder and logfile
mkdir -p /data/db
# Start mongodb with logging
# --logpath    Without this mongod will output all log information to the standard output.
# --logappend  Ensure mongod appends new entries to the end of the logfile. We create it first so that the below tail always finds something

if [[ $DOCKERINSTALL == "True" ]]; then
  echo '' > /var/log/mongodb/mongod.log
  chown -R mongodb /var/log/mongodb/mongod.log /data/db
  chgrp mongodb /var/log/mongodb/mongod.log /data/db

  /usr/bin/mongod  --quiet --logpath /var/log/mongodb/mongod.log --logappend &
else
  echo -e "${yellow}Restarting mongod service${NC}"
  service mongod stop
  echo '' > /var/log/mongodb/mongod.log
  chown mongodb /var/log/mongodb/mongod.log
  chgrp mongodb /var/log/mongodb/mongod.log

  service mongod start
fi

COUNTER=0
grep -q 'waiting for connections on port' /var/log/mongodb/mongod.log
while [[ $? -ne 0 && $COUNTER -lt 100 ]] ; do
    sleep 1
    let COUNTER+=1
    echo "Waiting for mongo to initialize... ($COUNTER seconds so far)"
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
    chown -R mongodb /var/log/mongodb/mongod.log /data/db
    ls -al /var/log/mongodb/mongod.log /data/db
    MONGOADMIN=$(mongo scotng-prod --eval "printjson(db.users.count({username:'admin'}))" --quiet)
    if [[ $MONGOADMIN == 1 ]]; then
      echo -e "${blue}admin/admin account successfuly added.${NC}"
    fi
  else
    PASSWORD=$(dialog --stdout --nocancel --title "Set SCOT Admin Password" --backtitle "SCOT Installer" --inputbox "Choose a SCOT Admin login password" 10 70)
    set='$set'
    HASH=`$DEVDIR/bin/passwd.pl $PASSWORD`

    if [[ $RESETDB -eq "1" ]]; then
        mongo scotng-prod $DEVDIR/bin/reset_db.js
    fi

    #Create SCOT admin account for initial setup
    mongo scotng-prod $DEVDIR/etc/admin_user.js
    mongo scotng-prod --eval "db.users.update({username:'admin'}, {$set:{hash:'$HASH'}})"
    dialog --title "Install Completed" --msgbox "\n Browse to https://$MYIP to finish SCOT configuration\n    Username=admin\n    Password=$PASSWORD" 10 70

    if [[ $RESETDB -eq "1" ]]; then
        $DEVDIR/bin/init_db.pl $PASSWORD
    fi
  fi
fi
echo "========================"
echo "==  Install Finished  =="
echo "========================"
