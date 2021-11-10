package Scot::Flair3::UdefRegex;

use strict;
use warnings;
use utf8;
use lib '../../../lib';
use Moose;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Data::Dumper;

has io  => (
    is      => 'ro',
    isa     => 'Scot::Flair3::Io',
    required=> 1,
);

has regex_set   => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    clearer     => 'reload',
    builder     => '_build_regex_set',
);

sub _build_regex_set ($self) {
    my @set         = ();
    my $et_cursor   = $self->io->get_active_entitytypes;

    while (my $et = $et_cursor->next) {
        my $entity_type = $et->value;
        my $match       = quotemeta($et->match);
        my $mlength     = length($match);
        my $multiword   = $et->options->{multiword};
        my $regex       = $self->build_regex($match, $multiword);

        push @set,  {
            type    => $entity_type,
            regex   => $regex,
            order   => $mlength,
            options => $et->options,
        };
    }
    # putting longest length matches first, might improve perf?
    my @sorted = sort { $b->{order} <=> $a->{order} } @set;
    return wantarray ? @sorted : \@sorted;
}


sub build_regex ($self, $match, $multiword) {
    if ( $multiword eq "yes" ) {
        return qr/($match)/i;
    }
    return qr/\b($match)\b/i;
}




__PACKAGE__->meta->make_immutable;
1;
