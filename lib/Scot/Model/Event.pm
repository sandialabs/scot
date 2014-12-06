package Scot::Model::Event;

use lib '../../lib';
use strict;
use warnings;
use v5.10;
use Data::Dumper;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

=head1 NAME

 Scot::Model::Event 

=head1 DESCRIPTION

 a moose obj rep of a Scot Event

=cut

extends 'Scot::Model';

=head2 Enumerations

    valid_status    : open, closed, cold, promoted

=cut

enum 'valid_status', [ qw(open closed cold promoted) ];

=head2 Roles Consumed

    'Scot::Roles::Closeable',
    'Scot::Roles::Dumpable',
    'Scot::Roles::Entriable',
    'Scot::Roles::Entitiable',
    'Scot::Roles::FileAttachable',
    'Scot::Roles::Hashable',
    'Scot::Roles::Historable',
    'Scot::Roles::Labelable',
    'Scot::Roles::Ownable',
    'Scot::Roles::Permittable',
#    'Scot::Roles::Promotable',
    'Scot::Roles::SetOperable',
    'Scot::Roles::Sourceable',
#    'Scot::Roles::Scot2identifiable',
    'Scot::Roles::Statusable',
    'Scot::Roles::Subjectable',
    'Scot::Roles::Taggable',
    'Scot::Roles::ViewTrackable',

=cut

with (
    'Scot::Roles::Closeable',
    'Scot::Roles::Dumpable',
    'Scot::Roles::Entriable',
    'Scot::Roles::Entitiable',
    'Scot::Roles::FileAttachable',
    'Scot::Roles::Hashable',
    'Scot::Roles::Historable',
    'Scot::Roles::Labelable',
    'Scot::Roles::Ownable',
    'Scot::Roles::Permittable',
#    'Scot::Roles::Promotable',
    'Scot::Roles::SetOperable',
    'Scot::Roles::Sourceable',
#    'Scot::Roles::Scot2identifiable',
    'Scot::Roles::Statusable',
    'Scot::Roles::Subjectable',
    'Scot::Roles::Taggable',
    'Scot::Roles::ViewTrackable',
);

=head2 Attributes

=over 4

=item C<event_id>

 the integer id for the event

=cut

has event_id => (
    is          => 'rw',
    isa         => 'Int',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
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
    default     => 'event_id',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<collection>

 easy way to keep track of object to collection mapping.  
 We can debate the original choice later...

=cut

has collection => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'events',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<alerts>

 mongo iids of the the associated alerts 

=cut

has alerts      => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    builder     => '_build_empty_array',
    handles     => {
        add_alerts      => 'push',
        all_alerts      => 'elements',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

=item C<incidents>

 mongo iids of the the associated alerts 

=cut

has incidents      => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    builder     => '_build_empty_array',
    handles     => {
        add_incident      => 'push',
        all_incidents      => 'elements',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

=back

=head2 Methods

=over 4

=cut

sub _build_empty_array {
    return [];
}

around BUILDARGS    => sub {
    my $orig    = shift;
    my $class   = shift;

    if (@_ == 1 && ref $_[0] eq 'Scot::Controller::Handler') {
        my $req     = $_[0]->req;
        my $json    = $req->json;
        my $tagaref = $json->{'tags'} // [];
        my $href    = {
            subject => $json->{'subject'},
            tags    => $tagaref,
            env     => $_[0]->env,
        };
        $href->{sources} = [$json->{"source"}];

        my $rg      = $json->{"readgroups"};
        if ( defined $rg && scalar(@$rg) > 0 ) { $href->{readgroups} = $rg; }
    
        my $mg      = $json->{"modifygroups"};
        if ( defined $mg && scalar(@$mg) > 0 ) { $href->{modifygroups} = $mg; }
        if ( $json->{'created'} ) {
            $href->{created} = $json->{'created'};
        }

        return $class->$orig($href);
    }
    else {
        return $class->$orig(@_);
    }
};

=item C<apply_changes>

=cut

sub apply_changes {
    my $self    = shift;
    my $mojo    = shift;
    my $env     = $mojo->env;
    my $mongo   = $env->mongo;
    my $user    = $mojo->session('user');
    my $log     = $self->log;
    my $req     = $mojo->req;
    my $json    = $req->json;
    my $now     = $self->_timestamp();
    my $changes = [];

    $log->debug("JSON received " . Dumper($json));

    while ( my ($k, $v) = each %$json ) {
        if ($k eq "cmd") {
            # do stuff
            if ( $v eq "addtag" ) {
                foreach my $tag (@{$json->{tag}}) {
                    $self->add_to_tags($mongo, $tag);
                    push @$changes, "Added Tag: $tag";
                }
            }
            if ( $v eq "rmtag" ) {
                foreach my $tag (@{$json->{tag}}) {
                    $self->remove_tag($mongo, $tag);
                    push @$changes, "Removed Tag: $tag";
                }
            }
        }
        else {
            next if ($k eq "tag");
            my $orig = $self->$k;
            $self->$k($v);
            push @$changes, "Changed $k from $orig to $v";
        }
    }
    $self->updated($now);
    $self->add_historical_record({
        who     => $mojo->session('user'),
        when    => $now,
        what    => $changes,
    });
}

=item C<build_modification_cmd>

=cut

sub build_modification_cmd {
    my $self    = shift;
    my $mojo    = shift;
    my $env     = $mojo->env;
    my $mongo   = $env->mongo;
    my $user    = $mojo->session('user');
    my $log     = $self->log;
    my $req     = $mojo->req;
    my $json    = $req->json;
    my $now     = $self->_timestamp();
    my $changes = [];
    my $data_href    = {};

    $log->debug("building modification command");
    $log->debug("json is ".Dumper($json));

    while ( my ($k, $v) = each %$json ) {
        $log->debug("$k  => $v");
        if ($k eq "cmd") {
            if ($v  eq "addtag" ) {
                $data_href->{'$addToSet'}->{tags}->{'$each'} = $json->{tags};
                foreach my $tag (sort @{$json->{tags}}) {
                    $self->add_to_tags($mongo, $tag);
                }
                push @$changes, "added tag(s): ".join(',',@{$json->{tags}});
            }
            if ($v  eq "rmtag" ) {
                $data_href->{'$pullAll'}->{tags} = $json->{tags};
                foreach my $tag (sort @{$json->{tags}}) {
                    $self->remove_tag($mongo, $tag);
                }
                push @$changes, "removed tag(s): ".join(',',@{$json->{tags}});
            }
        }
        else {
            next if ($k eq "tags") ;
            my $orig    = $self->$k;
            if ($self->constraint_check($k,$v)) {
                push @$changes, "updated $k from $orig";
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
        what    => join(', ', @$changes),
    };
    my $modhref = {
        collection  => "events",
        match_ref   => { event_id   => $self->event_id },
        data_ref    => $data_href,
    };
    $log->debug("modhref = ".Dumper($modhref));
    return $modhref;
}

sub get_self_collection {
    return "events";
}

sub remove_self_from_references {
    my $self    = shift;
    my $mongo   = shift;
    my $log     = $self->log;
    my $thiscollection = $self->collection;
    my $idfield     = $self->idfield;
    my $id          = $self->$idfield;
    my $match_ref   = { $thiscollection => $id };
    my $data_ref    = { 
        '$pull' => { $thiscollection => $id } 
    };
    my $opts_ref    = { multiple => 1, safe => 1 };

    foreach my $collection (qw(alertgroups alerts incidents)) {
        if ($collection eq "alerts" ) {
            $data_ref->{'$set'} = { status => 'open' };
        }
        if ( $mongo->apply_update({
            collection  => $collection,
            match_ref   => $match_ref,
            data_ref    => $data_ref,
        }, $opts_ref) ) {
            $log->debug("removed $thiscollection($id) ".
                        "references from $collection");
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=back

=head1 Web API

=head2 GET /scot/event

retrieve a list of events

=over 4

=item B<Params>

    grid={start:x, limit: y, sort_ref: { colname: -1}
    columns=[col1, col2, ...]
    filter={colname: match_value_string}


=cut

=item B<Input>

none

=item B<Returned JSON>


{
    title: "Event list",
    action: "get",
    thing: "event",
    status: "ok"|"fail",
    stime:  int_unix_epoch,
    data: [
        { json_representation_of_alert1 },
        { json_representation_of_alert2 },
        ...
    ],
    columns: [ colname1, colname2, ... ],
    total_records: int_number_events_returned
}


=cut

=item B<activemq notification>


{
    action: "view",
    type:   "event",
}


=cut

=back

=head2 PUT /scot/event/:id

update event data for event :id

=over 4

=item B<Params>

none

=cut

=item B<Input>


JSON
{
    attribute_to_update: value_to_update_with,
    ...
}

=cut


=item B<returned JSON>


{
    title: "Update Event :id",
    action: "update",
    thing: "event",
    status: "ok" | "fail",
    reason: "explanation of fail, otherwise null",
    stime: server time for request in seconds
}


=cut

=item B<activemq notification>

destination: activity queue
{
    action: "update",
    type:   "event",
    id:     ":id",
    is_task: 1|undef,
    view_count: int,
}


=cut

=back

=head2 POST /scot/event

=over 4 

=item B<Params>

none

=cut

=item B<Input (JSON)>


{
    source: "sourcename",
    subject: "subject text",
    readgroups: [ "groupname1", ... ], # or omit for default
    modifygroups: [ "groupname2", ...], # or omit for default
}


=cut

=item B<returns JSON>


    {
        action  : "post",
        thing   : "event",
        id      : new event id,
        status  : "ok"|"fail",
        reason  : string,
        stime   : seconds request took on server
    }


=cut

=item B<ActiveMQ notification>


{
    action: "creation",
    type:   "event",
    id:     int_event_id,
}


=cut

=back

=head2 DEL /scot/event/:id

=over 4 

=item B<Params>

none

=item B<Input (JSON)>

none

=cut

=item B<returns JSON>


    {
        title   : "Delete event",
        action  : "delete",
        thing   : "event",
        status  : "ok"|"fail",
        reason  : string,
        stime   : seconds request took on server
    }


=cut

=item B<ActiveMQ notification>

{
    action: "deletion",
    type:   "event",
    id:     int_event_id,
}


=cut

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

