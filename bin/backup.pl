#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../lib';

use Scot::Util::Config;
use Scot::Env;

my $cfgobj  = Scot::Util::Config->new({
    file    => "backup.cfg",
    paths   => [ '/opt/scot/etc' ],
});
my $config  = $cfgobj->get_config();


# $config is
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

my $pidfile = $config->{pidfile};
if ( -s $pidfile ) {
    die "$pidfile exists and is non-zero length, implies another backup is running";
}

open my $pidfh, ">", $pidfile or die "Unable to create PID file $pidfile!";
print $pidfh "$$";
close $pidfh;

my $dumpdir = $config->{location};
unless ($dumpdir) {
    warn "$dumpdir is missing! Setting to /tmp/dump";
    $dumpdir = "/tmp/dump";
}

unless (-d $dumpdir ) {
    system("mkdir -p $dumpdir");
}


system("rm -rf $dumpdir/*");

my $cmd = "/usr/bin/mongodump ";

if ( $config->{user} and $config->{pass} ) {
    $cmd .= "-u $config->user -p $config->pass ";
}

if ( $config->{dbname} ) {
    $cmd .= "--db ". $config->{dbname}." ";
}
else {
    $cmd .= "--db scot-prod ";
}

$cmd .= "--oplog -o $dumpdir";

system($cmd);
my $tarloc = "/tmp";
if ( $config->{tarloc} ) {
    unless ( -d $config->{tarloc} ) {
        system ("mkdir -p $tarloc" );
    }
    $tarloc = $config->{tarloc};
}

# now backup elasticsearch

# is there a repo?
my $escmd   = $config->{es_server}."/_snapshot/scot_backup/snapshot_1";

my $repo_query = `curl -XGET $cmd`;
if ( $repo_query =~ /repository_missing_exception/ ) {
    # need to create the repo 
    my $create = $config->{es_server} .qq|/_snapshot/scot_backup/ -d '{ "scot_backup": { "type": "fs", "settings": { "compress": "true", "location": "|. $config->{es_backup_location} .qq|" } } }'|;
    my $status = `curl -XPUT $create`;
    unless ( $status =~ /acknowledged\":true/ ) {
        die "Failed to create create repo for ES backup: $status\n";
    }
}

my $status = `curl -XPUT $escmd`;
unless ( $status =~ /acknowledged\":true/ ) {
    warn "FAILED to create a snapshot of ES data!";
}
else {
    # loop and wait for snapshot to complete;
    my $status = `curl -XGET $escmd`;
    my $count   = 0;
    while ( $status !~ /SUCCESS/ ) {
        sleep 5;
        $status = `curl -XGET $escmd`;
        $count++;

        if ( $count > 100 ) {
            warn "Snapshot did not complete in timely matter. Continuing...";
            $status = "SUCCESS";
        }
    }
}



my $esdir   = $config->{es_backup_location};
my $dt  = DateTime->now();
my $ts  = $dt->year . $dt->month . $dt->day . $dt->hour . $dt->minute;
system("tar cvzf $tarloc.$ts.tgz $dumpdir $esdir");

if ( $config->{cleanup} ) {
    system("rm -rf $dumpdir/*");
    my $status = `curl -XDELETE $escmd`;
    unless ( $status =~ /acknowledged\":true/ ) {
        die "Failed to delete repo snapshot for ES backup: $status\n";
    }
    system("rm -rf $esdir/*");
}

system("rm -f $pidfile");
