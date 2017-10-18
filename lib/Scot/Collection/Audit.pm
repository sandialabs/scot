package Scot::Collection::Audit;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;
extends 'Scot::Collection';

sub create_from_handler {
    return {
        error   => "Direct creation of Audit record from Web API not supported",
    };
}

sub get_history {
    my $self    = shift;
    my %params  = @_;       # should be { target_id => xyz, target_type => "abc" }
    my $cursor  = $self->find(\%params);
    return $cursor;
}

sub create_audit_rec {
    my $self        = shift;
    my $href        = shift;
    my $handler     = $href->{handler};
    my $object      = $href->{object};
    my $changes     = $href->{changes};
    my $req         = $handler->tx->req;
    my $log     = $self->env->log;

    my $data    = {
        who     => $handler->session('user'),
        groups  => $handler->session('groups'),
        when    => $self->env->now,
        method  => $req->method,
        url     => $req->url->to_abs->to_string,
        from    => $handler->tx->remote_address,
        agent   => $req->headers->user_agent,
        params  => $req->params->to_hash,
        json    => $req->json,
    };


    if ( defined $object ) {
        $data->{object} = {
            id  => $object->id,
            col => ref($object),
        };
    }

    if ( defined $changes ) {
        $data->{changes} = $changes;
    }

    $log->trace("audit rec: ",{filter=>\&Dumper, value=>$data});

    $self->create($data);
}


1;
