#!/usr/bin/env perl
use lib '../lib';
use lib '../../lib';
use Test::More;
use Test::Deep;
use Scot::Env;
use Safe;
use Data::Dumper;
use v5.18;

$ENV{'scot_mode'}           = "testing";
$ENV{'scot_auth_type'}      = "Testing";
$ENV{'scot_logfile'}        = "/var/log/scot/scot.test.log";
$ENV{'scot_config_paths'}   = '../../../Scot-Internal-Modules/etc';
$ENV{'scot_config_file'}    = 'scot_env_test.cfg';

my $configfile  = '../../../Scot-Internal-Modules/etc/scot_env_test.cfg';

my $env     = Scot::Env->new({
   config_file              => $ENV{'scot_config_file'},
});

ok(defined($env), "Env is defined");

my $ctr = new Safe 'CONFIGTEST';
my $r   = $ctr->rdo($configfile);
my $hn  = 'CONFIGTEST::environment';
my $thref   = \%CONFIGTEST::environment;

is( $env->version, "3.5.1", "Correct Version");
is( $env->mojo_defaults->{default_expiration}, 14400, "Correct expiration");
is( $env->mode, "testing", "Got Mode from Environment var");
is ($env->servername, $thref->{servername}, "Correct Servername");
is ($env->file_store_root, $thref->{file_store_root}, "Correct file store root");

foreach my $module_href (@{$thref->{modules}}) {
    my $attr  = $module_href->{attr};
    my $class = $module_href->{class};
    ok(defined($env->$attr), "Module $class instantiated.");
}

# say Dumper($thref);

done_testing();



