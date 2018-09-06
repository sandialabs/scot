package Scot::Role::Sources;
use Moose::Role;
use namespace::autoclean;

=head1 Name

Scot::Role::Sources

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<source>

signals to the Api.pm that this model might have sources 

=back

=cut

has source => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [] },
);

1;
