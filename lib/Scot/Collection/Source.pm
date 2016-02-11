package Scot::Collection::Source;
use lib '../../../lib';
use Moose 2;
extends 'Scot::Collection';
with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

# source creation or update
sub create_from_handler {
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


1;
