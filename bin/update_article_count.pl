#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

# use lib '../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '/opt/scot/lib';
use Scot::Env;
use Data::Dumper;
use DateTime::Format::Strptime;

$ENV{http_proxy} = 'http://wwwproxy.sandia.gov:80';
$ENV{https_proxy} = 'http://wwwproxy.sandia.gov:80';

say "--- Starting Rss  ---";

my $config_file = $ENV{'scot_app_rss_config_file'} // 
                    '/opt/scot/etc/rss.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);

my $mongo   = $env->mongo;
my $dcol    = $mongo->collection('Dispatch');
my $fcol    = $mongo->collection('Feed');

my $results = {};

my $cursor  = $dcol->find();

while (my $d = $cursor->next ) {
    my $name = pop @{$d->source};
    $results->{$name}++;
}

foreach my $name (keys %$results) {
    my $feed = $fcol->find_one({name => $name});
    my $ac  = $results->{$name};
    print "updating $name with value $ac\n";



    $feed->update({
        '$set'    => {
            article_count => $ac
        }
    });
}


