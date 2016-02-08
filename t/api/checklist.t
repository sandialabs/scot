#!/usr/bin/env perl
use lib '../lib';
use lib '../../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Scot::Collection;
use Scot::Collection::Alertgroup;

$ENV{'scot_mode'}   = "testing";
print "Resetting test db...\n";
system("mongo scot-testing <../../bin/database/reset.js 2>&1 > /dev/null");

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

