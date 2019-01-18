FROM sandialabs/scot_perl 

#Create log directory
RUN mkdir -p /var/log/scot
RUN mkdir -p /opt/scot

COPY install/src/scot/ /opt/scot/etc/
COPY docker-configs/game/game.pl /opt/scot/bin/
COPY lib/Scot/App/Game.pm /opt/scot/lib/
COPY install/src/scot /opt/scot/etc/
COPY docker-configs/game/game.cfg.pl /opt/scot/etc/

CMD ["/usr/bin/perl", "/opt/scot/bin/game.pl"]
