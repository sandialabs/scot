#!/usr/bin/env perl
use lib '../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use Try::Tiny;
use Scot::App::Reflair;
use v5.18;


$ENV{'no_proxy'} = 'localhost,127.0.0.1';
$ENV{'scot_config_file'}    = "./reflair.cfg.pl";

system("mongo scot-testing < ../../../install/src/mongodb/reset.js 2>&1 > /dev/null");

my $env = Scot::Env->new({config_file=>$ENV{'scot_config_file'}});

use_ok('Scot::App::ReFlair');

my $reflair = Scot::App::Reflair->new( env => $env );
my $es      = $env->es;

my $index   = "reflair_test";
my @data    = (
    {
        type    => "entry",
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
        type    => "entry",
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
        type    => "alert",
        id  => 1,
        status  => "open",
        data    => {
            column1 => "foobar",
            column2 => "200.100.50.25",
        },
        created => 10,
        updated => 200,
        data_with_flair    => {
            column1 => "foobar",
            column2 => '<span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="200.100.50.25">200.100.50.25</span>',
        },
        columns => [ 'column1', 'column2' ],
        when    => 5,
        viewed_by   => {
            tbruner => {
                from    => '10.10.10.1',
                count   => 2,
                when    => 150,
            },
        },
        subject => "Stuff to Test",
        tags    => [ "test", "ids" ],
    },
    {
        type    => "alert",
        id  => 2,
        status  => "open",
        data    => {
            column1 => "foobar",
            column2 => "200.200.50.25",
        },
        created => 20,
        updated => 200,
        data_with_flair    => {
            column1 => "foobar",
            column2 => '<span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="200.200.50.25">200.200.50.25</span>',
        },
        columns => [ 'column1', 'column2' ],
        when    => 5,
        viewed_by   => {
            tbruner => {
                from    => '20.20.20.1',
                count   => 2,
                when    => 150,
            },
        },
        subject => "Stuff to Test x 2",
        tags    => [ "test", "ids" ],
    },
    {
        type    => "entry",
        id      => 6,
        owner   => "todd",
        target  => {
            id      => 1,
            type    => 'event',
        },
        body_plain  => "what did the brown fox say?",
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

my @temp    = ();
foreach my $item (@data) {
    my $type = delete $item->{type};
    my $id   = $item->{id};
    say "    indexing $type $id";
    my $results = $es->index($index, $type, $item);
    push @temp, { type => $type, id => $id };
}



sleep 2;

my $reflairterm = "brown fox";

my $entity  = $env->mongo->collection('Entity')->create({
    value   => $reflairterm,
    type    => "threat_actor",
});

my $query   = $reflair->build_es_query($entity);
my $expected_q  = {
              'query' => {
                'match' => {
                '_all' => 'brown fox'
                }
            }
};

cmp_deeply($query, $expected_q, "Query is correct");

my @appearances = $reflair->find_appearances($entity->id, $index);
my @expected_a  = (
    {
        'id' => 6,
        'type' => 'entry'
    },
    {
        'id' => 1,
        'type' => 'entry'
    }
);

cmp_bag(\@appearances, \@expected_a, "Appearances are correct");

done_testing();
exit 0;

