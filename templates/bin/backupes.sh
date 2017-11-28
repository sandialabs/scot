#!/bin/bash

##
## THIS IS JUST AN EXAMPLE
## of how to backup elastic search
## 
## use backup.pl to backup scot's mongo and elastic instances
###

ESRV='localhost:9200'
SETTINGS='{ "scot_backup": { "type": "fs", "settings": { "compress": "true", "location": "/opt/esback" } } }'

echo "DELETING Existing Snapshot"

curl -XDELETE $ESRV/_snapshot/snapshot_1

echo "CREATING Repo..."

curl -XPUT $ESRV/_snapshot/scot_backup -d $SETTINGS

echo "Creating Snapshot..."

curl -XPUT $ESRV/_snapshot/scot_backup/snapshot_1

echo "Backup Status..."

STATUS=curl -XGET $ESRV/_snapshot/scot_backup/_all`

exit 0;

# later do this:

cd /opt/esback
tar czvf /opt/esback.tgz .

# then move to esback.tgz to other system

# on other system do this to restore

cd /opt/esback
tar xzvf ~/esback.tgz

# close existing index
curl -XPOST localhost:9200/scot/_close

# restore
curl -XPOST localhost:9200/_snapshot/scot_backup/snapsot_1/_restore


