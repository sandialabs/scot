#!/bin/bash
. ./install_functions.sh

INTERACTIVE='yes'

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

set_defaults

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

if [[ $INSTMODE != "SCOTONLY" ]]; then
    . ./install_packages.sh
    install_packages
    . ./install_java.sh
    install_java
    . ./install_activemq.sh
    install_activemq
    . ./install_elasticsearch.sh
    install_elasticsearch
    . ./install_mongo.sh
    install_mongo
    . ./install_apache.sh
    install_apache.sh
    . ./install_perl.sh
    install_perl
    configure_filestore
fi

. ./install_scot.sh
install_scot



start_services

if [[ "$AUTHMODE" == "Local"  ]]; then
    echo "!!!!"
    echo "!!!! AUTHMODE is set to LOCAL.  Use the admin username and password"
    echo "!!!! to initially access SCOT.  Please see only documentation for "
    echo "!!!! direction on how to create users/password or to switch "
    echo "!!!! authentication options."
    echo "!!!!"
fi


echo ""
echo "@@"
echo "@@ SCOT online documentaton is available at "
echo "@@  https://localhost/docs/index.html"
echo "@@"
echo ""

echo "----"
echo "----"
echo "---- Install completed"
echo "----"
echo "----"






