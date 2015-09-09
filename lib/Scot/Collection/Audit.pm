package Scot::Collection::Audit;
use lib '../../../lib';
use Moose 2;
extends 'Scot::Collection';

sub create_from_handler {
    return {
        error   => "Direct creation of Audit record from Web API not supported",
    };
}

sub get_history {
    my $self    = shift;
    my %params  = @_;       # should be { target_id => xyz, target_type => "abc" }
    my $cursor  = $self->find(\%params);
    return $cursor;
}

1;
