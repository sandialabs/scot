package Scot::Collection::Entitytype;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;
extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
    Scot::Role::GetTargeted
);

sub entity_type_exists {
    my $self    = shift;
    my $value   = shift;
    my $type    = shift;
    my $obj     = $self->find_one({ value => $value, type => $type });

    if ( defined $obj ) {
        return 1;
    }
    return undef;
}

sub api_subthing {
    my $self    = shift;
    my $req     = shift;
    my $thing   = $req->{collection};
    my $id      = $req->{id} + 0;
    my $subthing= $req->{subthing};
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;

    if ( $subthing eq "entity" ) {
        my $et  = $self->find_one({id => $id});
        return $mongo->collection('Entity')->find({type => $et->value});
    }

    die "Unsupported subthing request ($subthing) for Entity";

}

sub autocomplete {
    my $self    = shift;
    my $frag    = shift;
    my $cursor  = $self->find({
        value => /$frag/
    });
    my @records = map { {
        id  => $_->{id}, key => $_->{value}
    } } $cursor->all;
    return wantarray ? @records : \@records;
}

1;
