package Scot::Controller::Metric;

use Data::Dumper;
use Try::Tiny;
use DateTime;
use DateTime::Format::Strptime;
use Mojo::JSON qw(decode_json encode_json);

use strict;
use warnings;
use base 'Mojolicious::Controller';

sub get {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $thing   = $self->stash('thing');

    $log->debug("---");
    $log->debug("--- GET metric $thing");
    $log->debug("---");

    return $self->$thing;
}

sub do_render {
    my $self    = shift;
    my $href    = shift;
    $self->render(
        json    => $href,
        code    => 200,
    );
}

sub get_request_params {
    my $self    = shift;
    return $self->req->params->to_hash;
}

# http://bl.ocks.org/tjdecke/5558084
sub day_hour_heatmap {
    my $self        = shift;
    my $env         = $self->env;
    my $log         = $env->log;
    my $mongo       = $env->mongo;
    my $request     = $self->get_request_params;
    my $collection  = $request->{collection} // 'event';
    my $type        = $request->{type} // 'created';
    my $year        = $request->{year} // $self->get_this_year;
    my $query       = {
        metric  => qr/$collection $type/,
        year    => $year,
    };

    my $cursor  = $mongo->collection('Stat')->find($query);
    my %results;
    while ( my $stat = $cursor->next ) {
        # doesn't work as expected because GMT 
        # $results{$stat->dow}{$stat->hour} += $stat->value;
        # once this is fixed, can probably collapse the two loops into one
        my $dt  = DateTime->from_epoch(epoch=>$stat->epoch);
        $dt->set_time_zone('America/Denver'); # TODO: move to config
        $results{$dt->dow}{$dt->hour} += $stat->value;
    }
    my @r   = ();
    for (my $dow = 1; $dow <= 7; $dow++) {
        for (my $hour = 0; $hour <= 23; $hour++) {
            my $value = $results{$dow}{$hour};
            push @r, { day => $dow, hour => $hour, value => $value };
        }
    }
    $self->do_render(\@r);
}


sub response_time {
    my $self    = shift;


}




1;
