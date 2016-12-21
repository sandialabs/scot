#!/bin/bash

. ./install_functions.sh

INTERACTIVE="yes"

#if root_check 
#then    
#    echo "running as root"
#else
#    echo "not as root";
#fi

if get_http_proxy
then
    echo "http proxy is $PROXY"
else
    echo "not set!"
fi

proceed

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

. ./install_activmq.sh
install_activmq

