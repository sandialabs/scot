package Scot::Role::GetByAttr;

use Data::Dumper;

use Moose::Role;
use namespace::autoclean;

# to be consumed by a Scot::Collection

sub get_by_attribute {
    my $self    = shift;
    my $match   = shift;    # { attr => value };
    
    my $cursor  = $self->find($match);

    unless (defined $cursor) {
        $self->log->error("Failed query ", { filter => \&Dumper, value => $match });
        return undef;
    }
    return $cursor;
}

1;
