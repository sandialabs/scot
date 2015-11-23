package Scot::Model::Source;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Sources

=head1 Description

The model of an individual alert

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Targets
);

=head1 Attributes

=over 4

=item B<value>

the name of the source

=cut

has value  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item B<targets>

[ { type: x, id, y } ]
from Scot::Role::Target

=cut

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
