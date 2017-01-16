#!/usr/bin/env perl

use warnings;
use strict;
use v5.18;
use lib '../../lib';

use Test::More;
use Scot::Util::Scot;
use Data::Dumper;
use IO::Prompt;

my $srvr = $ENV{'scot_ua_server'};
unless ( $srvr ) {
    prompt "Enter Scot server > ";
    $srvr = $_;
}

my $user = $ENV{'scot_ua_username'};
unless ($user ) {
    prompt "Enter username > ";
    $user    = $_;
}
my $pass = $ENV{'scot_ua_password'};
unless ($pass ) { 
    prompt ("Enter Password > ", -e => '*');
    $pass    = $_;
}


my $scot    = Scot::Util::Scot->new({
    servername  => $srvr,
    username    => $user,
    password    => $pass,
    authtype    => 'RemoteUser',
});

#my $json = $scot->get_alertgroup_by_msgid('<01802c60-6e4f-400a-9465-30ced472d208@EXCH03.srn.sandia.gov>');
# my $json = $scot->get_alertgroup_by_msgid('<asdfasdf>');

# say "alertgroup is ", Dumper($json);

# exit 1;

my $json    = $scot->do_request('get','config/2');

is($json->{id}, 2, "Correct ID");
is($json->{module}, "Scot::Util::Imap", "Correct Module");

$json = $scot->do_request("get", "event");
say Dumper($json);


$json    = $scot->do_request('post', "alertgroup", {
    json    => {
        message_id  => '112233445566778899aabbccddeeff',
        subject     => 'test message 1',
        data        => [
            { foo   => 1,   bar => 2 },
            { foo   => 3,   bar => 4 },
        ],
        tags     => [qw(test testing)],
        sources  => [qw(todd scot)],
        columns  => [qw(foo bar) ],
    }
});

say Dumper($json);

my $aid = $json->{id};

$json = $scot->do_request('get', "alertgroup/$aid");

say "alertgroup is ", Dumper($json);


