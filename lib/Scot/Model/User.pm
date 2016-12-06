package Scot::Model::User;

=head1 Name

Scot::Model::User

=head1 Description

This model holds configuration information for SCOT users

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

the user's name, duh.

=cut

=item B<pwhash>

the password hash

=cut

has pwhash  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => ' ',
);

=item B<lockouts>

the count of lockouts

=cut

has lockouts    => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
);

=item B<attempts>

the number of attempted logins (without sucess)

=cut

has attempts    => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 0,
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

=item B<fullname> 

The string full name of the the user

TODO: create a setter to set a real fullname (if possible)

=cut

has fullname    => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
    default         => 'not provided',
);

=item B<tzpref>

The timezone preference of the user

=cut

has tzpref      => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
    default         => 'UTC',
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

=item B<last_activity_check>

last activity check time

=cut

has last_activity_check => (
    is              => 'ro',
    isa             => 'Epoch',
    required        => 1,
    default         => 4,
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

if the account is active or locked, local auth only

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

__PACKAGE__->meta->make_immutable;
1;

=back

=head1 Copyright

Copyright (c) 2014 Sandia National Laboratories.

=head1 Author

Todd Bruner.  

=cut
