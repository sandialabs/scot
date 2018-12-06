#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

use lib '/opt/scot/lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '../lib';
use Scot::App::Mail;
use Scot::Env;
use Data::Dumper;
use Net::IP;

my $config_file = '/opt/scot/etc/scot.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);


my $mongo       = $env->mongo;
my $collection  = $mongo->collection('Entity');
my $cursor      = $collection->find({type   => 'ipaddr'});

while (my $entity = $cursor->next ) {

    my $ipstr   = $entity->value;
    my $ipobj   = Net::IP->new($ipstr);
    my $binip   = $ipobj->binip;

    say sprintf("IP: %15s ---> %32s",$ipstr,$binip);

    $entity->update_set(data => { binip => $binip });
}
