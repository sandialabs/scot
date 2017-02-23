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
use Scot::Util::Scot2;
use Scot::Util::EntityExtractor;
use Scot::Util::ImgMunger;
use Scot::Util::Enrichments;
use AnyEvent::STOMP::Client;
use AnyEvent::ForkManager;
use HTML::Entities;
use Module::Runtime qw(require_module);
use Sys::Hostname;
use strict;
use warnings;
use v5.18;

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

sub run {
    my $self    = shift;
    my $log     = $self->log;
    my $now     = time();
    my $ago     = $now - ( 7 * 24 * 60 * 60 );

    my $when    = [$now , $ago];

# collection->get_aggregate_count($aref) where $href is aggregate command
# $aref = [ $match_href, $group_href ];

    my @cats = (qw(
        teacher
        tattler
        alarmist
        closer
        cleaner
        fixer
        operative
    ));

    foreach my $category (@cats) {
        $self->$category($when);
    }
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
            what => 'event promotion to incident',
            when => { '$lte' => $when->[0] , '$gte' => $when->[1] },
        },
    };

    my $group   = {
        '$group'    => {
            '_id'   => '$who',
            total   => { '$sum' => 1 },
        }
    };

    my @agg = ( $match, $group );

    my $col     = $mongo->collection('History');

    $self->aggregate('tattler', $col, \@agg);

}

sub aggregate {
    my $self    = shift;
    my $type    = shift;
    my $col     = shift;
    my $agcmd   = shift;
    my $log     = $self->log;
    my $env     = $self->env;
    my $mongo   = $env->mongo;
    my $tt      = $self->tooltip;

    my $result  = $col->get_aggregate_count($agcmd);

    $log->debug("Aggregating $type");

    if ( $result ) {

        $log->debug("writing aggregation results for $type");

        my $gcol    = $mongo->collection("Game");
        while ( my $doc = $result->next ) {
            $doc->{tooltip} = $tt->{$type};

            $log->debug("updating ",{filter=>\&Dumper, value => $doc});

            my $gameobj = $gcol->upsert($type,$doc);
            unless ($gameobj) {
                $log->error("failed to create game object");
            }
        }
    }
    else {
        $log->error("error getting aggregation!");
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
            what        => 'promotion', 
            'data.type' => "alert to event", 
            when        => { '$lte' => $when->[0] , '$gte' => $when->[1] },
        },
    };

    my $group   = {
        '$group'    => {
            '_id'   => '$who',
            total   => { '$sum' => 1 },
        }
    };

    my @agg = ( $match, $group );

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
            when        => { '$lte' => $when->[0] , '$gte' => $when->[1] },
        },
    };

    my $group   = {
        '$group'    => {
            '_id'   => '$who',
            total   => { '$sum' => 1 },
        }
    };

    my @agg = ( $match, $group );

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
            what        => 'update_thing', 
            'data.request.json.closed'  => { '$ne' => undef },
            when        => { '$lte' => $when->[0] , '$gte' => $when->[1] },
        },
    };

    my $group   = {
        '$group'    => {
            '_id'   => '$who',
            total   => { '$sum' => 1 },
        }
    };

    my @agg = ( $match, $group );

    my $col     = $mongo->collection('Audit');
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
            what        => 'update_thing', 
            'data.collection'  => 'entry',
            when        => { '$lte' => $when->[0] , '$gte' => $when->[1] },
        },
    };

    my $group   = {
        '$group'    => {
            '_id'   => '$who',
            total   => { '$sum' => 1 },
        }
    };

    my @agg = ( $match, $group );

    my $col     = $mongo->collection('Audit');
    $self->aggregate('fixer', $col, \@agg);
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
            when        => { '$lte' => $when->[0] , '$gte' => $when->[1] },
        },
    };

    my $group   = {
        '$group'    => {
            '_id'   => '$owner',
            total   => { '$sum' => 1 },
        }
    };

    my @agg = ( $match, $group );

    my $col     = $mongo->collection('Entry');
    $self->aggregate('teacher', $col, \@agg);
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
            when        => { '$lte' => $when->[0] , '$gte' => $when->[1] },
        },
    };

    my $group   = {
        '$group'    => {
            '_id'   => '$owner',
            total   => { '$sum' => 1 },
        }
    };

    my @agg = ( $match, $group );

    my $col     = $mongo->collection('Entry');
    $self->aggregate('operative', $col, \@agg);
}





1;
