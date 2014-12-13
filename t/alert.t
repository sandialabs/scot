#!/usr/bin/env perl
use lib '../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;

system("mongo scotng-dev ./reset_alert_db.js");

my $t       = Test::Mojo->new('Scot');
my $json    = Mojo::JSON->new;

# sleep 60;

# JSON 
# get alerts for grid
$t  ->get_ok('/scot/alert')
    ->status_is(200)
    ->json_has('/status' => "no matching permitted records");


# add and alert
$t  ->post_ok(
        '/scot/alert' => json => {
            sources      => ["tests"],
            subject     => "Test Alert Numero Uno",
            data        => {
                    text    => "This is a test of the alert creation",
            },
            readgroups      => [ qw(ir test) ],
            modifygroups    => [ qw(ir test) ],
        }
    )
    ->status_is(200)
    ->json_is('/status' => 'ok');
my $alert1 = $t->tx->res->json->{id};



$t  ->get_ok("/scot/alert/$alert1")
    ->status_is(200)
    ->json_has('/status'    => 'ok');


# print Dumper($t->tx->res), "\n";
# done_testing();
# exit 0;

$t  ->get_ok("/scot/alert/$alert1")
    ->status_is(200)
    ->json_is('/data/viewed_by/scot-test/count'    => 2, 
                "view count incremented");

 #print Dumper($t->tx->res->json), "\n";
 #exit 0;

$t  ->post_ok('/scot/alert' => json => {
       sources   => ["tests"],
       subject  => "Test Alert Numero Dos",
       data     => {text     => "Testing, is not very fun."},
       readgroups => [ qw(ir test) ],
       modifygroups => [ qw(ir test) ],
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $alert2 = $t->tx->res->json->{id};

my $colparam    = $json->encode([qw(alert_id updated)]);

$t  ->get_ok("/scot/alert?columns=$colparam" => {
    }, "Get Alert List" )
    ->status_is(200)
    ->json_is('/data/0/alert_id'    => $alert2)
    ->json_is('/data/1/alert_id'    => $alert1);


my $alertsref   = $t->tx->res->json;
my $updated1    = $alertsref->{data}->[1]->{updated};
my $updated2    = $alertsref->{data}->[0]->{updated};

print "Alert 1 updated at $updated1\n";
print "Alert 2 updated at $updated2\n";



sleep 1;

my $tx = $t->ua->build_tx(PUT => "/scot/alert/$alert2" => json =>{
       sources   => ["new tests"],
       subject  => "Test Alert Numero Dos (updated)",
    });
$t  ->request_ok($tx, "update alert $alert2")
    ->status_is(200)
    ->json_is('/status' => 'ok');


# print Dumper($t->tx->res->json), "\n";
# done_testing();
# exit 0;

$t  ->get_ok("/scot/alert/$alert2")
    ->status_is(200)
    ->json_is('/data/sources/0'    => "new tests")
    ->json_is('/data/subject'   => "Test Alert Numero Dos (updated)")
    ->json_is('/data/data/text'      => "Testing, is not very fun.");

isnt $t->tx->res->json->{updated}, $updated2, "update time changed";

$tx = $t->ua->build_tx(PUT => "/scot/alert/$alert2" => json => { cmd => "upvote", });
$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->get_ok("/scot/alert/$alert2")
    ->status_is(200)
    ->json_has('/data/upvotes/0', "upvote registered");

$tx = $t->ua->build_tx(PUT => "/scot/alert/$alert2" => json =>{
    cmd => "downvote", });
$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');


$tx = $t->ua->build_tx(
    PUT     => "/scot/alert/$alert2" => 
    json    => {
        cmd     => "addtag", 
        tags    => [qw(bar boom baz foo)]
    }
);

$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');

#  print Dumper($t->tx->res->json);
#  exit 0;

$t  ->get_ok("/scot/alert/$alert2")
    ->status_is(200)
    ->json_has('/data/downvotes/0', "downvote registered")
    ->json_is ('/data/tags' => [qw(bar baz boom foo )], "tags correct");


$tx = $t->ua->build_tx(PUT => "/scot/alert/$alert2" => json =>{
    cmd => "rmtag", tags =>[qw(boom baz)]});
$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->get_ok("/scot/alert/$alert2")
    ->status_is(200)
    ->json_is ('/data/tags' => [qw(bar foo)], "tags correct");
#   print Dumper($t->tx->res->json), "\n";

$t  ->delete_ok("/scot/alert/$alert1"   => {} => "Alert Deletion")
    ->status_is(200)
    ->json_is('/status' => 'ok');

#$t  ->get_ok('/scot/alert' => {
#        columns => [
#            qw(alert_id status updated created subject tags views entries)
#        ]} => "Get Alert List with Selected Columns")
#    ->status_is(200);

$colparam    = $json->encode([qw(alert_id status updated created subject tags views entries)]);
my $clist = "?columns=" . $colparam;
$t  ->get_ok("/scot/alert".$clist, "Get alerts with selected columns")
    ->status_is(200);

$t  ->post_ok('/scot/alert' => json => {
       sources   => ["todd"],
       subject  => "More Testing F-yeah",
       data     => {text     => "Testing, is not very fun."},
       readgroups => [ qw(ir test) ],
       modifygroups => [ qw(ir test) ],
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');
my $alert3 = $t->tx->res->json->{id};

$t  ->post_ok('/scot/alert' => json => {
       source   => ["todd"],
       subject  => "More Testing 2 F-yeah",
       data     => {text     => "Testing, is not very fun."},
       readgroups => [ qw(ir test) ],
       modifygroups => [ qw(ir test) ],
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $alert4 = $t->tx->res->json->{id};

$t  ->post_ok('/scot/alert' => json => {
       sources   => ["todd"],
       subject  => "More Testing 3 F-yeah",
       data     => {text     => "Testing, is not very fun."},
       readgroups => [ qw(ir test) ],
       modifygroups => [ qw(ir test) ],
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');
my $alert5 = $t->tx->res->json->{id};

$tx = $t->ua->build_tx(PUT => "/scot/alert/$alert3" => json =>{
    cmd => "addtag", tags =>[qw(foo bar boom baz)]});
$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');

# XXX
#  print Dumper($t->tx->res), "\n";
#  done_testing();
#  exit 0;


$colparam    = $json->encode([qw(alert_id subject sources views entries tags)]);
$clist = '?columns=' . $colparam;
$t  ->get_ok("/scot/alert".$clist."&sources=todd", 
             "Get alerts with computed columns")
    ->status_is(200)
    ->json_is('/data/0/alert_id'    => 5)
    ->json_is('/data/1/alert_id'    => 4)
    ->json_is('/data/2/alert_id'    => 3)
    ->json_is('/data/0/sources/0'      => 'todd');


my $cols    = $json->encode([ qw(alert_id subject_tags) ]);
my $jfilter = $json->encode({ tags => [ qw(foo) ] });
my $gfilter = $json->encode({ sort => { alert_id => 1 }});
my $url     =   "/scot/alert?" .
                "&columns=$cols".
                "&filter=$jfilter".
                "&grid=$gfilter";

print "url is ".$url."\n";

$t  ->get_ok( $url, "Get alerts with computed columns")
    ->status_is(200)
    ->json_is('/data/0/alert_id'    => $alert3)
    ->json_is('/data/0/tags'        => [qw(bar baz boom foo)])
    ->json_is('/data/1/alert_id'    => $alert2)
    ->json_is('/data/1/tags'        => [qw(bar foo )]);

   $jfilter = $json->encode({ tags => [ qw(foo baz) ] });
   my $cols = $json->encode([qw(alert_id subject tags)]);
   $url     = "/scot/alert?columns=$cols&filter=$jfilter&grid=$gfilter";

$t  ->get_ok( $url, "Get alerts with computed columns")
    ->status_is(200)
    ->json_is('/data/0/alert_id' => 3)
    ->json_is('/data/0/tags' => [qw(bar baz boom foo )]);


   $url     = "/scot/alert/$alert2?columns=";
   $json    = Mojo::JSON->new;
   $jfilter = $json->encode([ qw(updated subject) ] );
   $url     = $url . "$jfilter";

$t  ->get_ok( $url, "Get alert with only  selected columns")
    ->status_is(200)
    ->json_hasnt('/data/data')
    ->json_has('/data/updated' )
    ->json_has('/data/subject' );






   $url     = "/scot/alert/$alert2?columns=";
   $json    = Mojo::JSON->new;
   $jfilter = $json->encode([ qw(-data) ] );
   $url     = $url . "$jfilter";

$t  ->get_ok( $url, "Get alert with only  selected fields")
    ->status_is(200)
    ->json_hasnt('/data/data');
# print Dumper($t->tx->res->json), "\n";

$t  ->get_ok('/scot/alert')
    ->status_is(200);


$t  ->post_ok(
        '/scot/alert' => json => {
            sources      => ["tests"],
            subject     => "Test Alert With Entity Goodness",
            data        => {
                    text    => "what is newcmd.exe?  is heartofpole.net a good source? ok I brought it to 134.253.14.12",
            },
            readgroups      => [ qw(ir test) ],
            modifygroups    => [ qw(ir test) ],
        }
    )
    ->status_is(200)
    ->json_is('/status' => 'ok');
my $alert_with_entity = $t->tx->res->json->{id};

$t  ->get_ok("/scot/alert/$alert_with_entity")
    ->status_is(200)
    ->json_has('/data/flairdata')
    ->json_is('/data/flairdata/heartofpole.net/alerts_count' =>  1 );


  # debug
  print Dumper($t->tx->res->json), "\n";
  done_testing();
  exit 0;
