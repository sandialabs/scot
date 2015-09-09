#!/usr/bin/env perl
use lib '../lib';
use lib '../../lib';
use Test::More;
use Test::Deep;
use Scot::Env;
use Data::Dumper;
use v5.18;

$ENV{'scot_mode'} = "testing";
my $db  = "scot-testing";
system("mongo $db ../../bin/reset_db.js");

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

is( $env->default_owner, "scot-adm", "Correct default owner pulled from db");
cmp_deeply( $env->default_groups, {
    read    => [ qw(ir testing) ],
    modify  => [ qw(ir testing) ],
}, "Correct default groups from config db");

while ( my $mod = $cursor->next ) {
    my $class   = $mod->class;
    my $attr    = $mod->attribute;
    is ( ref($env->$attr), $class, "$attr was loaded correctly");
}


done_testing();



