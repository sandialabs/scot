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

has config  => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);

sub get_config_value {
    my $self    = shift;
    my $attr    = shift;
    my $default = shift;
    my $envname = shift;

    if ( defined $envname ) {
        if ( defined $ENV{$envname} ) {
            return $ENV{$envname};
        }
    }
    if ( defined $self->config->{$attr} ) {
        return $self->config->{$attr};
    }
    return $default;
}

1;

