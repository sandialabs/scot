FROM sandialabs/scotbase
MAINTAINER Josh Maine, jmaine@sandia.gov

USER root

# Prevent daemon start during install
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && \
    chmod +x /usr/sbin/policy-rc.d

# Set proxy settings (if your environment requires it)
#ENV http_proxy http://PROXY_SERVER_HERE:80
#ENV https_proxy http://PROXY_SERVER_HERE:80

RUN \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 && \
  echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' >> /etc/apt/sources.list && \
  apt-get -q update && \
  apt-get install -y mongodb-org supervisor redis-server && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  mkdir -p /var/log/supervisor

# Add SCOT Files
COPY . /scot
RUN chmod 755 /scot/install_scot3.sh
COPY deploy/docker-entrypoint.sh /
COPY deploy/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENV DOCKERINSTALL True

# Run SCOT Installer
RUN cd /scot && /scot/install_scot3.sh && rm -rf /scot
COPY deploy/scotamq.xml /opt/sandia/webapps/activemq/conf/scotamq.xml

# ENTRYPOINT ["/docker-entrypoint.sh"]

VOLUME ["/opt/sandia/webapps/scot3/public"]

EXPOSE 443
EXPOSE 80
# USER nonroot
CMD ["/usr/bin/supervisord"]
