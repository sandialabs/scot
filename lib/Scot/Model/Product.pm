package Scot::Model::Product;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Product

=head1 Description

The model of an individual intel product item

=head1 Extends

Scot::Model

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Entriable
    Scot::Role::Hashable
    Scot::Role::Historable
    Scot::Role::Permission
    Scot::Role::Promotable
    Scot::Role::Sources
    Scot::Role::Status
    Scot::Role::Subject
    Scot::Role::Tags
    Scot::Role::Times
    Scot::Role::TLP
    Scot::Role::Views
);

=head1 Consumed Roles

    Meerkat::Role::Document
    Scot::Role::Entriable
    Scot::Role::Hashable
    Scot::Role::Historable
    Scot::Role::Permission
    Scot::Role::Promotable
    Scot::Role::Sources
    Scot::Role::Status
    Scot::Role::Subject
    Scot::Role::Tags
    Scot::Role::Times
    Scot::Role::TLP
    Scot::Role::Views

=head1 Attributes

=over 4

=item B<subject>

the subject of the item
from Scot::Role::Subject

=cut

=item B<prodtype>

The product type, e.g. ThreatCard, Report, etc.

=cut

has prodtype => (
    is      => 'ro',
    isa     => 'Str',
    required => 1,
    default => 'unknown',
);

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
    
