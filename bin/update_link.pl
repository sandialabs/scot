#!/usr/bin/env perl

use MongoDB;
use Data::Dumper;
use v5.18;

my $mongo           = MongoDB->connect->db('scot-prod');
my $collection      = $mongo->get_collection('link');
my $newcollection   = $mongo->get_collection('newlink');

my $newcur  = $newcollection->find({});
   $newcur->sort({id => -1});
my $last = $newcur->next;
my $lastid  = $last->{id};

say "Last link processed was $lastid";

$newcur = undef;

my $cursor          = $collection->find({id=>{'$gt'=>$lastid}});
$cursor->immortal(1);

print "starting...\n";
my %lookup  = ();

my $remain = $cursor->count;
my $batch_count = 0;
my @batch   = ();
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

    push @batch, $new_record;
    $batch_count++;

    if ( $batch_count > 99 ) {
        $newcollection->insert_many(\@batch);
        $remain -= $batch_count;
        $batch_count = 0;
        printf("%15d links remain to update\n", $remain);
    }

#     $newcollection->update({id=>$id}, $new_record, {upsert => 1});
}

# now drop link

# and rename newlink to link
