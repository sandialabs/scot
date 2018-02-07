
#ActiveMQ dockerfile
FROM openjdk:8 

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


#AMQ
ENV ACTIVEMQ_VERSION 5.14.3
ENV ACTIVEMQ apache-activemq-$ACTIVEMQ_VERSION
ENV ACTIVEMQ_STOMP=61613 
ENV ACTIVEMQ_UI=8161
ENV ACTIVEMQ_HOME /opt/activemq

ENV DEBIAN_FRONTEND=noninteractive 

#install amq

RUN set -x && \
    #wget -qO- https://archive.apache.org/dist/activemq/$ACTIVEMQ_VERSION/$ACTIVEMQ-bin.tar.gz | tar xvz -C /opt && \
    curl -k -s -S  https://archive.apache.org/dist/activemq/$ACTIVEMQ_VERSION/$ACTIVEMQ-bin.tar.gz | tar xvz -C /opt && \
    ln -s /opt/$ACTIVEMQ $ACTIVEMQ_HOME && \
    useradd -r -M -d $ACTIVEMQ_HOME activemq && \
    chown -R activemq:activemq /opt/$ACTIVEMQ && \
    chown -h activemq:activemq $ACTIVEMQ_HOME && \
    mkdir -p /var/log/activemq && \
    touch /var/log/activemq/scot.amq.log

#Copy over SCOTAQ config stuffs    
COPY install/src/ActiveMQ/amq/scotaq/ /opt/activemq/webapps/scot
COPY install/src/ActiveMQ/amq/scotamq.xml /opt/activemq/conf/
COPY install/src/ActiveMQ/amq/jetty.xml /opt/activemq/conf/

USER activemq
WORKDIR $ACTIVEMQ_HOME
EXPOSE $ACTIVEMQ_TCP $ACTIVEMQ_AMQP $ACTIVEMQ_STOMP $ACTIVEMQ_MQTT $ACTIVEMQ_WS $ACTIVEMQ_UI


CMD ["/bin/sh", "-c", "bin/activemq console"]
