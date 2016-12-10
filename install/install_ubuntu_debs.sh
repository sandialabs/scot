#!/bin/bash

FOO=`./determine_os.sh`
DISTRO=`echo $FOO | cut -d ' ' -f 1`
OS=`echo $FOO | cut -d ' ' -f 2`
OSVERSION=`echo $FOO | cut -d ' ' -f 3`
PROXY=`./determine_proxy.sh`

echo "------"
echo "------ Distro: $DISTRO"
echo "------ OS    : $OS"
echo "------ OsVer : $OSVERSION"
echo "------"

if [ "$OS" != "Ubuntu" ]; then
    echo "!!! Installing of deb packages, only supported on Ubuntu."
    exit 1
fi

echo "++++ Installing MongoDB ++++"

if grep --quiet mongo /etc/apt/sources.list; then
    echo "= mongo entry in /etc/apt/sources.list already present"
else
    if grep --quiet 10gen /etc/apt/sources.list
        echo "= 10gen mongo repo already present in /etc/apt/sources.list"
    else
        echo "+ adding Mongo 10Gen repo to /etc/apt/sources.list"

