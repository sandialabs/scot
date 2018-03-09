#!/usr/bin/env perl

use lib '../../lib';

use Test::More;
use Test::Deep;
use Scot::Env;
use Data::Dumper;
use v5.18;

my $configfile  = './scot.cfg.pl';
my $env     = Scot::Env->new(
    config_file => $configfile,
);


ok(defined($env), "Env is defined");
is($env->version, "3.5.1", "Version Correct");
is($env->servername, "127.0.0.1", "Servername set correctly");
is($env->group_mode, "ldap", "Group Mode Set correctly");

my @modules = (
    { attr => "log", class => "Log::Log4perl::Logger"},
    { attr => "mongo", class => "Meerkat"},
    { attr => "mongoquerymaker", class => "Scot::Util::MongoQueryMaker"},
    { attr => "imap", class => "Scot::Util::Imap"},
    { attr => "enrichments", class => "Scot::Util::Enrichments"},
    { attr => "ldap", class => "Scot::Util::Ldap"},
#    { attr => "img_munger", class => "Scot::Util::ImgMunger"},
#    { attr => "scot", class => "Scot::Util::Scot2"},
    { attr => "mq", class => "Scot::Util::Messageq"},
);

foreach my $href (@modules) {
    my $attr = $href->{attr};
    my $class= $href->{class};
    my $obj = $env->$attr;
    is (ref($obj), $class, "$attr is the correct class");
#    my $handle  = $env->get_handle($attr);
#    is (ref($handle), $class, "get_handle $attr worked");
}

print Dumper($env);

$env->log->debug("grabbing directly");
my $l1  = $env->ldap;
print "l1 = ".ref($l1)."\n";

$env->log->debug("grabbing via handle");
my $l2  = $env->get_config_item('ldap');
print "l2 = ".ref($l2)."\n";



done_testing();



