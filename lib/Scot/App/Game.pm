package Scot::App::Game;

use lib '../../../lib';
# use lib '/opt/scot/lib';

=head1 Name

Scot::App::Game

=head1 Description

run a fun report about what the analysts are upto

=cut

use Data::Dumper;
use JSON;
use Try::Tiny;
use Mojo::UserAgent;
use Scot::Env;
use Scot::App;
use Scot::Util::ScotClient;
use Scot::Util::ImgMunger;
use Scot::Util::Enrichments;
use AnyEvent::STOMP::Client;
use AnyEvent::ForkManager;
use HTML::Entities;
use Module::Runtime qw(require_module);
use Sys::Hostname;
use DateTime;
use strict;
use warnings;
use v5.16;

use Moose;
extends 'Scot::App';


has thishostname    =>  (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => sub { hostname; },
);

has tooltip => (
    is          => 'ro',
    isa         => 'HashRef',
    default     => sub { {
        teacher     => "Most Guide Entries Authored",
        tattler     => "Most Incidents Promoted",
        alarmist    => "Most Alerts Promoted",
        closer      => "Most Closed things",
        cleaner     => "Most Deleted Things",
        fixer       => "Most Edited Entries",
        operative   => "Most Intel Entries",
    }},
);


sub out {
    my $self    = shift;
    my $msg     = shift;

    if ( $self->interactive ) {
        say $msg;
    }
}

sub docker {
    my $self    = shift;
    my $log     = $self->log;
    my $env     = $self->env;
    my $interval    = (24 * 60 * 60);
    while (1) {
        $self->run();
        sleep $interval;
    }
}



sub run {
    my $self    = shift;
    my $log     = $self->log;
    my $env     = $self->env;
    my $now     = time();
    my $days_ago    = $env->days_ago // 30;
    my $ago     = $now - ( $days_ago * 24 * 60 * 60 ); 


# collection->get_aggregate_count($aref) where $href is aggregate command
# $aref = [ $match_href, $group_href ];

    my @cats = (qw(
        alarmist
        fixer
        cleaner
        closer
        operative
        tattler
        teacher
    ));

    foreach my $category (@cats) {
        $self->$category($ago);
    }
}

sub aggregate {
    my $self    = shift;
    my $type    = shift;
    my $col     = shift;
    my $agcmd   = shift;
    my $log     = $self->log;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $tt      = $self->tooltip->{$type};

    $log->debug("Aggregating $type");
    $log->debug("Aggregate Count Parameter:" .Dumper($agcmd));

    my $result  = $col->get_aggregate_count($agcmd);
    
    $log->debug("Results: ",{filter=>\&Dumper, value=>$result});

    my $gamecol = $mongo->collection('Game');

    my $obj = $gamecol->find_one({
        game_name   => $type,
    });

    if ( defined $obj ) {
        $obj->update({ '$set' => {
            lastupdate  => $env->now,
            results     => $result,
        }});
    }
    else {
        $gamecol->create({
            game_name   => $type,
            tooltip     => $tt,
            lastupdate  => $env->now,
            results     => $result
        });
    }
}


=item B<alarmist>

this game calculates who has promoted the most alerts

=cut

sub alarmist {
    my $self    = shift;
    my $when    = shift;
    my $env     = $self->env;
    my $log     = $self->log;
    my $mongo   = $env->mongo;
    
    my $match   = {
        '$match'    => { 
            what                    => "promotion",
            "data.source.type"      => "alert",
            when                    => { '$gte' => $when },
        },
    };

    my $group   = { 
        '$group' => { _id => '$who', total   => { '$sum' => 1 } }
    };
    my $sort    = { 
        '$sort' => { total => -1 }
    };

    my @agg = ( $match, $group, $sort );
    $log->debug("Aggreation command is ",
                {filter=>\&Dumper, value => \@agg});

    my $col     = $mongo->collection('Audit');
    $self->aggregate('alarmist', $col, \@agg);
}

=item B<cleaner>

this game calculates who has deleted the most things in the past timeframe

=cut


sub cleaner {
    my $self    = shift;
    my $when    = shift;
    my $env     = $self->env;
    my $log     = $self->log;
    my $mongo   = $env->mongo;
    
    my $match   = {
        '$match'    => { 
            what        => 'delete_thing', 
            when        => { '$gte' => $when },
        },
    };

    my $group   = {
        '$group'    => {
            '_id'   => '$who',
            total   => { '$sum' => 1 },
        }
    };
    my $sort    = { 
        '$sort' => {total => -1 }
    };

    my @agg = ( $match, $group, $sort );
    $log->debug("Aggreation command is ",
                {filter=>\&Dumper, value => \@agg});

    my $col     = $mongo->collection('Audit');
    $self->aggregate('cleaner', $col, \@agg);
}

=item B<closer>

this game calculates who has closed the most things in the past timeframe

=cut

sub closer {
    my $self    = shift;
    my $when    = shift;
    my $env     = $self->env;
    my $log     = $self->log;
    my $mongo   = $env->mongo;
    
    my $match   = {
        '$match'    => { 
            what        => qr/closed/,
            when        => { '$gte' => $when },
        },
    };

    my $group   = {
        '$group'    => {
            '_id'   => '$who',
            total   => { '$sum' => 1 },
        }
    };
    my $sort    = { 
        '$sort' => { total =>  -1 },
    };

    my @agg = ( $match, $group, $sort );
    $log->debug("Aggreation command is ",
                {filter=>\&Dumper, value => \@agg});

    my $col     = $mongo->collection('History');
    $self->aggregate('closer', $col, \@agg);
}

=item B<fixer>

this game calculates who has edited the most entries in the past timeframe

=cut

sub fixer {
    my $self    = shift;
    my $when    = shift;
    my $env     = $self->env;
    my $log     = $self->log;
    my $mongo   = $env->mongo;
    
    my $match   = {
        '$match'    => { 
            what        => qr/updated/, 
            'target.type'  => 'entry',
            when        => { '$gte' => $when },
        },
    };

    my $group   = {
        '$group'    => {
            '_id'   => '$who',
            total   => { '$sum' => 1 },
        }
    };
    my $sort    = { 
        '$sort' => { total =>  -1 },
    };

    my @agg = ( $match, $group, $sort );
    $log->debug("Aggreation command is ",
                {filter=>\&Dumper, value => \@agg});

    my $col     = $mongo->collection('History');
    $self->aggregate('fixer', $col, \@agg);
}

=item B<operative>

this game calculates who has created the most Intel 

=cut

sub operative {
    my $self    = shift;
    my $when    = shift;
    my $env     = $self->env;
    my $log     = $self->log;
    my $mongo   = $env->mongo;
    
    my $match   = {
        '$match'    => { 
            'target.type'  => 'intel',
            when        => { '$gte' => $when },
        },
    };

    my $group   = {
        '$group'    => {
            '_id'   => '$owner',
            total   => { '$sum' => 1 },
        }
    };
    my $sort    = { 
        '$sort' => {total => -1 },
    };

    my @agg = ( $match, $group, $sort );
    $log->debug("Aggreation command is ",
                {filter=>\&Dumper, value => \@agg});

    my $col     = $mongo->collection('Entry');
    $self->aggregate('operative', $col, \@agg);
}

=item B<tattler>

this game calculated the user who has promoted the most incidents

=cut

sub tattler {
    my $self    = shift;
    my $when    = shift;
    my $env     = $self->env;
    my $log     = $self->log;
    my $mongo   = $env->mongo;
    
    my $match   = {
        '$match'    => { 
            what => 'event promoted to incident',
            when => { '$gte' => $when },
        },
    };

    my $group   = {
        '$group'    => {
            '_id'   => '$who',
            total   => { '$sum' => 1 },
        }
    };

    my $sort    = { 
        '$sort' => {total => -1 },
    };

    my @agg = ( $match, $group, $sort );
    $log->debug("Aggreation command is ",
                {filter=>\&Dumper, value => \@agg});

    my $col     = $mongo->collection('History');

    $self->aggregate('tattler', $col, \@agg);

}

=item B<teacher>

this game calculates who has create the most guide entries in the past timeframe

=cut

sub teacher {
    my $self    = shift;
    my $when    = shift;
    my $env     = $self->env;
    my $log     = $self->log;
    my $mongo   = $env->mongo;
    
    my $match   = {
        '$match'    => { 
            'target.type'  => 'guide',
            when        => { '$gte' => $when },
        },
    };

    my $group   = {
        '$group'    => {
            '_id'   => '$owner',
            total   => { '$sum' => 1 },
        }
    };
    my $sort    = { 
        '$sort' => { total => -1 }
    };

    my @agg = ( $match, $group, $sort );
    $log->debug("Aggreation command is ",
                {filter=>\&Dumper, value => \@agg});

    my $col     = $mongo->collection('Entry');
    $self->aggregate('teacher', $col, \@agg);
}

1;
