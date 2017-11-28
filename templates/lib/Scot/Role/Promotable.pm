package Scot::Role::Promotable;

use Moose::Role;

=item B<promotion_id>

hold the id of the promoted object
so in an alert it would hold the event_id
in and event it would hold the incident_id

0 means not promoted

=cut

has promotion_id => (
    is      => 'ro',
    isa     => 'Int',
    required=> 1,
    default => 0,
);


1;
