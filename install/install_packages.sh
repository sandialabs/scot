#!/bin/bash

function install_ubuntu_packages {

    DEBPACKAGES='
        curl
        make
        groff
        dialog
        gcc
        lynx
        libgssapi-krb5-2
        libkrb5support0
        libkrb5-3
        krb5-doc
        libimlib2-dev
        libimlib2
        libmagic-dev
        libmagic1
    '

    if [[ $REFRESHAPT == "yes" ]]; then
        echo "-- refreshing apt repositories"
        apt-get-update
        if [[ $? != 0 ]]; then
            echo "!! Error refreshing apt repository !!"
            exit 3
        fi
    fi

    for pkg in $DEBPACKAGES; do
        echo ""
        echo "-- Installing $pgk"
        apt-get -y install $pkg
    done
}

function install_cent_packages {

    echo "-- adding config to allow unverified ssl in yum "
    echo "--     you can remove this from /etc/yum.conf after install"
    echo "sslverify=false" >> /etc/yum.conf

    YUMPACKAGES='
        redhat-lsb
        openssl-devel
        openssl
        wget
        git
        file-devel
        dialog
        krb5-libs
        krb5-devel
    '

    for pkg in $YUMPACKAGES; do
        echo ""
        echo "-- Installing $pgk"
        yum install $pkg -y
    done
}

function install_packages {

    echo "---"
    echo "--- Installing System Package Prerequisites"
    echo "---"

    if [[ $OS == "Ubuntu" ]]; then
        apt-get-update
        install_ubuntu_packages
    else 
        install_cent_packages
    fi
}
