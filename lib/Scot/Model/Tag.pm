package Scot::Model::Tag;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Tag

=head1 Description

The model of an individual Tag

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Targets
);

=head1 Attributes

=over 4

=item B<value>

the text that makes up the tag

=cut

has value  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item B<targets>

[ { target_type: x, target_id, y } ]

=cut


__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
