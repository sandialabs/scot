package Scot::Util::Cursor;

use lib '../../../lib';
use strict;
use warnings;
use v5.10;
use Data::Dumper;

use Scot::Model::Alert;
use Scot::Model::Alertgroup;
use Scot::Model::Guide;
use Scot::Model::Event;
use Scot::Model::Entry;
use Scot::Model::Entity;
use Scot::Model::Incident;
use Scot::Model::Intel;
use Scot::Model::Chat;
use Scot::Model::User;
use Scot::Model::Tag;
use Scot::Model::File;
use Scot::Model::Plugin;
use Scot::Model::Plugininstance;
use Scot::Model::Parser;

use Moose;
use namespace::autoclean;

=pod

=head1 NAME

Scot::Util::Cursor - Moose based module, takes a mongo cursor and 
provides Scot model objects

=head1 DESCRIPTION


=head2 Attributes

=cut

=item C<log>

 the logger is passed in as well
 usually instantiated in Scot.pm as well.
 isa of object for max flexibility, 
 allows swapping of logger modules

=cut

has 'log'       => (
    is          => 'ro',
    isa         => 'Object', 
    required    => 0,
);

=item C<db>

 the db attribute is built at object creation
 params come from config

=cut

has 'cursor'        => (
    is          => 'ro',
    isa         => 'MongoDB::Cursor',
    required    => 1,
);

has 'collection'    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

sub next {
    my $self        = shift;
    my $cursor      = $self->cursor; 
    my $collection  = ucfirst($self->collection);
    $collection     =~ s/^(.*)s$/$1/;
    $collection     =~ s/^(.*)ie$/$1y/;
    my $class       = "Scot::Model::$collection";

    my $record      = $cursor->next;
    
    return undef unless (defined $record);

    # $self->log->trace("obj is ".Dumper($record));

    $record->{log}  = $self->log;
    my $obj;
    my $log = $self->log;
    eval {
        $obj         = $class->new($record);
    };
    if ($@) {
        $log->error("Error: $@");
        $log->error("Record was: ".Dumper($record));
    }
    return $obj;
}

sub count { 
    my $self    = shift;
    my $cursor  = $self->cursor;
    return $cursor->count;
}

sub immortal {
    my $self    = shift;
    my $cursor  = $self->cursor;
    $cursor->immortal(1);
}

sub next_raw {
    my $self    = shift;
    my $cursor  = $self->cursor;
    my $next    = $cursor->next;
    if (defined $next) {
        return $next;
    }
    # $self->log->debug("last item reached..");
    return undef;
}

sub all {
    my $self        = shift;
    my $cursor      = $self->cursor;
    my $collection  = $self->collection;
    my @objects     = ();

    while (my $obj = $self->next) {
        push @objects, $obj;
    }
    return @objects;
}

sub all_array {
    my $self        = shift;
    my $cursor      = $self->cursor;
    my $collection  = $self->collection;
    my $log         = $self->log;
    my @objects     = ();
    my @data        = $cursor->all;
    $collection     =~ s/^(.*)s$/$1/;
    $collection     =~ s/^(.*)ie$/$1y/;
    my $class       = "Scot::Model::$collection";

    while ( my $href = shift @data ) {
        $href->{log} = $self->log;
        my $obj;
        eval {
            $obj    = $class->new($href);
        };
        if ($@) {
            $log->error("Error: $@");
            $log->error("Record was: ".Dumper($href));
        }
        push @objects, $obj;
    }
    return @objects;
}


__PACKAGE__->meta->make_immutable();
        
1;
