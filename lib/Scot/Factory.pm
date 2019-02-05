package Scot::Factory;

=head1 Name

Scot::Factory

=head1 Description

Code to create Factories

=cut

use lib '../../lib';
use strict;
use warnings;

use Moose;

=item b<make>

this method returns the product of the factory.
it is implemented in the subclass

=cut

=item b<product>

a string that represents what the expected
type of the make subroutine is.  
$product = ref(Factory->new()->make());

=cut

=item B<defaults>

when no config data is missing use these as defaults

=cut

has defaults  => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { {} },
);

sub get_config_value {
    my $self    = shift;
    my $attr    = shift;
    my $conf    = shift;

    if ( defined $conf->{$attr} ) {
        return $conf->{$attr};
    }
    return $self->defaults->{$attr};
}

1;

