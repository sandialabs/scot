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
use Moose;

with qw(Scot::Role::Configurable);

has log => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
    lazy        => 1,
    builder     => '_get_log',
);

sub _get_log {
    my $self        = shift;
    my $config      = $self->config;    # from scot::role::configurable
    my $logconfig   = $config->{log};

    unless ( $logconfig ) {
        $logconfig  = {
            logger_name     => 'SCOT',
            layout          => '%d %7p [%P] %15F{1}: %4L %m%n',
            appender_name   => 'scot_log',
            logfile         => '/var/log/scot/scot.log',
            log_level       => 'DEBUG',
        };
    }
    return Scot::Util::Logger->new($logconfig);
}

1;

