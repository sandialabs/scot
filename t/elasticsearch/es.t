#!/usr/bin/env perl
use lib '../../lib';

$ENV{'no_proxy'} = 'localhost,127.0.0.1';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Try::Tiny;
use v5.18;

use Scot::Util::ElasticSearch;
$ENV{'scot_config_file'}    = "./es.test.cfg.pl";
my $env = Scot::Env->new({ config_file => $ENV{'scot_config_file'}});
my $es  = $env->es;
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
    {
        id      => 2,
        owner   => "maddox",
        target  => {
            id      => 2,
            type    => 'event',
        },
        body_plain  => "The google.com address is 10.10.10.1",
        updated     => time(),
        parent      => 0,
    },
    {
        id      => 3,
        owner   => "todd",
        target  => {
            id      => 3,
            type    => 'incident',
        },
        body_plain  => "foobar is a boombaz of kitkilly casterian finish",
        updated     => time(),
        parent      => 0,
    },
    {
        id      => 4,
        owner   => "todd",
        target  => {
            id      => 3,
            type    => 'incident',
        },
        body_plain  => "this has 1010101 in it and 10 10 10 1 in it",
        updated     => time(),
        parent      => 0,
    },
);

my $body    = {
     settings    => {
         analysis    => {
             analyzer    => {
                 scot_analyzer   => {
                     tokenizer   => "my_tokenizer",
                 },
             },
             tokenizer   => {
                 my_tokenizer    => {
                     type    => "uax_url_email", # what is this?
                 }
             },
         },
     },
    mappings    => {
        entry   => {
            _all    => {
                store   => 1,
            },
            properties  => {
                id      => { type   => "integer", },
                owner   => { type   => "string", index => "analyzed" },
                groups  => {
                    properties  => {
                        read    => { 
                            type    => "string",
                            index   => "not_analyzed",
                        },
                        modify    => { 
                            type    => "string",
                            index   => "not_analyzed",
                        },
                    }
                },
                target  => {
                    properties  => {
                        id      => { type   => "integer" },
                        type    => { 
                            type    => "string",
                            index   => "not_analyzed",
                        },
                    },
                },
                body_plain  => {
                    type    => "string",
                    # index   => "not_analyzed",
                    index   => "analyzed",
                    fields  => {
                        raw => {
                            type    => "string",
                            # index   => "not_analyzed",
                            index   => "analyzed",
                        }
                    }
                },
                updated => {
                    type    => "date",
                    format  => "strict_date_optional_time||epoch_second",
                },
                created => {
                    type    => "date",
                    format  => "strict_date_optional_time||epoch_second",
                },
                when => {
                    type    => "date",
                    format  => "strict_date_optional_time||epoch_second",
                },
                parsed  => { type => "integer" },
                summary => { type => "boolean" },
                task    => {
                    properties  => {
                        when    => {
                            type    => "date",
                            format  => "strict_date_optional_time||epoch_second",
                        },
                        who    => { 
                            type    => "string",
                           index   => "not_analyzed",
                        },
                        status  => {
                            type    => "string",
                           index   => "not_analyzed",
                        },
                    }
                },
                is_task => { type => "boolean" },
                parent  => { type => "integer" },
            }
        },
    },
};

try {
    say "    dropping existing index $index";
    my $results = $es->delete_index($index);
    say Dumper($results);
}
catch {
    say "    $index does not exist";
    say "    moving on...";
};

say "Creating Index $index...";
my $results = $es->create_index($index,$body);
say Dumper($results);

foreach my $entry (@entries) {
    say "    indexing entry ".$entry->{id};
    my $results = $es->index($index, "entry", $entry);
    say Dumper($results);
}

say "Performing search for owner sydney";
my $query   = {
#    explain => 1,
    query   => {
        match   => { 
            owner => 'sydney'
        },
    }
};
sleep 2;
my $results = $es->search($index, "entry", $query );
say Dumper($results);

say "Performing search for 10.10.10.1";

my $query   = { 
    query   => {
        match   => {
            _all    => '10.10.10.1',
        }
    }
};
my $results = $es->search($index, "entry", $query );
say Dumper($results);

