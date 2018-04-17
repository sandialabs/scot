package Scot::Util::MongoQueryMaker;

use Data::Dumper;
use v5.18;
use Moose;
extends 'Scot::Util';

sub parse_datefield_match {
    my $self    = shift;
    my $value   = shift;
    my $match   = {};

    # accept an array of epochs or a string of , seperated epochs


    my @epochs  = ();
    if ( ref($value) eq "ARRAY" ) {
        @epochs = sort { $a <=> $b } @$value;
    }
    else {
        my @items   = split(/,/, $value);
        unless (scalar(@items) == 2) {
            return { error => "invalid datefield match string" };
        }

        @epochs = sort { $a <=> $b } @items;
    }
    if ( scalar(@epochs) < 2 ) {
        return { error => "must have 2 epochs for date range filter" };
    }
    $match->{'$gte'}    = $epochs[0];
    $match->{'$lte'}    = $epochs[-1];

    return $match;
}

sub parse_handler_match {
    my $self    = shift;
    my $value   = shift;
    my $match   = {};
}



sub get_op_val {
    my $self    = shift;
    my $item    = shift;
    my $regex   = qr{^([><=]+)(\d+)$};
    my ($op,$val)   = $item =~ /$regex/;
    unless ($op) {
        $op = "=";
    }
    unless ($val) {
        $val = $item;
    }
    return $op,$val+0;
}

sub get_mongo_op {
    my $self    = shift;
    my $op      = shift;
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

sub parse_numericfield_match {
    my $self    = shift;
    my $value   = shift;
    my $match   = {};

    # accept the following:
    # single number     => exact match
    # array of numbers  => $in
    # expression like "23<=x<=27" => { $gte: 23 },{$lte: 27}
    # (future) expression like "x>5|x<3"   => $or: [{ $gt:5 },{$lt:3}]
    # single number prepended with !3 (not)  => { $ne: 3 }
    # array of numbers !1 !3 !4 => { $nin: [ 1,3,4 ] }
    #    note any negation in the array will be the same as all being negated
    #    e.g.  1 3 !5 6 would yield { $nin: [ 1 3 5 6 ] }

    if ( ref($value) eq "ARRAY" ) {
        my $negation = 0;
        my @set;
        foreach my $v (@$value) {
            unless ( $v =~ /\d+/ ) {
                return { error => "need numbers for numeric match" };
            }
            if ( $v =~ /^\!(\d+)/ ) {
                $negation++;
                $v = $1; # pull digits off
            }
            $v += 0;
            push @set, $v;
        }
        if ( $negation > 0 ) {
            $match  = { '$nin' => \@set };
        }
        else {
            $match  = { '$in'   => \@set };
        }
    }
    else {
        # single value or expression
        if ( $value =~ /[\<\=\>]+/  ) {
            # expression time
            # notice I do not check for nonsensical matches
            $value =~ /(\d+)([<=>]+)x([<=>]+)(\d+)/;
            unless (defined($1)) {
                # might be x>=123
                $value =~ /^x([<=>]+)(\d+)$/;
                unless (defined($1) and defined($2) ) {
                    return { error => "invalid numeric match expression" };
                }
                my $op  = $self->get_mongo_op($1);
                my $rv  = $2 + 0;
                $match  = { $op => $rv };
                return $match;
            }

            my $lv = $1 + 0;    # left value
            my $lo = $self->get_mongo_op($2);    # left op
            my $ro = $self->get_mongo_op($3);    # right op
            my $rv = $4 + 0;    # right value
            if ( $lo eq '$in' or 
                 $ro eq '$in' or 
                 $lo eq 'error' or
                 $ro eq 'error' ) {
                return { error => "invalid numeric match expression" };
            }
            if ( $lv == 0 and $rv == 0 ) {
                return { error => "invalid numeric match expression " };
            }
            if ( ($lo =~ /lt/ and $ro =~ /lt/) or 
                 ($lo =~ /gt/ and $ro =~ /gt/)) {
                if ( $lo eq '$lt' or $lo eq '$lte' ) {
                    $lo =~ s/l/g/;
                }
                elsif ( $lo eq '$gt' or $lo eq '$gte' ) {
                    $lo =~ s/g/l/;
                }
            }
            $match  = {
                $lo => $lv,
                $ro => $rv,
            };
        }
        else {
            unless ( $value =~ /\d+/ ) {
                return { error => "need numbers for numeric match" };
            }
            if ( $value =~ /^\!(\d+)/ ) {
                $value  = $1;
                $match  = { '$ne' => $value + 0};
            }
            else {
                $match  = $value + 0;
            }
        }
    }
    return $match;            
}

sub parse_stringfield_match {
    my $self    = shift;
    my $value   = shift;
    my $match   = {};

    # we expect a regex friendly string to match, that's it.
    $match  =  qr/$value/i ;
    return $match;
}

sub parse_source_tag_match {
    my $self    = shift;
    my $value   = shift;
    my $match   = {};

    # accept a single value "foo"
    # or array of values "foo", "bar", "boom"
    # allow negation "foo", "bar", "!boom"

    if ( ref($value) eq "ARRAY" ) {

        my @in  = ();
        my @nin = ();

        foreach my $v (@$value) {
            if ( $v =~ /^\!(\S+)/ ) {
                push @nin, $1;
            }
            else {
                push @in, $v;
            }
        }
        if ( scalar(@in) > 0 ) {
            $match->{'$all'}  = \@in;
        }
        if ( scalar(@nin) > 0 ) {
            $match->{'$nin'}  = \@nin;
        }
        return $match;
    }

    # single value 
    unless  ( $value =~ /,/ ) {
        if ( $value =~ /^\!(.+)/ ) {
            $match = { '$ne'    => $1 };
        }
        else {
            $match = $value;
        }
        return $match;
    }

    my @items   = split(/,/, $value);

    if ( scalar(@items) == 1 ) {
        # we might have pipes or singlular value

        @items = split(/\|/, $value);

        my @in;

        foreach my $item (@items) {
            push @{$match->{'$in'}}, $item;
        }
    }
    else {
        foreach my $item (@items) {
            push @{$match->{'$all'}}, $item;
        }
    }
    return $match;
}

sub build_match_ref {
    my $self    = shift;
    my $params  = shift;    # ... href of html params from request
    my %mquery  = ();       # ... the resulting mongo query

    # TODO: abstract this somewhere so these are known meta properties
    my @skipfields   = qw(sort columns limit offset withsubject);
    my @datefields   = qw(when updated created occurred discovered reported);
    my @numfields    = qw(id views entry_count alert_count);
    my @tagsrcfields = qw(tag source);
    my @exactfields  = qw(status);
    my @handler      = qw(start end);

    foreach my $key (keys %$params) {

        next if ( grep {/$key/} @skipfields );

        my $value   = $params->{$key};

        if ( grep {/$key/} @datefields ) {
            $mquery{$key} = $self->parse_datefield_match($value);
        }
        elsif ( grep {/$key/} @handler ) {
            if ($key eq "start" ) {
                $mquery{$key} = { '$gte' => $value };
            }
            else {
                $mquery{$key} = { '$lte' => $value };
            }
        }
        elsif ( grep {/$key/} @numfields ) {
            $mquery{$key} = $self->parse_numericfield_match($value);
        }
        elsif ( grep {/$key/} @tagsrcfields ) {
            $mquery{$key} = $self->parse_source_tag_match($value);
        }
        elsif ( grep {/$key/} @exactfields ) {
            $mquery{$key} = $self->parse_exact_match($value);
        }
        else {
            # stringfield
            $mquery{$key} = $self->parse_stringfield_match($value);
        }
    }
    say "Matching: ", Dumper(\%mquery);
    return wantarray ? %mquery : \%mquery;
}

sub parse_exact_match {
    my $self    = shift;
    my $value   = shift;
    my $match   = {};

    # we expect a regex friendly string to match, that's it.
    $match  = $value;
    return $match;
}

sub build_update_command {
    my $self    = shift;
    my $req     = shift;
    my $params  = $req->{request}->{params};
    my $json    = $req->{request}->{json};
    my %update  = ();

    if ( defined $params ) {
        foreach my $key (%$params) {
            my $value = $params->{$key};
            if ( $key eq "groups" ) {
                # if all groups are removed, put in the admin group(s)
                if ( scalar(@{$value->{read}}) < 1 ) { 
                    $update{$key}{read} = $self->env->admin_groups;
                }
                if ( scalar(@{$value->{modify}}) < 1) {
                    $update{$key}{modify} = $self->env->admin_groups;
                }
            }
            else {
                $update{$key} = $value;
            }
        }
    }
    if ( defined $json ) {
        foreach my $key (keys %$json) {
            if ( $key =~ /^\{/ ) {
                next;
            }
            $update{$key} = $json->{$key};  # json will overwrite params
        }
    }
    # $update{updated} = $self->env->now;
    return wantarray ? %update : \%update;
}


1;
