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

# Determine OS platform
# see http://unix.stackexchange.com/questions/92199/how-can-i-reliably-get-the-operating-systems-name

UNAME=$(uname | tr "[:upper:]" "[:lower:]")
# If Linux, try to determine specific distribution
if [ "$UNAME" == "linux" ]; then
    # If available, use LSB to identify distribution
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
        export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
        # Otherwise, use release info file
    else
        export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
    fi
fi
# For everything else (or if above failed), just use generic identifier
[ "$DISTRO" == "" ] && export DISTRO=$UNAME
unset UNAME


if [[ "$DISTRO" == "CentOS" ]]; then
    echo "CentOS detected..."
    ./centos_installer.sh
    exit 0
fi

if ! hash lsb_release 2>/dev/null; then
    # ubuntu should have this, but surprisingly
    # redhat might not have this installed!
    yum install redhat-lsb
fi

OS=`lsb_release -i | cut -s -f 2`
OSVERSION=`lsb_release -r | cut -s -f2 | cut -d. -f 1`

echo "$OS : $OSVERSION detected..."

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

