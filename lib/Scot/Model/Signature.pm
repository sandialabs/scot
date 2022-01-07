package Scot::Model::Signature;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Signature

=head1 Description

The model of a Signature

=head1 Extends

Scot::Model

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Entriable
    Scot::Role::Hashable
    Scot::Role::Historable
    Scot::Role::Permission
    Scot::Role::Times
    Scot::Role::Permission
    Scot::Role::Sources
    Scot::Role::Tags
    Scot::Role::TLP
);

=head1 Consumed Roles

    Meerkat::Role::Document
    Scot::Role::Entriable
    Scot::Role::Hashable
    Scot::Role::Historable
    Scot::Role::Permission
    Scot::Role::Times
    Scot::Role::Permission
    Scot::Role::Sources
    Scot::Role::Tags
    Scot::Role::TLP

=head1 Attributes

=over 4

=item B<name>

the name of the signature

=cut

has name  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'new sig',
);


=item B<status>

the status of the signature: enabled | disabled

=cut

has status  => (
    is          =>  'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'disabled',
);


=item B<latest_revision>

give easy to use/remember revision numbers for sigbody
 
=cut

has latest_revision => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);


=item B<stats>

Hash of stats about this signature.  TODO: define internal structure

=cut

has stats => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { {} },
);

=item <options>

hash of optional params 

=cut

has options => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { {} },
);


=item B<data_fmt_ver>

Incidents might change over time, this value must match a key in scot.cfg.pl "forms" section.

=cut

has data_fmt_ver    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'signature',
);

=item B<data>

metadata about the signuate that is displayed in the form element

    has type    => (
        is          => 'ro',
        isa         => 'Maybe[Str]',
        required    => 1,
        default     => '',
    );

    the description of the signature

    has description => (
        is          => 'ro',
        isa         => 'Str',
        required    => 1,
        default     => '',
    );

    Allow for grouping of Signatures aside from type

    has signature_group => (
        is              => 'ro',
        isa             => 'ArrayRef',
        traits          => [ 'Array' ],
        required        => 1,
        default         => sub { [] },
    );

    has prod_sigbody_id => (
        is          => 'ro',
        isa         => 'Int',
        required    => 1,
        default     => 0,
    );

    has qual_sigbody_id => (
        is          => 'ro',
        isa         => 'Int',
        required    => 1,
        default     => 0,
    );
    Array of actions to take if Signature is matched

    has action  => (
        is          => 'ro',
        isa         => 'ArrayRef',
        required    => 1,
        default     => sub { [] },
    );

    has target = { type => x, id => y}
=cut

has data        => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { {
        type    => '',
        qual_sigbody_id => 0,
        prod_sigbody_id => 0,
        description     => '',
        action          => [],
        signature_group => [],
        target          => {},
    } },
);

sub get_memo {
    my $self    = shift;
    return $self->subject;
}

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2016 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
