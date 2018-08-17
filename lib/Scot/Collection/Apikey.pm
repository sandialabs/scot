package Scot::Collection::Apikey;
use lib '../../../lib';
use v5.18;
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';

override api_create => sub {
    my $self    = shift;
    my $req     = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    my $json    = $req->{request}->{json};

    my $apikey  = $self->create($json);

    unless ( $apikey) {
        $log->error("Error creating apikey from ",
                    { filter=>\&Dumper, value=>$req});
        return undef;
    }
    return $apikey;
};

sub get_users_apikeys {
    my $self    = shift;
    my $user    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    my $cursor  = $self->find({ username => $user });
    return $cursor;
}

override api_list => sub {
    my $self    = shift;
    my $req     = shift;
    my $user    = shift;
    my $groups  = shift;
    my $env     = $self->env;

    my $match   = $self->build_match_ref($req->{request});
    
    if (! $env->is_admin($user,$groups) ) {
        $match->{username}  = $user;
    }
    my $cursor  = $self->find($match);
    my $total   = $self->count($match);

    my $limit = $self->build_limit($req);
    if ( defined $limit ) {
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
};



1;
