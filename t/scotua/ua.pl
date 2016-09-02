#!/usr/bin/env perl
use lib '../lib';
use lib '../../lib';
use Scot::Env;
use Scot::Util::Scot2;
use Data::Dumper;

my $env = Scot::Env->new({
    logfile => '/var/log/scot/ua.log',
});

my $client  = Scot::Util::Scot2->new({
    servername  => 'as3001snllx'
});

my $json  = $client->get({
    type    => "event",
    params  => {
        limit => 3,
    }
});

if ( $json ) {
    print "Good!\n";
}
else {
    print "Error!\n";
}

print Dumper($json);

