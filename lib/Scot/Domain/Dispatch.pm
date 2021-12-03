package Scot::Domain::Dispatch;

use strict;
use warnings;
use Moose;
use experimental qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;

extends 'Scot::Domain';

sub create ($self, $request) {
    my $data    = $self->extract_dispatch_data($request);
}

sub extract_dispatch_data ($self, $request) {
    my $data    = {};
    
    $data->{owner}  = $self->extract_owner($request, 'scot-rss');
    $data->{tags}   = $self->get_array_from_request_data($request, 'tags');
    $data->{sources}= $self->get_array_from_request_data($request, 'sources');
}

1;
