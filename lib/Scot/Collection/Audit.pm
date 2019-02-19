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
    my $log         = $self->env->log;

    my $data    = {
        who     => $href->{who},
        when    => $self->env->now,
        what    => $href->{changes},
        data    => $href->{data},
    };
    $log->debug("audit rec: ",{filter=>\&Dumper, value=>$data});
    $self->create($data);
}


1;
