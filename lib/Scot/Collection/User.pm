package Scot::Collection::User;

use lib '../../../lib';
use Moose 2;
extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

sub create_from_api {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    
    my $request = $href->{request}->{json};

    my $user    = $self->create($request);

    unless ($user) {
        $log->error("Failed to create user with data ",
                    { filter => \&Dumper, value => $request});
        return undef;
    }

    return $user;
}

1;
