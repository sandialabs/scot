#!/usr/bin/env perl

use lib '../lib';
use lib '../../lib';

#use Test::More;
use Data::Dumper;
use JSON;
use Net::STOMP::Client;
use Test::More;
use Test::Mojo;

$ENV{'scot_mode'} = "testing";

# my $flairpid    = `ps -ef | grep flairer.pl | grep -v grep | cut -d ' ' -f 3`;

# if ( $flairpid =~ /\d+/ ) {
#     kill $flairpid;
# }

# system("../../bin/flairer.pl&");
system("mongo scot-testing ../../bin/reset_db.js");

my $t   = Test::Mojo->new('Scot');


# print `ps -ef | grep -i scot`;

$t->post_ok(
    '/scot/api/v2/event'    => json => 
    {
        subject => "Test Event",
        source  => "my mind",
        status  => 'open',
    }
    )->status_is(200);

my $event_id    = $t->tx->res->json->{id};

$t->post_ok("/scot/api/v2/entry" => json => {
    body        => "gooogle.com (notice extra o)  is phishy",
    target_id   => $event_id,
    target_type => "event",
})->status_is(200);

sleep 4;

$t->get_ok("/scot/api/v2/event/$event_id/entry" => {}, 
    "Getting event $event_id entries")->status_is(200)
    ->json_is('/records/0/body_flair'   => '<html><head></head><body><p><span class="entity domain tld" entity-data-type="domain" entity-data-value="gooogle.com">gooogle.com</span> (notice extra o) is phishy</body></html>');

$t->post_ok(
    '/scot/api/v2/alertgroup'   => json => {
        message_id  => '112233445566778899aabbccddeeff',
        subject     => 'Test Flair Alert',
        data        => [
            { ipaddr => "10.1.1.1", domain => "foo.com", email => 'todd@zoo.foo.com' },
#            { ipaddr => "10.1.1.2", domain => "bar.com", email => 'todd@.mail.bar.com' },
#            { ipaddr => "10.1.1.3", domain => "boom.com", email => 'todd@smtp.boom.com' },
        ],
        tags        => [ qw(flair test) ],
        source      => [ qw(foo bar) ],
        columns     => [ qw(ipaddr domain email) ],
    }
)->status_is(200);

my $alertgroup_id   = $t->tx->res->json->{id};

print "Sleeping while awaiting flairing\n";
sleep 6;

$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id/alert" => {},
    "Getting alerts in alertgroup $alertgroup_id")
    ->status_is(200)
    ->json_is('/records/0/data_with_flair/domain' => '<html><head></head><body><p><span class="entity domain tld" entity-data-type="domain" entity-data-value="foo.com">foo.com</span></body></html>');


# print Dumper($t->tx->res->json), "\n";
done_testing();
exit 0;

