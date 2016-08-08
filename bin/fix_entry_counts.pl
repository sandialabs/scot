#!/usr/bin/env perl

use lib '../lib';
use Scot::Env;

my $env = Scot::Env->new();

my $mongo = $env->mongo;

my $col = $mongo->collection('Entry');
my $cursor  = $col->find(); # {id=>{'$gte'=>307503}});
my $cursor  = $col->find({id=>{'$gte'=>302966}}); 
my $remain  = $cursor->count();

while ( $o = $cursor->next ) {
    print "Entry: ". $o->id . " => ";
    my $target  = $o->target;
    my $id      = $target->{id};
    my $type    = $target->{type};

    if ( $type eq "alertgroup" ) {
        # alertgroups are not entriable, so assign to first alert
        my $agcol   = $mongo->collection('Alert');
        my $alert   = $agcol->find_one({alertgroup => $id});
        if ($alert) {
            $id = $alert->id;
            $type   = "alert";
        }
    }

    print "$type : $id ";
    my $tcol    = $mongo->collection(ucfirst($type));
    my $tobj    = $tcol->find_iid($id);
    unless ( $tobj ) {
        print ": NOT Found! ";
        $remain--;
        print $remain . " remain\n";
        next;
    }
    $tobj->update({
        '$inc'  => { entry_count => 1 },
    });
    print $tobj->entry_count ." entries ";
    $remain--;
    print $remain . " remain\n";

}



