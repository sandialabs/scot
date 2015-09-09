package Scot::Model::Event;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Event

=head1 Description

The model of an individual event

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Alerts
    Scot::Role::Hashable
    Scot::Role::Incidents
    Scot::Role::Owner
    Scot::Role::Permittable
    Scot::Role::Status
    Scot::Role::Subject
    Scot::Role::Views
    Scot::Role::When
);

=head1 Attributes

=over 4

=item B<subject>

Subject ofor the event
from Scot::Role::Subject

=cut

=item B<status>

the status of the event, from Scot::Role::Status

=cut

=item B<alerts>

the integer id of the alerts that started this event
from Scot::Role::Alerts

=cut


=item B<incidents>

the incident(s) that this event was promoted to
from Scot::Role::Incidents

=cut

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
