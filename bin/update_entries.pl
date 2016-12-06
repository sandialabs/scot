#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use lib '../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';

use MongoDB;

my $db  = MongoDB->connect->db('scot-prod');
my $col = $db->get_collection('entry');
my $cur = $col->find({is_task => 1});

while (my $href = $cur->next ) {

    if ( $href->{is_task} ) {
        print "Entry ".$href->{id}." is a task\n";
        $col->update_one({ id => $href->{id} }, { '$set' => { class => 'task', metadata => $href->{task} } });
    }
}


