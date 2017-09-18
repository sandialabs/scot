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

my @entries = (
    {
        id      => 1,
        owner   => "sydney",
        groups  => {
            read    => [ 'rios', 'bruner' ],
            modify  => [ 'bruner' ],
        },
        target  => {
            id      => 1,
            type    => 'event',
        },
        body_plain  => "The quick brown fox jump over the lazy dog",
        updated     => time(),
        created     => time() - 10,
        when        => time() - 20,
        parsed      => 1,
        summary     => 0,
        task        => {},
        is_task     => 0,
        parent      => 0,
    },
    {
        id      => 2,
        owner   => "maddox",
        groups  => {
            read    => [ 'rios', 'bruner' ],
            modify  => [ 'bruner' ],
        },
        target  => {
            id      => 2,
            type    => 'event',
        },
        body_plain  => "The google.com address is 10.10.10.1",
        updated     => time(),
        created     => time() - 10,
        when        => time() - 20,
        parsed      => 1,
        summary     => 0,
        task        => {},
        is_task     => 0,
        parent      => 0,
    },
    {
        id      => 3,
        owner   => "todd",
        groups  => {
            read    => [ 'bruner' ],
            modify  => [ 'bruner' ],
        },
        target  => {
            id      => 3,
            type    => 'incident',
        },
        body_plain  => "foobar is a boombaz of kitkilly casterian finish",
        updated     => time(),
        created     => time() - 10,
        when        => time() - 20,
        parsed      => 1,
        summary     => 0,
        task        => {},
        is_task     => 0,
        parent      => 0,
    },
);

my $index   = "entry_test";
my $body    = {
#     settings    => {
#         analysis    => {
#             analyzer    => {
#                 scot_analyzer   => {
#                     tokenizer   => "my_tokenizer",
#                 },
#             },
#             tokenizer   => {
#                 my_tokenizer    => {
#                     type    => "uax_url_email", # what is this?
#                 }
#             },
#         },
#     },
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
#                            index   => "not_analyzed",
                        },
                        modify    => { 
                            type    => "string",
#                            index   => "not_analyzed",
                        },
                    }
                },
                target  => {
                    properties  => {
                        id      => { type   => "integer" },
                        type    => { 
                            type    => "string",
#                            index   => "not_analyzed",
                        },
                    },
                },
                plain  => {
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
#                            index   => "not_analyzed",
                        },
                        status  => {
                            type    => "string",
#                            index   => "not_analyzed",
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
    my $results = $es->delete_index($index, 1);
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

say "Performing empty search";
my $query   = {
    explain => 1,
    query   => {
        match   => { 
            owner => 'sydney'
        },
    }
};
# my $results = $es->search($index, { query => $query });
my $results = $es->search($index, "entry", $query );
say Dumper($results);

say "Direct e client with index";
my $e = $es->es;
my $results = $e->search(index => $index, type=>"entry",  body => $query );
say Dumper($results);

say "Direct e client with no index";
my $e = $es->es;
my $results = $e->search(body => $query );
say Dumper($results);

say "Get Source of doc 1";
my $results = $e->get_source(index => "entry_test", type=>"entry", id=>1);

say Dumper($results);

say "HEalth";
my $results = $e->cluster->health;
say Dumper($results);

my $results = $e->search();
say Dumper($results);
