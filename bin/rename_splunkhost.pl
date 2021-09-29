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
    next if ( ! ref $data );

    foreach my $key (keys %$data) {
        next if ( ! ref($data->{$key}));
        next if ( ! ref($data->{$key}->{data} ));
        my $url = $data->{$key}->{data}->{url};
        if ( defined $url ) {
            # print "$key url = $url\n";
            my $old = $url;
            $url =~ s/splunk\.sandia\.gov/splunkit\.sandia\.gov/;
            next if ( $url eq $old );
            # print "$key new url = $url\n";
            my $update = {
                "data.$key.data.url" => $url
            };
            $entity->update({ '$set' => $update });
            my $t = $entity->data->{$key}->{data}->{url};
            # print "t = $t\n";
        }

    }
}

