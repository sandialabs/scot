package Scot::Role::GetTargeted;

use Moose::Role;
use Data::Dumper;
use namespace::autoclean;

# to be consumed by a Scot::Collection

sub get_targeted {
    my $self    = shift;
    my %params  = @_;

    my $match   = {
        targets => {
            target_id   => $params{target_id},
            target_type => $params{target_type},
        }
    };
    
    my $cursor  = $self->find($match);

    unless (defined $cursor) {
        $self->log->error("Failed query ", { filter => \&Dumper, value => $match });
        return undef;
    }
    return $cursor;
}

1;
