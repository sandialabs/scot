package Scot::Model::Alertgroup;

use lib '../../lib';
use strict;
use warnings;
use v5.10;

use Moose;
use Moose::Util::TypeConstraints;
use Data::Dumper;
use namespace::autoclean;

=head1 NAME

 Scot::Model::Alertgroup - a moose obj rep of a Scot Alert Groups

=head1 DESCRIPTION

 Definition of an Alertgroup
 this collection will be displayed in the alertgrid
 and hopefully solve some of the problems with grouping alerts

=cut

=head2 Roles Consumed

    'Scot::Roles::Closeable',
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Entitiable',
    'Scot::Roles::Entriable',
    'Scot::Roles::Hashable',
    'Scot::Roles::Loggable',
    'Scot::Roles::Permittable',
    'Scot::Roles::Promotable',
    'Scot::Roles::SetOperable',
    'Scot::Roles::Sourceable',
    'Scot::Roles::Taggable',
    'Scot::Roles::Timestampable',
    'Scot::Roles::ViewTrackable',

=cut 

extends 'Scot::Model';
with    (  
    'Scot::Roles::Closeable',
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Entitiable',
    'Scot::Roles::Entriable',
    'Scot::Roles::Hashable',
    'Scot::Roles::Historable',
    'Scot::Roles::Loggable',
    'Scot::Roles::Permittable',
#    'Scot::Roles::Promotable',
    'Scot::Roles::SetOperable',
    'Scot::Roles::Sourceable',
    'Scot::Roles::Taggable',
    'Scot::Roles::Timestampable',
    'Scot::Roles::ViewTrackable',
);


=head2 Attributes

=over 4

=item B<alertgroup_id>

 the integer id for the alertgroup
 why oid and id? convenience and ease of use

=cut
has alertgroup_id    => (
    is          => 'rw',
    isa         => 'Int',
    required    =>  0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1
    },
);

=item B<idfield>

 since my integer id fields in models include the model name in them 
 instead of just "id", this field gives us an easy way to figure out
 what the id attribute is.  We can debate the original choice later...

=cut

has idfield => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'alertgroup_id',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item B<collection>

 easy way to keep track of object to collection mapping.  
 We can debate the original choice later...

=cut

has collection => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'alertgroups',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item B<message_id>

This is the Email header MSG-ID that uniquely id's the incoming 
email.  Store this so we don't reprocess the same email more than once

=cut

has message_id  => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 1,
    default     => 'Unspecified',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

=item B<when>

 user settable field as opposed to created, updated, 
 why?  This will allow a user to change the display order using 
 a sort on this field.  Also sometimes times need to be revised 
 when better info comes in.

=cut

has when        => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    builder     => '_timestamp',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
        alt_data_sub    => 'fmt_time',
    },
);

=item B<alert_ids>

 array of alert_id's that are in the alertgroup

=cut

has alert_ids   => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => ['Array'],
    required    => 1,
    builder     => '_empty_array',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1,
    },
);

sub _empty_array {
    return [];
}

=item B<events>

 the event_id's that alerts in this alertgroup have been promoted to.

=cut

has events   => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => ['Array'],
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1,
    },
);


=item B<status>

 from valid_status type above, ...

=cut
has status      => (
    is          =>  'rw',
    isa         =>  'Str',
    default     =>  'open',
    required    =>  1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item B<open>

 number of open alerts in alertgroup

=cut
has open    => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    default     => 0,
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item B<closed>

 number of closed alerts in alertgroup
 
=cut

has closed    => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    default     => 0,
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item B<promoted>

 number of promoted alerts in alertgroup

=cut

has promoted    => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    default     => 0,
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item B<total>

 number of alerts in alertgroup

=cut

has total => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    default     => 0,
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item B<subject>

 string describing the subject line of the alert

=cut

has subject     => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);

=item B<guide_id>

 int id of the guide for this alerttype

=cut

has guide_id    => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1
    },
);


=item B<parsed>

  Was this alertgroup parsed into the data hash field (true), or fallback to html(false)

=cut

has parsed   => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
       gridviewable   => 1,
       serializable   => 1
    },
);

=item B<view_count>

 count of the number of views

=cut

has view_count   => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);

=item B<body_html>

store the original html version of the email
in case there are parsing problms the analysts will not have
to dive back into the email client.

=cut

has body_html  => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1
    },
);

=item B<body_plain>

store the original plaintext version of the email
in case there are parsing problms the analysts will not have
to dive back into the email client.

=cut

has body_plain  => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1
    },
);

=item B<triage_ranking>

the alert triage ranking

=cut

has triage_ranking  => (
    is              => 'rw',
    isa             => 'Num',
    required        => 0,
    default         => -1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item B<triage_feedback>

if this is set, the alert feedback on this alert.

=cut

has triage_feedback => (
    is              => 'rw',
    isa             => 'Bool',
    traits          => ['Bool'],
    required        => 0,
    default         => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);
    
=back

=head2 Methods

=over 4

=item B<around BUILDARGS>

3.0 SCOT put string "source" attributes in the DB.
3.1 wants an array.
This will convert the incoming source string into the sources array.

=cut

around BUILDARGS    => sub {
    my $orig    = shift;
    my $class   = shift;

    if ( @_ == 1 && ref $_[0] eq 'Scot::Controller::Handler' ) {
        my $req     = $_[0]->req;
        my $json    = $req->json;
        my $href    = {
            sources => $json->{sources},
            subject => $json->{subject},
            tags    => $json->{tags},
            env     => $_[0]->env,
            'log'   => $_[0]->app->log,
        };
        my $rg  = $json->{readgroups};
        my $mg  = $json->{modifygroups};
        if ( scalar(@$rg) > 0 ) {
            $href->{readgroups} = $rg;
        }
        if ( scalar(@$mg) > 0 ) {
            $href->{modifygroups} = $mg;
        }
        return $class->$orig($href);
    } 
    else {
        my $input_href      = shift;
        my $string_source   = $input_href->{source};
        my $aref_source     = $input_href->{sources};

        unless ( defined $aref_source ) {
            $input_href->{sources} = [ $string_source ];
        }
        return $class->$orig($input_href);
    }
};


=item B<build_modification_cmd>

Two ways to modify an object.  This way modifies the object in situ on the
database.  The env is passed to method and it builds a mongodb
update command and returns it to you.  you can then use the Scot::Util::Mongo
method $mongo->apply_update($returned_mod_cmd, $opts_ref) to execute the 
change

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
    my @changes = ();
    my %data    = ();

    $log->debug("BUILDING MODIFICATION FOR ALERTGROUP");
    $log->debug("json is ".Dumper($json));

    while ( my ($k, $v) = each %$json ) {

        $log->debug("k = $k, v = $v");

        if ( $k eq "cmd" ) {
            if ( $v eq "upvote" ) {
                $data{alerts}{data_ref}{'$addToSet'}{upvotes}   = $user;
                $data{alerts}{data_ref}{'$pull'}    {downvotes} = $user;
                push @changes, "upvoted";
            }
            if ( $v eq "downvote" ) {
                $data{alerts}{data_ref}{'$addToSet'}{downvotes}    = $user;
                $data{alerts}{data_ref}{'$pull'}    {upvotes}      = $user;
            }
            if ( $v eq "addtag" ) {
                $data{alertgroups}{data_ref}
                     {'$addToSet'}{tags}{'$each'} = $json->{tags};
                $data{alerts}{data_ref}
                     {'$addToSet'}{tags}{'$each'} = $json->{tags};
                foreach (@{$json->{tags}}) { 
                    $self->add_to_tags($mongo, $_); 
                }
                push @changes, "added tags: ".join(',', @{$json->{tags}});
            }
            if ( $v eq "rmtag" ) {
                $data{alertgroups}{data_ref}{'$pull'}{tags}    = $json->{tags};
                $data{alerts}     {data_ref}{'$pull'}{tags}    = $json->{tags};
                foreach (@{$json->{tags}}) { 
                    $self->remove_tag($mongo, $_); 
                }
                push @changes, "removed these tags: ".join(',', @{$json->{tags}});
            }
            if ( $v eq "addsource" ) {
                $data{alertgroups}{data_ref}
                     {'$addToSet'}{sources}{'$each'} = $json->{sources};
                $data{alerts}{data_ref}
                     {'$addToSet'}{sources}{'$each'} = $json->{sources};
                foreach (@{$json->{sources}}) {
                    $self->add_to_sources($mongo, $_);
                }
                push @changes, "added sources: ".join(',', @{$json->{sources}});
            }
            if ( $v eq "rmsource" ) {
                $data{alertgroups}{data_ref}{'$pull'}{sources}    = $json->{sources};
                $data{alerts}     {data_ref}{'$pull'}{sources}    = $json->{sources};
                foreach (@{$json->{sources}}) { 
                    $self->remove_source($mongo, $_); 
                }
                push @changes, "removed these sources: ".join(',', @{$json->{sources}});
            }

        }
        else {
            next if ( $k eq "tags" );
            my $orig    = $self->$k;
            local $Data::Dumper::Indent=0;
            $log->debug("Trying to update $k from ".Dumper($orig) ." to ". Dumper($v));
            if ( $self->constraint_check($k, $v) ) {
                if ( $k ne "text" ) {
                    $log->debug("setting $k to $v");
                    if ($k eq "closed") { $v = $v + 0; }
                    push @changes, "changed $k from $orig";
                    $data{alerts}{data_ref}{'$set'}{$k} = $v;
                    $data{alertgroups}{data_ref}{'$set'}{$k} = $v;
                }
                else {
                    $log->error("changing text of subalerts not supported");
                }
            }
            else {
                $log->error("Value $v failed constraint check for $k!");
                $log->error("Requested update ignored");
            }
        }
    }
    $data{alertgroups}{data_ref}{'$set'}{updated} = $now;
    $data{alerts}     {data_ref}{'$set'}{updated} = $now;
    $data{alerts}     {data_ref}{'$addToSet'}{history} = {
        who     => $user,
        when    => $now,
        what    => join(', ',@changes),
    };
    my $agid    = $self->alertgroup_id + 0;
    $data{alertgroups}{match_ref} = { alertgroup_id => $agid+0 };
    $data{alertgroups}{collection}= "alertgroups";
    $data{alerts}     {match_ref} = { 
        alertgroup    => $agid,
    #    status        => { '$ne'    => "promoted" },
    };
    $data{alerts}     {collection}= "alerts";

    $log->debug("Resultant modification command : ");
    $log->debug(Dumper(\%data));
    return \%data;
}

=item B<add_alert>

add an alert_id to the alert_ids array_ref attribute
relies on Scot::Roles::SetOperable

=cut

sub add_alert {
    my $self    = shift;
    my $id      = shift;
    $self->add_to_set("alert_ids", [ $id ], 1); # from SetOperable.pm
}

=item B<determine_status>

Looks at the number open, closed, and promoted alerts that are members
of this alertgroup and returns the following:

    closed      if all alerts are closed
    open        if any alert is open and no alert(s) have been promoted
    promoted    if any alert has been promoted

=cut

sub determine_status {
    my $self    = shift;
    my $status  = "closed";
    my $opencount       = $self->open // 0;
    my $promotedcount   = $self->promoted // 0;

    if ( $opencount > 0 ) {
        $status = "open";
    }
    if ( $promotedcount > 0 ) {
        $status = "promoted";
    }
    return $status;
}

=item B<get_my_alerts>

    querries the db for all alerts that are part of this alertgroup.
    sets the alert_ids attribute with the current membership
    returns two array_refs:
        data        :   hashes of the alerts
        displaycols :   column names in the alert set

=cut

sub get_my_alerts {
    my $self        = shift;
    my $env         = shift;
    my $mongo       = $env->mongo;

    my $cursor  = $mongo->read_documents({
        collection  => "alerts",
        match_ref   => { alertgroup => $self->alertgroup_id },
        sort_ref    => { alert_id => 1 },
    });

    my @ids;
    my @data;
    my @entities;
    my @entries;
    my @displaycols;
    my $entity_data_href;

    while ( my $alert_object   = $cursor->next ) {
        $alert_object->env($env);
        my $href    = $alert_object->as_hash;
        if ( scalar(@displaycols)<0 ) {
            @displaycols = keys %$href;
        }
        push @data, $href;
        push @ids, $alert_object->alert_id;
    }
    $self->alert_ids(\@ids);
    return \@data, \@displaycols;
}

=item B<refresh_ag_data>

refreshes the grid display fields for the alertgroup if any thing
changes in the alertgroupset.  For example, someone promotes an alert,
the alertgroup status would be updated to "promoted" as well.

=cut

sub refresh_ag_data {
    my $self        = shift;
    my $env          = shift;
    my $mongo       = $env->mongo;
    my $log         = $self->log;

    my $cursor  = $mongo->read_documents({
        collection  => "alerts",
        match_ref   => { alertgroup => $self->alertgroup_id },
    });

    my @alert_ids;
    my @entries;
    my @tags;
    my ($open, $closed, $promoted, $total);
    my $triage_rank = $self->triage_ranking;

    while ( my $alert_object    = $cursor->next ) {
        $alert_object->env($env);

        push @alert_ids,  $alert_object->alert_id;
        $self->add_to_set("tags", $alert_object->tags, 1); # from SetOperable.pm
        $total++;
        $open ++        if ( $alert_object->status eq "open");
        $closed ++      if ( $alert_object->status eq "closed");
        $promoted ++    if ( $alert_object->status eq "promoted");
        if ( $alert_object->triage_ranking > $triage_rank) {
            $triage_rank = $alert_object->triage_ranking;
        }
    }
    $self->alert_ids(\@alert_ids);
    $self->open($open);
    $self->closed($closed);
    $self->promoted($promoted);
    $self->total($total);
    $self->status($self->determine_status);
    $self->triage_ranking($triage_rank);
}

sub remove_self_from_references {
    my $self    = shift;
    my $mongo   = shift;
    my $log     = $self->log;
    my $thiscollection = $self->collection;
    my $idfield     = $self->idfield;
    my $id          = $self->$idfield;
    my $match_ref   = { $thiscollection => $id };
    my $data_ref    = { '$pull' => { $thiscollection => $id } };
    my $opts_ref    = { multiple => 1, safe => 1 };

    return; # alertgroup references do not exist elsewhere
    
# but if that changes, here's code that will help

    foreach my $collection (qw(alertgroups alerts incidents)) {
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

=back

=cut

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 Web API

=head2 GET /scot/alertgroup

retrieve a list of alertgroups

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
    title: "Alertgroup list",
    action: "get",
    thing: "alertgroup",
    status: "ok"|"fail",
    stime:  int_unix_epoch,
    data: [
        { json_representation_of_alert1 },
        { json_representation_of_alert2 },
        ...
    ],
    columns: [ colname1, colname2, ... ],
    total_records: int_number_alertgroups_returned
}


=cut

=item B<activemq notification>


{
    action: "view",
    type:   "alertgroup",
}


=cut

=back

=head2 PUT /scot/alertgroup/:id

update alertgroup data for alertgroup :id

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
    title: "Update Alertgroup :id",
    action: "update",
    thing: "alertgroup",
    status: "ok" | "fail",
    reason: "explanation of fail, otherwise null",
    stime: server time for request in seconds
}


=cut

=item B<activemq notification>

destination: activity queue
{
    action: "update",
    type:   "alertgroup",
    id:     ":id",
    is_task: 1|undef,
    view_count: int,
}


=cut

=back

=head2 POST /scot/alertgroup

=over 4 

=item B<Params>

none

=cut

=item B<Input (JSON)>


{
    sources: [ "source1", ... ],
    subject: "subject string",
    alertgroup: int or omit to take next available,
    tags:    [ "tag1", "tag2", ... ],
    data: [
        { text: "this is alert1", value: 1, key1: value1, ... },
        ...
    ],
    columns: [ "text", "value", "key1" ],
    readgroups: [ "groupname1", ... ], # or omit for default
    modifygroups: [ "groupname2", ...], # or omit for default
}


=cut

=item B<returns JSON>


    {
        action  : "post",
        thing   : "alertgroup",
        id      : new alertgroup id,
        status  : "ok"|"fail",
        reason  : string,
        stime   : seconds request took on server
    }


=cut

=item B<ActiveMQ notification>


{
    action: "creation",
    type:   "alertgroup",
    id:     int_alertgroup_id,
}


=cut

=back

=head2 DEL /scot/alertgroup/:id

=over 4 

=item B<Params>

none

=item B<Input (JSON)>

none

=cut

=item B<returns JSON>


    {
        title   : "Delete alertgroup",
        action  : "delete",
        thing   : "alertgroup",
        status  : "ok"|"fail",
        reason  : string,
        stime   : seconds request took on server
    }


=cut

=item B<ActiveMQ notification>

{
    action: "deletion",
    type:   "alertgroup",
    id:     int_alertgroup_id,
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

=item L<Scot::Controller::Model>

=item L<Scot::Util::Mongo>

=item L<Scot::Roles::SetOperable>

=back

