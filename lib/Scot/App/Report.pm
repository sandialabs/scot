package Scot::App::Report;

use lib '../../../lib';
use strict;
use warnings;

use DateTime;
use Time::Duration;
use Data::Dumper;

use Moose;
extends 'Scot::App';

has months_ago  => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 6,
);

has nowdt       => (
    is          => 'rw',
    isa         => 'DateTime',
    lazy        => 1,
    required    => 1,
    default     => sub { DateTime->now; },
);

has thendt      => (
    is          => 'rw',
    isa         => 'DateTime',
    required    => 1,
    lazy        => 1,
    builder     => '_build_thendt',
);

sub _build_thendt {
    my $self    = shift;
    my $nowdt   = $self->nowdt;
    my $thendt  = $nowdt->clone();
    $thendt->subtract( months => $self->months_ago );
    return $thendt;
}

sub alertgroup_counts {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $nowdt   = $self->nowdt;
    my $thendt  = $self->thendt;

    $log->debug("counting alertgroups");

    my $query   = {
        metric  => 'alertgroups created',
        epoch    => {
            '$gte'  => $thendt->epoch,
            '$lte'  => $nowdt->epoch,
        },
    };

    $log->debug("query is ",{filter=>\&Dumper, value=>$query});

    my $cursor  = $mongo->collection('Stat')->find($query);
    my %result;

    while ( my $stat = $cursor->next ) {
        my $key = $stat->year . '/' . $stat->month;
        $result{$key} += $stat->value;
    }
    return wantarray ? %result : \%result;
}

sub event_counts {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $nowdt   = $self->nowdt;
    my $thendt  = $self->thendt;

    $log->debug("counting events");

    my $query   = {
        metric  => 'event created',
        epoch    => {
            '$gte'  => $thendt->epoch,
            '$lte'  => $nowdt->epoch,
        },
    };

    $log->debug("query is ",{filter=>\&Dumper, value=>$query});

    my $cursor  = $mongo->collection('Stat')->find($query);
    my %result;

    while ( my $stat = $cursor->next ) {
        my $key = $stat->year . '/' . $stat->month;
        $result{$key} += $stat->value;
    }
    return wantarray ? %result : \%result;
}

sub incident_counts {
    my $self    = shift;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $nowdt   = $self->nowdt;
    my $thendt  = $self->thendt;

    $log->debug("counting incidents");

    my $query   = {
        metric  => 'incident created',
        epoch    => {
            '$gte'  => $thendt->epoch,
            '$lte'  => $nowdt->epoch,
        },
    };

    $log->debug("query is ",{filter=>\&Dumper, value=>$query});

    my $cursor  = $mongo->collection('Stat')->find($query);
    my %result;

    while ( my $stat = $cursor->next ) {
        my $key = $stat->year . '/' . $stat->month;
        $result{$key} += $stat->value;
    }
    return wantarray ? %result : \%result;
}

sub response_times {
    my $self    = shift;
    my $env     = $self->env;;
    my $mongo   = $env->mongo;
    my $log     = $env->log;
    my $nowdt   = $self->nowdt;
    my $thendt  = $self->thendt;

    my $query   = {
        metric  => qr/Alertgroup Response Times/i,
        epoch   => {
            '$gte'  => $thendt->epoch,
            '$lte'  => $nowdt->epoch,
        },
    };

    my $cursor  = $mongo->collection('Stat')->find($query);
    my %result;

    while ( my $stat    = $cursor->next ) {
        my $key = $stat->year . '/' . $stat->month;
        my $metric  = $stat->metric;
        my @words   = split(/ /,$metric);
        my $type    = lc($words[0]);
        my $category = lc($words[2]);
        my $value   = $stat->value;
        $result{$key}{$category}{$type} += $value;
    }

    foreach my $key (keys %result) {
        $log->debug("$key");
        foreach my $category (keys %{$result{$key}}) {
            $log->debug("    $category");
            my $seconds = $result{$key}{$category}{sum};
            my $count   = $result{$key}{$category}{count};
            $log->debug({filter=>\&Dumper, value=> $result{$key}{$category}});
            if ( !defined $count or $count == 0 ) {
                $log->error("count zero or undef!");
                if ($seconds == 0) {
                    $result{$key}{$category}{avg} = 0;
                }
                else {
                    $result{$key}{$category}{avg} = 'na';
                }
                next;
            }

            $result{$key}{$category}{avg} = $seconds / $count;
            $result{$key}{$category}{humanavg} = duration($seconds / $count);
        }
    }

    return wantarray ? %result : \%result;
}



1;
