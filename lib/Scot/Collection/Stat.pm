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

sub get_statistics {
    my $self    = shift;
    my $metric  = shift;
    my %command;
    my $tie = tie(%command, "Tie::IxHash");
    %command = (
        mapreduce   => "stat",
        map         => $self->_get_map_js,
        reduce      => $self->_get_reduce_js,
        finalize    => $self->_get_finalize_js,
        query       => $metric,
        out         => { inline => 1 },
    );
    my $mongo   = $self->meerkat;
    my $json    = $self->_try_mongo_op(
        get_stats   => sub {
            my $db_name = $mongo->database_name;
            my $db      = $mongo->mongo_database($db_name);
            my $job     = $db->run_command(\%command);
            return $job;
        }
    );
    return $json;
}

sub _get_map_js {
    return <<EOF;
function () {
    var key = this.dow;
    var value = {
        sum: this.value,
        min: this.value,
        max: this.value,
        count: 1,
        diff: 0
    };
    emit(key, value);
}
EOF
}

sub _get_reduce_js {
    return <<EOF;
function(dow, value) {
    var a = value[0];
    for (var i = 1; i < value.length; i++) {
        var b = value[i];
        var delta = a.sum / a.count - b.sum / b.count;
        var weight = (a.count * b.count) / (a.count + b.count);
        a.diff += b.diff + delta * delta * weight;
        a.sum += b.sum;
        a.count += b.count;
        a.min = Math.min(a.min, b.min);
        a.max = Math.max(a.max, b.max);
    }
    return a;
}
EOF
}

sub _get_finalize_js {
    return <<EOF;
function (key, value) {
    value.avg = value.sum / value.count;
    value.variance = value.diff / value.count;
    value.stddev = Math.sqrt(value.variance);
    return value;
EOF
}

1;
