FROM sandialabs/scot_perl


# Installation:
# Import MongoDB public GPG key AND create a MongoDB list file
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
RUN echo "deb http://repo.mongodb.org/apt/ubuntu $(cat /etc/lsb-release | grep DISTRIB_CODENAME | cut -d= -f2)/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list

# Update apt-get sources AND install MongoDB
RUN apt-get update && apt-get install -y mongodb-org

# Create the MongoDB data directory
RUN mkdir -p /var/lib/mongodb 


# Expose port #27017 from the container to the host
EXPOSE 27017

ADD docker-configs/mongodb/mongod.conf /etc/mongod.conf
ADD docker-configs/scot/scot.cfg.pl /opt/scot/etc/
ADD docker-configs/mongodb/ /
ADD install/src/mongodb /opt/scot/install/src/mongodb

#Create log directory
RUN mkdir -p /var/log/mongodb/


#add entry scripts
RUN chmod 0755 /run.sh
RUN chmod 0755 /set_mongodb_config.sh

#ADD demo files
ADD demo/ /opt/scot/demo/

#set mongodb UID to system created
RUN usermod -u 1061 mongodb 

#add user to scot group
RUN groupadd -g 2060 scot && \
     usermod -a -G 2060 mongodb

#Set permissions for mongodb user

RUN chown -R 1061:2060 /var/log/mongodb /var/lib/mongodb/

# Set /usr/bin/mongod as the dockerized entry-point application
USER mongodb:mongodb


CMD ["/run.sh"]
