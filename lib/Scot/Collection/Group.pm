package Scot::Collection::Group;
use lib '../../../lib';
use Data::Dumper;
use HTML::Entities;
use Moose 2;
extends 'Scot::Collection';

override api_create => sub {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $json    = $request->{request}->{json};
    my $log     = $env->log;

    my $gname   = $json->{groupname};
    $json->{groupname} = encode_entities($gname);
    my $desc    = $json->{description};
    $json->{description} = encode_entities($desc);

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
    my $mongo       = $self->meerkat;
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

    if ( $subthing eq "link" ) {
        return $mongo->collection('Link')
                    ->get_links_by_target({
                        id      => $id,
                        type    => $thing,
                    });
    }

};

sub api_subthing {
    my $self        = shift;
    my $req         = shift;
    my $thing       = $req->{collection};
    my $id          = $req->{id} + 0;
    my $subthing    = $req->{subthing};
    my $mongo       = $self->meerkat;
    my $log         = $self->env->log;

    $log->debug("api_subthing /$thing/$id/$subthing");

    if ( $subthing eq "user" ) {
        my $group = $mongo->collection('Group')->find_iid($id);
        return $mongo->collection('User')->find({
            groups   => $group->name,
        });
    }

    die "unsupported subthing: $subthing";
}


1;
