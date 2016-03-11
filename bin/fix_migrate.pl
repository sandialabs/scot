#!/usr/bin/perl

use lib '../lib';
use strict;
use warnings;
use v5.18;
use Scot::Env;
use MongoDB;
use Meerkat;
use Meerkat::Cursor;
use Data::Dumper;
use Scot::Model::Link;

my $env = Scot::Env->new({
    logfile => "/var/log/scot/migration_fix.log",
    mode    => 'prod',
});


my $dryrun  = $ARGV[0];

my $mongo   = $env->mongo;
my $log     = $env->log;

# $log->debug("Starting ",{filter=>\&Dumper, value=>$mongo});

my $entity_col  = $mongo->collection('Entity');
my $entry_col   = $mongo->collection('Entry');
my $link_col    = $mongo->collection('Link');

my $cursor  = $link_col->find({
    '$or'   => [
        { target_type => "entry",  item_type   => "entity", },
        { target_type => "entity", item_type   => "entry", },
    ]
});
# my $cursor  = $link_col->find({});
# say Dumper($cursor);
unless ( $cursor ) {
    die "nothing matching!";
}

$cursor->immortal(1);
my $total   = $cursor->count();

say "--- Found $total Entity/Entry Links to Examine ----";

while ( my $link = $cursor->next ) {

    my $entry_id;
    my $entity_id;
    my $when    = $link->{when};

    # say Dumper($link->as_hash);

    if ( $link->{target_type} eq "entry" ) {
        $entry_id   = $link->{target_id};
        $entity_id  = $link->{item_id};
    }
    if ( $link->{item_type} eq "entry" ) {
        $entry_id   = $link->{item_id};
        $entity_id  = $link->{target_id};
    }

    say "Entity $entity_id is linked to Entry $entry_id";

    my $lcur = $link_col->find({
        '$or'   => [
            {
                target_type => "entry",
                target_id   => $entry_id,
                item_type   => { '$in' => [ 'event', 'incident' ] },
            },
            {
                item_type => "entry",
                item_id   => $entry_id,
                target_type   => { '$in' => [ 'event', 'incident' ] },
            },
        ]
    });

    while ( my $ll = $lcur->next ) {

        my $target_id;
        my $target_type;

        if ( $ll->{target_type} eq "entry" ) {
            $target_id      = $ll->{item_id};
            $target_type    = $ll->{item_type};
        }
        else {
            $target_id      = $ll->{target_id};
            $target_type    = $ll->{target_type};
        }

        say "   Entry $entry_id is linked to $target_type $target_id";

        unless ($dryrun) {
            $link_col->create_bidi_link({
                    type    => $target_type,
                    id      => $target_id,
                },{
                    type    => "entity",
                    id      => $entity_id,
                },
                $when
            );
        }
        else {
            say " -- dry run -- would have created links: ";
            say "   $target_type:$target_id --> entity:$entity_id";
        }
        $total --;
        say "$total remain";
    }
}




