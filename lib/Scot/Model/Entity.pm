package Scot::Model::Entity;

use lib '../../lib';
use lib '../../../lib';
use strict;
use warnings;
use v5.10;

use JSON qw( decode_json );
use XML::Smart;
use LWP::UserAgent;
use HTTP::Request::Common;
use Moose;
use MongoDB;
use Moose::Util::TypeConstraints;
use Data::Dumper;
use Geo::IP;
use Scot::Util::Geoip;
use Scot::Util::Timer;
use namespace::autoclean;

=head1 NAME

 Scot::Model::Entity = a moose obj rep of a Scot Entity

=cut

=head1 DESCRIPTION

 Entities are things like IP addresses, MD5 hashes, email addrs, domainnames
 and this is the definition of the logical datastructure to hold them

=head2 Consumes Roles

    'Scot::Roles::Loggable',
    'Scot::Roles::Dumpable',
    'Scot::Roles::Hashable',

=cut

extends 'Scot::Model';
with    (
    'Scot::Roles::Loggable',
    'Scot::Roles::Dumpable',
    'Scot::Roles::Hashable',
);

=head2 Attributes

=over 4

=cut

around BUILDARGS => sub {
    my $orig    = shift;
    my $class   = shift;

    if (@_ == 1 && ref($_[0]) eq 'Scot::Controller::Handler') {
        my $ref     = $_[0]->req;
        my $href    = {env => $_[0]->env};
        return $class->$orig($href);
    }
    else {
        my $init_href   = shift;
        unless ( $init_href->{notes} ) {
            $init_href->{notes} = [];
        }
        return $class->$orig($init_href);
    }
};

=item C<entity_id>

 integer

=cut

has entity_id   => (
    is          => 'rw',
    isa         => 'Int',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1
    },
);

=item C<idfield>

 since my integer id fields in models include the model name in them 
 instead of just "id", this field gives us an easy way to figure out
 what the id attribute is.  We can debate the original choice later...

=cut

has idfield    => (
    is          => 'ro',
    isa         => 'Str',
    required    =>  1,
    default     => 'entity_id',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<collection>

 easy way to keep track of object to collection mapping.  

=cut

has collection => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'entities',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<entity_type>

    ipaddr, hash, emailaddr...

=cut

has entity_type => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1
    },
);

=item C<value>

 this is the actual entity string representaion

=cut

has value     => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);

=item C<notes>

 user contributed data about the entity

=cut 

has notes   => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => [ 'Hash' ],
    default => sub {{}},
    handles => {
        delete_note => 'delete',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1
    },
);

=item C<entries>

    array of entry_id where  entity is present

=cut

has entries    => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    handles     => {
        entry_ref_count => 'count',
    },
    default     => sub {[]},
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1, 
        alt_data_sub    => 'entry_ref_count',
    },
);

=item C<alerts>

    array of alert_id where  entity is present

=cut

has alerts    => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    default     => sub {[]},
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

=item C<alert_count>

numerical count of alerts that this entity exists in

=cut 

has alert_count  => (
    is      => 'rw',
    isa     => 'Num',
    default     => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1, 
    },
);

=item C<alertgroups>

    array of alertgroup_id where  entity is present

=cut

has alertgroups    => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    default     => sub {[]},
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

=item C<alertgroup_count>

numerical count of alertgroups that this entity exists in

=cut 

has alertgroup_count  => (
    is      => 'rw',
    isa     => 'Num',
    default     => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1, 
    },
);


=item C<events>

    array of event_id where entity is present

=cut

has events    => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    default     => sub {[]},
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

has event_count  => (
    is      => 'rw',
    isa     => 'Num',
    default     => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1, 
    },
);

=item C<intels>

    array of intel_id where entity is present

=cut

has intels    => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    default     => sub {[]},
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

has intel_count  => (
    is      => 'rw',
    isa     => 'Num',
    default     => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1, 
    },
);

=item C<incidents>

    array of incidents where entity is present

=cut

has incidents   => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    default     => sub {[]},
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);


has incident_count  => (
    is      => 'rw',
    isa     => 'Num',
    default     => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1, 
    },
);


=item C<geo_data>

 cache of discovered geo_ip data

=cut

has geo_data    => (
    is          => 'rw',
    isa         => 'HashRef',
    traits      => [ 'Hash' ],
    lazy        => 1,
    builder     => 'get_geo_data',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1
    },
);

=item C<reputation>

 reputation data

=cut

has reputation     => (
    is          => 'rw',
    isa         => 'Maybe[HashRef]',
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
    default     => undef,
);

sub _empty_aref {
    return [];
}

=item C<block_data>

 hold the data received from blocklist

=cut

has block_data    => (
    is          => 'rw',
    isa         => 'HashRef',
    traits      => [ 'Hash' ],
    default     => sub {{}},
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1
    },
);

=back

=head2 Methods

=over 4

=cut


# currently Entity works, but it implementation is f*cked
# really should be treated like any other model
# but currently updated and changes have their own routes
# that are handled in Handler.pm.

# below is advance work to make this work like any other
# model and will require changes in the javascript code
# (and tests?) to make work

=item C<apply_changes>

takes data from controller (web input) and updated the object

=cut

sub apply_changes {
    my $self    = shift;
    my $mojo    = shift;
    my $user    = $mojo->session('user');
    my $log     = $self->log;
    my $req     = $mojo->req;
    my $json    = $req->json;
    my $now     = $self->_timestamp();
    my $changes = [];

    $log->debug("JSON received ".Dumper($json));

    while ( my ($k,$v) =  each %$json ) {
        if ($k eq "addnote") {
            $self->add_note( $user => $v );
        } 
        elsif ( $k eq "rmnote" ) {
            $self->delete_note($user);
        }
        else {
            next if ($k eq "tag");
            $log->debug("update $k to $v");
            my $orig = $self->$k;
            $self->$k($v);
            push @$changes,"Changed $k from $orig to $v";
        }
    }
    $self->updated($now);
}


# need to create add_to/remove_from functions for 
# events, alerts, incidents, entries

sub build_modification_cmd {
    my $self    = shift;
    my $mojo    = shift;
    my $user    = $mojo->session('user');
    my $log     = $self->log;
    my $req     = $mojo->req;
    my $json    = $req->json;
    my $now     = $self->_timestamp();
    my $changes = [];
    my $data_href    = {};

    while ( my ($k, $v) = each %$json ) { 
        if ( $k eq "addnote" ) {
            my $note    = {
                who     => $user,
                when    => $now,
                text    => $v,
            };
            $data_href->{'$addToSet'}->{notes} = $note;
        }
        elsif ( $k eq "addreference" ) {
            my $type    = $v->{type};
            my $id      = $v->{id};
            $data_href->{'$addToSet'}->{"references.".$type} = $id;
        }
        else {
            my $orig    = $self->$k;
            if ($self->constraint_check($k,$v)) {
                push @$changes, {$k => $orig};
                $data_href->{'$set'}->{$k} = $v;
            }
            else {
                $log->error("Value $v does not pass type constraint for attribute $k!");
                $log->error("Requested update ignored");
            }
        }
    }
    $data_href->{'$set'}->{updated} = $now;
    $data_href->{'$addToSet'}->{'history'} = {
        who     => $user,
        when    => $now,
        what    => "updated",
        old     => $changes,
    };
    my $modhref = {
        collection  => "entities",
        match_ref   => { entity_id => $self->entity_id },
        data_ref    => $data_href,
    };
    return $modhref;
}


sub expensive_update_data {
    my $self    = shift;
    my $mongo   = shift;
    my $log     = $self->log;
    my $type    = $self->entity_type;

    if (! defined $mongo ) {
        $log->error("Failed to provide mongo ref from ".Dumper(caller(1)));
    }

    my $geo_data = $self->geo_data;
    my $org = $geo_data->{org};
}
sub update_data {
    my $self    = shift;
    my $mongo   = shift;
    my $log     = $self->log;
    my $type    = $self->entity_type;

    #$log->debug("UPDATING ENTITY DATA!");
    #$log->debug("    entity_id : ".$self->entity_id);
    #$log->debug("    value     : ".$self->value);
    #$log->debug("    type      : ".$type);

    if (! defined $mongo ) {
        $log->error("Failed to provide mongo ref from ".Dumper(caller(1)));
    }


    if ($type =~ /ipaddr/i ) {
     #   $log->debug("Entity type is ipaddr so geting geo data");
        my $href    = $self->get_geo_data();
     #   $log->debug("Got ".Dumper($href));
        $self->geo_data($href);
    }
}

sub get_extended_data {
    my $self    = shift;
    my $type    = $self->entity_type;

    if ( $type =~ /ipaddr/i ) {
        my $geo     = $self->get_geo_data;
        $self->geo_data($geo);
        my $org     = $geo->{org};
    }
}


sub get_geo_data {
    my $self    = shift;
    my $type    = $self->entity_type;
    my $ipaddr  = $self->value;
    my $log     = $self->log;

    my $env     = $self->env;
    my $geoip   = $env->geoip;
    
    return $geoip->get_geo_data($type, $ipaddr);
}

# need to remove these from Handler.pm when 
# we make Entity cosistent with other models
# in handler we will call this to enrich data before rendering to client

sub get_referenced_objects {
    my $self    = shift;
    my $mongo   = shift;
    my $log     = $self->log;
    my %data    = ();

    foreach my $collection (qw(alerts events incidents)) {

        my $idfield         = $mongo->get_id_field_from_collection($collection);
        my $nonpluralname   = $mongo->unplurify_name($collection);

        $log->debug("Gathering referenced $collection for Entity");

        my $subjects_aref   = $self->get_ref_subjects(  $collection, 
                                                        $self->$collection,
                                                        $mongo);

        foreach my $href (@$subjects_aref) {
            my $id      = $href->{$idfield};
            $data{$collection}{$id}{subject} = $href->{subject};
        }

        my $cursor  = $mongo->read_documents({
            collection  => "entries",
            match_ref   => { entry_id => { '$in' => $self->entries } },
        });
        while ( my $href = $cursor->next_raw ) {
            my $target  = $href->{target_type};
            my $tid     = $href->{target_id};
            next unless ( $target eq $nonpluralname );
            push @{$data{$collection}{$tid}{entries}}, $href->{entry_id};
        }
    }
    return \%data;
}

sub get_ref_subjects {
    my $self    = shift;
    my $type    = shift;
    my $aref    = shift;
    my $mongo   = shift;

    my $idfield     = $mongo->get_id_field_from_collection($type);
    my $match_ref   = { $idfield => { '$in' => $aref } };
    my $cursor      = $mongo->read_documents({
        collection  => $type,
        match_ref   => $match_ref,
    });
    my @data    = ();

    while (my $href = $cursor->next_raw ) {
        push @data, {
            $idfield    => $href->{$idfield},
            subject     => $href->{subject},
        };
    }
    return \@data;
}


sub build_href_list {
    my $self        = shift;
    my $p_href      = shift;
    my $target      = $p_href->{target};
    my $collection  = $p_href->{collection};
    my $field       = $p_href->{field};
    my $idfield     = $p_href->{idfield};
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $log         = $self->log;

    # $log->debug("Building href_list based on ".Dumper($p_href));

    my %data;
    my @ids;

    my $cursor  = $mongo->read_documents({
        collection  => $collection,
        match_ref   => { $idfield => { '$in' => $self->$field } },
    });
    while ( my $href = $cursor->next_raw ) {
        my $id = $href->{$idfield};
        push @ids, $id;
        $data{$id}{subject} = $href->{subject};
    }
    $cursor = $mongo->read_documents({
        collection  => "entries",
        match_ref   => {
            target_type => $target,
            target_id   => { '$in'  => \@ids },
        }
    });
    while ( my $href = $cursor->next_raw ) {
        my $id = $href->{target_id};
        push @{ $data{$id}{entries} }, $href->{entry_id};
    }
    # $log->debug("found ".Dumper(\%data));
    return \%data;
}


sub build_event_href_list {
    my $self        = shift;
    my $env         = $self->env;
    my $redis       = $env->redis;
    my $events_aref = $redis->get_events(lc($self->value));
    $self->events($events_aref);
    return $self->build_href_list({
        target      => "event",
        collection  => "events",
        idfield     => "event_id",
        field       => "events",
    });
}

sub build_incident_href_list {
    my $self        = shift;
    my $env         = $self->env;
    my $redis       = $env->redis;
    my $incidents_aref = $redis->get_incidents(lc($self->value));
    $self->incidents($incidents_aref);
    return $self->build_href_list({
        target      => "incident",
        collection  => "incidents",
        idfield     => "incident_id",
        field       => "incidents",
    });
}

sub build_alert_href_list {
    my $self        = shift;
    my $env         = $self->env;
    my $redis       = $env->redis;
    my $alerts_aref = $redis->get_alerts(lc($self->value));
    $self->alerts($alerts_aref);
    return $self->build_href_list({
        target      => "alert",
        collection  => "alerts",
        idfield     => "alert_id",
        field       => "alerts",
    });

}

__PACKAGE__->meta->make_immutable;
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

=item L<Scot::Controller::Handler>

=item L<Scot::Util::Mongo>

=item L<Scot::Model>

=back

