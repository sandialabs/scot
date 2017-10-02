#!/bin/bash

DISTRO=`./determine_distro.sh | cut -d ' ' -f 2`

if [ "$DISTRO" == "RedHat" ]; then
    if ! hash lsb_release 2>/dev/null; then
        echo "- This RedHat based system does not have lsb installed, fixing..."
        yum install -y redhat-lsb
    fi
fi

OS=`lsb_release -i | cut -s -f 2`
VER=`lsb_release -r | cut -s -f 2 | cut -d. -f 1`

if [[ "$OS" == "RedHatEnterpriseServer" ]]; then
    echo "- Changing OS id to CentOS from $OS"
    OS="CentOs"
fi

echo "$DISTRO $OS $VER"
