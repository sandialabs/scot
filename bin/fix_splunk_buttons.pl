#!/usr/bin/env perl

use lib '../lib';
use lib '../../Scot-Internal-Modules/lib';
use Scot::Env;
use Data::Dumper;

use strict;
use warnings;

my $env = Scot::Env->new(config_file => '/opt/scot/etc/scot.cfg.pl');
my $mongo   = $env->mongo;

my $col = $mongo->collection('Entity');
my $cursor = $col->find();
$cursor->immortal(1);

while (my $entity = $cursor->next) {
    my $id      = $entity->id;
    my $data    = $entity->data;
    print Dumper($data);
    if ( defined $data->{splunk} ) {
        if (defined $data->{splunkit}) {
            printf "%10d SplunkIt present, deleting splunk button\n",$id;
            delete $data->{splunk};
            $entity->update({'$set' => { data => $data }});
        }
        else {
            my $orig    = delete $data->{splunk};
            my $title   = $orig->{data}->{title};
            my $url     = $orig->{data}->{url};

            (my $newtitle = $title) =~ s/Splunk/SplunkIt/g;
            (my $newurl   = $url) =~ s/splunk/splunkit/g;

            print "$id Changing Data => \n";
            print "    $newtitle\n";
            print "    $newurl\n";

            $orig->{data} = {
                title   => $newtitle,
                url     => $newurl,
            };

            $data->{splunkit} = $orig;

            $entity->update({'$set' => { data => $data }});
        }
        print Dumper($data);
    }
}

