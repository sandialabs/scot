package Scot::Role::Parsed;
use Moose::Role;

=head1 Name

Scot::Role::Parsed

=head1 Description

This role, when consumed by a Scot::Model, provides the following attributes

=head1 Attributes

=over 4

=item B<parsed>

Was the consuming model parsed? (false = 0, true = 1) 

=back

=cut

has parsed => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

1;
