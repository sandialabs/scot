#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use lib '/opt/scot/lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '../lib';
use Scot::App::Mail;
use Scot::Env;
use Data::Dumper;
use Net::IP;
use Net::Subnet;

my $config_file = '/opt/scot/etc/scot.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);

my $timer       = $env->get_timer("Mongo");

my $mongo       = $env->mongo;
my $collection  = $mongo->collection('Entity');
my $block       = "134.253.0.0/16";

my ($targetip,$bits) = split(/\//,$block);

say "bits = $bits";

my $ipobj   = Net::IP->new($block);
my $match   = substr($ipobj->binip,0,$bits);

say "IP     : ".$ipobj->ip;
say "bin    : ".$ipobj->binip;
say "match  : ".substr($ipobj->binip,0,$bits);
say "mask   : ".$ipobj->mask;


my $cursor = $collection->find({
    'data.binip'    => qr/^$match/
});

my @entity_ids  = ();
while ( my $entity = $cursor->next ) {
    push @entity_ids, {
        value   => $entity->value,
        id      => $entity->id,
    };
}

say join("\n", map { Dumper($_) } @entity_ids);
say "Found ".scalar(@entity_ids)." Matching IP addresses";
my $elapsed = &$timer;
say "    in $elapsed seconds";

my $cidr    = subnet_matcher qw(
    $block
);

exit 0;
$timer       = $env->get_timer("PurePerl"); 
$cursor      = $collection->find({type   => 'ipaddr'});
@entity_ids  = ();
while (my $entity = $cursor->next ) {
    if ( $cidr->($entity->value) ) {
        push @entity_ids, {
            value   => $entity->value,
            id      => $entity->id,
        };
    }
}

say join("\n", map { Dumper($_) } @entity_ids);
say "Found ".scalar(@entity_ids)." Matching IP addresses";
$elapsed = &$timer;
say "    in $elapsed seconds";

