#!/bin/bash

echo "--------------------------------------------------------------------"
echo "-- VAST Queue Sizes                                                 "
echo "--------------------------------------------------------------------"

PASS="NX3FCKPASS"
PASS="#jlkxj3LX_3lkx"
PASS="admin"

echo -n "Alert Email Processing Queue      :"
ss_size=`curl -s -u admin:$PASS http://localhost:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=email_alert/QueueSize | jq .value`
echo $ss_size

echo -n "Dispatch Email Processing Queue   :"
sysid_size=`curl -s -u admin:$PASS http://localhost:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=email_dispatch/QueueSize | jq .value`
echo $sysid_size

echo -n "AlertPassthrough Processing Queue :"
scaneval_size=`curl -s -u admin:$PASS http://localhost:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=email_alert_passthrough/QueueSize | jq .value`
echo $scaneval_size

echo -n "Email Event Queue                 :"
syseval_size=`curl -s -u admin:$PASS http://localhost:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=email_event/QueueSize | jq .value`
echo $syseval_size

