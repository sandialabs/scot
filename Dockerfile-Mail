FROM sandialabs/scot_perl

#Create log directory
RUN mkdir -p /var/log/scot
RUN mkdir -p /opt/scot

COPY install/src/scot/ /opt/scot/etc/
COPY docker-configs/mail/alert.pl /opt/scot/bin/
COPY docker-configs/mail/Mail.pm /opt/scot/lib/Scot/App/
COPY install/src/scot /opt/scot/etc/
COPY docker-configs/mail/alert.cfg.pl /opt/scot/etc/

CMD ["/usr/bin/perl", "/opt/scot/bin/alert.pl"]
