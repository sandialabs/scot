#!/bin/bash
#
# scot installer
#

# color output formatting
blue='\e[0;34m'
green='\e[0;32m'
yellow='\e[0;33m'
red='\e[0;31m'
NC='\033[0m'

echo -e "${blue}########"
echo "######## SCOT 3 Installer"
echo "######## Support at: scot-dev@sandia.gov"
echo -e "########${NC}"

if [[ $EUID -ne 0 ]]; then
    echo -e "${red}This script must be run as root or using sudo!${NC}"
    exit 1
fi

DEVDIR="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd )"
FILESTORE="/opt/scotfiles";
SCOTDIR="/opt/scot"
REFRESH_AMQ_CONFIG=1

. $DEVDIR/etc/install/locations.sh

echo -e "${yellow}Reading Commandline Args... ${NC}"

while getopts "adigsrflm" opt; do
    case $opt in
        a)
            echo -e "${green}--- will refresh the apt repositories ${NC}"
            REFRESHAPT="yes"
            ;;
        d)
            echo -e "${red}--- will delete installation directory $SCOTDIR ${NC}"
            DELDIR="true"
            ;;
        i)
            echo -e "${red}--- will overwrite existing /etc/init.d/scot file ${NC}"
            NEWINIT="yes"
            ;;
        g)
            echo -e "${red}--- overwrite existing GeoCity DB ${NC}"
            OVERGEO="yes"
            ;;
        m)
            echo -e "${red}--- overwrite mongodb config and restart"
            MDBREFRESH="yes"
            ;;
        s) 
            echo -e "${green}--- will install only SCOT software (no prereqs) ${NC}"
            INSTMODE="SCOTONLY"
            ;;
        r)
            echo -e "${red}--- will reset SCOT DB (warning: DATA LOSS!)"
            RESETDB=1
            ;;
        f)
            echo -e "${red}--- will delete SCOT filestore directory $FILESTORE (warning: DATA LOSS) {$NC}"
            SFILESDEL=1
            ;;
        l)
            echo -e "${red}--- will zero existing log files (warning potential data loss) {$NC}"
            CLEARLOGS=1
            ;;
        q)  
            echo -e "${red}--- will refresh ActiveMQ config and init files ${NC}"
            REFRESH_AMQ_CONFIG=1
            ;;
        \?)
            echo "!!! Invalid -$OPTARG"
            echo ""
            echo "Usage: $0 [-f][-s][-r][-d]"
            echo ""
            echo "    -f    delete $FILESTORE filestore directory and its contents"
            echo "    -s    only install the SCOT software, skip prerequisite or 3rd party software"
            echo "    -r    delete the SCOT database and install initial template"
            echo "    -d    delete $SCOTDIR intallation directory prior to install"
            echo "    -i    overwrite existing /etc/init.d/scot "
            echo "    -g    overwrite existing GeoCity db file"
            exit 1
            ;;
    esac
done

echo -e "${NC}"
echo -e "${yellow}Determining OS..."
echo -e "${NC}"

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

    echo -e "${yellow}+ installing prerequisite packages ${NC}"

    if [[ $OS == "RedHatEnterpriseServer" ]]; then
        #
        # install mongo
        #
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

        # all this sh*t is necessary to install rabbitmq from repos

        # need to see if this works only on centos
        # if so, we need to diff ReddHat from Cent, I HATE RPMS!
#        echo "+ attempting install epel-release"
#        yum install epel-release

        #
        # install rpmforge
        #
#        rfrpm="rpmforge-release-0.5.3-1.el7.rf.x86_64.rpm"
#        if [ -e $DEVDIR/$rfrpm ]; then
#            echo "= already downloaded $rfrpm"
#        else
#            echo "+ downloading rpmforge"
#            (cd $DEVDIR/pkgs && wget http://pkgs.repoforge.org/rpmforge-release/$rfrpm)
#        fi
#        (cd $DEVDIR/pkgs && rpm -Uvh $rfrpm)

        #
        # install erlang
        #
#        if grep --quiet erlang-solutions /etc/yum.repos.d/erlang.repo
#        then
#            echo "= erlang stanza present"
#        else
#            echo "+ adding erlang-solutions signing key to yum"
#            rpm --import http://packages.erlang-solutions.com/rpm/erlang_solutions.asc
#            echo "+ adding erlang stanza to yum repos"
#            erlang_releasever=$OSVERSION
#            erlang_basearch="18.2"
#            cat <<- EOF > /etc/yum.repos.d/erlang.repo
#[erlang-solutions]
#name=Centos $erlang_releasever - $erlang_basearch - Erlang Solutions
#baseurl=http://packages.erlang-solutions.com/rpm/centos/$erlang_releasever/$erlang_basearch
#gpgcheck=1
#gpgkey=http://packages.erlang-solutions.com/rpm/erlang_solutions.asc
#enabled=1
#EOF
#        fi
        # end sh*t necessary to instal rabbitmq



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
            if grep -q 10gen /etc/apt/sources.list
            then
                echo "= mongo 10Gen repo already present"
            else 
                echo "+ Adding Mongo 10Gen repo and updating apt-get caches"
                echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" >> /etc/apt/sources.list
                apt-key add $DEVDIR/etc/mongo_10gen.key
            fi

            # for possible switch to rabbitmq
            #if grep -q rabbitmq /etc/apt/sources.list
            #then
            #    echo "= rabbitmq repo already present"
            #else
            #    echo "+ Adding RabbitMQ repo and updateing apt-get caches"
            #    echo "deb http://www.rabbitmq.com/debian/ testing main" >> /etc/apt/sources.list
            #    apt-key add $DEVDIR/etc/rabbitmq.key
            #fi
        fi

        if [ "$REFRESHAPT" == "yes" ]; then
            echo "= updating apt repository"
            apt-get update > /dev/null
        fi

        echo -e "${yellow}+ installing apt packages ${NC}"

        for pkg in `cat $DEVDIR/etc/install/ubuntu_debs_list`; do
            # echo "+ package $pkg"
	    pkgs="$pkgs $pkg"
        done
        apt-get -qq install $pkgs > /dev/null
    fi

#    echo "+ configuring rabbitmq for stomp"
#    rabbitmq-plugins enable rabbitmq_stomp

###
### ActiveMQ install
###
    echo -e "${yellow}= checking activmq user has been created${NC}"
    AMQ_USER=`grep -c activemq: /etc/passwd`
    if [ $AMQ_USER -ne 1 ]; then
        echo "+ adding activemq user"
        useradd -c "ActiveMQ User" -d $AMQDIR -M -s /bin/bash activemq
    fi

    echo "= checking activemq logging directories"
    if [ ! -d /var/log/activemq ]; then
        echo "+ creating /var/log/activemq"
        mkdir -p /var/log/activemq
        touch /var/log/activemq/scot.amq.log
        chown -R activemq.activemq /var/log/activemq
        chmod -R g+w /var/log/activemq
    fi

    if [ $REFRESH_AMQ_CONFIG == 1 ]; then
        echo "+ adding/refreshing scot activemq config"
        cp $DEVDIR/etc/scotamq.xml     $AMQDIR/conf
        cp $DEVDIR/etc/jetty.xml       $AMQDIR/conf
        cp -R $DEVDIR/etc/scotaq       $AMQDIR/webapps
        mv $AMQDIR/webapps/scotaq      $AMQDIR/webapps/scot
        cp $DEVDIR/etc/activemq-init   /etc/init.d/activemq
        chmod +x /etc/init.d/activemq
        chown -R activemq.activemq $AMQDIR
    fi

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
            chown activemq.activemq $AMQDIR
        fi

        tar xf /tmp/$AMQTAR --directory /tmp
        mv /tmp/apache-activemq-5.14-SNAPSHOT/* $AMQDIR

        echo "+ starting activemq"
        service activemq start
    fi

###
### Perl Module installation
###

    echo -e "${yellow}+ installing Perl Modules${NC}"

    for mod in `cat $DEVDIR/etc/install/perl_modules_list`; do
        DOCRES=`perldoc -l $mod 2>/dev/null`
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

    echo -e "${yellow}= Configuring Apache ${NC}"

    MYHOSTNAME=`hostname`

    if [[ $OS == "RedHatEnterpriseServer" ]]; then

        if [ ! -e /etc/httpd/conf.d/scot.conf ]; then
            echo -e "${yellow}+ adding scot configuration${NC}"
            REVPROXY=$DEVDIR/etc/scot-revproxy-$MYHOSTNAME
            if [ ! -e $REVPROXY ]; then
                echo -e "${red}= custom apache config for $MYHOSTNAME not present, using defaults${NC}"
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
            rm $MODSENABLED/000-default.conf    # exists as symbolic link
        fi

        a2enmod -q proxy
        a2enmod -q proxy_http
        a2enmod -q ssl
        a2enmod -q headers
        a2enmod -q rewrite
        a2enmod -q authnz_ldap

        if [ ! -e /etc/apache2/sites-enabled/scot.conf ]; then
            echo -e "${yellow}+ adding scot configuration${NC}"
            REVPROXY=$DEVDIR/etc/scot-revproxy-$MYHOSTNAME
            if [ ! -e $REVPROXY ]; then
                echo -e "${red}= custom apache config for $MYHOSTNAME not present, using defaults${NC}"
                REVPROXY=$DEVDIR/etc/scot-revproxy-local.conf
            fi
            cp $REVPROXY /etc/apache2/sites-available/scot.conf
            ln -s /etc/apache2/sites-available/scot.conf /etc/apache2/sites-enabled/scot.conf
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
            echo -e "${red}- overwriting existing GeoLiteCity.dat file"
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
    if [ $OS == "RedHatEnterpriseServer" ]; then
        cp $DEVDIR/etc/scot-centos-init /etc/init.d/scot
    fi
    if [ $OS == "Ubuntu" ]; then
        cp $DEVDIR/etc/scot-init /etc/init.d/scot
    fi
    chmod +x /etc/init.d/scot
    sed -i 's=/instdir='$SCOTDIR'=g' /etc/init.d/scot
fi
    
###
### Set up Filestore directory
###
echo -e "${yellow} Checking SCOT filestore $FILESTORE ${NC}"

if [ "$SFILESDEL" == "1" ]; then
    echo -e "${red}- removing existing filestore${NC}"
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
echo -e "${yellow} setting up backup directory $BACKDIR ${NC}"
mkdir -p $BACKUPDIR
chown scot:scot $BACKUPDIR

###
### install the scot
###

echo -e "${yellow} installing SCOT files ${NC}"

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

usermod -a -G scot www-data
cp -r $DEVDIR/* $SCOTDIR/
chown -R scot.scot $SCOTDIR
chmod -R 755 $SCOTDIR/bin

###
### Logging file set up
###
echo -e "${yellow} setting up Log dir $LOGDIR ${NC}"
if [ ! -d $LOGDIR ]; then
    mkdir -p $LOGDIR
fi

chown scot.scot $LOGDIR
chmod g+w $LOGDIR

if [ "$CLEARLOGS"  == "1" ]; then
    echo -e "${red}- clearing any existing scot logs"
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
    echo -e "${red}- Dropping mongodb scot database!${NC}"
    mongo scot-prod $DEVDIR/bin/reset_db.js
fi

MONGOADMIN=$(mongo scot-prod --eval "printjson(db.users.count({username:'admin'}))" --quiet)

if [ "$MONGOADMIN" == "0" ] || [ "$RESETDB" == "1" ]; then
    PASSWORD=$(dialog --stdout --nocancel --title "Set SCOT Admin Password" --backtitle "SCOT Installer" --inputbox "Choose a SCOT ADmin login password" 10 70)
    set='$set'
    HASH=`$DEVDIR/bin/passwd.pl $PASSWORD`

    mongo scot-prod $DEVDIR/etc/admin_user.js
    mongo scot-prod --eval "db.users.update({username:'admin'}, {$set:{hash:'$HASH'}})"

fi

if [ ! -e /etc/init.d/scot ]; then
    echo -e "${yellow}+ missing /etc/init.d/scot, installing...${NC}"
    if [ $OS == "RedHatEnterpriseServer" ]; then
        cp $DEVDIR/etc/scot-centos-init /etc/init.d/scot
    fi
    if [ $OS == "Ubuntu" ]; then
        cp $DEVDIR/etc/scot-init /etc/init.d/scot
    fi
    chmod +x /etc/init.d/scot
    sed -i 's=/instdir='$SCOTDIR'=g' /etc/init.d/scot
fi

echo "= restarting scot"
/etc/init.d/scot restart

echo "----"
echo "----"
echo "---- Install completed"
echo "----"
echo "----"
