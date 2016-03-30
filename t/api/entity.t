#!/usr/bin/env perl
use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Env;
use Scot::Util::EntityExtractor;
use Parallel::ForkManager;
use Mojo::JSON qw(decode_json encode_json);

$ENV{'scot_mode'}   = "testing";
$ENV{'SCOT_AUTH_TYPE'}   = "Testing";
print "Resetting test db...\n";
system("mongo scot-testing <../../etc/database/reset.js 2>&1 > /dev/null");

# fork and run Scot::App::Flair

my @defgroups       = ( 'wg-scot-ir', 'testing' );

my $t   = Test::Mojo->new('Scot');
my $env = Scot::Env->instance;

my $ee  = Scot::Util::EntityExtractor->new({
    log => $env->log,
});

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
        readgroups  => $defgroups,
        modifygroups => $defgroups,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry2  = $t->tx->res->json->{id};

$t  ->get_ok("/scot/api/v2/entry/$entry2")
    ->status_is(200);

my $entrydata = $t->tx->res->json;

### put entity enrich
my $eehref = $ee->process_html($entrydata->{body});
my $json   = {
    parsed  => 1,
    body_plain  => $eehref->{text},
    body_flair  => $eehref->{flair},
    entities    => $eehref->{entities},
};

$t  ->put_ok("/scot/api/v2/entry/$entry2" => json => $json)
    ->status_is(200);

$t  ->get_ok("/scot/api/v2/event/$event_id/entity")
    ->status_is(200)
    ->json_is('/totalRecordCount' => 2)
    ->json_is('/records/google.com/type'   => 'domain')
    ->json_is('/records/10.12.14.16/type'   => 'ipaddr');

my $googleid = $t->tx->res->json->{records}->{'google.com'}->{id};
my $ipid     = $t->tx->res->json->{records}->{'10.12.14.16'}->{id};

$t  ->get_ok("/scot/api/v2/entity/$googleid/event")
    ->status_is(200)
    ->json_is('/records/0/id'       => 1)
    ->json_is('/records/0/subject'  => 'Test Event 1');
    
$t  ->get_ok("/scot/api/v2/entity/$ipid/event")
    ->status_is(200)
    ->json_is('/records/0/id'       => 1)
    ->json_is('/records/0/subject'  => 'Test Event 1');


 print Dumper($t->tx->res->json);
 done_testing();
 exit 0;



