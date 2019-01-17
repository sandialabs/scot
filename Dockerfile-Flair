FROM sandialabs/scot_perl

#Create log directory
RUN mkdir -p /var/log/scot
RUN mkdir -p /opt/scot

COPY install/src/scot/ /opt/scot/etc/
COPY bin/flairer.pl /opt/scot/bin/
COPY install/src/scot /opt/scot/etc/
COPY docker-configs/flair/flair.cfg.pl /opt/scot/etc/

CMD ["/usr/bin/perl", "/opt/scot/bin/flairer.pl"]
