#!/usr/bin/env perl

use lib '/opt/scot/lib';
use Scot::Env;
use strict;
use warnings;
use v5.16;

my $env = Scot::Env->new(
    config_file => "/opt/scot/etc/scot.cfg.pl"
);
my $mongo   = $env->mongo;
my $mq      = $env->mq;

my @collections = (qw(entry alertgroup));

foreach my $colname (@collections) {

    print "Updating $colname...\n";

    my $col = $mongo->collection(ucfirst($colname));
    my $cur = $col->find({parsed => 0});

    while ( my $obj = $cur->next ) {

        print "updating id = ".$obj->id."\n";

        $mq->send("/topic/scot", {
            action  => "updated",
            data    => {
                who     => "reflair",
                type    => $colname,
                id      => $obj->id,
            }
        });
        sleep 1;
    }
}


