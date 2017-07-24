#!/usr/bin/env perl

use lib '../lib';
use Scot::Util::ScotClient;
use MIME::Base64;
use Data::Dumper;
use JSON;
use strict;
use warnings;
use v5.18;


my %users = (
    admin       => '61E4663E-6CAB-11E7-B011-FEE80D183886',
    joplin      => '51E4663E-6CAB-11E7-B011-FEE80D183886',
#    kelly       => '41E4663E-6CAB-11E7-B011-FEE80D183886',
#    montgomery  => '31E4663E-6CAB-11E7-B011-FEE80D183886',
#    pilgrim     => '21E4663E-6CAB-11E7-B011-FEE80D183886',
);

my %clients = ();
foreach my $user (sort keys %users) {
    say "Initializing $user UA...";

    my $client  = Scot::Util::ScotClient->new({
        auth_type   => 'apikey',
        api_key => $users{$user},
        config  => {},
    });

    $clients{$user} = $client;

    say Dumper($client->get('whoami'));
#    die;
}

say Dumper($clients{'admin'}->get('whoami'));

