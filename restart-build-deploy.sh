#!/bin/bash

sudo docker-compose down

#build open-source scot

echo " "
echo "**************** "
echo "Hello, and welcome to the Docker version of SCOT 🔍 "
echo " "
echo "This script will walk you through the installation process. First, we have a couple questions for you"
echo " "
echo "SCOT has two installation modes:" 
echo " "
echo "1. Default mode (quick) - In this mode, we will pull pre-built images from Dockerhub. Feel free to modify the docker-compose.yml file for any custom volume mappings"
echo "2. Custom mode (slow): In this mode, we will build the Docker containers from the Dockerfiles contained in the cloned source code. You can also make changes to the Dockerfiles, source code, etc. as you see fit"
echo " "
echo -n "Please enter your installation mode selection: "
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





