package Scot::Enricher::Io;

use Data::Dumper;
use Try::Tiny;
use HTTP::Request;
use LWP::UserAgent;
use LWP::Protocol::https;
use File::Slurp;
use File::Path qw(make_path);
use Digest::MD5 qw(md5_hex);
use namespace::autoclean;
use MIME::Base64;
use Moose;

has env => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
);

sub retrieve_item {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $log     = $self->env->log;
    my $mongo   = $self->env->mongo;
    my $colname = ucfirst($type);
    my $col     = $mongo->collection($colname);
    my $item    = $col->find_iid($id);

    if ( ! defined $item ) {
        $log->error("Unable to find $colname $id!");
    }

    return $item;
}

sub retrieve_entity_href {
    my $self    = shift;
    my $id      = shift;
    my $log     = $self->env->log;

    $log->debug("retrieving entity $id");

    my $obj     = $self->retrieve_item('entity', $id + 0);
    if ( defined $obj and ref($obj) eq "Scot::Model::Entity" ) {
        return $obj->as_hash;
    }
    $log->error("Entity $id not found in DB");
    return undef;
}

sub apply_enrichment_data {
    my $self    = shift;
    my $id      = shift;
    my $update  = shift;
    my $obj     = $self->retrieve_item('entity', $id);
    my $log     = $self->env->log;

    # note to future self
    # this overwrites the key for each enrichment
    # if you want instead to push latest update
    # update the $set to a $push
    my $update_data = {};
    foreach my $key (keys %$update) {
        my $val = $update->{$key};
        my $i   = 'data.'.$key;
        $update_data->{$i} = $val;
    }
    my $command     = { '$set' => $update_data };
    $log->debug("Updating entity $id with ",{filter=>\&Dumper, value => $command});
    $obj->update($command);

    my $msg = {
        'action'    => 'updated',
        data        => {
            who     => 'scot-enricher',
            type    => 'entity',
            id      => $id,
        }
    };
    # not sure we need to do this since this information is only 
    # viewable on click
    # $self->send_mq('/topic/scot', $msg);
}

sub send_mq {
    my $self    = shift;
    my $queue   = shift;
    my $data    = shift;
    my $mq      = $self->env->mq;
    my $log     = $self->env->log;

    $log->debug("Sending to $queue : ");
    $log->debug({filter=>\&Dumper, value => $data});

    $mq->send($queue, $data);
}
1;
