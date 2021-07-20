#!/usr/bin/env perl

use lib '../lib';
use lib '/opt/scot/lib';
use Data::Dumper;
use Scot::Env;
use v5.16;

my $env   = Scot::Env->new(config_file=>'/opt/scot/etc/scot.cfg.pl');
my $mongo = $env->mongo;

my $agcol   = $mongo->collection('Alertgroup');
my $acol    = $mongo->collection('Alert');

my $start   = $ARGV[0];
my $end     = $ARGV[1];

if ( !defined $start or !defined $end ) {
    die "usage error: $0 start_id end_id";
}

if ( $start > $end ) {
    my $tmp = $start;
    $start  = $end;
    $end    = $tmp;
}

my $agcursor    = $agcol->find({
    '$and'  => [
        { id => { '$gte' => $start + 0 } },
        { id => { '$lte' => $end + 0 }},
    ],
});

while ( my $ag = $agcursor->next ) {

    my $agid    = $ag->id + 0;

    print "Bulk closing Alertgroup $agid\n";

    my $acursor = $acol->find({alertgroup => $agid});
    my $count   = 0;
    while (my $alert = $acursor->next) {

        print "    closing alert ".$alert->id."\n";

        $alert->update({
            '$set'  => { status => 'closed' },
        });
        $count++;

    }
    print "    updating alertgroup stats\n";
    $ag->update({
        '$set'  => {
            status => 'closed',
            closed_count => $count,
            open_count  => 0,
            promoted_count  => 0,
            updated => time(),
        },
    });

    print "     sending mq message to browsers\n";
    $env->mq->send("/topic/scot", {
        action  => 'updated',
        data    => {
            who => 'scot-admin',
            type => 'alertgroup',
            id => $agid,
        },
    });
    
}

