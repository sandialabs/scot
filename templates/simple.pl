#!/usr/bin/env perl

use v5.18;
use strict;
use warnings;
use Mojo::UserAgent;
use MIME::Base64;
use Data::Dumper;

my $ua   = Mojo::UserAgent->new();
my $user = "test-user";
my $pass = "xxxxx";
chomp(my $auth = "Basic ".encode_base64($user.":".$pass));

$ua->on( start => sub {
    my $ua = shift;
    my $tx = shift;
    $tx->req->headers->header(
        'Authorization' => $auth,
        'Host'  => 'testhost'
    );
});

my $results = {};
for my $i (1..100) {

    my $tx = $ua->get(
        'https://testhost/scot/api/v2/event/1' => {Accept => '*/*' }
    );

    my $code = $tx->res->code;
    $results->{$code}++;

}
say Dumper($results);
