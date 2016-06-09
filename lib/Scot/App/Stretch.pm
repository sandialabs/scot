package Scot::App::Stretch;

use lib '../../../lib';

=head1 NAME

Scot::App::Stretch

=head1 Description

Listen for data changes in SCOT, submit that data to ElasticSearch

or 

Send it on a case by case basis

=cut

use Data::Dumper;
use JSON;
use Try::Tiny;

use Scot::Env;
use Scot::Util::Scot;
use Scot::Util::ElasticSearch;
use AnyEvent::STOMP::Client;
use AnyEvent::ForkManager;
use Sys::Hostname;

use strict;
use warnings;
use v5.18;

use Moose;

extends 'Scot::App';

has thishostname    => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
    default         => sub { hostname; },
);

has scot    => (
    is          => 'ro',
    isa         => 'Scot::Util::Scot',
    required    => 1,
    lazy        => 1,
    builder     => '_build_scot_scot',
);

sub _build_scot_scot {
    my $self    = shift;
    return Scot::Util::Scot->new({
        log         => $self->log,
        servername  => $self->config->{scot}->{servername},
        username    => $self->config->{scot}->{username},
        password    => $self->config->{scot}->{password},
        authtype    => $self->config->{scot}->{authtype},
    });
}

has es      => (
    is          => 'ro',
    isa         => 'Scot::Util::Elasticsearch',
    required    => 1,
    lazy        => 1,
    builder     => '_build_es',
);

sub _build_es {
    my $self    = shift;
    return Scot::Util::Elasticsearch->new({
        log     => $self->log,
        config  => $self->config->{elasticsearch},
    });
}

has max_workers => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 1,   # two processes
);

=head2 Autonomous

$stretch->run();

this will listen to the activemq topic queue for changes.
pull them in, and then submit them for indexing to ES

=cut

sub run {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $scot    = $self->scot;

    $log->debug("Starting STOMP watcher");

    my $pm  = AnyEvent::ForkManager->new( max_workers => $self->max_workers );

    $pm->on_start( sub {
        my ( $pm, $pid, $action, $type, $id ) = @_;
        $log->debug("Starting worker $pid to handle $action on $type $id");
    });

    $pm->on_finish( sub {
        my ( $pm, $pid, $action, $type, $id ) = @_;
        $log->debug("Ending worker $pid to handle $action on $type $id");
    });

    my $stomp   = AnyEvent::STOMP::Client->new();

    $stomp->connect();
    $stomp->on_connected(sub {
        my $stomp   = shift;
        $stomp->subscribe('/topic/scot');
    });

    $stomp->on_message(
        sub {
            my ($stomp, $header, $body) = @_;

            my $json    = decode_json $body;
            my $type    = $json->{data}->{type};
            my $id      = $json->{data}->{id};
            my $action  = $json->{action};

            $log->debug("[AMQ] $action $type $id");

            return if ($action eq "viewed");

            $pm->start(
                cb  => sub {
                    my ( $pm, $action, $type, $id ) = @_;
                    $self->process_message($action, $type, $id);
                },
                args    => [ $action, $type, $id ],
            );
        }
    );
    AnyEvent->condvar->recv;
}

sub process_message {
    my $self    = shift;
    my $action  = shift;
    my $type    = shift;
    my $id      = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $es      = $self->es;

    if ($action eq "deleted") {
        # TODO implement a delete from es
        return;
    }

    my $record  = $self->get_scot($type, $id);
    $es->index($type, $record, 'scot');
}

sub get_scot {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $scot    = $self->scot;
    return $scot->get($type, $id);
}

# this should only be used when migrating database
# 
sub import_range {
    my $self    = shift;
    my $type    = shift;
    my $range   = shift;    # aref [start, finish] ids
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $match   = {};
    my $es      = $self->es;

    if ($range and ref($range) eq "ARRAY") {
        $match  = {
            id  => { 
                '$gte'  => $range->[0],
                '$lte'  => $range->[1],
            },
        };
    }


    $log->debug("importing $type range ",{filter=>\&Dumper, value=> $match});

    my $cursor  = $mongo->collection(ucfirst($type))->find($match);
    $cursor->immortal(1);

    while ( my $obj = $cursor->next ) {
        my $href    = $obj->as_hash;
        my $id      = $obj->id;
        $log->debug("Indexing $type $id");
        $es->index($type, $id, $href, 'scot');
    }
}

sub reprocess_collection {

}


1;
