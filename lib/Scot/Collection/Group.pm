package Scot::Collection::Group;
use lib '../../../lib';
use Data::Dumper;
use Moose 2;
extends 'Scot::Collection';

override api_create => sub {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $json    = $request->{request}->{json};
    my $log     = $env->log;

    my $group   = $self->create($json);

    if ( $group ) {
        return $group;
    }
    $log->error("Failed to create GROUP from ", { fitler => \&Dumper, value => $request });
    return undef;
};

override get_subthing => sub {
    my $self        = shift;
    my $thing       = shift;
    my $id          = shift;
    my $subthing    = shift;
    my $env         = $self->env;
    my $mongo       = $env->mongo;
    my $log         = $env->log;
    $id += 0;

    if ( $subthing eq "user" ) {
        my $col = $mongo->collection('Group');
        my $obj = $col->find_one({id => $id});
        my $name    = $obj->name;

        my $subcol = $mongo->collection('User');
        my $cur     = $subcol->find({groups=>$name});

        return $cur;
    }

};

1;
