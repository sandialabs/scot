package Scot::Collection::Handler;
use lib '../../../lib';
use Data::Dumper;
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

=item B<api_create($request)>

Create an handler and from a POST to the handler

=cut

override api_create => sub {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $log     = $self->log;
    my $mongo   = $self->meerkat;

    $log->trace("Custom create in Scot::Collection::Handler");

    my $json    = $href->{request}->{json};
    my $params  = $href->{request}->{params};

    my $build_href  = $json // $params;

    $log->debug("creating handler with ",{filter=>\&Dumper, value=>$build_href});

    my $handler   = $self->create($build_href);

    return $handler;
};

override api_list => sub {
    my $self    = shift;
    my $href    = shift;
    my $user    = shift;
    my $groups  = shift;

    my $match   = $self->build_match_ref($href->{request});
    my $current = $href->{request}->{params}->{current};

    if ( defined $current ) {
        my @records;
        my ($cursor,$count)  = $self->get_handler($current);
        return ($cursor, $count);
    }

    $self->log->debug("match is ",{filter=>\&Dumper, value=>$match});

    my $cursor  = $self->find($match);
    my $total   = $self->count($match);

    my $limit   = $self->build_limit($href);
    if ( defined $limit ) {
        $cursor->limit($limit);
    }
    else {
        # TODO: accept a default out of env/config?
        $cursor->limit(50);
    }

    if ( my $sort   = $self->build_sort($href) ) {
        $cursor->sort($sort);
    }
    else {
        $cursor->sort({id   => -1});
    }

    if ( my $offset  = $self->build_offset($href) ) {
        $cursor->skip($offset);
    }

    return ($cursor,$total);

};

sub get_handler {
    my $self    = shift;
    my $env     = $self->env;
    my $when    = shift // $self->now();
    
    $when = $self->now() if ($when == 1);

    my $match   = {
        start   => { '$lte' => $when },
        end     => { '$gte' => $when },
    };

    my $cursor  = $self->find($match);
    my $count   = $self->count($match);

    return $cursor, $count;
}


1;
