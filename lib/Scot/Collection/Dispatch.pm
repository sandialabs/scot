package Scot::Collection::Dispatch;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

=head1 Name

Scot::Collection::Dispatch

=head1 Description

Custom collection operations for Dispatch

=head1 Methods

=over 4

=item B<create_from_handler($handler_ref)>

Create an event and from a POST to the handler

=cut


override api_create => sub {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $self->log;
    my $mongo   = $self->meerkat;

    $log->debug("Custom create in Scot::Collection::Dispatch");

    my $json    = $request->{request}->{json};
    my $user    = $request->{user};

    $json->{owner} = 'scot-rss';

    my @tags    = $env->get_req_array($json, "tags");
    my @sources = $env->get_req_array($json, "sources");

    $self->validate_permissions($json);

    my $entry = delete $json->{entry};

    $log->trace("Creating Dispatch with ",{filter=>\&Dumper,value=>$json});

    my $dispatch   = $self->create($json);

    my $id  = $dispatch->id;

    if ( scalar(@sources) > 0 ) {
        my $col = $mongo->collection('Source');
        $col->add_source_to("dispatch", $dispatch->id, \@sources);
    }
    if ( scalar(@tags) > 0 ) {
        my $col = $mongo->collection('Tag');
        $col->add_source_to("dispatch", $dispatch->id, \@tags);
    }

    if ( defined $entry ) {
        $self->create_dispatch_entry($dispatch, $entry);
    }
    else {
        $log->error("No entry provided in dispatch!");
    }

    return $dispatch;
};

sub create_dispatch_entry {
    my $self        = shift;
    my $dispatch    = shift;
    my $entry       = shift;
    my $mongo       = $self->meerkat;
    my $col         = $mongo->collection('Entry');
    my $log         = $self->log;
    my $data        = {
        target      => {
            type    => 'dispatch',
            id      => $dispatch->id,
        },
        groups      => $dispatch->groups,
        summary     => 0,
        body        => $entry,
        owner       => $dispatch->owner,
    };
    $log->trace("creating dispatch entry with ",{filter=>\&Dumper, value=>$data});
    my $entry_obj = $col->create($data);
}

sub api_subthing {
    my $self    = shift;
    my $req     = shift;
    my $thing   = $req->{collection};
    my $id      = $req->{id} + 0;
    my $subthing= $req->{subthing};
    my $mongo   = $self->meerkat;

    if ( $subthing eq "entry" ) {
        return $mongo->collection('Entry')->get_entries_by_target({
            id      => $id,
            type    => 'dispatch',
        });
    }

    if ( $subthing eq "entity" ) {
        return $mongo->collection('Link')
                     ->get_linked_objects_cursor(
                        { id => $id, type => 'dispatch' },
                        'entity' );
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
                type    => 'tag', 
                'target.type'   => 'dispatch',
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
                'target.type'   => 'dispatch',
                'target.id'     => $id,
            })->all;
        return $mongo->collection('Source')->find({
            id => {'$in' => \@appearances}
        });
    }

    if ( $subthing eq "history" ) {
        my $col = $mongo->collection('History');
        my $cur = $col->find({'target.id'   => $id,
                              'target.type' => 'dispatch',});
        return $cur;
    }
    if ( $subthing eq "file" ) {
        my $col = $mongo->collection('File');
        my $cur = $col->find({
            'entry_target.type' => 'dispatch',
            'entry_target.id'   => $id,
        });
        return $cur;
    }
    die "Unsupported dispatch subthing $subthing";
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
