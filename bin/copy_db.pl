#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;

use lib '../lib';

use Log::Log4perl;
use File::Slurp;
use JSON;


use Getopt::Long qw(GetOptions);

$| = 1;
my $olddb           =   'scotng-prod';   # the old database (mongo name)
my $destdb          =   'scotng-dev';    # the new database (mongo name)
my $config_file     =   '../scot.json';
my $sourcehost      = "HOSTNAME_OF_SERVER_DATA_IS_COMING_FROM";
my $source_dbuser   = "USERNAME_THAT_HAS_ACCESS_TO_MONGO_DB";
my $source_dbpass   = "PASSWORD_FOR_ABOVE_USER";
my $dontdrop        = "";               # if set don't drop dest db

GetOptions(
    "sourcedb=s"      => \$olddb,
    "destdb=s"        => \$destdb,
    "sourcehost=s"    => \$sourcehost,
    "dontdrop"        => \$dontdrop,
) or die  <<EOF

    Invalid option!

    Usage: copy_db.pl   --sourcedb srcdbname --destdb dstdbname 
                        --sourcehost hostname

    srcdbname and dstdbname are both the internal mongodb names

EOF
;

my $config_href = get_configuration($config_file);
my $log         = get_logger("../etc/conversion.log.conf");

$log->debug("================================================");
$log->debug("- Beginning Copy with following options:   ");
$log->debug("- sourcedb   = $olddb");
$log->debug("- sourcehost = $sourcehost");
$log->debug("- destdb     = $destdb");
$log->debug("- config     = $config_file");
$log->debug("================================================");

my $dest_host = "localhost";

print "Copying Database\n";
printf "               %10s     %10s\n", "host", "db";
printf "Source       = %10s     %10s\n", $sourcehost,$olddb;
printf "Destination  = %10s     %10s\n", $dest_host,$destdb;

my $dropcmd = qq|mongo $destdb --eval "db.dropDatabase();"|;
my $copycmd = qq|mongo $destdb --eval "db.copyDatabase('$olddb', '$destdb', '$sourcehost', '$source_dbuser', '$source_dbpass');"|;

if ($dontdrop ne '') {
    print "Executing:\n$dropcmd\n";
    system($dropcmd);
}

print "Executing:\n$copycmd\n";
system($copycmd);

exit 0;

sub get_configuration {
    my $filename    = shift;
    my $raw         = read_file($filename);
    my $json        = JSON->new->relaxed(1);
    my $href        = $json->decode($raw);
    return $href;
}

sub get_logger {
    my $filename    = shift;
    Log::Log4perl::init($filename);
    return Log::Log4perl->get_logger();
}
