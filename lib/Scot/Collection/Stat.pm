package Scot::Collection::Stat;

use lib '../../../lib';
use Moose 2;

extends 'Scot::Collection';

with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

sub create_from_api {
    my $self    = shift;
    my $request = shift;
    my $env     = $self->env;
    my $log     = $env->log;

    $log->trace("Create Stat from API");
    
    my $stat = $self->create($request);

    return $stat;
}

sub increment {
    my $self    = shift;
    my $dt      = shift;
    my $metric  = shift;
    my $value   = shift;   
    my $env     = $self->env;
    my $log     = $env->log;

    $log->debug("Incrementing a Stat record");

    my $obj = $self->find_one({
        year    => $dt->year,
        month   => $dt->month,
        day     => $dt->day,
        hour    => $dt->hour,
        metric  => $metric,
    });

    unless ( $obj ) { 
        $log->debug("Creating new stat record");

        $obj = $self->create({
            year    => $dt->year,
            month   => $dt->month,
            day     => $dt->day,
            hour    => $dt->hour,
            dow     => $dt->dow,
            quarter => $dt->quarter,
            metric  => $metric,
            value   => $value,
        });
    }
    else {
        $log->debug("Updating existing stat record");
        $obj->update_inc( value   => $value );
    }
    return $obj;
}

1;
