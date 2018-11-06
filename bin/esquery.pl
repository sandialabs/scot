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
                    '/opt/scot/etc/esquery.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);

my $query   = {
    query   => {
        filtered    => {
            filter      => {
                or          => [
                    { term => { _type => { value => "alert" } } },
                    { term => { _type => { value => "entry" } } },
                ]
            },
            query => {
                query_string    => {
                    query   => $qstring
                }
            }
        }
    },
    highlight   => {
        require_field_match => \0,
