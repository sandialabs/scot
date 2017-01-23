package Scot::Role::Configurable;

=head1 Name

Scot::Role::Configurable

=head1 Description

 this role is meant to be consumed by Apps and Utils
 and provided the means to load a configuration file
 and store it in an attribute "config"

=cut

use strict;
use warnings;
use v5.18;
use File::Find;
use Safe;
use Data::Dumper;

use Moose::Role;

=head1 Attributes

=over 4


=item B<config_file>

this is the basename filename of the the config file to use
this is a required attribute

=cut

has config_file => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    builder     => '_build_config_file',
);

sub _build_config_file {
    my $self    = shift;
    my $config  = $self->config;

    if ( defined $config ) {
        # config was passed in fully formed, and no config file sent.
        # clear indication to use the passed in config
        # print "Configurion passed in as hash_ref\n";
        $self->feedback("Config HREF passed in disregarding config_file");
        return ' ';
    }
    if ( defined $ENV{'scot_config_file'} ) {
        $self->feedback("using environment variable scot_config_file");
        return $ENV{'scot_config_file'};
    }
    $self->feedback("Failed to provide config file!");
    die "need config_file for ".__PACKAGE__."\n";
}

=item B<paths>

this is an array ref of paths to be seached for the config_file
testing has revealed that the last location found is the file that
will be used.  In other words, if paths = [ '/etc', '/home/tbruner' ] 
and the config_file is in both directories, the one in /home/tbruner is 
the one that will be returned

If not explicitly set, the environment variable 'scot_config_path' is
consulted and the colon seperated (:) path string is used.  Otherwise,
the path will default to /opt/scot/etc

=cut

has paths   => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    lazy        => 1,
    builder     => '_build_paths',
);

sub _build_paths {
    my $self    = shift;
    my $default = $ENV{'scot_config_paths'};

    $self->feedback("paths not passed in" );

    unless ( defined $default ) {
        $self->feedback("using default path of /opt/scot/etc");
        return [ '../..' ]; # a reasonable default
    }
    my @paths   = split(/:/, $default);
    $self->feedback("using env scot_config_paths ".join(':',@paths));
    return \@paths;
}

=item B<config>

this attribute holds the HashRef that contains the data from the config_file

=cut

has config  => (
    is          => 'ro',
    isa         => 'HashRef',
    lazy        => 1,
    required    => 1,
    builder     => '_build_config',
);

sub _build_config {
    my $self    = shift;
    my $file    = $self->config_file;
    my $paths   = $self->paths;
    my $fqname;

    $self->feedback("config file: $file");
    $self->feedback("path: ".join(':',@$paths));

    unless (defined $file) {
        die "Config file not provided!\n";
    }

    #print "building ".ref($self)." config from $file in ".join(':',@$paths)."\n";

    # File::Find does the hard work of locating the file
    find(
        sub {
            # print "looking for $file in $File::Find::dir\n";
            if ( $_ eq $file ) {
                $fqname = $File::Find::name;
                return;
            }
        },
        @$paths
    );

    unless ($fqname) {
        print "\n";
        print "Error: unable to locate $file\n";
        print "       searched ".join(',', @$paths)."\n";
        die   "Config File $file not found!\n";
    }

    # print "Reading config file: $fqname\n";

    no strict 'refs'; # just for this code scope
    my $cont    = new Safe 'MCONFIG';
    my $r       = $cont->rdo($fqname);
    my $hname   = 'MCONFIG::environment';
    my %copy    = %$hname;
    my $href    = \%copy;

    if ( defined $href->{include} ) {
        # print "processing includes...\n";
        my $include_href    = delete $href->{include};
        foreach my $attr ( keys %{ $include_href } ) {
            $href->{$attr} = $self->_build_config($include_href->{$attr});
        }
    }
    #print "got config: ".Dumper($href)."\n";
    return $href;
}

sub get_config_value {
    my $self    = shift;
    my $attr    = shift;
    my $default = shift;

    # environment_var -> config_file_var -> default
    my $env_var = "scot_".$attr;
    if ( defined $ENV{$env_var} ) {
        $self->feedback("Setting $attr = ".Dumper($ENV{$env_var}).
                        " from env_var $env_var");
        return $ENV{$env_var};
    }
    my $config  = $self->config;
    if ( defined $config ) {
        if ( defined $config->{$attr} ) {
            $self->feedback(
                "Setting $attr = ".Dumper($config->{$attr})." from config file"
            );
            return $config->{$attr};
        }
    }
    $self->feedback("setting $attr = ".Dumper($default)." (default)");
    return $default;
}

sub feedback {
    my $self    = shift;
    my $msg     = shift;

    return if $self->quiet;

    if ( $self->has_log ) {
        $self->log->debug($msg);
    }
    else {
        printf "%s\n", $msg;
    }
}

has quiet => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 1,
);

1;
