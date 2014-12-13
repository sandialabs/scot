#!/usr/bin/env perl
use lib '../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;

# system("mongo scotng-test ./reset_entry_db.js");

my $t = Test::Mojo->new('Scot');

my $defgroups   = [ 'ir', 'test' ];

my $testsub = "Test Event for Entry with Entities";
$t  ->post_ok('/scot/event' => json => {
                subject         => $testsub,
                source          => 'realdata',
                readgroups     => $defgroups,
                modifygroups    => $defgroups,
            })
    ->status_is(200)
    ->json_is('/status' => 'ok');
my $event_id    = $t->tx->res->json->{id};

my $text    = q|<p>Searched Splunk logs for last 30 days for the domains listed in the Tipper. Found 681 matching events for hmelin(dot)org for the past 30 days. The DNS name is thought to be a used for C2. Many are dns logs but there are a few realted to e-mails sent to rcool@scot.org and jblow@scot.org. Subject is &quot;Re: <a href='opensuse-security'>1</a> SuSEfirewall2 and opening high ports&quot; <br /></p>\n<p>Also, I am seeing several GET requests to lxtreme.hmelin.org and moksha.hmelin.org and hrnga.hmelin.org</p>\n|;

$t  ->post_ok('/scot/entry' => json => {
        body            => $text,
        target_id       => $event_id,
        target_type     => "event",
        readgroups     => $defgroups,
        modifygroups    => $defgroups,
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');
my $entry_id    = $t->tx->res->json->{id};

my $json    = Mojo::JSON->new;
my $filter  = $json->encode({ 
    entity_type     => "domain", 
    entity_value    => ["hrnga.hmelin.org"],
});
my $url     = "/scot/entity?match=$filter";

$t  ->get_ok($url,
    "get entry list")
    ->status_is(200)
    ->json_has('/status' => "ok")
    ->json_has('/data/0/value'    => "hrnga.hmelin.org")
    ->json_has('/data/0/notes/scot-test' => "This is CRAZY!");

#   print Dumper($t->tx->res);
#   exit 0;

$tx = $t->ua->build_tx(
    PUT     => "/scot/entity" =>
    json    => {
        entity_value    => "hrnga.hmelin.org",
        note            => "This is CRAZY!",
    }
);

$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->get_ok($url,
    "get entity info")
    ->status_is(200)
    ->json_has('/status' => 'ok')
    ->json_is("/data/0/notes/scot-test" => "This is CRAZY!");
print Dumper($t->tx->res->json->{data});

# my $entity_id   = $t->tx->res->json->{data}->


done_testing();
exit 0;
