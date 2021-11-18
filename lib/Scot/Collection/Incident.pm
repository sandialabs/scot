package Scot::Collection::Incident;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

=head1 Name

Scot::Collection::File

=head1 Description

Custom collection operations for Files

=head1 Methods

=over 4

=item B<api_create($handler_ref)>

Create an event and from a POST to the handler

=cut

override api_create => sub {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $self->log;
    my $mongo   = $self->meerkat;

    $log->trace("Custom create in Scot::Collection::Incident");

    my $user    = $request->{user};
    my $json    = $request->{request}->{json};

    my @tags    = $env->get_req_array($json, "tags");

    $self->validate_permissions($json);

    my $incident    = $self->create($json);

    unless ($incident) {
        $log->error("ERROR creating Incident from ",
                    { filter => \&Dumper, value => $request});
        return undef;
    }

    my $id  = $incident->id;

    if ( scalar(@tags) > 0 ) {
        $self->upssert_links("Tag", "incident", $id, @tags);
    }
    $self->create_incident_summary($request, $incident);


    return $incident;
};

sub create_incident_summary {
    my $self        = shift;
    my $request     = shift;
    my $incident    = shift;
    my $env         = $self->env;
    my $log         = $self->log;
    my $mongo       = $self->meerkat;

    $log->debug("creating incident summary entry");

    my $envmeta         = $env->meta;
    my $summary_method  = $envmeta->get_method("incident_summary_template");

    if ( defined $summary_method ) {
        my $template    = $env->incident_summary_template;
        my $entrycol    = $mongo->collection('Entry');
        my $href        = {
            user    => $request->{user},
            class   => "summary",
            parent  => 0,
            target  => {
                type    => "incident",
                id      => $incident->id,
            },
            body        => $env->incident_summary_template,
        };
        $log->debug("with data ",{filter=>\&Dumper, value=>$href});
        my $entry = $entrycol->create($href);
        if (! defined $entry) {
            $log->error("failed to create summary entry");
        }
        else {
            $log->debug("entry ".$entry->id." created");
        }
    }
    else {
        $log->warn("incident_summary_template not defined.  please add to scot.cfg.pl");
    }
}

sub create_promotion {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $user    = $req->{user};

    my $subject         = $object->subject // $self->get_value_from_request($req, "subject");
    my $href    = {
        subject     => $subject,
        owner       => $user,
    };

    my $incident = $self->create($href);
    $self->create_incident_summary($req, $incident);
    return $incident;
}

sub get_promotion_obj {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $promotion_id    = $req->{request}->{json}->{promote}
                          // $req->{request}->{params}->{promote};
    my $incident;
    if ( $promotion_id =~ /\d+/ ) {
        $incident = $self->find_iid($promotion_id);
        if ( defined $incident and ref($incident) eq "Scot::Model::Incident") {
            return $incident;
        }
        else {
            die "Incident $promotion_id does not exist, can not promote to non-existing incident";
        }
    }
    if ($promotion_id eq "new" or ! defined $promotion_id ) {
        $incident = $self->create_promotion($object, $req);
        return $incident;
    }

    die "Invalid promotion id";
}


sub api_subthing {
    my $self    = shift;
    my $req     = shift;
    my $mongo   = $self->meerkat;
    my $log     = $self->log;

    my $thing       = $req->{collection};
    my $subthing    = $req->{subthing};
    my $id          = $req->{id}+0;

    if ( $subthing eq "event" ) {
        return $mongo->collection('Event')->find({
            promotion_id    => $id
        });
    }

    if ( $subthing eq "entry" ) {
        return $mongo->collection('Entry')->get_entries_by_target({
            id      => $id,
            type    => 'incident',
        });
    }

    if ( $subthing eq "entity" ) {
        return $mongo->collection('Link')
                     ->get_linked_objects_cursor(
                        { id => $id, type => "incident" },
                        "entity"
                    );
    }
    if ( $subthing eq "link" ) {
        return $mongo->collection('Link')
                    ->get_links_by_target({
                        id      => $id,
                        type    => $thing,
                    });
    }

    if ( $subthing eq "tag" ) {
        my @appearances = map { $_->{apid} }
            $mongo->collection('Appearance')->find({
                type            => 'tag',
                'target.type'   => 'event',
                'target.id'     => $id,
            })->all;
        return $mongo->collection('Tag')->find({
            id  => { '$in' => \@appearances }
        });
    }
    if ( $subthing eq "source" ) {
        my @appearances = map { $_->{apid} }
            $mongo->collection('Appearance')->find({
                type            => 'source',
                'target.type'   => 'event',
                'target.id'     => $id,
            })->all;
        return $mongo->collection('Source')->find({
            id  => { '$in' => \@appearances }
        });
    }

    if ( $subthing eq "history" ) {
        return $mongo->collection('History')->find({
            'target.id'   => $id,
            'target.type' => 'event'
        });
    }

    if ( $subthing eq "file" ) {
        return $mongo->collection('File')->find({
            'entry_target.id'     => $id,
            'entry_target.type'   => 'event',
        });
    }

    die "Unsupported subthing $subthing";

}

sub autocomplete {
    my $self    = shift;
    my $frag    = shift;
    my $cursor  = $self->find({
        subject => /$frag/
    });
    my @records = map { {
        id  => $_->{id}, key => $_->{subject}
    } } $cursor->all;
    return wantarray ? @records : \@records;
}


1;
