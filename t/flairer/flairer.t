#!/usr/bin/env perl
use lib '../lib/';
use lib '../../lib';
use Test::More;
use Data::Dumper;
use Scot::App::Flair;

my $flair   = Scot::App::Flair->new(
    paths               => [
        '../../etc',
        '/home/tbruner/Scot-Internal-Modules/etc',
        '/opt/scot/etc',
    ],
    configuration_file  => 'flair.app.cfg',
    interactive         => 1
);

#my @ids = (
#    40578387,
#    40578388,
#    40578389,
#    40578390,
#    40578391,
#);
#
#foreach my $id (@ids) {
#    $flair->process_one("alert", $id);
#}

my $alertgroup_id = 1495989;
$flair->process_alertgroup($alertgroup_id);
