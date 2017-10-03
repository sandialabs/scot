package Scot::Collection::Atmetric;

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
    $log->debug("doc: ",{filter=>\&Dumper,value=>$doc});
    delete $match->{value};
    my $obj = $self->find_one($match);
    unless (defined $obj) {
        $log->debug("New AtMetric, inserting");
        $self->create($doc);
    }
    else {
        $log->debug("Updating existing AtMetric");
        $obj->update({
            '$set'  => $doc
        });
    }
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
    my $atype   = shift;
    my $log     = $self->env->log;
    my %command;
    my $tie = tie(%command, "Tie::IxHash");
    %command = (
        mapreduce   => "atmetric",
        out         => { inline => 1 },
        query       => { alerttype => $atype },
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
            my $job     = $db->run_command(\%command);
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
    var key = this.alerttype;
    var value = {
        sum: this.rt_sum,
        min: this.rt_sum,
        max: this.rt_sum,
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
