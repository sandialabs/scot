#!/bin/bash

function install_java {

    echo "---"
    echo "--- Installing JAVA"
    echo "---"

    if [[ $OS == "Ubuntu" ]]; then
        apt-get install -y openjdk-7-jdk -y
    else
        yum install java-1.7.0-openjdk -y
    fi

}
