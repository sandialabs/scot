package Scot::Model::Audit;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Alert

=head1 Description

The model of an audit record

=cut

=head1 Extends

Scot::Model

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Data
);

=head1 Consumed Roles

Scot::Role::Data

=head1 Attributes

=over 4

=item B<who>

who is doing the doing

=cut

has who  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'unknown',
);

=item B<when>

when it happened

=cut

has when  => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => sub { time(); },
);

=item B<what>

what happened

=cut

has what    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => ' ',
);

=item B<data>

any data we wish to store
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
    
