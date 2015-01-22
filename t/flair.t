#!/usr/bin/env perl
use lib '../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;

my $defgroups   = [ qw(ir test) ];
my $t           = Test::Mojo->new('Scot');

# create an test event to attach entries to
$t      ->post_ok(
    '/scot/event'   => json => {
        subject     => "Flair Test Event",
        source      => 'tbrain',
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
    }
)       ->status_is(200)
        ->json_is('/status' => 'ok');

my $event_id    = $t->tx->res->json->{id};

$t      ->post_ok(
    "/scot/entry"   => json => {
        body        => "The IPAddr is 1.1.1.1 and 2.3.4.5",
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
    }
)       ->status_is(200)
        ->json_is('/status' => 'ok');

my $entry_1         = $t->tx->res->json->{id};

$t      ->post_ok(
    "/scot/entry"   => json => {
        body        => 'The email is scot.ir@gmail.com',
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
    }
)       ->status_is(200)
        ->json_is('/status' => 'ok');

my $entry_2         = $t->tx->res->json->{id};

$t      ->post_ok(
    "/scot/entry"   => json => {
        body        => 'The MD5 is 1234567890abcdef1234567890abcdef',
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
    }
)       ->status_is(200)
        ->json_is('/status' => 'ok');

my $entry_3         = $t->tx->res->json->{id};

$t      ->post_ok(
    "/scot/entry"   => json => {
        body        => 'The SHA1 is 1234567890abcdef1234567890abcdef12345678',
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
    }
)       ->status_is(200)
        ->json_is('/status' => 'ok');

my $entry_4         = $t->tx->res->json->{id};

$t      ->post_ok(
    "/scot/entry"   => json => {
        body        => 'The URL is http://foo.bar.com',
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
    }
)       ->status_is(200)
        ->json_is('/status' => 'ok');

my $entry_5         = $t->tx->res->json->{id};

$t      ->post_ok(
    "/scot/entry"   => json => {
        body        => 'The FILE is <a href="/scot/files/232342342342342342342342">foofile.txt</a>',
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
    }
)       ->status_is(200)
        ->json_is('/status' => 'ok');

my $entry_6         = $t->tx->res->json->{id};

$t      ->post_ok(
    "/scot/entry"   => json => {
        body        => 'Does mail.google.com work right?',
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
    }
)       ->status_is(200)
        ->json_is('/status' => 'ok');

my $entry_7         = $t->tx->res->json->{id};

$t      ->post_ok(
    "/scot/entry"   => json => {
        body        => 'what about domains like mail[.]google[.]com',
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
    }
)       ->status_is(200)
        ->json_is('/status' => 'ok');

my $entry_8         = $t->tx->res->json->{id};

my $body    = q|this is a torture test for 10.1.1.1.  A user sbruner@scot.org did this!  I don't know about osito.org though, because https://random.osito.org looks fine. 74.125.239.128|;

$t      ->post_ok(
    "/scot/entry"   => json => {
        body        => $body,
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
    }
)       ->status_is(200)
        ->json_is('/status' => 'ok');

my $entry_9         = $t->tx->res->json->{id};

# system('../bin/extract_entities.pl');


#my $entry_1_html    = q|The IPAddr is <span data-entity-value="1.1.1.1" data-entity-type="ipaddr" class="entity ipaddr">1.1.1.1</span> and <span data-entity-value="2.3.4.5" data-entity-type="ipaddr" class="entity ipaddr">2.3.4.5</span>|;
my $entry_1_html    = q|<html><head></head><body><p>The IPAddr is <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="1.1.1.1">1.1.1.1</span> and <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="2.3.4.5">2.3.4.5</span></body></html>|;

$t      ->get_ok("/scot/entry/$entry_1")
        ->status_is(200)
        ->json_is("/data/body_flaired" => $entry_1_html);


# my $entry_2_html    = q|The email is <span data-entity-value="scot.ir@gmail.com" data-entity-type="email" class="entity email">scot.ir@<span data-entity-value="gmail.com" data-entity-type="domain" class="entity domain">gmail.com</span></span>|;
my $entry_2_html    = q|<html><head></head><body><p>The email is <span class="entity email" data-entity-type="email" data-entity-value="scot.ir@gmail.com"><span class="entity emailuser" data-entity-type="emailuser" data-entity-value="scot.ir">scot.ir</span>@<span class="entity domain" data-entity-type="domain" data-entity-value="gmail.com">gmail.com</span></span></body></html>|;

# print Dumper($t->tx->res->json);
# exit 0;

$t      ->get_ok("/scot/entry/$entry_2")
        ->status_is(200)
        ->json_is("/data/body_flaired" => $entry_2_html);

# my $entry_3_html    = q|The MD5 is <span data-entity-value="1234567890abcdef1234567890abcdef" data-entity-type="md5" class="entity md5">1234567890abcdef1234567890abcdef</span>|;
my $entry_3_html    = q|<html><head></head><body><p>The MD5 is <span class="entity md5" data-entity-type="md5" data-entity-value="1234567890abcdef1234567890abcdef">1234567890abcdef1234567890abcdef</span></body></html>|;

$t      ->get_ok("/scot/entry/$entry_3")
        ->status_is(200)
        ->json_is("/data/body_flaired" => $entry_3_html);

# my $entry_4_html    = q|The SHA1 is <span data-entity-value="1234567890abcdef1234567890abcdef12345678" data-entity-type="sha1" class="entity sha1">1234567890abcdef1234567890abcdef12345678</span>|;
my $entry_4_html    = q|<html><head></head><body><p>The SHA1 is <span class="entity sha1" data-entity-type="sha1" data-entity-value="1234567890abcdef1234567890abcdef12345678">1234567890abcdef1234567890abcdef12345678</span></body></html>|;

$t      ->get_ok("/scot/entry/$entry_4")
        ->status_is(200)
        ->json_is("/data/body_flaired" => $entry_4_html);

# my $entry_5_html    = q|The URL is http://<span data-entity-value="foo.bar.com" data-entity-type="domain" class="entity domain">foo.bar.com</span>|;
my $entry_5_html    = q|<html><head></head><body><p>The URL is http://<span class="entity domain" data-entity-type="domain" data-entity-value="foo.bar.com">foo.<span class="entity domain" data-entity-type="domain" data-entity-value="bar.com">bar.com</span></span></body></html>|;

$t      ->get_ok("/scot/entry/$entry_5")
        ->status_is(200)
        ->json_is("/data/body_flaired" => $entry_5_html);

# my $entry_7_html    = q|Does <span data-entity-value="mail.google.com" data-entity-type="domain" class="entity domain">mail.google.com</span> work right?|;
my $entry_7_html    = q|<html><head></head><body><p>Does <span class="entity domain" data-entity-type="domain" data-entity-value="mail.google.com">mail.<span class="entity domain" data-entity-type="domain" data-entity-value="google.com">google.com</span></span> work right?</body></html>|;

$t      ->get_ok("/scot/entry/$entry_7")
        ->status_is(200)
        ->json_is("/data/body_flaired" => $entry_7_html);

# my $entry_8_html    = q|what about domains like <span data-entity-value="mail[.]google[.]com" data-entity-type="domain" class="entity domain">mail[.]google[.]com</span>|;
my $entry_8_html    = q|<html><head></head><body><p>what about domains like mail[.]google[.]com</body></html>|;

$t      ->get_ok("/scot/entry/$entry_8")
        ->status_is(200)
        ->json_is("/data/body_flaired" => $entry_8_html);

# my $entry_9_html    = q|this is a torture test for <span data-entity-value="10.1.1.1" data-entity-type="ipaddr" class="entity ipaddr">10.1.1.1</span>.  A user <span data-entity-value="sbruner@scot.org" data-entity-type="email" class="entity email">sbruner@<span data-entity-value="scot.org" data-entity-type="domain" class="entity domain">scot.org</span></span> did this!  I don't know about <span data-entity-value="osito.org" data-entity-type="domain" class="entity domain">osito.org</span> though, because https://<span></span><span data-entity-value="osito.org" data-entity-type="domain" class="entity domain"><span data-entity-value="random.osito.org" data-entity-type="domain" class="entity domain">random.osito.org</span></span> looks fine.|;
my $entry_9_html    = q|<html><head></head><body><p>this is a torture test for 10.1.1.1. A user <span class="entity email" data-entity-type="email" data-entity-value="sbruner@scot.org"><span class="entity emailuser" data-entity-type="emailuser" data-entity-value="sbruner">sbruner</span>@<span class="entity domain" data-entity-type="domain" data-entity-value="scot.org">scot.org</span></span> did this! I don&#39;t know about <span class="entity domain" data-entity-type="domain" data-entity-value="osito.org">osito.org</span> though, because https://<span class="entity domain" data-entity-type="domain" data-entity-value="random.osito.org">random.<span class="entity domain" data-entity-type="domain" data-entity-value="osito.org">osito.org</span></span> looks fine. <span class="entity ipaddr" data-entity-type="ipaddr" data-entity-value="74.125.239.128">74.125.239.128</span></body></html>|;

$t      ->get_ok("/scot/entry/$entry_9")
        ->status_is(200)
        ->json_is("/data/body_flaired" => $entry_9_html);

#   print Dumper($t->tx->res->json); done_testing(); exit 0;

$t      ->get_ok("/scot/event/$event_id")
        ->status_is(200)
        ->json_is("/status" => "ok")
        ->json_is("/data/flairdata/74.125.239.128/geo_data/city" => "Mountain View");

#print Dumper($t->tx->res->json->{data}->{flairdata}->{'74.125.239.128'});
#done_testing();
#exit 0;

my $body    = q|this file foo.bar is cool.  foo.exe is not|;
$t      ->post_ok(
    "/scot/entry"   => json => {
        body        => $body,
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        readgroups  => $defgroups,
        modifygroups=> $defgroups,
    }
)       ->status_is(200)
        ->json_is('/status' => 'ok');

my $entry_10        = $t->tx->res->json->{id};
my $entry_10_html   = q|<html><head></head><body><p>this file <span class="entity domain" data-entity-type="domain" data-entity-value="foo.bar">foo.bar</span> is cool. <span class="entity file" data-entity-type="file" data-entity-value="foo.exe">foo.exe</span> is not</body></html>|;
$t      ->get_ok("/scot/entry/$entry_10")
        ->status_is(200)
        ->json_is("/data/body_flaired" => $entry_10_html);

done_testing();
exit 0;
