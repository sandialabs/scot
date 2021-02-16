package Scot::Model::Feed;

use lib '../../../lib';
use Moose;
use namespace::autoclean;

=head1 Name

Scot::Model::Feed

=head1 Description

The model of an dispatch feed

=head1 Extends

Scot::Model

=cut

extends 'Scot::Model';
with    qw(
    Meerkat::Role::Document
    Scot::Role::Entriable
    Scot::Role::Data
    Scot::Role::Permission
    Scot::Role::Times
    Scot::Role::TLP
    Scot::Role::Tags
    Scot::Role::Sources
    Scot::Role::Hashable
);

=head1 Consumed Roles

    Meerkat::Role::Document
    Scot::Role::Entriable
    Scot::Role::Data;
    Scot::Role::Permission
    Scot::Role::Times
    Scot::Role::TLP
    Scot::Role::Tags
    Scot::Role::Sources
    Scot::Role::Hashable

=head1 Attributes

=over 4

=item B<status>

active, disabled

=cut

has status => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'active',
);

=item B<name>

The commonly known name of the the feed. e.g. Krebs on security.

=cut

has name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'unknown',
);

=item B<type>

The type of feed. RSS, Email, or Twitter

=cut

has type => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'rss',
);

=item B<uri>

The URI to the feed 

=cut

has uri  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'unknown',
);

=item B<last_attempt>

last time pulling feed was attempted

=cut

has last_attempt => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => 0,
);

=item B<last_article>

last time an article from feed was inserted

=cut

has last_article => (
    is          => 'ro',
    isa         => 'Epoch',
    required    => 1,
    default     => 0,
);

=item B<article_count>

the number of articles SCOT has input from feed

=cut

has article_count  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

=item B<promotions>

number of times an article from feed was promoted

=cut

has promotions   => (
    is          => 'ro',
    isa         => 'Int',
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
    
