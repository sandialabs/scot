#!/bin/bash

sudo docker-compose down

scot_log_dir="/var/log/scot"
scot_backup="/opt/scotbackup"
mongodb_dir="/var/lib/mongodb"
elastic_dir="/var/lib/elasticsearch"


#check if scot_log_dir exists
if [  -d $scot_log_dir ]; then
    echo "$scot_log_dir exists!"
else
    sudo mkdir -p $scot_log_dir
fi

#check if scot_backup exists
if [  -d $scot_backup ]; then
    echo "$scot_backup exists!"
else
    sudo mkdir -p $scot_backup
fi
#check if mongodb_dir exists
if [  -d $mongodb_dir ]; then
    echo "$mongodb_dir exists!"
else
    sudo mkdir -p $mongodb_dir
fi
#check if elastic_dir exists
if [ -d $elastic_dir ]; then
    echo "$elastic_dir exists!"
else
    sudo mkdir -p $elastic_dir
fi



#set permissions
sudo chmod -R 0770 /opt/scotbackup/
sudo chmod -R 0775 /var/log/scot/
sudo chmod -R g+rwx /var/lib/elasticsearch/ 
sudo chgrp 1000 /var/lib/elasticsearch/

echo "Creating SCOT and mongodb groups"
#create groups
sudo groupadd -g 2060 scot
echo "Changing /opt/scotbackup/ permissions"
sudo chown -R :2060 /opt/scotbackup/

function add_users {
    echo "- checking for existing scot user"
    if grep --quiet -c scot: /etc/passwd; then
        echo "- scot user exists"
    else
       echo "SCOT user does not exist. Creating user"
       sudo useradd -c "SCOT User" -u 1060 -g 2060 -M -s /bin/bash scot
    fi
    
    echo "-Checking for existing Mongodb User"
    if grep --quiet -c mongodb: /etc/passwd; then
        echo "- mongodb user exists"
    else
        
       echo "mongodb user does not exist. Creating user"
       sudo useradd -c "mongodb User" -u 1061 -g 2060 -M -s /bin/bash mongodb
    fi

}

#set ownership 
sudo chown -R 1061:2060 /var/lib/mongodb/ /var/log/mongodb/
sudo chown -R 1060:2060 /var/log/scot/ /opt/scot/
sudo chown -R 1060:2060 /opt/scotfiles/

#add users
add_users


#build open-source scot

echo " "
echo "**************** "
echo "Hello, and welcome to the Docker version of SCOT 🔍 "
echo " "
echo "This script will walk you through the installation process. First, we have a couple questions for you"
echo " "
echo "SCOT has two installation modes:" 
echo " "
echo "1. Demo Mode - In this mode, we will pull pre-built images from Dockerhub. Note: Using this mode, there is no customization such as insertion of your own server's SSL certs, no LDAP integration, etc. This mode should not be used in production instances"
echo "2. Custom mode: In this mode, we will build the Docker containers from the Dockerfiles contained in the cloned source code. You can also make changes to the Dockerfiles, source code, etc. as you see fit"
echo " "
echo -n "Please enter your selection: 1 for demo mode  / 2 for custom mode"
read -n 1 selection

if [ "$selection" == "1" ]; then
  echo "You selected demo mode."
  echo " "
  sudo -E docker-compose pull
  sudo -E docker-compose up --build
elif [ "$selection" == "2" ]; then
  echo "You selected custom mode."
  echo " "
  sudo -E docker-compose -f docker-compose-custom.yml up --build
else
  echo "Invalid selection"
fi





