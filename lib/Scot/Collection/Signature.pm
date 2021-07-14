package Scot::Collection::Signature;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';
    
=head1 Name

Scot::Collection::Signature

=head1 Description

Custom collection operations on signatures

=head1 Methods

=over 4

=item B<api_create>

Create Signature from POST to API

=cut

override api_create => sub {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->debug("Creating Signature from POST to API");
    $log->debug(Dumper($request));

    my $user        = $request->{user};
    my $json        = $request->{request}->{json};
    $json->{owner}  = $user;
    my @tags        = $env->get_req_array($json, "tags");
    my @sources     = $env->get_req_array($json, "sources");

    $log->debug("json is ". Dumper($json));

    $self->validate_permissions($json);
    
    my $signature   = $self->create($json);

    unless ( $signature ) {
        $log->error("Error creating Signature from ",
                    { filter => \&Dumper, value => $request });
        return undef;
    }

    my $id  = $signature->id;

    if ( scalar(@sources) > 0 ) {
        my $col = $self->meerkat->collection('Source');
        $col->add_source_to("signature", $id, \@sources);
    }
    if ( scalar(@tags) > 0 ) {
        my $col = $self->meerkat->collection('Tag');
        $col->add_source_to("signature", $id, \@tags);
    }

    return $signature;
};


sub get_bundled_sigbody {
    my $self    = shift;
    my $sigobj  = shift;
    my $href    = $sigobj->as_hash;
    $href->{body} = {};
    my $id      = $sigobj->id + 0;
    my $match   = { signature_id => $id };
    my $col     = $self->meerkat->collection('Sigbody');
    my $cur     = $col->find($match); $cur->sort({created => -1});
    while ( my $sigbody = $cur->next ) {
        my $ahref = $sigbody->as_hash;
        $href->{version}->{$sigbody->revision} = $ahref;
    }
    return $href;
}

sub get_sigbodies {
    my $self    = shift;
    my $object  = shift;
    my $id      = $object->id + 0;
    my $col     = $self->meerkat->collection('Sigbody');
    my $cur     = $col->find({signature_id => $id});
    my $bodies  = {};
    $cur->sort({created => -1});
    while ( my $body = $cur->next ) {
        $bodies->{$body->revision} = $body->as_hash;
    }
    return $bodies;
}

sub api_subthing {
    my $self    = shift;
    my $req     = shift;
    my $thing   = $req->{collection};
    my $id      = $req->{id} + 0;
    my $subthing= $req->{subthing};
    my $mongo   = $self->meerkat;

    $self->env->log->debug("api_subthing /$thing/$id/$subthing");

    if ($subthing eq "entry") {
        return $mongo->collection('Entry')->get_entries_by_target({
            id      => $id,
            type    => 'signature',
        });
    }

    if ($subthing eq "entity") {
        return $mongo->collection('Link')
                     ->get_linked_objects_cursor(
                        { id => $id, type => 'signature' },
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
                'target.type'   => 'signature',
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
                'target.type'   => 'signature',
                'target.id'     => $id,
            })->all;
        return $mongo->collection('Source')->find({
            id => {'$in' => \@appearances}
        });
    }

    if ( $subthing eq "history" ) {
        return $mongo->collection('History')->find({
            'target.id'   => $id,
            'target.type' => 'signature'
        });
    }

    if ( $subthing eq "file" ) {
        return $mongo->collection('File')->find({
            'entry_target.id'     => $id,
            'entry_target.type'   => 'signature',
        });
    }

    die "unsupported signature subthing $subthing";

}


1;
