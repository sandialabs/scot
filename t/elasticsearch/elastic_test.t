#!/usr/bin/env perl
$ENV{'no_proxy'} = 'localhost,127.0.0.1';
use lib '../../lib';

use Test::More;
use Test::Deep;
use Data::Dumper;
use Try::Tiny;
use JSON::XS;
use v5.18;

use Scot::Env;
my $env = Scot::Env->new({
    config_file => "./es.test.cfg.pl",
});

my $index   = "es_test_index";
my $type    = "entry";
my $mapping = load_mapping();
my $es      = $env->es;

ok(ref($es) eq "Scot::Util::ElasticSearch");

try {
    say "-- Dropping existing index $index ";
    my $results = $es->delete_index($index);
    ok( $results->{acknowledged} = 1, "... Dropped existing index $index");
}
catch {
    say "...Index $index not present. ";
};

index_entries();
my @searches = load_searches();
foreach my $search (@searches) {
    my $query   = $search->{query};
    my $expect  = $search->{expect};
    my $result  = $es->search($index, $type, $query);
    is($result->{hits}, $expect, $search->{title});
}

sub index_entries {
    my @entries = load_entries();
    foreach my $entry (@entries) {
        my $results = $es->index($index, "entry", $entry);
        my $created = $results->{created};
        my $successful = $results->{_shards}->{successful};
        ok($created == 1 && $successful == 1, "Entry created");
    }
}

sub load_mapping {
    my $mapping    = {
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
    return $mapping;
}

sub load_entries {

    my @entries = (
        {
            owner   => "sydney",
            groups  => [
                read    => [ "bruner", "rios" ],
                modify  => [ "bruner" ],
            ],
            target  => {
                id      => 1,
                type    => "event",
            },
            body_plain  => "the quick brown fox jumped over the lazy dog",
            # updated   =>  filled in at creation time
            # created       ...
            # when          ...
            parent      => 0,
            parsed      => 1,
            summary     => 0,
            task        => {},
            is_task     => 0,
        },
    );
    return wantarray ? @entries : \@entries;
}

sub load_alerts {

    my @alerts = (
        {
            message_id  => '1',
            subject     => "Alertgroup 1",
            tag         => [qw(hardees tacobell pizzahut)],
            source      => [qw(splunk)],
            data        => [
                {

                },
            ],
            columns     => [ ],
        },
    );
    return wantarray ? @alerts : \@alerts;
}
