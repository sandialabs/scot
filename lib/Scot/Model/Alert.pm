package Scot::Model::Alert;

use lib '../../../lib';
use strict;
use warnings;
use v5.10;
use HTML::Entities;

use Scot::Env;
use Moose;
use Moose::Util::TypeConstraints;
use HTML::Entities;
use Data::Dumper;
use namespace::autoclean;

=head1 NAME

 Scot::Model::Alert - a moose obj rep of a Scot Alert

=head1 DESCRIPTION

 Definition of an Alert

=head2 Roles Consumed

    'Scot::Roles::Closeable',
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Entitiable',
    'Scot::Roles::Entriable',
    'Scot::Roles::FileAttachable',
    'Scot::Roles::Hashable',
    'Scot::Roles::Historable',
    'Scot::Roles::Plaintextable',
    'Scot::Roles::Promotable',
    'Scot::Roles::Loggable',
    'Scot::Roles::Permittable', 
    'Scot::Roles::SetOperable',
#    'Scot::Roles::Scot2identifiable',
    'Scot::Roles::Sourceable',
    'Scot::Roles::Statusable',
    'Scot::Roles::Subjectable',
    'Scot::Roles::Taggable',
    'Scot::Roles::ViewTrackable',
    'Scot::Roles::Votable',
    'Scot::Roles::Whenable',
    'Scot::Roles::Searchable'

=cut 

extends 'Scot::Model';

enum 'valid_status', [qw(new open closed promoted revisit second_opinion)];

with (  
    'Scot::Roles::Closeable',
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Entitiable',
    'Scot::Roles::Entriable',
    'Scot::Roles::FileAttachable',
    'Scot::Roles::Hashable',
    'Scot::Roles::Historable',
    'Scot::Roles::Plaintextable',
#    'Scot::Roles::Promotable',
    'Scot::Roles::Loggable',
    'Scot::Roles::Permittable', 
    'Scot::Roles::SetOperable',
#    'Scot::Roles::Scot2identifiable',
    'Scot::Roles::Sourceable',
    'Scot::Roles::Statusable',
    'Scot::Roles::Subjectable',
    'Scot::Roles::Taggable',
    'Scot::Roles::ViewTrackable',
    'Scot::Roles::Votable',
    'Scot::Roles::Whenable',
    'Scot::Roles::Searchable'
);

=head2 Attributes 

=over 4

=item around BUILDARGS

    if you pass a Mojo::Message::Requst in as only parameter
        parse it and then do normal moose instantiation

=cut

around BUILDARGS    => sub {
    my $orig    = shift;
    my $class   = shift;

    if (@_ == 1 && ref $_[0] eq 'Scot::Controller::Handler') {
        my $req     = $_[0]->req;
        my $json    = $req->json;

        # the alert bot determines columns, but the rest api
        # may or may not.  This will set columns based on
        # actual data hash, of course you get hash order
        # if you want to control the order pass in your own col list
        unless (defined $json->{'columns'}) {
            $json->{'columns'} = [keys %{$json->{'data'}}];
        }

        my $href    = {
            sources  => $json->{'sources'} // [],
            status  => 'open',
            subject => $json->{'subject'},
            data    => $json->{'data'},
            tags    => $json->{'tags'}     // [],
            alertgroup=> $json->{'alertgroup'},
            columns => $json->{'columns'},
            env         => $_[0]->env,
            'log'       => $_[0]->app->log,
        };
        my $rg = $json->{'readgroups'};
        my $mg = $json->{'modifygroups'};

        if (scalar(@$rg) > 0) {
            $href->{readgroups} = $rg;
        }

        if (scalar(@$mg) > 0 ) {
            $href->{modifygroups} = $mg;
        }

        if ( $json->{'created'} ) {
            $href->{created} = $json->{'created'};
        }

        return $class->$orig($href);
    }
    # pulls from db will be a hash ref
    # which moose will handle normally
    else {
        my $init_href   = shift;
        # print "initializing alert with : ".Dumper($init_href)."\n";
        my $source      = $init_href->{source};
        unless ( $init_href->{sources} ) {
            $init_href->{sources} = [ $source ];
        }
        return $class->$orig($init_href);
    }
};

=item C<alert_id>

 the integer id for the alert

=cut

has alert_id    => (
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
    default     => 'alert_id',
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
    default     => 'alerts',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<alertgroup>

 holds the id of the alertgroup this alert belongs to.

=cut

has alertgroup    => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1
    },
);

=item C<message_id>

the email unique MSG-ID

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

=item C<parsed>

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


=item C<is_fyi>
 
 (future use)
 some alerts are only that for situational awareness
 this gives the analyst confidence to skip if busy
 and alows entity extraction to take place

=cut
has is_fyi      => (
    is          => 'rw',
    isa         => 'Bool',
    traits      => [ 'Bool' ],
    required    => 1,
    default     => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1
    },
);

=item C<data>

 hash reference to the data extracted from the alert email

=cut

has data        => (
    is          =>  'rw',
    isa         =>  'HashRef',
    traits      =>  ['Hash'],
    required    =>  1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1
    },
);

=item C<data_with_flair>

 values in hash are now flaired,  in other words.  
 Entities are wrapped with special <span></span> for display

=cut

has data_with_flair => (
    is              => 'rw',
    isa             => 'HashRef',
    traits          => [ 'Hash' ],
    required        => 1,
    lazy            => 1,
    builder         => 'flair_the_data',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1
    },
);

=item C<columns>

 the columns parsed from the incoming data
 allows us to control the order of extraction/display
 because hash keys come out unpredictable with the keys function

=cut

has columns     => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => ['Array'],
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);

=item C<events>

 Array of event_id's that this alert was promoted to.

=cut

has events    => (
    is          => 'rw',
    isa         => 'ArrayRef[Int]',
    traits      => ['Array'],
    builder     => '_build_empty_array',
    handles     => {
        add_event   => 'push',
        all_events  => 'elements',
    },
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1
    },
);

=item C<guide_id>

 link to an alert type -> a guide for this type of alert

=cut

has guide_id  => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1
    },
);


=item C<searchtext>

 It is difficult for Mongo to search down through an extend href
 that is in the data attribute.  So we simply concatenate all the
 key/value pairs into a scalar string and then search this field.
 Hackish? Si.

=cut

has searchtext  => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1
    },
);

=item C<triage_ranking>

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

=item C<triage_feedback>

if this is set, the alert triage machinine learning algorithms 
want analyst feedback on this alert.

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
        gridviewable    => 0,
    },
);

=item C<triage_probs>

probability results from the alert triage process

=cut

has triage_probs    => (
    is              => 'rw',
    isa             => 'Maybe[HashRef]',
    required        => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 0,
    },
);


=back

=head2 Methods

=over 4

=cut

sub _build_empty_array {
    my $self    = shift;
    return [];
}

=item C<apply_changes>

 using object methods to update the object
 note you will need to save the object back to the db to retain 
 changes this was the original way to update fields, but proved 
 to be somewhat error prone (array ops, forgeting to save the 
 object after updates).  Also this requires 2 database ops 
 (read object in, and write it back out) so it may be less 
 performant (nice word invention, heh?)

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

            # if data is updated make sure to update data_flair plaintext 
            
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

=item C<build_modification_cmd>

 this function builds a mongodb command to alter the record 
 in the database this is the newer way to update the object.  
 Not for sure which way is best in the long run, so I'm 
 keeping both until I decide.  This method doesn't actually 
 do an update, though.  It gives you a hash_ref that when passed
 to Scot::Util::Mongo->apply_update will update the database 
 document.

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
    my $data_href = {};

    $log->debug("Building modification Command");
    $log->debug("json is ". Dumper($json));

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
                    if ( $k eq "status" ) {
                        if ($v eq "closed" and $self->status eq "promoted") {
                            next;
                        }
                    }
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
        collection  => "alerts",
        match_ref   => { alert_id   => $self->alert_id },
        data_ref    => $data_href,
    };
    return $modhref;
}


=item C<flair_the_data>

 this function send the daa off to the phantomjs webservice for 
 "flairing" really just a compatability wrapper around 
 extract_entities

=cut

sub flair_the_data {
    my $self    = shift;
    my $data    = $self->data;
    my $log     = $self->log;
    $log->debug("Flairing the data field");
    return $self->extract_entities;
}

=item C<extract_entities>

 examine data attribute for entities 
 and update entities collection

=cut

sub extract_entities {
    my $self        = shift;
    my $env         = $self->env;
    my $log         = $self->log;
    my $mongo       = $env->mongo;
    # my $phantom     = $env->phantom;
    my $extractor     = $env->entity_extractor;
    
    my %entities;
    my @ents;
    my $href = {};

    
    #Flair the data part of the entry
    while ( my ($k, $v) = each %{$self->data} ) {
        my $encoded = $v;
        if($self->parsed) {
          $encoded = encode_entities($v);
        }
        if ( $k =~ /^message_id$/i ) {
            # this means it is a special splunk column for message id 
            $href->{$k} = $v;
            push @ents, {value => $v, type => "message_id" };
        }
        else {
            my $eeref = $extractor->process_html($encoded);
            my $f     = $eeref->{flair};
            my $p     = $eeref->{text};
            my $e_aref = $eeref->{entities};
            $href->{$k} = $f;
            foreach my $ehref (@$e_aref) {
                unless ( defined $entities{$ehref->{value}} ) {
                    push @ents, $ehref;
                    $entities{$ehref->{value}}++;
                }
            }
        }
    }
    
    $log->debug("got these entities: ".Dumper(\@ents));
    $self->add_self_to_entities(\@ents);

    if ( $self->alertgroup) {
        $log->debug("adding entities to alertgroup ".$self->alertgroup);
        foreach my $e (@ents) {
            $log->debug("adding $e to redis");
            $env->redis->add_entity_targets(
                $e->{value},"alertgroups", $self->alertgroup);
        }
    }
    return $href;
}

=item C<remove_self_from_entities>

I think that this has been moved to the Role Entitiable.
Anyway, don't rely on this.  Will investigate...

=cut

sub remove_self_from_entities {
    my $self    = shift;
    my $mongo   = shift;
    my $log     = $self->log;

    my $target_type     = "alerts";
    my $target_id       = $self->alert_id;

    my $update_href     = {
        collection  =>  "entities",
        match_ref   => { alerts   => $self->alert_id, },
        data_ref    => {
            '$pull' => { $target_type => $target_id },
        },
    };
    $log->debug("REMOVING SELF FROM ENITIES");
    $log->debug(Dumper($update_href));
    $mongo->apply_update($update_href,{ multiple => 1, safe => 1});
}

=item C<update_alertgroup>

update the alert dependent fields within an alertgroup.

=cut

sub update_alertgroup {
    my $self    = shift;
    my $mongo   = shift;
    my $log     = $self->log;

    $log->debug("updating alertgroup");

    my $alertgroup_object   = $self->get_my_alertgroup($mongo);

    $alertgroup_object->log     ($log);
    $alertgroup_object->add_alert($self->alert_id);
    $alertgroup_object->open    ( $self->get_count($mongo, "open") );
    $alertgroup_object->closed  ( $self->get_count($mongo, "closed") );
    $alertgroup_object->promoted( $self->get_count($mongo, "promoted") );
    $alertgroup_object->total   ( $self->get_count($mongo, "total") );
    $alertgroup_object->status  ( $alertgroup_object->determine_status );

    $mongo->update_document($alertgroup_object);
}

=item C<get_my_alertgroup>

get the alertgroup object from the DB or created a new one if nothing
matches in the db.  returns the ref to that object.

=cut 

sub get_my_alertgroup {
    my $self            = shift;
    my $mongo           = shift;
    my $alertgroup_id   = $self->alertgroup;
    my $log             = $self->log;
    my $alertgroup_object;


    if ( defined $alertgroup_id ) {
        $log->debug("Looking for alertgroup_id $alertgroup_id.");
        # we have an alertgroup_id, lets get it from the db
        $alertgroup_object  = $mongo->read_one_document({
            collection  => "alertgroups",
            match_ref   => { alertgroup_id  => $alertgroup_id },
        });
        if ( defined $alertgroup_object ) {
            return $alertgroup_object;
        }
        else {
            $log->error("No matching alertgroup with id $alertgroup_id");
            $log->error("will create new alertgroup with id $alertgroup_id");
        }
    }
    
    my $ag_href     = {
        when        => $self->when,
        updated     => $self->updated,
        status      => $self->status,
        subject     => $self->subject,
        sources      => $self->sources // [],
        tags        => $self->tags,
        events      => $self->events // [],
    };
    $log->debug("Creating Alertgroup with ".Dumper($ag_href));
    if ( $alertgroup_id ) {
        $ag_href->{alertgroup_id}    = $alertgroup_id;
        $alertgroup_object      = Scot::Model::Alertgroup->new($ag_href);
        $alertgroup_id          = $mongo->create_document($alertgroup_object,-1);
    }
    else {
        $alertgroup_object      = Scot::Model::Alertgroup->new($ag_href);
        $alertgroup_id          = $mongo->create_document($alertgroup_object);
        $alertgroup_object->alertgroup_id($alertgroup_id);
    }
    $log->debug("Alertgroup ".$alertgroup_object->alertgroup_id." created");
    return $alertgroup_object;
}

=item C<get_count($mongo_ref, $status)>

return the number of alerts matching the given status

=cut

sub get_count {
    my $self    = shift;
    my $mongo   = shift;
    my $status  = shift;

    my $cursor  = $mongo->read_documents({
        collection  => "alerts",
        match_ref   => {
            alertgroup  => $self->alertgroup,
            status      => $status,
        },
    });
    return $cursor->count;
}

=item C<make_data_entry>

when promoting an alert, this takes the data attribute and creates 
an html version of the data.

=cut

sub make_data_entry {
    my $self    = shift;
    my $columns = $self->columns;
    my $data    = $self->data;

    if ($data->{search}) {
        unshift(@$columns, "search");
    }

    my $table  = qq|<table class="alert_data_entry">|;

    foreach my $column (@$columns) {
        $table  .= qq| <tr><th>$column</th><td>$data->{$column}</td></tr> |;
    }
    $table .= qq|</table>|;
    return $table;
}

sub make_data_row {
    my $self    = shift;
    my $columns = $self->columns;
    my $data    = $self->data;

    my $row     = qq|<tr>|;
    foreach my $column (@$columns) {
        if ($column =~ /^message_id$/i ) {
            $row    .=  qq|<td><div class="alert_data_cell">|.
                        $data->{$column}.
                        qq|</div></td>|;
        }
        else {
            $row    .=  qq|<td><div class="alert_data_cell">|.
                        encode_entities($data->{$column}).
                        qq|</div></td>|;
        }
    }
    $row    .= qq|</tr>|;
    return $row;
}

sub make_data_header {
    my $self    = shift;
    my $columns = $self->columns;
    my $data    = $self->data;

    my $row = qq|<tr>|;
    foreach my $column (@$columns) {
        $row    .= qq|<th>$column</th>|;
    }
    $row    .= qq|</tr>|;
    return $row;
}

sub get_splunk_search {
    my $self    = shift;
    my $data    = $self->data;

    if ( $data->{search} ) {
        return  qq|<table><tr><th>splunk search</th><td>|.
                $data->{search} .qq|</td></tr></table>|;
    }
    return "";
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

    foreach my $collection (qw(events)) {
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

