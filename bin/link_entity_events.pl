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


my $entity_col  = $mongo->collection('Entity');
my $entry_col   = $mongo->collection('Entry');
my $link_col    = $mongo->collection('Link');

my $link_cursor = $link_col->find({
    '$or'   => [
        { target_type   => "entry",
          item_type     => "entity", },
        { target_type   => "entity",
          item_type     => "entry" },
    ]
});

$link_cursor->immortal(1);
my $remain = $link_cursor->count();

while ( my $link = $link_cursor->next ) {

    my $entity_id;
    my $entry_id;

    if ( $link->target_type eq "entry" ) {
        $entry_id   = $link->target_id;
        $entity_id  = $link->item_id;
    }
    else {
        $entity_id   = $link->target_id;
        $entry_id    = $link->item_id;
    }
    my $when = $link->when;

    printf "Entity %8d in Entry %8d ", $entity_id, $entry_id;

    # get the "event" id for the entry

    my $event_link = $link_col->find_one({
        '$or'   => [
            { target_type   => "event",
              item_type     => "entry",
              item_id       => $entry_id,
            },
            { target_type   => "entry",
              target_id     => $entry_id,
              item_type     => "event",
            },
        ]
    });
    
    unless (defined $event_link ) {
        print " X ";
        $remain --;
        printf commify($remain)."\n";
        next;
    }

    my $event_id;

    if ( $event_link->target_type eq "event" ) {
        $event_id   = $event_link->target_id;
    }
    else {
        $event_id   = $event_link->item_id;
    }

    printf "Event %5d ", $event_id;

    my $event_entity_link = $link_col->find_any_one(
        { id => $event_id, type => "event" },
        { id => $entity_id, type => "entity" },
    );

    if ( $event_entity_link ) {
        print " = ";
    }
    else {
        $event_entity_link  = $link_col->create_bidi_link(
            { id => $event_id, type => "event" },
            { id => $entity_id, type => "entity" },
            $when
        );
        print " + ";
    }
    $remain --;
    printf commify($remain)."\n";
}

sub commify {
    my $number  = shift;
    my $text    = reverse $number;
    $text       =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}





