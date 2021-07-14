#!/usr/bin/env perl

use strict;
use warnings;
use lib '../../../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Env;
use Scot::Flair::Worker;
use HTML::Entities;
use Mojo::JSON qw(encode_json decode_json);
use Meerkat;
use feature qw(say);

my $config_file = "./test.cfg.pl";
my $env         = Scot::Env->new({config_file => $config_file});
system("/usr/bin/mongo scot-test ./reset.js");

my $t   = Test::Mojo->new('Scot');

ok (defined $t, "Test::Mojo defined");

my $worker      = Scot::Flair::Worker->new({env => $env});
my $processor   = $worker->get_processor({data=>{type=>'remoteflair'}});

is (ref($processor), "Scot::Flair::Processor::Remoteflair", "Got Processor");

my $start_queue_size = get_queuesize();

my $postdata = {
    command => 'flair',
    html    => qq|
<html>
  <body>
    <h1>Foobar strikes Again</h1>
    <p>This time from 10.10.10.1</p>
  </body>
</html>
|,
    uri     => 'http://foo.com/recent.html',
};

$t->post_ok( '/scot/api/v2/remoteflair'  => json => $postdata )->status_is(202) or die;
say Dumper($t->tx->res->json);
my $rfid    = $t->tx->res->json->{rfid} + 0;

my $after_queue_size = get_queuesize();
is ($start_queue_size + 1, $after_queue_size, "Queue size increased by 1");

$t  ->get_ok('/scot/api/v2/remoteflair/'.$rfid => json => {})
    ->status_is(200)
    ->json_is('/status' => 'requested')
    ->json_is('/md5' => 'dce7a675a9e60fc9d00b7bbee6ccc884');
my $rfrec = $t->tx->res->json;
say Dumper($rfrec);

my $mongo   = $env->mongo;
my $rfobj   = $mongo->collection('Remoteflair')->find_iid($rfid);

my $results     = $processor->flair_object($rfobj);


$t  ->get_ok('/scot/api/v2/remoteflair/'.$rfid => json => {})
    ->status_is(200)
    ->json_is('/status' => 'ready')
    ->json_is('/md5' => 'dce7a675a9e60fc9d00b7bbee6ccc884')
    ->json_is('/results/entities/0/type' => 'ipaddr')
    ->json_is('/results/entities/0/value' => '10.10.10.1');

done_testing();

sub get_queuesize {
    my $PASS="admin";
    my $rf_queue_cmd = "curl -s -u admin:$PASS ".
                    "http://localhost:8161/api/jolokia/read/".
                    "org.apache.activemq:type=Broker,brokerName=localhost,".
                    "destinationType=Queue,destinationName=remoteflair/QueueSize ";
    my $rf_queue_size_raw  = `$rf_queue_cmd`;
    my $rf_queue_size_json = decode_json($rf_queue_size_raw);
    my $rf_queue_size      = $rf_queue_size_json->{value};

    say "Queue Size for remoteflair = $rf_queue_size";
    return $rf_queue_size;
}
    
