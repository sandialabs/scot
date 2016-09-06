package Scot::Collection::Einfo;

use lib '../../../lib';
use v5.18;
use strict;
use warnings;
use Data::Dumper;
use Moose 2;

extends 'Scot::Collection';
with qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

sub create_from_api {
    my $self    = shift;
    my $href    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $mq      = $env->mq;

    $log->trace("Create Einfo");

    my $request = $href->{request}->{json};
    my $einfo   = $self->create($request);

    unless ( defined $einfo ) {
        $log->error("Error! Failed to create Einfo with data ",
                    { filter => \&Dumper, value => $request} );
        return undef;
    }

    #$env->mq->send("scot", {
    #    action  => "created",
    #    data    => {
    #        type    => 'einfo',
    #        id      => $einfo->id,
    #    }
    #});

    return $einfo;
}

sub get_einfo {
    my $self    = shift;
    my $id      = shift;
    my $match;

    if ( $id =~ /\d+/ ) {
        $id     += 0;
        # get id match
        $match  = { id  => $id };
    }
    # get string match
    $match  = { value   => qr/$id/ };

    my $cursor  = $self->find($match);
    return $cursor;
}

1;
