#!/usr/bin/env perl
use lib '../../lib';

$ENV{'no_proxy'} = 'localhost,127.0.0.1';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Util::ElasticSearch;
use Scot::Util::Config;
use Scot::Util::Logger;
my $confobj = Scot::Util::Config->new({
    paths   => ['../../../Scot-Internal-Modules/etc/'],
    file    => 'logger_test.cfg',
});
my $loghref = $confobj->get_config();
my $log     = Scot::Util::Logger->new($loghref);

my $es  = Scot::Util::ElasticSearch->new({
    log => $log,
    config => {
        nodes => [
         'as3001snllx.sandia.gov:9200',
        ],
    },
});

my $type    = "testcol";
my $index   = "es_test";

my $doc = {
    id      => 1,
    subject => 'test doc 1',
    body    => 'The quick brown fox jumped over the xylophone zanily',
};

ok ($es->index($type, $doc, $index), "Doc submitted of indexing");


$doc = {
    id  => 2,
    subject => 'test doc 2',
    body    => 'foo bar boom baz',
};
ok ($es->index($type, $doc, $index), "Doc submitted of indexing");

sleep 1;

my $ret = $es->search({
    query => {
        term   => { body => "fox" },
    }
}, $index);

my $match_id    = $ret->{hits}->{hits}->[0]->{_id};

is ($match_id, 1, "Got the right document");

$ret = $es->search({
    query => {
        match   => {
            body    => {
                query   => "boom",
            }
        }
    }
}, $index);
$match_id    = $ret->{hits}->{hits}->[0]->{_id};
is ($match_id, 2, "Got the right document");

$ret    = $es->search({
    query   => {
        query_string    => {
            query   => '/fo./',
        }
    }
}, $index);

is ($ret->{hits}->{total}, 2, "Got both docs from RE search");

print Dumper($ret)."\n";

$es->delete_index($index);

done_testing();
exit 0;

