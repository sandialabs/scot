package Scot::Model::Group;

=head1 Name

Scot::Model::Group

=head1 Description

This model holds information about a local group

=head1 Extends

Scot::Model

=cut

use Moose;
use namespace::autoclean;

extends "Scot::Model";
with    qw(
    Meerkat::Role::Document
    Scot::Role::Hashable
);

=head1 Consumed Roles

    Meerkat::Role::Document
    Scot::Role::Hashable

=head1 Attributes

=over 4


=item B<name>

the name of the group

=cut

has name  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item B<description>

the description of the groups purpose

=cut

has description    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'no desc',
);

sub get_memo {
    my $self    = shift;
    return $self->name;
}
__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
