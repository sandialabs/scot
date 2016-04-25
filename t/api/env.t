#!/usr/bin/env perl
use lib '../lib';
use lib '../../lib';
use Test::More;
use Test::Deep;
use Scot::Env;
use Data::Dumper;
use v5.18;

$ENV{'scot_mode'}   = "testing";
$ENV{'SCOT_AUTH_MODE'}   = "Testing";
print "Resetting test db...\n";
system("mongo scot-testing <../../etc/database/reset.js 2>&1 > /dev/null");


my $env     = Scot::Env->new({
});

ok(defined($env), "Env is defined");

is( $env->version, "3.5", "Correct Version");
is( $env->mojo->{default_expiration}, 14400, "Correct expiration");
is( $env->mode, "testing", "Got Mode from Environment var");
is( $env->mongo_config->{db_name}, "scot-testing", "Correct DB Name");

my $mongo   = $env->mongo;
my $col     = $mongo->collection('Scotmod');
my $cursor  = $col->find();

is( $env->default_owner, "scot-admin", "Correct default owner pulled from db");
cmp_deeply( $env->default_groups, {
    read    => [ qw(wg-scot-ir wg-scot-researchers) ],
    modify  => [ qw(wg-scot-ir ) ],
}, "Correct default groups from config db");

say Dumper($env->default_groups);

while ( my $mod = $cursor->next ) {
    my $class   = $mod->module;
    my $attr    = $mod->attribute;
    is ( ref($env->$attr), $class, "$attr was loaded correctly");
}


done_testing();



