package Scot::Roles::Entitiable;

use lib '../../../lib';
use utf8;
use Moose::Role;
use Data::Dumper;
use LWP::UserAgent;
use Scot::Model::Entity;
use JSON;
use HTML::Entities;
use HTTP::Request::Common qw(POST);
use namespace::autoclean;
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);
use IPC::Run qw(run timeout);
use Scot::Util::Redis3;

=head1 NAME

    Scot::Roles::Entitiable

=head1 DESCRIPTION

This role is designed to be consumed by Scot::Models that might have
entities with in them (See Scot::Model::Entity for discussion on what
an entity is).  

Objects (alerts, events, incidents, entries) that are Entitiable 
may contain entities.  Entities are strings that match regular expressions
defined in the entity extractor .  Entities that are detected will
be stored in the Entities collection of the Scot database.  

methods in this role facilitate interactions with entities in a consitent
way.

Entity interations:
    1. discover entities within object
    3. look up information about entities from scot db, geoip, etc...

=cut

requires 'log';

=head1 Attributes

=over 4

=item C<entity_data>

 entity data should not be stored in the object, but in the entity collection
 this will be populated at request time to ensure the most update view of
 an entities status
 this is a HashRef of  { entity_value => entity_obj_href }

=cut

has entity_data => (
    is          => 'rw',
    isa         => 'HashRef',
    traits      => [ 'Hash' ] ,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

sub _empty_array {
    return [];
}

=back

=head1 Methods

=over 4

=cut

=item C<get_entity_data>

 this function will look up data in scot and via geo lookup etc.
 for each enity found and store it in the entity_data attribute

=cut

sub get_entity_data {
    my $self        = shift;
    my $full        = shift;
    my $env         = $self->env;
    my $log         = $self->log // $env->log;
    my $redis       = $env->redis; # scot::util::redis3
    my $data        = $redis->get_entities($self, $full);

    foreach my $entity_value ( keys %$data ) {
        if ( $data->{$entity_value}->{entity_type} eq "ipaddr" ) {
            $data->{$entity_value}->{geo_data} = 
                $self->get_geo_data($entity_value);
        }
    }

    return $data;
}

sub get_geo_data {
    my $self    = shift;
    my $ipaddr  = shift;
    my $geoutil = $self->env->geoip;
    my $gi      = $geoutil->geoip_city;
    my $record  = $gi->record_by_addr($ipaddr);
    my $href    = {};

    $self->log->debug("Getting GEO data");

    if ($record) {
        my $cc  = $record->country_code;
        my $org = '';
        my $odb = $geoutil->geoip_org;
        if(defined($odb)) {
           $org    = $odb->name_by_addr($ipaddr);

        }
        $href   = {
            country_code    => $cc,
            country_name    => $record->country_name,
            region          => $record->region,
            org             => $org,
            city            => $record->city,
        };
    }
    else {

        my $v6  = $geoutil->geoip_v6;
	if(defined($v6)) {
           my $cc  = $v6->country_code_by_addr_v6($ipaddr);

           if ( defined $cc ) {
               $href   = { country_code => $cc };
           }

           my $asn     = $geoutil->geoip_v6asn;
           my $ipasn   = $asn->name_by_addr_v6($ipaddr);

           if ( defined $ipasn ) {
               $href->{asn}    = $ipasn;

           }
        }
    }
    return $href;
}

=item C<remove_self_from_entities>

This method, called from an Entitiable object (e.g. alerts, events,...)
will remove that object's id from the Entity record.

Say that this is called from an Alert with alert_id = 21.  
We wish to delete this alert.  To keep the entities collection up to date
we need to remove all references of alert 21 from all entities containing it.
This call will do that.

=cut

sub remove_self_from_entities {
    my $self            = shift;
    my $env             = $self->env;
    my $log             = $env->log;
    my $redis           = $env->redis;
    $log->debug("removing ".ref($self)." from entities");
    $redis->remove_from_redis($self);
}

sub remove_dups {
   my $self = shift; 
   my %hash;
    $hash{$_}++ for @_;
  return keys %hash;
}

=item C<add_self_to_entities>

given an array ref of entitites, this function will add the id of this
object to the entity record in the entities collection.

E.g.  An alert alert_id=4 has two entities (foo.com, 10.1.1.1)
calling this will at a "4" to the array attribute "alerts" in Entities
that have a value of "foo.com" or "10.1.1.1".

=cut

sub add_self_to_entities {
    my $self            = shift;
    my $entities_aref   = shift; # array of { type=> t, value=>v }
    my $env             = $self->env;
    my $redis           = $env->redis;
    my $log             = $env->log;

    $log->debug("Adding self to these entities: ",
        { filter => \&Dumper, value => $entities_aref});

    $redis->add_entities($self, $entities_aref);

}


1;
__END__

=back

=head1 COPYRIGHT

Copyright (c) 2013.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut

=head1 SEE ALSO

=cut

=over 4

=item L<Scot::Model>

=item L<Scot::Model::Entity>

=back
