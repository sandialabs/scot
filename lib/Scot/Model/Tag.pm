package Scot::Model::Tag;

use lib '../../lib';
use strict;
use warnings;
use v5.10;

use Data::Dumper;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

=head1 NAME
 Scot::Model::Tag - a moose obj rep of a Scot Tag

=head1 DESCRIPTION
 Definition of an A Tag
=cut

extends 'Scot::Model';

=head2 Attributes

=cut
with (  
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Hashable',
    'Scot::Roles::Loggable',
);

has tag_id  => (
    is      => 'rw',
    isa     => 'Int',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
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
    default     => 'tag_id',
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
    default     => 'tags',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<text>
 string describing the subject line of the alert
=cut
has text     => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<taggee>
 Array of things that are tagged with "text"
 [ { type: event|entry|alert|..., id: int }, ... ]
=cut
has taggee      => (
    traits      => [ 'Array' ],
    is          => 'rw',
    isa         => 'ArrayRef[HashRef]',
    required    => 1,
    builder     => '_build_empty_array_ref',
    handles     => {
        'taggee_count'    => 'count',
        'add_taggee'      => 'push',
        'all_taggees'     => 'elements',
        'find_taggee'     => 'first_index',
        'splice_taggee'   => 'splice',
        'grep_taggee'     => 'grep',
    },
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
        alt_data_sub    => 'all_taggees',
    },
);


sub _build_empty_array_ref {
    return [];
}

sub add_to_taggees {
    my $self    = shift;
    my $href    = shift;
    my $type    = $href->{type};
    my $id      = $href->{id};

    if ( defined $type and defined $id ) {
        my @alreadythere = $self->grep_taggee(sub {
            my $t = $_->{type};
            my $i = $_->{id};
            return ( $t eq $type and $i eq $id );
        });
        if (scalar(@alreadythere) > 0 ) {
            return;
        }

        # alternate code to above.  should do the same
        #foreach my $tag_href ($self->all_taggees) {
        #    my $this_type   = $tag_href->{type};
        #    my $this_id     = $tag_href->{id};
        #
        #    if ( $type eq $this_type and $id eq $this_id ) {
        #        return;
        #    }

        $self->add_taggee($href);
    }
}

sub remove_taggee {
    my $self    = shift;
    my $type    = shift;
    my $id      = shift;
    my $log     = $self->log;

    if (defined $type and defined $id) {
        $log->debug("Removing taggee $type $id");
        my $index   = $self->find_taggee(sub {
            my $t   = $_->{type};
            my $i   = $_->{id};
            return ( $t eq $type and $i eq $id );
        });
        $log->debug("removing index " .$index);
        $self->splice_taggee($index, 1);
        $log->debug(Dumper($self->taggee));
    }
    else {
        $log->error("Need to provide type and id!");
        return undef;
    }
}

 __PACKAGE__->meta->make_immutable;
1;
