package Scot::Role::Tags;
use Moose::Role;
use namespace::autoclean;

=head1 Name

Scot::Role::Tags

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.
Tags may be applied to consuming object.

=head1 Attributes

=over 4

=item B<tag>

This attribute holds an array of tag strings.
Tag objects are in their own collection with a targets array.


=cut

has tag    => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [] },
);

1;
