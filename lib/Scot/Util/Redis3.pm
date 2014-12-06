package Scot::Util::Redis3;

use lib '../../../lib';
use lib '../../lib';
use lib '../lib';

use strict;
use warnings;
use v5.10;

use Carp qw(confess);
use Data::Dumper;
use JSON;
use Redis;
use Scot::Model::Entity;
use Moose;
use namespace::autoclean;

=head1 Scot::Util::Redis

This module provides convenience to work with Redis queries

=head2 Attributes

=over 4

=item C<config>

Hash reference to the parsed scot.json file

=cut

has config      => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);

=item C<log>

reference to the Log::Log4Perl logger 

=cut

has 'log'       => (
    is          => 'ro',
    isa         => 'Object',
    required    => 1,
);

=item C<db>

reference to the MongoDB::Database connection

=cut

has db          => (
    is          => 'ro',
    isa         => 'Redis',
    required    => 1,
    lazy        => 1,
    builder     => '_build_db_handle',
);


sub _build_db_handle {
    my $self        = shift;
    my $log         = $self->log;

    $log->info("---- Redis client connection build ---");

    return Redis->new;

}

=head2 Methods

=over 4

=item C<select_redis_db>

Select which DB to work with

search_entries  => db index 0
    keys   are snippets of text from entries data
    values are (SET) entry_ids

search_alerts  => db index 1
    keys   are snippets of text from alert data
    values are (SET) alert_ids

entity_data    => db index 2
    keys    are entity strings 
    values  are (HASH) { block_type => x, entity_type => y }

entity_notes   => db index 3
    keys    are entity strings
    values  are (HASH) { username => note }

entity_alerts   => db index 4
    keys    are entity strings
    values  are (SET) alert_ids 

alert_entities  => db index 5
    keys    are alert id's
    valeus  are (SET) entity strings in that alert

entity_alertgroups   => db index 6
    keys    are entity strings
    values  are (SET) alertgroup_ids 

alertgroup_entities  => db index 7
    keys    are alertgroup id's
    valeus  are (SET) entity strings in that alertgroup

entity_events   => db index 8
    keys    are entity strings
    values  are (SET) event_ids 

event_entities  => db index 9
    keys    are event id's
    valeus  are (SET) entity strings in that event

entity_incidents   => db index 10
    keys    are entity strings
    values  are (SET) incident_ids 

incident_entities  => db index 11
    keys    are incident id's
    valeus  are (SET) entity strings in that incident

entity_intels   => db index 12
    keys    are entity strings
    values  are (SET) intel_ids 

intel_entities  => db index 13
    keys    are intel id's
    valeus  are (SET) entity strings in that intel

entity_entries   => db index 14
    keys    are entity strings
    values  are (SET) entry ids 

entry_entities  => db index 15
    keys    are entry id's
    valeus  are (SET) entity strings in that entry

=cut

sub select_redis_db {
    my $self    = shift;
    my $type    = shift;
    my $db      = $self->db;
    my %map     = (
        'search_entries'        => 0,       # search entries using snippets
        'search_alerts'         => 1,       # search alerts using snippets
        'entity_data'           => 2,       # Key = entity str value = Hash
        'entity_notes'          => 3,       # Key = entity str value = hash
        'entity_alerts'         => 4,       # Key = entity str value = set of alert ids
        'alert_entities'        => 5,       # Key = alert id   value = set of entity strings
        'entity_alertgroups'    => 6,       # Key = entity str value = set of ag ids
        'alertgroup_entities'   => 7,       # Key = ag ids     value = set of entity strings
        'entity_events'         => 8,       # Key = entity str value = set of event ids
        'event_entities'        => 9,       # Key = event_ids  value = set of entity strings
        'entity_incidents'      => 10,      # Key = entity str value = set of incident ids
        'incident_entities'     => 11,      # Key = incidents  value = set of entity strings
        'entity_intels'         => 12,      # Key = entity str value = set of intel ids
        'intel_entities'        => 13,      # Key = intel ids  value = set of entity strings
        'entity_entries'        => 14,      # Key = entity str value = set of entry ids
        'entry_entities'        => 15,      # Key = entry ids  value = set of entity strings
        'entrie_entities'        => 15,      # Key = entry ids  value = set of entity strings
    );
    my $index   = $map{$type};

    unless ( defined $index ) {
        $self->log->error("OOPS! Redis DB index didnt match $type");
    }
    
    $self->log->trace("Selecting Redis DB $index ($type)");

    $db->select($map{$type});
}

=item C<do_cmd($dbname, $cmd, @opt_params)>

do the redis command primitive
    $dbname should match the list above
    $cmd    are the redis db command primitives such as sadd,  lrem, etc.
    @opt_params is a list of additional params that will be passed on to the $cmd.

=cut

sub do_cmd {
    my $self    = shift;
    my $dbname  = shift;
    my $cmd     = shift;
    my @params  = @_;

    local $Data::Dumper::Indent = 0;
    $self->log->trace("on $dbname executing $cmd with ", 
                        {   filter => \&Data::Dumper::Dumper,
                            value   => \@params});
    $self->select_redis_db($dbname);

    if ( wantarray ) {
        my @results;
        eval { @results    = $self->db->$cmd(@params); };
        if ($@) {
            $self->log->error("Redis $cmd FAIL: $@");
            return undef;
        }
        return @results;
    }
    else {
        my $result;
        eval { $result     = $self->db->$cmd(@params); };
        if ( $@ ) {
            $self->log->error("Redis $cmd FAIL: $@");
            return undef;
        }
        return $result;
    }
}

=item C<get_id_set>

for a given object (alert, event, alertgroup, etc.) generate a array
    of ids

=cut

sub get_id_set {
    my $self        = shift;
    my $object      = shift;
    my $collection  = $object->collection;
    my $idfield     = $object->idfield;
    my $id          = $object->$idfield;
    my @ids     = ();

#    if ( ref($object) eq "Scot::Model::Alertgroup" ) {
#        push @ids, @{$object->alert_ids};
#    }
#    else {
        push @ids, $id;
#    }
    return @ids;
}

=item C<get_entities>

get all entities for the referenced object

=cut

sub get_entities {
    my $self    = shift;
    my $object  = shift;
    my $full    = shift;
    my @values  = $self->get_objects_entity_values($object);
    my %data    = ();

    foreach my $value (@values) {
        $self->log->debug("getting entity data for : ",
                        { filter => \&Dumper, value => $value});
        $data{$value} = $self->get_redis_entity_data($value, $full);
    }
    return \%data;
}

=item C<get_objects_entity_values>

this function get the entities associated with a given object (alert, event, 
etc.) 

returns an array of entity value names

=cut

sub get_objects_entity_values {
    my $self    = shift;
    my $object  = shift;
    my $collection  = $object->collection;
    my @values  = ();
    my @ids     = $self->get_id_set($object);
    my $type    = $self->unplurify_name($collection);
    my $dbname  = $type . "_entities";

    $self->log->debug("Entity id set is ",
                    { filter => \&Dumper, value => \@ids});

    foreach my $id (@ids) {
        $self->log->debug("members of $collection => $id");
        my @evs = $self->do_cmd($dbname, "smembers", $id); 
        unless ( scalar(@evs) > 0 ) {
            $self->log->error("ERROR: Nothing returned from ".
                " $dbname smembers $id.");
        }
        $self->log->debug({filter => \&Dumper, value => \@evs});
        push @values, @evs;
    }
    return @values;
}

=item C<get_entitys_events>

return the events associated with an entity

=cut

sub get_entitys_events {
    my $self    = shift;
    my $entity  = shift;
    return $self->do_cmd("entity_events","smembers", $entity);
}

=item C<get_event_entities>

give an event_id and get array of entities

=cut

sub get_event_entities {
    my $self    = shift;
    my $id      = shift;
    return $self->do_cmd("event_entities", "smembers", $id);
}


=item C<get_entity_count>

return the number of times an entity appears 

=cut

sub get_entity_count {
    my $self        = shift;
    my $value       = shift;
    my @collections = @_ ;
    unless (scalar(@collections) > 0) {
        @collections = qw(alerts alertgroups events incidents intels);
    }
    my $count   = 0;

    foreach my $col (@collections) {
        my $dbname  = "entity_".$col;
        my $thiscount   = $self->do_cmd($dbname, "scard", $value);
        unless (defined $thiscount) {
            $self->log->debug("ERROR: $dbname scard $value");
        }
        $count += $thiscount;
    }
    return $count;
}

=item C<update_search_db>

when an entry changes, need to update the snippet db

=cut 

sub update_search_db {
    my $self        = shift;
    my $entry_id    = shift;
    my $orig_href   = shift; # snippets
    my $new_href    = shift;

    foreach my $key (keys %$new_href) {
        unless (defined $orig_href->{$key}) {
            eval {
                $self->do_cmd("search_entries", "sadd", $key, $entry_id);
            };
            if ( $@ ) {
                $self->log->error("ERROR: $@");
            }
        }
    }
    foreach my $key (keys %$orig_href) {
        unless (defined $new_href->{$key}) {
            eval {
                $self->do_cmd("search_entries", "srem", $key, $entry_id);
            };
            if ( $@ ) {
                $self->log->error("ERROR: $@");
            }
        }
    }
}


=item C<get_redis_entity_data>

generate and href of data about an entity

=cut

sub get_redis_entity_data {
    my $self    = shift;
    my $value   = shift;    # the entity_value
    my $full    = shift;    # if not undefined, do expensive stuff
    
    my %other   = $self->do_cmd("entity_data", "hgetall", $value);
    my %notes   = $self->do_cmd("entity_notes", "hgetall", $value);


    # splitting counts into events, alerts, incidents, etc. 
    # is done here because thats what the client expects,
    # need to see if we can just provide the aggregate
    # in other words just do a 
    # $href->{count} = $self->get_entity_appearance_coutn($value);

    my $href    = {
        value           => $value,
        events_count    => $self->get_entity_count($value, "events"),
        alerts_count    => $self->get_entity_count($value, "alerts"),
        intel_count     => $self->get_entity_count($value, "intels"),
        alertgroups_count    => $self->get_entity_count($value, "alertgroups"),
        incidents_count => $self->get_entity_count($value, "incidents"),
        count           => $self->get_entity_count($value),
        notes           => \%notes,
        block_data      => $other{block_data} // {},
        entity_type     => $other{entity_type} // "unknown",
    };
    if ( $full ) {
        my @events      = $self->do_cmd("entity_events","smembers", $value);
        my @alerts      = $self->do_cmd("entity_alerts","smembers", $value);
        my @alertgroups = $self->do_cmd("entity_alertgroups","smembers",$value);
        my @incidents   = $self->do_cmd("entity_incidents","smembers", $value);
        my @intels      = $self->do_cmd("entity_intels", "smembers", $value);
        $href->{events}         = \@events;
        $href->{alerts}         = \@alerts;
        $href->{alertgroups}    = \@alertgroups;
        $href->{incidents}      = \@incidents;
        $href->{intels}          = \@intels;
    }

    $self->log->debug("Entity Data for $value in Redis is: ",
                    { filter => \&Dumper, value => $href});

    return $href;
}


sub set_entity_note {
    my $self    = shift;
    my $value   = shift;
    my $user    = shift;
    my $note    = shift;
    $self->log->debug("Setting note for $value: $user => $note");
    eval {
        $self->do_cmd("entity_notes", "hset", $value, $user, $note);
    };
    if ( $@ ) {
        $self->log->error("ERROR: $@");
    }
}

sub update_block {
    my $self    = shift;
    my $domain  = shift;
    my $status  = shift;

    $self->set_block_data($domain, $status);
    my @subdomains = $self->do_cmd("entity_data", "keys", '*'.$domain);
    foreach my $subdom (@subdomains) {
        $self->set_block_data($subdom, $status);
    }
}

sub set_block_data {
    my $self    = shift;
    my $value   = shift;
    my $status  = shift;
    $self->log->debug("Setting block status to $status for $value");
    $self->do_cmd("entity_data", "hset", $value, "block_type", $status);
}

sub set_entity_type  {
    my $self    = shift;
    my $value   = shift;
    my $type    = shift;
    $self->log->debug("Setting entity type for $value to $type");
    $self->do_cmd("entity_data", "hset", $value, "entity_type", $type);
}

sub add_entity_targets {
    my $self        = shift;
    my $entity      = shift;
    my $type        = shift;
    my $id          = shift;
    my $dbname      = substr $type, 0, -1;

    $self->log->debug("Adding $entity to redis $dbname key $id");

    unless (defined $id) {
        $self->log->error("NO ID SET: ".carp());
    }

    $dbname = $dbname . "_entities";
    $self->log->debug("Adding $entity to $type $id");
    $self->do_cmd($dbname, "sadd", $id, $entity);
    my $reverse     = "entity_$type";
    $self->do_cmd($reverse, "sadd", $entity, $id);
}

=item C<del_entity_targets>

if an enity, denoted by it string value, is removed 
    call this to update the redis dbs for what it was removed from

=cut

sub del_entity_targets {
    my $self        = shift;
    my $entity      = shift;
    my $type        = shift;
    my $id          = shift;
    my $dbname      = substr $type, 0, -1;

    unless (defined $id) {
        $self->log->error("NO ID SET: ".carp());
    }

    $dbname = $dbname . "_entities";
    $self->log->debug("Removing $entity from $type $id");
    $self->do_cmd($type, "srem", $id, $entity);
}

=item C<add_entities>

when you get an entity array for a given thing call this to 
add the entities to the redis dbs

=cut

sub add_entities {
    my $self    = shift;
    my $object  = shift;    # the thing that has the entities
    my $aref    = shift;    # of entities { type => t, value => v }
    my $log     = $self->log;

    my $collection  = $object->collection;
    my $idfield     = $object->idfield;
    my $id          = $object->$idfield;

    # one tricky part: an Entry.  

    unless (defined $id) {
        $log->error("NO ID SET: ".confess());
    }


    $log->debug("updating redis entities to $collection $id");

    foreach my $href (@$aref) {
        my $type    = $href->{type};
        my $value   = $href->{value};

        if (ref($object) eq "Scot::Model::Entry") {
            $self->add_entrys_entities( {
                target_type => $object->target_type,
                target_id   => $object->target_id,
                entity_value => $value,
                entity_type => $type,
                entry_id    => $object->entry_id,
            });
        }

        $self->add_entity_targets($value, $collection, $id);
        $self->set_entity_type($value, $type);
    }
}

=item C<remove_from_redis>

when you remove a alert, event, entry, etc. call this to remove
references to that thing in the redis dbs

=cut

sub remove_from_redis {
    my $self        = shift;
    my $object      = shift;
    my $log         = $self->log;

    my @entities    = $self->get_objects_entity_values($object);

    $log->debug("this object has the following entities: ",
                { filter => \&Dumper, value => \@entities});

    my $collection  = $object->collection;
    my $idfield     = $object->idfield;
    my $id          = $object->$idfield;

    unless (defined $id) {
        $self->log->error("NO ID SET: ".carp());
    }

    foreach my $entity (@entities) {
        my $dbname = "entity_".$collection;
        $self->do_cmd($dbname, "srem", $entity, $id);
    }
    my $dbname = $self->unplurify_name($collection) . "_entities";
    $self->do_cmd($dbname, "del", $id);
}

sub plurify_name {
    my $self    = shift;
    my $name    = shift;
    my $lastchr = substr $name, -1;

    if ( $lastchr eq 'y' ) {
        my $junk = substr $name, -1, 1 , 'ie';
    }
    my $plural  = lc($name) . "s";
    return $plural;
}

sub unplurify_name {
    my $self    = shift;
    my $plural  = shift;
    my $suffix  = substr $plural, -3;
    my $singular;

    if ( $suffix eq 'ies' ) {
        ($singular = $plural) =~ s/ies$/y/;
    }
    else {
        $singular = $plural;
        chop($singular);
    }
    return $singular;
}
    


sub add_entrys_entities {
    my $self    = shift;
    my $href    = shift; 
    my $log     = $self->log;

    $log->debug("add_entrys_entities: ".Dumper($href));
        
    my $target_type     = $href->{target_type};
    my $target_id       = $href->{target_id};
    my $entity_value    = $href->{entity_value};
    my $entity_type     = $href->{entity_type};
    my $entry_id        = $href->{entry_id};

    my $thing2entities  = $target_type . "_entities";
    my $entity2things   = "entity_" . $self->plurify_name($target_type);
    my $entitydata      = "entity_data";

    $self->do_cmd($thing2entities, "sadd", $target_id, $entity_value);
    $self->do_cmd($entity2things,  "sadd", $entity_value, $target_id);
    $self->do_cmd($entitydata,     "hset", $entity_value, "entity_type", $entity_type);

    if ( defined $entry_id ) {
        $self->do_cmd("entry_entities", "sadd", $entry_id, $entity_value);
        $self->do_cmd("entity_entries", "sadd", $entity_value, $entry_id);
    }
}

sub add_text_to_search {
    my $self    = shift;
    my $href    = shift;

    my $text        = $href->{text};
    my $id          = $href->{id};
    my $collection  = $href->{collection};
    my $sniplength  = $href->{sniplength} // 4;
    my $searchdb    = "search_" . $collection;


    my @chars   = split(//, $text);

    for ( my $i = 0; $i < length($text); $i++ ) {
        my $snippet = lc( substr $text, $i, $sniplength );
        $self->do_cmd($searchdb, "sadd", $snippet, $id);
    }
}



1;
__PACKAGE__->meta->make_immutable;
__END__
=back

=head1 COPYRIGHT

Copyright (c) 2013.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut
