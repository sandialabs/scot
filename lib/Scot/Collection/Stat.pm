package Scot::Collection::Stat;

use lib '../../../lib';
use Moose 2;
use Data::Dumper;

extends 'Scot::Collection';

with    qw(
    Scot::Role::GetByAttr
    Scot::Role::GetTagged
);

sub upsert_metric {
    my $self    = shift;
    my $doc     = shift;
    my $match   = { %$doc }; # shallow clone ok bc only one level deep.
    my $log     = $self->env->log;
    # $log->debug("doc: ",{filter=>\&Dumper,value=>$doc});
    delete $match->{value};
    my $obj = $self->find_one($match);
    unless (defined $obj) {
        $log->trace("New Metric, inserting");
        $self->create($doc);
    }
    else {
        $log->trace("Updating existing metric");
        $obj->update({
            '$set'  => $doc
        });
    }
}

sub put_stat {
    my $self    = shift;
    my $metric  = shift;
    my $value   = shift;
    my $env     = $self->env;
    my $dt      = DateTime->from_epoch( epoch => $env->now );
    $self->increment($dt, $metric, $value);
}

sub fix_stat {
    my $self    = shift;
    my $metric  = shift;
    my $value   = shift;
    my $epoch   = shift;
    my $dt      = DateTime->from_epoch( epoch => $epoch );
    $self->increment($dt, $metric, $value);
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
        $log->debug("Updating existing stat record ".ref($obj));
        $log->trace("object is ",{filter=>\&Dumper, value=>$obj});
        my $newvalue = $obj->value + $value;
        $obj->update({
            '$set'  => { value => $newvalue },
        });
    }
    return $obj;
}

sub get_today_count {
    my $self    = shift;
    my $metric  = shift;
    my $log     = $self->env->log;
    my $dt      = DateTime->from_epoch( epoch => $self->env->now );
    my $match   = {
        metric  => $metric,
        year    => $dt->year,
        month   => $dt->month,
        day     => $dt->day, 
    };
    my $cursor  = $self->find($match);
    my $total   = 0;
    while ( my $obj = $cursor->next ) {
        $total += $obj->value;
    }
    return $dt->dow, $total;
}

sub get_dow_statistics {
    my $self    = shift;
    my $metric  = shift;
    my $log     = $self->env->log;
    my @command = (
        mapreduce   => "stat",
        out         => { inline => 1 },
        query       => { metric => $metric},
        map         => $self->_get_map_dow_js,
        reduce      => $self->_get_reduce_js,
        finalize    => $self->_get_finalize_js,
        # out         => 'tempstats',
    );

    # $log->debug("Command is ",{filter=>\&Dumper,value=>\%command});

    my $mongo   = $self->meerkat;
    my $db_name = $mongo->database_name;
    my $db      = $mongo->_mongo_database($db_name);
    my $result  = $self->_try_mongo_op(
        get_stats   => sub {
            my $job     = $db->run_command(\@command);
            return $job;
        }
    );
    # $log->debug("mapreduce returned: ",{filter=>\&Dumper, value=>$result});

    my @stats   = @{ $result->{results} };

    # $log->debug("stats are ", {filter=>\&Dumper, value => \@stats});

    return wantarray ? @stats : \@stats;
}

sub _get_map_dow_js {
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
}
EOF
}

1;
