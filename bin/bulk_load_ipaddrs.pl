#!/usr/bin/env perl

use lib '../lib';
use lib '/opt/scot/lib';
use Data::Dumper;
use Scot::Env;
use File::Slurp;

my $env   = Scot::Env->new(config_file=>'/opt/scot/etc/scot.cfg.pl');
my $mongo = $env->mongo;
my $csvfile = "/tmp/bulk.csv";

my @lines   = read_file($csvfile);

foreach my $line (@lines) {

    my @row = split(',',$line);

    my $ipaddr  = $row[0];
    my $subnet  = $row[1];
    my $machine = $row[2];
    my $make    = $row[3];
    my $site    = $row[4];
    my $area    = $row[5];
    my $building = $row[6];
    my $room    = $row[7];

}






