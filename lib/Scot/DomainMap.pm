package Scot::DomainMap;

use strict;
use warnings;
use Module::Runtime qw(require_module);
use Moose;
use feature 'signatures';
no warnings 'experimental::signatures';
use lib '../../lib';

#
# domainmap 
# load all Domain packages in the Scot/Domain directory
# and provide a function to instantiate those domains
# 

around BUILDARGS => sub {
    my $orig    = shift;
    my $class   = shift;

    my $domdir;
    my @search  = (qw(
        ../lib/Scot/Domain
        ../../lib/Scot/Domain
        ../../../lib/Scot/Domain
    ));

    foreach my $dir (@search) {
        if ( -d $dir ) {
            unshift @INC, $dir; # add to perl lookup path
            $domdir = $dir;
            last;
        }
    }

    opendir(DIR, $domdir) || die "Unable to read $domdir";

    while (my $file = readdir(DIR)) {
        next if ($file =~ /^\.+$/);  #no . or ..
        next if ($file =~ /.*swp/);  # no vim swap files
        next if ($file =~ /^\..+$/); # no .files

        $file =~ m/^\w+\.pm$/;
        my $base    = $1;
        my $class   = "Scot::Domain::$base";
        require_module($class);
    }
    return $class->$orig(@_);
};

has cache   => (
    is      => 'ro',
    isa     => 'HashRef',
    required=> 1,
    default => sub { {} },
);

sub get_domain ($self, $name) {

    my $cache   = $self->cache;
    return $cache->{$name} if (defined $cache->{$name});

    my $class   = "Scot::Domain::".ucfirst($name);
    my $instance= $class->new();
    $cache->{$name} = $instance;
    return $instance;
}

1;

    
