#!/usr/bin/env perl

use lib '/opt/scot/lib';
use strict;
use warnings;
use v5.16;

my $env = Scot::Env->new(
    config_file => "/opt/scot/etc/scot.cfg.pl"
);
my $mongo   = $env->mongo;
my $mq      = $env->mq;

my @collections = (qw(alert entry));

foreach my $colname (@collections) {

    print "Updating $colname...\n";

    my $col = $mongo->collection(ucfirst($colname));
    my $cur = $col->find({});

    while ( my $obj = $cur->next ) {

        $mq->send("scot", {
            action  => "update",
            data    => {
                who     => "reflair",
                type    => $colname,
                id      => $obj->id,
            }
        });
        sleep 1;
    }
}


