Migration
---------

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
logging is performed in /var/log/scot/migration.alert.log, where alert is
the actual collection being migrated.  Pro tip: 'grep -i error /var/log/scot/migration*'

The list of collections to migrate:

# alertgroup
# alert
# event
# entry
# user
# guide
# handler
# user
# file

If you wish for totally hands off operation, do the following::
  
   $ cd /opt/scot/bin
   $ ./migrate.pl all

This will sequentially migrate the collections listed above.  The migration
will take a bit longer, though.

NOTE:  Migration assumes that the database to be migrated is on the same
database server as the new server.  So in other words, if you are installing 
SCOT 3.5 on a new system, and want to migrate your database to that server,
you will need to use the mongodump and mongorestore to move the old database
to the new server first.

Example Migration::

   $ ssh oldscot
   oldscot:/home/scot> mongodump scotng-prod
   ...
   oldscot:/home/scot> tar czvf ./scotng-prod.tgz ./dump
   ...
   oldscot:/home/scot> scp scotng-prod.tgz scot@newscot:/home/scot
   ...
   oldscot:/home/scot> exit
   $ ssh newscot
   newscot:/home/scot> tar xzvf ./scotng-prod.tgz
   ...
   newscot:/home/scot> mongorestore --db scotng-prod ./dump/scotng-prod
   ...
   newscot:/home/scot> cd /opt/scot/bin
   newscot:/opt/scot/bin> ./migrate.pl all

Save Your Old Database
-----------------------

The migration tool has been tested, but as with any process that operates on user data, things can happen.  The only defense is to save a copy of the last 3.4 SCOT database backup.
