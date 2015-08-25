#!/bin/bash
#
# SCOT 3 installer
# 
# goal: support more than Ubuntu
#
# 

echo "########## "
echo "########## SCOT3 installer"
echo "########## support at: scot-dev@sandia.gov"
echo "########## "

echo ""
echo "Determining OS..."
echo ""


DISTRO=`./etc/determine_os.sh | cut -d ' ' -f 2`
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

echo "LSB results = $OS : $OSVERSION"

if [[ "$OS" == "CentOS" ]]; then
    echo "CentOS detected..."
    ./centos_installer.sh
    exit 0
fi



if [[ "$OS" == "Ubuntu" ]]; then
    ./ubuntu_installer.sh
    exit 0
fi

if [[ "$OS" == *"RedHat"* ]]; then
    ./redhat_installer.sh
    exit 0
fi

echo "!!!! Installation not support for this OS !!!!"
exit 1;

