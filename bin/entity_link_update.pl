#!/usr/bin/env perl

use MongoDB;
use Data::Dumper;
use v5.18;

#my $env = Scot::Env->new({
#    config_file => "../../Scot-Internal-Modules/etc/elu.cfg.pl",
#});

my $mongo       = MongoDB->connect->db('scot-prod');
my $entitycol   = $mongo->get_collection('entity');
my $linkcol     = $mongo->get_collection('link');
my $nlcol       = $mongo->get_collection('link2');


my $entitycur = $entitycol->find({});
$entitycur->immortal(1);
my $entity_remain = $entitycur->count;
# $entitycur->sort({id=>1});

print "___Processing $entity_remain Entities\n";

my %duplicate_entities  = ();
my %entity_lookup       = ();
my @batch               = ();
my $batch_count         = 0;


ENTITY:
while ( my $entity = $entitycur->next ) {
    my $entity_lookup_id = $entity_lookup{$entity->{value}};

    say "Entity ".$entity->{value}." (".$entity->{id}.")";

    if ( defined $entity_lookup_id ) {
        # this entity has duplicate records
        # replace the id in the entity record with the first id
        my $dupid = $entity->{id};
        $entity->{id} = $entity_lookup_id;
        push @{$duplicate_entities{$entity->{value}}{$entity_lookup_id}}, 
            $dupid;
        print "    is a duplicate of $entity_lookup_id\n";
    }
    else {
        # this is the first time working with this entity
        $entity_lookup{$entity->{value}} = $entity->{id};
    }

    my @links = get_entity_links($entity);

    foreach my $link (@links) {
        # inserts are costly, but insert_many allows you do multiple hundreds
        # of records in the same time as one record.
        my $record  = create_link_record($entity,$link);
        push @batch, $record;
        $batch_count = scalar(@batch);
        if ( $batch_count > 999 ) {
            print "        ! Writing new Link Records\n";;
            $nlcol->insert_many(\@batch);
            $batch_count    = 0;
            @batch          = ();
        }
    }
    $entity_remain--;
    print "--- $entity_remain entities remain to be processed\n";
}

# in case some records still in @batch
if ( scalar(@batch) > 0 ) {
    print "!!!! Writing new Link Records !!!!!\n";
    $nlcol->insert_many(\@batch);
}

remove_duplicate_entities(\%duplicate_entities);

sub remove_duplicate_entities {
    my $dups    = shift;

    foreach my $value (keys %$dups) {
        foreach my $id (sort keys %{$dups->{$value}}) {
            my $id_aref = $dups->{$value}->{$id};
            print "$value ($id) has duplicates: \n";
            foreach (@$id_aref) {
                print "    $_\n";
            }
        }
    }
}

sub get_entity_links {
    my $entity  = shift;
    my $value   = $entity->{value};

    my $elcursor    = $linkcol->find({
        value   => $value,
    });
    # $elcursor->sort({id=>1});
    my $link_count = $elcursor->count;

    print "    Orig: $link_count links, ";

    my @targets = ();
    my %seen    = ();
    LINK:
    while ( my $link = $elcursor->next ) {
        my $key = $link->{target}->{type}.$link->{target}->{id};
        $seen{$key}++;
        if ( $seen{$key} > 1 ) {
            next LINK;
        }
        push @targets, $link;
    }
    
    say " now ".scalar(@targets) . " links";

    return wantarray ? @targets : \@targets;
}

sub create_link_record {
    my $entity      = shift;
    my $link        = shift;

    my $entity_id   = $entity->{id};
    my $link_id     = $link->{id};
    my $targetid    = $link->{target}->{id};
    my $targettype  = $link->{target}->{type};
    my $when        = $link->{when};

    my $vertices    = [
        { id => $entity_id, type => "entity" },
        { id => $targetid,  type => $targettype },
    ];
    my $record  = {
        id      => $link_id,
        weight  => 1,
        vertices=> $vertices,
        when    => $when,
    };
    return $record;
}
        





