package Scot::Util::Imap::Cursor;

use lib '../../../../lib';
use strict;
use warnings;
# use v5.18;
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
