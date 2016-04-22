package Scot::Collection::Tag;

use lib '../../../lib';
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTargeted
);

# tags can be created from a post to /scot/v2/tag
# ( also "put"ting a tag on a thing will create one but not in this function

sub create_from_api {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->trace("Create Tag from API");
    $log->debug("request is ",{ filter=>\&Dumper, value=>$request });

    my $json    = $request->{request}->{json};

    my $value       = $json->{value};
    my $note        = $json->{note};

    unless ( defined $value ) {
        $log->error("Error: must provide the tag as the value param");
        return { error_msg => "No Tag value provided" };
    }

    $value =~ s/ /_/g;  # tags should not have spaces!

    my $tag_obj         = $self->find_one({ value => $value });

    unless ( defined $tag_obj ) {
        my $href    = { value => $value };
        $href->{note} = $note if $note;
        $tag_obj    = $self->create($href);
        $env->mongo->collection("History")->add_history_entry({
            who     => "api",
            what    => "tag created",
            when    => $env->now(),
            targets => { id => $tag_obj->id, type => "tag" },
        });
    }

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
    my $log = $env->log;

    $log->debug("Add_tag_to $thing:$id => $tag");

    my $tag_obj         = $self->find_one({ value => $tag });
    unless ( defined $tag_obj ) {
        $log->debug("created new tag $tag");
        $tag_obj    = $self->create({
            value    => $tag,
        });
    }

    $env->mongo->collection("Link")->create_link({
        type => $thing,
        id   => $id + 0,
    },{
        type   => "tag",
        id     => $tag_obj->id + 0,
    });

    return $tag_obj;
}

sub get_linked_tags {
    my $self    = shift;
    my $obj     = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $lnkcol  = $mongo->collection('Link');
    my $target_type  = $obj->get_collection_name;
    my $target_id    = $obj->id;
    my $target_link_cursor  = $lnkcol->get_links(
        $target_type,
        $target_id,
        "tag"
    );
    my @ids = ();
    while ( my $link = $target_link_cursor->next ) {
        my $pair = $link->pair;
        if ( $pair->[0]->{type} eq $target_type ) {
            push @ids, $pair->[1]->{id};
        }
        else {
            push @ids, $pair->[0]->{id};
        }
    }
    my $cursor  = $self->find({id => {'$in' => \@ids}});
    return $cursor;
}


1;

