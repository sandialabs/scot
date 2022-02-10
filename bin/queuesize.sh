#!/bin/bash

echo "--------------------------------------------------------------------"
echo "-- SCOT Queue Sizes                                                 "
echo "--------------------------------------------------------------------"

source /opt/scot/etc/amqcreds

echo -n "SCOT Flair Queue          : "
syseval_size=`curl -s -u $USER:$PASS http://localhost:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=flair/QueueSize | jq .value`
echo $syseval_size

echo -n "SCOT Enricher Queue       : "
syseval_size=`curl -s -u $USER:$PASS http://localhost:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=enricher/QueueSize | jq .value`
echo $syseval_size

echo -n "SCOT RemoteFlair Queue    : "
syseval_size=`curl -s -u $USER:$PASS http://localhost:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=remoteflair/QueueSize | jq .value`
echo $syseval_size

echo -n "SCOT Recorded Future Queue: "
syseval_size=`curl -s -u $USER:$PASS http://localhost:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=recfuture/QueueSize | jq .value`
echo $syseval_size

echo -n "SCOT LRI  Proxy Queue     : "
syseval_size=`curl -s -u $USER:$PASS http://localhost:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=lriproxy/QueueSize | jq .value`
echo $syseval_size

echo -n "SCOT Emlat      Queue     : "
syseval_size=`curl -s -u $USER:$PASS http://localhost:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=emlat/QueueSize | jq .value`
echo $syseval_size

