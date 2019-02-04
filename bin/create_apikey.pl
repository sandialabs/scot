#!/usr/bin/env perl
use strict;
use warnings;
use v5.16;
use lib '../lib';
use lib '/opt/scot/lib';

use Data::UUID;
use Scot::Env;

my $env = Scot::Env->new(
    config_file => "/opt/scot/etc/scot.cfg.pl"
);

my $mongo   = $env->mongo;
my $usercol = $mongo->collection('User');
my $userobj = $usercol->find_one({ username => $ARGV[0] });

die unless defined $userobj;

my $user    = $userobj->username;
my $groups  = $userobj->groups;

my $ug  = Data::UUID->new();
my $key = $ug->create_str();
my $record  = {
    apikey  => $key,
    groups  => $groups,
    username    => $user,
};

my $apikeycol   = $mongo->collection('Apikey');
my $apikey      = $apikeycol->create_from_api($record);


