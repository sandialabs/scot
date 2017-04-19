#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use lib '/opt/scot/lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '../lib';
use Scot::App::Mail;
use Scot::Env;
use Data::Dumper;

say "--- Starting Mail Ingester ---";

my $config_file = '/opt/scot/etc/scot.cfg.pl';

my $env = Scot::Env->new(
    config_file => $config_file,
);


my $mongo   = $env->mongo;
my $agcol       = $mongo->collection('Alertgroup');
my $auditcol    = $mongo->collection('Audit');

my $cursor      = $agcol->find({});
$cursor->sort({id   => -1});
$cursor->immortal(1);

while ( my $ag = $cursor->next ) {
    say "Alertgroup ".$ag->id;
    my $c   = $auditcol->find({
        what                => "get_subthing",
        "data.collection"   => "alertgroup",
        "data.id"           => $ag->id . '',
    });
    $c->sort({when => 1});
    my $auditobj =$c->next;
    unless (defined $auditobj) {
        say "    Not Viewed Yet";
        $ag->update_set(firstview => -1);
        next;
    }
    my $v   = $auditobj->when + 0;
    my $t   = $ag->created + 0;
    my $r   = $v -$t;
    say "    Earliest view: ". $v;
    say "    Response Time: ". $r;
    $ag->update_set(firstview => $v);
}

