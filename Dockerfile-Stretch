FROM sandialabs/scot_perl 

RUN mkdir -p /var/log/scot
RUN mkdir -p /opt/scot

COPY install/src/scot/ /opt/scot/etc/

COPY bin/ /opt/scot/bin/
COPY install/src/scot /opt/scot/etc/
COPY docker-configs/stretch/stretch.cfg.pl /opt/scot/etc/

CMD ["/usr/bin/perl", "/opt/scot/bin/stretch.pl"]
