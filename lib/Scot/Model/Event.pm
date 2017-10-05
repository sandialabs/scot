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
    Scot::Role::Entriable
    Scot::Role::Entitiable
    Scot::Role::Hashable
    Scot::Role::Historable
    Scot::Role::Permission
    Scot::Role::Promotable
    Scot::Role::Status
    Scot::Role::Sources
    Scot::Role::Subject
    Scot::Role::Tags
    Scot::Role::Times
    Scot::Role::TLP
    Scot::Role::Views
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

=item B<promotable>

Tracks promotion, see Scot::Role::Promotable

=cut

=item B<promoted_from>

int id of the alert(group) that was promoted to this
empty arrayref means was not created from a promotion

=cut

has promoted_from => (
    is          => 'ro',
    isa         => 'ArrayRef',
    traits      => ['Array'],
    required    => 1,
    default     => sub {[]},
);

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
