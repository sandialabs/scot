package Scot::App::Stretch;

use lib '../../../lib';
use lib '/opt/scot/lib';

=head1 NAME

Scot::App::Stretch

=head1 Description

deprecated:  moving to Scot::App::Responder::Stretch once tested

Listen for data changes in SCOT, submit that data to ElasticSearch

or 

Send it on a case by case basis

=cut

use Data::Dumper;
use JSON;
use Try::Tiny;

use Scot::Env;
use Scot::Util::ScotClient;
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

has scot_get_method => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'mongo',
);

has thishostname    => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
    lazy            => 1,
    default         => sub { hostname; },
);

has scot    => (
    is          => 'ro',
    isa         => 'Scot::Util::ScotClient',
    required    => 1,
    lazy        => 1,
    builder     => '_build_scotclient',
);

sub _build_scotclient {
    my $self    = shift;
    my $env     = $self->env;
    return $env->scot;
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
    my $env     = $self->env;
    return $env->es;
}

has max_workers => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    builder     => '_get_max_workers',
);

sub _get_max_workers {
    my $self    = shift;
    my $attr    = "max_workers";
    my $default = 1;
    my $envname = "scot_app_stretch_max_workers";
    return $self->get_config_value($attr, $default, $envname);
}

has stomp_host  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_stomp_host',
);

sub _build_stomp_host {
    my $self    = shift;
    my $attr    = "stomp_host";
    my $default = "localhost";
    my $envname = "scot_util_stomphost";
    return $self->get_config_value($attr, $default, $envname);
}
has stomp_port  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    builder     => '_build_stomp_port',
);

sub _build_stomp_port {
    my $self    = shift;
    my $attr    = "stomp_port";
    my $default = 61613;
    my $envname = "scot_util_stompport";
    return $self->get_config_value($attr, $default, $envname);
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
    $log->debug("SCOT access mode is ".$self->scot_get_method);

    my $stomp;

    if ( $self->stomp_host eq "localhost" ) {
        $stomp   = AnyEvent::STOMP::Client->new();
    }
    else {
        $stomp   = AnyEvent::STOMP::Client->new($self->stomp_host, $self->stomp_port);
    }

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

        #    $pm->start(
        #        cb  => sub {
        #            my ( $pm, $action, $type, $id ) = @_;
                    $self->process_message($action, $type, $id);
        #        },
        #        args    => [ $action, $type, $id ],
        #    );
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

    $log->debug("Processing message $action $type $id");

    if ($action eq "deleted") {
        $es->delete($type, $id, 'scot');
        $self->put_stat("elastic doc deleted", 1);
        return;
    }
    my $cleanser = Data::Clean::FromJSON->get_cleanser;
    my $record  = $self->get_document($type, $id);
    $cleanser->clean_in_place($record);
    $es->index('scot', $type, $record);
    $self->put_stat("elastic doc inserted", 1);
}

sub get_document {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;

    if ( $self->scot_get_method eq "mongo" ) {
        my $mongo   = $self->env->mongo;
        my $col     = $mongo->collection(ucfirst(lc($type)));
        my $obj     = $col->find_iid($id);
        return $obj->as_hash;
    }
    my $record  = $self->scot->get("$type/$id");
    return $record;
}

sub query_documents {
    my $self    = shift;
    my $type    = shift;
    my $limit   = shift // 100;
    my $lastid  = shift // 0;

    if ( $self->scot_get_method eq "mongo" ) {
        my $mongo   = $self->env->mongo;
        my $col     = $mongo->collection(ucfirst(lc($type)));
        my $match   = {
            id  => { '$gt'  => $lastid }
        };
        say "Match is ".Dumper($match);
        my $cursor  = $col->find({
            id      => { '$gt' => $lastid },
        });
        $cursor->limit($limit);
        $cursor->sort({id => 1});
        return $cursor;
    }
    my $record  = $self->scot->get("$type?id=x>$lastid");
    return $record;
}

sub get_maxid {
    my $self    = shift;
    my $type    = shift;

    if ( $self->scot_get_method eq "mongo" ) {
        my $col = $self->env->mongo->collection(ucfirst(lc($type)));
        my $cur = $col->find({});
        $cur->sort({id => -1});
        my $obj = $cur->next;
        return $obj->id;
    }
    my $resp = $self->scot->get("$type/maxid");
    my $maxid   = $resp->{max_id} // 500;
    return $maxid;
}
        

sub process_all {
    my $self        = shift;
    my $collection  = shift;
    my $startid     = shift // 0;
    my $scot        = $self->scot;
    my $es          = $self->es;
    my $limit       = 100;
    my $last_completed = $startid;
    my $log         = $self->log;

    $log->debug("Processing all $collection greater than $startid");

    say "Collection = $collection";

    my $maxid   = $self->get_maxid($collection);
    say "Max ID = $maxid";
    say "last_completed = $last_completed";

    $log->debug("Max id = $maxid, last completed = $last_completed");

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
        #my $m = {
        #    id  => "x>$last_completed",
        #    limit   => $limit,
        #    sort    => "+id",
        #};
        #say "looking for ".Dumper($m);
        #my $json = $scot->get({
        #    type    => $collection, 
        #    params  => $m
        #});
### NOTE: this is a quick hack until I can fix using the API
        my $count = 1;
        my $cursor  = $self->query_documents($collection, $limit, $last_completed);

        my @errors  = ();
        while (my $obj  = $cursor->next ) {
            my $href    = $obj->as_hash;
            say "   $count.    id = ".$href->{id};

            $log->debug("$count ... indexing id $href->{id}");

            delete $href->{_id};
            try {
                $es->index('scot',$collection, $href);
            }
            catch {
                say "Error: Failed to index $collection : ". $href->{id};
                say Dumper($href);
                $log->error("Failed to index $collection $href->{id}");
                push @errors, $href->{id};
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
    $limit          = 0 unless $limit;
    my $mongo       = $self->env->mongo;
    my $scot        = $self->scot;
    my $es          = $self->es;
#    my $json    = $scot->get("$collection?created=$start&created=$end&limit=$limit");

    my $cursor  = $mongo->collection(ucfirst($collection))->find({
        when    => {
            '$gte'  => $start,
            '$lte'  => $end,
        }
    });
    $cursor->immortal(1);

    while ( my $obj = $cursor->next ) {
        my $href    = $obj->as_hash;
        my $id      = $obj->id;
        $es->index($collection, $id, $href, "scot");
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
    my $mongo   = $self->env->mongo;
    my $log     = $self->env->log;
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
