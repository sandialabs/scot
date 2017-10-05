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

say "--- Starting Mail Ingester ---";

my $config_file = $ENV{'scot_config_file'} // 
                    '/opt/scot/etc/scot.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);

my $mongo   = $env->mongo;
my $metcol  = $mongo->collection('Metric');
my $now     = $env->now;
my $minutes = 10;
my $ago  = $now - ($minutes * 60 );
my $cursor  = $metcol->find({
    metric  => qr/healthcheck received/i,
    epoch   => { '$gt'  => $ago },
});

my $senders = $env->mail_watch_senders // [];

if ( ! defined $senders ) {
    die "You need to create an array ref in $config_file for mail_watch_senders";
}

my %seen;
foreach my $sender (@$senders) {
    $seen{$sender} = 0;
}

while (my $stat = $cursor->next) {
    my $subject = $stat->metric;
    my $system  = ( split(/ /,$subject) )[0];
    $seen{$system}++;
}

foreach my $sender (@$senders) {
    if ( $seen{$sender} == 0 ) {
        $env->mq->send("scot", {
            action  => "wall",
            data    => {
                message => $sender . "has not sent health check email in $minutes minutes",
                who => "health check",
                when => $now,
            }
        });
    }
}


