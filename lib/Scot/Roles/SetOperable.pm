package Scot::Roles::SetOperable;

use Data::Dumper;
use Test::Deep::NoTest qw(eq_deeply);
use Moose::Role;
use namespace::autoclean;

=item C<add_to_set>

    when applied to a Scot::Model
    insertion_candiates_aref is array ref to things to add to set 
    attribute is the object field we are trying to add to

=cut

sub add_to_set {
    my $self                        = shift;
    my $attribute                   = shift;
    my $insertion_candidates_aref   = shift;
    my $sorted                      = shift;
    my $log                         = $self->log;

#    $log->debug("attribute is ".Dumper($attribute));

    unless ($attribute) {
        $log->error("Failed to provide an attribute to add to");
        return undef;
    }

#    $log->debug("insertion_candidates is ".Dumper($insertion_candidates_aref));

    unless ($insertion_candidates_aref) {
        $log->error("Failed to provide anything to add to set");
        return undef;
    }

    if ( ref ($insertion_candidates_aref) ne "ARRAY" ) {
        $log->error("insertion data is not array ref, will convert for you");
        $insertion_candidates_aref = [ $insertion_candidates_aref ];
    }

    my $current_aref    = $self->$attribute;
    unless ( ref($current_aref) eq  "ARRAY" ) {
        $log->error("add to set can only work on attributes of ArrayRef type.");
        $log->error("type was ".ref($current_aref));
        return undef;
    }
    my @newlist         = ();
    foreach my $item ( @$insertion_candidates_aref ) {
        if ( defined $item ) {
            if ( ref($item) eq "HASH" ) {
                unless ( grep { eq_deeply($item, $_) } @$current_aref ) {
                    push @newlist, $item;
                }
            }
            else {
                unless ( grep { /$item/ } @$current_aref ) {
                    push @newlist, $item;
                }
            }
        }
    }
    my $numadded    = scalar(@newlist);
    push @newlist, @$current_aref;
    if ( $sorted ) { 
        @newlist = sort @newlist;
    }
    $self->$attribute(\@newlist);
    return $numadded;
}

sub add_href_to_set {
    my $self        = shift;
    my $attribute   = shift;
    my $insert_aref = shift;
    my $sorted      = shift;     # the key value of hash to sort on
    my $log         = $self->log;

    unless ($attribute) {
        $log->error("Failed to provide an attribute to add href to");
        return undef;
    }

    unless ( $insert_aref ) {
        $log->error("Failed to provide anything to insert");
        return undef;
    }

    unless ( ref($insert_aref) eq "ARRAY" ) {
        $log->error("Expexted aref, so converting scalar...");
        $insert_aref = [ $insert_aref ];
    }

    my $current_aref    = $self->$attribute;
    unless ( ref($current_aref) eq  "ARRAY" ) {
        $log->error("add to set can only work on attributes of ArrayRef type.");
        return undef;
    }
    my @newlist         = ();

    foreach my $item (@$insert_aref) {
        if (defined $item) {
            unless ( grep { eq_deeply($item, $_) } @$current_aref ) {
                push @newlist, $item;
            }
        }
    }
    my $numadded    = scalar(@newlist);

    push @newlist, @$current_aref;
    if ( defined($sorted) ) {
        my $sort_sub = sub { $a->{$sorted} cmp $b->{$sorted} };
        @newlist = sort $sort_sub @newlist;
    }
    $self->$attribute(\@newlist);
    return $numadded;
}

sub pull_href_from_set {
    my $self        = shift;
    my $attribute   = shift;
    my $del_aref    = shift;
    my $log         = $self->log;

    unless ( $attribute ) {
        $log->error("Failed to provide and attribute to delete href from");
        return undef;
    }
    unless ( $del_aref ) {
        $log->error("Failed to provide aref of hashes to delete");
        return undef;
    }
    unless ( ref ($del_aref) eq "ARRAY" ) {
        $log->error("Expected an array of hashes, converting...");
        $del_aref   = [ $del_aref ];
    }

    my $current_aref    = $self->$attribute;
    unless ( ref($current_aref) eq  "ARRAY" ) {
        $log->error("PULLS can only work on attributes of ArrayRef type.");
        return undef;
    }
    my @keepers         = ();
    
    foreach my $item ( @$del_aref ) {
        if (defined $item) {
            push @keepers, grep { ! eq_deeply($item, $_) } @$current_aref;
        }
    }
    $self->$attribute(\@keepers);
    return scalar(@$current_aref) - scalar(@keepers);
}

sub pull_string_from_set {
    my $self        = shift;
    my $attribute   = shift;
    my $del_aref    = shift;
    my $log         = $self->log;


    unless ($attribute) {
        $log->error("Failed to provide and attribute to delete string from");
        return undef;
    }
    unless ($del_aref) {
        $log->error("Failed to provide strings to delete from attribute");
        return undef;
    }
    unless ( ref($del_aref) eq "ARRAY" ) {
        $log->error("expected an array of strings, converting...");
        $del_aref   = [ $del_aref ];
    }
    my $current_aref    = $self->$attribute;
    unless ( ref($current_aref) eq  "ARRAY" ) {
        $log->error("PULLS can only work on attributes of ArrayRef type.");
        return undef;
    }

    my %deleters    = map { $_ => 1 } @$del_aref;
    my @keepers     = grep ( ! defined $deleters{$_}, @{$current_aref});

    $self->$attribute(\@keepers);
    return scalar(@$current_aref) - scalar(@keepers);
}

=item C<merge_hash>

 given to href's merge them into on href and return it.

=cut

sub merge_hash {
    my $self    = shift;
    my $this    = shift;
    my $that    = shift;
    my %new     = ();
    if (defined $this) {
        if (defined $that) {
            %new     = (%$this, %$that);
        }
        else {
            %new    = %$this;
        }
    }
    else {
        if (defined $that) {
            %new    = %$that;
        }
    }
    return \%new;
}
1;
