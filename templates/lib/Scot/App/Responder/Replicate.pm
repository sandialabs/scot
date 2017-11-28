package Scot::App::Replicate;

use lib '../../../lib';

=head1 Name

Scot::App::Replicate

=head1 Description

Watch for amq events
copy data to another SCOT

=cut

use Data::Dumper;
use JSON;
use Try::Tiny;
use Mojo::UserAgent;
use Scot::Env;
use Scot::App;
use Scot::Util::Scot2;
use Scot::Util::ImgMunger;
use Scot::Util::Enrichments;
use AnyEvent::STOMP::Client;
use AnyEvent::ForkManager;
use HTML::Entities;
use Module::Runtime qw(require_module);
use Sys::Hostname;
use strict;
use warnings;
use v5.18;

use Moose;

extends 'Scot::App';

has thishostname    =>  (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => sub { hostname; },
);


has thisscot    => (
    is          => 'ro',
    isa         => 'Scot::Util::Scot2',
    required    => 1,
    lazy        => 1,
    builder     => '_build_this_scot',
);

sub _build_this_scot {
    my $self    = shift;
    # say Dumper($self->config);
    return Scot::Util::Scot2->new({
        log         => $self->log,
        servername  => $self->config->{source}->{scot}->{servername},
        username    => $self->config->{source}->{scot}->{username},
        password    => $self->config->{source}->{scot}->{password},
        authtype    => $self->config->{source}->{scot}->{authtype},
    });
}

has thatscot    => (
    is          => 'ro',
    isa         => 'Scot::Util::Scot2',
    required    => 1,
    lazy        => 1,
    builder     => '_build_that_scot',
);

sub _build_that_scot {
    my $self    = shift;
    # say Dumper($self->config);
    return Scot::Util::Scot2->new({
        log         => $self->log,
        servername  => $self->config->{dest}->{scot}->{servername},
        username    => $self->config->{dest}->{scot}->{username},
        password    => $self->config->{dest}->{scot}->{password},
        authtype    => $self->config->{dest}->{scot}->{authtype},
    });
}

has interactive => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    default     => 0,
);



sub process_message {
    my $self    = shift;
    my $action  = shift;
    my $type    = shift;
    my $id      = shift;
    my $log     = $self->log;
    my $scot    = $self->thatscot;

    $log->debug("processing message $action $type $id");

    unless ( $type eq "entity" ) {
        $log->debug("Non Entity Event. Skipping...");
        return;
    }

    if ( $action eq "deleted" ) {
        $self->delete($type, $id);
    }
    else {
        my $href    = $self->get_record($type, $id);
        if ( $href ) {
            if ( $action eq "created" ) {
                $self->create($type,$href);
            }
            elsif ( $action eq "updated" ) {
                $self->update($type,$href);
            }
            else {
                $log->debug("ERROR: unsupported action type $action");
            }
        }
        else {
            $log->error("couldn't get the record from this scot!");
        }
    }
}

sub delete {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $log     = $self->log;
    my $scot    = $self->thatscot;

    if ( $scot->delete({ id => $id, type => $type}) ) {
        $log->debug("Deleted $type $id on that scot");
    }
    else {
        $log->error("Failed to delete $type $id on that scot");
    }
}

sub get_record {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $log     = $self->log;
    my $scot    = $self->thisscot;

    my $record  = $scot->get({
        type    => $type,
        id      => $id,
    });
    return $record;
}

sub create {
    my $self    = shift;
    my $type    = shift;
    my $href    = shift;
    my $log     = $self->log;
    my $scot    = $self->thatscot;

    delete $href->{_id};
    my $id = delete $href->{id};

    if ( $scot->post({ type => $type, data => $href, }) ) {
        $log->debug("Created $type $id on that scot");
    }
    else {
        $log->error("Failed to create $type $id on that scot");
    }
}

sub update {
    my $self    = shift;
    my $type    = shift;
    my $href    = shift;
    my $log     = $self->log;
    my $scot    = $self->thatscot;

    $log->debug("attempting $type update with ",{filter=>\&Dumper, value=>$href});

    my $id      = delete $href->{id};
    delete $href->{_id};

    if ( $scot->put({ type => $type, id => $id, data => $href }) ) {
        $log->debug("Updated $type $id on that scot");
    }
    else {
        $log->error("Failed to update $type $id on that scot");
    }
}

1;
