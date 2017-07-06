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

=over 4

=item B<create_from_api($handler_ref)>

Create an event and from a POST to the handler

=cut


sub create_from_api {
    my $self    = shift;
    my $request = shift;
    my $log     = $self->env->log;

    $log->trace("Create File from API");
    $log->trace("request is ",{ filter => \&Dumper, value=>$request});


}

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
