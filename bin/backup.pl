#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';

use Scot::Env;

my $env     = Scot::Env->new();
my $mongo   = $env->mongo;
my $confcol = $mongo->collection('Config');
my $config  = $confcol->find_one({
    module  => "backup",
});
my $log     = $env->log;

unless ($config) {
    $log->error("Backup Config not in Mongo!");
    exit 1;
}

# $config is
#   
#   pidfile  = the pid file for runnign dump
#   location = directory to dump the mongodump
#   tarloc  = directory to place tar file
#   cleanup  = true if you wish to remove the dumped directory
#   user     = if needed, set to user name for db access
#   pass     = if needed, set to the password
#   dbname   = dbname, defaults to scot-prod
#
my $pidfile = $config->pidfile;
if ( -s $pidfile ) {
    $log->error("$pidfile exists and is non-zero length, implies another backup is running");
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

unless (-d $dumpdir ) {
    system("mkdir -p $dumpdir");
}


system("rm -rf $dumpdir/*");

my $cmd = "/usr/bin/mongodump ";

if ( $config->user and $config->pass ) {
    $cmd .= "-u $config->user -p $config->pass ";
}

if ( $config->dbname ) {
    $cmd .= "--db ". $config->dbname." ";
}
else {
    $cmd .= "--db scot-prod ";
}

$cmd .= "--oplog -o $dumpdir";

system($cmd);
my $tarloc = "/tmp";
if ( $config->tarloc ) {
    unless ( -d $config->tarloc ) {
        system ("mkdir -p $tarloc" );
    }
    $tarloc = $config->tarloc;
}

my $dt  = DateTime->now();
my $ts  = $dt->year . $dt->month . $dt->day . $dt->hour . $dt->minute;
system("tar cvzf $tarloc.$ts.tgz --directory $dumpdir");

if ( $config->cleanup ) {
    system("rm -rf $dumpdir/*");
}

system("rm -f $pidfile");
