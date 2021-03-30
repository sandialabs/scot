#!/usr/bin/env perl

use lib '../../../../lib';
use strict;
use warnings;

use Scot::Email::Responder::Alert;
use Scot::Env;
use Test::More;
use Test::Deep;
use Data::Dumper;

my $reset_file = "../../../../install/src/mongodb/reset.js";
system("mongo scot-testing < $reset_file 2>&1 > /dev/null");

my $config_file = '../../../../../Scot-Internal-Modules/etc/test_alert_responder.cfg.pl';

my $env = Scot::Env->new( config_file => $config_file);
my $responder = Scot::Email::Responder::Alert->new(env => $env);

my @alert_rows = (
    { 
        columns     => [
            'foo_status', 'bar_value', 'boom_index'
        ],
        foo_status  => 'false',
        bar_value   => [ 'one', 'two', 'three' ],
        boom_index  => 23,
    },
    { 
        columns     => [
            'foo_status', 'bar_value', 'boom_index'
        ],
        foo_status  => 'true',
        bar_value   => [ 'a', 'b', 'c' ],
        boom_index  => 42,
    },
);

# side effect! $data->{data} is consumed in the create_alertgroup($data) function!
my @adata = @alert_rows;

my $data    = {
    subject     => "Test Alertgroup Mesage 1",
    message_id  => '<adfasdfadsfasdfasdfasdf@splunk.watermelon.com>',
    body_plain  => '',
    body        => '',
    tag         => ['foo', 'bar'],
    source      => [ 'boom', 'baz' ],
    columns     => [ 'foo_status', 'bar_value', 'boom_index' ],
    ahrefs      => [
        {
            link => 'https://splunk.watermelon.con/app/cyber/@go?dispatch=alerts',
            subject => "Alerts that seem Testy",
        }
    ],
    data        =>  \@adata,
};

my $created_count = $responder->create_alertgroup($data);

is($created_count, 1, "Created an Alertgroup");

my $acol  = $env->mongo->collection('Alert');
my $agcol = $env->mongo->collection('Alertgroup');
my $ag    = $agcol->find_one({ subject => $data->{subject}});

ok(defined($ag), "Alertgroup was stored in DB");

my $cursor = $acol->find({alertgroup => $ag->id});
$cursor->sort({id => 1});
my $counter = 0;
while (my $alert = $cursor->next ) {
    my $expected = $alert_rows[$counter];
    # print "expected ".Dumper(\@alert_rows)."\n";
    foreach my $column (@{$data->{columns}}) {
        my $adata = $alert->data->{$column};
        # print "Got adata: ".Dumper($adata);
        my $edata = $expected->{$column};
        # print "\nGot edata: ".Dumper($edata)."\n";
        cmp_deeply( $adata, $edata, "$column was correct");
    }
    $counter++;
}
done_testing();
