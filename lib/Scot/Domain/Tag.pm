package Scot::Domain::Tag;

use strict;
use warnings;
use Moose;
use experimental qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;

extends 'Scot::Domain';

sub _build_collection ($self) {
    return $self->mongo->collection('Tag');
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

sub find_related ($self, $request, $type, $id) {
    my @return  = ();
    # find all tags linked to an alertgroup
    if ( $type eq "alertgroup" ) {
        my $target  = { id => $id, type => $type};
        my @results = $self->get_related_domain('link')->find_linked_by_type('tag',$target);
        return {
            queryRecordCount    => scalar(@results),
            totalRecordCount    => scalar(@results),
            records             => \@results,
        };
    }
}

1;
