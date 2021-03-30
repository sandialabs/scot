package Scot::Email::Imap::Cursor;

use lib '../../../../lib';
use strict;
use warnings;
use Moose;

has uids    => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    default     => sub { [] },
    handles     => {
        all     => 'elements',
        next    => 'shift',
    }
);

sub count {
    my $self    = shift;
    
    return scalar(@{ $self->uids });
}


1;
