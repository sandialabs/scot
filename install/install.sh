#!/bin/bash
. ./install_functions.sh

set_ascii_colors
root_check
set_defaults
process_command_line
determine_distro
get_os_name
get_os_version

configure_accounts

if [[ $INSTMODE != "SCOTONLY" ]]; then
    echo -e "{yellow}+ Installing Prerequisite Packages ${nc}"

    install_packages
    install_perl_modules
    install_nodejs
    install_mongodb
    install_elasticsearch
    install_activemq
    configure_geoip
fi

configure_apache
configure_startup
configure_filestore
configure_backup
install_scot
configure_scot
install_private
configure_logging
configure_mongodb
start_services

if [ $AUTHMODE == "Local"  ];then
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






