package Scot::Collection::Apikey;
use lib '../../../lib';
use v5.18;
use Moose 2;

extends 'Scot::Collection';

sub create_from_api {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    my $apikey  = $self->create($href);

    unless (defined $apikey) {
        $log->error("Failed to create apikey");
        return undef;
    }
    return $apikey;
}

sub get_users_apikeys {
    my $self    = shift;
    my $user    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    my $cursor  = $self->find({ username => $user });
    return $cursor;
}


1;
