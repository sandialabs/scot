#!/usr/bin/env perl

use lib '../../lib';

use Test::More;
use Test::Deep;
use Scot::Env;
use Data::Dumper;
use v5.18;

my $configfile  = './configs/scot.test.cfg.pl';
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
    { attr => "extractor", class => "Scot::Util::EntityExtractor"},
    { attr => "img_munger", class => "Scot::Util::ImgMunger"},
    { attr => "scot", class => "Scot::Util::Scot2"},
    { attr => "mq", class => "Scot::Util::Messageq"},
);

foreach my $href (@modules) {
    my $attr = $href->{attr};
    my $class= $href->{class};
    my $obj = $env->$attr;
    is (ref($obj), $class, "$attr is the correct class");
}

done_testing();



