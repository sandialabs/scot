Installing SCOT
================================

We've made installing SCOT a snap; follow these simple instructions and you'll be running in no time.

Minimum System Requirements
^^^^^^^^^^^^^^^^^^^^^^^^^^^

* Ubuntu 14.04LTS 
* 2 Quad Core CPUs
* 16 GB Ram
* 1TB Disk

The installer will also work for CentOS/Redhat EL.

Initial Installation
^^^^^^^^^^^^^^^^^^^^

Installation of SCOT requires internet access or the ability to have local
mirrors of several apt/yum repos and access to CPAN (local or remote). 

# Get the SCOT source from Github::

   git clone https://github.com/sandialabs/scot.git scot 

# cd to the SCOT directory::

  $ cd /home/tbruner/scot

# run the configuration bootstrap and answer the questions::
  
  $ bin/bootstrap.pl

# run the installer as root.  Make sure http_proxy and https_proxy are set if needed::

  $ sudo bash
  # ./install.sh

# get a cup of coffee, initial install has to download and install many dependencies.  If any errors, should occur with downloading packages or failure of a package to install, it is OK to re-run the installer after those problems are resolved.


install.sh Options
^^^^^^^^^^^^^^^^^^

SCOT's install is designed to automate many of the tasks need to install and 
upgrade SCOT.  The installer takes the following flags to modify its installtion behavior::

Usage: ./install.sh [-abigmsrflq] [-A mode] [-J file]

    -a      do not attempt to perform an "apt-get update"
    -d      do not delete /opt/scot before installation
    -i      do not overwrite an existing /etc/init.d/scot file
    -g      Overwrite existing GeoCitiy DB
    -m      Overwrite mongodb config and restart mongo service
    -s      SAFE SCOT. Only instal SCOT software, do not refresh apt, do not
                overwrite /etc/init.d/scot, do not reset db, and
                do not delete /opt/scotfiles
    -r      delete SCOT database (will result in data loss!)
    -f      delete /opt/scotfiles directory and contents ( again, data loss!)
    -l      truncate logs in /var/log/scot (potential data loss)
    -q      install new activemq config, apps, initfiles and restart service
    -w      overwrite existing SCOT apache config files

    -A mode     mode = Local | Ldap | Remoteuser
                default is Remoteuser (see docs for details)
    -J file.js  bootstrap SCOT's config and scotmod collections from this file


.. _upgrade:

Upgrading
^^^^^^^^^

* From 3.4
    * BACKUP your existing SCOT database (mongodump scotng-prod)
    * delete /etc/init.d/scot3 and remove crontab entries about scot
    * pull latest code and run the install.sh script
    * Migrate your database (see below)

* 3.5.x -- 
   * git pull
   * bash install.sh -s 

Database Migration
^^^^^^^^^^^^^^^^^^

Many parts of the database have changed from the 3.4 version of SCOT and it 
is necessary to migrate that data if you wish to continue to access that data
in SCOT 3.5.  We have developed a migration program to assist with this task.

We are assuming that you Mongo instance has sufficient space to keep the 3.4
database and the new 3.5 database on it during the migration.  The 3.5 instance
will be roughly the same size as the 3.4 instance.  

Depending on the amount of data you need to migrate, this process could take
a while.  It is hard to estimate, but from my experience, the migration will
process a million alerts in 24 hours.  

Migration is designed to be parallelized.  Not only can each collection be
migrated concurrently, but you can also specify the number of processes to 
operate on each collection.  For example, if you have 1 million alerts to 
process, you can specify 4 processes to work on alerts and each process will
migrate 250,000 alerts.  Unless you have very large databases, my recommendation
is to allow a single process to work on each collection because this will
make it easier to detect and correct any anomalies in the data migration.

The migration command::

   $ cd /opt/scot/bin
   $ ./migrate.pl alert 2

would begin migrating alerts from the 3.4 database using two processes.

Best practice in migration is to open a terminal for each collection, start 
tmux or screen, and then start the migration for a collection.  Extensive
loggin is performed in /var/log/scot/migration.alert.log, where alert is
the actual collection being migrated.  Pro tip: 'grep -i error /var/log/scot/migration*'

The Migrate the following collections:

# alertgroup
# alert
# event
# entry
# user
# guide
# handler
# user
# file


Uninstallation
^^^^^^^^^^^^^^

* Source
   * rm -rf /opt/sandia/webapps/scot
   * sudo crontab -e #remove all the scot stuff
   * rm /etc/init.d/scot


