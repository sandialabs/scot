package Scot::Role::Hashable;

use Moose::Role;

sub as_hash {
    my $self    = shift;
    my $fields  = shift;
    my $meta    = $self->meta;
    my %hash    = ();

    my $filter;
    if (defined $fields) {
        $filter++;
    }

    ATTR:
    foreach my $attr ( $meta->get_all_attributes ) {
        my $name     = $attr->name;
        if ( $filter ) {
            next ATTR unless ( grep {/$name/} @$fields );
        }
        unless ( $name =~ /^_/ ) {
            $hash{$name} = $self->$name;
        }
    }
    return wantarray ? %hash : \%hash;
}

1;
