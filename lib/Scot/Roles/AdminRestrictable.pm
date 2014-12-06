package Scot::Roles::AdminRestrictable;

use Moose::Role;
use namespace::autoclean;

requires 'log';

=item C<user_can_update>

some fields can be restricted so that only
1.  the admin can update

other fields, say the users tz_pref, can
be updated by admin or the user.  However,
a user should not be able update another user's pref

=cut

sub user_can_update {
    my $self    = shift;

}

sub user_can_delete {
    my $self    = shift;
    
}


1;

