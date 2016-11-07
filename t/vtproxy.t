#!/usr/bin/env perl

use lib '../lib';
use Scot::Env;
use Scot::Util::VirusTotal;
use Data::Dumper;
use IO::Prompt;
use v5.18;

my $env = Scot::Env->new();

# my $user    = $env->ldap->username;
# my $pass    = $env->ldap->password;

my $user = prompt "username: ";
my $pass = prompt(-tty, -e => '*', "password: ");

$user = $user->{value};
$pass = $pass->{value};

my $vt  = Scot::Util::VirusTotal->new({
    env         => $env,
    username    => $user,
    password    => $pass,
});

# my $domain_report = $vt->get_domain_report('wix.com');
# say Dumper($domain_report);

my $hash = "put your hash here";

my $behavior = $vt->get_file_behaviour($hash);

say Dumper($behavior);
