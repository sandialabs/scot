package Scot::Model::Intel;

use lib '../../lib';
use strict;
use warnings;
use v5.10;

use Moose;
use Moose::Util::TypeConstraints;
use Data::Dumper;
use namespace::autoclean;

=head1 NAME

 Scot::Model::Intel - a moose obj rep of a Scot Intel item

=head1 DESCRIPTION

 Definition of an Intel

=cut

extends 'Scot::Model';

=head2 Attributes

=cut

with (  
#    'Scot::Roles::Closeable',
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Entitiable',
    'Scot::Roles::Entriable',
    'Scot::Roles::FileAttachable',
    'Scot::Roles::Hashable',
    'Scot::Roles::Historable',
    'Scot::Roles::Loggable',
    'Scot::Roles::Plaintextable',
    'Scot::Roles::Permittable', 
#    'Scot::Roles::Riskable',
    'Scot::Roles::Sourceable',
    'Scot::Roles::Taggable',
    'Scot::Roles::ViewTrackable',
    'Scot::Roles::Votable',
);

=item custom new

    if you pass a Mojo::Message::Requst in as only parameter
        parse it and then do normal moose instantiation

=cut

around BUILDARGS    => sub {
    my $orig    = shift;
    my $class   = shift;

    if (@_ == 1 && ref $_[0] eq 'Scot::Controller::Handler') {
        my $req     = $_[0]->req;
        my $json    = $req->json;

        my $href    = {
            sources  => [$json->{'source'}],
            status  => 'open',
            subject => $json->{'subject'},
            tags    => $json->{'tags'}     // [],
            env     => $_[0]->env,
        };

        my $rg = $json->{'readgroups'};
        if (defined $rg && scalar(@$rg) > 0) {
            $href->{readgroups} = $rg;
        }

        my $mg = $json->{'modifygroups'};
        if (defined $mg && scalar(@$mg) > 0 ) {
            $href->{modifygroups} = $mg;
        }

        return $class->$orig($href);
    }
    # pulls from db will be a hash ref
    # which moose will handle normally
    else {
        return $class->$orig(@_);
    }
};

=item C<intel_id>

 the integer id for the intel
 why oid and id? convenience and ease of use

=cut

has intel_id    => (
    is          => 'rw',
    isa         => 'Int',
    required    =>  0,
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
    default     => 'intel_id',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

has collection  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'intels',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<when>

 the positive integer number of seconds since unix epoch
 when is "when" the intel was entered into SCOT

=cut

has when        => (
    is          =>  'rw',
    isa         =>  'Int',
    required    =>  1,
    builder     => '_timestamp',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
        alt_data_sub    => 'fmt_time',
    },
);

=item C<subject>

 string describing the subject line of the intel

=cut

has subject     => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);


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

    $log->debug("JSON received ".Dumper($json));

    while ( my ($k,$v) =  each %$json ) {
        if ($k eq "cmd") {
            if ($v eq "upvote") {
                $self->add_to_vote($user,"up");
                push @$changes, "Upvote";
            }
            if ($v eq "downvote") {
                $self->add_to_vote($user,"down");
                push @$changes, "Downvote";
            }
            if ($v eq "addtag") {
                foreach my $tag (sort @{$json->{tags}}) {
                    $log->debug("ADDING TAG: $tag");
                    $self->add_to_tags($mongo, $tag);
                    push @$changes, "Added Tag: $tag";
                }
            }
            if ($v eq "rmtag") {
                foreach my $tag (@{$json->{tags}}) {
                    $self->remove_tag($mongo, $tag);
                    push @$changes, "Removed Tag: $tag";
                }
            }
        } 
        else {
            next if ($k eq "tags");
            $log->debug("update $k to $v");
            my $orig = $self->$k;
            $self->$k($v);
            
            local $Data::Dumper::Indent = 0;
            push @$changes,"Changed $k from ".Dumper($orig)." to ". Dumper($v);
        }
    }
    $self->updated($now);
    $self->add_historical_record({
        who     => $mojo->session('user'),
        when    => $now,
        what    => $changes,
    });
}

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
    my $data_href = {};

    $log->debug("building modification command");
    $log->debug("json is ",{filter => \&Dumper, value=>$json});

    while ( my ($k, $v) = each %$json ) {
        if ($k eq "cmd") {
            $log->debug("COMMAND $k FOUND");
            if ($v  eq "upvote") {
                $data_href->{'$addToSet'}->{upvotes}    = $user;
                $data_href->{'$pull'}->{downvotes}      = $user;
                push @$changes, "upvoted";
            }
            if ($v eq "downvote" ) {
                $data_href->{'$addToSet'}->{downvotes}  = $user;
                $data_href->{'$pull'}->{upvotes}        = $user;
                push @$changes, "downvoted";
            }
            if ($v  eq "addtag" ) {
                $log->debug("tags are ".Dumper($json->{tags}));
                $data_href->{'$addToSet'}->{tags}->{'$each'} = $json->{tags};
                foreach my $tag (@{$json->{tags}}) {
                    $self->add_to_tags($mongo, $tag);
                }
                push @$changes, "added these tags: ".join(',',@{$json->{tags}});
            }
            if ($v  eq "rmtag" ) {
                $data_href->{'$pullAll'}->{tags} = $json->{tags};
                foreach my $tag (@{$json->{tags}}) {
                    $self->remove_tag($mongo, $tag);
                }
                push @$changes, "removed these tags: ".join(',',@{$json->{tags}});
            }
        }
        else {
            next if ($k eq "tags") ;
            my $orig    = $self->$k;
            if ($self->constraint_check($k, $v) ) {
                if ( $k ne "text" ) {
                    push @$changes, "changed field $k from $orig";
                    $data_href->{'$set'}->{$k} = $v;
                }
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
        collection  => "intels",
        match_ref   => { intel_id   => $self->intel_id },
        data_ref    => $data_href,
    };
    return $modhref;
}



__PACKAGE__->meta->make_immutable;
1;
__END__

=back

=head1 Web API

=head2 GET /scot/intel

retrieve a list of intels

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
    thing: "intel",
    status: "ok"|"fail",
    stime:  int_unix_epoch,
    data: [
        { json_representation_of_intel1 },
        { json_representation_of_intel2 },
        ...
    ],
    columns: [ colname1, colname2, ... ],
    total_records: int_number_intels_returned
}


=cut

=item B<activemq notification>

{
    action: "view",
    type:   "intel",
}


=cut

=back

=head2 PUT /scot/intel/:id

update intel data for intel :id

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
    thing: "intel",
    status: "ok" | "fail",
    reason: "explanation of fail, otherwise null",
    stime: server time for request in seconds
}


=cut

=item B<activemq notification>

destination: activity queue
{
    action: "update",
    type:   "intel",
    id:     ":id",
    is_task: 1|undef,
    view_count: int,
}


=cut

=back

=head2 POST /scot/intel

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
        thing   : "intel",
        id      : new intel id,
        status  : "ok"|"fail",
        reason  : string,
        stime   : seconds request took on server
    }


=cut

=item B<ActiveMQ notification>


{
    action: "creation",
    type:   "intel",
    id:     int_intel_id,
}


=cut

=back

=head2 DEL /scot/intel/:id

=over 4 

=item B<Params>

none

=item B<Input (JSON)>

none

=cut

=item B<returns JSON>


    {
        title   : "Delete intel",
        action  : "delete",
        thing   : "intel",
        status  : "ok"|"fail",
        reason  : string,
        stime   : seconds request took on server
    }


=cut

=item B<ActiveMQ notification>

{
    action: "deletion",
    type:   "intel",
    id:     int_intel_id,
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

