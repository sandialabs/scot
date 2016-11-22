package Scot::Model::Game;

=head1 Name

Scot::Model::Game

=head1 Description

This model holds information about SCOT the GAME! 

=cut

use Moose;
use namespace::autoclean;

extends "Scot::Model";
with    qw(
    Meerkat::Role::Document
    Scot::Role::Hashable
);

=head1 Attributes

=over 4


=item B<username>

the name of the contestant

=cut

has username  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item B<category>

the category of competition
e.g.:  tattler, alarmist, voyeur, fixer, cleaner, novelist

=cut

has category    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has tooltip => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item B<count>

the count for the category

=cut

has count   => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 0,
);

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
