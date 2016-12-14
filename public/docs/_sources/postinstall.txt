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

  $ perl -wc scot_env.cfg

Correct any syntax errors reported before continuing.  Typically you will need
to resart SCOT for any changes to be recognized.

scot_env.cfg
^^^^^^^^^^^^

This config controls many aspects of the SCOT application server.  

.. literalinclude:: ../../etcsrc/templates/scot_env.cfg
   :linenos:

ldap.cfg
^^^^^^^^

If you plan on using LDAP for authentication or for Group membership, you will need
to update this configuration file.

.. literalinclude:: ../../etcsrc/templates/ldap.cfg
   :linenos:

logger.cfg
^^^^^^^^^^

How to configure the SCOT logger.

.. literalinclude:: ../../etcsrc/templates/logger.cfg
   :linenos:

mail.app.cfg
^^^^^^^^^^^^

This config file controls how alerts are received from an IMAP server.  

.. literalinclude:: ../../etcsrc/templates/mail.app.cfg
   :linenos:

flair.app.cfg
^^^^^^^^^^^^^

The Flair app automatically detects enties, see :ref:`entities`.  This config file look like:

.. literalinclude:: ../../etcsrc/templates/flair.app.cfg
   :linenos:

enrichments.cfg
^^^^^^^^^^^^^^^

This config file is lists the entity enrichments and is used in the Flairing process.

.. literalinclude:: ../../etcsrc/templates/enrichments.cfg
   :linenos:


CRON Jobs
---------

The /opt/scot/alert.pl program that reads in alerts from the IMAP server needs a crontab
entry.  It is recommended to run this every 2 to 5 minutes.  Here's the crontab entry::

    */5 * * * * /opt/scot/bin/alert.pl

Automating SCOT backups are a good idea as well::

    0 3,12,20 * * * /opt/scot/bin/backup.pl     # backup scot at 3am 12 noon and 8pm



