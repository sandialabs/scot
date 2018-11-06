#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;
use lib '../lib';
#use lib '/opt/scot/lib';

use Scot::Env;
use DateTime;
use Mojo::JSON qw(decode_json);

my $config_file = $ENV{'scot_restore_config_file'} // '/opt/scot/etc/restore.cfg.pl';

my $env  = Scot::Env->new({
    config_file => $config_file,
});

my $curl    = "curl -s";

# $env has
#   
#   pidfile  = the pid file for runnign dump
#   location = directory to dump the mongodump
#   tarloc  = directory to place tar file
#   cleanup  = true if you wish to remove the dumped directory
#   user     = if needed, set to user name for db access
#   pass     = if needed, set to the password
#   dbname   = dbname, defaults to scot-prod
#   es_server = the url to the elastic server e.g. http://localhost:9200
#   es_backup_location = the directory to create the repo snapshots
#

my $pidfile = $env->pidfile;
if ( -s $pidfile ) {
    die "$pidfile exists and is non-zero length, implies another restore is running";
}

open my $pidfh, ">", $pidfile or die "Unable to create PID file $pidfile!";
print $pidfh "$$";
close $pidfh;

my $dumpdir = $env->location;
unless ($dumpdir) {
    warn "$dumpdir is missing! Setting to /tmp/dump";
    $dumpdir = "/tmp/dump";
}

unless (-d $dumpdir ) {
    system("mkdir -p $dumpdir");
}


my $cmd = "/usr/bin/mongorestore ";

if ( defined $env->auth->{user} ) {
    if ( $env->auth->{user} and $env->auth->{pass} ) {
        $cmd .= "-u $env->user -p $env->pass ";
    }
}

if ( $env->dbname ) {
    $cmd .= "--db ". $env->dbname." ";
}
else {
    $cmd .= "--db scot-prod ";
}

# $cmd .= "--oplog -o $dumpdir";
$cmd .= "--dir $dumpdir/scot-prod --drop";

print "Executing: $cmd\n";

system("cd $dumpdir/.. && $cmd");

#system("rm -f $pidfile");
#exit 0;


# now backup elasticsearch
print "Restoring ElasticSearch...\n";

system( "/opt/scot/install/src/elasticsearch/mapping.sh");
my $closestat = `$curl -XPOST "http://localhost:9200/_all/_close"`;
print ("attempting to close open ES instances. Returned: $closestat");

my $restorestat = `$curl -XPOST "http://localhost:9200/_snapshot/scot_backup/snapshot_1/_restore"`;
print ("restore status is: $restorestat");

# back up cached images
print "Restoring Cached images...\n";

my $ciloc = $env->cacheimg;
system("cp -r $ciloc/ /opt/scot/public/");

END{
    system("rm -f $pidfile");
}
