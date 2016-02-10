#!/usr/bin/perl

use lib '../lib';
use strict;
use warnings;
use v5.18;
use Scot::Env;
use MongoDB;
use Meerkat;
use Meerkat::Cursor;
use Data::Dumper;
use Scot::Model::Link;

my $env = Scot::Env->new({
    logfile => "/var/log/scot/migration_fix.log",
    mode    => 'prod',
});


my $dryrun  = $ARGV[0];

my $mongo   = $env->mongo;
my $log     = $env->log;

# $log->debug("Starting ",{filter=>\&Dumper, value=>$mongo});

my $link_col    = $mongo->collection('Link');

my $cursor  = $link_col->find({});
unless ( $cursor ) {
    die "nothing matching!";
}

$cursor->immortal(1);
my $total   = $cursor->count();

say "--- Found $total Links to Examine ----";

my %seen;

while ( my $link = $cursor->next ) {

    my $tt  = $link->target_type;
    my $ti  = $link->target_id;
    my $it  = $link->item_type;
    my $ii  = $link->item_id;
    my $id  = $link->id;

    if ( $seen{$tt}{$ti}{$it}{$ii} ) {
        say "Duplicate found.  Orig ".
            $seen{$tt}{$ti}{$it}{$ii}.
            " link $id.  $tt:$ti -> $it:$ii";
        # $link->remove;
    }
    else {
        $seen{$tt}{$ti}{$it}{$ii} = $id;
    }
}



