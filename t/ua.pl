#!/usr/bin/env perl
use lib '../lib';
use Scot::Env;
use Scot::Util::Scot;
use Data::Dumper;

my $env = Scot::Env->new({
    logfile => '/var/log/scot/ua.log',
});

my $client  = Scot::Util::Scot->new({
    servername  => 'localhost'
});

my $tx  = $client->get("/scot/api/v2/event/9000");

if ( $tx ) {
    print "Good!\n";
}
else {
    print "Error!\n";
}

print Dumper($tx->res->json);

