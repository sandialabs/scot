package Scot::Model::Apikey;

=head1 Name

Scot::Model::Apikey

=head1 Description

definition of the apikey 

=cut
use lib '../../../lib';
use Scot::Types;
use Moose;
use namespace::autoclean;

extends "Scot::Model";
with    qw(
    Meerkat::Role::Document
    Scot::Role::Username
    Scot::Role::Hashable
);

=head1 Attributes

=over 4

=item B<username>

the user's name, that is tied to this apikey

=cut

=item B<apikey>

the password hash

=cut

has apikey  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => ' ',
);


=item B<last_login_attempt>

the time (seconds epoch) when the last login was attempted

=cut

has last_login_attempt   => (
    is              => 'ro',
    isa             => 'Epoch',
    required        => 1,
    default         => sub { time(); },
);


=item B<lastvisit>

when the user last accessed scot

=cut

has lastvisit   => (
    is              => 'ro',
    isa             => 'Epoch',
    required        => 1,
    default         => 0,
);

=item B<groups>

array_ref of groups a user belongs to 
(only used for local auth, otherwise LDAP group set is used)

=cut

has groups  => (
    is          => 'ro',
    isa         => 'ArrayRef',
    traits      => ['Array'],
    required    => 1,
    default     => sub {[]},
);

=item B<active>

if the apikey is active (1) or locked (0),

=cut

has active  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

=item B<local_acct>

if account is local auth

=cut

has local_acct  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

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
