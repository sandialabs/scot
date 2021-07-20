package Scot::Enricher::Io;

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
    my $mongo   = $self->env->mongo;
    my $col     = $mongo->collection(ucfirst($type));
    my $item    = $col->find_iid($id);
    return $item;
}

sub retrieve_entity_href {
    my $self    = shift;
    my $id      = shift;
    my $log     = $self->env->log;
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
    my @updates = @_;
    my $obj     = $self->retrieve_item($id);

    # note to future self
    # this overwrites the key for each enrichment
    # if you want instead to push latest update
    # update the $set to a $push

    foreach my $update (@updates) {
        my ($key, $val) = each %$update;
        my $command = {
            '$set' => {
                "data.$key" => $val
            }
        };
        $obj->update($command);
    }
}

1;
