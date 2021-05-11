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
    my $obj     = $self->retrieve_item('entity', $id);
    return $obj->as_hash;
}

1;
