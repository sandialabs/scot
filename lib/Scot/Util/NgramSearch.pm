package Scot::Util::Ngram;

# coding an implementation of the previous
# scot search in case things are weird
# with elastic

use Moose;

has ngram_length => (
    is           => 'ro',
    isa          => 'Int',
    default      => 4,
);

sub get_ngram_hash {
    my $self    = shift;
    my $text    = shift;
    my %ngrams  = ();

    for ( my $i = 0; $i < length($text); $i++ ) {
        my $snip = substr $text, $i, $self->ngram_length;
        $ngrams{$snip} = 1;
    }
    return wantarray ? %ngrams : \%ngrams;
}

sub get_ngram_changes {
    my $self    = shift;
    my $origtxt = shift;
    my $newtxt  = shift;

    my $origngrams  = $self->get_ngram_hash($origtxt);
    my $newngrams   = $self->get_ngram_hash($newtxt);

    my @additions   = ();
    my @deletions   = ();

    foreach my $newkey ( keys %$newngrams ) {
        unless ( $origngrams->{$newkey} == 1 ) {
            push @additions, $newkey;
        }
    }

    foreach my $oldkey ( keys %$origngrams ) {
        unless ( $newngrams->{$oldkey} == 1 ) {
            push @deletions, $oldkey;
        }
    }

    return {
        added_ngrams    => \@additions,
        deleted_ngrams  => \@deletions,
    };
}

sub get_query_ngrams {
    my $self    = shift;
    my $query   = shift;
    my @chars   = split(//,$query);
    my $count   = ( scalar(@chars) - ($self->ngram_length - 1) );
    my @ngrams  = ();

    for ( my $i = 0; $i < $count; $i++ ) {
        my $snip = substr($query, $i, $self->ngram_length);
        push @ngrams, $snip;
    }

    return wantarray ? @ngrams : \@ngrams;
}




1;

