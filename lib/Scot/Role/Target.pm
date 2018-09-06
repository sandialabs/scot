package Scot::Role::Target;
use Moose::Role;

=head1 Name

Scot::Role::Target;

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<target>

a target is a hashref of

    { 
        type => $type, 
        id => $id 
    }

This allows many to one linking.

=back 

=cut

has target  => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => [ 'Hash' ],
    required=> 1,
    default => sub {{}},
);

1;
