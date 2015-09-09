package Scot::Collection::Checklist;
use lib '../../../lib';
use Moose 2;
extends 'Scot::Collection';

sub create_from_handler {
    my $self        = shift;
    my $handler     = shift;
    my $build_href  = $handler->get_build_href;
    my $checklist   = $self->create($build_href);
    
    return $checklist;
}

1;
