package Scot::Model::Parser;

use lib '../../lib';
use lib '../../../lib';
use strict;
use warnings;
use v5.10;

use JSON qw( decode_json );
use Moose;
use MongoDB;
use Moose::Util::TypeConstraints;
use Data::Dumper;
use Scot::Util::Timer;
use namespace::autoclean;

=head1 NAME

 Scot::Model::Parser = a moose obj rep of a Scot alert parser

=cut

=head1 DESCRIPTION

  A parser is used to parse an alert via JavaScript submitted by the user.  This is used for parsing alerts.

=head2 Consumes Roles

    'Scot::Roles::Loggable',
    'Scot::Roles::Dumpable',
    'Scot::Roles::Hashable',

=cut

extends 'Scot::Model';
with    (
    'Scot::Roles::Loggable',
    'Scot::Roles::Dumpable',
    'Scot::Roles::Hashable',
);

=head2 Attributes

=over 4

=cut

=item C<parser_id>

 the integer id of the parser

=cut

has parser_id    => (
    is          => 'rw',
    isa         => 'Int',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<idfield>

easy way to find parser_id above

=cut

has idfield    => (
    is          => 'ro',
    isa         => 'Str',
    required    =>  1,
    default     => 'parser_id',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);


=item C<created>

 epoch of when this parser was created

=cut

has created    => (
    is          => 'ro',
    isa         => 'Int',
    required    =>  1,
    builder     => '_timestamp',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<collection>

 easy way to keep track of object to collection mapping.  

=cut

has collection => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'parsers',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<js>

   JS to parser alert with

=cut

has js => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1
    },
);

=item C<condition_match>

  This is the string to match, taking condition_type and condition_comparator into account

=cut

has condition_match     => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);

=item C<condition_comparator>

  How to do  the comparison 'equals', 'contains', 'starts'

=cut 

has condition_comparator   => (
    is      => 'rw',
    isa     => 'Str',
    required  => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1
    },
);

=item C<condition_type>

  what to match 'from', 'subject' when determine which parser to use

=cut

has condition_type   => (
    is      => 'rw',
    isa     => 'Str',
    required  => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1
    },
);

sub _empty_aref {
    return [];
}

=back

=head2 Methods

=over 4

=cut

around BUILDARGS    => sub {
    my $orig    = shift;
    my $class   = shift;

    if (@_ == 1 && ref $_[0] eq 'Scot::Controller::Handler') {
        my $req     = $_[0]->req;
        my $json    = $req->json;
        my $js = $json->{'js'} // '';
        my $condition_match = $json->{'condition_match'} // '';
        my $condition_comparator = $json->{'condition_comparator'} // 'equal';
        my $condition_type   = $json->{'condition_type'} // 'source';
        my $href    = {
            js => $js,
            condition_match => $condition_match,
   	    condition_comparator => $condition_comparator,
  	    condition_type => $condition_type,
            env     => $_[0]->env,
        };
        return $class->$orig($href);
    }
    else {
        return $class->$orig(@_);
    }
};



sub apply_changes {
    my $self    = shift;
    my $mojo    = shift;
    my $user    = $mojo->session('user');
    my $log     = $self->log;
    my $req     = $mojo->req;
    my $json    = $req->json;
    my $now     = $self->_timestamp();
    my $changes = [];

    $log->debug("JSON received ".Dumper($json));

    while ( my ($k,$v) =  each %$json ) {
            $log->debug("update $k to $v");
            my $orig = $self->$k;
            $self->$k($v);
            push @$changes,"Changed $k from $orig to $v";
    }
    $self->updated($now);
}


# need to create add_to/remove_from functions for 
# events, alerts, incidents, entries

sub build_modification_cmd {
    my $self    = shift;
    my $mojo    = shift;
    my $user    = $mojo->session('user');
    my $log     = $self->log;
    my $req     = $mojo->req;
    my $json    = $req->json;
    my $now     = $self->_timestamp();
    my $changes = [];
    my $data_href    = {};

    while ( my ($k, $v) = each %$json ) { 
            my $orig    = $self->$k;
            if ($self->constraint_check($k,$v)) {
                push @$changes, {$k => $orig};
                $data_href->{'$set'}->{$k} = $v;
            }
            else {
                $log->error("Value $v does not pass type constraint for attribute $k!");
                $log->error("Requested update ignored");
            }
    }
    $data_href->{'$set'}->{created} = $now;
    $data_href->{'$addToSet'}->{'history'} = {
        who     => $user,
        when    => $now,
        what    => "created",
        old     => $changes,
    };
    my $modhref = {
        collection  => "parser",
        match_ref   => { },
        data_ref    => $data_href,
    };
    return $modhref;
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=back

=head1 COPYRIGHT

Copyright (c) 2014.  Sandia National Laboratories

=cut

=head1 AUTHOR

Nick Peterson.  nrpeter@sandia.gov.  505-844-7851.

=cut

=head1 SEE ALSO

=cut

=over 4

=item L<Scot::Controller::Handler>

=item L<Scot::Util::Mongo>

=item L<Scot::Model>

=back

