POST Install Procedures
=======================

Migration
---------

If you backed up data from your 3.4 SCOT instance and wish to restore it, 
you will need to follow the migration procedure :ref:`migration.rst`

SSL Certs
---------

SCOT will generate a "snake-oil" self signed certificate upon install.  
It is highly recommended to replace these certificates with real certs 
as soon as possible.

Configuration Files
-------------------

The following sections details the parameters in the varios configuration files
available in SCOT.  Use your favorite editor to adjust the values to your site.
You can test your changes for syntax erros by using the following command::

  $ perl -wc scot.cfg.pl

Correct any syntax errors reported before continuing.  Typically you will need
to resart SCOT for any changes to be recognized.

scot.cfg.pl
^^^^^^^^^^^^

This config controls many aspects of the SCOT application server.  

.. literalinclude:: ../../install/src/scot/scot.cfg.pl
   :linenos:

alert.cfg.pl
^^^^^^^^^^^^

This config file controls how alerts are received from an IMAP server.  

.. literalinclude:: ../../install/src/scot/alert.cfg.pl
   :linenos:

flair.cfg.pl
^^^^^^^^^^^^^

The Flair app automatically detects enties, see :ref:`entities`.  This config file look like:

.. literalinclude:: ../../install/src/scot/flair.cfg.pl
   :linenos:

game.cfg.pl
^^^^^^^^^^^

This controls aspects of the gamification system.

.. literalinclude:: ../../install/src/scot/game.cfg.pl
   :linenos:

stretch.cfg.pl
^^^^^^^^^^^

This controls aspects of the elastic search input system.

.. literalinclude:: ../../install/src/scot/stretch.cfg.pl
   :linenos:


CRON Jobs
---------

The /opt/scot/alert.pl program that reads in alerts from the IMAP server needs a crontab
entry.  It is recommended to run this every 2 to 5 minutes.  Here's the crontab entry::

    */5 * * * * /opt/scot/bin/alert.pl

Automating SCOT backups are a good idea as well::

    0 3,12,20 * * * /opt/scot/bin/backup.pl     # backup scot at 3am 12 noon and 8pm



