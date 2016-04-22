package Scot::Collection::Source;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;
extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

# source creation or update
sub create_from_api {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->trace("Create Source from API");

    my $json    = $request->{request}->{json};
    my $value   = $json->{value};
    my $note    = $json->{note};

    unless ( defined $value ) {
        $log->error("Error: must provide the source as the value param");
        return { error_msg => "No Source value provided" };
    }

    my $source_obj         = $self->find_one({ value => $value });

    unless ( defined $source_obj ) {
        $source_obj    = $self->create({
            value    => $value,
        });
        # note that targets below is handled in the History
        # collection correctly, ie. converted to Links not 
        # an embedded array
        $env->mongo->collection("History")->add_history_entry({
            who     => "api",
            what    => "source $value created",
            when    => $env->now,
            targets => { id => $source_obj->id, type => "source" } ,
        });
    }
    return $source_obj;
}

sub get_source_completion { 
    my $self    = shift;
    my $string  = shift;
    my @results = ();
    my $cursor  = $self->find({
        value    => /$string/
    });
    @results    = map { $_->value } $cursor->all;
    return wantarray ? @results : \@results;
}

sub add_source_to {
    my $self    = shift;
    my $thing   = shift;
    my $id      = shift;
    my $sources = shift;

    my $env = $self->env;
    my $log = $env->log;
    my $mongo   = $env->mongo;

    if ( ref($sources) ne "ARRAY" ) {
        $sources = [ $sources];
    }

    $log->debug("Add_source_to $thing:$id => ".join(',',@$sources));

    $thing = lc($thing);

    my $linkcol = $mongo->collection('Link');
    # $log->debug("LinkCol is ",{filter=>\&Dumper, value => $linkcol});

    foreach my $source (@$sources) {
        my $source_obj         = $self->find_one({ value => $source });
        unless ( defined $source_obj ) {
            $log->debug("created new source $source");
            $source_obj    = $self->create({
                value    => $source,
            });
        }
        $linkcol->create_link(
            { type => $thing,       id   => $id },
            { type   => "source",   id   => $source_obj->id, },
        );
    }
    return 1;
}

sub get_linked_sources {
    my $self    = shift;
    my $obj     = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $lnkcol  = $mongo->collection('Link');
    my $target_type  = $obj->get_collection_name;
    my $target_id    = $obj->id;
    my $srclnkcursor = $lnkcol->get_links(
        $target_type,
        $target_id,
        "source"
    );

    my @src_ids = ();
    while ( my $linkobj = $srclnkcursor->next ) {
        my $pair    = $linkobj->pair;
        if ( $pair->[0]->{type} eq $target_type ) {
            push @src_ids, $pair->[1]->{id};
        }
        else {
            push @src_ids, $pair->[0]->{id};
        }
    }
    
    my $cursor  = $self->find({id => {'$in' => \@src_ids}});
    return $cursor;
}

1;
