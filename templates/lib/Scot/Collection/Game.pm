package Scot::Collection::Game;
use lib '../../../lib';
use Moose 2;
extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
);

=head1 Name

Scot::Collection::Game

=head1 Description

Custom collection operations for Game

=head1 Methods

=over 4


=cut


sub upsert {
    my $self    = shift;
    my $type    = shift;
    my $href    = shift;
    my $user    = $href->{_id};
    my $count   = $href->{total};
    my $tt      = $href->{tooltip};

    my $obj     = $self->find_one({ username => $user, category => $type });
    if ( $obj ) {
        $obj->update({'$set' => { count => $count }});
    }
    else {
        $obj    = $self->create({
            username    => $user,
            category    => $type,
            count       => $count,
            tooltip     => $tt,
        });
    }
    return $obj;
}

sub upsert_native {
    my $self    = shift;
    my $type    = shift;
    my $href    = shift;
    my $user    = $href->{_id};
    my $count   = $href->{total};
    my $col     = $self->mongo_collection('Game');
    
    return $col->update_one(
        { username => $user, category => $type },
        { '$set' => { count => $count } },
        { 'upsert' => 1 }
    );
}
    


1;
