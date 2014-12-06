#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use lib '../lib';
use Getopt::Long qw(GetOptions);
use Scot::Env;
use HTML::Entities;
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);

$|  = 1;
my $interactive     =   '';
my $mode            =   'quality';      # the new database (mongo name)
my $config_file     =   "../scot.json"; # the config file
my $stat_collection =   'stats'; 
my $scan_collection =   '';
my $altday          =   '';             # allow this job to be rerun as if it was another day

GetOptions(
    "altyear=s"     => \$altyear,
    "altdmonth=s"   => \$altmonth,
    "altday=s"      => \$altday,
    "statcol=s"     => \$stat_collection,
    "mode=s"        => \$mode,
    "config=s"      => \$config_file,
) or die  <<EOF
    Invalid option!

    Usage: $0   
                --config configfile 
                --mode  quality
                --statcol stats_collection  
                --altyear year
                --altmonth month
                --altday day
EOF
;

# tasker will act as a Controller object that the other PM can use
# to get all the various info relied upon

my $tasker  = Scot::Env->new(
    config_file     => $config_file,
    mode            => $mode,
);

my $log     = $tasker->log;
my $mongo   = $tasker->mongo;
my $cursor;
my $day_in_seconds  = 60*60*24;
my %stats;

my $now         = DateTime->now;
my $stat_date   = DateTime->new(
    year    => $now->year,
    month   => $now->month,
    day     => $now->day,
    hour    => 0,
    minute  => 0,
    second  => 0,
    time_zone   => 'America/Denver',
);

my $daily_href  = get_daily_stats();
my $game_href   = get_game_stats();







exit 0;

sub get_daily_stats {
    my $href    = {};
    foreach my $collection (qw(alerts altergroups events incidents entries)) {
        my $cursor  = $mongo->read_documents({
            collection  => $collection,
        });
        $href->{$collection}->{total} = $cursor->count;
        my $begin   = $stat_date - $day_in_seconds;
        my $end     = $stat_date;
        $cursor = $mongo->read_documents({
            collection  => $collection,
            match_ref   => {
                created => {
                    '$gte'  => $begin,
                    '$lte'  => $end,
                },
            },
        });
        $href->{$collection}->{daily} = $cursor->count;
    }
    return $href;
}

sub get_orig {
    my $href    = shift;
    my $type    = $href->{type};
    my $value   = $href->{value};

    if (defined $orig_entity_db{$type}) {
        if ( defined $orig_entity_db{$type}{$value} ) {
            return $orig_entity_db{$type}{$value};
        }
    }

    my $entity  = $mongo->read_one_raw({
        collection  => "entities",
        match_re    => { entity_type   => $type, value => $value },
    });
    if ($entity) {
        $orig_entity_db{$type}{$value} = {
            created     => $entity->{created} // time(),
            updated     => $entity->{updated} // time(),
            entity_id   => $entity->{entity_id},
            notes       => $entity->{notes},
        };
        return $orig_entity_db{$type}{$value};
    }
}


sub set_checkpoint {
    my $type    = shift;
    my $id      = shift;

    my $href    = {
        collection  => "checkpoints",
        match_ref   => { collection => $type },
        data_ref    => { '$set' => { id => $id } },
    };
    $tasker->mongo->apply_update($href, { upsert => 1, safe => 1 });
}

sub get_checkpoint {
    my $type    = shift;

    say "Getting checkpoint for $type";

    my $search  = {
        collection  => "checkpoints",
        match_ref   => { collection => $type },
    };

    my $href    = $tasker->mongo->read_one_raw($search);

    say "    got ". Dumper($href);

    return $href->{id};
}

sub restart_phantom {
    # my   $phantom_count = `ps -ef | grep phantom | grep -v grep | wc -l`;
    # if ( $phantom_count >0 ) {
    #     system("ps -ef | grep phantom| grep -v grep | xargs kill -9 ");
    # }
    # my $foo = `/etc/init.d/phantomjs restart`;
    # say $foo;
    # $tasker  = Scot::Tasker->new(
     #    config_file     => $config_file,
      #   user_options    => { },
       #  mode            => $mode,
    # );
    sleep 5;
}

sub get_timer {
    my $start   = [ gettimeofday ];
    return sub {
        my $begin   = $start;
        my $elapsed = tv_interval($begin, [ gettimeofday ]);
        return $elapsed;
    };
}

sub get_entity_id {
    my $mongo   = $tasker->mongo;
    my $id      = $mongo->get_next_id("entities");
    return $id;
}

