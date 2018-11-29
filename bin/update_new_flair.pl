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
$ENV{'scot_logfile'}        = "/var/log/scot/scot.newflair.log";
$ENV{'scot_config_file'}    = '../../Scot-Internal-Modules/etc/scot.cfg.pl';

my $env = Scot::Env->new({
    config_file => $ENV{'scot_config_file'},
});
my $mongo   = $env->mongo;
my $entitycol   = $mongo->collection('Entry');
my $alertcol    = $mongo->collection('Alert');
# my $search_term = q{CVE};
my $search_term = 'Island Servers LTD';

my $es  = $env->es;
#my $es_search   = {
#    query   => {
#        filtered    => {
#            filter  => {
#                or  => [
#                    { term => { _type => { value => "alert" } } },
#                    { term => { _type => { value => "entry" } } },
#                    { term => { _type => { value => "entity" } } },
#                ],
#            },
#            query   => {
#                query_string    => {
#                    query   => $search_term,
#                    rewrite => "scoring_boolean",
#                    analyze_wildcard => "true",
#                },
#            },
#        },
#    },
#    _source => [ qw(id target body_plain alertgroup data value) ],
#};

my $es_search = {
    query   => {
                body => $search_term,
    }
};

my $response = $es->do_request_new($es_search);
my $hits     = $response->{hits};
my $total    = $hits->{total};
my @records  = @{ $hits->{hits} };
my @results  = ();

say "Searching for $search_term";
say "     found $total hits";
say "--------------------------";

foreach my $record (@records) {
    say Dumper($record);
}





