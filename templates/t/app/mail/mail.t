#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;
use lib '../../lib/';
use Scot::Env;
use Test::More;
use DateTime;
use Data::Dumper;

my $config_file = "./alert.cfg.pl";
my $env = Scot::Env->new( config_file => $config_file );

use_ok('Scot::App::Mail');

my $mail = Scot::App::Mail->new( env => $env );


say "Approved alert domains  = ",join(',',@{$env->approved_alert_domains});
say "Approved alert accounts = ",join(',',@{$env->approved_accounts});

my $href    = {
    message_id  => "123456789123456789",
    subject     => "foo test",
};

my %senders = (
    'tbruner@watermelon.gov' => 1,
    'todd.bruner@gmail.com' => 1,
    'foo@watermelon.gov'    => 1,
    'foo@bar.gov'   => undef,
    'hacker@bad.com'    => undef,
    'sydney@scotdemo.org'   => 1,
    'maddox@law.com'    => undef,
);


foreach my $sender (sort keys %senders) {
    $href->{from} = $sender;
    my $msg = "$sender was ";
    $msg .= "NOT " unless ($senders{$sender});
    $msg .= "approved";
    is ( $mail->approved_sender($href), $senders{$sender}, "$msg ");
}

    
