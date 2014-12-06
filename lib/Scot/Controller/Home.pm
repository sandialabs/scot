package Scot::Controller::Home;

use lib '../../../lib';
use v5.10;
use strict;
use warnings;

use Data::Dumper;
use Scot::Util::Mongo;
use JSON;
use Time::HiRes qw(gettimeofday tv_interval);
use Net::LDAP;
use Net::STOMP::Client;

use Scot::Model::Alert;
use Scot::Model::Audit;
use Scot::Model::Event;
use Scot::Model::Incident;
use Scot::Model::Entry;
use Scot::Model::Checklist;
use Scot::Model::Guide;
use Scot::Model::Entity;

use base 'Mojolicious::Controller';

=head2 home
=cut

sub get_response_timer {
    my $self    = shift;
    my $title   = shift;
    my $start   = [ gettimeofday ];
    my $log     = $self->app->log;

    return sub {
        my $begin   = $start;
        my $elapsed = tv_interval($begin, [gettimeofday]);
        $log->debug(" -- -- $title ");
        $log->debug(" -- -- Elapsed seconds: $elapsed ");
        $log->debug(" -- -- ----------------");
        return $elapsed;
    };
}

sub home {
    my $self        = shift;
    my $log         = $self->app->log;
    my $mongo       = $self->mongo;
    my $timer       = $self->get_response_timer();

    my %data;
    foreach my $collection (qw(alerts events incidents)) {
        $data{$collection}  = $self->get_type_stats($collection);
    }

    $log->debug("Data so far is ".Dumper(\%data));

    # $data{'tags'}   = $self->get_tag_stats();

    my $servertime = &$timer;
    
    $self->render(
        json => {
            title   => "Home Page Stats",
            action  => "get",
            thing   => "stats",
            status  => 'ok',
            stime   => $servertime,
            data    => \%data,
        }
    );

}

sub get_type_stats {
    my $self        = shift;
    my $type        = shift;
    my $log         = $self->app->log;
    my $mongo       = $self->mongo;

    my $day_in_seconds  = 60*60*24;
    
    my $cursor      = $mongo->read_documents({
        collection  => $type,
        match_ref   => {},
    });
    my $total_type_count   = $cursor->count;

    my @spark   = ();
    my $now     = time();
    
    for ( my $i = 1; $i <= 5; $i++ ) {
        my $begin  =  $now - ( $i * $day_in_seconds );
        my $end    =  $now - ( ($i - 1) * $day_in_seconds );
        $cursor     = $mongo->read_documents({
            collection  => $type,
            match_ref   => {
                created => { 
                    '$gte'    => $begin ,
                    '$lte'    => $end ,
                },
            },
        });
        push @spark, $cursor->count;
    }
    @spark = reverse @spark;
    return {
        total_count     => $total_type_count,
        spark_data      => \@spark,
    };
}

sub get_aggregate_sum {
    my $self            = shift;
    my $agghref         = shift;
    my $collection      = $agghref->{collection};
    my $match_ref       = $agghref->{match_ref};
    my $agg_by_field    = $agghref->{agg_by_field};
    my $sum_field       = $agghref->{sum_field};
    my $mongo           = $self->mongo;
    my $log             = $self->app->log;

    my $group_ref   = {
        '$group'    => {
            '_id'   => '$'.$agg_by_field,
            total   => {
                '$sum'  => '$'.$sum_field
            }
        }
    };

    $log->debug("group_ref is ".Dumper($group_ref));

    my $result  = $mongo->aggregate({
        collection          => $collection,
        aggregation_aref    => [
            { '$match'  => $match_ref},
            $group_ref,
        ]
    });
    $log->debug("Got aggregate result: ".Dumper($result));

    return $result;
}

sub get_aggregate_count {
    my $self            = shift;
    my $agghref         = shift;
    my $collection      = $agghref->{collection};
    my $match_ref       = $agghref->{match_ref};
    my $agg_by_field    = $agghref->{agg_by_field};
    my $mongo           = $self->mongo;
    my $log             = $self->app->log;

    my $group_ref   = {
        '$group'    => {
            '_id'   => '$'.$agg_by_field,
            total   => { '$sum'  => 1 },
        },
    };
    $log->debug("group_ref is ".Dumper($group_ref));

    my $result  = $mongo->aggregate({
        collection          => $collection,
        aggregation_aref    => [
            { '$match' => $match_ref},
            $group_ref,
        ]
    });
    $log->debug("Got aggregate result: ".Dumper($result));

    return $result;
}

sub get_tag_stats {
    my $self    = shift;
    my $mongo   = $self->mongo;
    my %results;

    foreach my $collection (qw(alerts events incidents intel)) {

        my $result  = $mongo->aggregate({
            collection          => $collection,
            aggregation_aref    => [
                { '$match'      => {} },
                { '$project'    => { tags => 1 } },
                { '$unwind'     => '$tags' },
                { '$group'      => {
                        '_id'   => '$tag', count   => { '$sum' => 1 },
                    }
                }
            ]
        });
        foreach my $href (@$result) {
            my $tag     = $href->{_id};
            my $count   = $href->{count};
            $results{$tag} += $count;
        }
    }
    return \%results;
}

sub game {
    my $self    = shift;
    my $type    = $self->stash('type');
    my $method  = "get_". $type;
    return $self->$method;
}

sub get_alarmist {
    my $self    = shift;
    return  $self->get_aggregate_count({
        collection      => "audits",
        match_ref       => { what => "promoted alert" },
        agg_by_field    => "who",
    });
}

sub get_tattler {
    my $self    = shift;
    return $self->get_aggregate_count({
        collection      => "audits",
        match_ref       => { what => "promoted event" },
        agg_by_field    => "who",
    });
}

sub get_voyeur {
    my $self        = shift;
    my $viewregex   = qr/viewed/i;
    return $self->get_aggregate_count({
        collection      => "audits",
        match_ref       => { what => $viewregex },
        agg_by_field    => "who",
    });
}

sub get_fixer {
    my $self        = shift;
    my $updateregex = qr/updated/i;
    return $self->get_aggregate_count({
        collection      => "audits",
        match_ref       => { what => $updateregex },
        agg_by_field    => "who",
    });
}

sub get_closer {
    my $self        = shift;
    my $closeregex  = qr/closed/i;
    return $self->get_aggregate_count({
        collection      => "audits",
        match_ref       => { what => $closeregex },
        agg_by_field    => "who",
    });
}

sub get_cleaner {
    my $self        = shift;
    my $deleteregex = qr/deleted/i;
    return $self->get_aggregate_count({
        collection      => "audits",
        match_ref       => { what => $deleteregex },
        agg_by_field    => "who",
    });
}

sub get_researcher {
    my $self = shift;
    return $self->get_aggregate_count({
        collection      => "audits",
        match_ref       => { what => "retrieved entity data" },
        agg_by_field    => "who",
    });
}

sub get_novelist {
    my $self    = shift;
    my $createregex = qr/created entry/;
    return $self->get_aggregate_count({
        collection      => "audits",
        match_ref       => { what => $createregex },
        agg_by_field    => "who",
    });
}

1;

