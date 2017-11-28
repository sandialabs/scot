package Scot::Model::Sigbody;

use lib '../../../lib';
use Moose;
use MIME::Base64;
use namespace::autoclean;

=head1 Name

Scot::Model::Signature

=head1 Description

The model of a Sigbody 
these are refrenced by Signatures
Are essentially read only.
any mods create a new sigbody

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Hashable
    Scot::Role::Times
);

=head1 Attributes

=over 4

=item B<signature_id>

the id of the signature this belongs to

=cut

has signature_id  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
);

=item B<revision>

as opposed to the id, this will increment  only within a Signature

=cut

has revision    => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
);

=item B<body>

the body text

=cut

has body    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item B<bodyb64>

the base64 representation of the body

=cut

has bodyb64 => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    required    => 1,
    builder     => '_build_bodyb64',
);

sub _build_bodyb64 {
    my $self    = shift;
    my $body    = $self->body;
    return encode_base64($body);
}


__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2016 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
    
