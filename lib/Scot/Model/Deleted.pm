package Scot::Model::Deleted;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Deleted

=head1 Description

The model of a deletion record

=cut

=head1 Extends

Scot::Model

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Data
    Scot::Role::Hashable
    Scot::Role::Times
);

=head1 Consumed Roles

    Meerkat::Role::Document
    Scot::Role::Data
    Scot::Role::Hashable
    Scot::Role::Times

=head1 Attributes

=over 4

=item B<type>

the type of Scot::Model::* 

=cut

has type  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'unknown',
);

=item B<data>

the hash reference to the data extraced from the alert
from Scot::Role::Data

=cut

sub get_memo {
    my $self    = shift;
    return '';
}

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
