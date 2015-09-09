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
    Scot::Role::Hashable
    Scot::Role::Owner
    Scot::Role::Permittable
    Scot::Role::Subject
    Scot::Role::Updated
    Scot::Role::Views
    Scot::Role::When
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
    
