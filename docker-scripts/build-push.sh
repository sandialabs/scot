unset MONGODBUID
unset MONGODBGID
unset SCOTUID
unset SCOTGID
unset ELASTICUID
unset ELASTICGID
unset HOSTNAME

cd ../

export SCOTUID=`id scot -u`
export SCOTGID=`id scot -g` 
export ELASTICUID=`id elasticsearch -u`
export ELASTICGID=`id elasticsearch -g`
export MONGODBUID=`id mongodb -u`
export MONGODBGID=`id mongodb -g`


#build open-source scot
sudo -E docker-compose build
