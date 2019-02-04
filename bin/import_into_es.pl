#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use IO::Prompt;
use Getopt::Long qw(GetOptions);
use Data::Dumper;
use Try::Tiny;
use Data::Clean::FromJSON;
use Scot::Env;
use Parallel::ForkManager;

my $config_file = $ENV{'scot_app_es_importer_config'} //
                  '/opt/scot/etc/stretch.cfg.pl';

my $env = Scot::Env->new( config_file => $config_file );


my $limit       = 0;                # limit the number of records to process
my $collection  = 'entry,alert';    # default collections to process
my $start_id    = 1;                # for id ranges
my $end_id      = -1;               # to max id
my $start_date  = '';               # enter a date range mm-dd-yyyy
my $end_date    = '';               # enter a date range mm-dd-yyyy
my $start_epoch = 0;               # seconds epoch to start
my $end_epoch   = 0;               # seconds epoch to end
my $workers     = 0;                # number of forked workers to run
                                    # zero = no fork

GetOptions(
    'l=i'       => \$limit,
    'c=s'       => \$collection,
    'si=i'      => \$start_id,
    'ei=i'      => \$end_id,
    'se=i'      => \$start_epoch,
    'ee=i'      => \$end_epoch,
    'sd=s'      => \$start_date,
    'ed=s'      => \$end_date,
    'w=i'       => \$workers,
) or die <<EOF

Invalid option !

    usage: $0
        [-l=1001]           limit to 1001 items
        [-c=alert,entry]    process collections listed
        [-si=123]           process records with id's >= this number
        [-ei=123]           process records with id's <= this number
        [-se=1547831257]    start epoch, import records after this
        [-ee=1547831257]    end epoch, import records before this
        [-sd=10-10-2010]    start mm-dd-yyyy
        [-ed=10-10-2010]    end mm-dd-yyyy
        [-w=3]              number of forked workers to use, default = 0

EOF
;

my $pm  = Parallel::ForkManager->new($workers);
my $es  = $env->es;
my $cleanser    = Data::Clean::FromJSON->get_cleanser;


foreach my $col (split(/,/,$collection)) {
    my $collection  = $env->mongo->collection(ucfirst($col));
    my $match       = build_query();
    print "-- Querying $col with ".Dumper($match)."\n";
    my $count       = $collection->count($match);
    my $cursor      = $collection->find($match);
    $cursor->immortal(1);
    if ( $limit > 0 ) {
        $cursor->limit($limit);
    }

    print "--- Processing $count records\n";

    RECORD:
    while ( my $obj = $cursor->next ) {
        my $pid         = $pm->start();
        if ( $pid != 0 ) {
            next RECORD;
        }
        my $data = $obj->as_hash;
        try {
            $cleanser->clean_in_place($data);
            $es->index('scot', $col, $data);
        }
        catch {
            $env->log->error("Error failed to index $col:$data->{id}");
        };
        $pm->finish(0);
    }
}
$pm->wait_all_children;

sub build_query {
    my $href    = {};

    if ( $start_id > 1 ) {
        $href->{id}->{'$gte'}  = $start_id;
    }
    if ( $end_id > -1) {
        $href->{id}->{'$lte'}  = $end_id;
    }
    if ( $start_date ne '' ) {
        my ($m,$d,$y) = split(/-/, $start_date);
        my $dt       = DateTime->new(
            year    => $y,
            month   => $m,
            day     => $d);
        $href->{when}->{'$gte'} = $dt->epoch;
    }
    if ( $end_date ne '' ) {
        my ($m,$d,$y) = split(/-/, $end_date);
        my $dt       = DateTime->new(
            year    => $y,
            month   => $m,
            day     => $d);
        $href->{when}->{'$lte'} = $dt->epoch;
    }
    if ( $start_epoch ) {
        $href->{when}->{'$gte'} = $start_epoch;
    }
    if ( $end_epoch ) {
        $href->{when}->{'$gte'} = $end_epoch;
    }
    return $href;
}
