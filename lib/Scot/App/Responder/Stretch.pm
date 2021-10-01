package Scot::App::Responder::Stretch;

use Try::Tiny;
use Data::Dumper;
use Data::Clean::ForJSON;
use Moose;
extends 'Scot::App::Responder';

has name => (
    is      => 'ro',
    isa     => 'Str',
    required    => 1,
    default => 'Stretch',
);

sub process_message {
    my $self        = shift;
    my $pm          = shift;
    my $href        = shift;
    my $log         = $self->log;

    $log->debug("processing message");

    my $action      = $href->{action};
    my $type        = $href->{data}->{type};
    my $id          = $href->{data}->{id};
    my $es          = $self->env->es;

    $log->debug("[Wkr $$] Processing Message $action $type $id");

    if ( $type eq "event" and $action eq "updated" ) {
        $log->debug("skipping an event updated event");
        return 1;
    }

    if ( $type eq "user" or $type eq "group" ) {
        $log->debug("skipping putting user or group into elasticsearch");
        return 1;
    }

    if ( $action eq "deleted" ) {
        $es->delete($type, $id, 'scot');
        $log->debug("after sending delete");
        $self->put_stat("elastic doc deleted",1);
        return 1;
    }

    my $cleanser    = Data::Clean::ForJSON->get_cleanser;
    my $record      = $self->get_document($type, $id);
    my $cleansed    = $cleanser->clone_and_clean($record);

    $log->trace("cleansed document: ",{ filter => \&Dumper, value => $cleansed });

    $log->warn("TYPE = $type");

    if ( $action eq "created" ) {
        $es->index('scot', $type, $cleansed);
        $log->debug("after sending index");
        $self->put_stat("elastic doc inserted", 1);
        return 1;
    }

    if ( $action eq "updated" ) {
        $es->update("scot", $type, $id, $cleansed);
        $log->debug("after sending update");
        $self->put_stat("elastic doc updated", 1);
        return 1;
    }

    $log->debug("That Message was not for me :-(");
}

sub get_document {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;

    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection(ucfirst(lc($type)));
    my $obj     = $col->find_iid($id);
    return $obj->as_hash;
}

sub query_documents {
    my $self    = shift;
    my $type    = shift;
    my $limit   = shift // 100;
    my $lastid  = shift // 0;
    my $log     = $self->log;

    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection(ucfirst(lc($type)));
    my $match   = {
        id  => { '$gt'  => $lastid }
    };
    $log->debug("Match is ".Dumper($match));
    my $cursor  = $col->find({
        id      => { '$gt' => $lastid },
    });
    $cursor->limit($limit);
    $cursor->sort({id => 1});
    return $cursor;
}

sub get_maxid {
    my $self    = shift;
    my $type    = shift;

    my $col = $self->env->mongo->collection(ucfirst(lc($type)));
    my $cur = $col->find({});
    $cur->sort({id => -1});
    my $obj = $cur->next;
    return $obj->id;
}
        

sub process_all {
    my $self        = shift;
    my $collection  = shift;
    my $startid     = shift;
    # my $scot        = $self->scot;
    my $es          = $self->env->es;
    my $limit       = 100;
    my $last_completed = $startid;
    my $log         = $self->log;

    my $maxid   = $self->get_maxid($collection);
    $log->debug("Max ID = $maxid");
    $log->debug("last_completed = $last_completed");

    my $continue = 1;
    my $cleanser = Data::Clean::JSON->get_cleanser;

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
            $log->debug("   $count.    id = ".$href->{id});

            delete $href->{_id};
            try {
                $es->index('scot',$collection, $href);
            }
            catch {
                $log->error("Error: Failed to index $collection : ". $href->{id});
                $log->error( Dumper($href));
                push @errors, $href->{id};
            };

            $last_completed = $href->{id};
            $log->debug("         last_completed = $last_completed");
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

