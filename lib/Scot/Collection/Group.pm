package Scot::Collection::Group;
use lib '../../../lib';
use Data::Dumper;
use Moose 2;
extends 'Scot::Collection';

sub create_from_api {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $json    = $request->{request}->{json};
    my $log     = $env->log;

    my $group   = $self->create($json);

    if ( $group ) {
        return $group;
    }

    $log->error("Failed to create GROUP from ", { fitler => \&Dumper, value => $request });
    return undef;
}
1;
