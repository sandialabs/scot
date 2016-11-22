Administration Guide
====================

Backup
------

SCOT supports on-demand and scheduled backups.  The backup script is::

    /opt/scot/bin/backup.pl

and will back up the SCOT's mongo database and the ElasticSearch collections.  The
backup is a gzipped tar file and will be stored in /opt/scotbackup.  Moving these 
backups to another system is left as an exercise to the admin.  By default, the
last 7 days of backups are kept in /opt/scotbackup and files older than 7 days are removed.

Restore
-------

Extract the timestamped SCOT backup tar file::

    tar xzvf scotback.201701211832.tgz

This will create a directory "./dump/scot-prod".  Restore the MondoDB with::

    mongorestore --dropdatabase --db scot-prod ./dump/scot-prod

SSL Certs
---------

The initial install of SCOT will use self-signed SSL Certs.  Please update these certs as 
soon as possible.  

GeoIP
-----

SCOT use the MaxMind GEOIP2 libraries and databases for geo location.  Please see the MaxMind
website for details on how to update the database files.

Upgrading
---------

Pull or Clone the latest from github (https://github.com/sandialabs/scot). CD into the 
downloaded directory, run::

    ./install.sh -s

You probably want to do this when your analysts are very busy.

CRON Entries
------------

If you are using /opt/scot/bin/alert.pl to import events you will need a crontab entry like::

    */5 * * * * /opt/scot/bin/alert.pl

To automate your backups::

    0 3,12,20 * * * /opt/scot/bin/backup.pl

Daemons
-------

A properly functioning SCOT has the following services running:

* ActiveMQ
* MondoDB
* Apache2
* Scot
* scfd   (scot flairing daemon)
* scepd  (scot elastic push daemon)

All of these services have /etc/init.d entries with start|stop|restart commands.

Logging
-------

SCOT is a prolific logger.  All logs are stored in /var/log/scot.  It is highly recommended to set 
up logrotate to avoid filling you disk.  Create a /etc/logrotate.d/scot like 

.. literalinclude:: ../../etc/logrotate.scot
   :linenos:


