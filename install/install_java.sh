#!/bin/bash

function install_java {

    echo "---"
    echo "--- Installing JAVA"
    echo "---"

    if [[ $OS == "Ubuntu" ]]; then
        if [[ $OSVERSION == "18" ]] || [[ $OSVERSION == "20" ]]; then
            apt-get install -y openjdk-8-jdk -y
        elif [[ $OSVERSION == "16" ]]; then
            apt-get install -y openjdk-8-jdk -y
        else
            apt-get install -y openjdk-7-jdk -y
        fi
    else
        yum install java-1.8.0-openjdk -y
    fi

}
