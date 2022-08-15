package Scot::Model::Handler;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Handler

=head1 Description

The model of an the Handler record...
The incident handler that is

=head1 Extends

Scot::Model

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Hashable
    Scot::Role::Username
);

=head1 Consumed Roles

    Meerkat::Role::Document
    Scot::Role::Hashable
    Scot::Role::Username

=head1 Attributes

=over 4

=item B<start>

start epoch for shift as handler

=cut

has start  => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
);

=item B<end>

start epoch for shift as handler

=cut

has end  => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
);

=item B<username>

this is the ihandler, from Scot::Role::Handler

=cut

=item B<type>

handler, commander, hunter, 

=cut

has type => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'handler',
);

sub get_memo {
    my $self    = shift;
    return $self->username;
}
__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
