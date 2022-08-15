package Scot::Mquery;

use Moose;
use feature qw(signatures);
no warnings qw(experimental::signatures);


has field_parsers => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    builder     => '_build_field_parsers',
);


sub _build_field_parsers ($self) {
    my %parsers = (
        sort    => 'skip',
        columns => 'skip',
        limit   => 'skip',
        offset  => 'skip',
        withsubject => 'skip',
        when        => 'date',
        updated     => 'date',
        created     => 'date',
        occurred    => 'date',
        discovered  => 'date',
        reported    => 'date',
        id          => 'numeric',
        views       => 'numeric',
        entry_count => 'numeric',
        alert_count => 'numeric',
        tag         => 'source_tag',
        source      => 'source_tag',
        status      => 'exact',
        start       => 'handler',
        end         => 'handler',
    );
    return \%parsers;
}

sub get_op_value ($self, $item) {
    my $regex        = qr{^([<>=]+)(\d+)$};
    my ($op, $value) = $item =~ /$regex/;
    $op     = '='   if ( ! $op);
    $value  = $item if (!$value);
    return $op, $value + 0;
}


sub get_mongo_op ($self, $op) {
    return '$in'    unless (defined $op);
    return '$in'    if ($op eq "=" );
    return '$gte'   if ( $op eq ">=" );
    return '$gte'   if ( $op eq "=>" );
    return '$gt'    if ( $op eq ">" );
    return '$lte'   if ( $op eq "<=" );
    return '$lte'   if ( $op eq "=<" );
    return '$lt'    if ( $op eq "<" );
    return 'error';
}


sub parse_stringfield_match ($self, $value) {
    return qr/$value/i;
}


sub invalid_op ($self, $op) {
    return ( $op eq '$in' or $op eq 'error' );
}

sub build_match_ref ($self, $params) {
    my %mquery  = ();       # ... the resulting mongo query

    foreach my $key (keys %$params) {

        my $parser  = $self->field_parsers->{$key};
        $parser     = 'default' if ! defined $parser;

        next if ( $parser eq 'skip' );

        my $value   = $params->{$key};
        my $psub    = "parse_".$parser."_match";

        $mquery{$key} = $self->$psub($key, $value);
    }
    return wantarray ? %mquery : \%mquery;
}

sub parse_date_match ($self, $key, $value) {
    my @epochs  = ();

    if (ref($value) eq "ARRAY") {
        @epochs = sort { $a <=> $b } @$value;
    }
    else {
        my @items = split(/,[ ]*/, $value);
        if (scalar(@items) != 2) {
            return { error => 'invalid datefield match string' };
        }
        @epochs = sort { $a <=> $b } @items;
    }
    if (scalar(@epochs) != 2) {
        return { error => "must have 2 epochs for date range filter" };
    }
    return {
        '$gte'  => $epochs[0],
        '$lte'  => $epochs[-1],
    };
}

sub parse_handler_match ($self, $key, $value) {
    if ( $key eq "start" ) {
        return { '$gte' => $value };
    }
    return { '$lte' => $value };
}

sub parse_numeric_match ($self, $key, $value) {

    if ( $self->value_is_simple_number($value)) {
        if ($value =~ /^\!(\d+)/) {
            return { '$ne' => $1 };
        }
        return $value;
    }

    if ( $self->value_is_array($value)) {
        return $self->process_numeric_array($value);
    }

    if ( $self->value_is_simple_inequality($value)) {
        return $self->process_simple_inequality($value);
    }

    if ( $self->value_is_range_expression($value)) {
        return $self->process_range_expression($value);
    }
    return { error => 'malformed numeric match' };
}

sub value_is_simple_number ($self, $value) {
    return $value =~ /^[\!]*\d+$/;
}

sub value_is_array ($self, $value) {
    return ref($value) eq "ARRAY";
}

sub value_is_simple_inequality ($self, $value) {
    $value =~ /^x([<=>]+)(\d+)$/;
    return defined $1;
}

sub value_is_range_expression ($self, $value) {
    $value =~ /^(\d+)([<=>]+)x([<=>]+)(\d+)$/;
    return (
        defined $1 and defined $2 and defined $3 and defined $4
    );
}

sub process_numeric_array ($self, $value) {
    my @i   = ();
    my $neg = 0;
    foreach my $v (@$value) {
        if ( $v =~ /^(\d+)$/ ) {
            push @i, $1+0;
            next;
        }
        if ( $v =~ /^\!(\d+)$/ ) {
            $neg++;
            push @i, $1+0;
            next;
        }
        return { error => 'non-numeric values in numeric array match' };
    }
    if ( $neg ) {
        return { '$nin' => \@i };
    }
    return { '$in' => \@i };
}

sub process_simple_inequality ($self, $value) {
    $value =~ /^x([<=>]+)(\d+)$/;
    my $op  = $self->get_mongo_op($1);
    return { $op => $2 };
}

sub process_range_expression ($self, $value) {
    $value  =~ /^(\d+)([<=>]+)x([<=>]+)(\d+)$/;
    my $a   = $1;
    my $lc  = $2;
    my $rc  = $3;
    my $b   = $4;

    if ( $a >= $b ) {
        return {
            error => 'first number must be less than last in range comparison'
        };
    }

    if ( $lc ne $rc ) {
        # a>=x<=b
        if ( $lc =~ />/ and $rc =~ /</ ) {
            # degenerate case that yields x<=a
            my $op  = $self->get_mongo_op($rc);
            return { $op => $a };
        }
        if ( $lc =~ /</ and $rc =~ />/ ) {
            # another degenerate that yields x>=b
            my $op  = $self->get_mongo_op($rc); 
            return { $op => $b };
        }
    }

    if ( $lc =~ /<=/ or $lc =~ /=</ ) {
        return { '$gte' => $a, '$lte' => $b };
    }
    if ( $lc =~ /</ ) {
        return { '$gt' => $a, '$lt' => $b };
    }
    if ( $lc =~ />=/ or $lc =~ /=>/ ) {
        return { '$lte' => $a, '$gte' => $b };
    }
    if ( $lc =~ />/ ) {
        return { '$lt' => $a, '$gt' => $b };
    }
    return { error => 'malformed range operation' };
}


sub parse_source_tag_match ($self, $key, $value) {
    my $match   = (ref($value) eq "ARRAY") ?
        $self->parse_source_tag_array($key, $value) :
        $self->parse_source_tag_single($key, $value);
    return $match;
}

sub parse_source_tag_array ($self, $key, $value) {
    my @in  = ();
    my @nin = ();
    my $match   = {};

    foreach my $v (@$value) {
        if ( $v =~ /^\!(\S+)/ ) {
            push @nin, $1;
        }
        else {
            push @in, $v;
        }
    }

    $match->{'$all'} = \@in  if (scalar(@in) > 0);
    $match->{'$nin'} = \@nin if (scalar(@nin) > 0);
    return $match;
}

sub parse_source_tag_single($self, $key, $value) {
    if (! $value =~ /,/ ) {
        if ($value =~ /^\!(\S+)/ ) {
            return { '$ne' => $1 };
        }
        return $value;
    }
    my @items = split(/,[ ]*/, $value);

    if (scalar(@items) == 1) {
        @items = split(/\|/, $value);
        return { '$in'  => \@items };
    }

    return $self->parse_source_tag_array($key, \@items);
}

sub parse_exact_match ($self, $key, $value) {
    return $value;
}

sub parse_default_match ($self, $key, $value) {
    if ( $value =~ /^\d+$/ ) {
        return $self->parse_numeric_match($key, $value);
    }
    return $self->parse_string_match($key, $value);
}

sub parse_string_match ($self, $key, $value) {
    return qr/$value/i;
}

sub build_update_command ($self, $params, $json) {
    my %update  = ();

    # accept from both params and json, but json overwrites any conflict

    if ( defined $params) {
        foreach my $key (keys %$params) {
            my $value = $params->{$key};
            if ($key ne "groups") {
                $update{$key} = $value;
                next;
            }
            if ($self->all_groups_removed('read', $value)) {
                return { error => 'update would remove all read groups' };
            }
            if ($self->all_groups_removed('modify', $value)) {
                return { error => 'update would remove all modify groups' };
            }
            $update{$key} = $value;
        }
    }
    if (defined $json) {
        foreach my $key (keys %$json) {
           next if ($key =~ /^\{/) ;
           $update{$key} = $json->{$key};
        }
    }
    return wantarray ? %update : \%update;
}

sub all_groups_removed ($self, $type, $value) {
    return scalar(@{$value->{$type}}) == 0;
}

1;
