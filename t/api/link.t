#!/usr/bin/env perl
use lib '../../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '../../lib';
use v5.18;

use HTML::Entities;
use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Env;
use Parallel::ForkManager;
use Mojo::JSON qw(decode_json encode_json);
use Scot::App::Flair;

$ENV{'scot_mode'}           = "testing";
$ENV{'scot_auth_type'}      = "Testing";
$ENV{'scot_logfile'}        = "/var/log/scot/scot.test.log";
$ENV{'scot_config_file'}    = '../../../Scot-Internal-Modules/etc/scot.test.cfg.pl';

print "Resetting test db...\n";
system("mongo scot-testing <../../install/src/mongodb/reset.js 2>&1 > /dev/null");

my @defgroups       = ( 'wg-scot-ir', 'testing' );

foreach my $k (keys %ENV) {
    next unless $k =~ /scot/i;
    print "$k = $ENV{$k}\n";
}

my $t       = Test::Mojo->new('Scot');
my $env     = Scot::Env->instance;
my $flairer = Scot::App::Flair->new({env=>$env});

$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Test Event 1",
        source  => ["firetest"],
        status  => 'open',
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event_id = $t->tx->res->json->{id};

$t  ->post_ok('/scot/api/v2/entry'    => json => {
        body        => qq| 
            google.com was providing 10.12.14.16 as the ipaddress
        |,
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        groups      => {
            read    => \@defgroups,
            modify  => \@defgroups,
        },
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry2  = $t->tx->res->json->{id};
$flairer->process_message("created", "entry", $entry2);

$t  ->post_ok('/scot/api/v2/entry'    => json => {
        body        => qq| 
            scotdemo.com is the place to be
        |,
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        groups      => {
            read    => \@defgroups,
            modify  => \@defgroups,
        },
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry3  = $t->tx->res->json->{id};
$flairer->process_message("created", "entry", $entry3);

# set up complete now check links

#my $mongo   = $env->mongo;
#my $linkcol = $mongo->collection('Link');
#my $cursor  = $linkcol->find({value => "10.12.14.16"});
#my @links   = $cursor->all;

$t->get_ok("/scot/api/v2/link")
    ->status_is(200)
    ->json_is('/totalRecordCount'   => 6)
    ->json_is('/records/0/value'    => 'google.com')
    ->json_is('/records/0/target/type'  => "entry")
    ->json_is('/records/0/target/id'    => 1)
    ->json_is('/records/1/value'    => 'google.com')
    ->json_is('/records/1/target/type'  => "event")
    ->json_is('/records/1/target/id'    => 1)
    ->json_is('/records/5/value'    => 'scotdemo.com')
    ->json_is('/records/5/target/type'  => "event")
    ->json_is('/records/5/target/id'    => 1)
    ->json_is('/records/4/value'    => 'scotdemo.com')
    ->json_is('/records/4/target/type'  => "entry")
    ->json_is('/records/4/target/id'    => 2);
    
# say Dumper($t->tx->res->json);
done_testing();
exit 0;


