package Scot::App::Stretch;

use lib '../../../lib';
use lib '/opt/scot/lib';

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
use Scot::Util::Scot2;
use Scot::Util::ElasticSearch;
use AnyEvent::STOMP::Client;
use AnyEvent::ForkManager;
use Sys::Hostname;
use Data::Clean::FromJSON;

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
    isa         => 'Scot::Util::Scot2',
    required    => 1,
    lazy        => 1,
    builder     => '_build_scot_scot',
);

sub _build_scot_scot {
    my $self    = shift;
    my $log     = $self->log;
    $log->debug("Config is : ",{filter=>\&Dumper,value=>$self->config});
    return Scot::Util::Scot2->new({
        log         => $self->log,
        servername  => $self->config->{scot}->{servername},
        username    => $self->config->{scot}->{username},
        password    => $self->config->{scot}->{password},
        authtype    => $self->config->{scot}->{authtype},
    });
}

has es      => (
    is          => 'ro',
    isa         => 'Scot::Util::ElasticSearch',
    required    => 1,
    lazy        => 1,
    builder     => '_build_es',
);

sub _build_es {
    my $self    = shift;
    return Scot::Util::ElasticSearch->new({
        log     => $self->log,
        config  => $self->config->{elasticsearch},
    });
}

has max_workers => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    builder     => '_get_max_workers',
);

sub _get_max_workers {
    my $self    = shift;
    my $conf    = $self->config;
    return $conf->{max_workers} // 1;
}

=head2 Autonomous

$stretch->run();

this will listen to the activemq topic queue for changes.
pull them in, and then submit them for indexing to ES

=cut

sub run {
    my $self    = shift;
    my $log     = $self->log;
    my $scot    = $self->scot;

    $log->debug("Starting STOMP watcher");

    my $stomp   = AnyEvent::STOMP::Client->new();
    my $pm      = AnyEvent::ForkManager->new( 
        max_workers => $self->max_workers 
    );

    $pm->on_start( sub {
        my ( $pm, $pid, $action, $type, $id ) = @_;
        $log->debug("Starting worker $pid to handle $action on $type $id");
    });

    $pm->on_finish( sub {
        my ( $pm, $pid, $action, $type, $id ) = @_;
        $log->debug("Ending worker $pid to handle $action on $type $id");
    });

    $pm->on_error( sub {
        my ( $pm, @anyargs ) = @_;
        say Dumper(@anyargs);
        $log->error("Worker ERROR: ",{filter=>\&Dumper, value=>\@_});
    });


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
    my $cv = AnyEvent->condvar;
    $cv->recv;
}

sub process_message {
    my $self    = shift;
    my $action  = shift;
    my $type    = shift;
    my $id      = shift;
    my $log     = $self->log;
    my $es      = $self->es;

    if ($action eq "deleted") {
        $es->delete($type, $id, 'scot');
        return;
    }
    my $cleanser = Data::Clean::FromJSON->get_cleanser;
    my $scot    = $self->scot;
    my $record  = $scot->get({
        type    => $type, 
        id      => $id
    });
    $cleanser->clean_in_place($record);
    $es->index($type, $record, 'scot');
}

sub process_all {
    my $self       = shift;
    my $collection = shift;
    my $scot        = $self->scot;
    my $es          = $self->es;
    my $limit       = 100;
    my $last_completed = 0;

    my $resp = $scot->get({
        type    => "$collection/maxid",
    });
    my $maxid   = $resp->{max_id} // 500;

    say "Max ID = $maxid";

    my $continue = 1;
    my $cleanser = Data::Clean::FromJSON->get_cleanser;

    while ( $continue ) {
        

        if ( $last_completed > $maxid ) {
            last;
        }

#        my $m   = {
#            id    => "x>$last_completed",
#            limit => $limit,
#            sort  => { id => 1 },
#        };
        my $m = {
            id  => "x>$last_completed",
            limit   => $limit,
            sort    => "+id",
        };
        say "looking for ".Dumper($m);
        my $json = $scot->get({
            type    => $collection, 
            params  => $m
        });
        my $count = 1;

        $cleanser->clean_in_place($json);

        foreach my $href ( @{$json->{records}} ) {

            say "   $count.    id = ".$href->{id};

            delete $href->{_id};
            try {
                $es->index($collection, $href, 'scot');
            }
            catch {
                die Dumper($href);
            };

            $last_completed = $href->{id};
            say "         last_completed = $last_completed";
            $count++;
        }

    }
}

sub process_by_date {
    my $self        = shift;
    my $collection  = shift;
    my $start       = shift;    # epoch
    my $end         = shift;    # epoch
    my $limit       = shift;
    $limit  = 0 unless $limit;
    my $scot        = $self->scot;
    my $es          = $self->es;
    # TODO change this to new style
    my $json        = $scot->get({
        type    => $collection,
        params  => {
            created => [ $start, $end ],
            limit   => $limit,
        },
    });

    foreach my $href (@{$json->{records}}) {
        $es->index($collection, $href, 'scot');
    }
}

#
# this should only be used when migrating database
# 
sub import_range {

    die "Not fully implemented...";

    my $self    = shift;
    my $type    = shift;
    my $range   = shift;    # aref [start, finish] ids
    my $mongo   = $self->mongo;
    my $log     = $self->log;
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
