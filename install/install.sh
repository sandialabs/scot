#!/bin/bash
. ./install_functions.sh

INTERACTIVE='yes'

set_ascii_colors
root_check
set_defaults
process_command_line
determine_distro
get_os_name
get_os_version

configure_accounts

proceed

if [[ $INSTMODE != "SCOTONLY" ]]; then
    echo -e "${blue}+ Installing Prerequisite Packages ${nc}"

    install_packages
    proceed

    install_perl_modules
    proceed

    install_nodejs
    proceed

    install_mongodb
    proceed

    install_elasticsearch
    proceed

    install_activemq
    proceed

    configure_geoip
    proceed

fi

configure_apache
proceed

configure_startup
proceed

configure_filestore
proceed

configure_backup
proceed

install_scot
proceed

configure_scot
proceed

install_private
proceed

configure_logging
proceed

configure_mongodb
proceed

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






