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

sub api_list {
    my $self    = shift;
    my $req     = shift;
    my $user    = shift;
    my $groups  = shift;

    my $match   = $self->build_match_ref($req->{request});
    
    if (! $self->env->is_admin($user,$groups) ) {
        $match->{username}  = $user;
    }
    my $cursor  = $self->find($match);
    my $total   = $cursor->count;

    if ( my $limit = $self->build_limit($req)) {
        $cursor->limit($limit);
    }
    else {
        $cursor->limit(50);
    }

    if ( my $sort   = $self->build_sort($req)) {
        $cursor->sort($sort);
    }
    else {
        $cursor->sort({id => -1});
    }

    if ( my $offset = $self->build_offset($req) ) {
        $cursor->skip($offset);
    }

    return ($cursor, $total);
}



1;
