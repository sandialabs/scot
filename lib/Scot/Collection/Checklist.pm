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

    my @entries     = @{$json->{entry}};
    delete $json->{entry};

    my $checklist   = $self->create($json);

    if ( scalar(@entries) > 0 ) {
        # entries were posted in
        my $mongo   = $self->env->mongo;
        my $ecoll   = $mongo->collection('Entry');
        foreach my $entry (@entries) {
            $entry->{targets}   = [{
                id     => $checklist->id,
                type   => "checklist",
            }];
            $entry->{owner}         = $entry->{owner} // $request->{user};
            $entry->{task}          = {
                when    => $env->now(),
                who     => $request->{user},
                status  => 'open',
            };
            $entry->{is_task}   = 1;

            my $obj = $ecoll->create($entry);
        }
    }
    
    return $checklist;
}

1;
