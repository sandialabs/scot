#!/usr/bin/env perl
use lib '../../../Scot-Internal-Modules/lib';
use lib '../lib';
use lib '../../lib';
use strict;
use warnings;
use v5.18;

use HTML::Entities;
use Test::More;
use Test::Mojo;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use Parallel::ForkManager;
use Mojo::JSON qw(decode_json encode_json);
use Scot::App::Responder::Flair;

$ENV{'scot_mode'}           = "testing";
$ENV{'scot_auth_type'}      = "Testing";
$ENV{'scot_logfile'}        = "/var/log/scot/scot.test.log";
$ENV{'scot_config_file'}    = '../../../Scot-Internal-Modules/etc/scot.test.cfg.pl';

print "Resetting test db...\n";
system("mongo scot-testing <../../install/src/mongodb/reset.js 2>&1 > /dev/null");

my @defgroups       = ( 'wg-scot-ir', 'testing' );

foreach my $k (keys %ENV) {
    next unless $k =~ /scot/i;
    print "$k = $ENV{$k}\n";
}

my $t       = Test::Mojo->new('Scot');
my $env     = Scot::Env->instance;
my $flairer = Scot::App::Responder::Flair->new({env=>$env});

$t  ->post_ok  ('/scot/api/v2/event'  => json => {
        subject => "Test Event 1",
        source  => ["firetest"],
        status  => 'open',
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $event_id = $t->tx->res->json->{id};

$t  ->post_ok('/scot/api/v2/entry'    => json => {
        body        => qq| 
            google.com was providing 10.12.14.16 as the ipaddress
        |,
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        groups      => {
            read    => \@defgroups,
            modify  => \@defgroups,
        },
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry2  = $t->tx->res->json->{id};
$flairer->process_message(undef, {
    action  => "created", 
    data    => {
        type    => "entry", 
        id      => $entry2
    }
});

$t  ->post_ok('/scot/api/v2/entry'    => json => {
        body        => qq| 
            scotdemo.com is the place to be
        |,
        target_id   => $event_id,
        target_type => "event",
        parent      => 0,
        groups      => {
            read    => \@defgroups,
            modify  => \@defgroups,
        },
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $entry3  = $t->tx->res->json->{id};
$flairer->process_message(undef, {
    action  => "created", 
    data    => {
        type    => "entry", 
        id      => $entry3
    }
});

# set up complete now check links

#my $mongo   = $env->mongo;
#my $linkcol = $mongo->collection('Link');
#my $cursor  = $linkcol->find({value => "10.12.14.16"});
#my @links   = $cursor->all;

my @okvertices = (
    [ {id => 1, type => "entity"}, {id=>1, type=>"entry"} ],
    [ {id => 1, type => "entity"}, {id=>1, type=>"event"} ],
    [ {id => 2, type => "entity"}, {id=>1, type=>"entry"} ],
    [ {id => 2, type => "entity"}, {id=>1, type=>"event"} ],
    [ {id => 3, type => "entity"}, {id=>2, type=>"entry"} ],
    [ {id => 3, type => "entity"}, {id=>1, type=>"event"} ],
);


$t->get_ok("/scot/api/v2/link")
    ->status_is(200)
    ->json_is('/totalRecordCount'   => 6);

my $rec_aref = $t->tx->res->json->{records};
my @gotvertices = map { $_->{vertices} } @{$rec_aref};

cmp_deeply(\@okvertices, \@gotvertices, "Got correct links");
    
# more test of linking arbitrary things

$t->post_ok('/scot/api/v2/alertgroup' => json => {
    message_id  => '123456789abcdef1234566789abcdef',
    subject     => 'link test 1',
    data        => [
        { foo => 1, bar => 2 },
        { foo => 2, bar => 3 },
    ],
    tag => [ qw(test) ],
    source => [ qw(test) ],
    columns => [ qw(foo bar) ],
})->status_is(200);

my $agid    = $t->tx->res->json->{id};

$t->post_ok(
    '/scot/api/v2/guide'   => json => {
        subject     => "Guide to Alert: Foo does Bar",
        applies_to  => ['link test 1'],
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

my $guideid = $t->tx->res->json->{id};

my @linkedvertices = (
    { id => $agid,      type => "alertgroup" },
    { id => $guideid,   type => "guide" },
);

$t->post_ok(
    '/scot/api/v2/link' => json => {
        weight      => 2,
        vertices    => \@linkedvertices,
        context     => "because I said so",
    })->status_is(200);

my $linkid = $t->tx->res->json->{id};

$t->get_ok("/scot/api/v2/link/$linkid")
  ->status_is(200);

@gotvertices = $t->tx->res->json->{vertices};

cmp_deeply(\@linkedvertices, @gotvertices, "link created correctly");

#$t->get_ok("/scot/api/v2/alertgroup/$agid/link")
#  ->status_is(200);


 say Dumper($t->tx->res->json);
done_testing();
exit 0;


