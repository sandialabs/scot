FROM sandialabs/scot_perl 


ENV DEBIAN_FRONTEND="noninteractive" \
    NO_PROXY="elastic,mongodb,activemq"


RUN apt-get update && \
    apt-get install ssmtp -y -f  && \
    apt-get autoclean && \
    apt-get --purge -y autoremove && \ 
    rm -rf /var/lib/apt/lists* /tmp/* /var/tmp/*
    

RUN mkdir -p /var/log/scot
RUN mkdir -p /opt/scot
RUN mkdir -p /opt/scot/public/cached_images
RUN mkdir -p /tmp/foo

#copy config files
COPY install/src/scot/ /opt/scot/etc/  
COPY script/ /opt/scot/script/
COPY t/ /opt/scot/t/
COPY templates/ /opt/scot/templates/ 
COPY docker-configs/scot/scot.cfg.pl /opt/scot/etc/
COPY docker-scripts/* /opt/scot/bin/
COPY docker-configs/scot/backup.cfg.pl /opt/scot/etc/
COPY docker-configs/scot/restore.cfg.pl /opt/scot/etc/


RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 && \
    echo "deb http://repo.mongodb.org/apt/ubuntu $(cat /etc/lsb-release | grep DISTRIB_CODENAME | cut -d= -f2)/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list && \
    apt-get update && \
    apt-get install -y --force-yes --allow-downgrades  pwgen mongodb-org-shell mongodb-org-tools  && \
    echo "mongodb-org-shell hold" | dpkg --set-selections 

RUN groupadd -g 2060 scot && \
    useradd -r -u 1060 -g scot scot

RUN mkdir /home/scot

COPY demo/ /opt/scot/demo/

#scot permissions
RUN chown -R scot:scot /opt/scot/
RUN chown -R scot:scot /home/scot/
RUN chmod -R 0777 /tmp/

EXPOSE 3000 

USER scot
ENV HOME /home/scot
CMD /usr/local/bin/hypnotoad -f /opt/scot/script/Scot
