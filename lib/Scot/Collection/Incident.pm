package Scot::Collection::Incident;
use lib '../../../lib';
use Moose 2;
extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

=head1 Name

Scot::Collection::File

=head1 Description

Custom collection operations for Files

=head1 Methods

=over 4

=item B<create_from_handler($handler_ref)>

Create an event and from a POST to the handler

=cut


sub create_from_handler {
    my $self    = shift;
    my $handler = shift;
    my $log     = $handler->env->log;

    $log->trace("Custom create in Scot::Collection::Incident");

    my $build_href  = $handler->get_build_href;

    if ( defined $build_href->{from_alerts} ) {
        return $self->build_from_alerts($handler, $build_href);
    }

    my $event   = $self->create($build_href);

    return $event;

}

1;
