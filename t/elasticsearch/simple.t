#!/usr/bin/env perl

use Data::Dumper;
use Try::Tiny;
use Search::Elasticsearch;
use v5.18;

$ENV{'no_proxy'} = '127.0.0.1,localhost';

my $es  = Search::Elasticsearch->new(
    nodes       => [qw(localhost:9200)],
    cxn_pool    => 'Sniff',
    trace_to    => 'Stderr',
);
$Search::Elasticsearch::Error::DEBUG = 2;

my $index   = "entry_test";
my @entries = (
    {
        id      => 1,
        owner   => "sydney",
        target  => {
            id      => 1,
            type    => 'event',
        },
        body_plain  => "The quick brown fox jump over the lazy dog",
        updated     => time(),
        parent      => 0,
    },
);


try {
    say "    dropping existing index $index";
    my $results = $es->indices->delete(index => $index);
    say Dumper($results);
}
catch {
    say "    $index does not exist";
    say "    moving on...";
};

say "Creating Index $index...";
my $results = $es->indices->create(
    index   => $index,
);
say Dumper($results);

foreach my $entry (@entries) {
    say "    indexing entry ".$entry->{id};
    my $results = $es->index(
        index   => $index, 
        type    => "entry", 
        id      => $entry->{id},
        body    => $entry
    );
    say Dumper($results);
}

 sleep 2;

my $query   = {
    explain => 1,
    query   => {
        match   => { 
            owner => 'sydney'
        },
    }
};
say "Performing search";
my $results = $es->search(index => $index, type=>"entry",  body => $query );
say Dumper($results);
