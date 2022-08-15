#!/usr/bin/env perl

use lib '../../../../lib';
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use feature qw(say);

system("/usr/bin/mongo scot-test ./reset.js");

my $config_file = "./test.cfg.pl";
my $env         = Scot::Env->new(config_file=>$config_file);
require_ok('Scot::Enricher::Io');
my $io = Scot::Enricher::Io->new({env => $env});


require_ok('Scot::Enricher::Processor');
my $proc = Scot::Enricher::Processor->new({env => $env, scotio => $io});

ok(defined $proc, "Created Processor") || die "Failed to create Processor.pm";

my $enrichment_aref = $proc->enrichments;

#foreach (@$enrichment_aref) {
#    say ref($_);
#}

my @types = (
    { type  => 'ipaddr', expect => [qw(robtex_ip geoip splunk ick_ip recfutureproxy lriproxy rf_ipaddr farm)], },
    { type  => 'ipv6', expect => [qw(robtex_ip geoip splunk ick_ip recfutureproxy lriproxy rf_ipaddr farm)], },
    { type  => 'domain', expect => [qw(robtex_dns splunk recfutureproxy lriproxy farm)]},
    { type  => 'message_id', expect => [qw(hybrid_msgid splunk msgid_splunkdash)]},
);

foreach my $test (@types) {
    my $type    = $test->{type};
    my $expect  = $test->{expect};
    my @got     = ();

    foreach my $e (@$enrichment_aref) {
        if ( $e->will_enrich($type) ) {
            push @got, lc((split(/::/,ref($e)))[-1]);
        }
    }

    cmp_deeply(\@got, bag(@$expect), "$type got expected enrichments");
}

my @tests   = (
    {
        type    => 'ipaddr',
        value   => '192.168.1.1',
        expect  => {
            'farm' => {
                'type' => 'link',
                'data' => {
                    'title' => 'Search Farm',
                    'url' => 'https://farm.sandia.gov/search/?q=192.168.1.1'
                },
            },
            'geoip' => {
            },
            'ick_ip' => {
                'type' => 'link',
                'data' => {
                    'title' => 'ICK IP Details',
                    'url' => 'https://ick.sandia.gov/ipaddress/details/192.168.1.1'
                }
            },
            'lriproxy' => {
                'type' => 'link',
                'data' => {
                    'title' => 'Query LRI API',
                    'url' => '/scot/api/v2/lriproxy/1'
                    },
            },
            'recfutureproxy' => {
                'type' => 'link',
                'data' => {
                    'title' => 'Query Recorded Future API',
                    'url' => '/scot/api/v2/recfuture/1'
                },
            },
            'rf_ipaddr' => {
                'type' => 'link',
                'data' => {
                    'title' => 'Recorded Future',
                    'url' => 'https://splunk.sandia.gov/en-US/app/TA_recordedfuture-cyber/recorded_future_ip_enrichment?form.name=192.168.1.1'
                }
            },
            'robtex_ip' => {
                'type' => 'link',
                'data' => {
                    'title' => 'Lookup on Robtex (external)',
                    'url' => 'https://www.robtex.com/ip/192.168.1.1.html'
                }
            },
            'splunk' => {
                'data' => {
                    'url' => 'https://splunk.sandia.gov/en-US/app/search/search?q=search%20192.168.1.1',
                    'title' => 'Search on Splunk'
                },
                'type' => 'link'
            },
        },
    },
);

foreach my $test (@tests){
    my $expect  = delete $test->{expect};
    my $entity  = create_entity($test);
    my $updates = $proc->process_enrichments($entity);
    # say Dumper($updates);
    cmp_deeply($updates,$expect, "Got expected update");
    # say Dumper($expect);

}

sub create_entity {
    my $href    = shift;
    my $mongo   = $env->mongo;
    my $obj     = $mongo->collection('Entity')->create($href);
    return $obj;
}



