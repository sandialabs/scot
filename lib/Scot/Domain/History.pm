package Scot::Domain::History;

use strict;
use warnings;
use Moose;
use experimental qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;

extends 'Scot::Domain';

sub _build_collection ($self) {
    return $self->mongo->collection('History');
}

sub add_history ($self, $obj, $record) {
    my $target  = $self->extract_target($obj);
    if ( defined $target->{error} ) { return $target; }
    $record->{target}   = $target;
    $record->{when}     = time() unless (defined $record->{when});
    $record->{who}      = 'unknown' unless (defined $record->{when});
    my $history = $self->collection->create($record);
}

sub extract_target ($self, $obj) {
    my $target;
    if ( ref($obj) =~ /Scot::Model/ ) {
        $target = {
            type    => $self->get_object_type($obj),
            id      => $obj->id,
        };
    }
    elsif (ref($obj) eq 'HASH') {
        # obj is a target already
        $target = { type => $obj->{type}, id => $obj->{id} };
    }
    else {
        return {error => 'invalid object to add history too'};
    };
    return $target;
}


sub find_related ($self, $request, $type, $id) {
    my @results  = ();
    my $cursor  = $self->collection->find({
        'target.id'     => $id,
        'target.type'   => $type,
    });
    while (my $h = $cursor->next) {
        my $href    = $h->as_hash;
        push @results, $href;
    }
    return {
        queryRecordCount    => scalar(@results),
        totalRecordCount    => scalar(@results),
        records             => \@results,
    };
}

1;
