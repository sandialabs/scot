package Scot::Model::File;

use lib '../../lib';
use strict;
use warnings;
use v5.10;

use Moose;
use Moose::Util::TypeConstraints;
use Data::Dumper;
use namespace::autoclean;

=head1 NAME
 Scot::Model::File - a moose obj rep of a Scot file

=head1 DESCRIPTION
 Definition of an File
 contains the meta data about files tracked in scot
=cut

extends 'Scot::Model';

enum 'valid_status', [qw(open assigned complete)];

=head2 Attributes

=cut
with (  
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Hashable',
    'Scot::Roles::Historable',
    'Scot::Roles::Ownable',
    'Scot::Roles::Permittable', 
    'Scot::Roles::Targetable',
);

has file_id => (
    is          => 'rw',
    isa         => 'Int',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<scot2_id>
 keep track of the file's oid from scot2
 since this is an oid and not an id, can't use Scot2identifiable role
=cut
has scot2_id    => (
    is          => 'rw',
    isa         => 'Maybe[MongoDB::OID]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
    },
);

=item C<idfield>
 since my integer id fields in models include the model name in them 
 instead of just "id", this field gives us an easy way to figure out
 what the id attribute is.  We can debate the original choice later...
=cut
has idfield    => (
    is          => 'ro',
    isa         => 'Str',
    required    =>  1,
    default     => 'file_id',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<collection>
 easy way to keep track of object to collection mapping.  
 We can debate the original choice later...
=cut
has collection => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'files',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<notes>
 string field containing any analyst supplied information about a file
=cut
has notes => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<entry_id>
 the upload and other data can be displayed in this entry
=cut
has entry_id => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<size>
 The drag coefficient.... no the file size
=cut
has size => (
    is          => 'rw',
    isa         => 'Int',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<filename>
 the filename duh
=cut
has filename => (
    is          => 'rw',
    isa         => 'Str',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<dir>
 where the file is asaved
=cut
has dir => (
    is          => 'rw',
    isa         => 'Str',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<fulllname>
 the fully qualified file name
=cut
has fullname => (
    is          => 'rw',
    isa         => 'Str',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<md5>
 the md5 hash of this data
=cut
has md5 => (
    is          => 'rw',
    isa         => 'Str',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<sha1>
 the sha1 hash
=cut
has sha1 => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);
=item C<sha256>
 the sha256 hash
=cut
has sha256 => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

around BUILDARGS    => sub {
    my $orig        = shift;
    my $class       = shift;

    if (@_==1 && ref $_[0] eq 'Scot::Controller::Handler') {
        my $controller  = $_[0];
        my $req         = $controller->req;
        my $href        = { env => $controller->env };
        my @rg  = $req->param('readgroups');
        my @mg  = $req->param('modifygroups');
        $href->{readgroups}   = \@rg if ( scalar(@rg) > 0 );
        $href->{modifygroups} = \@mg if ( scalar(@mg) > 0 );

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

    $log->debug("JSON received " . Dumper($json));

    while ( my ($k, $v) = each %$json ) {
        if ( $k eq "cmd" ) {
            # can't think of any now, but...
        }
        else {
            $log->debug("update $k to $v");
            my $orig = $self->$k;
            $self->$k($v);
            push @$changes, "Changed $k from $orig to $v";
            # probably should check for invalive changes
            # like change in target_id and parent still 
            # pointing to old chain
        }
    }
    $self->updated($now);
    $self->add_historical_record({
        who     => $mojo->session('user'),
        when    => $now,
        what    => $changes,
    });
}

sub build_modification_cmd {
    my $self    = shift;
    my $mojo    = shift;
    my $user    = $mojo->session('user');
    my $log     = $self->log;
    my $req     = $mojo->req;
    my $json    = $req->json;
    my $now     = $self->_timestamp();
    my $changes = [];
    my $data    = {};

    while ( my ($k, $v) = each %$json ) {
        if ( $k eq "cmd" ) {
            # can't think of any now, but...
        }
        else {
            my $orig = $self->$k;
            if ($self->constraint_check($k,$v)) {
                push @$changes, "updated $k from $orig";
                $data->{'$set'}->{$k} = $v;
            }
            else {
                $log->error("Value $v does not pass type constraint for attribute $k!");
                $log->error("Requested update ignored");
            }
        }
    }
    $data->{'$set'}->{updated} = $now;
    $data->{'$addToSet'}->{'history'}   = {
        who     => $user,
        when    => $now,
        what    => join(', ', @$changes),
    };
    my $modhref = {
        collection  =>  "files",
        match_ref   => { file_id => $self->file_id },
        data_ref    => $data,
    };
    return $modhref;
}



__PACKAGE__->meta->make_immutable;
1;
