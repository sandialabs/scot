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
$ENV{'scot_config_paths'}   = '../../../Scot-Internal-Modules/etc';
$ENV{'scot_config_file'}    = '../../../Scot-Internal-Modules/etc/scot.test.cfg.pl';

print "Resetting test db...\n";
system("mongo scot-testing <../../install/src/mongodb/reset.js 2>&1 > /dev/null");

my $t = Test::Mojo->new('Scot');
my $env = Scot::Env->instance;


$t->post_ok(
    '/scot/api/v2/checklist'   => json => {
        subject     => "Spear Phishing Checklist",
        description => "Set of Tasks to perform when working a Spear Phish",
        entry       => [
            {
                body => "SpearPhish Task 1",
            },
            {
                body    => "SpearPhish Task 2",
            },
        ],
    }
)->status_is(200);

my $checklist_id    = $t->tx->res->json->{id};
my $updated         = $t->tx->res->json->{updated};


$t->get_ok("/scot/api/v2/checklist/$checklist_id" => {},
           "Get Checklist $checklist_id" )
  ->status_is(200)
  ->json_is('/subject'      => 'Spear Phishing Checklist')
  ->json_is('/description'  => 'Set of Tasks to perform when working a Spear Phish');


$t->get_ok("/scot/api/v2/checklist/$checklist_id/entry" => {},
    "Getting entries in checklist")
    ->status_is(200)
    ->json_is('/totalRecordCount'   => 2)
    ->json_is('/queryRecordCount'   => 2)
    ->json_is('/records/0/body'     => 'SpearPhish Task 1')
    ->json_is('/records/1/body'     => 'SpearPhish Task 2');

# print Dumper($t->tx->res->json), "\n";
done_testing();
exit 0;

