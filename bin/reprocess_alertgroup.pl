#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

use lib '../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';
use Scot::App::Mail;
use Scot::Env;
use Data::Dumper;
use Getopt::Long qw(GetOptions);
use DateTime::Format::Strptime;
use DateTime;

# sample code on how to reprocess an alertgroup for flair
# ./reprocess_alertgroup.pl 123


say "--- Starting Mail Reprocessor ---";

my $config_file = $ENV{'scot_mail_config_file'} // '/opt/scot/etc/alert.cfg.pl';
my $env         = Scot::Env->new({
    config_file => $config_file
});

my $processor   = Scot::App::Mail->new({
    env => $env,
});

my $id = 0;
my $start;
my $end;
my $si;
my $ei;

GetOptions(
    'id=s'  => \$id,
    'start'   => \$start,   # mm/dd/yyyy hh:mm::ss
    'end'   => \$end,
    'si'    => \$si,
    'ei'    => \$ei,
);


if ( $id ) {
    $processor->reprocess_alertgroup($id);
    exit 0;
}

print "Reprocessing from $si to $ei\n";

for (my $index = $si; $index <= $ei; $index++ ) {
    warn "Reprocessing Alertgroup $index\n";
    $processor->reprocess_alertgroup($index);
}
