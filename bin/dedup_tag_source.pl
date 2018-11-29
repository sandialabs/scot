#!/usr/bin/env perl
use lib '../../Scot-Internal-Modules/lib';
use lib '../lib';
use strict;
use warnings;
use v5.16;

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Mojo::JSON qw(encode_json decode_json);
use Scot::Env;
use HTML::Entities;

$ENV{'scot_mode'}           = "testing";
$ENV{'scot_auth_type'}      = "Testing";
$ENV{'scot_logfile'}        = "/var/log/scot/scot.link.test.log";
$ENV{'scot_config_file'}    = '../../Scot-Internal-Modules/etc/scot.cfg.pl';

my $env = Scot::Env->new({
    config_file => $ENV{'scot_config_file'},
});
my $mongo       = $env->mongo;
my @colnames    = (qw(tag source));

foreach my $colnombre (@colnames) {

    say "Deduplicating $colnombre";

    my %seen    = ();

    my $col = $mongo->collection(ucfirst($colnombre));
    my $cur = $col->find();

    ITEM:
    while ( my $item = $cur->next ) {

        my $id      = $item->id;
        my $value   = $item->value;
        my $lcval   = lc($value);

        say "  $value : $id";

        if ( $value eq $lcval ) {
            # special case, already lc'ed
            say "    ... already lowercased ... skipping"
            $seen{$lcval}++;
            next ITEM;
        }


    }
}

sub move_links {
    my $tagsrc  = shift;
    my $oldobj  = $tagsrc;
    my $newobj  = shift;

    my $lcol    = $mongo->collection('Link');
    my $lcur    = $lcol->get_object_links($tagsrc);

    while ( my $link = $lcur->next  ) {
        my $pullvert    = $lcol->get_vertex($oldobj);
        my $addvert     = $lcol->get_vertex($newobj);
        say "    ... removing old link vertice ".$pullvert->{type}.":".$pullvert->{id};
        $link->update({'$pull' => { vertices => $pullvert }});
        say "    ... adding new   link vertice ".$addvert->{type}.":".$addvert->{id};
        $link->update({'$addToSet' => { vertices => $addvert }});
    }
}

    
