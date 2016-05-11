package Scot::App;

use lib '../../lib';
use v5.18;
use strict;
use warnings;
use Log::Log4perl;
use Log::Log4perl::Level;
use Log::Log4perl::Layout::PatternLayout;
use Log::Log4perl::Appender;
use Safe;

use Moose;
use namespace::autoclean;

has logname => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_logname',
);

sub _build_logname {
    my $self    =shift;
    if ( $self->config->{logname} ) {
        return $self->config->{logname};
    }
    return 'SCOT';
}

has log => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
    lazy        => 1,
    builder     => '_build_logger',
);

sub _build_logger {
    my $self        = shift;
    my $file        = $self->logfile;
    my $name        = $self->logname;

    my $log     = Log::Log4perl->get_logger($name);
    my $layout  = Log::Log4perl::Layout::PatternLayout->new(
        '%d %7p [%P] %15F{1}: %4L %m%n'
    );
    my $appender    = Log::Log4perl::Appender->new(
        "Log::Log4perl::Appender::File",
        name        => $name,
        filename    => $file,
        autoflush   => 1,
    );
    $appender->layout($layout);
    $log->add_appender($appender);
    $log->level($TRACE);
    return $log;
}

has logfile => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    builder     => '_get_logfile',
);

sub _get_logfile {
    my $self    = shift;
    if ( $self->config->{logfile} ) {
        return $self->config->{logfile};
    }
    return '/var/log/scot/scot.log';
}

has configuration_file  => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
);

has config  => (
    is              => 'ro',
    isa             => 'HashRef',
    required        => 1,
    lazy            => 1,
    builder         => '_build_config',
);

sub _build_config { 
    my $self    = shift;
    my $file    = $self->configuration_file;
    unless ( $file ) {
        die "Error: configuration file attribute not set!";
    }
    unless ( -e $file ) {
        die "Error: Unable to find configuration file $file";
    }
    my $c   = new Safe 'CONFIG';
    my $r   = $c->rdo($file);
    return \%CONFIG::config;
}

1;
