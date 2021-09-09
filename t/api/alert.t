#!/usr/bin/env perl
use lib '../../../Scot-Internal-Modules/lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Collection;
use Scot::Collection::Alertgroup;
use Mojo::JSON qw(encode_json decode_json);
use Scot::Flair::Worker;

$ENV{'scot_mode'}           = "testing";
$ENV{'scot_auth_type'}      = "Testing";
$ENV{'scot_logfile'}        = "/var/log/scot/scot.test.log";
$ENV{'scot_config_file'}    = '../../../Scot-Internal-Modules/etc/scot.test.cfg.pl';

print "Resetting test db...\n";
system("mongo scot-testing <../../install/src/mongodb/reset.js 2>&1 > /dev/null");

@defgroups = ( 'ir', 'test' );

foreach my $k (keys %ENV) {
    next unless $k =~ /scot/;
    print "$k = $ENV{$k}\n";
}

my $t = Test::Mojo->new('Scot');
my $env = Scot::Env->instance;
#my $amq = $env->amq;
#$amq->subscribe("alert", "alert_queue");
#$amq->get_message(sub{
#    my ($self, $frame) = @_;
#    print "AMQ received: ". Dumper($frame). "\n";
#});

# use this to set csrf protection 
# though not really used due to testing auth 

my $flairer = Scot::Flair::Worker->new(env => $env);

$t->ua->on(start => sub {
    my ($ua, $tx) = @_;
    $tx->req->headers->header('X-Requested-With' => 'XMLHttpRequest');
});


$t->post_ok(
    '/scot/api/v2/alertgroup'   => json => {
        message_id  => '112233445566778899aabbccddeeff',
        subject     => 'test message 1',
        data        => [
            { foo   => 1,   bar => 2, data => "10.10.10.1" },
            { foo   => 3,   bar => 4, data => "10.10.10.2"},
            { foo   => 5,   bar => 6, data => "10.10.10.3"},
            { foo   => 7,   bar => 8, data => "10.10.10.4"},
        ],
        tag     => [qw(test testing)],
        source  => [qw(todd scot)],
        columns  => [qw(foo bar data) ],
    }
)->status_is(200);

my $alertgroup_id   = $t->tx->res->json->{id};
my $updated         = $t->tx->res->json->{updated};
$flairer->process_message({
    body => {
        action  => "created",
        data    => {
            type    => "alertgroup",
            id      => $alertgroup_id
        }
    }
});

$t->get_ok("/scot/api/v2/alertgroup" => {},
    "Get alertgroup by list")
    ->status_is(200);
# print Dumper($t->tx->res->json), "\n";

$t->get_ok("/scot/api/v2/alert?withsubject=1" => {},
    "Get alert list")
    ->status_is(200)
    ->json_is('/records/0/subject'  => 'test message 1')
    ->json_is('/records/3/subject'  => 'test message 1');
    
#  print Dumper($t->tx->res->json), "\n";

$t->get_ok("/scot/api/v2/alert?id=1&withsubject=1" => {},
    "Get alert list")
    ->status_is(200)
    ->json_is('/records/0/subject'  => 'test message 1');

# try to add a new alert to alertgroup

$t->post_ok(
    '/scot/api/v2/alert'    => json => {
        alertgroup  => $alertgroup_id,
        columns     => [qw(foo bar data)],
        data        => {
            foo => 10, bar => 10, data => "4.4.4.4"
        },
    }
)->status_is(200);
my $alert_id    = $t->tx->res->json->{id};
$flairer->process_message({
    body => {
        action  => "updated",
        data    => {
            type    => "alertgroup",
            id      => $alertgroup_id
        }
    }
});

$t->get_ok("/scot/api/v2/alert/$alert_id");
# print Dumper($t->tx->res->json), "\n";

$t->get_ok("/scot/api/v2/alertgroup/$alertgroup_id/alert" => {},
    "Get alertgroup by list")
    ->status_is(200);
print Dumper($t->tx->res->json), "\n";

done_testing();
exit 0;

