#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use lib '../../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';
use Scot::Env;
use v5.16;

my $config_file = $ENV{'scot_app_fix_id_config_file'} //
                        '/opt/scot/etc/scot.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);
my $mongo   = $env->mongo;
my $fix     = $ARGV[0];


foreach my $colname(qw(
    appearance
    alertgroup
    alert
    checklist
    entity
    entry
    event
    guide
    history
    incident
    intel
    source
    tag
    user
    audit
    file
    link
)) {
    say "--------";
    say "-------- Collection $colname";
    say "--------";

    my $collection  = $mongo->collection(ucfirst($colname));
    my $cursor      = $collection->find({});
    $cursor->sort({id=>-1});
    my $object      = $cursor->next;

    unless ($object) {
        next;
    }

    my $max = $object->id;
    say "Max ID is $max";

    if ( $fix eq "fix" ) { 
        $collection->set_next_id($max);
    }
}
