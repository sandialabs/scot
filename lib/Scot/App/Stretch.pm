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
extends 'Scot::App::Responder';

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

sub process_message {
    my $self    = shift;
    my $pm      = shift;
    my $href    = shift;
    my $log     = $self->log;
    my $es      = $self->es;

    my $action  = lc($href->{action});
    my $type    = lc($href->{data}->{type});
    my $id      = $href->{data}->{id} + 0;
    my $who     = $href->{data}->{who};
    my $opts    = $href->{data}->{opts};

    $log->debug("[Wkr $$] Processing message $action $type $id from $who");

    if ($action eq "deleted") {
        $es->delete($type, $id, 'scot');
        $self->put_stat("elastic doc deleted", 1);
        return "deleted elastic doc $type $id";
    }
    my $cleanser = Data::Clean::FromJSON->get_cleanser;
    my $record  = $self->get_document($type, $id);
    $cleanser->clean_in_place($record);
    $es->index('scot', $type, $record);
    $self->put_stat("elastic doc inserted", 1);
    return "indexed document $type $id";
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
