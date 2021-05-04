#!/usr/bin/env perl

use lib '../../../../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Scot::Env;
use feature qw(say);

my $config_file = "./test.cfg.pl";
my $env         = Scot::Env->new({config_file => $config_file});

require_ok('Scot::Flair::Io');

my $io = Scot::Flair::Io->new({env => $env});

ok(defined $io, "IO module instantiated");


my $mongo   = $env->mongo;
my $col     = $mongo->collection('Entry');
my $entry   = $col->create({
    target  => {
        id  => 1,
        type    => 'event',
    },
    owner   => 'test',
    groups  => {
        read    => ['wg-scot-ir'],
        modify  => ['wg-scot-ir'],
    },
    body    => "<html><h1>This is a test</h1><html>",
});

my $fetched_entry = $io->get_object("entry", $entry->id);

ok (defined $fetched_entry, "Got something from io");
ok (ref($fetched_entry) eq "Scot::Model::Entry", "and its the right thing");
ok ($fetched_entry->body eq $entry->body, "Bodies match");

done_testing();
exit 0;
