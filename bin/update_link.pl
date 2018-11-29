#!/usr/bin/env perl

use MongoDB;
use Data::Dumper;
use v5.16;

my $mongo           = MongoDB->connect->db('scot-prod');
my $collection      = $mongo->get_collection('link');
my $newcollection   = $mongo->get_collection('newlink');
$newcollection->indexes->create_one(['vertices' => 1]);
$newcollection->indexes->create_one(['vertices.type' => 1, 'vertices.id' => 1]);

my $newcur  = $newcollection->find({});
   $newcur->sort({id => -1});
my $last = $newcur->next;
my $lastid  = $last->{id} // 0;

say "Last link processed was $lastid";

$newcur = undef;

my $cursor          = $collection->find({id=>{'$gt'=>$lastid}});
$cursor->immortal(1);

print "starting...\n";
my %lookup  = ();

my $remain = $cursor->count;
my $batch_count = 0;
my @batch       = ();
my %seen        = ();
my %entitydups  = ();
my %linkdups    = ();

my $starting_link_count = $cursor->count;
my $new_link_count      = 0;
my $dup_entity_count    = 0;
my $dup_link_count      = 0;

open(my $linkdups,      ">", "/var/log/scot/link.dups.txt") || die "can not open link dups";
open(my $entitydups,    ">", "/var/log/scot/entity.dups.txt") || die "can not open entity dups";
open(my $entitychanges, ">", "/var/log/scot/entity.chages.txt") || die "can not open file";
open(my $linkupdates,   ">", "/var/log/scot/linkupdates.dups.txt") || die "can not open linkupdates ";

LINK:
while (my $link = $cursor->next) {

    my $id      = $link->{id};
    my $value   = $link->{value};
    my $target  = $link->{target};
    my $eid     = $link->{entity_id};
    my $tid     = $target->{id};
    my $ttype   = $target->{type};

    say "Link $id : $value($eid) <==> $ttype($tid)";

    if ( defined $seen{$value} ) {
        # we have seen this value before, let's see if the entity id is the same
        if ( $seen{$value} ne $eid ) {
            # ok, we have an entity with same value but different id.  a duplicate entity!
            my $key = $value.':'.$seen{$value};
            push @{$entitydups{$key}}, $eid;

            my $dupid   = $eid;
            $eid = $seen{$value}; # set it to the first found instance
            $dup_entity_count++;
            say $entitydups "$value [$eid] has a duplicate entity id = $dupid";
        }
    }
    else {
        $seen{$value} = $eid;
    }

    my $vertices = [
        { id => $eid, type => "entity" },
        { id => $tid, type => $ttype },
    ];

    my $tmemo   = "";

    if ( $ttype eq "event" or 
         $ttype eq "alertgroup" or 
         $ttype eq "intel" or
         $ttype eq "incident" ) {
        my $tobj    = $mongo->get_collection($ttype)->find_one({id => $tid});
        $tmemo = $tobj->{subject};
    }


    my $memo    = [ $value, "$tmemo" ];

    my $linkkey = join(':',$eid,$ttype,$tid);

    if ( defined $linkdups{$linkkey} ) {
        say $linkdups "Duplicate Link skipped: Entity - $eid <===> $ttype - $tid";
        $dup_link_count++;
        next LINK;
    }
    $linkdups{$linkkey} = $id;  # store the orig/first link id

    $new_link_count++;

    my $when = $link->{when};

    my $new_record = {
        id      => $id,
        when    => $when,
        weight  => 1,
        vertices=> $vertices,
        memo    => $memo,
    };

    say $linkupdates "Creating Link $id of Entity $eid to $ttype $tid";

    push @batch, $new_record;
    $batch_count++;

    if ( $batch_count > 499 ) {
        $newcollection->insert_many(\@batch);
        $remain -= $batch_count;
        $batch_count = 0;
        @batch = ();
        printf("%15d links remain to update\n", $remain);
    }
}

# catch remainder of batch
if ( scalar(@batch) > 0 ) {
    $newcollection->insert_many(\@batch);
}

say "===========";
say "= $starting_link_count links were reduced to $new_link_count";
say "= $dup_entity_count duplicate entities were detected";
say "===========";
say "";
# say "Renaming collections...";
# now change link to oldlink
if ( $new_link_count == 0 ) {
    die "No Links processed!";
}

 
say "Deleting duplicate Entities...";
my $entitycol       = $mongo->get_collection('entity');
my $entrycol        = $mongo->get_collection('entry');

foreach my $dupkey (keys %entitydups) {
    my ($id,$value) = split(/:/,$dupkey,2);
    say "deduplicating $id:$value";
    say $entitychanges "Updating entries pointing to duplicates of $value($id)";
    my $id_aref     = $entitydups{$dupkey};
    my $result  = $entrycol->update_many(
        {'target.id' => {'$in' => $id_aref}, 'target.type' => "entity"},
        {'$set' => { 'target.id' => $id } }
    );
    say $entitychanges "    repointed ". $result->modified_count. " entries of duplicates";
    my $delresult = $entitycol->delete_many({id => {'$in' => $id_aref }});
    say $entitychanges "    deleted   ". $delresult->deleted_count. " duplicate entities of $value";
}

#my $oldlinkcol = $collection->rename('oldlink');

# and rename newlink to link
#my $collection   = $newcollection->rename('link');
