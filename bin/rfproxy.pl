#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use lib '../../lib';
use lib '../../Scot-Internal-Modules/lib';
use lib '/opt/scot/lib';
use v5.16;
use Scot::App::Responder::Reflair;
use Data::Dumper;

my $config_file = $ENV{'scot_app_rfproxy_config_file'} //
                        '/opt/scot/etc/recfuture.cfg.pl';
my $env = Scot::Env->new(
    config_file => $config_file,
);

$SIG{__DIE__} = sub { our @reason = @_ };

END {
    our @reason;
    if (@reason) {
        say "RecFuture Proxy died because: @reason";
        $env->log->error("RecFuture ProxyReFlair died because: ",{filter=>\&Dumper, value=>\@reason});
    }
}




my $loop    = Scot::App::Responder::RecFutureProxy->new({
    env => $env,
});
$loop->run();

