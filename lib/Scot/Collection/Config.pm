package Scot::Collection::Config;
use lib '../../../lib';
use Moose 2;
extends 'Scot::Collection';

sub create_from_handler {
    my $self    = shift;
    my $handler = shift;
    my $href    = $handler->get_build_href;
    my $config  = $self->create($href);
    return $config;
}
1;
