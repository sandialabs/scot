#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

use lib '../lib';
use Scot::Env;
use Scot::App::Report;
use Data::Dumper;

my $config  = $ENV{'scot_monthly_report_config_file'} //
              '/opt/scot/etc/david.cfg.pl';

my $env     = Scot::Env->new( config_file => $config );
my $app     = Scot::App::Report->new( env => $env );

my $href    = $app->alertgroup_counts;

say "Alertgroups";
say "date\tcount";
foreach my $date (sort keys %$href) {
    say "$date\t".$href->{$date};
}

$href       = $app->event_counts;
say "\nEvents";
say "date\tcount";
foreach my $date (sort keys %$href) {
    say "$date\t".$href->{$date};
}

$href       = $app->incident_counts;
say "\nIncidents";
say "date\tcount";
foreach my $date (sort keys %$href) {
    say "$date\t".$href->{$date};
}

$href   = $app->response_times;
say "\nResponse Times";
printf "%8s\t%8s\t%9s\t%20s\n","date","category","avg","human readable avg";
foreach my $date (sort keys %$href) {
    foreach my $category (sort keys %{$href->{$date}}) {
        printf "%8s\t%8s\t%6.2f\t%20s\n", $date, $category, $href->{$date}->{$category}->{avg}, $href->{$date}->{$category}->{humanavg} // '';
    }
    print "\n";
}
        
