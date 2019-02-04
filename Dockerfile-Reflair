FROM sandialabs/scot_perl 

#Create log directory
RUN mkdir -p /var/log/scot
RUN mkdir -p /opt/scot

COPY install/src/scot/ /opt/scot/etc/
COPY bin/reflair.pl /opt/scot/bin/
COPY install/src/scot /opt/scot/etc/
COPY docker-configs/reflair/reflair.cfg.pl /opt/scot/etc/
COPY docker-configs/scot/scot.cfg.pl /opt/scot/etc/

CMD ["/usr/bin/perl", "/opt/scot/bin/reflair.pl"]
