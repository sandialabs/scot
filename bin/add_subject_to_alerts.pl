#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use Scot::Env;

my $config  = "/opt/scot/etc/scot.cfg.pl";
my $env     = Scot::Env->new({config_file => $config});
my $mongo   = $env->mongo;
my $alertcol    = $mongo->collection('Alert');
my $agcol       = $mongo->collection('Alertgroup');

my $query   = {
    subject => { '$exists' => undef }
};

my $cursor  = $alertcol->find($query);
$cursor->sort({id => -1});
$cursor->immortal(1);

while ( my $obj = $cursor->next ) {
    my $id      = $obj->id + 0;
    my $agid    = $obj->alertgroup + 0;

    print "Alert $id linked to alergroup $agid ";

    my $ag = $agcol->find_iid($agid);

    if ( defined $ag ) {
        my $subject = $ag->subject;
        if ( defined $subject ) {
            print "subject $subject\n";
            $obj->update_set(subject => $subject);
        }
        else {
            print "-- subject null --\n";
            die;
        }
    }
    else {
        print "-- alertgroup not found --\n";
        die;
    }
}
