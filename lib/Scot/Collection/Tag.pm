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
    my $text        = $build_href->{text};

    unless ( defined $target_type ) {
        $log->error("Error: must provide a target type");
        return { error_msg => "Tags must have a target_type defined"};
    }

    unless ( defined $target_id ) {
        $log->error("Error: must provide a target id");
        return { error_msg => "Tags must have a target_id defined"};
    }

    unless ( defined $text ) {
        $log->error("Error: must provide the tag as the text param");
        return { error_msg => "No Tag text provided" };
    }

    my $tag_collection  = $handler->env->mongo->collection("Tag");
    my $tag_obj         = $tag_collection->find_one({ text => $text });

    unless ( defined $tag_obj ) {
        $tag_obj    = $tag_collection->create({
            text    => $text,
            targets => [{
                type    => $target_type,
                id      => $target_id,
            }],
        });
    }
    else {
        $tag_obj->update_add( targets => {
            type    => $target_type,
            id      => $target_id,
        });
    }
    $tag_obj->update_add( occurred => $env->now );

    return $tag_obj;

}

sub get_tags {
    my $self    = shift;
    my %params  = @_;

    my $id      = $params{target_id};
    my $thing   = $params{target_type};

    my $cursor  = $self->find({
        targets => {
            '$elemMatch' => {
                target_type => $thing,
                target_id   => $id,
            },
        },
    });
    my $count   = $cursor->count;
    return $cursor;
}

sub get_tag_completion { 
    my $self    = shift;
    my $string  = shift;
    my @results = ();
    my $cursor  = $self->find({
        text    => /$string/
    });
    @results    = map { $_->text } $cursor->all;
    return wantarray ? @results : \@results;
}

sub add_tag_to {
    my $self    = shift;
    my $thing   = shift;
    my $id      = shift;
    my $tag     = shift;

    my $env = $self->env;

    my $tag_obj         = $self->find_one({ text => $tag });
    unless ( defined $tag_obj ) {
        $tag_obj    = $self->create({
            text    => $tag,
            targets => [{
                type    => $thing,
                id      => $id,
            }],
        });
    }
    else {
        $tag_obj->update_add( targets => {
            type    => $thing,
            id      => $id,
        });
    }
    $tag_obj->update_add( occurred => $env->now );

    return $tag_obj;
}


1;
