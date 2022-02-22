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

$env->log->info("BEFORE EMLAT");

my $alert_id = 1;
$t->put_ok("/scot/api/v2/emlat" => json => {
    alert_id    => $alert_id,
    emlat_score => 0.44
})->status_is(200);

$t->get_ok("/scot/api/v2/alert/$alert_id")
  ->status_is(200)
  ->json_is('/data/emlat_score' => 0.44)
  ->json_is('/data_with_flair/emlat_score' => 0.44)
  ->json_is('/columns'      => [qw(emlat_score foo bar data)])
  ->json_is('/data/columns/0' => 'emlat_score')
  ->json_is('/data_with_flair/columns/0' => 'emlat_score');

# print Dumper($t->tx->res->json);


done_testing();
exit 0;


