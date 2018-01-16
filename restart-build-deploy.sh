unset MONGODBUID
unset MONGODBGID
unset SCOTUID
unset SCOTGID
unset ELASTICUID
unset ELASTICGID
unset HOSTNAME

sudo chmod -R 0755 /opt/scotbackup/
sudo chmod -R 0777 /var/log/scot/
sudo chmod -R 0755 /var/lib/mongodb/


function add_users {
    echo "- checking for existing scot user"
    if grep --quiet -c scot: /etc/passwd; then
        echo "- scot user exists"
    else
       sudo useradd -c "SCOT User"  -M -s /bin/bash scot
    fi

    echo "-Checking for existing Elastic User"
    if grep --quiet -c elasticsearch: /etc/passwd; then
        echo "- elasticsearch user exists"
    else
        sudo useradd -c "elasticsearch User"  -M -s /bin/bash elasticsearch
    fi
    
    echo "-Checking for existing Mongodb User"
    if grep --quiet -c mongodb: /etc/passwd; then
        echo "- mongodb user exists"
    else
        sudo useradd -c "mongodb User"  -M -s /bin/bash mongodb
    fi

}

sudo chown -R mongodb:mongodb /var/lib/mongodb/ /var/log/mongodb/

#add users
add_users

export SCOTUID=`id scot -u`
export SCOTGID=`id scot -g` 
export ELASTICUID=`id elasticsearch -u`
export ELASTICGID=`id elasticsearch -g`
export MONGODBUID=`id mongodb -u`
export MONGODBGID=`id mongodb -g`

echo "MONGOUID: $MONGODBUID"
echo "MONGOGID: $MONGODBGID"

sudo -E docker-compose up --build

