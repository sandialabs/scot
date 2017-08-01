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

my $cursor      = $agcol->find({id=>{'$lt'=>1508328}});
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
    my $v;
    my $t   = $ag->created + 0;
    if (defined $auditobj) {
        $v   = $auditobj->when + 0;
    }
    else {
        my $rawag = $agcol->raw_get_one({id => $ag->id});
        my $viewby = $rawag->{viewed_by};
        if ( defined $viewby ) {
            if (scalar(keys %$viewby) > 0 ) {
                my @times = sort { $a <=> $b } map { 
                    $viewby->{$_}->{when};
                } keys %$viewby;
                my $rt = $times[0];
                $rt = -1 if ($rt < 948483389);
                $v = $rt;
                say "        resorted to old viewed_by for rt";
            }
            else {
                say "    Not Viewed Yet";
                $v = -1;
            }
        }
        else {
            say "    Not Viewed Yet";
            $v = -1;
        }
    }
    say "    Earliest view: ". $v;
    $ag->update_set(firstview => $v);
    if ( $v > 0 ) {
        my $r   = $v - $t;
        say "    Response Time: ". $r;
    }
}

