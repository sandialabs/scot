#!/bin/env perl

use v5.18;
use Data::Dumper;
use Mojo::UserAgent;
use Mojo::JSON qw/encode_json decode_json/;

my $ua  = Mojo::UserAgent->new();
my $url = 'http://localhost:9200/_search';

my $json = {
    'size' => 0,
    'query' => {
        'simple_query_string' => {
            'query' => 'test',
            'fields' => [
                '_all'
            ]
        }
    }
};

my $tx = $ua->post($url => $json);

say Dumper($tx->success);
