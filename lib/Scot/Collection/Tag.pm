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

override api_create => sub {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $self->log;

    $log->trace("Create Tag from API");
    $log->debug("request is ",{ filter=>\&Dumper, value=>$request });

    my $json    = $request->{request}->{json};

    my $value       = lc($json->{value});
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
        $self->meerkat->collection("History")->add_history_entry({
            who     => $request->{user},
            what    => "tag created",
            when    => $self->now(),
            target  => { id => $tag_obj->id, type => "tag" },
        });
    }

    return $tag_obj;

};

sub autocomplete { 
    my $self    = shift;
    my $string  = shift;
    my $env     = $self->env;
    my $log     = $self->log;

    $log->debug("Tag autocomplete! $string");
    my @results = ();
    my $cursor  = $self->find({
        value    => qr/$string/i
    });
    $cursor->limit(25); # to help react tags
    @results    = map { $_->{value} } $cursor->all;
    return wantarray ? @results : \@results;
}

# TODO:  this handles the adding of a tag, but what about tag removal?

sub add_tag_to {
    my $self    = shift;
    my $thing   = shift;
    my $user    = shift;
    my $id      = shift;
    $id += 0;
    my $tags    = shift;
    my $env     = $self->env;
    my $log     = $self->log;

    if ( ref($tags) ne "ARRAY" ) {
        $tags   = [ $tags ];
    }

    $log->debug("Add_tag_to     $thing:$id => ".join(',',@$tags));

    $thing = lc($thing);

    foreach my $tag (@$tags) {
        my $tag_obj         = $self->find_one({ value => $tag });
        unless ( defined $tag_obj ) {
            $log->debug("created new tag $tag");
            $tag_obj    = $self->create({
                value    => $tag,
            });
        }

        $self->meerkat->collection("Appearance")->create({
            type    => "tag",
            value   => $tag,
            apid    => $tag_obj->id,
            when    => $self->now,
            target   => {
                type    => $thing,
                id      => $id,
            }
        });
        $self->meerkat->collection("History")->add_history_entry({
            who     => $user,
            what    => "tag created",
            when    => $self->now(),
            target  => { id => $id, type => $thing },
        });
    }
    return 1;
}

# TODO: finish is needed
sub syncro_tags {
    my $self        = shift;
    my $target_type = lc(shift);
    my $id          = shift;
    my $tag_aref    = shift;
    my $env         = $self->env;
    my $log         = $self->log;

    $log->debug("syncronizing tags");

    my $current_cur = $self->meerkat->collection("Appearance")->find({
        target  => {
            type    => $target_type,
            id      => $id+0,
        },
        type    => "tag"
    });
    
}






1;

