#!/usr/bin/env perl
use lib '../../Scot-Internal-Modules/lib';
use lib '../lib';
use strict;
use warnings;
use v5.16;

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Mojo::JSON qw(encode_json decode_json);
use Scot::Env;
use HTML::Entities;

$ENV{'scot_mode'}           = "testing";
$ENV{'scot_auth_type'}      = "Testing";
$ENV{'scot_logfile'}        = "/var/log/scot/scot.link.test.log";
$ENV{'scot_config_file'}    = '../../Scot-Internal-Modules/etc/scot.cfg.pl';

my $env = Scot::Env->new({
    config_file => $ENV{'scot_config_file'},
});
my $mongo   = $env->mongo;
my $entitycol   = $mongo->collection('Entity');
my $cursor      = $entitycol->find({type => {'$in'=> ["email","domain",]}}); # "file","md5","sha1","sha256"]});
$cursor->immortal(1);

while (my $entity = $cursor->next ) {
    my $lcval   = lc($entity->value);
    say "updating entity ".$entity->id." from ".$entity->value." to ".$lcval;
    $entity->update_set(value => $lcval);
}

