package Scot::Collection::Checklist;
use lib '../../../lib';
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';

sub create_from_api {
    my $self        = shift;
    my $request     = shift;
    my $env         = $self->env;
    my $json        = $request->{request}->{json};
    my $log         = $env->log;

    my @entries     = @{$json->{entry}};
    delete $json->{entry};

    my $checklist   = $self->create($json);

    $log->debug("created checklist ".$checklist->id);

    if ( scalar(@entries) > 0 ) {
        # entries were posted in
        my $mongo   = $self->env->mongo;
        my $ecoll   = $mongo->collection('Entry');

        foreach my $entry (@entries) {
            $entry->{owner}         = $entry->{owner} // $request->{user};
            $entry->{task}          = {
                when    => $env->now(),
                who     => $request->{user},
                status  => 'open',
            };
            $entry->{body}      = $entry->{body};
            $entry->{is_task}   = 1;

            my $obj = $ecoll->create($entry);

            $env->mongo->collection('Link')->add_link({
                item_type   => "entry",
                item_id     => $obj->id,
                when        => $env->now,
                target_type => "checklist",
                target_id   => $checklist->id,
            });
        }
    }
    
    return $checklist;
}

1;
