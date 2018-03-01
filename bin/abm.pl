#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use lib '../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '/opt/scot/lib';
use Scot::App::Mail;
use Scot::Env;
use Data::Dumper;
use DateTime;

my $config_file = $ENV{'scot_config_file'} // 
                    '/opt/scot/etc/scot.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);

my $mongo       = $env->mongo;
my $collection  = $mongo->collection('Alertgroup');
my $cursor      = $collection->find();;
my %results;
my %alerts;

while (my $ag = $cursor->next) {
    my $created = $ag->created;
    my $dt      = DateTime->from_epoch( epoch => $created );
    my $year    = $dt->year;
    my $month   = $dt->month;
    $results{$year}{$month}++;
    $alerts{$year}{$month} += $ag->alert_count;
}

say "alertgroup counts";
say "Year, Month, Amount";
foreach my $y (sort {$a<=>$b} keys %results) {
    foreach my $m (sort {$a<=>$b} keys %{$results{$y}} ) {
        say "$y-$m, $results{$y}{$m}";
    }
}

say "alert counts";
say "Year, Month, Amount";
foreach my $y (sort {$a<=>$b} keys %alerts) {
    foreach my $m (sort {$a<=>$b} keys %{$alerts{$y}} ) {
        say "$y-$m, $alerts{$y}{$m}";
    }
}


