package Scot::Role::GetTagged;

use Moose::Role;
use Data::Dumper;
use namespace::autoclean;

# to be consumed by a Scot::Collection

sub get_tagged {
    my $self    = shift;
    my $match   = {
        tags    => { '$all' => \@_ },
    };
    
    my $cursor  = $self->find($match);

    unless (defined $cursor) {
        $self->log->error("Failed query ", { filter => \&Dumper, value => $match });
        return undef;
    }
    return $cursor;
}


1;
