cd ../
#replace all open-source FROM lines with Sandia internal
HOSTNAME=`hostname`
find . -type f \( -iname "Dockerfile-*" ! -iname "" \) -exec sed -i 's/ubuntu:16.04/gitlab.sandia.gov:3434\/docker\/ubuntu/g' {} +
sed -i 's/proxy: " "/proxy: http:\/\/wwwproxy.sandia.gov:80/g' docker-compose.yml
sed -i 's/-s -S/-x $proxy -s -S/g' Dockerfile-Activemq
sed -i 's/" "/http:\/\/wwwproxy.sandia.gov:80/g' Dockerfile-Scot
#build open-source scot
sudo docker-compose build
#Replace sandia with open-source ubuntu stuff
find . -type f \( -iname "Dockerfile-*" ! -iname "" \) -exec sed -i 's/gitlab.sandia.gov:3434\/docker\/ubuntu/ubuntu:16.04/g' {} +
sed -i 's/proxy: http:\/\/wwwproxy.sandia.gov:80/proxy: " "/g' docker-compose.yml
sed -i 's/-x $proxy -s -S/-s -S/g' Dockerfile-Activemq
sed -i 's/http:\/\/wwwproxy.sandia.gov:80/" "/g' Dockerfile-Scot

