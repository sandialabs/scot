#!/usr/bin/env perl

use MongoDB;
use Data::Dumper;
use v5.18;

my $mongo           = MongoDB->connect->db('scot-prod');
my $collection      = $mongo->get_collection('link');
my $newcollection   = $mongo->get_collection('newlink');
my $cursor          = $collection->find();

$cursor->immortal(1);

print "starting...\n";
my %lookup  = ();

my $remain = $cursor->count;

while (my $link = $cursor->next) {

    my $id  = $link->{id};

    my $vertices = [
        { id => $link->{entity_id},    type => "entity" },
        { id => $link->{target}->{id}, type => $link->{target}->{type} },
    ];

    my $when = $link->{when};

    my $new_record = {
        id      => $id,
        when    => $when,
        weight  => 1,
        vertices=> $vertices,
    };

    $newcollection->update({id=>$id}, $new_record, {upsert => 1});
    printf("%15d links remain to update\n", $remain--);
}

# now drop link

# and rename newlink to link
