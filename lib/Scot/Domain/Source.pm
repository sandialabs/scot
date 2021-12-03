package Scot::Domain::Source;

use strict;
use warnings;
use Moose;
use experimental qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;

extends 'Scot::Domain';

sub _build_collection ($self) {
    return $self->mongo->collection('Source');
}

sub upsert ($self, $value) {
    # if exists, return it, if not create it.
    my $href = { value => $value };
    my $tag  = $self->collection->find_one($href);
    if ( defined $tag ) {
        return $tag;
    }
    $tag    = $self->collection->create($href);
    return $tag;
}

1;
