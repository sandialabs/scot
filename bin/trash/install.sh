#!/bin/bash

##
## SCOT installer
##

set -o pipefail

DEVDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTDIR='/opt/scot'
FILESTORE='/opt/scotfiles'
INSTLOG='/tmp/scot.install.log'
TESTURL="http://getscot.sandia.gov"
CPANM="/usr/local/bin/cpanm"
APT_PKGS="$DEVDIR/etc/apt_packages.install.txt"
PERLPKGS="$DEVDIR/etc/perl_modules.install.txt"
YUM_PKGS="$DEVDIR/etc/yum_packages.install.txt"
LOGDIR="/var/log"

# color output formatting
blue='\e[0;34m'
green='\e[0;32m'
yellow='\e[0;33m'
red='\e[0;31m'
NC='\e[-m'

echo -e "${green}"
echo "### "
echo "### SCOT installer"
echo "### support at: scot-dev@sandia.gov"
echo "### "
echo -e "${NC}"

if [[ $EUID -ne 0 ]]; then
    echo "!!!"
    echo -e "${red} !!! This script must be run as ROOT or using SUDO !!! ${NC}"
    echo "!!!"
    exit 2
fi

if hash wget 2>/dev/null; then
    wget -qO- $TESTURL &>/dev/null
else 
    curl $TESTURL &>/dev/null
fi

if [ "$?" != 0 ]; then
    echo -e "${red}"
    echo "!!! Unable to reach $TESTURL !!!"
    echo -e "${NC}"
    echo "SCOT installation relies on having an internet connection available "
    echo " for the installation of libraries and helper software."
    echo "Possible causes to check: "
    echo "  1.  if using a proxy, ensure that http_proxy environment variable is set"
    echo "  2.  make sure system has wget or curl installed"
    echo "  3.  make sure your network can reach the internet"
    exit 3
fi

echo -n "Determining OS..."

DISTRO=`./etc/determine_os.sh | cut -d ' ' -f 2`
echo "  $DISTRO based system detected."

if [[ $DISTRO == "RedHat" ]]; then
    if ! hash lsb_release 2>/dev/null; then
        # suprisingly, RH/Cent systems might need this installed
        yum install redhat-lsb
    fi
fi

OS=`lsb_release -i | cut -s -f 2`
OSVERSION=`lsb_release -r | cut -s -f2 | cut -d. -f 1`

echo "LSB results = $OS : $OSVERSION"
echo ""
echo "Checking install options: "

while getopts "dsfrym:" opt; do
    case $opt in 
        d)
            echo -e "${red} Deleting installation directory $INSTDIR${NC}"
            DEL_INSTDIR="true"
            ;;
        s)
            echo -e "${green} Installing SCOT application code ONLY${NC}"
            INSTMODE="SCOTONLY"
            ;;
        f)
            echo -e "${red} Delete files in $FILESTORE. (warning data will be destroyed)${NC}"
            DEL_FILESTORE=1
            ;;
        r)
            echo -e "${red} Resting SCOT DB, existing data will be lost!${NC}"
            RESETDB=1
            ;;
        y)
            echo -e "${red} Do NOT wait for confirmation. (I know what I'm doing)${NC}"
            CONFIRMED=1
            ;;
        m)
            echo -e "${green} MODE will be set to $OPTARG ${NC}"
            MODE=$OPTARG
        :)
            echo -e "${yellow} Option -$OPTARG requires an argument!"
            exit 1
            ;;
        \?)
            echo -e "${yellow} Invalid -$OPTARG"
            echo -e "${NC}"
            echo ""
            echo "      -f        deletes filestore directory and contents"
            echo "      -s        only install SCOT, skip 3rd party software"
            echo "      -m mode   mode is dev or prod"
            echo "      -r        will reset mongo databases (data loss!)"
            echo "      -d        delete existing scot install"
            echo "      -y        I know what I'm doing, do not ask for confirmation"
            exit 1
            ;;
    esac
done

if [[ $CONFIRMED != 1 ]]; then
    echo ""
    read -p "Do you wish to proceed with installation?" yn
    case $yn in 
        [Yy]* ) 
            break;;
        * )
            echo "installation cancelled"
            exit;;
    esac
fi

if [[ $INSTMODE != "SCOTONLY" ]];
then

    if [ "$OS" == "CentOS" ] || [ "$OS" == "RedHat" ]; then
        echo "+ creating yum stanza for mongodb"
        cat <<- EOF > /etc/yum.repos.d/mongodb.repo
[mongodb]
name=MongoDB Repository
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64/
gpgcheck=0
enabled=1
EOF
        echo "- installing yum packages"
        yum groupinstall "Development Tools" -y
        yum install wget git file-devel openssl-devel libcurl-devl -y

        if hash perl 2>/dev/null; then
            echo "= perl is installed."
            perlver=`perl -V | grep perl5 | cut -d ' ' -f 8`
            if [ $perlver -lt 18 ]; then
                echo "${red}- WARNING: might not work with Perl version installed.  Need 5.18${NC}"
            fi
        else 
            echo "+ installing perl and perl-Net-SSLeay"
            yum install perl perl-Net-SSLeay -y
        fi

        if hash cpanm 2>/dev/null; then
            echo "= cpanm installed"
        else 
            echo "+ installing cpanm"
            yum install perl-devel -y
            yum install perl-CPAN -y
            curl -L http://cpanmin.us | perl - --sudo App::cpanminus
        fi

        while IFS= read -r line; do
            echo "+ installing $line"
            yum install $line -y
        done < $YUM_PCKGS
    
        APACHE_CONF_DIR="/etc/httpd/conf.d"
        SCOT_APACHE_CONF=$DEVDIR/etc/scot-revproxy-local-rh.conf

    # Ubuntu stuff follows
    else

        if grep --quiet mongo /etc/apt/sources.list; then
            echo "= mongo already in apt-get sources.list"
        else
            echo "+ Adding Mongo 10Gen repo and updating apt-get caches"
            echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" >> /etc/apt/sources.list
            apt-key add $DEVDIR/etc/mongo_10gen.key
            apt-get update
        fi

        while IFS= read -r line; do
            echo "+ apt-get install $line"
            apt-get -qq install $line
        done < $APT_PKGS


        APACHE_CONF_DIR="/etc/apache2/sites-enabled"
        SCOT_APACHE_CONF=$DEVDIR/etc/scot-revproxy-local.conf
        SSL_DIR=/etc/apache2/ssl

    fi

    # all distros do this
    while IFS= read -r line; do
        echo "+ perl module $line"
        cpanm $line
    done < $PERLPKGS

    echo "- checking apache config"
    if [ ! -e $APACHE_CONF_DIR/scot.conf ]; then
        echo "+ adding scot.conf to $APACHE_CONF_DIR"
        cp $SCOT_APACHE_CONF $APACHE_CONF_DIR/scot.conf
    else 
        echo "= scot.conf already exists, remove and reinstall if you wish to replace"
    fi

    SSL_DIR=/etc/apache2/ssl

    # rh/cent do not have a /etc/apache2/ssl, but we will create it because
    # the scot-rev-proxy looks there.  simpler, for now
    # creating a self signed ssl key, you can replace later
    echo "- Checking for scot certs"
    if [[ -f  $SSLDIR/scot.key ]]; then
        echo "+ creating scot.key and installing"
        mkdir -p $SSLDIR/ssl/   
        openssl genrsa 2048 > $SSLDIR/scot.key
        openssl req -new -key $SSLDIR/scot.key -out /tmp/scot.csr -subj '/CN=localhost/O=SCOT Default Cert/C=US'
        openssl x509 -req -days 36530 -in /tmp/scot.csr -signkey $SSLDIR/scot.key -out $SSLDIR/scot.crt
    fi

    echo "= Checking for Scot group"
    scot_group=`grep -c scot: /etc/group`
    if [ $scot_group -ne 1 ]; then 
        echo "+ creating scot group"
        groupadd scot
    else
        echo "- scot group already exists"
    fi

    echo "= Checking for scot user"
    scot_user=`grep -c scot: /etc/passwd`
    if [ $scot_user -ne 1 ]; then
        echo "+ creating scot user"
        useradd scot
        usermod -a -G scot scot
    fi

    echo "= creating backup directory $BACKUPDIR"
    mkdir -p $BACKUPDIR
    chown scot:scot $BACKUPDIR

    echo "+ installing scot server into /etc/init.d"
    cp $DEVDIR/etc/scot-init /etc/init.d/scot
    chmod +x /etc/init.d/scot
    sed -i 's=/opt/sandia/sebapps/scot3='$INSTDIR'=g' /etc/init.d/scot3

    echo "= checking GeoLiteCity DB"
    mkdir -p $GEODIR
    if [ ! -e $GEODIR/GeoLiteCity.dat ]; then
        cp $DEVDIR/etc/GeoLiteCity.dat $GEODIR/GeoLiteCity.dat
        chmod +r $GEODIR/GeoLiteCity.dat
    fi

    echo "+ touching scot log files in $LOGDIR"
    touch $LOGDIR/scot.prod.log
    chown scot:scot $LOGDIR/scot.prod.log

    echo "= checking for existing scot logrotate policy"
    if [ ! -e /etc/logrotate.d/scot ]; then
        echo "+ installing log rotate policy"
        cp $DEVDIR/etc/logrotate.scot /etc/logrotate.d/scot
    else 
        echo "- exists. remove and reinstall if you wish to replace."
    fi

fi

if [ $DEL_INSTDIR == "1" ]; then
    echo "- deleting previous installation directory"
    rm -rf $INSTDIR/*
fi

if [ $DEL_FILESTORE == "1" ]; then
    echo "- Deleteing SCOT Filestore"
    rm -rf $FILESTORE
fi

echo "+ ensuring $FILESTORE exists"
mkdir -p $FILESTORE
chown scot $FILESTORE
chgrp scot $FILESTORE
chmod g+w $FILESTORE



echo "= checking scot service status"
if [ -e /etc/init.d/scot ]; then
    echo "- stopping SCOT"
    service scot3 stop
fi

echo "+ Copying SCOT files"
mkdir -p $INSTDIR
cp -r $DEVDIR/* $INSTDIR


# TODO: continue moving stuff from ./install_*.sh into here
