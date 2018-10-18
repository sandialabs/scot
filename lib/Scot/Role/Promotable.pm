package Scot::Role::Promotable;
use Moose::Role;

=head1 Name

Scot::Role::Promotable

=head1 Description

This Role when consumed by a Scot::Model, provides the following attributes.

=head1 Attributes

=over 4

=item B<promotion_id>

hold the id of the promoted object
so in an alert it would hold the event_id
in and event it would hold the incident_id

0 means not promoted

=back

=cut

has promotion_id => (
    is      => 'ro',
    isa     => 'Int',
    required=> 1,
    default => 0,
);


1;
