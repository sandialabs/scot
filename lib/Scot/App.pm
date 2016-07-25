package Scot::App;

use lib '../../lib';
use v5.18;
use strict;
use warnings;
use Scot::Util::Logger;
use Scot::Util::Config;

use Moose;
use namespace::autoclean;

has configuration_file  => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
);

has paths   => (
    is              => 'ro',
    isa             => 'ArrayRef',
    required        => 1,
    default         => sub { ['/opt/scot/etc' ]; },
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
    print "Loading $file\n";
    my $confobj = Scot::Util::Config->new({
        file    => $file,
        paths   => $self->paths,
    });
    return $confobj->get_config;
}


has log => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    required    => 1,
    lazy        => 1,
    builder     => '_get_logger',
);

sub _get_logger {
    my $self    = shift;
    my $chref   = $self->config->{log};
    return Scot::Util::Logger->new($chref);
}

has base_url    => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
    default         => '/scot/api/v2',
);


1;
