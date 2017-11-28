#!/usr/bin/env perl

use lib '../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;

my $t   = Test::Mojo->new('Scot');

$t  ->  post_ok     ( '/scot/event' => json => {
                        subject     => "Test Event for Tasks",
                        source      => 'tasktester',
                        readgroups  => [ qw(ir test) ],
                        modifygroups=> [ qw(ir test) ],
                    })
    ->  status_is   (200)
    ->  json_is     ('/status'  => 'ok');

my $event_id    = $t->tx->res->json->{id};

$t  ->  post_ok     (   '/scot/entry'   => json => {
                            body        => 'Do this, NOW!',
                            owner       => "sbruner",
                            target_id   => $event_id,
                            target_type => "event",
                            is_task     => 1,
                            status      => 'open',
                            readgroups  => [ qw(ir test) ],
                            modifygroups=> [ qw(ir test) ],
                        }
                    )
    ->  status_is   (200)
    ->  json_is     ('/status'  => 'ok');

my $first_entry_id  = $t->tx->res->json->{id};

$t  ->  post_ok     ('/scot/entry'      => json => {
                            body        => 'Do this, Later!',
                            owner       => "aaaqqq",
                            target_id   => $event_id,
                            target_type => "event",
                            is_task     => 1,
                            status      => 'open',
                            readgroups  => [ qw(ir test) ],
                            modifygroups=> [ qw(ir test) ],
                        }
                    )
    ->  status_is   (200)
    ->  json_is     ('/status'  => 'ok');
my $last_entry_id   = $t->tx->res->json->{id};

my $json = Mojo::JSON->new;
my $filter = $json->encode({entry_id => [ $first_entry_id, $last_entry_id ]});
my $url = "/scot/task?filters=$filter";

$t  ->  get_ok      ($url,   "Get Task List" )
    ->  status_is   (200)
    ->  json_is     ('/data/0/body_plaintext' => "Do this, NOW!" )
    ->  json_is     ('/data/1/body_plaintext' => "Do this, Later!");

# print Dumper($t->tx->res);
# done_testing();
# exit 0;

my $tx  =   $t->ua->build_tx(PUT => "/scot/entry/$first_entry_id" => json => {
                status  => "closed" , 
            });


$t  ->post_ok('/scot/entry'    => json => {
    body            => "complete scotng testing",
    target_id       => 1,
    target_type     => "event",
    parent          => 0,
    readgroups      => [qw(ir test)],
    modifygroups    => [qw(ir test)],
    })
    ->status_is(200)
    ->json_is('/status' => 'ok');

my $taskid = $t->tx->res->json->{id};

$tx  = $t->ua->build_tx(PUT => "/scot/entry/$taskid" => json =>{
    cmd         => "maketask",
    assignee    => "foobar",
    taskstatus  => "assigned",
});

$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->get_ok("/scot/entry/$taskid")
    ->status_is(200)
    ->json_is("/data/is_task"       => 1)
    ->json_is("/data/task/who"      => "foobar")
    ->json_is("/data/task/status"   => "assigned");

$tx = $t->ua->build_tx( PUT => "/scot/entry/$taskid" => json => { 
    cmd         => "updatetask",
    assignee    => "roadhouse", # optional, if not set, the browser user is used
    taskstatus  => "closed", # optional , if not set then it is "open"
});
$t  ->request_ok($tx)
    ->status_is(200)
    ->json_is('/status' => 'ok');


$t  ->get_ok("/scot/entry/$taskid")
    ->status_is(200)
    ->json_is("/data/is_task"       => 1)
    ->json_is("/data/task/who"      => "roadhouse")
    ->json_is("/data/task/status"   => "closed");

done_testing();
exit 0;
