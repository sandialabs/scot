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

$ENV{'scot_config_file'}    = '../../Scot-Internal-Modules/etc/flair.cfg.pl';

my $env = Scot::Env->new({
    config_file => $ENV{'scot_config_file'},
});

my $mongo       = $env->mongo;
my $entitycol   = $mongo->collection('Entity');
my $query       = {
    type    => { '$in' => [ qw(ipaddr ipv6 domain) ] },
    "data.blocklist3"   => { '$exists' => 0 }
};
my $cursor      = $entitycol->find($query);
my $count       = $entitycol->count($query);
$cursor->immortal(1);

my $bl3 = $env->enrichments->blocklist3;

my $complete      = 0;
my $remain        = $count;

while (my $entity = $cursor->next ) {
    my $value   = $entity->value;
    my $type    = $entity->type;

    printf "%d of %d (%d remain): updating entity %d => %s", $complete++, $count, $remain--, $entity->id, $value;

    my $data    = $bl3->get_data($type, $value);
    
    if ( defined $data ) {

        print Dumper($data);

        my $update  = {
            '$set'  => {
                "data.blocklist3.data"   => $data
            }
        };
        $entity->update($update);
        print "\n";
        if ( $data->{firewall} != 0 ) {
            die "Entity ".$entity->id;
        }
#        my $temp    = $entity->as_hash;
#        print Dumper($temp);
#        exit;
    }
    else {
        print "....no data\n";
    }

}

