package Scot::Collection::Tag;

use lib '../../../lib';
use Moose 2;

extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTargeted
);

# tag creation or update
sub create_from_handler {
    my $self    = shift;
    my $handler = shift;
    my $env     = $handler->env;
    my $log     = $env->log;

    $log->trace("Custom create in Scot::Collection::Tag");

    my $build_href  = $handler->get_request_params->{params};
    my $target_type = $build_href->{target_type};
    my $target_id   = $build_href->{target_id};
    my $value        = $build_href->{value};

    unless ( defined $target_type ) {
        $log->error("Error: must provide a target type");
        return { error_msg => "Tags must have a target_type defined"};
    }

    unless ( defined $target_id ) {
        $log->error("Error: must provide a target id");
        return { error_msg => "Tags must have a target_id defined"};
    }

    unless ( defined $value ) {
        $log->error("Error: must provide the tag as the value param");
        return { error_msg => "No Tag value provided" };
    }

    my $tag_collection  = $handler->env->mongo->collection("Tag");
    my $tag_obj         = $tag_collection->find_one({ value => $value });

    unless ( defined $tag_obj ) {
        $tag_obj    = $tag_collection->create({
            value    => $value,
        });
    }

    my $linkcol  = $env->mongo->collection("Link");
    $linkcol->create_bidi_link({
        type    => "tag",
        id      => $tag_obj->id,
    },{
        type    => $target_type,
        id      => $target_id,
    });

    $env->mongo->collection("History")->add_history_entry({
        who     => "api",
        what    => "tag applied to $target_type : $target_id",
        when    => $env->now(),
        targets => [ { id => $tag_obj->id, type => "tag" } ],
    });

    return $tag_obj;

}

sub get_tag_completion { 
    my $self    = shift;
    my $string  = shift;
    my @results = ();
    my $cursor  = $self->find({
        value    => /$string/
    });
    @results    = map { $_->value } $cursor->all;
    return wantarray ? @results : \@results;
}

sub add_tag_to {
    my $self    = shift;
    my $thing   = shift;
    my $id      = shift;
    my $tag     = shift;

    my $env = $self->env;

    my $tag_obj         = $self->find_one({ value => $tag });
    unless ( defined $tag_obj ) {
        $tag_obj    = $self->create({
            value    => $tag,
        });
    }

    $env->mongo->collection("Link")->create_bidi_link({
        type => $thing,
        id   => $id,
    },{
        type   => "tag",
        id     => $tag_obj->id,
    });

    return $tag_obj;
}


1;
