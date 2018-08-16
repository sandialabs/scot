FROM ubuntu:16.04


ARG HTTPS_PROXY
ARG HTTP_PROXY
ARG https_proxy
ARG http_proxy
ARG no_proxy

ENV https_proxy=${https_proxy}
ENV http_proxy=${http_proxy}
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV no_proxy=${no_proxy}
ENV NO_PROXY=${NO_PROXY}

ENV  APACHE_RUN_USER=www-data \
        APACHE_RUN_GROUP=www-data \
        APACHE_LOG_DIR=/var/log/apache2 \
        APACHE_LOCK_DIR=/var/lock/apache2 \
        APACHE_RUN_DIR=/var/run/apache2 \
        APACHE_PID_FILE=/var/run/apache2.pid 

COPY ./docker-configs/apache/run.sh /scripts/
RUN chmod +x /scripts/run.sh

RUN apt-get update && \
  apt-get install -y apache2 libldap2-dev libsasl2-dev libssl-dev apache2 libapache2-mod-wsgi \
  apache2 libapache2-mod-authnz-external libapache2-mod-rpaf && \
  a2enmod proxy_http && a2enmod proxy && \
  a2enmod ssl && \
  a2ensite default-ssl && \
  a2enmod rewrite && \
  a2enmod proxy_html && \
  a2enmod headers 

#If you want to use your own SSL certificates, remove the below RUN line and simply add a data volume to the docker-compose file for your certs (i.e. /etc/apache2/ssl/yourcerts)
RUN mkdir -p /etc/apache2/ssl/ && \
    openssl genrsa 2048 > /etc/apache2/ssl/scot.key && \
    openssl req -new -key /etc/apache2/ssl/scot.key -out /tmp/scot.csr -subj '/CN=localhost/O=SCOT Default Cert/C=US' && \
    openssl x509 -req -days 36530 -in /tmp/scot.csr -signkey /etc/apache2/ssl/scot.key -out /etc/apache2/ssl/scot.crt
   
COPY docker-configs/apache/scot-revproxy-Ubuntu.conf /etc/apache2/sites-enabled


EXPOSE 443 80
   
 
CMD ["/scripts/run.sh"]
