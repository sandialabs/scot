package Scot::Collection::Guide;
use lib '../../../lib';
use Moose 2;
extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
);

=head1 Name

Scot::Collection::Guide

=head1 Description

Custom collection operations for Guides

=head1 Methods

=over 4

=item B<create_from_handler($handler_ref)>

Create an event and from a POST to the handler

=cut

sub create_from_api {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->trace("Custom create in Scot::Collection::Guide");

    my $json    = $request->{request}->{json};
    my $user    = $request->{user};

    my @entries = @{$json->{entry}};
    delete $json->{entry};

    unless ( $json->{group}->{read} ) {
        $json->{group}->{read}   = $env->default_groups->{read};
    }
    unless ( $json->{group}->{modify} ) {
        $json->{group}->{modify} = $env->default_groups->{modify};
    }

    my $guide   = $self->create($json);

    if ( scalar(@entries) > 0 ) {
        my $mongo   = $env->mongo;
        my $ecoll   = $mongo->collection('Entry');
        my $lcoll   = $mongo->collection('Link');
        foreach my $entry ( @entries ) {
            $entry->{owner} = $entry->{owner} // $request->{user};
            $entry->{target}    = {
                type    => "guide",
                id      => $guide->id,
            };
            my $obj = $ecoll->create($entry);
        }
    }

    return $guide;
}



1;
