#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

# use lib '../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '/opt/scot/lib';
use Scot::App::Rss;
use Scot::Env;
use Data::Dumper;
use DateTime::Format::Strptime;

$ENV{http_proxy} = 'http://proxy.sandia.gov:80';
$ENV{https_proxy} = 'http://proxy.sandia.gov:80';

say "--- Starting Rss  ---";

my $config_file = $ENV{'scot_app_rss_config_file'} // 
                    '/opt/scot/etc/rss.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);

my $mongo = $env->mongo;

my $col = $mongo->collection('Feed');

foreach my $f (@{$env->feeds}) {

    print "Loading $f\n";

    my $rec = {
        owner   => 'scot-rss',
        groups  => $env->default_groups,
        status  => 'active',
        name    => $f->{name},
        type    => 'rss',
        uri     => $f->{url},
    };

    $col->create($rec);
}
            


