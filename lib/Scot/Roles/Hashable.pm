package Scot::Roles::Hashable;

use Moose::Role;
use Data::Dumper;
use namespace::autoclean;

=head1 Role

Scot::Roles::Hashable

=head1 Description

Role allows an object to "serialize" itself into a hash reference.
Really convienient to then pass to Mongo for backing to the db.

=head1 Methods

=over 4

=item C<as_hash>

Given an array_ref of attributes to create the hash with,
returns a hash reference with those attributes as keys
only works on attributes with the serializable meta attribute

=cut

sub as_hash {
    my $self        = shift;
    my $fields      = shift;
    my $attr_ref    = $self->get_serializable_attributes();
    my $href        = {};
    my $log         = $self->log;

    local $Data::Dumper::Indent = 2;

    foreach my $attribute ( @$attr_ref ) {
        # $log->debug("getting attr $attribute");
        if ($self->is_selected_field($fields, $attribute)) {
            if ( $attribute eq "_id" ) {
                my $oid = $self->$attribute;
                my $unblessedoid;
                if (defined $oid and ref($oid) eq "MongoDB::OID") {
                    $unblessedoid = $oid->to_string;
                }
                $href->{$attribute} = $unblessedoid;
            }
            else {
                $href->{$attribute} = $self->$attribute;
            }
        }
    }
    return $href;
}

=item C<as_serializable_hash>

same?

=cut

sub as_serializable_hash {
    my $self        = shift;
    my $fields_aref = shift;
    my $href        = {};

    my $meta    = $self->meta;
    my @attrs   = $meta->get_all_attributes;

    foreach my $attribute (@attrs) {
        my $desc_href   = $attribute->description;
        my $serialize   = $desc_href->{serializable};
        my $attr_name   = $attribute->name;
        if ( defined $serialize and $serialize > 0 ) {
            if ( $self->is_selected_field($fields_aref, $attr_name) ) {
                if ($attr_name eq "_id") {
                    $href->{$attr_name} = $self->unbless_mongo_oid($attr_name);
                }
                else {
                    $href->{$attr_name} = $self->$attr_name;
                }
            }
        }
    }
    return $href;
}

sub unbless_mongo_oid {
    my $self        = shift;
    my $oid         = shift;

    if ( defined $oid and ref($oid) eq "MongoDB::OID" ) {
        return $oid->to_string;
    }
    return undef;
}



sub as_hash_no_oid {
    my $self    = shift;
    my $fields  = [qw(-_id)];
    return $self->as_hash($fields);
}

=item C<is_selected_field>



=cut

sub is_selected_field {
    my $self    = shift;
    my $faref   = shift;
    my $attr    = shift;

    
    unless ( defined $faref ) {
        return 1;
    }
    if ( scalar(@{$faref}) < 1) {
        return 1;
    }
    if ( scalar(@{$faref}) == 1 and ! defined $faref->[0] ) {
        return 1;
    }
    if ( grep { /^-$attr$/ } @$faref ) {
        return undef;
    }

    if ( grep { /^$attr$/ } @$faref ) {
        return 1;
    }

    return undef;
}

sub get_serializable_attributes {
    my $self    = shift;
    my $aref    = [];
    my $log     = $self->log;

    my $meta    = $self->meta;
    my @attrs   = $meta->get_all_attributes;

    foreach my $attr (@attrs) {
        my $href        = $attr->description;
        my $serialize   = $href->{serializable}; 
        if (defined $serialize and $serialize > 0) {
            push @{$aref}, $attr->name;
        } 
    }
    return $aref;
}

sub get_gridviewable {
    my $self    = shift;
    my $href    = {};
    my $meta    = $self->meta;
    my @attrs   = $meta->get_all_attributes;
    my $log     = $self->log;

    foreach my $attr (@attrs) {
        my $dhref   = $attr->description;
        my $gview   = $dhref->{gridviewable};
        if (defined $gview and $gview > 0) {
            $href->{$attr->name} = {
                colname => $dhref->{alt_col_name} // $attr->name,
                altsub  => $dhref->{alt_data_sub},
            };
        }
    }
    return $href;
}

sub grid_view_hash {
    my $self            = shift;
    my $req_fields      = shift;
    my $grid_href       = $self->get_gridviewable;
    my $datahref        = {};
    my $log             = $self->log;

    $log->trace("Getting Grid View Hash");
    $log->trace("Request Columns ". Dumper($req_fields));

    foreach my $grid_col (keys %$grid_href) {

        $log->trace("Grid column : $grid_col");

        if ( $self->is_selected_field($req_fields, $grid_col) ) {

            $log->trace("selected...");

            my $colhref = $grid_href->{$grid_col};
            my $altsub  = $colhref->{alt_data_sub};
            my $altcol  = $colhref->{colname};

            if ( defined $altsub ) {
                $log->trace("alternate sub detected...");
                if ( $altsub eq "all_taggees" ) {
                    $datahref->{$altcol} = $self->altsub();
                } 
                else {
                    $datahref->{$altcol} = $self->$altsub($self->$grid_col);
                }
            }
            else {
                $datahref->{$altcol} = $self->$grid_col;
                if ($self->col_is_int($grid_col)) {
                    # sometimes perl's typeless ness sucks
                    $datahref->{$altcol} += 0;
                }
            }
        }
    }
    return $datahref;
}

sub col_is_int {
    my $self    = shift;
    my $col     = shift;
    my $meta    = $self->meta;
    my $attr    = $meta->get_attribute($col);

    if (defined $attr) {
        my $constr  = $attr->type_constraint();
        return 1 if ($constr =~ /Int/);
    }
    return undef;
}

1;
__END__

=back

=head1 COPYRIGHT

Copyright (c) 2013.  Sandia National Laboratories

=cut

=head1 AUTHOR

Todd Bruner.  tbruner@sandia.gov.  505-844-9997.

=cut

=head1 SEE ALSO

=cut

=over 4

=item L<Scot::Controller::Handler>

=item L<Scot::Util::Mongo>

=item L<Scot::Model>

=back
