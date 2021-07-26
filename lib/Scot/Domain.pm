package Scot::Domain;

use strict;
use warnings;
use experimental 'signatures';
use Data::Dumper;
use Moose;

has log => (
    is      => 'ro',
    isa     => 'Log::Log4perl::Logger',
    required=> 1,
);

has mongo   => (
    is      => 'ro',
    isa     => 'Meerkat',
    required=> 1,
);

has skipfields  => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [qw(sort columns limit offset withsubject)] },
);

has taglikefields   => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [qw(tag source)] },
);

has exactfields => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [qw(status)] },
);

sub build_mongo_query ($self, $request) {
    my $query   = {};
    my $log     = $self->log;
    my $params  = $request->{data}->{params};
    my $datefields  = $self->datefields;

    foreach my $key (%$params) {
        my $value   = $params->{$key};
        if ( $self->is_date_field($key) ) {
            $query->{$key} = $self->parse_datefield_match($value);
        }
        elsif ( $self->is_handler_time_field($key) ) {
            $query->{$key} = ($key eq "start") ? 
                { '$gte' => $value } :
                { '$lte' => $value };
        }
        elsif ( $self->is_numeric_field($key) ) {
            $query->{$key} = $self->parse_numericfield_match($value);
        }
        elsif ( $self->is_taglike_field($key) ) {
            $query->{$key} = $self->parse_taglike_match($value);
        }
        elsif ( $self->is_exact_match_field($key) ) {
            $query->{$key} = $self->parse_exact_match($value);
        }
        else {
            if ( $self->is_value_numeric($value) ) {
                $query->{$key} = $self->parse_numericfield_match($value);
            }
            else {
                $query->{$key} = $self->parse_stringfield_match($value);
            }
        }
    }
    my $projection  = $self->build_projection($request);
    my $limit       = $self->build_limit($request);
    my $skip        = $self->build_offset($request);
    my $sort        = $self->build_sort($request);

    my $options = {};

    $options->{limit}       = $limit if ($limit);
    $options->{projection}  = $projection if ($projection);
    $options->{skip}        = $skip if ($skip);
    $options->{sort}        = $sort if ($sort);
        
    $log->trace("Query = ",{filter => \&Dumper, value => $query});
    return $query, $options;
}

sub is_date_field ($self, $fieldname) {
    my $fields  = $self->datefields;
    return grep {/$fieldname/} @$fields;
}

sub is_handler_time_field ($self, $fieldname) {
    my $fields  = $self->handler_time_fields;
    return grep {/$fieldname/} @$fields;
}

sub is_numeric_field ($self, $fieldname) {
    my $fields  = $self->numfields;
    return grep {/$fieldname/} @$fields;
}

sub is_taglike_field ($self, $fieldname) {
    my $fields  = $self->taglikefields;
    return grep {/$fieldname/} @$fields;
}

sub is_exact_match_field ($self, $fieldname) {
    my $fields  = $self->exactfields;
    return grep {/$fieldname/} @$fields;
}

sub is_value_numeric ($self, $value) {
    return $value =~ /^\d+$/;
}

sub build_sort ($self, $request) {
    my @s   = ();

    my $sort_ref = $request->{data}->{params}->{sort};

    if ( defined $sort_ref ) {
        if (ref($sort_ref) ne "ARRAY" ) {
            $sort_ref = [ $sort_ref ];  # turn scalar into an array
        }
        foreach my $term (@$sort_ref) {
            if ( $term =~ /^-(\S+)$/ ) { # one or more word char preceded by -
                push @s, $1, -1;         # mongo drive require an ordered doc (array)
            }
            elsif ( $term =~ /^\+(\S+)$/ ) { # preceded by a +
                push @s, $1, 1;
            }
            else {  # default is +
                push @s, $term, 1;
            }
        }
    }
    return wantarray ? @s : \@s;
}

sub build_limit ($self, $request) {
    my $limit       = undef;
    my $limit_req   = $request->{data}->{params}->{limit};
    if (defined $limit_req) {
        if ( $self->is_value_numeric($limit_req) ) {
            $limit = $limit_req;
        }
    }
    return $limit;
}

sub build_projection ($self, $request) {
    my %projection  = ();
    my $columns = $request->{data}->{params}->{columns};

    if ( defined $columns and ref($columns) eq "ARRAY" ) {
        foreach my $col (@$columns) {
            $projection{$col} = 1;
        }
        if ( scalar(keys %projection) != 0 ) {
            return wantarray ? %projection : \%projection;
        }
    }
    return undef;
}

sub build_offset ($self, $request) {
    my $skip    = 0;
    my $reqskip = $request->{data}->{params}->{offset};
    if ( $reqskip =~ /^\d+$/ ) {
        $skip = $reqskip;
    }
    return $skip;
}
    

1;
