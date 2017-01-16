#!/usr/bin/env perl
use lib '../lib';
use lib '../../lib';
use Test::More;
use Test::Deep;
use Scot::Env;
use Safe;
use Data::Dumper;
use v5.18;

$ENV{'scot_mode'}       = "testing";
$ENV{'SCOT_AUTH_TYPE'}  = "Testing";
$ENV{'scot_log_file'}   = "/var/log/scot/scot.test.log";
$ENV{'scot_env_configfile'} = '../../../Scot-Internal-Modules/etc/scot_env_test.cfg';

my $configfile  = '../../../Scot-Internal-Modules/etc/scot_env_test.cfg';

my $env     = Scot::Env->new({
    configfile              => $configfile,
});

ok(defined($env), "Env is defined");

my $ctr = new Safe 'CONFIGTEST';
my $r   = $ctr->rdo($configfile);
my $hn  = 'CONFIGTEST::environment';
my $thref   = \%CONFIGTEST::environment;

is( $env->version, "3.5", "Correct Version");
is( $env->mojo->{default_expiration}, 14400, "Correct expiration");
is( $env->mode, "testing", "Got Mode from Environment var");
is ($env->servername, $thref->{servername}, "Correct Servername");
is ($env->filestorage, $thref->{file_store_root}, "Correct file store root");

foreach my $module (keys %{$thref->{modules}}) {
    ok(defined($env->$module), "Module $module instantiated.");
}

say Dumper($thref);

done_testing();



