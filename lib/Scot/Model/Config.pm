package Scot::Model::Config;

=head1 Name

Scot::Model::Config

=head1 Description

This model holds configuration information for SCOt and SCOT modules

=cut

use Moose;
use namespace::autoclean;

extends "Scot::Model";
with    qw(
    Meerkat::Role::Document
    Scot::Role::Hashable
    Scot::Role::Times
);

=head1 Attributes

=over 4


=item B<module>

the name of the module this applies to

=cut

has module  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item B<item>

the hash_ref of config data for the mode and module

=cut

has item    => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
