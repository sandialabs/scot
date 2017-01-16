#!/usr/bin/env perl
use lib '../lib';

use Test::More;
use Test::Mojo;
use Data::Dumper;

#system('mongo scotng-test ./reset_file_db.js');

my $t   = Test::Mojo->new('Scot');

$t  ->get_ok('/scot/guide')
    ->status_is(200)
    ->json_has('/status' => 'no matching permitted records');

$t  ->post_ok('/scot/guide'   => 
                json => {
                    guide      => "test alert type 1",
                    readgroups      => [ qw(ir test) ],
                    modifygroups    => [ qw(ir test) ],
                }
    )
    ->status_is(200)
    ->json_is('/status'=>'ok');

my $alerttypeid = $t->tx->res->json->{id} + 0;

$t  ->post_ok('/scot/entry'   => 
        json    => {
            body        => "Do this, this, and this",
            target_id   => $alerttypeid,
            target_type => "guide",
            readgroups  => [ qw(ir test) ],
            modifygroups    => [ qw(ir test) ],
        }
    )
    ->status_is(200)
    ->json_is('/status' => 'ok');

$t  ->get_ok("/scot/guide/$alerttypeid")
    ->status_is(200)
    ->json_is('/data/entries/0/body_plaintext' => 'Do this, this, and this');


done_testing();
exit 0;

