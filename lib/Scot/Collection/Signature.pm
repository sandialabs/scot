package Scot::Collection::Signature;
use lib '../../../lib';
use Moose 2;
use v5.18;
use Data::Dumper;

extends 'Scot::Collection';
    
=head1 Name

Scot::Collection::Signature

=head1 Description

Custom collection operations on signatures

=head1 Methods

=over 4

=item B<create_from_api>

Create Signature from POST to API

=cut

sub create_from_api {
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
    
    my $signature   = $self->create($json);

    unless ( $signature ) {
        $log->error("Error creating Signature from ",
                    { filter => \&Dumper, value => $request });
        return undef;
    }

    my $id  = $signature->id;

    if ( scalar(@sources) > 0 ) {
        my $col = $env->mongo->collection('Source');
        $col->add_source_to("signature", $id, \@sources);
    }
    if ( scalar(@tags) > 0 ) {
        my $col = $env->mongo->collection('Tag');
        $col->add_source_to("signature", $id, \@tags);
    }

    return $signature;
}

sub get_bundled_sigbody {
    my $self    = shift;
    my $sigobj  = shift;
    my $href    = $sigobj->as_hash;
    $href->{body} = {};
    my $id      = $sigobj->id + 0;
    my $match   = { signature_id => $id };
    my $col     = $self->meerkat->collection('Sigbody');
    my $cur     = $col->find($match);
    $cur->sort({created => -1});
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


1;
