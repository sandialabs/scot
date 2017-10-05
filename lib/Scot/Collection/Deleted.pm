package Scot::Collection::Deleted;
use lib '../../../lib';
use Moose 2;
extends 'Scot::Collection';

sub create_from_handler {
    return {
        error   => "Direct creation of Deleted from Web API not supported",
    };
}

sub preserve {
    my $self    = shift;
    my $object  = shift;
    my $req     = shift;
    my $href    = $object->as_hash;
    $self->create({
        when    => $self->env->now,
        who     => $req->{user},
        type    => ref($object),
        data    => $href,
    });
}

1;
