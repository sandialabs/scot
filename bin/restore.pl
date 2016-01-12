#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';
use Scot::Env;

my $env     = Scot::Env->new();
my $mongo   = $env->mongo;
my $log     = $env->log;
my $confcol = $mongo->collection('Config');
my $config  = $confcol->find_one({
    module  => "restore",
});

unless ($config) {
    $log->error("Restore Config not in Mongo!");
    exit 1;
}

my $restorefile = $ARGV[0];

# $config is
#   
#   pidfile  = the pid file for running restore
#   tarfile  = the tarfile backup
#   location = directory to expand the tar file
#   ts      = YYYYMMDDHHMM.tgz
#   user     = if needed, set to user name for db access
#   pass     = if needed, set to the password
#   dbname   = dbname, defaults to scot-prod
#
my $pidfile = $config->pidfile;
if ( -s $pidfile ) {
    $log->error("$pidfile exists and is non-zero length, implies another restore is running");
    exit 2;
}
open my $pidfh, ">", $pidfile or die "Unable to create PID file $pidfile!";
print $pidfh "$$";
close $pidfh;

my $dumpdir = $config->location;
unless ($dumpdir) {
    $log->error("$dumpdir is missing! Setting to /tmp/dump");
    $dumpdir = "/tmp/dump";
}

# this is just a templete shell right now
# what needs to be done:
# get the tarfile from the users cmd line args
# go somewhere and extract the tar file
# then run the mongorestore
# remove the tar and the extracted dir
# remove pidfile

my $cmd = "/usr/bin/restore ";

if ( $config->user and $config->pass ) {
    $cmd .= "-u $config->user -p $config->pass ";
}

if ( $config->dbname ) {
    $cmd .= "--db ". $config->dbname." ";
}
else {
    $cmd .= "--db scot-prod ";
}

$cmd .= "--oplogReplay --drop $dumpdir/$restorefile";

system($cmd);

system("rm -f $pidfile");
