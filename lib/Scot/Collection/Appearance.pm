package Scot::Collection::Appearance;
use lib '../../../lib';
use Moose 2;
extends 'Scot::Collection';

sub create_from_handler {
    return {
        error   => "Direct creation of Audit record from Web API not supported",
    };
}

sub get_total_appearances {
    my $self    = shift;
    my $type    = shift;
    my $value   = shift;

    my $cursor  = $self->find({
        type    => $type,
        value   => $value,
    });

    return $cursor->count;
}

sub get_appearance_cursor {
    my $self    = shift;
    my $type    = shift;
    my $value   = shift;

    my $cursor  = $self->find({
        type    => $type,
        value   => $value,
    });

    return $cursor;
}


1;
