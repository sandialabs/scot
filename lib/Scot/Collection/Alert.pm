package Scot::Collection::Alert;
use lib '../../../lib';
use v5.16;
use Moose 2;
use MooseX::AttributeShortcuts;
use Type::Params qw/compile/;
use Types::Standard qw/slurpy :types/;
use Data::Dumper;

=head1 Name

Scot::Collection::Alert

=head1 Description

Collection methods for Alerts

=head1 Extends

Scot::Collection

=head1 Consumed Roles

Scot::Role::GetByAttr
Scot::Role::GetTagged

=cut

extends 'Scot::Collection';

with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

=head1 Methods

=over 4

=item B<api_create($req_href)>

a post to the api will land here

=cut

override api_create => sub {
    my $self        = shift;
    my $req_href    = shift;
    my $env         = $self->env;
    my $log         = $self->log;

    $log->debug("creating alert from api");

    my $json    = $req_href->{request}->{json};

    my $alert   = $self->create($json);
    return $alert;

};

=item B<linked_create($href)>

the request to create an alertgroup with embedded alerts in the data attribute
calls this

=cut

sub linked_create {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $self->log;

    $log->debug("in linked_create for alert");

    my $data    = $href->{data};
    if ( ! defined $data ) {
        $log->error("empty data field in api create request!");
        return 0;
    }

    my $agid    = $href->{alertgroup};
    if ( ! defined $agid ) {
        $log->error("alerts must have a parent alertgroup id");
        return 0;
    }

    my $columns = $href->{columns};
    if ( ! defined $columns ) {
        $log->error("alerts must have columns defined");
        return 0;
    }
    if ( ref($columns) ne "ARRAY" ) {
        $log->error("columns must be an array!");
        return 0;
    }


    my $ref    = {
        data        => $data,
        subject     => $href->{subject},
        alertgroup  => $agid,
        status      => 'open',
        columns     => $columns,
    };

    $log->debug("attempting to create alert: ");
    $log->trace({filter=>\&Dumper, value=>$ref});

    my $alert = $self->create($ref);

    if ( ! defined $alert ) {
        $log->error("failed to create alert!");
        return 0;
    }

    $self->env->mq->send("/queue/emlat", {
        action  => "created",
        data    => {
            who     => 'scot',
            type    => 'alert',
            id      => $alert->id,
        }
    });

    return 1;
}

# updating an Alert can cause changes in the alertgroup

=item B<update($obj, $update)>

=cut

override 'update'   => sub {
    state $check    = compile( Object, Object, HashRef );
    my ( $self,
         $obj,
         $update )  = $check->(@_);

    # causing deprecation warning
    #my $data        = $self->_try_mongo_op(
    #    update  => sub {
    #        $self->_mongo_collection->find_and_modify({
    #            query   => { _id    => $obj->_id },
    #            update  => $update,
    #            new     => 1,
    #        });
    #    },
    #);

    my $data    = $self->_try_mongo_op(
        update  => sub {
            $self->_mongo_collection->find_one_and_update(
                { _id   => $obj->_id },
                $update,
                { upsert => 1, returnDocument => "after" }
            )
        },
    );

    if ( ref $data ) {
        $self->_sync( $data => $obj );
        ## doing this manually in Scot::Collection::Event::build_from_alerts
        # alert has synced to database
        # update the alertgroup data
        $self->update_alertgroup_data($obj);
        return 1;
    }
    else {
        $obj->_set_removed(1);
        return;
    }
};

sub update_alertgroup_data {
    my $self    = shift;
    my $obj     = shift;
    my $mongo   = $self->meerkat;

    my $alertgroup_id   = $obj->alertgroup;

    my $agcol   = $mongo->collection("Alertgroup");

    $agcol->refresh_data($alertgroup_id);

}

sub get_alerts_in_alertgroup {
    my $self    = shift;
    my $id      = shift;
    $id         += 0;       # argh! otherwise it tries string match
    my $cursor  = $self->find({alertgroup => $id});
    return $cursor;
}

sub api_subthing {
    my $self    = shift;
    my $req     = shift;
    my $mongo   = $self->meerkat;

    my $thing       = $req->{collection};
    my $id          = $req->{id}+0;
    my $subthing    = $req->{subthing};

    $self->log->trace("api_subthing: /$thing/$id/$subthing");

    if ( $subthing eq "entry" ) {
        return $mongo->collection('Entry')->get_entries_by_target({
            id      => $id,
            type    => 'alert',
        });
    }

    if ( $subthing eq "entity" ) {
        return $mongo->collection('Link')
                     ->get_linked_objects_cursor(
                        { id  => $id, type => 'alert' },
                        'entity');
    }
    if ( $subthing eq "link" ) {
        return $mongo->collection('Link')
                    ->get_links_by_target({
                        id      => $id,
                        type    => $thing,
                    });
    }
    if ( $subthing eq "event" ) {
        return $mongo->collection('Event')->find({promoted_from => $id});
    }
    if ( $subthing eq "file" ) {
        return $mongo->collection('File')->find({
            'entry_target.type' => 'alert',
            'entry_target.id'   => $id,
        });
    }
    if ( $subthing eq "tag" ) {
        my @appearances = map { $_->{apid} } 
            $mongo->collection('Appearance')->find({
                type    => 'tag', 
                'target.type'   => 'alert',
                'target.id'     => $id,
            })->all;
        return $mongo->collection('Tag')->find({
            id => {'$in' => \@appearances}
        });
    }

    if ( $subthing eq "source" ) {
        my @appearances = map { $_->{apid} } 
            $mongo->collection('Appearance')->find({
                type    => 'source', 
                'target.type'   => 'alert',
                'target.id'     => $id,
            })->all;
        return $mongo->collection('Source')->find({
            id => {'$in' => \@appearances}
        });
    }

    if ( $subthing eq "history" ) {
        return $mongo->collection('History')->find({
            'target.type'   => 'alert',
            'target.id'     => $id,
        });
    }

    die "Unsupported alert subthing: $subthing";

}

sub update_alert_status {
    my $self    = shift;
    my $id      = shift;
    my $status  = shift;
    my $targets = shift;
    my $env     = $self->env;
    my $log     = $self->log;
    my @ids     = ();

    $log->debug("attempting updating alert status");

    unless ( grep { /$status/ } (qw(open closed promoted)) ) {
        $log->error("Invalid Alert Status set attempt: $status");
        return;
    }

    my $cur = $self->find({ alertgroup  => $id + 0 });

    unless ( $cur ) {
        $log->error("failed to find any alerts for alertgroup $id");
        return;
    }

    my @aidlist = ();
    if ( defined($targets) ) {
        @aidlist = map { $_ + 0 } @$targets;
    }

    $log->debug("updating alert status");

    ALERT:
    while ( my $alert = $cur->next ) {
        my $aid = $alert->id + 0;
        if ( defined($targets) ) {
            unless ( grep { $_ == $aid } @aidlist ) {
                next ALERT;
            }
        }
        $alert->update_set( status => $status );
        push @ids, $alert->id +0;
    }
    return wantarray ? @ids : \@ids;
}
sub update_alert_parsed {
    my $self    = shift;
    my $id      = shift;
    my $status  = shift;
    my $targets = shift;
    my $env     = $self->env;
    my $log     = $self->log;
    $status     += 0;
    my @ids     = ();

    $log->debug("attempting updating alert status");

    unless ( $status == 0 or $status == 1 ) {
        $log->error("Invalid Alert parsed set attempt: $status");
        return;
    }

    my $cur = $self->find({ alertgroup  => $id + 0 });

    unless ( $cur ) {
        $log->error("failed to find any alerts for alertgroup $id");
        return;
    }

    my @aidlist = ();
    if ( defined($targets) ) {
        @aidlist = map { $_ + 0 } @$targets;
    }

    $log->debug("updating alert parsed status");

    ALERT:
    while ( my $alert = $cur->next ) {
        my $aid = $alert->id + 0;
        if ( defined($targets) ) {
            unless ( grep { $_ == $aid } @aidlist ) {
                next ALERT;
            }
        }
        $alert->update_set( parsed => $status );
        $log->debug("reset parsed on alert $aid");
        push @ids, $aid;
    }
    return wantarray ? @ids : \@ids;
}

# override get_subthing => sub {
#     my $self    = shift;
#     my $thing   = shift;
#     my $id      = shift;
#     my $subthing    = shift;
#     my $env     = $self->env;
#     my $mongo   = $self->meerkat;
#     my $log     = $self->log;
# 
#     $id += 0;
# 
#     if ( $subthing eq "alertgroup" ) {
#         my $col   = $mongo->collection('Alert');
#         my $alert = $col->find_iid($id);
#         my $agid  = $alert->alertgroup;
#         $col      = $mongo->collection('Alertgroup');
#         my $cur   = $col->find({id => $agid});
#         return $cur;
#     }
#     else {
#         $log->error("unsupported subthing $subthing!");
#     }
# };

=back

=cut

1;
