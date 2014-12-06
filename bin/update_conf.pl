#!/usr/bin/env perl

use JSON;
use File::Slurp;
use Data::Dumper;

my $inst_dir        = $ARGV[0];
my $mode            = $ARGV[1];

unless ($inst_dir) {
    die "Usage: $0 /inst/dir mode";
}

unless (-d $inst_dir) {
    die "$inst_dir does not exist!";
}

my $config_file = $inst_dir . "/etc/scot.conf";

unless (-r $config_file) {
    die "Can not read $config_file";
}
my $text   = read_file($config_file);

my $transformed = sprintf($text, $mode, $inst_dir, $inst_dir, $inst_dir);

my $root_dest   = $inst_dir . "/scot.conf";

write_file($root_dest, {overwrite_file => 1}, $transformed);
