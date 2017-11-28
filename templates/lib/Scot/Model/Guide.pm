package Scot::Model::Guide;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Guide

=head1 Description

The model of a Guide
Guides are collections of entries that the team can use to build
instructions on how to handle various alerts.

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Entriable
    Scot::Role::Hashable
    Scot::Role::Permission
    Scot::Role::Subject
    Scot::Role::Times
    Scot::Role::TLP
);

=head1 Attributes

=over 4

=item B<Subject>

the subject, from Scot::Role::Subject

=cut

=item B<applies_to>

array of alert subjects that apply to this

=cut

has applies_to  => (
    is          => 'ro',
    isa         => 'ArrayRef',
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
    
