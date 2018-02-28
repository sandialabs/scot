package Scot::App::Taxii;

use v5.18;
use lib '../../../lib';
use Data::Dumper;
use Scot::Env;
use Scot::Util::Taxii;
use Parallel::ForkManager;
use Moose;
extends 'Scot::App';

has taxii => (
    is          => 'ro',
    isa         => 'Scot::Util::Taxii',
    required    => 1,
    lazy        => 1,
    builder     => "_build_taxii",
);

sub _build_taxii {
    my $self    = shift;
    return $self->env->taxii;
}

has max_processes => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    lazy        => 1,
    builder     => '_build_max_processes',
);

sub _build_max_processes {
    my $self    = shift;
    my $attr    = "max_processes";
    my $default = 0;
    my $envname = "scot_app_mail_max_processes";
    return $self->get_config_value($attr, $default, $envname);
}

sub run {
    my $self    = shift;
    my $log     = $self->log;
    my $taxii   = $self->taxii;

    $log->debug("Starting Taxii Import Processing");

    my $collections = $taxii->get_collections();
    my $xmlhref     = $taxii->get_collection_data($colname);
}
