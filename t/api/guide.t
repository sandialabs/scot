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
    '/scot/api/v2/guide'   => json => {
        subject     => "Guide to Alert: Foo does Bar",
        data    => {
            applies_to  => ['Splunk Alert: (AJB) zip/rar/7z/jar Hourly Quarantined=False'],
        },
        entry       => [
            {
                body => "Get copy of zip",
            },
            {
                body    => "Extract and Scan",
            },
        ],
    }
)->status_is(200);

my $guide_id        = $t->tx->res->json->{id};
my $updated         = $t->tx->res->json->{updated};

$t->get_ok("/scot/api/v2/guide/$guide_id" => {},
           "Get Guid $guide_id" )
  ->status_is(200)
  ->json_is('/subject'      => 'Guide to Alert: Foo does Bar')
  ->json_is('/data/applies_to/0'  => 'Splunk Alert: (AJB) zip/rar/7z/jar Hourly Quarantined=False');

#  print Dumper($t->tx->res->json), "\n";

$t->get_ok("/scot/api/v2/guide/$guide_id/entry" => {},
    "Getting entries in guide")
    ->status_is(200)
    ->json_is('/totalRecordCount'   => 2)
    ->json_is('/queryRecordCount'   => 2)
    ->json_is('/records/0/body'     => 'Get copy of zip')
    ->json_is('/records/1/body'     => 'Extract and Scan');

done_testing();
exit 0;

