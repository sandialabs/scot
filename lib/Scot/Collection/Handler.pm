package Scot::Collection::Handler;
use lib '../../../lib';
use Moose 2;
extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
);

=head1 Name

Scot::Collection::File

=head1 Description

Custom collection operations for Files

=head1 Methods

=over 4

=item B<create_from_api($request)>

Create an handler and from a POST to the handler

=cut


sub create_from_api {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $mongo   = $env->mongo;

    $log->trace("Custom create in Scot::Collection::Handler");

    my $json    = $href->{request}->{json};
    my $params  = $href->{request}->{params};

    my $build_href  = $json // $params;

    my $handler   = $self->create($build_href);

    return $handler;
}

sub get_handler {
    my $self    = shift;
    my $env     = $self->env;
    my $when    = shift // $env->now();
    
    $when = $env->now() if ($when == 1);

    my $match   = {
        start   => { '$lte' => $when },
        end     => { '$gte' => $when },
    };

    my $cursor = $self->find($match);

    return $cursor;
}


1;
