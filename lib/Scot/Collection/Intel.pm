package Scot::Collection::Intel;
use lib '../../../lib';
use Moose 2;
extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

=head1 Name

Scot::Collection::Intel

=head1 Description

Custom collection operations for Intel

=head1 Methods

=over 4

=item B<create_from_handler($handler_ref)>

Create an event and from a POST to the handler

=cut


sub create_from_handler {
    my $self    = shift;
    my $handler = shift;
    my $log     = $handler->env->log;
    my $env     = $handler->env;

    $log->trace("Custom create in Scot::Collection::Intel");

    my $build_href  = $handler->get_build_href;

    $build_href->{owner}        = $handler->session('user');
    unless ( $build_href->{readgroups} ) {
        $build_href->{readgroups}   = $env->default_groups->{readgroups};
    }
    unless ( $build_href->{modifygroups} ) {
        $build_href->{modifygroups} = $env->default_groups->{modifygroups};
    }

    my $intel   = $self->create($build_href);

    return $intel;

}


1;
