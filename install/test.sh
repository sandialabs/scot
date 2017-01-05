#!/bin/bash

. ./install_functions.sh
set_defaults

INTERACTIVE="yes"

if root_check 
then    
    echo "running as root"
else
    echo "not as root"; 
    exit 2
fi

if get_http_proxy
then
    echo "http proxy is $PROXY"
else
    echo "not set!"
fi


if get_script_src_dir
then
    echo $DIR
else 
    echo "get_script_src_dir failed!"
fi

if determine_distro
then
    echo "distro is $DISTRO"
else
    echo "failed getting distro"
fi

if get_os_name
then
    echo "osname is $OS"
else 
    echo "failed getting OS name"
fi

if get_os_version
then
    echo "osversion is $OSVERSION"
else
    echo "failed to get osversion"
fi

proceed


#. ./install_packages.sh
#install_packages

#proceed

#. ./install_java.sh
#install_java
#proceed

#. ./install_activemq.sh
#install_activemq
#proceed

#. ./install_mongodb.sh
#install_mongodb

#. ./install_apache.sh
#install_apache

#. ./install_perl.sh
#install_perl

. ./install_scot.sh
install_scot

