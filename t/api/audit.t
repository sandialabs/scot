#!/usr/bin/env perl
use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Collection;
use Scot::Collection::Alertgroup;

$ENV{'scot_mode'}   = "testing";
$ENV{'SCOT_AUTH_TYPE'}   = "Testing";
print "Resetting test db...\n";
system("mongo scot-testing <../../etc/database/reset.js 2>&1 > /dev/null");

@defgroups = ( 'ir', 'test' );

my $t = Test::Mojo->new('Scot');
my $env = Scot::Env->instance;
my $amq = $env->amq;
$amq->subscribe("alert", "alert_queue");
$amq->get_message(sub{
    my ($self, $frame) = @_;
    print "AMQ received: ". Dumper($frame). "\n";
});


$t->post_ok(
    '/scot/api/v2/alertgroup'   => json => {
        message_id  => '112233445566778899aabbccddeeff',
        subject     => 'test message 1',
        data        => [
            { foo   => 1,   bar => 2 },
            { foo   => 3,   bar => 4 },
        ],
        tags     => [qw(test testing)],
        sources  => [qw(todd scot)],
        columns  => [qw(foo bar) ],
    }
)->status_is(200);

my $alertgroup_id   = $t->tx->res->json->{id};


$t->get_ok("/scot/api/v2/audit" => {},
           "Get audit records " )
  ->status_is(200)
  ->json_is('/records/0/data/id'    => $alertgroup_id)
  ->json_is('/records/0/data/thing' => 'alertgroup')
  ->json_is('/records/0/what'       => 'create_thing');

#  print Dumper($t->tx->res->json), "\n";
done_testing();
exit 0;

