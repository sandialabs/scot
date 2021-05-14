package Scot::Controller::Proxy;

use strict;
use warnings;
use utf8;
use Try::Tiny;
use Carp qw(longmess);

use Mojo::Base 'Mojolicious::Controller', -signatures;

=head1 Scot::Controller::Proxy

contain the controllers for the various Proxy services API provides,
like RecFuture, etc.

=cut

sub recfuture ($self) {
    # receives an ID for an entity
    # places a request on /queue/recfuture to be handled
}


sub lri ($self) {
    # receives and ID for an entity
    # places request on /queue/lriproxy

}

sub remoteflair ($self) {
    # scot browser extension will send in html
    # this will place request on /queue/remoteflair
    # after creating a remote flair object
}

1;
