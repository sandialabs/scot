package Scot::Model::Tag;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Tag

=head1 Description

The model of an individual Tag

=head1 Extends

Scot::Model

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Value
);

=head1 Consumed Roles

    Meerkat::Role::Document
    Scot::Role::Value

=head1 Attributes

=over 4

=item B<value>

Moved to Scot::Role::Value

the text that makes up the tag

=cut

=item B<note>

a brief description of the tag
or other explanatory info

=cut

has note    => (
    is      => 'ro',
    isa     => 'Str',
    required=> 1,
    default => '',
);

sub get_memo {
    my $self    = shift;
    return $self->value;
}

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.  
=head1 Author

Todd Bruner.  

=cut
