#!/usr/bin/env perl
use lib '../../Scot-Internal-Modules/lib';
use lib '../lib';
use Test::More;
use Data::Dumper;
use Test::Deep;

use_ok('Scot::Mquery', "use Scot::Mquery");

my $q  = Scot::Mquery->new();

ok(defined $q, "Built a MongoQuery builder");
is(ref($q), "Scot::Mquery", "of correct type");

my $get_op_value_test_data = {
    '<4'    => { op => '<', value => 4 },
    '<=4'   => { op => '<=', value => 4 },
    '>4'    => { op => '>', value => 4 },
    '>=44'  => { op => '>=', value => 44},
    '88'    => { op => '=', value => 88},
    '=42'   => { op => '=', value => 42},
};

while (my ($key, $value) = each %$get_op_value_test_data) {
    my ($got_op, $got_val) = $q->get_op_value($key);
    is ($got_op, $value->{op}, "$key op correct");
    is ($got_val, $value->{value}, "$key value correct");
}

my $get_mongo_op_test_data  = {
    '='     => '$in',
    '>='    => '$gte',
    '=>'    => '$gte',
    '>'     => '$gt',
    '<='    => '$lte',
    '=<'    => '$lte',
    '<'     => '$lt',
    'x'     => 'error',
};

while (my ($key, $value) = each %$get_mongo_op_test_data) {
    my $got = $q->get_mongo_op($key);
    is ($got, $value, "Got correct mongo op for $key");
}
is ($q->get_mongo_op(undef), '$in', "Got correct mongo op for undef");

my @parse_date_match_test_data = (
    { key => 'good1', value => [ 123, 456 ], expect => { '$gte' => 123, '$lte' => 456 } },
    { key => 'good2', value => [ 123, 56 ],  expect => { '$gte' => 56, '$lte' => 123 } },
    { key => 'good3', value => "123, 456",   expect => { '$gte' => 123, '$lte' => 456 } },
    { key => 'good4', value => "123, 56",    expect => { '$gte' => 56, '$lte' => 123 } },
    { key => 'bad1', value => "12356", expect => { error => 'invalid datefield match string' }},
    { key => 'bad2', value => [12356], expect => { error => 'must have 2 epochs for date range filter'}},
);

foreach my $t (@parse_date_match_test_data) {
    my $got = $q->parse_date_match($t->{key}, $t->{value});
    cmp_deeply($got, $t->{expect}, "date ".$t->{key}. " produces expected output");
}

my @parse_handler_test_data = (
    { key   => 'start', value => 4, expect => { '$gte' => 4 } },
    { key   => 'end',   value => 4, expect => { '$lte' => 4 } },
);
foreach my $t (@parse_handler_test_data) {
    my $got = $q->parse_handler_match($t->{key}, $t->{value});
    cmp_deeply($got, $t->{expect}, "handler ".$t->{key}. " produces expected output");
}

my @parse_numeric_test_data = (
    { key => 'single number', value => 4, expect => 4 },
    { key => 'notn', value => '!3', expect => { '$ne' => 3 } },
    { key => 'array numbers', value => [1,2,3,4], expect => { '$in' => [1,2,3,4] } },
    { key => 'array neg',     value => ['!1',2,3], expect => { '$nin' => [1,2,3] }},
    { key => 'array nin1', value => ['!1',2,3], expect => { '$nin' => [1,2,3] } },
    { key => 'array nin2', value => ['!1','!2','!3'], expect => { '$nin' => [1,2,3] } },
    { key => 'array nin3', value => ['1','!2','3'], expect => { '$nin' => [1,2,3] } },
    { key => 'simple ineq1', value =>'x<4', expect => { '$lt' => 4} },
    { key => 'simple ineq2', value => 'x<=27', expect => { '$lte' => 27 }},
    { key => 'simple ineq3', value =>'x>4', expect => { '$gt' => 4} },
    { key => 'simple ineq4', value => 'x>=27', expect => { '$gte' => 27 }},
    { key => 'expr1', value => '23<=x<=27', expect => { '$gte' => 23, '$lte' => 27 }},
    { key => 'expr2', value => '4>=x>=27', expect => { '$lte' => 4 , '$gte' => 27 }},
    { key => 'degen1', value => '4<x>25', expect => { '$gt' => 25 } },
    { key => 'degen2', value => '4>x<25', expect => { '$lt' => 4 } },
    { key => 'err1', value => [qw(a b c)], expect => {error=>'non-numeric values in numeric array match'}},
    { key => 'err2', value => '<=23', expect => {error=>'malformed numeric match'}},
    { key => 'err3', value => '44>=x>=23', expect => {error=>'first number must be less than last in range comparison' }},
);
foreach my $t (@parse_numeric_test_data) {
    my $got = $q->parse_numeric_match($t->{key}, $t->{value});
    cmp_deeply($got, $t->{expect}, "numeric ".$t->{key}." produces expected output") || print Dumper($got);
}

my @parse_source_tag_test_data = (
    { key => '1', value => [qw(foo bar boom)], expect => { '$all' => [qw(foo bar boom)] } },
    { key => '2', value => [qw(!foo !bar !boom)], expect => { '$nin' => [qw(foo bar boom)] } },
    { key => '3', value => [qw(foo !bar boom)], expect => { '$all' => [qw(foo boom)], '$nin' => ['bar'] } },
    { key => '4', value => "foo, bar,boom", expect => { '$all' => [qw(foo bar boom)] } },
    { key => '5', value => "foo, bar, !boom", expect => { '$all' => [qw(foo bar)], '$nin' => ['boom'] } },
    { key => '6', value => "foo|bar|boom", expect => {'$in' => [qw(foo bar boom)] } },

);
foreach my $t (@parse_source_tag_test_data) {
    my $got = $q->parse_source_tag_match($t->{key}, $t->{value});
    cmp_deeply($got, $t->{expect}, "source tag ".$t->{key}." produces expected output") || print Dumper($got);
}

my @update_test_data = (
    { 
        params  => { foo => 'bar' }, 
        json    => {}, 
        expect  => { foo => 'bar' } 
    },
    { 
        params => { foo => 'bar' }, 
        json   => { foo => 'boom' }, 
        expect => { foo => 'boom'}
    },
    { 
        params  => { boom => { foo => 'bar' }}, 
        json    => {}, 
        expect  => { boom => { foo => 'bar'}},
    },
    { 
        params => { 
            groups => { read => [], modify => ['foo'] },
        }, 
        expect => { error => 'update would remove all read groups'},
    },
    { 
        params => { 
            groups => { read => ['foo'], modify => [] }
        }, 
        expect => { error => 'update would remove all modify groups'}
    },
    { 
        params => {
            groups  => {read => ['foo'], modify => ['bar'] },
        },
        expect => {
            groups => {read => ['foo'], modify => ['bar'] },
        },
    },
);

my $count = 0;
foreach my $t (@update_test_data) {
    $count++;
    my $got = $q->build_update_command($t->{params}, $t->{json});
    cmp_deeply($got, $t->{expect}, "$count got expected output");
}


done_testing();
exit 0;
