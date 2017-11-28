#!/bin/env perl

use v5.18;
use Data::Dumper;
use Mojo::UserAgent;
use Mojo::JSON qw/encode_json decode_json/;

my $ua  = Mojo::UserAgent->new();
my $url = 'http://localhost:9200/_search';

my $json = {
    'query' => {
        'simple_query_string' => {
            'query' => 'google',
            'fields' => [
                '_all'
            ]
        }
    },
    size    => undef
};

my $reallyjson = encode_json($json);

my $tx = $ua->post($url => $reallyjson);

my $retjson = Dumper($tx->success->json);

say Dumper($retjson);
exit 0;

my $foo = `curl -XPOST http://localhost:9200/_search -d'{"query":{"simple_query_string":{"query":"google","fields":["_all"]}},"size":null}'`;

say Dumper($foo);


