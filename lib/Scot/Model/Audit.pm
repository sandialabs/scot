package Scot::Model::Audit;

use lib '../../lib';
use strict;
use warnings;
use v5.10;
use Moose;
use Moose::Util::TypeConstraints;
use Data::Dumper;
use namespace::autoclean;

=head1 Scot::Model::Audit

=head2 DESCRIPTION

 Scot::Model::Audit - a moose obj rep of a Scot Audit log record
 Definition of an Audit

=cut

extends 'Scot::Model';


=head2 Roles Consumed

    'Scot::Roles::Loggable',
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Hashable',

=cut

with (  
    'Scot::Roles::Loggable',
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Hashable',
);

=head2 Attributes

=over 4

=item C<id>

 the integer id for the audit record

=cut

has audit_id          => (
    is          => 'rw',
    isa         => 'Int',
    required    =>  0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1
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
    default     => 'audit_id',
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
    default     => 'audits',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);


=item C<who>

 who is doing

=cut

has who         => (
    is          =>  'rw',
    isa         =>  'Str',
    required    =>  1,
    default     => 'new',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

=item C<what>

 string describing the audit record

=cut

has what        => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);

=item C<when>

    time hires since epoch

=cut

has when        => (
    is          =>  'rw',
    isa         =>  'Num',
    required    =>  1,
    builder     => '_timestamp',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1,
        gridviewable    => 1,
    },
);

# =item C<type>
# 
#  string describing the type of audit record
#  -- not sure if needed
# 
# =cut

#has type     => (
#    is          => 'rw',
#    isa         => 'Str',
#    required    => 1,
#    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
#    description => {
#        gridviewable    => 1,
#        serializable    => 1
#    },
#);


=item C<data>

 data hashref of the audit record

=cut

has data        => (
    is          =>  'rw',
    isa         =>  'HashRef',
    traits      =>  ['Hash'],
    required    =>  0,
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 1
    },
);


sub _build_empty_array {
    my $self    = shift;
    return [];
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=back

=head1 COPYRIGHT

Copyright (c) 2013.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut

=head1 SEE ALSO

=cut

=over 4

=item L<Scot::Controller::Handler>

=item L<Scot::Util::Mongo>

=item L<Scot::Model>

=back

