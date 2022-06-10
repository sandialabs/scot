package Scot::Model::Msv;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Msv

=head1 Description

Keep track of message id's that had msv in them
so we do not duplicate the log

=head1 Extends

Scot::Model

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Hashable
);

=head1 Consumed Roles

    Meerkat::Role::Document

=head1 Attributes

=over 4

=item B<message_id>

the message-id of the email that contained msv data

=cut

has message_id    => (
    is      => 'ro',
    isa     => 'Str',
    required=> 1,
    default => '',
);

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.  
=head1 Author

Todd Bruner.  

=cut
