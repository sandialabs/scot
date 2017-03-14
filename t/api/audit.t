#!/usr/bin/env perl
use lib '../../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Collection;
use Scot::Collection::Alertgroup;

$ENV{'scot_mode'}           = "testing";
$ENV{'scot_auth_type'}      = "Testing";
$ENV{'scot_logfile'}        = "/var/log/scot/scot.test.log";
$ENV{'scot_config_file'}    = '../../../Scot-Internal-Modules/scot.test.cfg.pl';

print "Resetting test db...\n";
system("mongo scot-testing <../../install/src/mongodb/reset.js 2>&1 > /dev/null");

@defgroups = ( 'ir', 'test' );

my $t = Test::Mojo->new('Scot');
my $env = Scot::Env->instance;


$t->post_ok(
    '/scot/api/v2/alertgroup'   => json => {
        message_id  => '112233445566778899aabbccddeeff',
        subject     => 'test message 1',
        data        => [
            { foo   => 1,   bar => 2 },
            { foo   => 3,   bar => 4 },
        ],
        tag     => [qw(test testing)],
        source  => [qw(todd scot)],
        columns  => [qw(foo bar) ],
    }
)->status_is(200);

my $alertgroup_id   = $t->tx->res->json->{id};

$t->post_ok(
    '/scot/api/v2/entry'    => json => {
        body    => 'test entry',
        target_id   => $alertgroup_id,
        target_type => "alertgroup",
    })
    ->status_is(200);

my $entry_id    = $t->tx->res->json->{id};

$t->put_ok(
    "/scot/api/v2/entry/$entry_id" => json => {
        body    => "updated test entry"
    })
    ->status_is(200);


$t->get_ok("/scot/api/v2/audit" => {},
           "Get audit records " )
  ->status_is(200)
  ->json_is('/records/2/data/id'    => $alertgroup_id)
  ->json_is('/records/2/data/thing' => 'alertgroup')
  ->json_is('/records/2/what'       => 'create_thing');

print Dumper($t->tx->res->json), "\n";
done_testing();
exit 0;

