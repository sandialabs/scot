package Scot::Util;

=head1 Name

Scot::Util

=head1 Description

Parent object for some of utils in Util.  Extending this class
gives the child a log attribute and the ability to load a config file
via Scot::Role::Configurable

=cut

use lib '../../lib';
use v5.16;
use strict;
use warnings;

use Scot::Util::LoggerFactory;
use Data::Dumper;
use Try::Tiny;

use Moose;

has env     => (
    is      => 'ro',
    isa     => 'Scot::Env',
    required    => 1,
);

has config  => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);

sub get_config_value {
    my $self    = shift;
    my $attr    = shift;
    my $default = shift;
    my $envname = shift;

    my $value = try {
        if ( defined $envname ) {
            if ( defined $ENV{$envname} ) {
                return $ENV{$envname};
            }
        }
        if ( defined $self->config->{$attr} ) {
            return $self->config->{$attr};
        }
        return $default;
    }
    catch {
        die "Error getting attr $attr: $_";
    };
    return $value;

}

has log => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
    lazy        => 1,
    builder     => '_build_log',
    predicate   => 'has_log',
);

sub _build_log {
    my $self    = shift;
    my $env     = $self->env;
    return $env->log;
}

1;

