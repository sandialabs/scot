package Scot::Collection::File;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;
extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

=head1 Name

Scot::Collection::File

=head1 Description

Custom collection operations for Files

=head1 Methods

=cut

sub autocomplete {
    my $self    = shift;
    my $frag    = shift;
    my $cursor  = $self->find({
        filename => /$frag/
    });
    my @records = map { {
        id  => $_->{id}, key => $_->{filename}
    } } $cursor->all;
    return wantarray ? @records : \@records;
}
1;
