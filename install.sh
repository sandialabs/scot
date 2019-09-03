#!/bin/bash

DEVDIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

. ./install/install_functions.sh

export no_proxy=localhost,$no_proxy

INTERACTIVE='yes'

echo "==================== SCOT 3.5 Installer ======================="
echo "DEVDIR is $DEVDIR"

if root_check 
then    
    echo "Running as root: Yes"
else
    echo "Running as root: NO (can not proceed)"
    exit 2
fi

if get_http_proxy
then
    echo "http_proxy    : $PROXY"
else
    echo "http_proxy    : not set!"
fi

if get_https_proxy 
then
    echo "https_proxy   : $SPROXY"
else
    echo "https_proxy   : not set!"
fi

check_no_proxy

if get_script_src_dir
then
    echo "Install Src Dir: $DIR"
else 
    echo "Install Src Dir: unknown (can not proceed)"
    exit 2
fi

if determine_distro
then
    echo "Linux distro   : $DISTRO"
else
    echo "Linux distro   :failed getting distro (can not proceed)"
    exit 2
fi

if get_os_name
then
    echo "Operating Sys  : $OS"
else 
    echo "Operating Sys  : unknown (can not proceed)"
    exit 2
fi

if get_os_version
then
    echo "OS Version     : $OSVERSION"
else
    echo "OS Version     : unknown (can not proceed)"
    exit 2
fi

. ./install/commandline.sh
default_variables
process_commandline $@
show_variables

echo "____ INSTALL MODE $INSTMODE"

if [[ $INSTMODE != "SCOTONLY" ]]; then
    echo "=========== installing packages ============="
    . ./install/install_packages.sh
    install_packages

    echo "=========== installing PERL modules ============="
    . ./install/install_perl.sh
    install_perl

    echo "=========== installing JAVA ============="
    . ./install/install_java.sh
    install_java

    echo "=========== installing APACHE ============="
    . ./install/install_apache.sh
    install_apache

    echo "=========== installing ActiveMQ ============="
    . ./install/install_activemq.sh
    install_activemq

    echo "=========== installing Mongodb ============="
    . ./install/install_mongodb.sh
    install_mongodb
    
    echo "=========== installing ElasticSearch ============="
    . ./install/install_elasticsearch.sh
    install_elasticsearch
    
    
fi

echo "=========== installing SCOT  ============="
. ./install/install_scot.sh
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

date > /opt/scot/last_install

. ./install/status.sh

echo "========= "
echo "========= Please let us know you are using SCOT"
echo "========= it helps us convince our management to continue work on it."
echo "========= "
echo "========= ways to communicate with us:"
echo "========= follow us on twitter: @scotincresp "
echo "========= subscribe to        : majordomo@sandia.gov "
echo "=========             with body subscribe scot-users"
echo "========= email the dev team  : scot-dev@sandia.gov "
echo "========= "



