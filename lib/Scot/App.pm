package Scot::App;

use lib '../../lib';
use v5.18;
use strict;
use warnings;
use Scot::Util::Logger;
use File::Find;
use Safe;

use Moose;
use namespace::autoclean;

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
    return $self->get_config($file);
}

sub get_config {
    my $self    = shift;
    my $file    = shift;
    my $paths   = shift;

    unless ($paths) {
        push @$paths, '/opt/scot/etc';
    }
    my $fqname;
    find(sub {
        if ( $_ eq $file ) {
            $fqname = $File::Find::name;
            return;
        }
    }, @$paths);

    unless ( -e $fqname ) {
        die "Config file $file not found!\n";
    }

    no strict 'refs';
    my $c   = new Safe 'CONFIG';
    my $r   = $c->rdo($fqname);
    my $n   = 'CONFIG::environment';
    my $h   = \%$n;
    return $h;
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
    my $cfile   = $self->config->{log_config};
    my $config  = $self->get_config($cfile);
    return Scot::Util::Logger->new($config);
}

has base_url    => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
    default         => '/scot/api/v2',
);


1;
