#!/bin/sh


PATH=/usr/local/bin:$PATH
PLACKUP=`which plackup`
BASE="/opt/sandia/webapps/scot3"
DIR="$BASE/script"
APP="Scot"
DAEMON="$DIR/$APP "
NAME="scot3"
PIDFILE="$BASE/scot.pid"
OPTS="daemon -s Starman --daemonize --listen 127.0.0.1:5100 --user scot --group scot --max-requests 1 --workers 20 --pid $PIDFILE"

# uncomment to allow profiling
#PERL5OPT=-d:NYTProf
#export PERL5OPT
#NYTPROF=trace=2:file=/tmp/nytprof.out:addpid=1
#export NYTPROF

if [ ! -e $PLACKUP ]; then
    PLACKUP="/usr/bin/plackup"
fi

if [ ! -e $PLACKUP ]; then
    PLACKUP="/usr/local/bin/plackup"
fi


echo "Starting the Scot Web Service..."
echo "SCOTMODE is $SCOTMODE."

eval $PLACKUP $DAEMON $OPTS 2>&1 >>$BASE/log/starman.log

