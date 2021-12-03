package Scot::Domain::Appearance;

use strict;
use warnings;
use Moose;
use experimental qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;

extends 'Scot::Domain';

sub _build_collection ($self) {
    return $self->mongo->collection('Appearance');
}

# to create an alert, you must provide an alertgroup
# to attach the alert to.
sub create ($self, $request) {
}

sub create_ts_appearance ($self, $type, $ts, $tsobj, $object) {
    my $obj_type    = $self->get_object_type($object);
    my $obj_id      = $object->id;
    my $href    = {
        type    => $type,
        value   => $ts,
        apid    => $tsobj->id,
        when    => time(),
        target  => {
            type    => $obj_type,
            id      => $obj_id,
        },
    };
    my $appearance = $self->collection->create($href);
    return $appearance;
}

1;
