#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

use lib '../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '/opt/scot/lib';
use Scot::Env;
use Data::Dumper;


my $config_file = $ENV{'scot_app_esquery_config_file'} // 
                    '/opt/scot/etc/scot.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);

my $qstring = "S-1-5-86-1544737700-199408000-2549878335-3519669259-381336952";

my $query   = {
    query   => {
        match   => {
            body_plain    => $qstring,
        }
    }
};

my $json = $env->es->search("scot", ['entry','alert'], $query);

say Dumper($json);
