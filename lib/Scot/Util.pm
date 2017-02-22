package Scot::Util;

=head1 Name

Scot::Util

=head1 Description

Parent object for some of utils in Util.  Extending this class
gives the child a log attribute and the ability to load a config file
via Scot::Role::Configurable

=cut

use lib '../../lib';
use v5.18;
use strict;
use warnings;

use Scot::Util::LoggerFactory;
use Data::Dumper;

use Moose;

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

has log => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
    lazy        => 1,
    builder     => '_build_log',
    predicate   => 'has_log',
);

sub _build_log {
    my $self        = shift;
    my $config      = $self->config;    # from scot::role::configurable
    my $logconfig   = $config->{log};

    print "in Scot::Util config is ".Dumper($logconfig)."\n";


    unless ( $logconfig ) {
        print "no logconfig, using defaults...\n";
        $logconfig  = {
            logger_name     => 'SCOT',
            layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
            appender_name   => 'scot_log',
            logfile         => '/var/log/scot/scot.log',
            log_level       => 'DEBUG',
        };
    }
    my $logfactory = Scot::Util::LoggerFactory->new($logconfig);
    return $logfactory->get_logger;
}

1;

