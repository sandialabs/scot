package Scot::Bot;

use lib '../../lib';
use strict;
use warnings;
use v5.10;

use MongoDB;
use MongoDB::OID;
use JSON;
use File::Slurp;
use Scot::Util::Mongo;
use namespace::autoclean;
use Log::Log4perl qw(:easy);
use Data::Dumper;

use Moose;


has 'env'   => ( 
    is          => 'ro', 
    isa         => 'Scot::Env', 
    required    => 1, 
);

has 'log'       => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
    lazy        => 1,
    builder     => '_get_logger',
);

has 'mongo'     => (
    is          => 'ro',
    isa         => 'Scot::Util::Mongo',
    required    => 1,
    lazy        => 1,
    builder     => '_get_mongo',
);

has 'mode'  => (
    is      => 'ro',
    isa     => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_mode',
);

sub _build_mode {
    my $self    = shift;
    my $config  = $self->config;
    return $config->{globals}->{scot_mode};
}

sub _get_logger {
    my $self    = shift;
    my $env  = $self->env;
    return $env->log;
}

sub _get_mongo {
    my $self    = shift;
    my $env  = $self->env;
    return $env->mongo;
}

1;
