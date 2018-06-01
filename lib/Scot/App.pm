package Scot::App;

use lib '../../lib';
use v5.18;
use strict;
use warnings;
use Try::Tiny;
use Scot::Util::LoggerFactory;
use Data::Dumper;
use DateTime;
use namespace::autoclean;

use Moose;

has env => (
    is          => 'ro',
    isa         => 'Scot::Env',
    required    => 1,
    lazy        => 1,
    builder     => '_get_env',
);

# builder on is run if not env provided
sub _get_env {
    my $self    = shift;
    my $file    = $self->config_file;
    return Scot::Env->new({
        config_file => $file,
    });
}

has config_file => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_get_config_file',
);

sub _get_config_file {
    my $self    = shift;
    my $envvar  = $ENV{'scot_app_config'};
    if ( defined $envvar ) {
        return $envvar;
    }
    return ' ';
}

has log => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
    lazy        => 1,
    builder     => '_build_log',
    predicate   => 'has_log',
);

has get_method  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'mongo',
);

sub _build_log {
    my $self    = shift;
    my $env     = $self->env;
    return $env->log;
}

sub get_config_value {
    my $self    = shift;
    my $attr    = shift;
    my $default = shift;
    my $envname = shift;
    my $env     = $self->env;

    if ( defined $envname ) {
        if ( defined $ENV{$envname} ) {
            return $ENV{$envname};
        }
    }
    my $value = $env->get_env_attr($attr);

    if ( defined $value ) {
        return $value;
    }
    return $default;
}

has base_url    => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
    default         => '/scot/api/v2',
);

sub put_stat {
    my $self    = shift;
    my $metric  = shift;
    my $value   = shift;
    my $now     = DateTime->now;

        if ( $self->get_method eq "scot_api" ) {
            try {
                my $response    = $self->scot->post({
                    type    => "stat",
                    data    => {
                        action  => 'incr',
                        year    => $now->year,
                        month   => $now->month,
                        day     => $now->day,
                        hour    => $now->hour,
                        dow     => $now->dow,
                        quarter => $now->quarter,
                        metric  => $metric,
                        value   => $value,
                    }
                });
            }
            catch {
                $self->log->warn("Caught error: $_");
                $self->log->warn("Attempt to put stat $metric $value may have failed!");
            };
        }
        else {
            try {
                my $mongo   = $self->env->mongo;
                my $col     = $mongo->collection('Stat');
                $col->increment($now, $metric, $value);
            }
            catch {
                $self->log->warn("Caught error: $_");
                $self->log->warn("Attempt to write stat may have failed");
            };
        }
}


1;
