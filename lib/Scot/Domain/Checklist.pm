package Scot::Domain::Checklist;

use strict;
use warnings;
use Moose;
use experimental qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;

extends 'Scot::Domain';

sub create ($self, $request) {

    my $data    = $self->parse_checklist_request($request);

}

sub parse_checklist_request ($self, $request) {

    my $data    = {};
    $data->{owner} = $self->extract_owner($request);
}

1;
