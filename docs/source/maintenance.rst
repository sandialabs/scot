.. _admin:

Admin / Maintenance
================================

Backup 
^^^^^^^^^^^^^^^^

SCOT supports on-demand backups, as well as scheduled backups.  On-demand backups can be done anytime (beware of mongo performance hit though) by running /opt/scot/bin/backup.pl from the command line.

Schedule regular backups by using the cron facility to run the script above.

Restore 
^^^^^^^

Extract the timestamped SCOT database backup created by the above.

::
    $ tar xzvf 201601011313.tgz

This will create a directory "./dump/scot-prod".  Restore the database with 

::
    $ mongorestore --dropdatabase --db scot-prod ./dump/scot-prod


Updating GeoIP files
^^^^^^^^^^^^^^^^^^^^

SCOT uses the MaxMind GEOIP2 libraries and databases for geo location.  Please see the MaxMind website for details on how to update the database files.

Upgrading SCOT
^^^^^^^^^^^^^^

Currently, to upgrade SCOT you will have to use the terminal. Follow the instructions for how SCOT was * :ref:`origionally installed <upgrade>`.




