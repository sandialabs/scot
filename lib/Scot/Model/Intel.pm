package Scot::Model::Intel;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Intel

=head1 Description

The model of an individual intel item

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Entriable
    Scot::Role::Hashable
    Scot::Role::Historable
    Scot::Role::Permission
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

the subject of the item
from Scot::Role::Subject

=cut


__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
