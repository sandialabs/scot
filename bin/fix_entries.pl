#!/usr/bin/env perl

use lib '../lib';
use Scot::Env;
use Meerkat;
use Meerkat::Cursor;
use v5.18;
use Data::Dumper;

my $env = Scot::Env->new();


my $type    = $ARGV[0];
my $id      = $ARGV[1] + 0;
my $mongo   = $env->mongo;
my $col     = $mongo->collection('Link');
my $entryc  = $mongo->collection('Entry');

my $links   = $col->get_links($type, $id, 'entry');

while ( my $link = $links->next ) {

    my $pair    = $link->pair;
    say Dumper($pair);
    my $entryid;

    if ( $pair->[0]->{type} eq "entry" ) {
        $entryid    = $pair->[0]->{id} + 0;
    }
    else {
        $entryid    = $pair->[1]->{id} + 0;
    }

    my $entry   = $entryc->find_iid($entryid);

    $entry->update({
        '$set'   => {
            target  => {
                id      => $id,
                type    => $type,
            }
        }
    });
}

